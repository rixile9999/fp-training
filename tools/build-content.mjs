#!/usr/bin/env node
/**
 * tools/build-content.mjs — 콘텐츠 빌더 (PLAN §5.3 ① + ③).
 *
 * content/ TOML 저작 트리 → app/priv/static/content/*.json 청크.
 * 앱(fpdojo/content/loader)은 이 산출물만 fetch하며 디코더 계약은
 * fpdojo/content/schema 와 1:1이다:
 *   priv/static/content/manifest.json              → schema.manifest_decoder
 *   priv/static/content/units/<unit_id>.json       → schema.unit_decoder
 *   priv/static/content/families/<family_id>.json  → schema.family_decoder
 *
 * 책임: ①(스키마/태그/선수 그래프/타입×채점 매트릭스 검증) + ③(JSON 청크 직렬화).
 * ②(컴파일 골든)·④(스냅샷 갱신)는 tools/golden/verify.mjs. CI: build → verify.
 *
 * 사용: node build-content.mjs --content ../content --out ../app/priv/static/content
 */

import { parse as parseToml } from "smol-toml";
import fs from "node:fs";
import path from "node:path";
import { argv, cwd, exit } from "node:process";

const CONTENT_VERSION = process.env.CONTENT_VERSION || "dev";
const COMPILER_VERSION = "1.17.0";

// 타입×채점 허용 매트릭스 — PLAN §4.1 표가 유일 기준.
const TYPE_GRADING = {
  predict: ["choice", "exact_output"],
  mcq: ["choice"],
  fill_hole: ["tests"],
  fix_error: ["tests"],
  write_fn: ["tests"],
  refactor: ["tests_lint"],
  parsons: ["parsons_order"],
  spot_bug: ["spot_two_stage"],
};
// 타임드 적합성 정합성 — PLAN §4.3.
function checkTimedFlags(fam, fail) {
  const t = fam.puzzle_type;
  if ((t === "write_fn" || t === "refactor") && (fam.rush_eligible || fam.streak_eligible)) {
    fail(`${fam.id}: ${t} 는 rush/streak_eligible=false 여야 함 (P5/P6, §4.3)`);
  }
  if (t === "fix_error" && fam.rush_eligible) fail(`${fam.id}: fix_error(P4) 는 rush_eligible=false (§4.3)`);
}

// ── ① TAG REGISTRY ─────────────────────────────────────────────────
export function loadTagRegistry(contentRoot) {
  const t = parseToml(fs.readFileSync(path.join(contentRoot, "registry", "tags.toml"), "utf8"));
  return {
    concepts: new Set((t.concept?.slugs) || []),
    tricky: new Set((t.tricky?.slugs) || []),
    aliases: t.alias || {},
  };
}
export function assertTagRegistered(tagKey, reg, fail, where) {
  const m = /^(concept|tricky):(.+)$/.exec(tagKey);
  if (!m) return fail(`${where}: 잘못된 태그 표기 "${tagKey}" (concept:|tricky: 접두 필요)`);
  const [, kind, slug] = m;
  const set = kind === "concept" ? reg.concepts : reg.tricky;
  if (set.has(slug)) return;
  if (reg.aliases[slug]) return fail(`${where}: 구 태그 "${slug}" 는 거부됨 — 캐논 "${reg.aliases[slug]}" 를 쓰세요 (alias)`);
  fail(`${where}: 미등록 태그 "${tagKey}" (tags.toml 에 추가하거나 오타 수정)`);
}

// ── ① PREREQ GRAPH ─────────────────────────────────────────────────
export function assertPrerequisitesAcyclic(unitMetas, fail) {
  const ids = new Set(unitMetas.map((u) => u.id));
  const adj = new Map();
  for (const u of unitMetas) {
    for (const p of u.prerequisites || []) {
      if (!ids.has(p)) fail(`${u.id}: 존재하지 않는 선수 유닛 "${p}"`);
    }
    adj.set(u.id, (u.prerequisites || []).filter((p) => ids.has(p)));
  }
  const state = new Map(); // 0=unseen,1=onstack,2=done
  const stack = [];
  function dfs(n) {
    state.set(n, 1); stack.push(n);
    for (const m of adj.get(n) || []) {
      if (state.get(m) === 1) return fail(`선수 그래프 사이클: ${[...stack, m].join(" -> ")}`);
      if (!state.get(m)) dfs(m);
    }
    stack.pop(); state.set(n, 2);
  }
  for (const u of unitMetas) if (!state.get(u.id)) dfs(u.id);
}

export function assertTypeGradingAllowed(fam, fail) {
  const allowed = TYPE_GRADING[fam.puzzle_type];
  if (!allowed) return fail(`${fam.id}: 알 수 없는 puzzle_type "${fam.puzzle_type}"`);
  if (!allowed.includes(fam.grading)) fail(`${fam.id}: ${fam.puzzle_type} × ${fam.grading} 조합 금지 (허용: ${allowed.join("|")}, §4.1)`);
  checkTimedFlags(fam, fail);
}

// ── helpers ─────────────────────────────────────────────────────────
const readIf = (p) => (fs.existsSync(p) ? fs.readFileSync(p, "utf8") : null);
const trimNl = (s) => (s == null ? s : s.replace(/\n$/, ""));

function tagsOf(obj) { return (obj && obj.tags) || (obj && obj.emits_tags) || []; }

// ── ③ CHUNK BUILDERS ───────────────────────────────────────────────
export function buildFamilyChunk(famDir, reg, fail) {
  const meta = parseToml(fs.readFileSync(path.join(famDir, "family.toml"), "utf8"));
  assertTypeGradingAllowed(meta, fail);
  for (const tag of [meta.primary_theme, ...(meta.themes || [])]) assertTagRegistered(tag, reg, fail, `family ${meta.id}`);
  const variants = (meta.variants || []).map((v) => {
    const vDir = path.join(famDir, "variants", v.id);
    const starter = readIf(path.join(vDir, "starter.gleam")) || "";
    const ans = trimNl(readIf(path.join(vDir, "answer.txt")));
    let answer = null;
    if (meta.grading === "choice" && ans != null) {
      const idxs = (v.choices || []).map((c, i) => [c.trim().replace(/^`+|`+$/g, "").trim(), i])
        .filter(([c]) => c === ans.trim()).map(([, i]) => i);
      if (idxs.length !== 1) fail(`family ${meta.id}/${v.id}: answer.txt↔choices 유일 매칭 실패 (${idxs.length}개)`);
      else answer = String(idxs[0]);
    }
    return {
      id: v.id, prompt_md: readIf(path.join(vDir, "prompt.md")) || "",
      starter, choices: v.choices || [], answer,
      runner_test: readIf(path.join(vDir, "runner_test.gleam")),
    };
  });
  return {
    id: meta.id, puzzle_type: meta.puzzle_type, grading: meta.grading,
    primary_theme: meta.primary_theme, themes: meta.themes || [],
    seed_tier: meta.seed_tier, compiler_version: meta.compiler_version || COMPILER_VERSION,
    variants,
  };
}

export function buildUnitChunk(unitDir, reg, fail) {
  const meta = parseToml(fs.readFileSync(path.join(unitDir, "unit.toml"), "utf8"));
  for (const tag of meta.concepts || []) assertTagRegistered(tag, reg, fail, `unit ${meta.id}`);
  const lessons = [];
  const lessonsDir = path.join(unitDir, "lessons");
  if (fs.existsSync(lessonsDir)) {
    for (const lid of fs.readdirSync(lessonsDir)) {
      const lDir = path.join(lessonsDir, lid);
      const lmeta = parseToml(fs.readFileSync(path.join(lDir, "lesson.toml"), "utf8"));
      for (const tag of lmeta.emits_tags || []) assertTagRegistered(tag, reg, fail, `lesson ${lmeta.id}`);
      const segments = parseSegments(readIf(path.join(lDir, "prose.ko.md")) || "");
      const blocks = (lmeta.blocks || []).map((b) => {
        if (b.kind === "prose") {
          if (!(b.segment_id in segments)) fail(`lesson ${lmeta.id}: prose 세그먼트 "${b.segment_id}" 없음`);
          return { kind: "prose", segment_id: b.segment_id, markdown: segments[b.segment_id] || "" };
        }
        const sDir = path.join(lDir, "steps", b.step_id);
        const step = parseToml(fs.readFileSync(path.join(sDir, "step.toml"), "utf8"));
        for (const tag of step.tags || []) assertTagRegistered(tag, reg, fail, `step ${step.id}`);
        return { kind: "exercise", step: { ...step, starter: step.starter ?? readIf(path.join(sDir, "starter.gleam")) ?? "" } };
      });
      lessons.push({ id: lmeta.id, unit_id: lmeta.unit_id, title: lmeta.title, emits_tags: lmeta.emits_tags || [], srs_items: lmeta.srs_items || [], blocks });
    }
  }
  const cp = readIf(path.join(unitDir, "checkpoint.toml"));
  const checkpoint = cp ? parseToml(cp) : null;
  return { meta, lessons, checkpoint };
}

function parseSegments(md) {
  const out = {};
  let cur = null, buf = [];
  for (const line of md.split("\n")) {
    const m = /^<!--\s*segment:\s*(\S+)\s*-->/.exec(line);
    if (m) { if (cur) out[cur] = buf.join("\n").trim(); cur = m[1]; buf = []; }
    else buf.push(line);
  }
  if (cur) out[cur] = buf.join("\n").trim();
  return out;
}

export function buildManifest(unitMetas, reg, contentVersion) {
  return {
    content_version: contentVersion, compiler_version: COMPILER_VERSION,
    units: unitMetas.map((m) => ({ id: m.id, title: m.title, order: m.order, level: m.level, concepts: m.concepts || [], prerequisites: m.prerequisites || [], lesson_ids: m.lesson_ids || [] })),
    tags: { concepts: [...reg.concepts], tricky: [...reg.tricky], aliases: reg.aliases },
  };
}

// ── main ────────────────────────────────────────────────────────────
export async function main(args) {
  const get = (n, d) => { const i = args.indexOf(n); return i >= 0 && args[i + 1] ? args[i + 1] : d; };
  const contentRoot = path.resolve(cwd(), get("--content", "content"));
  const outRoot = path.resolve(cwd(), get("--out", "app/priv/static/content"));
  const errors = [];
  const fail = (m) => errors.push(m);

  const reg = loadTagRegistry(contentRoot);

  // units
  const unitsDir = path.join(contentRoot, "units");
  const unitChunks = [];
  if (fs.existsSync(unitsDir)) {
    for (const uid of fs.readdirSync(unitsDir).sort()) {
      if (!fs.existsSync(path.join(unitsDir, uid, "unit.toml"))) continue;
      unitChunks.push(buildUnitChunk(path.join(unitsDir, uid), reg, fail));
    }
  }
  assertPrerequisitesAcyclic(unitChunks.map((u) => u.meta), fail);

  // families
  const puzzlesDir = path.join(contentRoot, "puzzles");
  const familyChunks = [];
  if (fs.existsSync(puzzlesDir)) {
    for (const fid of fs.readdirSync(puzzlesDir).sort()) {
      if (!fs.existsSync(path.join(puzzlesDir, fid, "family.toml"))) continue;
      familyChunks.push(buildFamilyChunk(path.join(puzzlesDir, fid), reg, fail));
    }
  }

  if (errors.length) {
    console.error(`[build-content] ✗ ${errors.length} 검증 오류:`);
    for (const e of errors) console.error("  - " + e);
    return 1;
  }

  // ③ emit
  fs.mkdirSync(path.join(outRoot, "units"), { recursive: true });
  fs.mkdirSync(path.join(outRoot, "families"), { recursive: true });
  const manifest = buildManifest(unitChunks.map((u) => u.meta), reg, CONTENT_VERSION);
  fs.writeFileSync(path.join(outRoot, "manifest.json"), JSON.stringify(manifest, null, 2));
  for (const u of unitChunks) fs.writeFileSync(path.join(outRoot, "units", u.meta.id + ".json"), JSON.stringify(u, null, 2));
  for (const f of familyChunks) fs.writeFileSync(path.join(outRoot, "families", f.id + ".json"), JSON.stringify(f, null, 2));

  console.log(`[build-content] ✓ ${unitChunks.length} units, ${familyChunks.length} families → ${path.relative(cwd(), outRoot)}`);
  console.log(`  tags: ${reg.concepts.size} concepts, ${reg.tricky.size} tricky · content_version=${CONTENT_VERSION} · compiler=${COMPILER_VERSION}`);
  return 0;
}

main(argv.slice(2)).then(exit);
