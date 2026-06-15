// gleam-runner.mjs — 골든 오라클의 컴파일/실행 드라이버 (PLAN §5.3 ②).
//
// 핀 gleam 1.17.0 바이너리(tools/golden/bin)를 재사용 오라클 프로젝트
// (tools/golden/oracle-proj, target=javascript, gleam_stdlib 1.0.3)에 대해 구동한다.
// 브라우저는 동일 버전의 WASM 컴파일러로 같은 코드를 컴파일/실행하므로(같은 JS 타깃
// 코드젠 + 같은 stdlib) predict 출력·테스트 결과가 일치한다. WASM-in-Node 변형(브라우저
// 바이트 동일성)은 후속 정밀화이며, 본 CLI 오라클이 CI 골든 게이트로 충분히 동작한다.

import { execFileSync } from "node:child_process";
import { randomBytes } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, "..", "..");

export const GLEAM = path.join(HERE, "bin", "gleam-1.17.0");
export const ORACLE = path.join(HERE, "oracle-proj");
const ORACLE_SRC = path.join(ORACLE, "src");
const HARNESS_GLEAM = path.join(REPO, "app", "priv", "static", "harness", "harness.gleam");
const HARNESS_FFI = path.join(REPO, "app", "priv", "static", "harness", "harness_ffi.mjs");

export const PINNED_COMPILER = "1.17.0";

function resetSrc() {
  fs.mkdirSync(ORACLE_SRC, { recursive: true });
  for (const f of fs.readdirSync(ORACLE_SRC)) fs.rmSync(path.join(ORACLE_SRC, f), { force: true });
}

function writeModules(modules, withHarness) {
  resetSrc();
  for (const m of modules) {
    fs.writeFileSync(path.join(ORACLE_SRC, m.name + ".gleam"), m.code);
  }
  if (withHarness) {
    fs.copyFileSync(HARNESS_GLEAM, path.join(ORACLE_SRC, "harness.gleam"));
    fs.copyFileSync(HARNESS_FFI, path.join(ORACLE_SRC, "harness_ffi.mjs"));
  }
}

/** Compile only (no run). Returns {ok} or {ok:false, pretty}. */
export function compile(modules, { withHarness = false } = {}) {
  writeModules(modules, withHarness);
  try {
    execFileSync(GLEAM, ["build", "--target", "javascript"], {
      cwd: ORACLE, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"],
    });
    return { ok: true };
  } catch (e) {
    const pretty = (e.stderr || "") + (e.stdout || "");
    return { ok: false, pretty: pretty.trim() };
  }
}

/** Compile + run a module's main(). Returns {ok, stdout} or {ok:false, pretty}. */
export function run(modules, entry, { withHarness = false, token } = {}) {
  writeModules(modules, withHarness);
  const env = { ...process.env };
  if (token) env.FPDOJO_RUN_TOKEN = token;
  try {
    const stdout = execFileSync(GLEAM, ["run", "--target", "javascript", "-m", entry], {
      cwd: ORACLE, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], env,
    });
    return { ok: true, stdout };
  } catch (e) {
    // Distinguish compile failure (gleam error on stderr) from runtime crash.
    return { ok: false, pretty: ((e.stderr || "") + (e.stdout || "")).trim(), stdout: e.stdout || "" };
  }
}

/** First-line `error: <title>` category from a pretty compiler error. */
export function errorTitle(pretty) {
  const m = (pretty || "").match(/error:\s*(.+)/);
  return m ? m[1].trim() : null;
}

/** Parse the harness stdout token protocol → [{name, passed, detail}]. */
export function parseProtocol(stdout, token) {
  const prefix = `__${token}__|`;
  const results = [];
  for (const line of (stdout || "").split("\n")) {
    if (!line.startsWith(prefix)) continue; // non-protocol lines = user stdout
    const rest = line.slice(prefix.length).split("|");
    const verdict = rest[0];
    const name = rest[1];
    if (verdict === "pass") results.push({ name, passed: true, detail: null });
    else if (verdict === "fail") results.push({ name, passed: false, detail: rest.slice(2).join("|") });
  }
  return results;
}

export function freshToken() {
  return randomBytes(16).toString("hex");
}
