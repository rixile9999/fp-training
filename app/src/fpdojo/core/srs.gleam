//// 8레벨 간격 반복(SRS) — 순수 스케줄러 (PLAN.md §4.4, Chessable 8레벨).
////
//// 카드 단위는 퍼즐 인스턴스가 아니라 `family_id`(테마×타입 퍼즐 패밀리,
//// 변형 3~5개 보유) — 리뷰마다 변형을 회전 출제해 답 암기를 막는다
//// (training-system.md §3.6). 시간은 항상 `now_ms: Int` 인자로 주입한다.
////
//// 의존 방향: 다른 fpdojo 모듈을 import하지 않는다(core/types 바로 아래
//// 계층). 위로는 core/progress(레벨 게이트), core/profile, session/review가
//// 사용한다.
////
//// M1 탑재 범위(PLAN §4.4): 간격 테이블 + due 큐 + 레벨 해제 게이트.
//// 변형 회전·Learn/Review 구분·일일 큐 UI 고도화는 M3. 후일 FSRS 교체에
//// 대비해 스케줄 결정은 이 모듈 뒤에 격리한다(`fn(card_history) -> next_due`
//// 인터페이스 경로, PLAN §4.4).

/// SRS 카드 1장 (PLAN §5.4 데이터 모델).
///
/// - `family_id`: 카드 키. 퍼즐 패밀리 단위 — 아키텍처의 `srs_item`
///   마이크로 스킬 문자열은 대시보드 그룹핑 라벨로 격하(카드 키 아님).
/// - `level`: 1..8 (간격 테이블 인덱스).
/// - `due_at_ms`: 다음 리뷰 시각(epoch ms).
/// - `consecutive_successes`: 간격을 둔 연속 성공 횟수 — 4면 졸업.
/// - `lapses`: L1 리셋 누적 횟수(대시보드·후일 FSRS 적합용).
/// - `last_variant`: 직전 출제 변형 id — session/review가 변형 회전 시
///   회피 기준으로 쓰고, 레코드 업데이트로 직접 갱신한다.
pub type SrsCard {
  SrsCard(
    family_id: String,
    level: Int,
    due_at_ms: Int,
    consecutive_successes: Int,
    lapses: Int,
    last_variant: String,
  )
}

/// 세션 종료 시점의 리뷰 판정 (PLAN §4.4).
///
/// 세션 내 재시도 무벌점(Execute Program식)은 호출 계층(session/review)의
/// 책임 — 같은 세션에서 다시 풀어 맞히면 이 모듈까지 Failed가 내려오지
/// 않는다. AnswerRevealed('정답 보기')만은 즉시 벌점이다(PLAN §3.2 —
/// 재시도 무벌점, '정답 보기'만 인터벌 축소).
pub type ReviewOutcome {
  ReviewPassed
  ReviewFailed
  AnswerRevealed
}

/// 새 카드 등록: L1, due = now + 4h (레슨 완료 시 핵심 아이템 2~4개 등록,
/// PLAN §2). 첫 4h 게이트가 "오늘 배운 것을 오늘 저녁에 한 번 더"를
/// 강제한다(PLAN §2 맞물림 규칙). `last_variant`는 아직 없음("").
pub fn new_card(family_id: String, now_ms: Int) -> SrsCard {
  SrsCard(
    family_id: family_id,
    level: 1,
    due_at_ms: now_ms + interval_ms(1),
    consecutive_successes: 0,
    lapses: 0,
    last_variant: "",
  )
}

/// 간격 테이블 (PLAN §4.4 — Chessable 검증 간격, canonical):
/// L1=4h, L2=1d, L3=3d, L4=1w, L5=2w, L6=1mo(30d), L7=3mo(90d), L8=6mo(180d).
/// 범위 밖 레벨은 1..8로 클램프.
pub fn interval_ms(level: Int) -> Int {
  case level {
    // 1d
    2 -> 86_400_000
    // 3d
    3 -> 259_200_000
    // 1w
    4 -> 604_800_000
    // 2w
    5 -> 1_209_600_000
    // 1mo = 30d
    6 -> 2_592_000_000
    // 3mo = 90d
    7 -> 7_776_000_000
    // 6mo = 180d (level >= 8 클램프)
    l if l >= 8 -> 15_552_000_000
    // 4h (level <= 1 클램프)
    _ -> 14_400_000
  }
}

/// 리뷰 결과 1건을 카드에 반영 (PLAN §4.4).
///
/// 계약:
/// - ReviewPassed: level +1(최대 8 유지 — 졸업은 is_retired가 별도 판정),
///   consecutive_successes +1, due = now + 새 레벨 간격.
/// - ReviewFailed / AnswerRevealed: L1 리셋, lapses +1,
///   consecutive_successes 0, due = now + L1 간격(4h).
/// - `last_variant`는 여기서 건드리지 않는다 — 출제 변형을 아는
///   session/review가 레코드 업데이트로 갱신.
pub fn apply_review(
  card: SrsCard,
  outcome: ReviewOutcome,
  now_ms: Int,
) -> SrsCard {
  todo as "Passed면 레벨+1(최대 8)·연속성공+1·새 간격 due, Failed/Revealed면 L1 리셋·lapses+1·연속 0으로 갱신한다"
}

/// 카드가 리뷰 대상인가: due 시각 경과 여부 (PLAN §2 — 접속 시 due 카드
/// 우선 노출, 큐 소진이 데일리 스트릭 기본 충족 조건).
pub fn is_due(card: SrsCard, now_ms: Int) -> Bool {
  todo as "due_at_ms가 now_ms에 도달했는지 비교한다"
}

/// 졸업(은퇴) 판정: 간격을 둔 연속 성공 4회 → 은퇴 (EP식, 약 2개월 시점,
/// PLAN §4.4 — 아키텍처의 "L8 도달 시 은퇴"는 폐기). 은퇴 카드의
/// "6개월 후 확인 리뷰 1회"는 M3 범위로 이 모듈 밖.
pub fn is_retired(card: SrsCard) -> Bool {
  todo as "consecutive_successes가 졸업 기준 4회에 도달했는지 판정한다"
}
