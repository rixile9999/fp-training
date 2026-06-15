// localStorage 원시 접근 어댑터 (fpdojo/storage/local FFI — 실구현).
//
// 이 파일은 예외 → Gleam Result 변환만 담당한다. JSON 직렬화·스키마 버전·
// 컴팩션 로직은 전부 Gleam 쪽(local.gleam)의 책임 (FFI 3접점 격리, PLAN R8).

import { Ok, Error as GError } from "../../gleam.mjs";

// localStorage 사용 가능 여부 (프라이빗 모드, 샌드박스 iframe, 쿠키 차단 등 탐지).
// getItem만으로는 SecurityError를 못 잡는 환경이 있어 실제 쓰기로 프로브한다.
export function isAvailable() {
  try {
    const probe = "__fpdojo_probe__";
    globalThis.localStorage.setItem(probe, "1");
    globalThis.localStorage.removeItem(probe);
    return true;
  } catch (_e) {
    return false;
  }
}

// 키 조회 → Result(String, Nil). Error(Nil) = 키 없음(또는 접근 불가 —
// 가용성은 isAvailable로 선판별하는 것이 Gleam 쪽 계약).
export function getItem(key) {
  try {
    const value = globalThis.localStorage.getItem(key);
    return value === null ? new GError(undefined) : new Ok(value);
  } catch (_e) {
    return new GError(undefined);
  }
}

// 키 저장 → Result(Nil, String). Error 페이로드 = 예외 name —
// "QuotaExceededError"는 Gleam 쪽에서 QuotaExceeded로 매핑한다.
export function setItem(key, value) {
  try {
    globalThis.localStorage.setItem(key, value);
    return new Ok(undefined);
  } catch (e) {
    return new GError(e && e.name ? e.name : String(e));
  }
}

// 키 삭제. 실패해도 무해(베스트 에포트) — Nil(undefined) 반환.
export function removeItem(key) {
  try {
    globalThis.localStorage.removeItem(key);
  } catch (_e) {
    // 접근 불가 환경에서는 지울 것도 없음
  }
  return undefined;
}
