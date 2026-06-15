//// 채팅 사이드바 공유 타입 — 리프 모듈.
////
//// ui/app 과 ui/components/chat_panel 이 함께 import 하므로, 둘 중 누구도
//// 상대를 역import 하지 않도록 타입을 여기에 둔다 (pages/* 가 ui/app 대신
//// content/schema 를 import 하는 패턴과 동일).
////
//// 진짜 대화 메모리는 서버(server/)가 보유한다. 클라이언트는 렌더용 미러와
//// session_id(서버 메모리를 가리키는 UUID)만 들고 있는다.

/// 한 말풍선. role 은 "user" | "assistant" | "system"("system"은 클라이언트
/// 측 에러 안내 버블에 사용).
pub type ChatMsg {
  ChatMsg(role: String, text: String)
}

/// 사이드바 채팅 상태 — 전역 Model 의 하위 레코드.
pub type ChatState {
  ChatState(
    /// 사이드바 펼침 여부.
    open: Bool,
    /// 백엔드 세션 id (브라우저당 1개, platform.new_uuid 로 생성).
    session_id: String,
    /// 입력 버퍼.
    draft: String,
    /// 렌더용 메시지 — 표시 순서(오래된 것이 앞). 서버가 진실의 원천.
    messages: List(ChatMsg),
    /// 응답 대기 중 (입력·전송 비활성화).
    streaming: Bool,
  )
}

/// POST /api/chat 성공 응답의 디코드 결과.
pub type ChatReply {
  ChatReply(session_id: String, text: String)
}
