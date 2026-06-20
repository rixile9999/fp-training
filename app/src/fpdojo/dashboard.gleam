//// 대시보드 분석 데이터 (서버 /api/dashboard 응답의 도메인 모델 + 디코더).
////
//// 서버(server/src/analytics.mjs)가 이벤트 로그에서 학습속도·성실성을 계산해
//// 내려주고, 커버리지(트랙/레벨/유닛 완료율)는 프론트가 자기 units 와 합쳐
//// 그린다(서버는 커리큘럼을 모름). 이 모듈은 그 응답을 디코드만 한다.
////
//// 의존 방향: 표준 라이브러리만. ui/pages/dashboard 와 ui/app 이 사용한다.

import gleam/dynamic/decode
import gleam/option.{type Option}

/// 하루치 완료 수(막대/히트맵용).
pub type DayCount {
  DayCount(date: String, count: Int)
}

/// 학습 속도 지표.
pub type Speed {
  Speed(
    lessons_total: Int,
    days_active: Int,
    lessons_per_active_day: Float,
    avg_lesson_ms: Option(Int),
    median_lesson_ms: Option(Int),
    recent: List(DayCount),
  )
}

/// 성실성·꾸준함 지표.
pub type Consistency {
  Consistency(
    current_streak: Int,
    longest_streak: Int,
    active_days: Int,
    span_days: Int,
    consistency_rate: Float,
    calendar: List(DayCount),
    by_weekday: List(Int),
  )
}

/// 대시보드 전체.
pub type Dashboard {
  Dashboard(speed: Speed, consistency: Consistency, events_count: Int)
}

// ── 디코더 ─────────────────────────────────────────────────────────

fn day_count_decoder() -> decode.Decoder(DayCount) {
  use date <- decode.field("date", decode.string)
  use count <- decode.field("count", decode.int)
  decode.success(DayCount(date: date, count: count))
}

fn speed_decoder() -> decode.Decoder(Speed) {
  use lessons_total <- decode.field("lessons_total", decode.int)
  use days_active <- decode.field("days_active", decode.int)
  use lpd <- decode.field("lessons_per_active_day", decode.float)
  use avg <- decode.field("avg_lesson_ms", decode.optional(decode.int))
  use median <- decode.field("median_lesson_ms", decode.optional(decode.int))
  use recent <- decode.field("recent", decode.list(day_count_decoder()))
  decode.success(Speed(
    lessons_total: lessons_total,
    days_active: days_active,
    lessons_per_active_day: lpd,
    avg_lesson_ms: avg,
    median_lesson_ms: median,
    recent: recent,
  ))
}

fn consistency_decoder() -> decode.Decoder(Consistency) {
  use current <- decode.field("current_streak", decode.int)
  use longest <- decode.field("longest_streak", decode.int)
  use active <- decode.field("active_days", decode.int)
  use span <- decode.field("span_days", decode.int)
  use rate <- decode.field("consistency_rate", decode.float)
  use calendar <- decode.field("calendar", decode.list(day_count_decoder()))
  use by_weekday <- decode.field("by_weekday", decode.list(decode.int))
  decode.success(Consistency(
    current_streak: current,
    longest_streak: longest,
    active_days: active,
    span_days: span,
    consistency_rate: rate,
    calendar: calendar,
    by_weekday: by_weekday,
  ))
}

/// `/api/dashboard` → { user, analytics: { speed, consistency, events_count } }.
pub fn decoder() -> decode.Decoder(Dashboard) {
  use analytics <- decode.field("analytics", analytics_decoder())
  decode.success(analytics)
}

fn analytics_decoder() -> decode.Decoder(Dashboard) {
  use speed <- decode.field("speed", speed_decoder())
  use consistency <- decode.field("consistency", consistency_decoder())
  use events_count <- decode.field("events_count", decode.int)
  decode.success(Dashboard(
    speed: speed,
    consistency: consistency,
    events_count: events_count,
  ))
}
