// 환경설정 1회 읽기·검증. 키는 이 모듈에서만 읽고 llm.mjs로만 흘려보낸다.
// (FFI/포트 격리 정신과 동일 — 키는 프로세스 밖으로 나가지 않는다.)

const API_KEY = process.env.DASHSCOPE_API_KEY;
if (!API_KEY) {
  console.warn(
    "[warn] DASHSCOPE_API_KEY 미설정 — AI 채팅 사이드바만 비활성화됩니다(로그인·진행저장·대시보드는 정상). 채팅을 쓰려면 server/.env 에 키를 넣으세요.",
  );
}

export const config = {
  apiKey: API_KEY ?? null,
  // 채팅(DashScope) 사용 가능 여부 — 키가 있을 때만.
  chatEnabled: !!API_KEY,
  // 기본값 = intl(싱가포르). 베이징 키면 DASHSCOPE_BASE_URL 로 바꾼다. region↔key 짝이 맞아야 함.
  baseURL:
    process.env.DASHSCOPE_BASE_URL ??
    "https://dashscope-intl.aliyuncs.com/compatible-mode/v1",
  model: process.env.DASHSCOPE_MODEL ?? "qwen-plus",
  port: Number(process.env.PORT ?? 8787),
  // 기본 127.0.0.1 바인드 — 외부에서 키 쿼터를 못 쓰게. 외부 노출이 필요하면 HOST=0.0.0.0 + AGENT_API_TOKEN.
  host: process.env.HOST ?? "127.0.0.1",
  // 설정 시 /api/* 가 X-Agent-Token 헤더를 요구(opt-in).
  apiToken: process.env.AGENT_API_TOKEN ?? null,
  // 단일 메시지 길이 상한(토큰/비용 폭주·악용 방지).
  maxMessageChars: Number(process.env.MAX_MESSAGE_CHARS ?? 8000),
  // DashScope 로 보낼 때 유지할 비-system 메시지 개수(시스템 프롬프트는 항상 보존).
  maxHistoryMessages: Number(process.env.MAX_HISTORY_MESSAGES ?? 24),
  // 구글 로그인 OAuth Client ID(웹). 미설정이면 로그인 비활성(게스트 전용) —
  // 프론트는 /api/auth/config 로 enabled 여부를 받아 버튼 노출을 결정한다.
  googleClientId: process.env.GOOGLE_CLIENT_ID ?? null,
};
