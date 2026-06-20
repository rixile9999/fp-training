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

import fpdojo/auth
import fpdojo/content/schema
import fpdojo/content/seed
import fpdojo/content/seed_en
import fpdojo/content/seed_theory
import fpdojo/content/seed_theory_en
import fpdojo/core/locale.{type Locale, En, Ko}
import fpdojo/core/types
import fpdojo/dashboard
import fpdojo/engine/grading
import fpdojo/platform
import fpdojo/session/lesson
import fpdojo/ui/chat
import fpdojo/ui/components/chat_panel
import fpdojo/ui/pages/dashboard as dashboard_page
import fpdojo/ui/pages/home
import fpdojo/ui/pages/lesson as lesson_page
import gleam/dict
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
import lustre/event
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
    /// 레슨 시작 시각(ms) — 완료 시 소요시간(duration_ms) 이벤트 계산용.
    started_ms: Int,
  )
}

/// 전역 모델.
pub type Model {
  Model(
    route: Route,
    /// 표시 언어 — 상단 토글로 전환. 콘텐츠/UI 모두 이 값으로 투영한다.
    locale: Locale,
    /// 활성 언어로 투영된 실용 트랙 유닛(아래 _ko/_en 중 locale 선택본).
    units: List(schema.Unit),
    /// 활성 언어로 투영된 FP 이론 트랙 유닛
    /// (병렬 트랙 — docs/design/fp-theory-curriculum.md).
    theory_units: List(schema.Unit),
    /// 완료한 레슨 id. 게스트면 인메모리(새로고침 시 초기화), 로그인 시 서버에서
    /// 하이드레이션되고 완료마다 서버에 이벤트로 적재된다(영속).
    completed: List(String),
    lesson: Option(LessonState),
    /// 코딩 어시스턴트 사이드바 상태(전 라우트 상주). 진짜 대화 메모리는
    /// 서버(server/)가 보유하고, 여기는 렌더 미러 + session_id 만 든다.
    chat: chat.ChatState,
    /// 인증 상태(선택형 로그인). None user = 게스트.
    auth: auth.AuthState,
    /// 대시보드 분석(로그인 + Dashboard 라우트 진입 시 서버에서 로드).
    dashboard: Option(dashboard.Dashboard),
  )
}

pub type Msg {
  UserNavigated(route: Route)
  /// 상단 언어 토글 — 콘텐츠/UI를 통째로 해당 언어 투영으로 바꾼다.
  ChangedLocale(locale: Locale)
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
  // ── 인증 / 진행상황 영속화 ──
  /// 부팅 시 /api/auth/config 응답 — 로그인 가능 여부 + client_id.
  GotAuthConfig(result: Result(#(Bool, Option(String)), rsvp.Error(String)))
  /// 부팅 시 /api/auth/me 응답 — 기존 세션 복원.
  GotMe(result: Result(Option(auth.User), rsvp.Error(String)))
  /// GIS 콜백 — 구글 ID 토큰(JWT). 서버로 보내 검증한다.
  GoogleCredential(credential: String)
  /// /api/auth/google 응답 — 로그인 확정.
  LoggedIn(result: Result(Option(auth.User), rsvp.Error(String)))
  /// 사용자가 로그아웃 클릭.
  RequestedLogout
  /// /api/auth/logout 응답.
  LoggedOut(result: Result(Nil, rsvp.Error(String)))
  /// /api/progress 응답 — 완료 레슨 하이드레이션.
  GotProgress(result: Result(List(String), rsvp.Error(String)))
  /// /api/progress/event 응답 — 서버가 갱신한 완료 목록.
  EventPosted(result: Result(List(String), rsvp.Error(String)))
  /// /api/dashboard 응답.
  GotDashboard(result: Result(dashboard.Dashboard, rsvp.Error(String)))
}

/// 언어별 실용 트랙 유닛. 콘텐츠는 한/영 seed에 1:1 구조로 나뉘어 있다.
fn units_for(locale: Locale) -> List(schema.Unit) {
  case locale {
    Ko -> seed.units()
    En -> seed_en.units()
  }
}

/// 언어별 이론 트랙 유닛.
fn theory_units_for(locale: Locale) -> List(schema.Unit) {
  case locale {
    Ko -> seed_theory.theory_units()
    En -> seed_theory_en.theory_units()
  }
}

pub fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  #(
    Model(
      route: Home,
      locale: Ko,
      units: units_for(Ko),
      theory_units: theory_units_for(Ko),
      completed: [],
      lesson: None,
      chat: chat.ChatState(
        open: False,
        session_id: platform.new_uuid(),
        draft: "",
        messages: [],
        streaming: False,
      ),
      auth: auth.initial(),
      dashboard: None,
    ),
    // 부팅: 로그인 가능 여부 + 기존 세션을 병렬로 확인.
    effect.batch([fetch_auth_config(), fetch_me()]),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserNavigated(route) -> {
      // 대시보드 진입 + 로그인 상태면 분석을 서버에서 로드한다.
      let eff = case route, auth.is_logged_in(model.auth) {
        Dashboard, True -> fetch_dashboard()
        _, _ -> effect.none()
      }
      #(Model(..model, route: route), eff)
    }

    ChangedLocale(loc) -> #(switch_locale(model, loc), effect.none())

    ReturnedHome -> #(Model(..model, route: Home, lesson: None), effect.none())

    StartedLesson(id) ->
      case lookup_lesson(model, id) {
        Ok(l) -> {
          let now = platform.now_ms()
          let session = lesson.start(l, now)
          #(
            Model(
              ..model,
              route: Lesson,
              lesson: Some(LessonState(
                lesson: l,
                session: session,
                selected: None,
                result: None,
                started_ms: now,
              )),
            ),
            post_event(model, started_event(l)),
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
          // 레슨을 막 끝냈고 로그인 상태면 완료 이벤트를 서버에 적재(영속).
          let eff = case completed {
            True -> post_event(model, completed_event(ls))
            False -> effect.none()
          }
          #(Model(..model, completed: done, lesson: Some(ls2)), eff)
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
            locale.t(
              model.locale,
              "죄송해요, 지금 답변을 가져오지 못했어요. 잠시 후 다시 시도해 주세요.",
              "Sorry, I couldn't get a response right now. Please try again shortly.",
            ),
          ),
        ])
      #(
        Model(
          ..model,
          chat: chat.ChatState(..cs, messages: messages, streaming: False),
        ),
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

    // ── 인증 / 진행상황 ──
    GotAuthConfig(Ok(#(enabled, client_id))) -> {
      let auth =
        auth.AuthState(..model.auth, enabled: enabled, client_id: client_id)
      #(Model(..model, auth: auth), maybe_render_login(auth))
    }
    GotAuthConfig(Error(_)) -> #(model, effect.none())

    GotMe(Ok(user)) -> {
      let auth = auth.AuthState(..model.auth, user: user, checked: True)
      let eff = case user {
        // 기존 세션 복원 → 완료 레슨 하이드레이션.
        Some(_) -> fetch_progress()
        None -> maybe_render_login(auth)
      }
      #(Model(..model, auth: auth), eff)
    }
    GotMe(Error(_)) -> #(
      Model(..model, auth: auth.AuthState(..model.auth, checked: True)),
      effect.none(),
    )

    GoogleCredential(credential) -> #(model, post_credential(credential))

    LoggedIn(Ok(Some(user))) -> {
      let auth = auth.AuthState(..model.auth, user: Some(user))
      // 로그인 직후: 진행 하이드레이션 + (대시보드에 있으면) 분석 로드.
      let eff = case model.route {
        Dashboard -> effect.batch([fetch_progress(), fetch_dashboard()])
        _ -> fetch_progress()
      }
      #(Model(..model, auth: auth), eff)
    }
    LoggedIn(_) -> #(model, effect.none())

    RequestedLogout -> {
      // 낙관적으로 게스트로 되돌린다(완료/대시보드 비우기) + 서버 쿠키 삭제.
      let auth = auth.AuthState(..model.auth, user: None)
      #(
        Model(..model, auth: auth, completed: [], dashboard: None),
        effect.batch([
          post_logout(),
          disable_auto_select_effect(),
          maybe_render_login(auth),
        ]),
      )
    }
    LoggedOut(_) -> #(model, effect.none())

    GotProgress(Ok(ids)) -> #(
      Model(..model, completed: union(model.completed, ids)),
      effect.none(),
    )
    GotProgress(Error(_)) -> #(model, effect.none())

    EventPosted(Ok(ids)) -> #(
      Model(..model, completed: union(model.completed, ids)),
      effect.none(),
    )
    EventPosted(Error(_)) -> #(model, effect.none())

    GotDashboard(Ok(d)) -> #(Model(..model, dashboard: Some(d)), effect.none())
    GotDashboard(Error(_)) -> #(model, effect.none())
  }
}

/// 언어 전환 — 콘텐츠/UI를 새 언어 투영으로 바꾼다. 진행 중 레슨이 있으면
/// 같은 레슨 id를 새 언어 트랙에서 다시 찾아 세션을 relocalize(진행 위치 보존,
/// 한/영 구조가 1:1 동일하다는 불변식에 의존)하고 제목도 번역본으로 교체한다.
fn switch_locale(model: Model, loc: Locale) -> Model {
  let units = units_for(loc)
  let theory = theory_units_for(loc)
  let lesson = case model.lesson {
    None -> None
    Some(ls) ->
      case find_lesson(units, theory, ls.lesson.id) {
        Ok(translated) -> {
          let session = lesson.relocalize(ls.session, translated)
          Some(
            LessonState(
              ..ls,
              lesson: translated,
              session: session,
              result: relocalized_result(session, ls.result),
            ),
          )
        }
        Error(_) -> Some(ls)
      }
  }
  Model(
    ..model,
    locale: loc,
    units: units,
    theory_units: theory,
    lesson: lesson,
  )
}

/// 결과 피드백 문구는 제출 시점에 채점기가 만든 스냅샷이라 언어 전환 시 옛 언어로
/// 남는다. 결과 화면(정답)에서 보이는 정답 피드백만큼은 번역본 step의 "correct"
/// 항목으로 다시 도출해 일관성을 맞춘다. 오답 인라인 피드백(distractor별)은
/// feedback_key를 보존하지 않으므로 스냅샷을 그대로 둔다(재시도 중 잠깐만 노출).
fn relocalized_result(
  session: lesson.LessonSession,
  result: Option(#(Bool, String)),
) -> Option(#(Bool, String)) {
  case result {
    Some(#(True, _)) ->
      case lesson.current_block(session) {
        Some(schema.Exercise(step)) ->
          Some(#(True, feedback_entry(step, "correct", "정답입니다! 잘했어요.")))
        _ -> result
      }
    _ -> result
  }
}

fn feedback_entry(step: schema.Step, key: String, fallback: String) -> String {
  case dict.get(step.feedback.entries, key) {
    Ok(text) -> text
    Error(_) -> fallback
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

// ── 인증 / 진행상황 Effect (same-origin /api/*, 쿠키 기반) ──────────

fn fetch_auth_config() -> Effect(Msg) {
  rsvp.get(
    "/api/auth/config",
    rsvp.expect_json(auth.config_decoder(), GotAuthConfig),
  )
}

fn fetch_me() -> Effect(Msg) {
  rsvp.get("/api/auth/me", rsvp.expect_json(auth.me_decoder(), GotMe))
}

fn fetch_progress() -> Effect(Msg) {
  rsvp.get("/api/progress", rsvp.expect_json(completed_decoder(), GotProgress))
}

fn fetch_dashboard() -> Effect(Msg) {
  rsvp.get(
    "/api/dashboard",
    rsvp.expect_json(dashboard.decoder(), GotDashboard),
  )
}

fn post_credential(credential: String) -> Effect(Msg) {
  let body = json.object([#("credential", json.string(credential))])
  rsvp.post(
    "/api/auth/google",
    body,
    rsvp.expect_json(auth.me_decoder(), LoggedIn),
  )
}

fn post_logout() -> Effect(Msg) {
  rsvp.post(
    "/api/auth/logout",
    json.object([]),
    rsvp.expect_json(decode.success(Nil), LoggedOut),
  )
}

/// 진행 이벤트 적재 — 로그인 상태에서만 보낸다(게스트는 no-op).
fn post_event(model: Model, body: json.Json) -> Effect(Msg) {
  case auth.is_logged_in(model.auth) {
    False -> effect.none()
    True ->
      rsvp.post(
        "/api/progress/event",
        body,
        rsvp.expect_json(completed_decoder(), EventPosted),
      )
  }
}

/// `{ completed: [...] }` → List(String).
fn completed_decoder() -> decode.Decoder(List(String)) {
  use completed <- decode.field("completed", decode.list(decode.string))
  decode.success(completed)
}

fn started_event(l: schema.Lesson) -> json.Json {
  json.object([
    #("type", json.string("lesson_started")),
    #("lesson_id", json.string(l.id)),
    #("unit_id", json.string(l.unit_id)),
    #("track", json.string(lesson_track(l))),
  ])
}

fn completed_event(ls: LessonState) -> json.Json {
  let duration = int_max(0, platform.now_ms() - ls.started_ms)
  json.object([
    #("type", json.string("lesson_completed")),
    #("lesson_id", json.string(ls.lesson.id)),
    #("unit_id", json.string(ls.lesson.unit_id)),
    #("track", json.string(lesson_track(ls.lesson))),
    #("duration_ms", json.int(duration)),
  ])
}

/// 트랙 판별 — 이론 유닛 id는 "tu" 접두(seed_theory), 실용은 "u" 접두(seed).
fn lesson_track(l: schema.Lesson) -> String {
  case string.starts_with(l.unit_id, "tu") {
    True -> "theory"
    False -> "practical"
  }
}

/// 로그인 버튼 렌더 Effect — 로그인 가능 + client_id 있을 때만. 비로그인 뷰에
/// #gsi-button div 가 그려진 뒤 GIS 버튼을 주입한다(Effect는 렌더 후 실행).
fn maybe_render_login(a: auth.AuthState) -> Effect(Msg) {
  case a.enabled, a.client_id, a.user {
    True, Some(cid), None ->
      effect.from(fn(dispatch) {
        auth.render_google_button("#gsi-button", cid, fn(cred) {
          dispatch(GoogleCredential(cred))
        })
      })
    _, _, _ -> effect.none()
  }
}

fn disable_auto_select_effect() -> Effect(Msg) {
  effect.from(fn(_dispatch) { auth.disable_auto_select() })
}

/// 두 문자열 리스트의 합집합(순서: 기존 + 새 항목).
fn union(a: List(String), b: List(String)) -> List(String) {
  list.fold(b, a, fn(acc, x) {
    case list.contains(acc, x) {
      True -> acc
      False -> [x, ..acc]
    }
  })
}

fn int_max(a: Int, b: Int) -> Int {
  case a > b {
    True -> a
    False -> b
  }
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
  find_lesson(model.units, model.theory_units, id)
}

/// 주어진 두 트랙 목록에서 레슨 id로 조회 (언어 전환 시 번역본 재조회에도 쓴다).
fn find_lesson(
  units: List(schema.Unit),
  theory: List(schema.Unit),
  id: String,
) -> Result(schema.Lesson, Nil) {
  list.append(units, theory)
  |> list.flat_map(fn(u) { u.lessons })
  |> list.find(fn(l) { l.id == id })
}

pub fn view(model: Model) -> Element(Msg) {
  // 라우트별 페이지를 먼저 계산한 뒤, 앱 셸로 감싸 채팅 사이드바를 전 화면에
  // 상주시킨다(Lesson 의 중첩 분기는 그대로 보존).
  let page = case model.route {
    Home ->
      home.view(
        model.locale,
        model.units,
        model.theory_units,
        model.completed,
        StartedLesson,
      )
    Lesson ->
      case model.lesson {
        Some(ls) ->
          lesson_page.view(
            model.locale,
            ls.lesson.title,
            ls.session,
            ls.selected,
            ls.result,
            SelectedChoice,
            SubmittedAnswer,
            ContinuedLesson,
            ReturnedHome,
          )
        None ->
          home.view(
            model.locale,
            model.units,
            model.theory_units,
            model.completed,
            StartedLesson,
          )
      }
    Dashboard ->
      dashboard_page.view(
        model.locale,
        model.dashboard,
        list.append(model.units, model.theory_units),
        model.completed,
      )
    _ -> placeholder(model.locale)
  }
  html.div([attribute.class("app-shell")], [
    top_bar(model),
    html.main([attribute.class("app-main")], [page]),
    chat_panel.view(
      model.locale,
      model.chat,
      ChatInputChanged,
      ChatSubmitted,
      ChatToggled,
      ChatReset,
    ),
  ])
}

/// 상단 바 — 모든 라우트 상주. 좌측: 내비(홈·대시보드, 로그인 시), 우측: 언어
/// 토글 + 인증 영역(게스트=구글 버튼 / 로그인=프로필+로그아웃).
fn top_bar(model: Model) -> Element(Msg) {
  html.div([attribute.class("top-bar")], [
    html.div([attribute.class("top-bar__nav")], nav_links(model)),
    html.div([attribute.class("top-bar__right")], [
      html.div([attribute.class("lang-bar")], [
        lang_button("한국어", Ko, model.locale),
        lang_button("English", En, model.locale),
      ]),
      auth_area(model),
    ]),
  ])
}

/// 로그인 상태에서만 홈/대시보드 내비를 보여준다(게스트는 대시보드 없음).
fn nav_links(model: Model) -> List(Element(Msg)) {
  case auth.is_logged_in(model.auth) {
    False -> []
    True -> [
      nav_button(locale.t(model.locale, "학습", "Learn"), Home, model.route),
      nav_button(
        locale.t(model.locale, "대시보드", "Dashboard"),
        Dashboard,
        model.route,
      ),
    ]
  }
}

fn nav_button(label: String, target: Route, active: Route) -> Element(Msg) {
  let cls = case target == active {
    True -> "nav-btn nav-btn--active"
    False -> "nav-btn"
  }
  html.button(
    [
      attribute.class(cls),
      attribute.type_("button"),
      event.on_click(UserNavigated(target)),
    ],
    [html.text(label)],
  )
}

/// 인증 영역: 로그인 → 아바타+이름+로그아웃. 게스트+가능 → 구글 버튼 슬롯
/// (#gsi-button, GIS가 주입). 게스트+불가(서버에 client id 없음) → 아무것도 안 함.
fn auth_area(model: Model) -> Element(Msg) {
  case model.auth.user {
    Some(user) -> user_chip(model.locale, user)
    None ->
      case model.auth.enabled {
        // GIS 버튼이 주입될 빈 컨테이너 — vdom 자식은 항상 비워 둔다(주입물 보존).
        True ->
          html.div(
            [attribute.id("gsi-button"), attribute.class("gsi-slot")],
            [],
          )
        False -> element.none()
      }
  }
}

fn user_chip(loc: Locale, user: auth.User) -> Element(Msg) {
  let avatar = case user.picture {
    "" -> element.none()
    src ->
      html.img([
        attribute.class("user-chip__avatar"),
        attribute.src(src),
        attribute.alt(user.name),
        attribute.attribute("referrerpolicy", "no-referrer"),
      ])
  }
  html.div([attribute.class("user-chip")], [
    avatar,
    html.span([attribute.class("user-chip__name")], [html.text(user.name)]),
    html.button(
      [
        attribute.class("logout-btn"),
        attribute.type_("button"),
        event.on_click(RequestedLogout),
      ],
      [html.text(locale.t(loc, "로그아웃", "Sign out"))],
    ),
  ])
}

fn lang_button(label: String, target: Locale, active: Locale) -> Element(Msg) {
  let is_active = target == active
  let cls = case is_active {
    True -> "lang-btn lang-btn--active"
    False -> "lang-btn"
  }
  let pressed = case is_active {
    True -> "true"
    False -> "false"
  }
  html.button(
    [
      attribute.class(cls),
      attribute.type_("button"),
      attribute.aria_pressed(pressed),
      event.on_click(ChangedLocale(target)),
    ],
    [html.text(label)],
  )
}

fn placeholder(loc: Locale) -> Element(Msg) {
  home_shell([
    element.text(locale.t(loc, "이 화면은 준비 중입니다.", "This screen is coming soon.")),
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
