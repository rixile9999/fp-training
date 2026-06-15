#!/usr/bin/env bash
# 핀 Gleam 1.17.0 골든 오라클 아티팩트 재취득 (+ sha256 검증).
# 대용량 바이너리는 저장소에 커밋하지 않으므로 CI/새 클론에서 이걸로 받는다.
#   tools/golden/fetch-compiler.sh
set -euo pipefail
V=1.17.0
ARCH=x86_64-unknown-linux-musl   # CI 러너에 맞게 조정
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REL="https://github.com/gleam-lang/gleam/releases/download/v${V}"

verify() { # url out
  curl -sSL -m 240 -o "$2" "$1"
  curl -sSL -m 60 -o "$2.sha256" "$1.sha256"
  local exp got
  exp=$(cut -d' ' -f1 "$2.sha256"); got=$(sha256sum "$2" | cut -d' ' -f1)
  [ "$exp" = "$got" ] || { echo "✗ sha256 mismatch: $2" >&2; exit 1; }
  echo "✓ $(basename "$2")"
}

# 1) 네이티브 CLI 컴파일러 (골든 오라클용)
mkdir -p "$HERE/bin"
if [ ! -x "$HERE/bin/gleam-${V}" ]; then
  tmp="$HERE/bin/_g.tar.gz"
  verify "${REL}/gleam-v${V}-${ARCH}.tar.gz" "$tmp"
  tar -xzf "$tmp" -C "$HERE/bin" && mv "$HERE/bin/gleam" "$HERE/bin/gleam-${V}"
  rm -f "$tmp" "$tmp.sha256"
fi
"$HERE/bin/gleam-${V}" --version

# 2) 브라우저 WASM 타르볼 (앱 인-브라우저 컴파일 / 향후 WASM-in-Node)
mkdir -p "$HERE/compiler"
if [ ! -f "$HERE/compiler/gleam-v${V}-browser.tar.gz" ]; then
  verify "${REL}/gleam-v${V}-browser.tar.gz" "$HERE/compiler/gleam-v${V}-browser.tar.gz"
fi
echo "compiler artifacts ready (v${V})"
