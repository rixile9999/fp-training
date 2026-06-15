//// 컴파일 워커 포트 — 장수명 compiler.worker.js와의 Promise 경계 (PLAN §5.2 듀얼 워커).
////
//// 역할:
//// - 유저 코드는 이 워커에서 절대 실행되지 않는다(컴파일 전용). 따라서 워커를
////   장수명으로 유지해 WASM init + stdlib ~50모듈 write_module 비용을 1회만 지불한다.
//// - solution(+runner_test)을 받으면 워커가 harness.gleam을 자동 주입해 함께
////   컴파일한다(PLAN §5.2 채점 하니스 단일화 — 모듈명 solution/runner_test/harness 통일).
//// - 인터페이스는 message-passing 형태로 고정한다 — 커뮤니티 퍼즐 도입 시 러너를
////   sandboxed iframe으로 격상해도 이 포트는 그대로(architecture.md §3.6, R2 격리).
////
//// 의존 방향(interfaces.md 의존 그래프): core/types만 import.
//// engine/runner → engine/grading이 이 모듈을 사용한다 — 역방향 import 금지.
////
//// FFI: ./compiler_ffi.mjs (콜로케이션) ↔ /workers/compiler.worker.js
//// 프로토콜: {id, type:"init"|"compile", modules:[{name,code}]} →
////           {id, ok:true, modules:[{name,js}], warnings:[]} | {id, ok:false, pretty}

import fpdojo/core/types
import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise
import gleam/option

/// 컴파일 입력 1모듈. name은 "solution" / "runner_test" 로 통일(PLAN §5.2).
/// code는 Gleam 소스 전문 — 워커가 write_module(pid, name, code)로 기록한다.
pub type SourceModule {
  SourceModule(name: String, code: String)
}

/// 컴파일 산출 1모듈. js는 ES module 텍스트 — eval 불가하므로 러너가
/// base64 data: URL import로 실행한다(architecture.md §3.4).
pub type CompiledModule {
  CompiledModule(name: String, js: String)
}

/// 컴파일 실패 — pretty는 컴파일러 평문 출력 원문 보존(ANSI 없음).
/// "에러 독해가 곧 커리큘럼"이므로 원문을 자르지 않는다(PLAN §4.5 2단 표시의 1면).
///
/// - spans: `src/\w+\.gleam:L:C` 정규식 추출 — CodeMirror 인라인 마커용.
/// - category: 첫 줄 "error: <제목>" 추출 — 에러 번역 사전 조회 키(PLAN §4.5).
///   추출 규칙은 engine/error_explain과 동일한 텍스트 계약이며 골든 테스트가
///   파서를 보호한다(R3 — 깨지면 그때 compiler-wasm 포크).
pub type CompileFailure {
  CompileFailure(
    pretty: String,
    spans: List(types.Span),
    category: option.Option(String),
  )
}

/// 컴파일 결과. CompileOk의 modules에는 요청 모듈 + 자동 주입된 harness가
/// 포함된다(PLAN §5.2: read_compiled_javascript × [solution, runner_test, harness]).
/// warnings는 pop_warning 드레인 결과(평문).
pub type CompileOutcome {
  CompileOk(modules: List(CompiledModule), warnings: List(String))
  CompileFailed(failure: CompileFailure)
  /// 컴파일러 자체 이상 — 워커 panic 또는 안전망 watchdog 30s 초과
  /// (PLAN §5.2: 이때만 풀 respawn). 유저 코드 문제가 아니므로
  /// CompileFailed와 구분해 "다시 시도" UI로 안내한다.
  CompileCrashed(message: String)
}

/// WASM 컴파일러 lazy-load + 컴파일 워커 부팅 (PLAN §5.2).
///
/// - 첫 인터랙티브 연습 진입 시점에 호출한다 — 레슨 prose·predict/choice형은
///   컴파일러 없이 동작하므로 앱 셸 초기 로드는 가볍게 유지(architecture.md §3.2).
/// - 워커 내부: gleam_wasm.js(?v=1.17.0 캐시버스터) import → wasm init →
///   initialise_panic_hook → stdlib 소스 write_module + harness.gleam 주입.
/// - 멱등: 이미 초기화됐으면 즉시 Ok(Nil). 실패 시 Error(사람이 읽을 메시지).
pub fn init() -> promise.Promise(Result(Nil, String)) {
  todo as "ffi_init 응답을 Result(Nil, String)으로 매핑하고 중복 호출 멱등성을 보장"
}

/// 소스 모듈들을 JS 타깃으로 컴파일 (PLAN §5.2).
///
/// - modules는 보통 [solution] 또는 [solution, runner_test]. harness는 호출자가
///   넣지 않는다 — 워커가 자동 주입(PLAN §5.2 채점 하니스).
/// - 성공: 요청 모듈 + harness의 컴파일 JS와 경고 목록.
/// - 실패: pretty 원문 + 추출 스팬/카테고리(위 CompileFailure 계약).
/// - 워커 panic·안전망 watchdog 30s 초과 시에도 reject하지 않고
///   CompileCrashed로 정규화한다(Promise는 항상 resolve).
pub fn compile(modules: List(SourceModule)) -> promise.Promise(CompileOutcome) {
  todo as "ffi_compile 호출 후 워커 프로토콜 응답을 CompileOutcome으로 디코드"
}

/// FFI 경계 디코드 헬퍼: 워커 응답 {ok:true, modules, warnings} |
/// {ok:false, pretty}를 CompileOutcome으로. pretty에서 spans/category도 추출.
fn decode_outcome(raw: Dynamic) -> CompileOutcome {
  todo as "워커 응답 dynamic을 CompileOk/CompileFailed로 디코드하고 스팬·카테고리 추출"
}

@external(javascript, "./compiler_ffi.mjs", "initCompiler")
fn ffi_init() -> promise.Promise(Dynamic)

@external(javascript, "./compiler_ffi.mjs", "compileModules")
fn ffi_compile(modules: List(SourceModule)) -> promise.Promise(Dynamic)
