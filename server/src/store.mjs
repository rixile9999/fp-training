// JSON 파일 영속화 — 유저별 단일 파일 + append-only 이벤트 로그.
//
// 진실의 원천은 server/data/ 아래 파일이다. 채팅 메모리(memory.mjs)가 인메모리
// Map 인 것과 달리, 학습 진행/이벤트는 새로고침·서버 재시작을 넘어 살아남아야
// 하므로 디스크에 둔다. 동시 쓰기 안전을 위해 쓰기는 tmp 파일 → rename 으로
// 원자화하고, 유저별 쓰기는 직렬화 큐로 직렬화한다(단일 프로세스 가정).
//
// 레이아웃:
//   data/users/<userId>.json   { profile, events: [...] }
//   data/.session_secret       세션 쿠키 서명 키(없으면 1회 생성)

import { mkdirSync, readFileSync, writeFileSync, renameSync, existsSync } from "node:fs";
import { randomBytes, randomUUID } from "node:crypto";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const DATA_DIR = process.env.FPDOJO_DATA_DIR ?? join(ROOT, "data");
const USERS_DIR = join(DATA_DIR, "users");

mkdirSync(USERS_DIR, { recursive: true });

// ── 세션 서명 키 ───────────────────────────────────────────────────
// env(SESSION_SECRET) 우선, 없으면 data/.session_secret 에 1회 생성·재사용.
// 파일에 두어 서버 재시작 후에도 기존 세션 쿠키가 유효하게 유지된다.
export function getSessionSecret() {
  if (process.env.SESSION_SECRET) return process.env.SESSION_SECRET;
  const path = join(DATA_DIR, ".session_secret");
  if (existsSync(path)) return readFileSync(path, "utf8").trim();
  const secret = randomBytes(32).toString("hex");
  writeFileSync(path, secret, { mode: 0o600 });
  return secret;
}

// ── 유저 파일 I/O ──────────────────────────────────────────────────

function userPath(id) {
  // id 는 google sub(숫자 문자열) 또는 안전한 토큰 — 경로 조작 방지로 화이트리스트.
  const safe = String(id).replace(/[^A-Za-z0-9_-]/g, "");
  if (!safe) throw new Error("invalid user id");
  return join(USERS_DIR, `${safe}.json`);
}

function readUser(id) {
  const path = userPath(id);
  if (!existsSync(path)) return null;
  try {
    return JSON.parse(readFileSync(path, "utf8"));
  } catch {
    return null;
  }
}

function writeUserAtomic(id, data) {
  const path = userPath(id);
  const tmp = `${path}.${process.pid}.${randomUUID()}.tmp`;
  writeFileSync(tmp, JSON.stringify(data, null, 2));
  renameSync(tmp, path);
}

// 유저별 쓰기 직렬화 — 같은 유저에 대한 read-modify-write 경합을 막는다.
const writeQueues = new Map();
function withUserLock(id, fn) {
  const prev = writeQueues.get(id) ?? Promise.resolve();
  const next = prev.then(fn, fn);
  // 큐가 무한정 자라지 않도록 완료 후 정리.
  writeQueues.set(
    id,
    next.catch(() => {}).finally(() => {
      if (writeQueues.get(id) === next) writeQueues.delete(id);
    }),
  );
  return next;
}

// ── 공개 API ───────────────────────────────────────────────────────

/** 유저 1명(profile + events)을 돌려준다. 없으면 null. */
export function getUser(id) {
  return readUser(id);
}

/**
 * 구글 프로필로 유저를 생성/갱신한다. 기존 events 는 보존하고 표시 정보만 최신화.
 * 반환: 저장된 profile.
 */
export function upsertUser(googleProfile) {
  const { sub, email, name, picture } = googleProfile;
  return withUserLock(sub, () => {
    const existing = readUser(sub);
    const now = Date.now();
    const profile = {
      id: sub,
      email: email ?? "",
      name: name ?? (email ? email.split("@")[0] : "user"),
      picture: picture ?? "",
      created_at: existing?.profile?.created_at ?? now,
      updated_at: now,
    };
    const data = { profile, events: existing?.events ?? [] };
    writeUserAtomic(sub, data);
    return profile;
  });
}

/**
 * append-only 이벤트 1건을 적재한다. 서버가 id·at_ms 를 부여한다(신뢰 경계).
 * `lesson_completed` 는 같은 lesson 의 첫 1건만 의미 있게 집계되지만 로그는 전부 남긴다.
 * 반환: { ok, events_count }.
 */
export function appendEvent(id, event) {
  return withUserLock(id, () => {
    const data = readUser(id);
    if (!data) return { ok: false };
    const stamped = {
      id: randomUUID(),
      at_ms: Date.now(),
      ...sanitizeEvent(event),
    };
    data.events.push(stamped);
    writeUserAtomic(id, data);
    return { ok: true, events_count: data.events.length };
  });
}

// 클라이언트 입력에서 허용 필드만 추린다(임의 키 적재 차단).
function sanitizeEvent(e) {
  const out = {};
  const type = typeof e?.type === "string" ? e.type : "unknown";
  out.type = type.slice(0, 40);
  if (typeof e?.lesson_id === "string") out.lesson_id = e.lesson_id.slice(0, 120);
  if (typeof e?.unit_id === "string") out.unit_id = e.unit_id.slice(0, 120);
  if (typeof e?.step_id === "string") out.step_id = e.step_id.slice(0, 120);
  if (typeof e?.track === "string") out.track = e.track.slice(0, 20);
  if (typeof e?.locale === "string") out.locale = e.locale.slice(0, 8);
  if (typeof e?.correct === "boolean") out.correct = e.correct;
  if (Number.isFinite(e?.duration_ms)) out.duration_ms = Math.max(0, Math.min(e.duration_ms, 86_400_000));
  if (Number.isFinite(e?.hints)) out.hints = Math.max(0, Math.min(e.hints | 0, 99));
  return out;
}

/** 완료한 레슨 id 집합(중복 제거) — lesson_completed 이벤트에서 도출. */
export function completedLessonIds(id) {
  const data = readUser(id);
  if (!data) return [];
  const seen = new Set();
  for (const ev of data.events) {
    if (ev.type === "lesson_completed" && ev.lesson_id) seen.add(ev.lesson_id);
  }
  return [...seen];
}
