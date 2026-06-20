// DashScope(OpenAI 호환) 클라이언트. 키는 이 프로세스에만 존재하며,
// Authorization: Bearer 헤더로만 쓰이고 어떤 응답 본문에도 실리지 않는다.

import OpenAI from "openai";
import { config } from "./config.mjs";

// 키가 없으면 채팅 비활성 — 클라이언트를 만들지 않는다(서버는 계속 뜬다).
export const client = config.chatEnabled
  ? new OpenAI({ apiKey: config.apiKey, baseURL: config.baseURL })
  : null;
