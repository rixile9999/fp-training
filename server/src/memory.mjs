// 세션 메모리 — "비스므리한 쓰기 편한 툴". Map<sessionId, messages[]> 누산기.
// (Microsoft Agent Framework 의 AgentSession 도 내부적으로 메시지 배열을 들고
//  매 턴 다시 보내는 방식이라, 여기선 그 핵심만 직접 구현한다.)
//
// 진실의 원천은 이 Map 이다(서버 권위). 클라이언트는 session_id(UUID)만 보관한다.
// 메모리 안에서는 전체 히스토리를 보존하고, DashScope 로 보낼 때만 windowed() 로
// 토큰/비용을 제한한다(시스템 프롬프트는 절대 잘라내지 않는다).

import { config } from "./config.mjs";

const SESSIONS = new Map();

const SYSTEM = {
  role: "system",
  content:
    "You are a patient, precise coding tutor embedded in 'fpdojo', a learning app " +
    "that teaches functional programming in the Gleam language. Prefer short, correct, " +
    "idiomatic Gleam; explain your reasoning briefly. When relevant, connect answers to " +
    "core FP ideas (immutability, pattern matching, pure functions, types, recursion over " +
    "iteration). If a question is ambiguous, ask one brief clarifying question instead of " +
    "guessing. Reply in the same language the user writes in (Korean or English).",
};

/** 세션의 전체 히스토리 배열을 돌려준다(없으면 시스템 프롬프트로 시드). */
export function getHistory(id) {
  let h = SESSIONS.get(id);
  if (!h) {
    h = [{ ...SYSTEM }];
    SESSIONS.set(id, h);
  }
  return h;
}

/** 성공한 한 턴(user + assistant)을 원자적으로 커밋한다. 실패 시 호출하지 않는다. */
export function commitTurn(id, userMsg, assistantMsg) {
  const h = getHistory(id);
  h.push(userMsg, assistantMsg);
}

/** 대화 초기화. */
export function reset(id) {
  SESSIONS.delete(id);
}

/**
 * DashScope 전송용 윈도잉: 시스템 메시지는 전부 보존 + 최근 비-system 메시지 N개.
 * (naive 한 slice(-N) 이 시스템 프롬프트를 날려버리는 버그를 피한다.)
 */
export function windowed(history, maxNonSystem = config.maxHistoryMessages) {
  const system = history.filter((m) => m.role === "system");
  const rest = history.filter((m) => m.role !== "system");
  const tail = rest.slice(-maxNonSystem);
  return [...system, ...tail];
}
