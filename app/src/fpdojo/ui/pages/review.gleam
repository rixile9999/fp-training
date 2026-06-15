//// 복습 — SRS due 큐 소화 화면 (PLAN §4.4).
////
//// 접속 시 우선 노출되는 due 카드 큐. 카드 = (테마×타입) 패밀리이고
//// 매번 last_variant를 회피한 파라미터 변형이 출제돼 답 암기가 불가능하다.
//// 일일 상한 신규 10 / 리뷰 50 (~10분 부담), 큐 소진이 데일리 스트릭의
//// 기본 충족 조건(§2). 세션 내 재시도 무벌점, 세션 종료 시점 실패 또는
//// '정답 보기' → L1 리셋(§4.4). 1회차 리뷰 통과가 레벨 게이트를 연다(§3.1).
////
//// 큐 상태는 session/review.ReviewQueue(순수)가 들고, 이 모듈은
//// next/remaining 투영을 렌더만 한다. ui/app import 금지 (역방향).

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// 화면 골격 stub. 구현 단계에서 session/review.ReviewQueue 투영
/// (현재 ReviewItem, 남은 개수)을 인자로 받아 렌더한다.
pub fn view() -> Element(msg) {
  html.div([attribute.class("page page--review")], [
    html.h1([], [html.text("복습 큐")]),
    html.p([], [html.text("오늘의 SRS due 카드")]),
  ])
}
