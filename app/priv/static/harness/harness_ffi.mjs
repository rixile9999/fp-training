// harness_ffi.mjs — harness.gleam의 rescue/emit FFI (PLAN §5.2, architecture.md §3.8).
//
// ⚠ 이 파일은 앱 번들이 아니다 — /precompiled/ 정적 자산으로 서빙되거나(브라우저
// 러너 워커), CI 골든 오라클(tools/golden)에서 핀 gleam이 src/ 에 co-locate해
// 컴파일·실행한다. gleam JS 빌드는 패키지별로 prelude를 gleam.mjs 로 co-locate하므로
// 아래 `./gleam.mjs` import 는 브라우저(/precompiled 재작성)·CLI(co-located) 양쪽에서
// 해석된다.
//
// stdout 프로토콜 (채점 계약의 전부 — runner_ffi.mjs / verify.mjs 가 파싱):
//   __<토큰>__|pass|<이름>
//   __<토큰>__|fail|<이름>|<메시지>
//
// 토큰: 브라우저는 runner.worker가 import 이전에 globalThis.__FPDOJO_RUN_TOKEN__ 주입
// (스푸핑 1차 방어, R7). CLI 오라클은 verify.mjs가 FPDOJO_RUN_TOKEN env로 주입.
// 둘 다 없으면 로컬 디버그용 "T" 폴백.

import { Ok, Error as GleamError } from "./gleam.mjs"; // 프렐류드 (co-located)

function token() {
  if (typeof globalThis !== "undefined" && globalThis.__FPDOJO_RUN_TOKEN__) {
    return globalThis.__FPDOJO_RUN_TOKEN__;
  }
  if (typeof process !== "undefined" && process.env && process.env.FPDOJO_RUN_TOKEN) {
    return process.env.FPDOJO_RUN_TOKEN;
  }
  return "T";
}

// assert 실패 객체의 구조화 필드가 *존재할 경우*만 메시지 보강(best-effort).
function unwrap(x) {
  return x && typeof x === "object" && "value" in x ? x.value : x;
}
function enrich(e) {
  const base = e && e.message ? e.message : String(e);
  try {
    if (e && e.left !== undefined && e.right !== undefined) {
      return base + " (expected " + str(unwrap(e.left)) + " == " + str(unwrap(e.right)) + ")";
    }
    if (e && Array.isArray(e.values) && e.values.length >= 2) {
      return base + " (expected " + str(unwrap(e.values[0])) + " == " + str(unwrap(e.values[1])) + ")";
    }
  } catch (_) {}
  return base;
}
function str(v) {
  try {
    return typeof v === "object" ? JSON.stringify(v) : String(v);
  } catch (_) {
    return String(v);
  }
}

/**
 * try/catch rescue — harness.suite가 테스트 본문마다 호출한다.
 * 반환: Gleam Result(Nil, String).
 */
export function rescue(body) {
  try {
    body();
    return new Ok(undefined);
  } catch (e) {
    return new GleamError(enrich(e));
  }
}

/** pass 라인 방출 — 러너 워커의 console.log 몽키패치 / verify.mjs 가 수집. */
export function emitPass(name) {
  console.log(`__${token()}__|pass|${name}`);
}

/** fail 라인 방출. 프로토콜이 라인 단위이므로 메시지 개행은 공백으로 정규화. */
export function emitFail(name, message) {
  const flat = String(message).replaceAll("\n", " ");
  console.log(`__${token()}__|fail|${name}|${flat}`);
}
