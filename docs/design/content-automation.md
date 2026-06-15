# 콘텐츠 자동화 — 레퍼런스 소스 등록 + 드리프트 감지 CI 설계

> 목표: Gleam 기초·심화 개념 레슨을 현재 포맷으로 대폭 확장하되, **일회성이 아니라**
> 레퍼런스 소스를 등록하고 정기적으로 참조해 업스트림 변경 시 자동으로 플랫폼에 반영한다.
>
> 연구 → 후보 3안 → 적대적 비평 → 채점으로 도출. 추천안 **SPEC-as-source(83점)**
> (대안: 소스-드리프트 LLM 재생성 73, 신뢰도 2-티어 69). 핵심 가정은 실제 레포에서 검증.
>
> **상위 설계**: 본 문서를 플랫폼 규모(에이전트 오케스트레이션 기반 수직·수평 자율 확장)로
> 일반화한 설계는 `docs/design/autonomous-expansion.md` 참조 — 본 SPEC-as-source/드리프트
> 설계는 그 §4 오케스트레이션 루프와 §6 신뢰-티어 테이블의 단일 트랙(Gleam) 구현에 해당한다.

## 0. 먼저 — 냉정한 현실(검증됨)

> **구현 현황(2026-06-14)**: 아래 선결조건 중 **골든 오라클이 구현·동작**한다.
> 핀 `gleam 1.17.0` 네이티브 바이너리(`tools/golden/bin/`, 브라우저 WASM 과 동일
> 버전·소스)를 구동하는 CLI 오라클로, `tools/build-content.mjs`(① 태그/선수/매트릭스
> 검증 + ③ JSON 청크·정답인덱스 도출)와 `tools/golden/verify.mjs`(② predict 스냅샷·
> fix_error 컴파일실패·tests 통과)를 `cd tools && npm run golden` 으로 실행한다.
> 현재 content/ fixture 4건 전수 통과. `harness_ffi.mjs` 구현 완료. 부수 성과로 오라클이
> 실제 버그를 잡았다 — `harness.test` 는 gleam 1.17 예약어 `test` 와 충돌 → `harness.check`
> 로 변경. WASM 타르볼 미러 + `fetch-compiler.sh`(재취득+sha256), Apache-2.0 LICENCE/NOTICE 동봉.
> (WASM-in-Node 바이트 동일성은 후속 — 동일 버전 네이티브로 진단·코드젠이 일치해 CI 게이트로 충분.)
> 남은 선결조건: git-init, 태그 레거시 매핑(드리프트 CI 착수 시), GitHub App 토큰.

"콘텐츠 늘리기"에 바로 못 들어간다. 선결조건이 있다:

1. **골든 검증 파이프라인 전체가 미구현 stub.** `tools/golden/verify.mjs`,
   `tools/build-content.mjs`, `tools/scaffold.mjs`, `app/priv/static/harness/harness_ffi.mjs`,
   `workers/{compiler,runner}.worker.js`, `engine/{compiler,runner}_ffi.mjs`가 전부
   `throw new Error('TODO')` 또는 `todo as "..."`. **TODO 주석이 곧 상세 스펙**이다.
2. **`gleam-v1.17.0-browser.tar.gz`가 디스크에 없음.** 자가 미러링 필요(LICENSE+NOTICE 동봉).
3. **git 저장소가 없음.** CI의 전제 → `git init` + 원격 필요.
4. **태그 불일치(하드 선결조건).** `content/registry/tags.toml`의 `[alias]`가 비어 있는데
   `curriculum.md`는 캐논이 아닌 레거시 태그(`immutability`, `expressions-everywhere`,
   `blocks`, `int-float-ops`, `fold-direction` …)를 방출 → 그대로 materialize하면 build ①
   전부 실패. **레거시→캐논 매핑을 먼저 확정**해야 한다.

**결론**: LLM 생성은 검증 게이트(골든 오라클)가 실재해야만 신뢰 가능. **오라클을 먼저
구현**한 뒤에야 콘텐츠 자동 생성이 의미를 가진다. 약 2~3주의 오라클 작업 + 태그 정리 +
git 초기화가 어떤 설계를 택하든 회피 불가능한 선행 작업이다.

## 1. 전략 — SPEC-as-source(스펙 중심 + 핀 방어)

문제를 "드리프트하는 업스트림에서 콘텐츠를 끊임없이 재생성"(고분산·환각·리뷰 부담)이
아니라 **"우리가 소유한 스펙에서 한 번 materialize → 핀된 산출물을 방어"**로 재정의한다.
근거: 이 프로젝트는 이미 완성된 스펙(`docs/design/curriculum.md` — 15유닛/62레슨을
prose·연습·정답·피드백·방출태그까지 명세)과 골든 오라클 설계(PLAN §5.3)를 소유한다.

- **Phase A (1회 materialize)**: 오라클 구현 → 타르볼 미러 → `curriculum.md`에서 v1 TOML
  트리(U1~U7 = 31레슨 + 7체크포인트 + 참조 퍼즐 패밀리)를 LLM으로 materialize.
  생성물은 **사람 저작 콘텐츠와 동일한 골든 게이트**를 통과해야 하며 일반 커밋으로 들어간다.
  **런타임 LLM 없음, 콘텐츠 서버 없음** — 여전히 정적 사이트(build + publish).
- **Phase B (정기 CI)**: 작은 소스 레지스트리를 폴링해 **3가지 드리프트만** 좁게 대응.

채택한 하이브리드 그래프트(다른 후보의 최선 요소):
- **answer.txt = 실행 산출(SDCR에서)**: predict/exact_output의 정답은 사람이 타이핑하지
  않는다. 생성기는 "실행 가능한 완전 모듈"만 제안하고, **WASM 실행 결과를 골든이 동결**한다.
  레포 fixture가 이미 이 불변식을 체현. 정답이 레포에 들어오는 유일한 합법 경로.
- **신뢰-티어 결정 테이블(TTCD에서)**: "검증 가능 ≠ 자동머지 가능". 자동머지 허용 변경을
  오라클 근거와 함께 **명시 테이블**로 코드화, 목록에 없으면 기본 사람 게이트.
- **체크포인트 정답 인덱스 도출**: `verify.mjs`가 체크포인트 predict 항목도 starter 실행
  결과를 choices와 유일 매칭해 인덱스를 **도출**(하드코딩 `answer="1"` 신뢰 금지).
- **식별자 allow-list 사전검사**: 생성 .gleam의 모든 `module.fn`이 fetch된 시그니처
  집합에 있는지 정적 검사 → 환각 API를 비싼 WASM 컴파일 전에 차단(비용 절감).
- **stdlib 행위 골든 fixture**: 시그니처 해시만으로 못 잡는 "시그니처 동일·동작 변경"
  (예: `string.inspect` 포맷)을 잡도록 소수의 출력 골든을 핀. stdlib는 컴파일러가 싣는
  태그(1.0.3)에 핀, `main` 금지.

## 2. 레퍼런스 소스 레지스트리

신규 `content/registry/sources.toml`(tags.toml 옆, TOML, 사람이 읽는 단일 출처).
각 `[[source]]`: `id, kind, fetch, drift_signal, license, use, consume`.

| id | kind | fetch | drift_signal | license | 용도 |
|---|---|---|---|---|---|
| `gleam-compiler` | compiler_release | GitHub releases/latest API | `release_tag`(+ .sha256 사이드카) | Apache-2.0 | 골든 컴파일러 핀(현 v1.17.0) |
| `exercism-gleam-config` | taxonomy | `raw.githubusercontent.com/exercism/gleam/main/config.json` | `etag`(사전필터) + 슬러그 diff | MIT(슬러그=사실) | tags.toml `[concept]` |
| `gleam-stdlib` | stdlib_api | stdlib releases/latest + raw `src/gleam/<m>.gleam` | `release_tag` + per-시그니처 해시 | Apache-2.0 | 생성 그라운딩 시그니처 |
| `gleam-faq` | docs | website repo commits(소스 SHA, 렌더 HTML 아님) | `git_commit_sha` | 인용만 | U14 "Gleam에 없는 것" |
| `language-tour` | docs | language-tour repo commits/main | `git_commit_sha` | Apache-2.0(구조 참조만) | 레슨 순서 참조(prose 복사 금지) |

설계: 신호는 GitHub API tag/SHA + `.sha256` 사이드카 우선(타르볼 재해싱보다 저렴·무결성
앵커). 레지스트리가 소스별 라이선스를 기록 → CI가 prose 복사를 거부(사실/시그니처/슬러그만
흐름). `consume` 필드로 소스→락파일 슬라이스를 정밀 매핑(드리프트 스코프 최소화).

## 3. 드리프트 감지 + 자동/사람 분기

**마지막-관측 상태 = 커밋된 락파일** `content/registry/sources.lock.json`
(actions cache 아님 — 7일 만료·브랜치 스코프). 두 부분:
`sources[id]`=마지막 tag/SHA/etag, `groundings`=역인덱스 `시그니처-슬라이스-해시 → [artifact ids]`
(시그니처 단위 해시라 stdlib 한 줄 변경이 **그 함수를 인용한 레슨만** 더럽힘).

감지 잡(소스별 matrix + `always()` 집계 잡이 required check):
1. 조건부 GET(`If-None-Match`/tag/SHA 비교). 304/동일 → **단축(WASM·LLM 전부 건너뜀 — 최대 비용 레버)**.
2. 신호 이동 시 kind별 분기 → 아래 결정 테이블.

**신뢰-티어 결정 테이블** (자동머지는 "기계적 검증 가능 ∧ 핀된 산출물에 스코프됨"일 때만):

| 드리프트 | 동작 | 머지 |
|---|---|---|
| Exercism 슬러그 **추가만** | tags.toml `[concept]` append PR(사실, prose 무변경) | 골든 green 시 **자동머지 가능** |
| 슬러그 제거/개명 | 리뷰 **이슈**(콘텐츠가 참조 중일 수 있음) | 사람 |
| **컴파일러 핀 bump** | 타르볼 재미러 → 전 골든 재실행 → 변경된 에러텍스트·answer.txt만 LLM 보수 → renderDriftReport 첨부 PR | **절대 자동머지 금지**(`do-not-automerge`) — §5.3 ④ |
| stdlib API 변경(참조 함수만) | 영향 레슨 목록 리뷰 **이슈**(재작성=교육적 판단) | 사람 |
| FAQ/tour SHA 변경 | 정보성 only | — |
| 새 레슨 생성 | **CI가 하지 않음** — 사람이 생성기를 도구로 호출 | 사람 |

**오탐 제어**: 신호 우선 비교 → 콘텐츠 fetch 없음; 슬라이스 단위 해시; stdlib는
**참조 심볼 교집합** 게이팅(아무도 안 쓰는 변경 무시); docs는 콘텐츠 자동 수정 안 함.
**미탐 보완**: 시그니처 동일·동작 변경 대비 행위 골든 fixture; fetcher는 **빈 슬라이스 시
크게 실패**(업스트림 경로 개편이 "무드리프트"로 조용히 죽는 것 방지).

## 4. 생성 + 그라운딩 (수정된 메커니즘)

신규 `tools/gen/{ground,materialize,repair}.mjs`. DashScope/Qwen 호출, **런타임 아님**.
모델은 초안 도구일 뿐 — 출력은 일반 저작 콘텐츠로 커밋되고 사람과 동일한 골든 게이트 통과.

⚠️ **비평 반영 수정**: DashScope/Qwen은 **CFG 문법 제약 디코드를 지원하지 않음**(JSON-schema
구조화 출력만, TOML 대상 아님). 따라서 "구조 보장 by construction"은 거짓. 실제 흐름:
**JSON-schema 구조화 출력 → TOML 직렬화 → build-content 사후 검증 → 경계 N=3 자동 보수 →
지속 실패 시 사람 에스컬레이션.**

그라운딩(환각 API 차단, Gorilla 패턴):
1. 코드 생성 전 핀된 stdlib(`@1.0.3`) raw `.gleam`에서 `pub fn`/`pub type` 시그니처 + harness
   API(`harness.test/suite`) + tags.toml 캐논 슬러그 + curriculum 슬라이스를 **labeled
   UNTRUSTED-DATA**로 주입("ALLOWED_SYMBOLS의 식별자만 사용").
2. 주입 슬라이스 sha256을 provenance + 락파일 groundings에 기록.
3. 멱등성: 캐시 키 = `f(curriculum 슬라이스 해시 + 시그니처 슬라이스 해시 + 프롬프트 해시
   + 고정 모델 id)` — 모델 결정성에 의존하지 않고 **키 불변 시 호출 자체를 건너뜀**.

타입별 불변식(골든 강제): predict starter=보여주는=실행하는 완전 모듈; fix_error starter는
선언 카테고리와 일치하는 에러로 실제 컴파일 실패; fill_hole은 `todo`로 컴파일·테스트 실패;
tests-family는 solution+runner_test 컴파일·전 테스트 통과; runner_test는 `import harness` +
`import solution`만, `harness.suite([...])` 호출(harness 본문 작성/런 토큰 하드코딩 금지).

프롬프트 인젝션 방어(OWASP LLM01): fetch된 텍스트는 **지시가 아닌 데이터**로 주입; 생성기는
파일 후보 emit 외 권한 없음; 커밋 전 fetch prose와의 **verbatim 중첩 스크린**(라이선스 안전).

## 5. 검증 게이트 = 기존 골든 파이프라인(구현)

순서: `build-content`(① 스키마/태그/선수/매트릭스 + ③ JSON 청크) → `verify`(② WASM 골든 + ④ 드리프트 리포트).
- **build ①**: 태그 등록(미등록=실패, alias=거부+캐논 안내), 선수 무사이클, 타입×채점 매트릭스,
  타임드 적합성, backlink 앵커 해소. ③-6: predict 인덱스를 answer.txt↔choices 유일 매칭으로 도출.
- **verify ②**: Node에서 **동일한 v1.17.0 WASM 컴파일러** 구동(브라우저 워커 init 미러:
  `wasm.default()` → `initialise_panic_hook(false)` → stdlib ~50 모듈 + harness write_module),
  타입별: tests 통과 / fix_error 실제 실패+제목 일치 / predict stdout을 answer.txt로 동결 /
  fill_hole todo-컴파일·테스트실패 / 인용 문자열 스냅샷 핀.
- **자동 보수 루프(생성 한정, N=3)**: 실패 시 {프롬프트 + 결함 TOML/gleam + 정확한 빌드/컴파일러
  에러 + 실패한 골든 체크 + ALLOWED_SYMBOLS} 피드백 재시도. 지속 실패 → 커밋 금지, 사람 목록행.

**게이트의 한계(정직한 인정)**: 골든은 "v1.17.0에서 컴파일 + 이 stdout/테스트 결과"라는
**한 속성**의 강력한 오라클. 다음은 **판정 불가** → 사람 게이트가 진짜 백스톱:
(a) 교육적 정확성·난이도·개념 순서, (b) **오답 보기(distractor) 타당성/유일성**(키 외 보기 미평가),
(c) prose 정확성(한국어 해설은 실행 안 됨), (d) "레슨당 새 개념 1개", (e) answer.txt가 "예측할
**옳은** 것"인지. ⇒ **컴파일 성공이 prose를 자동 승인하지 못한다.** "self-maintaining"은
컴파일러/택소노미 드리프트에 한해 성립, 교육적 의미가 있는 모든 것은 사람 유지.

## 6. CI 워크플로 (.github/workflows/)

전역 `permissions: contents: read`, 서드파티 액션 SHA 핀, 잡별 timeout, concurrency cancel.
1. **golden.yml** (required gate; pull_request·push·workflow_call): setup-node, 미러 타르볼 캐시,
   `build-content.mjs` → `verify.mjs`. **집계 잡(`if: always()`)을 required check 이름으로**
   (스킵된 matrix leg가 PR을 막지 않게).
2. **drift-watch.yml** (schedule cron 비-정시 + dispatch): 소스 matrix, 무드리프트 단축,
   집계 잡이 분기(컴파일러→compiler-bump 디스패치 / 택소노미-추가→peter-evans/create-pull-request@v8
   PR 자동머지 / 제거·stdlib→`gh issue`). **keepalive**로 60일 비활성 자동중단 방지.
3. **compiler-bump.yml** (§5.3 ④; dispatch): 새 타르볼 다운로드+sha256 검증·미러 → 핀 bump →
   `verify --update` 재스냅샷 → `repair.mjs` → PR(renderDriftReport 본문, `do-not-automerge` 라벨).
4. **deploy.yml** (push main): build-content → Lustre 빌드 → Cloudflare Pages(wrangler-action@v3),
   production environment로 시크릿 게이팅.

시크릿: `DASHSCOPE_API_KEY`(gen/repair 스텝 env에만), **GitHub App 토큰**(PR 생성 워크플로 —
⚠️ 기본 `GITHUB_TOKEN`으로 만든 PR은 골든 워크플로가 **승인대기 상태**로 떠 자동머지가 멈춤),
`CLOUDFLARE_API_TOKEN/ACCOUNT_ID`. 브랜치 보호로 골든 집계 체크 required.

## 7. 프로비넌스

1. **artifact 프론트매터**(생성기가 emit, build가 보존하는 선행 TOML 주석 — 디코더 무영향):
   `@generated-by`, `@spec-source`(curriculum 슬라이스+해시), `@grounded-on`(stdlib@1.0.3
   [함수들]+sig-hash), `@compiler: 1.17.0`, `@prompt-hash`, `@reviewed-by: human`(사인오프 시).
2. **락파일** `sources.lock.json`: `sources`(마지막 신호) + `groundings`(슬라이스-해시→artifact
   역인덱스). 콘텐츠 주소화 빌드(Bazel/Nix) 패턴 — 입력 변경 → 해시 재계산 → 해당 artifact만 dirty.

## 8. 라이선스 안전(기계적 강제)

1. **Exercism prose 재사용 금지** — 사실(개념 슬러그·선수 그래프)만 흐름. verbatim 중첩 스크린으로 커밋 차단.
2. **AGPL 벤더링 금지** — gleam-test-runner는 results.json **스키마만** 차용(harness가 이미 반영), 코드 절대 금지.
3. **Apache-2.0 귀속** — 미러한 타르볼·stdlib에 LICENSE+NOTICE 동봉(stdlib 파일명은 영국식 `LICENCE`).
   language-tour는 LICENSE 파일 없음(gleam.toml만 Apache-2.0) → **구조 참조만, prose 복사 금지**.

## 9. 빌드 순서 + 노력 (솔로, 시간제 환산)

**오라클 우선(게이팅 의존성 — 이게 없으면 아무것도 생성 불가): ~2-3주**
0. `git init` + 원격, 타르볼 다운로드·sha256 검증·미러(LICENSE+NOTICE).
1. `verify.mjs` Node WASM 드라이버(init/compile/run — 브라우저 워커와 **정확히** 일치: ~50 stdlib
   write_module, leaf-first import 재작성, per-run 토큰, Err-as-throw). *최고 위험; ~1주 추정은 낙관적.*
2. `build-content.mjs` ① + ③.
3. `verify.mjs` ② 타입별 골든 + ④ `--update`/renderDriftReport → **기존 fixture 2개로 E2E 검증**.
4. `golden.yml`을 required check + 브랜치 보호.

**태그 정리(하드 선결조건)**: 레거시→캐논 매핑 확정, `tags.toml [alias]` 채움. `immutability·
expressions-everywhere·blocks`는 캐논에 **없음** → 새 슬러그 등록 or 기존에 흡수 결정.

**콘텐츠(오라클 이후)**:
5. `gen/{ground,materialize}.mjs`(구조화 출력→TOML→사후검증→보수 N=3) — scaffold 재사용.
6. **U1 완전 materialize**(데모 1레슨 → 5레슨 + 10항목 체크포인트 + 참조 패밀리)로 프롬프트 튜닝.
7. U2~U7(v1) 일괄 — 유닛별 리뷰 PR로 골든 통과, 사람이 교육성·seed_tier 큐레이션.
8. `sources.toml` + `sources.lock.json` + `drift/check.mjs`.
9. `drift-watch.yml` + `compiler-bump.yml` + 택소노미 PR/리뷰 이슈 경로(App 토큰).
10. `deploy.yml`(Cloudflare Pages). keepalive.
11. L3(U8~U11) → L4(U12~U15, U15-3 OTP는 **읽기 전용**) 점진 materialize; 변이 생성기로 회전 변형.

**노력**: 오라클 2-3주(낙관 시), v1 콘텐츠 materialize+큐레이션은 별도(PLAN은 v1 콘텐츠 ~330시간을
사람 저작 기준으로 추정 — LLM materialize로 단축되나 교육성 큐레이션은 사람 병목으로 잔존).

## 10. 핵심 리스크

- **부트스트랩**: 오라클 stub + 타르볼 부재 = 임계경로. 미끄러지면 생성·드리프트·CI 전부 미끄러짐.
- **WASM-in-Node 패리티**: 브라우저 워커와 미세 불일치 → false fail 또는 더 나쁜 false pass(브라우저와 발산).
- **컴파일 되지만 틀린 콘텐츠**: 구조 보장은 의미를 보장 안 함. 시그니처 그라운딩 + AST 심볼 검사 +
  **필수 사람 교육성 사인오프**. 컴파일 성공이 prose 자동승인 못 함.
- **컴파일러 bump 스냅샷 드리프트**: 에러텍스트가 레슨 의미를 바꿀 수 있음 → 자동머지 금지 비협상.
- **GITHUB_TOKEN 함정**: 기본 토큰 PR은 골든 안 돌아 자동머지 정지/미검증 유입 → **App 토큰 필수**.
- **라이선스 오염**: verbatim FAQ/Exercism/tour prose 유입. 사실/시그니처/슬러그만 + 중첩 스크린.
- **프롬프트 인젝션**: fetch 소스가 숨은 지시 운반. labeled untrusted DATA + 최소권한 생성기.
- **스케줄 자동중단**(60일 비활성) → keepalive. **태그 레거시 드리프트** → materialize 전 정리 필수.
- **비용/멱등성**: 모델 결정성 대신 콘텐츠 주소 캐시 키로 미변경 스킵.
- **스코프 크리프**: 드리프트로 **새 레슨 자동 생성** 시 고분산 재생성 문제 재유입 → 새 레슨은 사람 발의.

## 11. 사용자 확정 필요 결정

> **확정(2026-06-14)**: ① **CI/드리프트 자동화는 본 문서 계획으로만 보류** — 먼저 초기 콘텐츠
> 확장을 달성한다. ② 향후 CI 구축 시 자동화 자세 = **"green이면 최대한 자동"**(골든 통과
> 기계적 변경은 자동머지; 단 컴파일러 핀 bump의 스냅샷 의미변경 위험과 prose는 여전히 사람
> 게이트 필요 — §5 한계 참조). ③ **콘텐츠 확장은 `seed.gleam`(앱이 실제 로드하는 M1 임베드)
> 직접 확장**으로 진행(TOML→JSON 파이프라인은 stub이라 보류). 예제 정확성은 **로컬 설치
> gleam 툴체인으로 실제 컴파일·실행 검증**(WASM-in-Node 오라클 없이). 무컴파일 타입
> (predict/mcq)만 사용해 브라우저 WASM 컴파일러 없이 동작.


1. **자동머지 vs 전면 사람 게이트** — 추천: WASM-in-Node 오라클이 브라우저와 bit-exact 검증될
   때까지 **모든 봇 출력 사람 게이트**, 택소노미-추가만 신뢰 확보 후 자동머지.
2. **일괄 생성 vs 점진 저작** — 추천: **오라클 먼저 검증** → U1~U3 E2E → 그 다음 U4~U7 + 드리프트
   배선. 오라클 전에는 어떤 LLM 생성도 켜지 않음.
3. **먼저 등록할 소스** — 추천: `gleam-compiler` + `exercism-config` 먼저 → `gleam-stdlib`(1.0.3 핀
   + 행위 fixture) → FAQ/tour는 U14 유지보수 통증이 실제로 올 때까지 보류.
4. **태그 정리** — `immutability/expressions-everywhere/blocks` 매핑처 결정(선결).
5. **인프라** — git-init(현재 없음), 타르볼 미러, GitHub App 토큰.
6. **tests-family 정책** — LLM이 solution+runner_test를 함께 생성? 추천: **테스트는 고정/사람
   리뷰**하고 고정 테스트에 대해 solution만 재생성(약화된 테스트가 틀린 풀이를 통과시키는 것 방지).
7. **prose/라이선스 자세** — 모든 prose 사람 사인오프, FAQ/tour prose는 프롬프트에 **미주입**
   (번역 거친 패러프레이즈는 n-gram 스크린이 못 잡는 파생물 회색지대) — 구조/커버리지 신호로만.
