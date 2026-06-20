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
import { getCookie, setCookie, deleteCookie } from "hono/cookie";
import { config } from "./config.mjs";
import { client } from "./llm.mjs";
import { getHistory, commitTurn, reset, windowed } from "./memory.mjs";
import { verifyGoogleIdToken, makeSessionToken, readSessionToken, sessionCookie } from "./auth.mjs";
import { upsertUser, getUser, appendEvent, completedLessonIds } from "./store.mjs";
import { analyze } from "./analytics.mjs";

const app = new Hono();

// 선택적 공유 토큰 게이트(AGENT_API_TOKEN 설정 시에만 활성).
app.use("/api/*", async (c, next) => {
  if (config.apiToken && c.req.header("x-agent-token") !== config.apiToken) {
    return c.json({ error: "unauthorized" }, 401);
  }
  await next();
});

app.get("/api/health", (c) => c.json({ ok: true }));

// ── 인증 (구글 로그인) ─────────────────────────────────────────────

// 현재 세션의 유저 프로필(없으면 null). 쿠키만 신뢰한다.
function currentUser(c) {
  const userId = readSessionToken(getCookie(c, sessionCookie.name));
  if (!userId) return null;
  return getUser(userId)?.profile ?? null;
}

// 로그인 가능 여부 + 프론트가 GIS 초기화에 쓸 client id.
app.get("/api/auth/config", (c) =>
  c.json({ enabled: !!config.googleClientId, client_id: config.googleClientId ?? null }),
);

// 현재 로그인 상태.
app.get("/api/auth/me", (c) => c.json({ user: currentUser(c) }));

// 구글 ID 토큰(credential) 검증 → 유저 upsert → 세션 쿠키 발급.
app.post("/api/auth/google", async (c) => {
  if (!config.googleClientId) return c.json({ error: "login_disabled" }, 503);
  let body;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: "invalid_json" }, 400);
  }
  const credential = typeof body?.credential === "string" ? body.credential : "";
  if (!credential) return c.json({ error: "bad_request" }, 400);

  let claims;
  try {
    claims = await verifyGoogleIdToken(credential, config.googleClientId);
  } catch (e) {
    console.error("[auth] verify failed:", e?.message ?? String(e));
    return c.json({ error: "invalid_token" }, 401);
  }

  const profile = await upsertUser(claims);
  setCookie(c, sessionCookie.name, makeSessionToken(profile.id), {
    ...sessionCookie.options,
    maxAge: sessionCookie.maxAge,
  });
  return c.json({ user: profile });
});

// 로그아웃 — 쿠키 삭제.
app.post("/api/auth/logout", (c) => {
  deleteCookie(c, sessionCookie.name, { path: "/" });
  return c.json({ ok: true });
});

// ── 학습 진행/이벤트 ───────────────────────────────────────────────

// 완료 레슨 목록(하이드레이션용). 비로그인은 401 → 프론트는 인메모리 유지.
app.get("/api/progress", (c) => {
  const user = currentUser(c);
  if (!user) return c.json({ error: "unauthorized" }, 401);
  return c.json({ completed: completedLessonIds(user.id) });
});

// 이벤트 1건 적재(lesson_started / lesson_completed / exercise_submitted 등).
app.post("/api/progress/event", async (c) => {
  const user = currentUser(c);
  if (!user) return c.json({ error: "unauthorized" }, 401);
  let body;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: "invalid_json" }, 400);
  }
  const result = await appendEvent(user.id, body ?? {});
  if (!result?.ok) return c.json({ error: "store_error" }, 500);
  return c.json({ ok: true, completed: completedLessonIds(user.id) });
});

// 대시보드 분석(학습속도·성실성·완료목록). 커버리지 맵은 프론트가 합성.
app.get("/api/dashboard", (c) => {
  const user = currentUser(c);
  if (!user) return c.json({ error: "unauthorized" }, 401);
  const data = getUser(user.id);
  return c.json({ user, analytics: analyze(data?.events ?? []) });
});

app.post("/api/chat", async (c) => {
  // DASHSCOPE_API_KEY 미설정이면 채팅 비활성(로그인/진행/대시보드는 계속 동작).
  if (!config.chatEnabled) return c.json({ error: "chat_disabled" }, 503);
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
