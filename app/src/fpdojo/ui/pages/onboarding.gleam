//// 온보딩 — 첫 방문 분기 (PLAN §2 "첫 방문").
////
//// 세 갈래: (a) "처음부터" — U1 시작, 레이팅 1500/RD 350.
//// (b) "배치 테스트"(5분) — 무컴파일 문항(predict/mcq) 12~15개 난이도
//// 사다리 → 초기 레이팅 800~1900 시드(RD 300, core/rating.placement_seed)
//// + 점수 구간별 유닛 선해제·태그 "학습됨" 마킹. (c) "트레이닝만" —
//// 배치 테스트 필수 후 그 결과 태그 풀에서 출제. 유닛 건너뛰기는 확인
//// 프롬프트 후 허용, 건너뛴 태그는 "잠정 학습됨"(learned_tags=False) 편입.
////
//// 의존 방향: ui/pages/* 는 ui/app을 import하지 않는다 (역방향 금지).

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// 화면 골격 stub. 구현 단계에서 분기 선택 상태·배치 테스트 진행
/// (무컴파일 문항 사다리)을 인자로 받아 렌더한다.
pub fn view() -> Element(msg) {
  html.div([attribute.class("page page--onboarding")], [
    html.h1([], [html.text("시작하기")]),
    html.p([], [html.text("처음부터 / 배치 테스트(5분) / 트레이닝만")]),
  ])
}
