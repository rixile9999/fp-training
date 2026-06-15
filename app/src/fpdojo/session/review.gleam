//// SRS 복습 큐 상태머신 — PLAN §4.4 (순수 모듈).
////
//// 접속 시 가장 먼저 노출되는 due 카드 큐를 만들고 소비한다 (PLAN §2
//// 하루 사용 흐름 1단계, 5~10분). 카드 단위는 family_id — 리뷰는 동일
//// 퍼즐이 아니라 패밀리 내 파라미터 변형 회전 출제로 답 암기를 막는다
//// (PLAN §4.4). 복습은 전부 unrated (PLAN §4.2).
////
//// M1 탑재 범위(PLAN §4.4): 간격 테이블 + due 큐 + 레벨 해제 게이트.
//// Learn/Review 모드 구분·일일 큐 UI 고도화는 M3 — 단 last_variant 회피
//// 회전은 인터페이스에 이미 반영돼 있다(ReviewItem).
////
//// 의존 방향: core/srs · core/profile · content/schema 만 import.
//// 카드 자체의 레벨 전이(L1 리셋·+1레벨·졸업)는 core/srs.apply_review가
//// 담당하고, 본 모듈은 "세션 내 재시도 무벌점"(Execute Program 관용 규칙)
//// 오케스트레이션만 얹는다. 시간은 `now_ms`, 난수는 `seed`로 주입.

import fpdojo/content/schema
import fpdojo/core/profile
import fpdojo/core/srs
import gleam/option.{type Option}

/// 복습 큐 (opaque — 내부 표현은 본 모듈의 설계 산출물).
///
/// 불변식:
/// - `pending`: 미출제 아이템 (오버듀 오래된 순 정렬 — due 임박이 아니라
///   가장 늦은 카드부터 소화).
/// - `retry`: 세션 내 첫 실패로 회송된 아이템 — pending 소진 후 재출제.
///   같은 세션에서 다시 맞히면 무벌점(레벨 유지), 여기서도 실패하면
///   L1 리셋 (PLAN §4.4 "세션 종료 시점 실패 또는 '정답 보기' → L1 리셋").
/// - `completed`: 이번 세션에서 확정 처리된 카드 수 (진행 표시용).
/// - `new_count`/`review_count`: build 시 캡 검증에 쓰인 신규/리뷰 편성 수.
pub opaque type ReviewQueue {
  ReviewQueue(
    pending: List(ReviewItem),
    retry: List(ReviewItem),
    completed: Int,
    new_count: Int,
    review_count: Int,
    seed: Int,
  )
}

/// 출제 1건 — 카드 + 패밀리 + 이번에 낼 변형.
/// 변형은 `card.last_variant`를 회피해 회전 선택한다 (암기 방지, PLAN §4.4).
pub type ReviewItem {
  ReviewItem(
    card: srs.SrsCard,
    family: schema.PuzzleFamily,
    variant: schema.Variant,
  )
}

/// 일일 신규 카드 상한 — binge 방지 캡 (Execute Program, PLAN §4.4)
pub const daily_new_cap = 10

/// 일일 리뷰 상한 — 예상 일일 부담 ~10분 (PLAN §4.4)
pub const daily_review_cap = 50

/// due 큐 빌드 (PLAN §4.4):
/// - profile.srs에서 `srs.is_due(card, now_ms)`인 카드만 — 졸업 카드는
///   제외(간격을 둔 연속 성공 4회 은퇴, 6개월 후 확인 리뷰 1회).
/// - 신규(아직 리뷰 이력 없는 L1) 최대 daily_new_cap개, 리뷰 최대
///   daily_review_cap개로 절단 — 캡은 하루 단위이므로 당일 기 소화 수
///   `served_today: #(신규, 리뷰)`를 차감한다(같은 날 두 번째 세션에서
///   캡이 리셋되지 않도록; 호출자가 당일 attempt 로그에서 집계).
/// - families에서 family_id 매칭·srs_eligible 패밀리만, 변형은
///   last_variant 회피 + seed 기반 결정적 회전 선택.
/// - 정렬: 오버듀가 오래된 카드 우선.
pub fn build(
  profile: profile.Profile,
  families: List(schema.PuzzleFamily),
  served_today: #(Int, Int),
  now_ms: Int,
  seed: Int,
) -> ReviewQueue {
  todo as "due 카드 필터·당일 잔여 캡 절단·last_variant 회피 변형 선택으로 복습 큐 구성"
}

/// 다음 출제 아이템. pending 우선, 소진 후 retry 더미 재출제.
/// `None`이면 큐 소진 — 데일리 스트릭의 기본 충족 조건 달성 (PLAN §2).
pub fn next(queue: ReviewQueue) -> Option(ReviewItem) {
  todo as "pending 머리 우선, 비면 retry 머리 반환, 둘 다 비면 None"
}

/// 리뷰 결과 1건 반영 — (갱신된 큐, 갱신된 프로필) 반환.
///
/// 계약 (PLAN §4.4, training-system.md §3.6):
/// - 첫 시도 `ReviewPassed`: srs.apply_review로 +1레벨·연속 성공+1,
///   last_variant 갱신, 카드 확정 처리.
/// - 첫 시도 `ReviewFailed`: 카드 무변경, 아이템을 retry 더미로 회송 —
///   세션 내 재시도 무벌점 (Execute Program).
/// - retry 아이템 `ReviewPassed`: 리셋 없이 레벨 유지(+0) — srs.apply_review를
///   거치지 않고 last_variant만 갱신.
/// - retry 아이템 `ReviewFailed` 또는 (어느 시점이든) `AnswerRevealed`:
///   srs.apply_review로 L1 리셋·lapses+1·연속 성공 0.
/// - 갱신된 카드는 profile.srs(키 = family_id)에 다시 써서 반환.
pub fn apply(
  queue: ReviewQueue,
  profile: profile.Profile,
  family_id: String,
  outcome: srs.ReviewOutcome,
  now_ms: Int,
) -> #(ReviewQueue, profile.Profile) {
  todo as "첫 실패는 retry 회송(무벌점), retry 실패·정답 보기는 L1 리셋, 통과는 레벨 갱신 후 프로필 반영"
}

/// 남은 아이템 수 (pending + retry) — 헤더 due 배지·진행 표시용 (PLAN §4.4 복귀 트리거).
pub fn remaining(queue: ReviewQueue) -> Int {
  todo as "pending과 retry 더미 길이 합산"
}

/// 세션 종료 정리 — retry 더미에 남은(= 첫 실패 후 만회하지 못한) 카드를
/// "세션 종료 시점 실패 = L1 리셋"(PLAN §4.4)으로 확정해 프로필에 반영한다.
/// 명시적 세션 종료와 이탈(페이지 이동·탭 닫기 전 저장) 양쪽에서 호출.
/// pending에 남은 미출제 카드는 무변경(실패가 아니라 미시도).
pub fn finalize(
  queue: ReviewQueue,
  profile: profile.Profile,
  now_ms: Int,
) -> profile.Profile {
  todo as "retry 잔여 카드 전부에 srs.apply_review(ReviewFailed)를 적용해 프로필 반환"
}
