//// 대시보드 — 진행/약점 가시화 (PLAN §4.2, §6 M2 "미니 대시보드").
////
//// 표시 항목: 글로벌 레이팅과 테마 서브 레이팅(시도 10회 미만 테마는
//// "측정 중", §4.2) / 실패 시도 로그 기반 약점 큐 — 테마 드릴 진입점
//// (§2 "Learn from your mistakes" 대응) / 레벨>유닛 진행 맵과 잠금 상태
//// (core/progress.Gate) / Rush·Streak 개인 최고 기록(M3 전 리더보드 없음,
//// §4.3). JSON 내보내기/가져오기 버튼의 진입점 — M1 필수 (§5.4, R6).
////
//// 데이터 원천: profile + storage/local.load_attempts 집계. 렌더 전용 —
//// ui/app을 import하지 않는다 (역방향 금지).

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// 화면 골격 stub. 구현 단계에서 프로필 요약(레이팅·진행)과 시도 집계를
/// 인자로 받아 렌더한다.
pub fn view() -> Element(msg) {
  html.div([attribute.class("page page--dashboard")], [
    html.h1([], [html.text("대시보드")]),
    html.p([], [html.text("레이팅 · 테마별 약점 · 진행 맵 · 데이터 내보내기")]),
  ])
}
