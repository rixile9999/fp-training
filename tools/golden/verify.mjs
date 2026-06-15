#!/usr/bin/env node
/**
 * tools/golden/verify.mjs — CI 골든 검증 오라클 (PLAN §5.3 ②, ④).
 *
 * 핀 gleam 1.17.0(tools/golden/bin, 브라우저 WASM 과 동일 버전·동일 Rust 소스)으로
 * content/ 의 코드-보유 콘텐츠를 실제 컴파일·실행해 타입별 골든 불변식을 강제한다:
 *   - predict (puzzle family, choice|exact_output): starter 실행 → stdout 을
 *       answer.txt 스냅샷으로 고정(불일치=실패). choice 는 answer.txt↔choices
 *       유일 매칭으로 정답 인덱스 도출(0개/2개↑=실패). --update 로 재스냅샷(§5.3 ④).
 *   - predict (lesson/checkpoint step, choice + starter): starter 가 컴파일·실행
 *       되는지 확인(깨진 예제 코드 차단).
 *   - fix_error: starter 가 실제로 컴파일 실패하는지(+ 에러 제목 기록).
 *   - tests (family solution*.gleam + runner_test): harness 로 전 테스트 통과 확인.
 *
 * 설계 노트: 원안은 "WASM-in-Node" 를 선호했다(브라우저와 자구까지 동일). 본 구현은
 * 동일 버전(1.17.0) 네이티브 바이너리를 쓴다 — 같은 컴파일러 소스라 진단 텍스트·JS
 * 타깃 코드젠이 동일하고, 순수 로직의 stdout 도 일치하므로 CI 골든 게이트로 충분하다.
 * (WASM-in-Node 바이트 동일성 검증은 후속 정밀화 — stdlib 주입+런타임 FFI 해소 필요.)
 *
 * 사용: node golden/verify.mjs --content ../content [--update]
 */

import { parse as parseToml } from "smol-toml";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { run, compile, errorTitle, parseProtocol, freshToken, PINNED_COMPILER } from "./gleam-runner.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));

function arg(name, def) {
  const i = process.argv.indexOf(name);
  if (i < 0) return def;
  const v = process.argv[i + 1];
  return v && !v.startsWith("--") ? v : true;
}
const CONTENT = path.resolve(process.cwd(), arg("--content", path.join(HERE, "..", "..", "content")));
const UPDATE = process.argv.includes("--update");

const results = [];
function record(id, kind, status, detail) { results.push({ id, kind, status, detail: detail || "" }); }
function readIf(p) { return fs.existsSync(p) ? fs.readFileSync(p, "utf8") : null; }
function trimOneNl(s) { return s.replace(/\n$/, ""); }
function normChoice(s) { return s.trim().replace(/^`+|`+$/g, "").trim(); }

// ── puzzle families ────────────────────────────────────────────────
function verifyFamilies() {
  const dir = path.join(CONTENT, "puzzles");
  if (!fs.existsSync(dir)) return;
  for (const fam of fs.readdirSync(dir)) {
    const tomlPath = path.join(dir, fam, "family.toml");
    if (!fs.existsSync(tomlPath)) continue;
    let meta;
    try { meta = parseToml(fs.readFileSync(tomlPath, "utf8")); }
    catch (e) { record(fam, "family", "fail", "family.toml parse: " + e.message); continue; }
    const ptype = meta.puzzle_type, grading = meta.grading;
    for (const variant of meta.variants || []) {
      const vDir = path.join(dir, fam, "variants", variant.id);
      const starter = readIf(path.join(vDir, "starter.gleam"));
      const id = `${fam}/${variant.id}`;
      if (ptype === "predict" && (grading === "choice" || grading === "exact_output")) {
        if (!starter) { record(id, "predict", "fail", "starter.gleam 없음"); continue; }
        const r = run([{ name: "solution", code: starter }], "solution");
        if (!r.ok) { record(id, "predict", "fail", "starter 실행 실패: " + (errorTitle(r.pretty) || "").slice(0, 80)); continue; }
        const out = r.stdout;
        const ansPath = path.join(vDir, "answer.txt");
        if (UPDATE) { fs.writeFileSync(ansPath, out); record(id, "predict", "update", "answer.txt ← " + JSON.stringify(trimOneNl(out))); continue; }
        const ans = readIf(ansPath);
        if (ans == null) { record(id, "predict", "fail", "answer.txt 없음 (--update 로 생성)"); continue; }
        if (trimOneNl(out) !== trimOneNl(ans)) { record(id, "predict", "fail", `스냅샷 불일치: got ${JSON.stringify(trimOneNl(out))} ≠ ${JSON.stringify(trimOneNl(ans))}`); continue; }
        if (grading === "choice") {
          const choices = (variant.choices || []).map(normChoice);
          const matches = choices.filter((c) => c === normChoice(trimOneNl(ans)));
          if (matches.length !== 1) { record(id, "predict", "fail", `choice 유일매칭 실패 (${matches.length}개)`); continue; }
        }
        record(id, "predict", "pass", `stdout=${JSON.stringify(trimOneNl(out))}`);
      } else if (grading === "tests") {
        const solutions = fs.existsSync(vDir) ? fs.readdirSync(vDir).filter((f) => /^solution.*\.gleam$/.test(f)) : [];
        const runnerTest = readIf(path.join(vDir, "runner_test.gleam"));
        if (!solutions.length || !runnerTest) { record(id, "tests", "fail", "solution*.gleam 또는 runner_test.gleam 없음"); continue; }
        const sol = readIf(path.join(vDir, solutions[0]));
        const tok = freshToken();
        const r = run([{ name: "solution", code: sol }, { name: "runner_test", code: runnerTest }], "runner_test", { withHarness: true, token: tok });
        if (!r.ok) { record(id, "tests", "fail", "컴파일/실행 실패: " + (errorTitle(r.pretty) || r.pretty || "").slice(0, 120)); continue; }
        const tr = parseProtocol(r.stdout, tok);
        const failed = tr.filter((t) => !t.passed);
        if (!tr.length) record(id, "tests", "fail", "테스트 결과 없음");
        else if (failed.length) record(id, "tests", "fail", `${failed.length}/${tr.length} 실패: ${failed.map((f) => f.name).join(", ")}`);
        else record(id, "tests", "pass", `${tr.length} 테스트 통과`);
      }
    }
  }
}

// ── lesson steps + checkpoint items (units/) ───────────────────────
function* iterUnitSteps() {
  const unitsDir = path.join(CONTENT, "units");
  if (!fs.existsSync(unitsDir)) return;
  for (const unit of fs.readdirSync(unitsDir)) {
    const uDir = path.join(unitsDir, unit);
    const lessonsDir = path.join(uDir, "lessons");
    if (fs.existsSync(lessonsDir)) {
      for (const lesson of fs.readdirSync(lessonsDir)) {
        const stepsDir = path.join(lessonsDir, lesson, "steps");
        if (!fs.existsSync(stepsDir)) continue;
        for (const sid of fs.readdirSync(stepsDir)) {
          const stepToml = path.join(stepsDir, sid, "step.toml");
          if (!fs.existsSync(stepToml)) continue;
          const step = parseToml(fs.readFileSync(stepToml, "utf8"));
          const starter = step.starter ?? readIf(path.join(stepsDir, sid, "starter.gleam"));
          yield { id: `${unit}/${lesson}/${sid}`, step, starter };
        }
      }
    }
    const cp = path.join(uDir, "checkpoint.toml");
    if (fs.existsSync(cp)) {
      const data = parseToml(fs.readFileSync(cp, "utf8"));
      for (const item of data.items || []) {
        if (!item.step) continue;
        yield { id: `${unit}/checkpoint/${item.step.id}`, step: item.step, starter: item.step.starter ?? null };
      }
    }
  }
}

function verifyUnits() {
  for (const { id, step, starter } of iterUnitSteps()) {
    const ptype = step.puzzle_type, grading = step.grading;
    if (ptype === "fix_error") {
      if (!starter) { record(id, "fix_error", "fail", "starter 없음"); continue; }
      const c = compile([{ name: "solution", code: starter }]);
      if (c.ok) record(id, "fix_error", "fail", "starter 가 컴파일됨 (fix_error 는 컴파일 실패해야)");
      else record(id, "fix_error", "pass", `컴파일 실패 확인: ${errorTitle(c.pretty) || "?"}`);
    } else if (ptype === "predict" && (grading === "choice" || grading === "exact_output")) {
      if (!starter) { record(id, "predict", "pass", "starter 없음 — 실행 skip"); continue; }
      const r = run([{ name: "solution", code: starter }], "solution");
      if (!r.ok) record(id, "predict", "fail", "starter 실행 실패: " + (errorTitle(r.pretty) || "").slice(0, 80));
      else record(id, "predict", "pass", `실행 OK, stdout=${JSON.stringify(trimOneNl(r.stdout))}`);
    } else {
      record(id, ptype || "?", "pass", `골든 무대상 (grading=${grading}) — skip`);
    }
  }
}

console.log(`[verify] 핀 컴파일러 gleam ${PINNED_COMPILER} · content=${CONTENT}${UPDATE ? " · --update" : ""}`);
verifyFamilies();
verifyUnits();

let pass = 0, fail = 0, upd = 0;
for (const r of results) {
  const sym = r.status === "pass" ? "✓" : r.status === "update" ? "↻" : "✗";
  if (r.status === "pass") pass++; else if (r.status === "update") upd++; else fail++;
  console.log(`  ${sym} [${r.kind}] ${r.id}${r.detail ? " — " + r.detail : ""}`);
}
console.log(`\n[verify] ${pass} pass, ${fail} fail${upd ? `, ${upd} updated` : ""}, total ${results.length}`);
process.exit(fail > 0 ? 1 : 0);
