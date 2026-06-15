//// 비결정성 주입 지점 — 시간·uuid·난수 시드 (FFI: platform_ffi.mjs, 실구현).
////
//// core/*·session/* 순수 계층은 시간·난수를 절대 직접 읽지 않는다 —
//// interfaces.md 원칙("시간은 어디서나 now_ms: Int 인자로 주입")에 따라
//// 이 모듈은 Effect 해석 계층(ui/app)만 호출하고, 값은 인자로 흘려보낸다.
//// 퍼즐/테스트 콘텐츠에는 시간·난수·네트워크 자체가 금지(저작 린트,
//// PLAN §5.2 결정성)이므로 이 모듈은 앱 셸 전용이다.
////
//// 의존 방향: 어떤 fpdojo 모듈도 import하지 않는 리프 모듈.

/// 현재 시각 epoch millis (Date.now).
/// SRS due 판정·레벨 게이트 카운트다운(PLAN §3.1)·Attempt.at_ms·
/// 데일리 키 계산(PLAN §4.3)에 주입한다.
@external(javascript, "./platform_ffi.mjs", "nowMs")
pub fn now_ms() -> Int

/// uuid v4 (crypto.randomUUID).
/// Attempt.id(M3 서버 union 병합 키, PLAN §5.4)와 로컬 user_id 생성에 사용.
@external(javascript, "./platform_ffi.mjs", "newUuid")
pub fn new_uuid() -> String

/// 의사난수 시드 (31비트 양의 정수).
/// session/training.pick_next·session/review.build에 주입해 순수 계층의
/// 결정적 테스트 가능성을 유지한다 (interfaces.md "session/training").
@external(javascript, "./platform_ffi.mjs", "randomSeed")
pub fn random_seed() -> Int
