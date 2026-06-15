// 시간·uuid·난수 시드 원시 구현 (fpdojo/platform FFI — 실구현).

// 현재 시각 epoch millis.
export function nowMs() {
  return Date.now();
}

// uuid v4. secure context에서는 crypto.randomUUID, 아니면
// getRandomValues 기반 폴백(구형 webview/비-https 대비).
export function newUuid() {
  const c = globalThis.crypto;
  if (c && typeof c.randomUUID === "function") {
    return c.randomUUID();
  }
  const bytes = new Uint8Array(16);
  if (c && typeof c.getRandomValues === "function") {
    c.getRandomValues(bytes);
  } else {
    for (let i = 0; i < 16; i++) bytes[i] = Math.floor(Math.random() * 256);
  }
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
  const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
  return (
    hex.slice(0, 8) + "-" + hex.slice(8, 12) + "-" + hex.slice(12, 16) +
    "-" + hex.slice(16, 20) + "-" + hex.slice(20)
  );
}

// 의사난수 시드 — 31비트 양의 정수. 순수 계층(session/*)에 인자로 주입된다.
export function randomSeed() {
  return Math.floor(Math.random() * 0x7fffffff);
}
