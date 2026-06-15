// Hono 앱 — same-origin 프록시. 브라우저는 /api/* 만 호출하고, 키는 여기에만 있다.
//
// 라우트:
//   GET  /api/health        -> { ok: true }
//   POST /api/chat          { session_id, message } -> { session_id, text } | 4xx | 502
//   POST /api/chat/reset    { session_id }          -> { ok: true }
//
// 메모리 일관성 원칙: 히스토리는 "완전 성공"에서만 변이된다(user+assistant 원자 커밋).
// 업스트림 실패·빈 응답은 히스토리를 건드리지 않으므로 재시도해도 오염되지 않는다.

import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { config } from "./config.mjs";
import { client } from "./llm.mjs";
import { getHistory, commitTurn, reset, windowed } from "./memory.mjs";

const app = new Hono();

// 선택적 공유 토큰 게이트(AGENT_API_TOKEN 설정 시에만 활성).
app.use("/api/*", async (c, next) => {
  if (config.apiToken && c.req.header("x-agent-token") !== config.apiToken) {
    return c.json({ error: "unauthorized" }, 401);
  }
  await next();
});

app.get("/api/health", (c) => c.json({ ok: true }));

app.post("/api/chat", async (c) => {
  let body;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: "invalid_json" }, 400);
  }

  const session_id = typeof body?.session_id === "string" ? body.session_id : "";
  const message = typeof body?.message === "string" ? body.message : "";
  if (!session_id || !message.trim()) return c.json({ error: "bad_request" }, 400);
  if (message.length > config.maxMessageChars) {
    return c.json({ error: "message_too_long" }, 413);
  }

  // 히스토리는 아직 변이하지 않는다 — 전송용 배열만 임시로 만든다.
  const history = getHistory(session_id);
  const userMsg = { role: "user", content: message };
  const outgoing = windowed([...history, userMsg]);

  let completion;
  try {
    completion = await client.chat.completions.create({
      model: config.model,
      messages: outgoing,
    });
  } catch (e) {
    console.error("[chat] upstream error:", e?.status ?? "", scrub(e?.message ?? String(e)));
    return c.json({ error: "upstream", detail: scrub(e?.message ?? String(e)) }, 502);
  }

  const choice = completion?.choices?.[0];
  const text = choice?.message?.content ?? "";
  if (!text.trim()) {
    // 빈/거부 응답은 메모리에 넣지 않는다(맥락 오염 방지).
    const reason = choice?.finish_reason === "content_filter" ? "content_filter" : "empty_completion";
    return c.json({ error: reason }, 502);
  }

  // 성공 — user + assistant 원자 커밋.
  commitTurn(session_id, userMsg, { role: "assistant", content: text });
  return c.json({ session_id, text });
});

app.post("/api/chat/reset", async (c) => {
  let body;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: "invalid_json" }, 400);
  }
  const session_id = typeof body?.session_id === "string" ? body.session_id : "";
  if (!session_id) return c.json({ error: "bad_request" }, 400);
  reset(session_id);
  return c.json({ ok: true });
});

// 키나 토큰처럼 보이는 문자열은 절대 응답/로그로 새 나가지 않게 마스킹.
function scrub(s) {
  return String(s).replace(/sk-[A-Za-z0-9_-]+/g, "sk-***");
}

serve({ fetch: app.fetch, port: config.port, hostname: config.host }, (info) => {
  console.log(`[fpdojo-agent] listening on http://${config.host}:${info.port}  (model=${config.model})`);
});
