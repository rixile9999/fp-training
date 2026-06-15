//// 커리큘럼 잠금 규칙 — 순수 게이트 판정 (PLAN.md §3.1).
////
//// 잠금 규칙(확정): 유닛 내 레슨 순차 해제 / 유닛 간 선수 유닛 완료 시
//// 해제 / 레벨 해제 = 이전 레벨 전 유닛 완료 ∧ 그 레벨 SRS 아이템의
//// 1회차 리뷰(4h~1d) 통과. 게이트 단위는 레벨로 통일(레슨 단위 리뷰
//// 게이트는 두지 않음). 신규 레슨은 하루 5개 캡.
////
//// 의존 방향: fpdojo/core/srs(카드 due 판정)만 import. 위로는
//// core/profile, session/*, ui/*가 사용한다. 콘텐츠(manifest)는 모름 —
//// 유닛 선수 목록 등 콘텐츠 파생 정보는 호출자가 인자로 내려준다.
////
//// 게이트 대기 UX(PLAN §2·§4.4): 막힌 동안 카운트다운 + 같은 레벨 내
//// 병렬 유닛·트레이닝 모드가 항상 열려 있어야 한다 — OpenAt이 그 표시용.

import fpdojo/core/srs
import gleam/dict

/// 유닛 1개의 진행 상태 (PLAN §5.4 데이터 모델).
/// `lessons_done`: 완료한 레슨 id 목록(유닛 내 순차 해제의 근거).
/// `checkpoint_passed`: 유닛 체크포인트(10문항 중 8개 이상, PLAN §3.2)
/// 통과 여부 — "유닛 완료"의 판정 기준.
pub type UnitProgress {
  UnitProgress(lessons_done: List(String), checkpoint_passed: Bool)
}

/// 잠금 판정 결과. UI는 이 값만 보고 렌더링한다.
pub type Gate {
  /// 즉시 진입 가능
  Open
  /// SRS 1회차 리뷰 대기 — 가장 이른 due 시각(ms). UI는 카운트다운 표시
  /// + "오늘 저녁에 다시 오세요" + 대기 중 가능한 활동 제시(PLAN §4.4)
  OpenAt(ms: Int)
  /// 미완료(checkpoint 미통과) 선수 유닛 목록
  RequiresUnits(unit_ids: List(String))
  /// 1회차 리뷰를 아직 통과하지 못한 SRS 패밀리 목록
  RequiresReview(family_ids: List(String))
}

/// 유닛 게이트: 선수 유닛이 전부 완료(checkpoint_passed)면 Open,
/// 아니면 미완료 선수 목록의 RequiresUnits (PLAN §3.1).
///
/// 계약: `prerequisites`는 manifest의 UnitMeta.prerequisites를 호출자가
/// 그대로 전달. `units`에 키가 없는 선수 유닛은 미착수 = 미완료로 취급.
/// 건너뛰기 확인 프롬프트(PLAN §2)는 UI 책임 — 여기서는 순수 판정만.
pub fn unit_gate(
  unit_id: String,
  prerequisites: List(String),
  units: dict.Dict(String, UnitProgress),
) -> Gate {
  todo as "선수 유닛 전부의 checkpoint_passed를 검사해 Open 또는 미완료 목록의 RequiresUnits를 반환한다"
}

/// 레벨 게이트: 레벨 해제 = 이전 레벨 전 유닛 완료 ∧ 그 레벨 SRS
/// 아이템의 1회차 리뷰(4h~1d) 통과 (PLAN §3.1, M1 DoD "L1→L2 게이트
/// 실동작").
///
/// 레벨→유닛/패밀리 매핑은 manifest(콘텐츠) 소관이고 이 모듈은 콘텐츠를
/// 모르므로, 호출자가 도출해 내려준다:
/// - `prev_level_unit_ids`: 이전 레벨에 속한 유닛 id (UnitMeta.level에서)
/// - `level_family_ids`: 이전 레벨 레슨들이 등록한 SRS 패밀리 id
///   (Lesson.srs_items에서)
///
/// 계약(우선순위): 이전 레벨 유닛 미완료 → RequiresUnits / 유닛은 다 됐고
/// 1회차 리뷰 미통과 카드가 아직 due 전 → OpenAt(가장 이른 due) /
/// due는 지났는데 미통과 → RequiresReview / 전부 충족 → Open.
/// "1회차 리뷰 통과"는 카드가 L1을 벗어났는지(level > 1)로 판정 가능.
pub fn level_gate(
  prev_level_unit_ids: List(String),
  level_family_ids: List(String),
  units: dict.Dict(String, UnitProgress),
  srs: dict.Dict(String, srs.SrsCard),
  now_ms: Int,
) -> Gate {
  todo as "이전 레벨 전 유닛 완료와 그 레벨 SRS 1회차 리뷰 통과를 검사해 Open/OpenAt/RequiresUnits/RequiresReview를 결정한다"
}

/// 오늘(Asia/Seoul 자정 기준, PLAN §4.3의 날짜 키와 동일 기준) 시작한
/// 신규 레슨 수 — daily_new_lesson_cap(5) 검사용 (PLAN §3.1).
/// `attempt_log_dates`: 신규 레슨 시작 시각(epoch ms) 목록.
pub fn new_lessons_today(attempt_log_dates: List(Int), now_ms: Int) -> Int {
  todo as "Asia/Seoul(UTC+9) 자정 기준으로 now_ms와 같은 날에 속한 타임스탬프 개수를 센다"
}

/// 신규 레슨 하루 캡 (PLAN §3.1 확정 수치).
pub const daily_new_lesson_cap = 5

/// 선해제(잠정 완료) 유닛 진행 — 배치 테스트 상위 구간의 유닛 선해제와
/// 유닛 건너뛰기(PLAN §2)에서 쓴다. `checkpoint_passed: True`로 두어
/// 후속 유닛의 `unit_gate`가 열리게 하되, `lessons_done`은 비워 둔다
/// (레슨을 실제로 푼 게 아니므로 — 진행 표시·재방문 시 구분 가능).
/// 태그의 "잠정 학습됨"(learned_tags False) 마킹은 프로필 쪽에서 별도 수행.
pub fn seed_unit() -> UnitProgress {
  UnitProgress(lessons_done: [], checkpoint_passed: True)
}
