// runner.worker.js — 일회용 러너 워커 (PLAN §5.2 듀얼 워커).
//
// 실행마다 메인스레드(src/fpdojo/engine/runner_ffi.mjs)가 새로 스폰하고,
// 응답 직후 또는 watchdog 타임아웃 시 무조건 terminate된다. WASM도 stdlib
// 쓰기도 없이 스크립트 로드뿐이라 respawn 비용은 수 ms(architecture.md §3.1).
//
// 메시지 프로토콜 (runner_ffi.mjs와 계약):
//   수신  { token: string, entry: string, modules: [{ name: string, js: string }] }
//   송신  { lines: string[], error: { name, message } | null }
//   — 하니스 프로토콜 라인(__<token>__|pass|… / …|fail|…|…)도 lines에 섞여
//     수집된다. 분리·파싱은 메인스레드(runner_ffi.parseHarnessLines) 몫.
//
// 샌드박싱 수위: same-origin Worker는 응답성 경계이지 보안 경계가 아니다 —
// 자기 코드만 실행하므로 수용, CSP connect-src 'self'가 fetch 남용 차단
// (architecture.md §3.6). 커뮤니티 퍼즐 도입 시 sandboxed iframe으로 격상.

self.onmessage = async (event) => {
  const { token, entry, modules } = event.data;
  const lines = [];
  let error = null;

  // TODO 1: 토큰 주입 — *어떤 동적 import보다 먼저*
  //         globalThis.__FPDOJO_RUN_TOKEN__ = token
  //         (harness_ffi.mjs가 읽어 __<token>__|… 프리픽스를 만든다.
  //          유저 코드는 토큰을 모른 채 컴파일되므로 출력 스푸핑 1차 방어 — R7)
  //
  // TODO 2: console.log 몽키패치 — 호출 인자를 문자열화해 lines에 누적
  //         (JS 타깃에서 io.println/io.debug/echo 출력이 전부 console.log 경유 —
  //          docs/research/gleam-in-browser.md. 워커가 일회용이라 패치 잔존 없음)
  //
  // TODO 3: import 재작성 ① stdlib — 각 모듈 js에 tour 패턴 정규식:
  //         js.replaceAll(/from\s+"\.\/(.+)"/g, `from "${self.location.origin}/precompiled/$1"`)
  //         — gleam.mjs(프렐류드)·gleam_stdlib .mjs/FFI·harness_ffi.mjs가
  //           /precompiled/ 정적 경로에서 해석된다(architecture.md §3.3)
  //
  // TODO 4: import 재작성 ② 모듈 간 — leaf-first 토폴로지 순서(architecture.md §3.4):
  //         entry가 아닌 모듈(solution, harness)을 먼저
  //         "data:text/javascript;base64," + b64(js) URL로 만들고,
  //         의존하는 모듈(runner_test)의 `"${origin}/precompiled/<name>.mjs"` 참조를
  //         그 data: URL로 치환한다 — tour의 단일 정규식만 쓰면 runner_test의
  //         `./solution.mjs`까지 /precompiled/로 잘못 가는 함정 회피.
  //         (harness.mjs의 ./harness_ffi.mjs는 /precompiled/ 서빙이 정답이므로
  //          ①의 재작성 결과를 그대로 둔다)
  //
  // TODO 5: base64는 유니코드 안전하게 — TextEncoder로 UTF-8 바이트화 후 btoa
  //         (한국어 테스트 이름·문자열 리터럴이 통과해야 한다)
  //
  // TODO 6: const mod = await import("data:text/javascript;base64," + b64(entryJs))
  //         — Gleam 산출 JS는 ES module이라 eval 불가(tour 패턴)
  //
  // TODO 7: try { mod.main() } catch (e) {
  //           error = { name: e?.name ?? "Error", message: e?.message ?? String(e) } }
  //         — RangeError("Maximum call stack size exceeded")는 메인스레드가
  //           stack_overflow(비-꼬리 무한 재귀)로 분류(PLAN §4.5 이원 매핑).
  //           꼬리 재귀 무한 루프는 여기서 안 잡힌다 — watchdog terminate가 유일 수단.
  //
  // TODO 8: self.postMessage({ lines, error }) — 이후 메인스레드가 terminate.
  throw new Error("TODO: 위 1~8 단계 구현");
};
