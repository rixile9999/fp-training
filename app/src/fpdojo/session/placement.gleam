//// 배치 테스트(온보딩) 상태머신 — PLAN §2 첫 방문 (순수 모듈).
////
//// 첫 화면에서 "배치 테스트"를 고른 사용자에게 12~15개 무컴파일 문항
//// (predict/mcq) 난이도 사다리를 제시하고(약 5분), 누적 정답을 점수 밴드로
//// 환산한다. 밴드는 세 가지로 쓰인다(PLAN §2): (i) 초기 레이팅 800~1900/
//// RD300 시드(rating.placement_seed), (ii) 점수 구간별 유닛 선해제, (iii)
//// 선해제 유닛 태그를 "학습됨"(처음부터/배치 경로) 또는 "잠정 학습됨"
//// (트레이닝만/건너뛰기 경로)으로 마킹.
////
//// 콘텐츠를 모른다(content/schema의 Step만 받는다): 사다리 문항은 호출자가
//// manifest에서 골라 주입하고, 밴드→{선해제 유닛 id, 태그} 매핑도 호출자
//// (ui/app)가 manifest로부터 도출한다 — core/progress.level_gate의 "호출자가
//// 도출해 내려준다" 패턴과 동일. 본 모듈은 밴드(Int)까지만 책임진다.
////
//// 무컴파일 채점: 문항이 predict 선택지형·mcq뿐이므로 정오를 동기로 판정
//// (선택지 인덱스 또는 출력 문자열 비교) — engine/grading·컴파일러 불필요.
////
//// 의존 방향: core/types · content/schema 만 import. 시간 의존 없음
//// (배치는 무시간 — 소요 시간 통계는 호스트가 잰다).

import fpdojo/content/schema
import fpdojo/core/types
import gleam/option.{type Option}

/// 배치 세션 상태 (opaque — 내부 표현은 본 모듈의 설계 산출물).
///
/// 불변식:
/// - `cursor`는 `items`의 0-기반 인덱스, 범위를 넘으면 종료(밴드 산출 가능).
/// - `correct`는 누적 정답 수 — `score_band`의 입력.
/// - `answered`는 문항별 정오(최신이 head) — 사후 표시·디버깅용.
/// - `seed`는 placement_seed 경로의 결정적 분기에 쓰는 시드(호스트 주입).
pub opaque type PlacementSession {
  PlacementSession(
    items: List(schema.Step),
    cursor: Int,
    correct: Int,
    answered: List(Bool),
    seed: Int,
  )
}

/// 호스트가 주입하는 이벤트.
pub type PlacementEvent {
  /// 현재 문항에 답 제출 — 동기 채점 후 다음 문항으로 전진
  Answered(submission: types.Submission)
  /// 문항 건너뛰기(오답으로 집계하지 않고 전진) — 배치 이탈 방지용
  Skipped
}

/// 세션이 방출하는 커맨드 — ui/app이 해석한다.
pub type PlacementCmd {
  /// 배치 완료. 호스트가 순서대로 적용:
  ///   1. rating.placement_seed(score_band) → profile.overall 교체(RD300)
  ///   2. manifest에서 band→선해제 유닛/태그 도출 →
  ///      각 유닛에 progress.seed_unit, 태그는 learned_tags에 마킹
  ///      (처음부터/배치=True 학습됨 / 트레이닝만·건너뛰기=False 잠정)
  ///   3. storage/local.save_profile
  PlacementCompleted(score_band: Int)
}

/// 배치 시작 — 사다리 문항(호출자가 manifest에서 선별, 보통 12~15개)과
/// 결정적 시드로 초기 세션을 만든다. cursor 0, correct 0.
pub fn start(items: List(schema.Step), seed: Int) -> PlacementSession {
  PlacementSession(
    items: items,
    cursor: 0,
    correct: 0,
    answered: [],
    seed: seed,
  )
}

/// 현재 표시할 문항. cursor가 범위 밖(종료)이면 None — 호스트는 결과 화면으로.
pub fn current_item(session: PlacementSession) -> Option(schema.Step) {
  todo as "cursor 위치의 Step 반환, 범위 밖이면 None"
}

/// 핵심 전이 — 이벤트 1개를 받아 (다음 상태, 커맨드 목록)을 돌려준다.
///
/// 계약 (PLAN §2):
/// - `Answered`: 현재 문항을 동기 채점(Choice는 step.answer 인덱스 비교,
///   ExactOutput은 출력 문자열 비교)해 정답이면 correct+1, answered에 결과 기록,
///   cursor+1. 마지막 문항을 넘으면 `[PlacementCompleted(score_band(session'))]`.
/// - `Skipped`: 오답 미집계로 answered에 False 기록 후 cursor+1(완료 판정 동일).
/// - 종료 후 이벤트는 무시(상태 불변, 커맨드 없음) — 전함수.
pub fn handle(
  session: PlacementSession,
  event: PlacementEvent,
) -> #(PlacementSession, List(PlacementCmd)) {
  todo as "현재 문항 동기 채점·correct 누적·cursor 전진, 마지막 문항 통과 시 score_band로 PlacementCompleted 방출"
}

/// 누적 정답을 점수 밴드(0-기반 Int)로 환산 — rating.placement_seed의 입력
/// 도메인과 일치한다(밴드 경계 수치는 본구현 결정). 종료 전 호출도 현재까지의
/// 정답 기준으로 계산 가능(중도 추정용).
pub fn score_band(session: PlacementSession) -> Int {
  todo as "correct/총문항 비율을 밴드 구간(예: 0..k)으로 매핑"
}

/// 진행률 0.0~1.0 — 답한 문항 수 / 전체 문항 수. 상단 진행 바용.
pub fn progress_ratio(session: PlacementSession) -> Float {
  todo as "cursor를 전체 문항 수로 나눈 진행률 (빈 사다리는 0.0)"
}
