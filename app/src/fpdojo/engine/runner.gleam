//// 일회용 러너 워커 포트 (PLAN §5.2 듀얼 워커).
////
//// 역할: 실행마다 runner.worker.js를 새로 스폰하고, 정상 종료든 타임아웃이든
//// **무조건 terminate**한다 — 상태 누수·console.log 몽키패치 잔존 없음
//// (architecture.md §3.5). 무한루프는 런타임에만 발생하고 러너는 WASM도
//// stdlib 쓰기도 없으므로 respawn 비용은 수 ms — 비싼 컴파일 워커 대신
//// 싼 러너만 죽인다(R5 완화의 핵심).
////
//// 하니스 stdout 프로토콜(PLAN §5.2): 워커가 캡처한 라인 중
//// `__<런별 난수 토큰>__|pass|이름` / `__<토큰>__|fail|이름|메시지` 를
//// FFI가 파싱해 TestReport로, 나머지 라인은 유저 stdout으로 분리한다.
//// 토큰은 런마다 FFI가 난수 생성(출력 스푸핑 1차 방어 — R7. 클라이언트
//// 채점은 본질적으로 신뢰 기반, 공개 경쟁은 M3 서버 재검증 후).
////
//// 의존 방향: engine/compiler(CompiledModule)만 import.
//// engine/grading·engine/error_explain이 이 모듈을 사용한다.
////
//// FFI: ./runner_ffi.mjs ↔ /workers/runner.worker.js

import fpdojo/engine/compiler
import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise
import gleam/option

/// 런타임 크래시 분류 (PLAN §4.5 무한 재귀 이원 피드백 매핑).
///
/// - StackOverflow: JS `RangeError: Maximum call stack size exceeded` —
///   비-꼬리 무한 재귀 또는 깊은 비-꼬리 재귀. 즉시 발생하므로 watchdog보다
///   먼저 잡힌다(U5-③ `first + total(xs)` 류는 이 경로).
/// - OtherCrash: 그 외 런타임 예외(panic, let assert 실패 등).
pub type CrashKind {
  StackOverflow
  OtherCrash
}

/// 하니스 프로토콜 1라인의 파싱 결과 (per-test 판정).
/// detail은 fail 라인의 메시지 — assert 실패의 기대/실제값이 들어올 수 있다.
/// 내부 스키마는 Exercism results.json v2 호환(M3 서버 러너 대비 — PLAN §5.2).
pub type TestReport {
  TestReport(name: String, passed: Bool, detail: option.Option(String))
}

/// 1회 실행의 결과.
///
/// - RunCompleted: entry의 main()이 정상 반환. stdout은 하니스 라인을 제외한
///   유저 출력(io.println/echo — console.log 몽키패치 캡처), tests는 하니스
///   프로토콜 파싱 결과(테스트 없는 실행이면 빈 리스트).
/// - RunTimedOut: watchdog이 worker.terminate() — 꼬리 재귀 무한 루프 경로.
///   채점상 오답이며 types.Outcome.TimedOut으로의 매핑은 grading의 몫.
/// - RunCrashed: 런타임 예외 — kind 분류는 위 CrashKind 참조.
pub type RunOutcome {
  RunCompleted(stdout: List(String), tests: List(TestReport))
  RunTimedOut(after_ms: Int)
  RunCrashed(kind: CrashKind, message: String)
}

/// 워커 생성 → 실행 → 무조건 terminate (PLAN §5.2).
///
/// - modules: 컴파일 워커 산출물(solution/runner_test/harness 등). import
///   재작성(stdlib → /precompiled/, 모듈 간 → data: URL leaf-first)은 워커 몫.
/// - entry_module: main()을 호출할 모듈 — 채점은 "runner_test",
///   exact_output(predict)은 "solution".
/// - timeout_ms: puzzle.toml의 timeout_ms — 기본 3000, write_fn 상한 5000,
///   Rush 고정 3000(PLAN §5.2). 하니스 토큰은 런별 난수 생성(FFI).
/// - 이 Promise는 reject하지 않는다 — 모든 실패가 RunOutcome으로 정규화된다.
pub fn run(
  modules: List(compiler.CompiledModule),
  entry_module: String,
  timeout_ms: Int,
) -> promise.Promise(RunOutcome) {
  todo as "ffi_run 호출 후 raw 결과 객체를 RunOutcome으로 디코드"
}

/// FFI 경계 디코드 헬퍼: runner_ffi가 resolve하는 raw 객체
/// {kind:"completed"|"timeout"|"crashed", ...}를 RunOutcome으로.
/// crashKind "stack_overflow" → StackOverflow, 그 외 → OtherCrash.
fn decode_run_outcome(raw: Dynamic) -> RunOutcome {
  todo as "러너 raw 결과 dynamic을 RunCompleted/RunTimedOut/RunCrashed로 디코드"
}

@external(javascript, "./runner_ffi.mjs", "runModules")
fn ffi_run(
  modules: List(compiler.CompiledModule),
  entry_module: String,
  timeout_ms: Int,
) -> promise.Promise(Dynamic)
