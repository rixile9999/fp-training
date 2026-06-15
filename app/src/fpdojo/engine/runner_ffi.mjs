// runner_ffi.mjs — 일회용 러너 워커 스폰 + watchdog + 결과 파싱 (PLAN §5.2).
//
// fpdojo/engine/runner.gleam 의 @external 대상. 러너 워커는 실행마다 생성하고
// 정상/타임아웃 불문 무조건 terminate한다(architecture.md §3.5 — 상태 누수·
// console.log 몽키패치 잔존 없음). 동기 무한 꼬리 루프에는 terminate가
// 유일한 수단이다(R5).
//
// 워커 메시지 프로토콜 (priv/static/workers/runner.worker.js와 계약):
//   요청  { token: string, entry: string, modules: [{ name: string, js: string }] }
//   응답  { lines: string[], error: { name: string, message: string } | null }
//
// 하니스 stdout 프로토콜 (PLAN §5.2 — 채점 계약의 전부):
//   __<token>__|pass|<이름>
//   __<token>__|fail|<이름>|<메시지>     // 메시지에 '|' 가능 — 나머지를 join
// 토큰은 런마다 crypto 난수로 생성해(출력 스푸핑 1차 방어, R7) 워커에 전달하고,
// 워커가 유저 코드 import *이전에* globalThis.__FPDOJO_RUN_TOKEN__으로 주입한다.
//
// resolve 값 (raw — RunOutcome 디코드는 runner.gleam의 private 헬퍼 몫):
//   { kind: "completed", stdout: string[], tests: [{ name, passed, detail: string|null }] }
//   { kind: "timeout",   afterMs: number }
//   { kind: "crashed",   crashKind: "stack_overflow" | "other", message: string }
// RangeError("Maximum call stack size exceeded") → "stack_overflow"
// (PLAN §4.5 무한 재귀 이원 매핑의 1행 — 비-꼬리 재귀 경로).

const WORKER_URL = "/workers/runner.worker.js"; // priv/static 정적 루트 기준

function newToken() {
  // TODO: crypto.getRandomValues(new Uint32Array(4)) → 32자리 hex 문자열
  //       (런별 난수 — 유저 코드는 토큰을 모른 채 컴파일되므로 스푸핑 1차 방어)
  throw new Error("TODO");
}

function parseHarnessLines(lines, token) {
  // TODO 1: const prefix = `__${token}__|`
  // TODO 2: prefix로 시작하는 라인 → rest.split("|"): ["pass"|"fail", name, ...tail]
  //         pass → { name, passed: true,  detail: null }
  //         fail → { name, passed: false, detail: tail.join("|") }
  // TODO 3: 그 외 라인은 유저 stdout (io.println/echo 출력)으로 분리
  // TODO 4: return { stdout, tests }
  throw new Error("TODO");
}

/**
 * 워커 생성 → 실행 → 무조건 terminate. timeoutMs는 puzzle.toml의 timeout_ms
 * (기본 3000, write_fn 상한 5000, Rush 고정 3000 — PLAN §5.2).
 * modules는 Gleam List(CompiledModule) — toArray(), 필드는 .name / .js.
 * 이 Promise는 절대 reject하지 않는다 — 모든 실패도 raw 객체로 resolve.
 */
export function runModules(modules, entryModule, timeoutMs) {
  // TODO 1: const token = newToken();
  //         const arr = modules.toArray().map((m) => ({ name: m.name, js: m.js }))
  // TODO 2: const worker = new Worker(WORKER_URL, { type: "module" })
  // TODO 3: return new Promise((resolve) => { ... }) — watchdog:
  //         const t = setTimeout(() => { worker.terminate();
  //           resolve({ kind: "timeout", afterMs: timeoutMs }); }, timeoutMs)
  // TODO 4: worker.onmessage = (e) => { clearTimeout(t); worker.terminate();
  //           const { lines, error } = e.data;
  //           if (error) resolve({ kind: "crashed",
  //             crashKind: error.name === "RangeError" ? "stack_overflow" : "other",
  //             message: error.message });
  //           else resolve({ kind: "completed", ...parseHarnessLines(lines, token) }); }
  // TODO 5: worker.onerror — clearTimeout, terminate 후
  //         { kind: "crashed", crashKind: "other", message } 로 resolve
  // TODO 6: worker.postMessage({ token, entry: entryModule, modules: arr })
  throw new Error("TODO");
}
