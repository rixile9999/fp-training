// compiler.worker.js — 장수명 컴파일 워커 (PLAN §5.2 듀얼 워커).
//
// 유저 코드를 절대 실행하지 않는다 — 컴파일 전용. 따라서 무한루프로 죽을 일이
// 없고, WASM init + stdlib ~50모듈 write_module 비용을 부팅 시 1회만 지불한다.
// 러너와 분리하는 이유: 무한루프는 런타임에만 발생하므로 비싼 이 워커는
// 살려 두고 싼 러너 워커만 죽인다(architecture.md §3.1).
//
// 메시지 프로토콜 (interfaces.md "JS 자산" — src/fpdojo/engine/compiler_ffi.mjs와 계약):
//   수신  { id, type: "init" }
//        { id, type: "compile", modules: [{ name, code }] }
//   송신  { id, ok: true,  modules: [{ name, js }], warnings: string[] }
//        { id, ok: false, pretty: string }     // pretty 평문 원문 (ANSI 없음)
//
// WASM JS API — 정확한 이름은 compiler-wasm/src/lib.rs 기준
// (docs/research/gleam-in-browser.md; 프로젝트 id 스코프 인메모리 파일시스템):
//   initialise_panic_hook(debug)
//   write_module(project_id, module_name, code)            // /src에 기록
//   compile_package(project_id, "javascript") -> Result<(), String>
//   read_compiled_javascript(project_id, module_name) -> Option<String>
//   reset_warnings(project_id) / pop_warning(project_id) -> Option<String>
//   (reset_filesystem, delete_project 등도 존재 — write_module은 덮어쓰기라 보통 불필요)
//
// R2 격리: WASM API 접점은 이 파일 단일 어댑터로 한정한다. 업그레이드는
// 핀 bump + 전 골든 재검증 절차로만(PLAN §5.3 ④).

const COMPILER_VERSION = "1.17.0"; // 핀 고정 (PLAN 머리말) — ?v= 캐시버스터 키
const PROJECT_ID = 0;

let wasm = null; // init 후의 gleam_wasm.js 모듈

async function handleInit() {
  // TODO 1: wasm = await import(`/compiler/gleam_wasm.js?v=${COMPILER_VERSION}`)
  //         — gleam-v1.17.0-browser.tar.gz(wasm-pack --target web 산출물:
  //           gleam_wasm.js glue + gleam_wasm_bg.wasm)를 자체 미러에서 정적 서빙.
  // TODO 2: await wasm.default()                       // wasm-pack init
  // TODO 3: wasm.initialise_panic_hook(false)
  // TODO 4: 빌드 산출물 stdlib.js(모듈명→소스 맵, tour의 generate_stdlib_bundle
  //         패턴 — deprecated 모듈 제외) import 후 모듈마다
  //         wasm.write_module(PROJECT_ID, name, source)  // ~50모듈, 1회만 지불
  // TODO 5: 하니스 자동 주입 — priv/static/harness/harness.gleam 소스를
  //         wasm.write_module(PROJECT_ID, "harness", harnessSource)
  //         (PLAN §5.2 채점 하니스: 모든 채점 컴파일에 자동 주입, 모듈명 "harness")
  throw new Error("TODO");
}

function handleCompile(modules) {
  // TODO 1: wasm.reset_warnings(PROJECT_ID)
  // TODO 2: 각 { name, code }에 wasm.write_module(PROJECT_ID, name, code)
  //         — 모듈명은 "solution" / "runner_test" 통일(PLAN §5.2)
  // TODO 3: wasm.compile_package(PROJECT_ID, "javascript")
  //         — Err(prettyText)는 wasm-bindgen 경계에서 throw로 나타날 수 있음:
  //           language-tour static/compiler.js 참조로 확정 후 try/catch로 수거
  // TODO 4: 요청 모듈명 + "harness" 각각
  //         wasm.read_compiled_javascript(PROJECT_ID, name) → { name, js }
  //         (PLAN §5.2: read_compiled_javascript × [solution, runner_test, harness])
  // TODO 5: pop_warning 드레인 —
  //         let w; const warnings = [];
  //         while ((w = wasm.pop_warning(PROJECT_ID)) !== undefined) warnings.push(w)
  //         (Option<String> → None은 JS에서 undefined)
  // TODO 6: return { ok: true, modules: compiled, warnings }
  //         컴파일 에러면 { ok: false, pretty } 반환
  throw new Error("TODO");
}

// onmessage 디스패치 골격 — id 상관관계는 그대로 되돌려준다.
self.onmessage = async (event) => {
  const { id, type, modules } = event.data;
  try {
    switch (type) {
      case "init": {
        await handleInit();
        self.postMessage({ id, ok: true, modules: [], warnings: [] });
        break;
      }
      case "compile": {
        const result = handleCompile(modules);
        self.postMessage({ id, ...result });
        break;
      }
      default:
        self.postMessage({ id, ok: false, pretty: `unknown message type: ${type}` });
    }
  } catch (e) {
    // 컴파일 에러(pretty)·워커 내부 실패를 같은 실패 응답으로 정규화.
    // 컴파일러 panic으로 응답 자체가 불가능한 경우는 메인스레드의
    // 안전망 watchdog 30s가 풀 respawn한다(compiler_ffi.mjs).
    self.postMessage({ id, ok: false, pretty: String(e?.message ?? e) });
  }
};
