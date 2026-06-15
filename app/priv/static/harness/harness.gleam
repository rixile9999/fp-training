//// 채점 하니스 (PLAN §5.2 채점 하니스 단일화, architecture.md §3.8).
////
//// ⚠ 이 모듈은 앱 빌드에 포함되지 않는다 — 브라우저의 컴파일 워커
//// (compiler.worker.js)가 부팅 시 WASM 프로젝트에 "harness" 모듈로 자동
//// 주입해, 유저 코드(solution)·히든 테스트(runner_test)와 함께 브라우저에서
//// 컴파일된다. 저자의 runner_test.gleam은 main()에서
//// harness.suite([harness.check("이름", fn() { assert ... }), ...])를 호출한다.
//// (`test` 는 gleam 1.17 예약어라 케이스 생성자는 `check` 다.)
////
//// 채점 계약은 stdout 프로토콜이 전부다(PLAN §5.2):
////   __<런별 난수 토큰>__|pass|<이름>
////   __<런별 난수 토큰>__|fail|<이름>|<메시지>
//// 토큰은 runner_ffi.mjs가 런마다 난수 생성 → runner.worker.js가 import 전에
//// globalThis로 주입 → harness_ffi.mjs가 읽어 프리픽스 생성(스푸핑 1차 방어).
//// 라인 파싱은 runner_ffi.mjs — 내부 결과 스키마는 Exercism results.json v2
//// 호환(M3 서버 러너 대비).
////
//// "./harness_ffi.mjs" 참조는 러너 워커의 import 재작성으로
//// /precompiled/harness_ffi.mjs 에서 해석된다(architecture.md §3.3~3.4).

import gleam/list

/// 단일 테스트 케이스: 이름 + 본문. 본문 안의 `assert` 실패(JS 타깃에서는
/// 예외)는 rescue FFI가 잡아 fail 라인으로 변환한다. "긴 리스트" 입력으로
/// 스택 오버플로를 유도해 꼬리 재귀 여부를 행동적으로 채점할 수도 있다
/// (architecture.md §3.8 — RangeError가 fail 메시지로 잡힘).
pub type Test {
  Test(name: String, body: fn() -> Nil)
}

/// 테스트 케이스 생성자.
/// (이름이 `check` 인 이유: `test` 는 gleam 1.17 예약어라 함수명으로 못 쓴다 —
///  골든 오라클이 핀 컴파일러로 잡아낸 제약. 저자는 `harness.check(...)` 를 쓴다.)
pub fn check(name: String, body: fn() -> Nil) -> Test {
  Test(name: name, body: body)
}

/// JS 타깃 assert 실패(예외)를 잡는 FFI (architecture.md §3.8).
/// assert 실패 객체의 구조화 필드(left/right 값)는 *존재할 경우에만* 메시지
/// 보강에 쓴다 — 존재 여부는 1.17.0 골든에서 확인하며 계약은 어디까지나
/// stdout 프로토콜이다(PLAN §5.2).
@external(javascript, "./harness_ffi.mjs", "rescue")
fn rescue(body: fn() -> Nil) -> Result(Nil, String)

/// pass 라인 방출: __<토큰>__|pass|<이름>
@external(javascript, "./harness_ffi.mjs", "emitPass")
fn emit_pass(name: String) -> Nil

/// fail 라인 방출: __<토큰>__|fail|<이름>|<메시지>
@external(javascript, "./harness_ffi.mjs", "emitFail")
fn emit_fail(name: String, message: String) -> Nil

/// 테스트들을 순서대로 실행하고 per-test 프로토콜 라인을 방출한다.
/// 한 테스트의 실패가 다음 테스트 실행을 막지 않는다(per-test 판정 —
/// PLAN §4.1 tests 채점).
pub fn suite(tests: List(Test)) -> Nil {
  list.each(tests, fn(t) {
    case rescue(t.body) {
      Ok(_) -> emit_pass(t.name)
      Error(message) -> emit_fail(t.name, message)
    }
  })
}
