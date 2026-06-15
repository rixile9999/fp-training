//// 유닛 체크포인트 상태머신 — PLAN §3.2 (순수 모듈).
////
//// 유닛 태그 혼합 10문항을 풀어 `pass_threshold`(=8) 이상 통과하면 유닛
//// 합격이다. 합격은 `UnitProgress.checkpoint_passed`를 True로 전환해
//// unit_gate/level_gate(core/progress)의 입력이 되므로, 이 모듈이 그
//// 결과값의 유일한 생산자다(M1 DoD: 체크포인트 + L1→L2 게이트).
//// 실패 문항은 `CheckpointItem.backlink`("lesson#segment")를 모아 호스트가
//// 해당 세그먼트로 역링크를 걸 수 있게 한다(PLAN §3.2).
////
//// 채점은 레슨과 동일하게 engine/grading에 위임한다 — 체크포인트 문항도
//// Step(P1~P5)이라 일부는 컴파일이 필요하다. 효과는 직접 수행하지 않고
//// `CheckpointCmd`로 방출하고 ui/app이 Effect로 해석한다(session/lesson과 동형).
////
//// 의존 방향: core/types · content/schema · engine/grading 만 import.
//// 시간은 `now_ms`로 주입.

import fpdojo/content/schema
import fpdojo/core/types
import fpdojo/engine/grading
import gleam/option.{type Option}

/// 내부 국면 — 문항 풀이 사이클. (피드백·코멘터리는 레슨과 달리 최소:
/// 체크포인트는 평가이므로 문항별 해설을 즉시 노출하지 않는다.)
type Phase {
  /// 문항 표시 중 — `Submitted` 대기
  Solving
  /// `RunGrade` 방출 후 호스트의 `Graded` 대기
  AwaitingGrade
  /// 채점 반영 후 — `Continued`로 다음 문항
  ShowingResult
  /// 마지막 문항 통과 — 합격/불합격 커맨드 방출 후 종착
  Done
}

/// 체크포인트 세션 상태 (opaque).
///
/// 불변식:
/// - `cursor`는 `checkpoint.items`의 0-기반 인덱스.
/// - `passed_count`는 통과 문항 수 — 종료 시 `pass_threshold`와 비교.
/// - `failed_backlinks`는 틀린 문항의 backlink 누적(최신이 head) — 불합격
///   시 역링크 표시(PLAN §3.2).
pub opaque type CheckpointSession {
  CheckpointSession(
    checkpoint: schema.Checkpoint,
    cursor: Int,
    phase: Phase,
    passed_count: Int,
    failed_backlinks: List(String),
    started_at_ms: Int,
  )
}

/// 호스트가 주입하는 이벤트 (레슨과 달리 힌트·정답 보기 없음 — 평가이므로).
pub type CheckpointEvent {
  Submitted(submission: types.Submission)
  Graded(report: grading.GradeReport)
  Continued
}

/// 세션이 방출하는 커맨드.
pub type CheckpointCmd {
  /// engine/grading.grade_step 호출 요청 (Promise → `Graded`로 회송)
  RunGrade(step: schema.Step, submission: types.Submission)
  /// 합격 — `passed_count >= pass_threshold`. 호스트가
  /// UnitProgress.checkpoint_passed=True로 전환 → 게이트 재평가 (PLAN §3.1)
  CheckpointPassed(unit_id: String)
  /// 불합격 — 틀린 문항의 backlink 목록 동봉. 호스트가 역링크 화면 제시
  CheckpointFailed(unit_id: String, failed_backlinks: List(String))
}

/// 체크포인트 시작 — 첫 문항을 가리키는 초기 세션. `now_ms`는 소요 시간 통계용.
pub fn start(checkpoint: schema.Checkpoint, now_ms: Int) -> CheckpointSession {
  todo as "첫 문항을 가리키는 Solving 국면 초기 세션 생성"
}

/// 현재 표시할 문항. `Done`이면 None — 호스트는 결과 화면으로.
pub fn current_item(
  session: CheckpointSession,
) -> Option(schema.CheckpointItem) {
  todo as "cursor 위치의 CheckpointItem 반환, Done/범위 밖이면 None"
}

/// 핵심 전이 — 이벤트 1개를 받아 (다음 상태, 커맨드 목록)을 돌려준다.
///
/// 계약 (PLAN §3.2):
/// - `Submitted`: Solving → AwaitingGrade, `[RunGrade(item.step, submission)]`.
/// - `Graded(Passed)`: passed_count+1, ShowingResult.
/// - `Graded(Failed/TimedOut)`: 해당 문항 backlink를 failed_backlinks에 추가,
///   ShowingResult (재시도 없음 — 평가이므로 1회 채점).
/// - `Graded(Crashed)`: 인프라 크래시 — 문항 미집계, 같은 문항 재출제(Solving
///   복귀) + 호스트가 "다시 시도" 안내. 정오에 반영하지 않는다(PLAN §5.2).
/// - `Continued`: cursor+1. 마지막을 넘으면 Done + passed_count와
///   pass_threshold 비교해 `CheckpointPassed` 또는 `CheckpointFailed` 방출.
/// - 국면에 맞지 않는 이벤트는 무시 — 전함수.
pub fn handle(
  session: CheckpointSession,
  event: CheckpointEvent,
  now_ms: Int,
) -> #(CheckpointSession, List(CheckpointCmd)) {
  todo as "제출→채점 위임, 정답 누적·오답 backlink 수집, Crashed는 재출제, 완료 시 임계 비교로 합격/불합격 방출"
}

/// 진행률 0.0~1.0 — 채점한 문항 수 / 전체 문항 수.
pub fn progress_ratio(session: CheckpointSession) -> Float {
  todo as "cursor를 전체 문항 수로 나눈 진행률 (빈 체크포인트는 0.0)"
}
