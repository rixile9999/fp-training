// 구글 로그인 + 세션 쿠키. 외부 의존성 없이 node:crypto 로 ID 토큰을 검증한다.
//
// 흐름: 브라우저가 Google Identity Services 로 받은 ID 토큰(JWT)을
// POST /api/auth/google 로 보내면, 여기서 Google JWKS 로 서명을 검증하고
// (iss/aud/exp 확인) 유저를 upsert 한 뒤, 서명된 httpOnly 쿠키를 내려준다.
// 이후 요청은 쿠키만으로 인증된다(stateless — 세션 저장소 불필요).

import { createPublicKey, verify as cryptoVerify, createHmac, timingSafeEqual } from "node:crypto";
import { getSessionSecret } from "./store.mjs";

const CERTS_URL = "https://www.googleapis.com/oauth2/v3/certs";
const VALID_ISS = new Set(["accounts.google.com", "https://accounts.google.com"]);
const SESSION_MAX_AGE = 60 * 60 * 24 * 30; // 30일(초)

// ── Google JWKS 캐시 ───────────────────────────────────────────────
let certCache = { keys: new Map(), expiresAt: 0 };

async function getGoogleKey(kid) {
  if (Date.now() < certCache.expiresAt && certCache.keys.has(kid)) {
    return certCache.keys.get(kid);
  }
  const res = await fetch(CERTS_URL);
  if (!res.ok) throw new Error(`jwks fetch failed: ${res.status}`);
  const body = await res.json();
  const keys = new Map();
  for (const jwk of body.keys ?? []) {
    keys.set(jwk.kid, createPublicKey({ key: jwk, format: "jwk" }));
  }
  // Cache-Control: max-age 만큼 캐시(없으면 1시간).
  const cc = res.headers.get("cache-control") ?? "";
  const m = /max-age=(\d+)/.exec(cc);
  const maxAge = m ? Number(m[1]) : 3600;
  certCache = { keys, expiresAt: Date.now() + maxAge * 1000 };
  return keys.get(kid) ?? null;
}

function b64urlToBuf(s) {
  return Buffer.from(s.replace(/-/g, "+").replace(/_/g, "/"), "base64");
}

/**
 * Google ID 토큰(JWT)을 검증하고 payload 를 돌려준다. 실패 시 throw.
 * clientId 가 주어지면 aud 일치도 강제한다.
 */
export async function verifyGoogleIdToken(jwt, clientId) {
  const parts = String(jwt).split(".");
  if (parts.length !== 3) throw new Error("malformed jwt");
  const [headerB64, payloadB64, sigB64] = parts;

  const header = JSON.parse(b64urlToBuf(headerB64).toString("utf8"));
  if (header.alg !== "RS256") throw new Error(`unexpected alg: ${header.alg}`);

  const key = await getGoogleKey(header.kid);
  if (!key) throw new Error("signing key not found");

  const signingInput = Buffer.from(`${headerB64}.${payloadB64}`);
  const ok = cryptoVerify("RSA-SHA256", signingInput, key, b64urlToBuf(sigB64));
  if (!ok) throw new Error("bad signature");

  const payload = JSON.parse(b64urlToBuf(payloadB64).toString("utf8"));
  const now = Math.floor(Date.now() / 1000);
  if (!VALID_ISS.has(payload.iss)) throw new Error("bad iss");
  if (typeof payload.exp !== "number" || payload.exp < now - 60) throw new Error("expired");
  if (clientId && payload.aud !== clientId) throw new Error("aud mismatch");
  if (!payload.sub) throw new Error("missing sub");

  return {
    sub: payload.sub,
    email: payload.email,
    name: payload.name,
    picture: payload.picture,
    email_verified: payload.email_verified,
  };
}

// ── 서명 세션 쿠키 ─────────────────────────────────────────────────
// 토큰 = base64url(`${sub}.${iat}`) + "." + HMAC. stateless 검증.

const COOKIE_NAME = "fpdojo_session";

function sign(value) {
  return createHmac("sha256", getSessionSecret()).update(value).digest("base64url");
}

export function makeSessionToken(userId) {
  const value = Buffer.from(`${userId}.${Math.floor(Date.now() / 1000)}`).toString("base64url");
  return `${value}.${sign(value)}`;
}

/** 세션 토큰을 검증하고 userId 를 돌려준다(유효하지 않으면 null). */
export function readSessionToken(token) {
  if (!token || typeof token !== "string") return null;
  const dot = token.lastIndexOf(".");
  if (dot <= 0) return null;
  const value = token.slice(0, dot);
  const sig = token.slice(dot + 1);
  const expected = sign(value);
  // 타이밍 안전 비교(길이 다르면 위조).
  if (sig.length !== expected.length) return null;
  if (!timingSafeEqual(Buffer.from(sig), Buffer.from(expected))) return null;
  const decoded = Buffer.from(value, "base64url").toString("utf8");
  const sep = decoded.lastIndexOf(".");
  if (sep <= 0) return null;
  const userId = decoded.slice(0, sep);
  const iat = Number(decoded.slice(sep + 1));
  if (!Number.isFinite(iat)) return null;
  if (Date.now() / 1000 - iat > SESSION_MAX_AGE) return null; // 만료
  return userId || null;
}

export const sessionCookie = {
  name: COOKIE_NAME,
  maxAge: SESSION_MAX_AGE,
  options: {
    httpOnly: true,
    sameSite: "Lax",
    path: "/",
    // secure 는 운영(HTTPS)에서만. 로컬 dev(http)는 false 여야 쿠키가 설정된다.
    secure: process.env.NODE_ENV === "production",
  },
};
