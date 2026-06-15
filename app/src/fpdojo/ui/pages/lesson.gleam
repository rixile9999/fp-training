//// 레슨 — 설명 세그먼트 × 마이크로 연습 교차 진행 화면 (PLAN §3.2).
////
//// session/lesson.LessonSession(순수 상태머신)의 투영을 렌더만 한다:
//// lesson.status로 화면 분기(설명/연습/결과/완료), current_block으로 내용,
//// progress_ratio로 진행 바. 채점·전이는 ui/app이 한다. ui/app을 import하지
//// 않고 메시지 생성자를 인자로 받는다(역방향 의존 금지, msg 제네릭).

import fpdojo/content/schema
import fpdojo/session/lesson.{type LessonSession}
import fpdojo/ui/markdown
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// `title`: 레슨 제목. `session`: 순수 세션. `selected`/`result`: 화면 로컬 상태.
/// 나머지는 메시지 생성자/값 — app이 자기 Msg를 주입한다.
pub fn view(
  title: String,
  session: LessonSession,
  selected: Option(Int),
  result: Option(#(Bool, String)),
  on_select: fn(Int) -> msg,
  on_submit: msg,
  on_continue: msg,
  on_home: msg,
) -> Element(msg) {
  html.div([attribute.class("page page--lesson")], [
    lesson_header(title, session, on_home),
    html.div([attribute.class("lesson-body")], [
      body(
        session,
        selected,
        result,
        on_select,
        on_submit,
        on_continue,
        on_home,
      ),
    ]),
  ])
}

fn lesson_header(
  title: String,
  session: LessonSession,
  on_home: msg,
) -> Element(msg) {
  let pct = float.round(lesson.progress_ratio(session) *. 100.0)
  html.header([attribute.class("lesson-header")], [
    html.button([attribute.class("link-back"), event.on_click(on_home)], [
      html.text("← 목록"),
    ]),
    html.span([attribute.class("lesson-header__title")], [html.text(title)]),
    html.div([attribute.class("progress")], [
      html.div(
        [
          attribute.class("progress__bar"),
          attribute.style("width", int.to_string(pct) <> "%"),
        ],
        [],
      ),
    ]),
  ])
}

fn body(
  session: LessonSession,
  selected: Option(Int),
  result: Option(#(Bool, String)),
  on_select: fn(Int) -> msg,
  on_submit: msg,
  on_continue: msg,
  on_home: msg,
) -> Element(msg) {
  case lesson.status(session) {
    lesson.AtProse -> prose_view(session, on_continue)
    lesson.AtExercise ->
      exercise_view(session, selected, result, on_select, on_submit)
    lesson.AtResult -> result_view(session, selected, result, on_continue)
    lesson.AtEnd -> end_view(on_home)
  }
}

fn prose_view(session: LessonSession, on_continue: msg) -> Element(msg) {
  case lesson.current_block(session) {
    Some(schema.Prose(_, md)) ->
      html.div([attribute.class("card card--prose")], [
        markdown.render(md),
        primary_button("계속", on_continue),
      ])
    _ -> element.none()
  }
}

fn exercise_view(
  session: LessonSession,
  selected: Option(Int),
  result: Option(#(Bool, String)),
  on_select: fn(Int) -> msg,
  on_submit: msg,
) -> Element(msg) {
  case current_step(session) {
    Some(step) ->
      html.div([attribute.class("card card--exercise")], [
        html.p([attribute.class("exercise__prompt")], markdown.inline(step.prompt_md)),
        code_block(step.starter),
        choice_list(step.choices, selected, None, on_select),
        // 오답 후 재시도 중이면 피드백을 인라인으로 보여준다(무벌점 재시도, PLAN §3.2)
        retry_feedback(result),
        submit_button(selected, on_submit),
      ])
    None -> element.none()
  }
}

/// AtExercise 상태에서 직전 오답 피드백 표시 (정답이면 AtResult로 가므로 여긴 항상 오답).
fn retry_feedback(result: Option(#(Bool, String))) -> Element(msg) {
  case result {
    Some(#(False, message)) -> feedback_banner(False, message)
    _ -> element.none()
  }
}

fn result_view(
  session: LessonSession,
  selected: Option(Int),
  result: Option(#(Bool, String)),
  on_continue: msg,
) -> Element(msg) {
  case current_step(session) {
    Some(step) -> {
      let #(correct, message) = case result {
        Some(r) -> r
        None -> #(False, "")
      }
      html.div([attribute.class("card card--exercise")], [
        html.p([attribute.class("exercise__prompt")], markdown.inline(step.prompt_md)),
        code_block(step.starter),
        choice_list(
          step.choices,
          selected,
          Some(#(correct, answer_index(step))),
          fn(_) { on_continue },
        ),
        feedback_banner(correct, message),
        primary_button("계속", on_continue),
      ])
    }
    None -> element.none()
  }
}

fn end_view(on_home: msg) -> Element(msg) {
  html.div([attribute.class("card card--done")], [
    html.h2([attribute.class("done__title")], [html.text("레슨 완료! 🎉")]),
    html.p([], [html.text("잘 해냈어요. 다음 레슨으로 이어가 보세요.")]),
    primary_button("목록으로", on_home),
  ])
}

// ── 작은 조각들 ───────────────────────────────────────────────────

/// 보기 목록. `verdict`가 Some(#(correct, answer_idx))이면 결과 색칠 모드
/// (정답=초록, 내가 고른 오답=빨강), None이면 선택 모드.
fn choice_list(
  choices: List(String),
  selected: Option(Int),
  verdict: Option(#(Bool, Int)),
  on_select: fn(Int) -> msg,
) -> Element(msg) {
  html.div(
    [attribute.class("choices")],
    list.index_map(choices, fn(choice, i) {
      html.button(
        [
          attribute.class(choice_class(i, selected, verdict)),
          attribute.disabled(verdict != None),
          event.on_click(on_select(i)),
        ],
        markdown.inline(choice),
      )
    }),
  )
}

fn choice_class(
  i: Int,
  selected: Option(Int),
  verdict: Option(#(Bool, Int)),
) -> String {
  let base = "choice"
  case verdict {
    Some(#(_, answer_idx)) ->
      case i == answer_idx, selected == Some(i) {
        True, _ -> base <> " choice--correct"
        False, True -> base <> " choice--wrong"
        False, False -> base
      }
    None ->
      case selected == Some(i) {
        True -> base <> " choice--selected"
        False -> base
      }
  }
}

fn submit_button(selected: Option(Int), on_submit: msg) -> Element(msg) {
  html.button(
    [
      attribute.class("btn btn--primary"),
      attribute.disabled(selected == None),
      event.on_click(on_submit),
    ],
    [html.text("제출")],
  )
}

fn primary_button(label: String, msg: msg) -> Element(msg) {
  html.button([attribute.class("btn btn--primary"), event.on_click(msg)], [
    html.text(label),
  ])
}

fn feedback_banner(correct: Bool, message: String) -> Element(msg) {
  let cls = case correct {
    True -> "feedback feedback--correct"
    False -> "feedback feedback--wrong"
  }
  let mark = case correct {
    True -> "정답"
    False -> "다시"
  }
  html.div([attribute.class(cls)], [
    html.span([attribute.class("feedback__mark")], [html.text(mark)]),
    html.span([attribute.class("feedback__text")], markdown.inline(message)),
  ])
}

fn code_block(code: String) -> Element(msg) {
  case code {
    "" -> element.none()
    _ -> html.pre([attribute.class("code")], [html.code([], [html.text(code)])])
  }
}

// ── 세션 투영 헬퍼 ────────────────────────────────────────────────

fn current_step(session: LessonSession) -> Option(schema.Step) {
  case lesson.current_block(session) {
    Some(schema.Exercise(step)) -> Some(step)
    _ -> None
  }
}

fn answer_index(step: schema.Step) -> Int {
  case step.answer {
    Some(s) ->
      case int.parse(s) {
        Ok(n) -> n
        Error(_) -> -1
      }
    None -> -1
  }
}
