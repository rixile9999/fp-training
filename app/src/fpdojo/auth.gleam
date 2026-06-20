//// 인증 상태 + 구글 로그인 연동 (FFI: auth_ffi.mjs).
////
//// 선택형 로그인: 로그인 없이도 학습 가능(게스트, 진행상황은 인메모리)하고,
//// 구글로 로그인하면 그때부터 서버(server/)가 진행상황·이벤트를 영속화한다.
//// 서버 권위 — 클라이언트는 httpOnly 세션 쿠키만 들고, 유저/진행은 API로 받는다.
////
//// 의존 방향: 표준 라이브러리만 import 하는 리프에 가깝다. ui/app 이 사용한다.

import gleam/dynamic/decode
import gleam/option.{type Option, None}

/// 로그인한 유저(서버 /api/auth/me·/google 응답).
pub type User {
  User(id: String, email: String, name: String, picture: String)
}

/// 인증 상태. `enabled`=서버에 GOOGLE_CLIENT_ID 설정됨(로그인 버튼 노출 여부).
/// `checked`=초기 세션 확인(/me) 완료. `user`=로그인 상태(None이면 게스트).
pub type AuthState {
  AuthState(
    enabled: Bool,
    client_id: Option(String),
    user: Option(User),
    checked: Bool,
  )
}

pub fn initial() -> AuthState {
  AuthState(enabled: False, client_id: None, user: None, checked: False)
}

pub fn is_logged_in(auth: AuthState) -> Bool {
  case auth.user {
    option.Some(_) -> True
    None -> False
  }
}

// ── 디코더 ─────────────────────────────────────────────────────────

/// `/api/auth/config` → #(enabled, client_id).
pub fn config_decoder() -> decode.Decoder(#(Bool, Option(String))) {
  use enabled <- decode.field("enabled", decode.bool)
  use client_id <- decode.field("client_id", decode.optional(decode.string))
  decode.success(#(enabled, client_id))
}

fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.string)
  use email <- decode.field("email", decode.string)
  use name <- decode.field("name", decode.string)
  use picture <- decode.field("picture", decode.string)
  decode.success(User(id: id, email: email, name: name, picture: picture))
}

/// `/api/auth/me` 및 `/api/auth/google` → { user: User | null } → Option(User).
pub fn me_decoder() -> decode.Decoder(Option(User)) {
  use user <- decode.field("user", decode.optional(user_decoder()))
  decode.success(user)
}

// ── FFI (Google Identity Services) ─────────────────────────────────

/// selector 요소에 구글 로그인 버튼을 렌더한다. `on_credential`은 로그인 성공 시
/// ID 토큰(JWT)으로 호출된다 — ui/app 이 이를 메시지로 바꿔 서버 검증을 건다.
@external(javascript, "./auth_ffi.mjs", "renderGoogleButton")
pub fn render_google_button(
  selector: String,
  client_id: String,
  on_credential: fn(String) -> Nil,
) -> Nil

/// 로그아웃 시 자동 재로그인(One Tap auto-select) 비활성.
@external(javascript, "./auth_ffi.mjs", "disableAutoSelect")
pub fn disable_auto_select() -> Nil
