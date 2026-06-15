//// 코딩 어시스턴트 사이드바 (우측, 모든 라우트에 상주).
////
//// pages/* 와 같은 규약: ui/app 을 import 하지 않고 메시지 생성자/값을 인자로
//// 받아 자기 msg 를 모른 채 이벤트만 위임한다(역방향 의존 금지, msg 제네릭).
//// 타입은 fpdojo/ui/chat 에서만 가져온다.

import fpdojo/ui/chat.{type ChatMsg, type ChatState, ChatMsg}
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// `state`: 채팅 상태. 나머지는 ui/app 이 주입하는 메시지 생성자/값.
/// - `on_input`: 입력 변경(값 운반)  - `on_submit`: 전송  - `on_toggle`: 열기/닫기
/// - `on_reset`: 대화 비우기
pub fn view(
  state: ChatState,
  on_input: fn(String) -> msg,
  on_submit: msg,
  on_toggle: msg,
  on_reset: msg,
) -> Element(msg) {
  case state.open {
    False -> fab(on_toggle)
    True -> panel(state, on_input, on_submit, on_toggle, on_reset)
  }
}

/// 접힌 상태: 우하단 플로팅 버튼.
fn fab(on_toggle: msg) -> Element(msg) {
  html.button(
    [
      attribute.class("chat-fab"),
      attribute.title("코딩 도우미 열기"),
      event.on_click(on_toggle),
    ],
    [html.text("💬")],
  )
}

/// 펼친 상태: 헤더 + 로그 + 입력.
fn panel(
  state: ChatState,
  on_input: fn(String) -> msg,
  on_submit: msg,
  on_toggle: msg,
  on_reset: msg,
) -> Element(msg) {
  html.aside([attribute.class("chat-panel")], [
    head(on_toggle, on_reset),
    log(state),
    composer(state, on_input, on_submit),
  ])
}

fn head(on_toggle: msg, on_reset: msg) -> Element(msg) {
  html.header([attribute.class("chat-panel__head")], [
    html.span([attribute.class("chat-panel__title")], [html.text("코딩 도우미")]),
    html.div([attribute.class("chat-panel__actions")], [
      icon_button("대화 비우기", "🗑", on_reset),
      icon_button("닫기", "✕", on_toggle),
    ]),
  ])
}

fn icon_button(label: String, glyph: String, msg: msg) -> Element(msg) {
  html.button(
    [
      attribute.class("chat-panel__icon-btn"),
      attribute.title(label),
      attribute.type_("button"),
      event.on_click(msg),
    ],
    [html.text(glyph)],
  )
}

fn log(state: ChatState) -> Element(msg) {
  let bubbles = case state.messages {
    [] -> [hint()]
    msgs -> list.map(msgs, bubble)
  }
  let items = case state.streaming {
    True -> list.append(bubbles, [typing()])
    False -> bubbles
  }
  html.div([attribute.class("chat-panel__log")], items)
}

fn hint() -> Element(msg) {
  html.div([attribute.class("chat-hint")], [
    html.text("Gleam·함수형 프로그래밍에 대해 무엇이든 물어보세요."),
  ])
}

fn bubble(m: ChatMsg) -> Element(msg) {
  let ChatMsg(role:, text:) = m
  html.div([attribute.class("chat-bubble chat-bubble--" <> role)], [
    html.text(text),
  ])
}

fn typing() -> Element(msg) {
  html.div([attribute.class("chat-bubble chat-bubble--assistant chat-bubble--typing")], [
    html.text("…"),
  ])
}

fn composer(
  state: ChatState,
  on_input: fn(String) -> msg,
  on_submit: msg,
) -> Element(msg) {
  // <form> 의 submit 은 Enter(단일행 input) 와 전송 버튼 양쪽에서 발화한다.
  // on_submit 은 자동으로 prevent_default 되므로 페이지 새로고침은 없다.
  // 폼데이터는 무시하고 Model 의 draft 를 신뢰한다.
  html.form(
    [attribute.class("chat-composer"), event.on_submit(fn(_) { on_submit })],
    [
      html.input([
        attribute.class("chat-composer__input"),
        attribute.value(state.draft),
        attribute.placeholder("코딩 질문을 입력하세요…"),
        attribute.disabled(state.streaming),
        attribute.autocomplete("off"),
        event.on_input(on_input),
      ]),
      html.button(
        [
          attribute.class("chat-composer__send"),
          attribute.type_("submit"),
          attribute.disabled(state.streaming),
        ],
        [html.text(case state.streaming {
          True -> "…"
          False -> "보내기"
        })],
      ),
    ],
  )
}
