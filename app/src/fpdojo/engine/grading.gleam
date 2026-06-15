//// 채점 디스패치 — grading 6종 (PLAN §4.1 통합 퍼즐 타입 레지스트리).
////
//// types.Grading × types.Submission 조합을 받아 비동기 채점한다:
////
//// - Choice        : 선택지 인덱스 비교(컴파일 불필요, 동기) → ChoiceDetail
//// - ExactOutput   : solution 컴파일·실행 stdout을 answer 스냅샷과 정확 비교
////                   → OutputDetail (predict 자유입력형도 answer 문자열 비교 —
////                   answer는 CI 골든이 실행으로 고정한 스냅샷, PLAN §5.3 ②)
//// - Tests         : solution+runner_test 컴파일·실행, 하니스 per-test 판정
////                   → TestsDetail
//// - TestsLint     : Tests + 구조 린트(예: `|>` 3회 이상 — P6 refactor)
////                   → LintDetail
//// - ParsonsOrder  : 줄 배치 조립 → 컴파일 → 테스트. 순서만 채점하고 인덴트는
////                   저작분 유지, 컴파일+테스트 통과하는 임의 순서 인정
////                   (PLAN §4.1 Parsons 인덴테이션 확정)
//// - SpotTwoStage  : 1단계 스팬 클릭(동기 판정) → 2단계 수정 테스트(P8)
////
//// Choice/ExactOutput(선택지형)·Span 1단계는 동기 판정이지만 인터페이스는
//// Promise로 통일한다(interfaces.md). 컴파일 실패는 CompileErrorDetail,
//// watchdog 타임아웃은 types.TimedOut, RangeError는 즉시 오답 처리(PLAN §4.2).
////
//// 의존 방향: content/schema, core/types, engine/compiler, engine/runner를
//// import. session/* 가 이 모듈을 사용한다 — 역방향 import 금지.

import fpdojo/content/schema
import fpdojo/core/types
import fpdojo/engine/compiler
import fpdojo/engine/runner
import gleam/int
import gleam/javascript/promise
import gleam/option
import gleam/string

/// grading 종류별 판정 상세 — UI가 결과 패널을 그릴 때 쓰는 전부.
///
/// - ChoiceDetail: 정답/선택 인덱스(0-기반) — distractor 피드백 키 유도용.
/// - OutputDetail: 기대 출력(answer 스냅샷) vs 실제 stdout.
/// - TestsDetail: 하니스 per-test 결과(이름·통과·실패 메시지).
/// - LintDetail: 테스트 결과 + 구조 린트 통과 여부와 진단 문장(P6).
/// - CompileErrorDetail: pretty 원문 보존 — 결과 패널 1면 + error_explain 2면
///   (PLAN §4.5 2단 표시). 유저 코드의 컴파일 실패(= 오답).
/// - InfraCrashDetail: 인프라 크래시 메시지 — 컴파일러 워커 panic·watchdog
///   30s(compiler.CompileCrashed) 또는 러너 크래시(runner.RunCrashed). 유저
///   코드 문제가 아니므로 "다시 시도" UI로 안내하고 채점하지 않는다(PLAN §5.2).
/// - SpanDetail: P8 1단계 — 정답 스팬과 클릭한 줄.
pub type GradeDetail {
  ChoiceDetail(correct_index: Int, chosen: Int)
  OutputDetail(expected: String, actual: String)
  TestsDetail(tests: List(runner.TestReport))
  LintDetail(
    tests: List(runner.TestReport),
    lint_passed: Bool,
    lint_message: String,
  )
  CompileErrorDetail(failure: compiler.CompileFailure)
  InfraCrashDetail(message: String)
  SpanDetail(correct: types.Span, chosen_line: Int)
}

/// 채점 1회의 최종 보고.
///
/// - outcome: types.Outcome — Passed / Failed(이유) / TimedOut(watchdog) / GaveUp.
/// - feedback_key: schema.FeedbackMap 조회 키 — distractor는 "choice:<인덱스>"
///   형식(interfaces.md), 오답 패턴 키는 feedback.ko.toml에서 저작(PLAN §5.3).
///   매칭되는 저작 진단이 없으면 None.
pub type GradeReport {
  GradeReport(
    outcome: types.Outcome,
    detail: GradeDetail,
    feedback_key: option.Option(String),
  )
}

/// grading 종류별 비동기 채점 디스패치 (PLAN §4.1 표가 타입×채점 조합을 강제 —
/// 조합 유효성은 콘텐츠 빌드 CI가 보장하므로 런타임은 신뢰한다).
///
/// - variant: 출제된 변형 — solutions/runner_test/answer/bug_span/parsons_lines/
///   feedback 등 채점 재료의 출처.
/// - submission: UI 제출물 — grading과 짝이 맞아야 한다
///   (Choice↔ChoiceAnswer, ExactOutput↔OutputAnswer, Tests·TestsLint·
///   ParsonsOrder 조립 후↔CodeSubmission, SpotTwoStage 1단계↔SpanSelection /
///   2단계↔CodeSubmission). 어긋난 조합은 Failed로 정규화.
/// - timeout_ms: 러너 watchdog 예산(puzzle.toml — PLAN §5.2).
/// - 컴파일이 필요한 경로: compiler.compile → runner.run → 하니스 결과 집계.
///
/// 초기화 시퀀싱(결정): 컴파일이 필요한 경로는 이 함수가 내부적으로
/// compiler.init()을 먼저 await한다 — init은 멱등이므로(compiler.gleam) 호출자가
/// 따로 순서를 맞출 필요가 없다. 무컴파일 경로(Choice/ExactOutput 선택지형·
/// SpotTwoStage 1단계)는 init을 건너뛴다.
///
/// outcome 매핑(결정, PLAN §4.2·§5.2):
/// - compiler.CompileOk + 테스트 전부 통과 → Passed
/// - compiler.CompileFailed → Failed + CompileErrorDetail (유저 코드 오답)
/// - compiler.CompileCrashed → Crashed + InfraCrashDetail (인프라, 비채점·재시도)
/// - runner.RunCrashed(StackOverflow/OtherCrash) → Failed (RangeError = 오답)
/// - runner.RunTimedOut → TimedOut
pub fn grade(
  variant: schema.Variant,
  grading: types.Grading,
  submission: types.Submission,
  timeout_ms: Int,
) -> promise.Promise(GradeReport) {
  todo as "compiler.init 선행(멱등)·grading 6종 디스패치·CompileCrashed→Crashed/RunCrashed→Failed/RunTimedOut→TimedOut 매핑으로 GradeReport 집계"
}

/// 레슨 마이크로 연습(schema.Step) 채점 — schema.step_to_variant를 거쳐
/// grade()와 동일 경로로 채점한다(채점 진입점 단일화). 레슨 스텝의
/// timeout은 기본값 3000ms 고정(PLAN §5.2 — 패밀리만 timeout_ms 보유).
pub fn grade_step(
  step: schema.Step,
  submission: types.Submission,
) -> promise.Promise(GradeReport) {
  todo as "step_to_variant 변환 후 grade(variant, step.grading, submission, 3000) 위임"
}

/// 무컴파일 동기 채점 — Choice·ExactOutput만 (M1 컴파일러-free 학습 루프).
///
/// predict 선택지형·mcq(Choice)와 predict 자유입력형(ExactOutput)은 컴파일러
/// 없이 즉시 판정되므로, 레슨/배치 같은 동기 흐름에서 Promise 왕복 없이 바로
/// 쓴다. 컴파일이 필요한 grading(Tests/TestsLint/ParsonsOrder/SpotTwoStage)은
/// 비동기 `grade`/`grade_step`으로 가야 하며 여기서는 Failed로 표시한다.
///
/// 계약:
/// - Choice: ChoiceAnswer(i) vs step.answer(0-기반 인덱스 문자열). 정답이면
///   Passed+feedback_key Some("correct"), 오답이면 Failed+Some("choice:<i>").
///   ChoiceDetail(정답 인덱스, 선택 인덱스) 동봉. answer 파싱 실패·제출 형식
///   불일치는 Failed로 정규화.
/// - ExactOutput: OutputAnswer(t) vs step.answer. 양끝 공백 trim 후 비교.
///   OutputDetail(기대, 실제) 동봉.
pub fn grade_step_sync(
  step: schema.Step,
  submission: types.Submission,
) -> GradeReport {
  case step.grading, submission {
    types.Choice, types.ChoiceAnswer(chosen) -> {
      let correct = case step.answer {
        option.Some(a) -> result_to_int(a)
        option.None -> -1
      }
      case chosen == correct {
        True ->
          GradeReport(
            outcome: types.Passed,
            detail: ChoiceDetail(correct_index: correct, chosen: chosen),
            feedback_key: option.Some("correct"),
          )
        False ->
          GradeReport(
            outcome: types.Failed(reason: "wrong choice"),
            detail: ChoiceDetail(correct_index: correct, chosen: chosen),
            feedback_key: option.Some("choice:" <> int.to_string(chosen)),
          )
      }
    }

    types.ExactOutput, types.OutputAnswer(text) -> {
      let expected = option.unwrap(step.answer, "")
      let actual = string.trim(text)
      case actual == string.trim(expected) {
        True ->
          GradeReport(
            outcome: types.Passed,
            detail: OutputDetail(expected: expected, actual: actual),
            feedback_key: option.Some("correct"),
          )
        False ->
          GradeReport(
            outcome: types.Failed(reason: "wrong output"),
            detail: OutputDetail(expected: expected, actual: actual),
            feedback_key: option.Some("wrong"),
          )
      }
    }

    // 컴파일 필요 grading이거나 grading×submission 불일치
    _, _ ->
      GradeReport(
        outcome: types.Failed(reason: "non-sync grading"),
        detail: OutputDetail(expected: "", actual: ""),
        feedback_key: option.None,
      )
  }
}

/// "2" → 2, 파싱 실패 시 -1 (정답 인덱스로는 절대 매칭 안 됨).
fn result_to_int(s: String) -> Int {
  case int.parse(string.trim(s)) {
    Ok(n) -> n
    Error(_) -> -1
  }
}
