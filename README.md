# fpdojo — Gleam으로 배우는 함수형 프로그래밍

체스 학습 플랫폼(레슨 + 레이팅 퍼즐 + 간격 반복)의 메커니즘을 함수형
프로그래밍 학습에 적용한 웹 앱. 타깃 언어는 **Gleam**. 전체 계획은
[`PLAN.md`](PLAN.md), 모듈 인터페이스는
[`docs/design/interfaces.md`](docs/design/interfaces.md) 참고.

## 지금 실행하면 되는 것 (M1 슬라이스)

브라우저에서 **실제로 돌아가는 학습 루프**가 동작한다 — 컴파일러 없이:

- 홈에서 유닛·레슨 목록과 진행도 확인
- 레슨: 설명(prose) ↔ 마이크로 연습(객관식·출력 예측) 교차 진행
- **즉각 피드백**: 정답이면 코멘터리, 오답이면 보기별 사전 저작 해설 + 무벌점 재시도
- 레슨 완료 → 진행도(✓) 갱신

현재 콘텐츠: **15개 유닛 64개 레슨 (L1~L4 전체)** — `docs/design/curriculum.md`
명세 기반. L1 값·함수·case(U1~U3), L2 커스텀타입·리스트·재귀·고차함수(U4~U7),
L3 list모듈·Option/Result·use·제네릭(U8~U11), L4 opaque·의도적크래시·"Gleam에
없는 것"·캡스톤(U12~U15, OTP는 읽기 전용). 모든 predict 예제는 로컬 gleam(JS
타깃=브라우저 런타임)으로 실행 검증된다(120+ 통과). 모든 문제는 무컴파일 채점
(predict 선택지형·mcq)이라 인-브라우저 Gleam 컴파일러 없이 동작한다.
fix_error·write_fn 등 코드 작성/컴파일 채점 연습은 다음 단계(WASM 컴파일러 도입,
PLAN §8-①)에서 추가된다.

**골든 검증 오라클**: `tools/`(build-content.mjs + golden/verify.mjs)이 핀 `gleam
1.17.0` 으로 content/ TOML 콘텐츠를 컴파일·실행 검증한다 — `cd tools && npm install
&& npm run fetch-compiler && npm run golden`. 콘텐츠 자동화(레퍼런스 소스 드리프트
CI)는 `docs/design/content-automation.md` 설계 참고(현재 계획 단계).

## 실행 방법

`app/` 디렉토리에서:

```fish
cd app

# 개발 서버 (핫리로드) — http://localhost:1234
gleam run -m lustre/dev start

# 또는 정적 번들 빌드 → dist/
gleam run -m lustre/dev build
```

첫 실행 시 Lustre 개발 도구가 번들러(Bun)를 자동 다운로드한다.

### AI 코딩 도우미 사이드바

모든 화면 우측에 코딩 질문용 에이전트 사이드바가 상주한다(DashScope/Qwen 백엔드,
세션 메모리). 키를 브라우저에 노출하지 않기 위해 별도의 same-origin 프록시
백엔드(`server/`)가 필요하다.

**한 번에 실행** — 루트의 `run.sh` 가 백엔드(:8787)+프론트(:1234)를 함께 띄우고,
Ctrl+C 한 번이면 둘 다(BEAM/bun/node 손주까지) 정리한다. `node_modules` 가 없으면
의존성도 자동 설치한다:

```fish
export DASHSCOPE_API_KEY=sk-...    # 또는 cp server/.env.example server/.env 후 키 입력
./run.sh                           # → http://localhost:1234 (우하단 💬)
```

수동으로 따로 띄우려면(터미널 2개):

```fish
cd server; npm install; npm run dev          # 백엔드 :8787 (node --watch, server/.env 자동 로드)
cd app;    gleam run -m lustre/dev start      # 프론트 :1234 (/api/* → 백엔드 프록시)
```

`/api/*` 는 `gleam.toml` 의 `[tools.lustre.dev].proxy` 로 백엔드에 포워딩되므로
브라우저는 same-origin 만 호출한다. 키는 `server/.env`(`.env.example` 참고, gitignore됨)
또는 셸 환경변수로 주입한다. 설계·결정 근거는
[`docs/todo/extension-plan.md`](docs/todo/extension-plan.md) 참고.

### 그 밖의 명령

```fish
gleam build            # 전체 컴파일·타입체크 (target=javascript 고정)
gleam test             # gleeunit 테스트
gleam format src test  # 포맷
```

## 구조

- `app/` — Gleam(Lustre SPA) 프로젝트
  - `src/fpdojo/core/` — 순수 도메인(rating·srs·progress·profile, 대부분 stub)
  - `src/fpdojo/content/` — 콘텐츠 스키마·로더(stub) + `seed.gleam`(M1 임베드 콘텐츠)
  - `src/fpdojo/engine/` — 컴파일/실행/채점(`grade_step_sync` 구현, 나머지 stub)
  - `src/fpdojo/session/` — 레슨·체크포인트·배치·트레이닝·복습 상태머신
    (`lesson` 구현, 나머지 stub)
  - `src/fpdojo/ui/` — Lustre MVU(app + home/lesson 페이지 + `chat`·`components/chat_panel` 사이드바)
  - `assets/styles.css` — UI 스타일
- `server/` — AI 코딩 도우미 백엔드(Node+Hono+openai SDK → DashScope, 세션 메모리 Map)
- `content/` — 정식 콘텐츠 저작 트리(TOML, 빌드 파이프라인용 — 현재 예시)
- `tools/` — 콘텐츠 빌더·골든 검증·스캐폴드(stub)
- `docs/design/` — 인터페이스 맵·설계서·리뷰 노트
- `PLAN.md` — 전체 제품 계획

## 현재 상태 / 다음 단계

M1의 **컴파일러-free 학습 루프**가 완성·검증됨(브라우저 end-to-end). 인메모리
진행도(새로고침 시 초기화 — localStorage 영속화는 후속). 다음 우선순위:

1. **진행도 영속화** — `storage/local` 구현(localStorage), 새로고침에도 유지
2. **콘텐츠 확장** — 유닛·레슨 추가, 트리키 파트(fold 방향 등) 집중
3. **인-브라우저 컴파일러**(PLAN §8-①) — `gleam-v1.17.0-browser.tar.gz` WASM
   듀얼 워커 → fix_error·write_fn 등 코드 채점 연습
4. **레이팅·SRS·트레이닝 모드** — 체스 퍼즐식 rated 루프(core/* · session/* 본구현)
