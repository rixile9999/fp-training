//// 홈 — 학습 허브 (PLAN §2).
////
//// M1: 임베드된 유닛·레슨 목록을 카드로 보여주고, 완료 표시(✓)를 단다.
//// 두 트랙을 나란히 보여준다 — **실용 트랙**(무엇을·어떻게, level 1~4)과
//// **FP 이론 트랙**(왜·그 패턴의 이름, level 5~8, 이론 레벨 TL1~TL4로 묶음).
//// 이론 트랙은 체스의 이론 공부처럼 병렬·선택이다
//// (docs/design/fp-theory-curriculum.md §0).
//// 정식 버전에서는 SRS due 배지·이어하기·트레이닝 모드 진입이 추가된다.
//// 페이지는 ui/app을 import하지 않고 메시지 생성자를 인자로 받는다
//// (역방향 의존 금지, msg 제네릭).

import fpdojo/content/schema
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// `practical`/`theory`: 두 트랙의 유닛. `completed`: 완료한 레슨 id.
/// `on_start`: 레슨 시작 메시지 생성자.
pub fn view(
  practical: List(schema.Unit),
  theory: List(schema.Unit),
  completed: List(String),
  on_start: fn(String) -> msg,
) -> Element(msg) {
  html.div([attribute.class("page page--home")], [
    html.header([attribute.class("hero")], [
      html.h1([attribute.class("hero__title")], [html.text("fpdojo")]),
      html.p([attribute.class("hero__subtitle")], [
        html.text("Gleam으로 배우는 함수형 프로그래밍 — 한 번에 한 개념씩."),
      ]),
      progress_summary(list.append(practical, theory), completed),
    ]),
    track(
      "실용 트랙",
      "Gleam으로 무엇을, 어떻게 — 손이 먼저 익는 길.",
      "track--practical",
      [units_list(practical, completed, on_start)],
    ),
    case theory {
      [] -> element.none()
      _ ->
        track(
          "FP 이론 트랙",
          "왜 그렇게 쓰는가, 그 패턴의 이름은 무엇인가 — 실용 트랙과 병렬로 공부한다.",
          "track--theory",
          theory_levels(theory, completed, on_start),
        )
    },
  ])
}

fn progress_summary(
  units: List(schema.Unit),
  completed: List(String),
) -> Element(msg) {
  let total =
    units
    |> list.flat_map(fn(u) { u.lessons })
    |> list.length
  let done = list.length(completed)
  html.p([attribute.class("hero__progress")], [
    html.text("완료한 레슨 " <> int.to_string(done) <> " / " <> int.to_string(total)),
  ])
}

/// 트랙 1개(실용/이론)를 헤더 + 내용으로 감싼다.
fn track(
  title: String,
  subtitle: String,
  extra_class: String,
  children: List(Element(msg)),
) -> Element(msg) {
  html.section([attribute.class("track " <> extra_class)], [
    html.div([attribute.class("track__header")], [
      html.h2([attribute.class("track__title")], [html.text(title)]),
      html.p([attribute.class("track__subtitle")], [html.text(subtitle)]),
    ]),
    ..children
  ])
}

fn units_list(
  units: List(schema.Unit),
  completed: List(String),
  on_start: fn(String) -> msg,
) -> Element(msg) {
  html.div(
    [attribute.class("units")],
    list.map(units, fn(unit) { unit_section(unit, completed, on_start) }),
  )
}

/// 이론 유닛을 이론 레벨(TL1~TL4 = level 5~8)별로 묶어 렌더한다.
fn theory_levels(
  units: List(schema.Unit),
  completed: List(String),
  on_start: fn(String) -> msg,
) -> List(Element(msg)) {
  [
    #(5, "TL1 · 함수와 계산의 본질"),
    #(6, "TL2 · 타입의 대수"),
    #(7, "TL3 · 구조 위의 추상화"),
    #(8, "TL4 · 토대와 한계"),
  ]
  |> list.filter_map(fn(pair) {
    let #(level, label) = pair
    case list.filter(units, fn(u) { u.meta.level == level }) {
      [] -> Error(Nil)
      group ->
        Ok(
          html.div([attribute.class("level-group")], [
            html.h3([attribute.class("level-group__title")], [html.text(label)]),
            units_list(group, completed, on_start),
          ]),
        )
    }
  })
}

fn unit_section(
  unit: schema.Unit,
  completed: List(String),
  on_start: fn(String) -> msg,
) -> Element(msg) {
  html.section([attribute.class("unit")], [
    html.h2([attribute.class("unit__title")], [html.text(unit.meta.title)]),
    html.div(
      [attribute.class("unit__lessons")],
      list.map(unit.lessons, fn(lesson) {
        lesson_card(lesson, list.contains(completed, lesson.id), on_start)
      }),
    ),
  ])
}

fn lesson_card(
  lesson: schema.Lesson,
  is_done: Bool,
  on_start: fn(String) -> msg,
) -> Element(msg) {
  let badge = case is_done {
    True -> html.span([attribute.class("lesson-card__badge")], [html.text("✓")])
    False -> element.none()
  }
  html.button(
    [
      attribute.class(case is_done {
        True -> "lesson-card lesson-card--done"
        False -> "lesson-card"
      }),
      event.on_click(on_start(lesson.id)),
    ],
    [
      html.span([attribute.class("lesson-card__title")], [
        html.text(lesson.title),
      ]),
      badge,
    ],
  )
}
