//// 대시보드 — 학습 진행 분석 시각화.
////
//// 서버(/api/dashboard, fpdojo/dashboard)가 준 학습속도·성실성 지표를 렌더하고,
//// 커버리지(트랙/레벨별 완료율)는 여기서 units + completed 로 계산해 그린다
//// (서버는 커리큘럼을 모름). 렌더 전용 — ui/app 을 import 하지 않고 값/메시지
//// 생성자를 인자로 받는다(역방향 의존 금지, msg 제네릭).

import fpdojo/content/schema
import fpdojo/core/locale.{type Locale}
import fpdojo/dashboard.{type Dashboard, type DayCount}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// `data`: 서버 분석(None=로딩 중). `units`: 두 트랙 합본(커버리지 계산용).
/// `completed`: 완료 레슨 id. (홈 이동은 상단 바 내비가 담당하므로 여긴 렌더 전용.)
pub fn view(
  locale: Locale,
  data: Option(Dashboard),
  units: List(schema.Unit),
  completed: List(String),
) -> Element(msg) {
  html.div([attribute.class("page page--dashboard")], [
    html.header([attribute.class("dash-header")], [
      html.h1([attribute.class("dash-title")], [
        html.text(locale.t(locale, "학습 대시보드", "Learning Dashboard")),
      ]),
      html.p([attribute.class("dash-subtitle")], [
        html.text(locale.t(
          locale,
          "학습 속도와 꾸준함, 커리큘럼 진척을 한눈에.",
          "Your learning pace, consistency, and curriculum progress at a glance.",
        )),
      ]),
    ]),
    case data {
      None -> loading(locale)
      Some(d) ->
        html.div([attribute.class("dash-grid")], [
          speed_section(locale, d),
          consistency_section(locale, d),
          coverage_section(locale, units, completed),
        ])
    },
  ])
}

fn loading(locale: Locale) -> Element(msg) {
  html.div([attribute.class("card dash-empty")], [
    html.text(locale.t(locale, "분석을 불러오는 중…", "Loading your analytics…")),
  ])
}

// ── 학습 속도 ──────────────────────────────────────────────────────

fn speed_section(locale: Locale, d: Dashboard) -> Element(msg) {
  let s = d.speed
  html.section([attribute.class("card dash-card")], [
    card_title(locale.t(locale, "학습 속도", "Learning Speed")),
    html.div([attribute.class("stat-row")], [
      stat(
        int.to_string(s.lessons_total),
        locale.t(locale, "완료 레슨", "lessons done"),
      ),
      stat(
        int.to_string(s.days_active),
        locale.t(locale, "학습한 날", "active days"),
      ),
      stat(
        float.to_string(s.lessons_per_active_day),
        locale.t(locale, "하루 평균 레슨", "lessons / active day"),
      ),
      stat(
        format_duration_opt(locale, s.avg_lesson_ms),
        locale.t(locale, "레슨당 평균 시간", "avg time / lesson"),
      ),
    ]),
    html.h3([attribute.class("chart-label")], [
      html.text(locale.t(locale, "최근 14일 완료", "Completions · last 14 days")),
    ]),
    bar_chart(s.recent),
  ])
}

/// 막대 차트 — 일별 완료 수. 최대값 기준 상대 높이.
fn bar_chart(days: List(DayCount)) -> Element(msg) {
  let max = list.fold(days, 1, fn(m, d) { int.max(m, d.count) })
  html.div(
    [attribute.class("bars")],
    list.map(days, fn(d) {
      let pct = d.count * 100 / max
      html.div(
        [
          attribute.class("bars__col"),
          attribute.title(d.date <> ": " <> int.to_string(d.count)),
        ],
        [
          html.div(
            [
              attribute.class(case d.count {
                0 -> "bars__bar bars__bar--empty"
                _ -> "bars__bar"
              }),
              attribute.style("height", int.to_string(pct) <> "%"),
            ],
            [],
          ),
        ],
      )
    }),
  )
}

// ── 성실성·꾸준함 ──────────────────────────────────────────────────

fn consistency_section(locale: Locale, d: Dashboard) -> Element(msg) {
  let c = d.consistency
  html.section([attribute.class("card dash-card")], [
    card_title(locale.t(locale, "성실성 · 꾸준함", "Consistency")),
    html.div([attribute.class("stat-row")], [
      stat(
        int.to_string(c.current_streak) <> day_unit(locale),
        locale.t(locale, "현재 연속", "current streak"),
      ),
      stat(
        int.to_string(c.longest_streak) <> day_unit(locale),
        locale.t(locale, "최장 연속", "longest streak"),
      ),
      stat(
        float.to_string(c.consistency_rate) <> "%",
        locale.t(locale, "꾸준함 지수", "consistency rate"),
      ),
    ]),
    html.h3([attribute.class("chart-label")], [
      html.text(locale.t(locale, "최근 12주 학습 히트맵", "Activity · last 12 weeks")),
    ]),
    heatmap(c.calendar),
    html.h3([attribute.class("chart-label")], [
      html.text(locale.t(locale, "요일별 학습", "By weekday")),
    ]),
    weekday_bars(locale, c.by_weekday),
  ])
}

/// 히트맵 — 84일을 날짜순 그리드로. 완료 수에 따라 강도 클래스.
fn heatmap(days: List(DayCount)) -> Element(msg) {
  html.div(
    [attribute.class("heatmap")],
    list.map(days, fn(d) {
      html.div(
        [
          attribute.class(
            "heatmap__cell heatmap__cell--l"
            <> int.to_string(intensity(d.count)),
          ),
          attribute.title(d.date <> ": " <> int.to_string(d.count)),
        ],
        [],
      )
    }),
  )
}

fn intensity(count: Int) -> Int {
  case count {
    0 -> 0
    1 -> 1
    2 -> 2
    3 -> 3
    _ -> 4
  }
}

/// 요일 분포 막대(일~토). by_weekday 는 [일,월,화,수,목,금,토].
fn weekday_bars(locale: Locale, by_weekday: List(Int)) -> Element(msg) {
  let labels = weekday_labels(locale)
  let max = list.fold(by_weekday, 1, fn(m, n) { int.max(m, n) })
  let pairs = list.zip(labels, by_weekday)
  html.div(
    [attribute.class("weekbars")],
    list.map(pairs, fn(p) {
      let #(label, n) = p
      let pct = n * 100 / max
      html.div([attribute.class("weekbars__col")], [
        html.div([attribute.class("weekbars__track")], [
          html.div(
            [
              attribute.class("weekbars__fill"),
              attribute.style("height", int.to_string(pct) <> "%"),
            ],
            [],
          ),
        ]),
        html.span([attribute.class("weekbars__label")], [html.text(label)]),
      ])
    }),
  )
}

fn weekday_labels(locale: Locale) -> List(String) {
  case locale {
    locale.Ko -> ["일", "월", "화", "수", "목", "금", "토"]
    locale.En -> ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
  }
}

// ── 커버리지 맵 ────────────────────────────────────────────────────

fn coverage_section(
  locale: Locale,
  units: List(schema.Unit),
  completed: List(String),
) -> Element(msg) {
  let #(p_units, t_units) = list.partition(units, fn(u) { u.meta.level <= 4 })
  let #(done_all, total_all) = tally(units, completed)
  html.section([attribute.class("card dash-card dash-card--wide")], [
    card_title(locale.t(locale, "커버리지", "Coverage")),
    progress_row(
      locale.t(locale, "전체", "Overall"),
      done_all,
      total_all,
      "track--overall",
    ),
    track_coverage(
      locale.t(locale, "실용 트랙", "Practical"),
      p_units,
      completed,
      "track--practical",
    ),
    track_coverage(
      locale.t(locale, "FP 이론 트랙", "Theory"),
      t_units,
      completed,
      "track--theory",
    ),
    html.div(
      [attribute.class("unit-coverage")],
      list.map(units, fn(u) { unit_coverage_row(u, completed) }),
    ),
  ])
}

fn track_coverage(
  label: String,
  units: List(schema.Unit),
  completed: List(String),
  cls: String,
) -> Element(msg) {
  case units {
    [] -> element.none()
    _ -> {
      let #(done, total) = tally(units, completed)
      progress_row(label, done, total, cls)
    }
  }
}

fn unit_coverage_row(
  unit: schema.Unit,
  completed: List(String),
) -> Element(msg) {
  let total = list.length(unit.lessons)
  let done = count_done(unit.lessons, completed)
  let cls = case done == total && total > 0 {
    True -> "unit-cov unit-cov--complete"
    False -> "unit-cov"
  }
  html.div([attribute.class(cls)], [
    html.span([attribute.class("unit-cov__name")], [html.text(unit.meta.title)]),
    html.span([attribute.class("unit-cov__count")], [
      html.text(int.to_string(done) <> "/" <> int.to_string(total)),
    ]),
  ])
}

fn progress_row(
  label: String,
  done: Int,
  total: Int,
  cls: String,
) -> Element(msg) {
  let pct = case total {
    0 -> 0
    _ -> done * 100 / total
  }
  html.div([attribute.class("cov-row " <> cls)], [
    html.div([attribute.class("cov-row__head")], [
      html.span([attribute.class("cov-row__label")], [html.text(label)]),
      html.span([attribute.class("cov-row__pct")], [
        html.text(
          int.to_string(pct)
          <> "%  ("
          <> int.to_string(done)
          <> "/"
          <> int.to_string(total)
          <> ")",
        ),
      ]),
    ]),
    html.div([attribute.class("cov-bar")], [
      html.div(
        [
          attribute.class("cov-bar__fill"),
          attribute.style("width", int.to_string(pct) <> "%"),
        ],
        [],
      ),
    ]),
  ])
}

// ── 집계 헬퍼 ──────────────────────────────────────────────────────

fn tally(units: List(schema.Unit), completed: List(String)) -> #(Int, Int) {
  list.fold(units, #(0, 0), fn(acc, u) {
    let #(d, t) = acc
    #(d + count_done(u.lessons, completed), t + list.length(u.lessons))
  })
}

fn count_done(lessons: List(schema.Lesson), completed: List(String)) -> Int {
  list.fold(lessons, 0, fn(n, l) {
    case list.contains(completed, l.id) {
      True -> n + 1
      False -> n
    }
  })
}

// ── 작은 조각 ──────────────────────────────────────────────────────

fn card_title(text: String) -> Element(msg) {
  html.h2([attribute.class("dash-card__title")], [html.text(text)])
}

fn stat(value: String, label: String) -> Element(msg) {
  html.div([attribute.class("stat")], [
    html.span([attribute.class("stat__value")], [html.text(value)]),
    html.span([attribute.class("stat__label")], [html.text(label)]),
  ])
}

fn day_unit(locale: Locale) -> String {
  locale.t(locale, "일", "d")
}

fn format_duration_opt(locale: Locale, ms: Option(Int)) -> String {
  case ms {
    None -> "—"
    Some(v) -> format_duration(locale, v)
  }
}

fn format_duration(locale: Locale, ms: Int) -> String {
  let secs = ms / 1000
  let m = secs / 60
  let s = secs % 60
  case m {
    0 -> int.to_string(s) <> locale.t(locale, "초", "s")
    _ ->
      int.to_string(m)
      <> locale.t(locale, "분 ", "m ")
      <> int.to_string(s)
      <> locale.t(locale, "초", "s")
  }
}
