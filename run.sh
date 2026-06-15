#!/usr/bin/env bash
# fpdojo 개발 서버 한 번에 실행 — 에이전트 백엔드(:8787) + 프론트엔드(:1234).
#
#   ./run.sh
#
# Ctrl+C 한 번이면 두 서버(와 BEAM/bun/node 손주 프로세스)가 모두 정리된다.
# DASHSCOPE_API_KEY 는 셸 환경변수 또는 server/.env 로 주입한다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1) API 키 확인 (셸 env 또는 server/.env 중 하나는 있어야 함)
if [ -z "${DASHSCOPE_API_KEY:-}" ] && [ ! -f "$ROOT/server/.env" ]; then
  cat >&2 <<'EOF'
✗ DASHSCOPE_API_KEY 가 없습니다. 다음 중 하나를 하세요:
    export DASHSCOPE_API_KEY=sk-...            # 셸 환경변수, 또는
    cp server/.env.example server/.env         # 파일로 두고 키 입력
EOF
  exit 1
fi

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

echo "▸ 프론트  → http://localhost:1234  (우하단 💬 버튼, 종료: Ctrl+C)"
( cd "$ROOT/app" && exec gleam run -m lustre/dev start ) &
pids+=("$!")

wait
