#!/usr/bin/env bash
# fpdojo 개발 서버 한 번에 실행 — 에이전트 백엔드(:8787) + 프론트엔드(:1234).
#
#   ./run.sh
#
# Ctrl+C 한 번이면 두 서버(와 BEAM/bun/node 손주 프로세스)가 모두 정리된다.
# DASHSCOPE_API_KEY 는 셸 환경변수 또는 server/.env 로 주입한다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1) 안내 — DASHSCOPE_API_KEY 는 이제 선택(없으면 AI 채팅만 비활성, 로그인·대시보드는 정상).
if [ -z "${DASHSCOPE_API_KEY:-}" ] && [ ! -f "$ROOT/server/.env" ]; then
  echo "ℹ DASHSCOPE_API_KEY 미설정 — AI 채팅은 비활성됩니다(로그인/대시보드는 동작)." >&2
fi

# 프론트 바인딩 — 외부(공유기 포트포워딩/DDNS) 접속을 허용하려면 0.0.0.0.
# 로컬만 쓰려면 FRONTEND_HOST=localhost 로 실행하세요.
FRONTEND_HOST="${FRONTEND_HOST:-0.0.0.0}"

# 2) 백엔드 의존성 (최초 1회만)
if [ ! -d "$ROOT/server/node_modules" ]; then
  echo "▸ server 의존성 설치 중 (최초 1회)..."
  (cd "$ROOT/server" && npm install)
fi

# 3) 종료 시 기록한 PID 의 서브트리를 재귀적으로 정리한다. gleam 은 BEAM 을,
#    BEAM 은 bun 워처를 손주로 띄우므로 단순 kill 로는 남는다 → pgrep 재귀로 전부.
pids=()
kill_tree() {
  local pid=$1 child
  for child in $(pgrep -P "$pid" 2>/dev/null); do kill_tree "$child"; done
  kill "$pid" 2>/dev/null || true
}
cleanup() {
  trap - INT TERM EXIT
  echo
  echo "▸ 종료 중..."
  for pid in "${pids[@]}"; do kill_tree "$pid"; done
}
trap cleanup INT TERM EXIT

echo "▸ 백엔드  → http://localhost:8787  (DashScope 프록시 + 세션 메모리)"
( cd "$ROOT/server" && exec node --env-file-if-exists=.env src/server.mjs ) &
pids+=("$!")

echo "▸ 프론트  → http://${FRONTEND_HOST}:1234  (외부 접속: https://cachyos-home.tail665a40.ts.net — Tailscale Funnel, 종료: Ctrl+C)"
( cd "$ROOT/app" && exec gleam run -m lustre/dev start --host="$FRONTEND_HOST" ) &
pids+=("$!")

wait
