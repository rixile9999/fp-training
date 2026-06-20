import fpdojo/content/schema
import fpdojo/content/seed
import fpdojo/content/seed_en
import fpdojo/content/seed_theory
import fpdojo/content/seed_theory_en
import gleam/int
import gleam/list
import gleam/option
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// ── 한/영 콘텐츠 구조 동등성 ──────────────────────────────────────
//
// 영어 seed는 한국어 seed와 "구조가 1:1로 같다"는 불변식을 지켜야 한다 —
// 같은 unit/lesson/step id, 같은 정답 인덱스, 같은 블록 수·순서·보기 수.
// ui/app.switch_locale 의 relocalize(진행 위치 보존)와 채점 정합성이
// 이 불변식에 기댄다. 표시 문구(제목·prose·prompt·보기 텍스트·피드백)만
// 언어별로 다르고 골격은 동일해야 한다.

/// 한 유닛을 구조 지문(fingerprint) 문자열로 압축한다 — 텍스트는 빼고
/// id·정답·타입·구조만 남긴다. 두 언어의 지문이 같으면 구조가 동일하다.
fn unit_fingerprint(unit: schema.Unit) -> String {
  let lessons =
    unit.lessons
    |> list.map(lesson_fingerprint)
    |> string_join("|")
  unit.meta.id <> "#" <> int.to_string(unit.meta.level) <> "{" <> lessons <> "}"
}

fn lesson_fingerprint(lesson: schema.Lesson) -> String {
  let blocks =
    lesson.blocks
    |> list.map(block_fingerprint)
    |> string_join(",")
  lesson.id <> "[" <> blocks <> "]"
}

fn block_fingerprint(block: schema.LessonBlock) -> String {
  case block {
    schema.Prose(seg, _md) -> "P:" <> seg
    schema.Exercise(step) ->
      "E:"
      <> step.id
      <> ":"
      <> int.to_string(list.length(step.choices))
      <> ":"
      <> option.unwrap(step.answer, "_")
  }
}

fn string_join(parts: List(String), sep: String) -> String {
  case parts {
    [] -> ""
    [head, ..rest] -> list.fold(rest, head, fn(acc, p) { acc <> sep <> p })
  }
}

fn assert_units_equivalent(
  ko: List(schema.Unit),
  en: List(schema.Unit),
) -> Nil {
  let ko_fp = list.map(ko, unit_fingerprint)
  let en_fp = list.map(en, unit_fingerprint)
  assert ko_fp == en_fp
  Nil
}

pub fn practical_structure_equivalence_test() {
  assert_units_equivalent(seed.units(), seed_en.units())
}

pub fn theory_structure_equivalence_test() {
  assert_units_equivalent(
    seed_theory.theory_units(),
    seed_theory_en.theory_units(),
  )
}
