//// Lustre SPA 루트 — MVU 엔트리 (PLAN §5.1 스택 결정, interfaces.md "ui/*").
////
//// 역할: 라우팅 + 전역 Model 보유 + Effect 해석. 도메인 결정은 session/*
//// 순수 상태머신에 위임하고, 이 모듈은 그들이 반환한 커맨드(LessonCmd 등)를
//// 해석하는 어댑터다. 비결정성(now_ms 등)은 이 계층에서만 fpdojo/platform으로
//// 읽어 순수 계층에 인자로 주입한다.
////
//// M1 슬라이스: 컴파일러 없이 동작하는 레슨 학습 루프. 콘텐츠는
//// content/seed(임베드), 채점은 grading.grade_step_sync(무컴파일 동기).
//// RunGrade 커맨드를 동기로 해석하므로 Effect/Promise 왕복이 없다 —
//// 컴파일러 도입 시 이 지점만 비동기 Effect로 바뀐다.
////
//// 의존 방향: ui/app → ui/pages/*, content/seed, session/lesson,
//// engine/grading, core/types, platform. 역방향 import 금지.

import fpdojo/content/schema
import fpdojo/content/seed
import fpdojo/content/seed_theory
import fpdojo/core/types
import fpdojo/engine/grading
import fpdojo/platform
import fpdojo/session/lesson
import fpdojo/ui/chat
import fpdojo/ui/components/chat_panel
import fpdojo/ui/pages/home
import fpdojo/ui/pages/lesson as lesson_page
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import rsvp

/// SPA 라우트. M1에서는 Home·Lesson만 실동작하고 나머지는 "준비 중" 안내.
pub type Route {
  Home
  Lesson
  Onboarding
  Training
  Review
  Dashboard
}

/// 활성 레슨의 UI 상태 — 순수 세션 + 화면 로컬 상태(선택·결과).
pub type LessonState {
  LessonState(
    lesson: schema.Lesson,
    session: lesson.LessonSession,
    /// 현재 선택한 보기 인덱스 (제출 전). 결과 표시 중엔 채점된 선택.
    selected: Option(Int),
    /// 채점 결과: #(정답 여부, 피드백 문구). None이면 아직 미채점.
    result: Option(#(Bool, String)),
  )
}

/// 전역 모델.
pub type Model {
  Model(
    route: Route,
    units: List(schema.Unit),
    /// FP 이론 트랙 유닛(병렬 트랙 — docs/design/fp-theory-curriculum.md).
    theory_units: List(schema.Unit),
    /// 완료한 레슨 id (M1: 인메모리 — 새로고침 시 초기화. 영속화는 후속).
    completed: List(String),
    lesson: Option(LessonState),
    /// 코딩 어시스턴트 사이드바 상태(전 라우트 상주). 진짜 대화 메모리는
    /// 서버(server/)가 보유하고, 여기는 렌더 미러 + session_id 만 든다.
    chat: chat.ChatState,
  )
}

pub type Msg {
  UserNavigated(route: Route)
  StartedLesson(lesson_id: String)
  SelectedChoice(index: Int)
  SubmittedAnswer
  ContinuedLesson
  ReturnedHome
  // ── 채팅 사이드바 ──
  ChatToggled
  ChatInputChanged(value: String)
  ChatSubmitted
  ChatResponse(result: Result(chat.ChatReply, rsvp.Error(String)))
  ChatReset
}

pub fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  #(
    Model(
      route: Home,
      units: seed.units(),
      theory_units: seed_theory.theory_units(),
      completed: [],
      lesson: None,
      chat: chat.ChatState(
        open: False,
        session_id: platform.new_uuid(),
        draft: "",
        messages: [],
        streaming: False,
      ),
    ),
    effect.none(),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigated(route) -> #(Model(..model, route: route), effect.none())

    ReturnedHome -> #(Model(..model, route: Home, lesson: None), effect.none())

    StartedLesson(id) ->
      case lookup_lesson(model, id) {
        Ok(l) -> {
          let session = lesson.start(l, platform.now_ms())
          #(
            Model(
              ..model,
              route: Lesson,
              lesson: Some(LessonState(
                lesson: l,
                session: session,
                selected: None,
                result: None,
              )),
            ),
            effect.none(),
          )
        }
        Error(_) -> #(model, effect.none())
      }

    SelectedChoice(index) ->
      case model.lesson {
        Some(ls) ->
          // 연습 풀이 중에만 선택 가능(정답 후 결과 화면에선 불가).
          // 새 선택 시 이전 오답 피드백은 지운다.
          case lesson.status(ls.session) {
            lesson.AtExercise -> #(
              Model(
                ..model,
                lesson: Some(
                  LessonState(..ls, selected: Some(index), result: None),
                ),
              ),
              effect.none(),
            )
            _ -> #(model, effect.none())
          }
        None -> #(model, effect.none())
      }

    SubmittedAnswer ->
      case model.lesson {
        Some(ls) -> #(
          Model(..model, lesson: Some(submit_answer(ls))),
          effect.none(),
        )
        None -> #(model, effect.none())
      }

    ContinuedLesson ->
      case model.lesson {
        Some(ls) -> {
          let #(ls2, completed) = continue_lesson(ls)
          let done = case completed {
            True -> add_unique(model.completed, ls.lesson.id)
            False -> model.completed
          }
          #(Model(..model, completed: done, lesson: Some(ls2)), effect.none())
        }
        None -> #(model, effect.none())
      }

    ChatToggled -> {
      let open = case model.chat.open {
        True -> False
        False -> True
      }
      #(
        Model(..model, chat: chat.ChatState(..model.chat, open: open)),
        effect.none(),
      )
    }

    ChatInputChanged(value) -> #(
      Model(..model, chat: chat.ChatState(..model.chat, draft: value)),
      effect.none(),
    )

    ChatSubmitted -> {
      let text = string.trim(model.chat.draft)
      case text, model.chat.streaming {
        // 빈 입력이거나 이미 대기 중이면 무시.
        "", _ -> #(model, effect.none())
        _, True -> #(model, effect.none())
        _, False -> {
          let cs = model.chat
          // 낙관적으로 user 버블을 붙이고 입력 잠금. 서버가 진짜 메모리를 갱신한다.
          let messages = list.append(cs.messages, [chat.ChatMsg("user", text)])
          let cs2 =
            chat.ChatState(..cs, draft: "", messages: messages, streaming: True)
          #(Model(..model, chat: cs2), send_chat(cs.session_id, text))
        }
      }
    }

    ChatResponse(Ok(reply)) -> {
      let cs = model.chat
      let messages =
        list.append(cs.messages, [chat.ChatMsg("assistant", reply.text)])
      #(
        Model(
          ..model,
          chat: chat.ChatState(
            ..cs,
            session_id: reply.session_id,
            messages: messages,
            streaming: False,
          ),
        ),
        effect.none(),
      )
    }

    ChatResponse(Error(_)) -> {
      let cs = model.chat
      let messages =
        list.append(cs.messages, [
          chat.ChatMsg(
            "system",
            "죄송해요, 지금 답변을 가져오지 못했어요. 잠시 후 다시 시도해 주세요.",
          ),
        ])
      #(
        Model(..model, chat: chat.ChatState(..cs, messages: messages, streaming: False)),
        effect.none(),
      )
    }

    // 대화 비우기 — 새 session_id 를 발급해 서버 측 새 대화로 전환(기존 세션은
    // 서버 인메모리에 남았다가 재시작 시 정리됨). 별도 왕복 불필요.
    ChatReset -> #(
      Model(
        ..model,
        chat: chat.ChatState(
          ..model.chat,
          draft: "",
          messages: [],
          streaming: False,
          session_id: platform.new_uuid(),
        ),
      ),
      effect.none(),
    )
  }
}

/// POST /api/chat 응답 디코더.
fn reply_decoder() -> decode.Decoder(chat.ChatReply) {
  use session_id <- decode.field("session_id", decode.string)
  use text <- decode.field("text", decode.string)
  decode.success(chat.ChatReply(session_id: session_id, text: text))
}

/// 사이드바 전송 Effect — same-origin 상대 URL("/api/chat")로 POST.
/// (브라우저는 DashScope 를 직접 접촉하지 않는다 → connect-src 'self' 유지.)
fn send_chat(session_id: String, prompt: String) -> Effect(Msg) {
  let body =
    json.object([
      #("session_id", json.string(session_id)),
      #("message", json.string(prompt)),
    ])
  rsvp.post("/api/chat", body, rsvp.expect_json(reply_decoder(), ChatResponse))
}

/// 제출 → 동기 채점 → 결과 반영. RunGrade를 그 자리에서 grade_step_sync로
/// 해석하고 Graded를 즉시 회송한다(무컴파일이라 Promise 불필요).
fn submit_answer(ls: LessonState) -> LessonState {
  case ls.selected {
    None -> ls
    Some(index) -> {
      let now = platform.now_ms()
      let submission = types.ChoiceAnswer(index)
      let #(s1, cmds1) =
        lesson.handle(ls.session, lesson.Submitted(submission), now)
      case find_run_grade(cmds1) {
        Some(#(step, sub)) -> {
          let report = grading.grade_step_sync(step, sub)
          let #(s2, cmds2) = lesson.handle(s1, lesson.Graded(report), now)
          let correct = report.outcome == types.Passed
          let message = find_feedback(cmds2)
          LessonState(..ls, session: s2, result: Some(#(correct, message)))
        }
        None -> LessonState(..ls, session: s1)
      }
    }
  }
}

/// "계속" → 다음 블록. 완료 커맨드가 나오면 True 반환.
fn continue_lesson(ls: LessonState) -> #(LessonState, Bool) {
  let now = platform.now_ms()
  let #(s2, cmds) = lesson.handle(ls.session, lesson.Continued, now)
  let completed = list.any(cmds, is_completed_cmd)
  #(LessonState(..ls, session: s2, selected: None, result: None), completed)
}

fn find_run_grade(
  cmds: List(lesson.LessonCmd),
) -> Option(#(schema.Step, types.Submission)) {
  list.fold(cmds, None, fn(acc, cmd) {
    case cmd {
      lesson.RunGrade(step, sub) -> Some(#(step, sub))
      _ -> acc
    }
  })
}

fn find_feedback(cmds: List(lesson.LessonCmd)) -> String {
  list.fold(cmds, "", fn(acc, cmd) {
    case cmd {
      lesson.ShowFeedback(md) -> md
      _ -> acc
    }
  })
}

fn is_completed_cmd(cmd: lesson.LessonCmd) -> Bool {
  case cmd {
    lesson.LessonCompleted -> True
    _ -> False
  }
}

fn add_unique(xs: List(String), x: String) -> List(String) {
  case list.contains(xs, x) {
    True -> xs
    False -> [x, ..xs]
  }
}

/// 두 트랙(실용 + 이론)을 통틀어 레슨 id로 조회한다.
fn lookup_lesson(model: Model, id: String) -> Result(schema.Lesson, Nil) {
  list.append(model.units, model.theory_units)
  |> list.flat_map(fn(u) { u.lessons })
  |> list.find(fn(l) { l.id == id })
}

pub fn view(model: Model) -> Element(Msg) {
  // 라우트별 페이지를 먼저 계산한 뒤, 앱 셸로 감싸 채팅 사이드바를 전 화면에
  // 상주시킨다(Lesson 의 중첩 분기는 그대로 보존).
  let page = case model.route {
    Home -> home.view(model.units, model.theory_units, model.completed, StartedLesson)
    Lesson ->
      case model.lesson {
        Some(ls) ->
          lesson_page.view(
            ls.lesson.title,
            ls.session,
            ls.selected,
            ls.result,
            SelectedChoice,
            SubmittedAnswer,
            ContinuedLesson,
            ReturnedHome,
          )
        None -> home.view(model.units, model.theory_units, model.completed, StartedLesson)
      }
    _ -> placeholder(model.route)
  }
  html.div([attribute.class("app-shell")], [
    html.main([attribute.class("app-main")], [page]),
    chat_panel.view(
      model.chat,
      ChatInputChanged,
      ChatSubmitted,
      ChatToggled,
      ChatReset,
    ),
  ])
}

fn placeholder(_route: Route) -> Element(Msg) {
  home_shell([
    element.text("이 화면은 준비 중입니다."),
  ])
}

fn home_shell(children: List(Element(Msg))) -> Element(Msg) {
  element.fragment(children)
}

/// 앱 부트: index.html의 #app에 마운트.
pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
