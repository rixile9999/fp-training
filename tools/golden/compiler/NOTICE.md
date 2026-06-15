# 미러된 Gleam 컴파일러 아티팩트 (Apache-2.0)

이 디렉토리와 `../bin/` 의 Gleam 컴파일러 아티팩트는 **gleam-lang/gleam** 에서
미러한 것이며 **Apache License 2.0** 으로 배포된다(전문: `LICENCE`).

- `gleam-v1.17.0-browser.tar.gz` (+ `.sha256`) — 브라우저용 WASM 컴파일러
  (gleam_wasm.js + gleam_wasm_bg.wasm). 브라우저 인-앱 컴파일/실행(PLAN §5.2)과
  향후 WASM-in-Node 골든 정밀화에 사용. 출처:
  https://github.com/gleam-lang/gleam/releases/tag/v1.17.0
- `../bin/gleam-1.17.0` — x86_64-unknown-linux-musl 네이티브 컴파일러(핀 버전).
  CI 골든 오라클(tools/golden/verify.mjs)이 콘텐츠 컴파일/실행 검증에 사용.

저작권: Louis Pilfold 및 Gleam 기여자. 원 LICENCE 전문을 `LICENCE` 로 동봉한다.
이 아티팩트는 재배포가 아니라 빌드/검증 도구로 미러하며, `tools/golden/fetch-compiler.sh`
로 릴리스에서 재취득(+sha256 검증)할 수 있다 — 저장소에는 커밋하지 않는다(.gitignore).
