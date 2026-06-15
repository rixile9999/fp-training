//// 트레이닝 — 모드 선택 + 퍼즐 풀이 화면 (PLAN §4.3).
////
//// 모드 5종: 믹스드(rated, 글로벌 ±밴드 + interleaving + 약점 +30%) /
//// 테마 드릴(rated, 서브 레이팅 ±밴드, 14일 쿨다운) / Code Rush(3분·5분·
//// 서바이벌, 3 strikes, 콤보 보너스 — unrated) / Streak(600부터 오름차순,
//// 1실수 종료, 스킵 1회 — unrated) / 데일리 퍼즐(Asia/Seoul 결정적 해시).
//// 첫 무힌트 시도만 rated(§4.2 lichess 의미론), 힌트 H1부터 unrated(§4.5).
////
//// 출제·런 상태는 session/training(pick_next, RushState, StreakState)이
//// 순수하게 들고, 이 모듈은 렌더만 한다. 타임드 모드는 1.5× 시간 설정과
//// 무제한 서바이벌 포맷 제공(§5.4 접근성). ui/app import 금지 (역방향).

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// 화면 골격 stub. 구현 단계에서 모드 상태(현재 퍼즐 변형, Rush/Streak
/// 진행, 밴드 선택)를 인자로 받아 렌더한다.
pub fn view() -> Element(msg) {
  html.div([attribute.class("page page--training")], [
    html.h1([], [html.text("트레이닝")]),
    html.p([], [html.text("믹스드 · 테마 드릴 · Code Rush · Streak · 데일리")]),
  ])
}
