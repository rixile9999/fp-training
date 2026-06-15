# Gleam FP 학습 플랫폼 — 기술 아키텍처 설계서

대상: 함수형 프로그래밍을 Gleam으로 단계별 학습하는 웹 플랫폼 (레슨 세션 + 트레이닝 세션, 체스 플랫폼식 설계: 구조화된 레슨, 레이팅 퍼즐, 타임드 드릴, spaced repetition).
제약: 1인 개발. 작성일: 2026-06-13. 기준 컴파일러: Gleam v1.17.0 (2026-06-02 릴리스), gleam_stdlib 1.0.3.

---

## 0. 결정 요약 (TL;DR)

| 영역 | 결정 | 핵심 근거 |
|---|---|---|
| 프론트엔드 | **Lustre v5.x SPA** (정적 호스팅) | 도그푸딩 = 마케팅 자산, MVU가 가르치는 패러다임과 동일, 정적 사이트로 충분 |
| 에디터 | **CodeMirror 6** + `@exercism/codemirror-lang-gleam` 포크 | 유일한 Gleam grammar 보유 에디터. Monaco는 grammar 없음, CodeFlask는 inline diagnostics 불가 |
| 컴파일/실행 | **공식 browser WASM 컴파일러** (`gleam-v1.17.0-browser.tar.gz`), 100% 인브라우저, JS 타깃 | tour.gleam.run / playground / LiveCodes로 검증된 패턴. 실행 서버 = 0 |
| 샌드박싱 | 컴파일 워커(장수명) + 러너 워커(일회용) 분리, **watchdog terminate** | tour의 치명적 결함(무한루프 방어 없음) 보완. 워커 분리로 WASM 재초기화 비용 회피 |
| 백엔드 | **M1–M2: 없음 (localStorage)** → M3: Wisp 2.2.2 + Mist 6.0.3 + SQLite | 정적 사이트는 호스팅 비용 0, 1인 개발자의 운영 부담 최소화 |
| 콘텐츠 | 파일 기반 git repo + TOML 메타데이터 + Gleam 빌드 스크립트, **CI 골든 검증** | 솔루션·테스트·예상 컴파일 에러를 실제 WASM 컴파일러로 검증 |
| 레이팅 | Glicko-2 (lichess 모델), MVP에서는 로컬 계산 + 저작 시 시드 레이팅 | 퍼즐 레이팅 전역 보정은 M3 서버에서 |
| SRS | Chessable MoveTrainer식 8단계 (4h/1d/3d/1w/2w/1mo/3mo/6mo), 실패 시 L1 리셋 | 구현이 자명한 테이블. FSRS는 추후 옵션 |

---

## 1. 설계 원칙

1. **실행 서버를 만들지 않는다.** 공식 language-tour가 증명한 인브라우저 컴파일이 1인 개발자의 결정적 우위다. Docker 샌드박스 함대(Exercism 방식: 제출당 20s/3GB)는 운영 비용·보안 부담·지연을 모두 가져온다.
2. **콘텐츠가 코드보다 비싸다.** 아키텍처의 모든 선택은 "퍼즐 1개를 30분 안에 저작하고 CI가 자동 검증"을 가능하게 하는 방향으로 정렬한다.
3. **모든 상태는 이벤트 로그로.** 시도(attempt) 기록을 append-only 로그로 두면 레이팅·SRS·대시보드가 전부 파생 상태가 되고, M3 서버 마이그레이션이 "로그 업로드 + 리플레이"로 단순해진다.
4. **컴파일러 버전을 고정한다.** 퍼즐의 기대 컴파일 에러는 버전 민감하다. tour가 v1.15.2를 고정하듯, 우리는 v1.17.0을 고정하고 의도적으로만 업그레이드한다.

---

## 2. 스택 선정 (대안 비교)

### 2.1 프론트엔드: Lustre (추천) vs SvelteKit vs React

| 기준 | Lustre v5.7.0 | SvelteKit | React/Next |
|---|---|---|---|
| 패러다임 | Elm식 MVU, managed effects | 반응형, 명령형 혼합 | 훅 기반 |
| 학습 플랫폼과의 정합성 | **가르치는 FP 모델 그대로** | 무관 | 무관 |
| 정적 SPA 산출 | 지원 (SPA 모드) | 지원 | 지원 |
| 생태계 | 작음 (252k 다운로드, 메인테이너 1인) | 큼 | 매우 큼 |
| JS interop | FFI로 가능 (CodeMirror, Worker) | 네이티브 | 네이티브 |
| 1인 개발 일관성 | **콘텐츠 빌드 스크립트·프론트·백엔드까지 전부 Gleam** | 언어 2개 | 언어 2개 |

**추천: Lustre.** 근거:

- **도그푸딩이 곧 제품 증명이다.** "Gleam을 가르치는 플랫폼이 Gleam으로 만들어졌다"는 것 자체가 신뢰 자산이고, 플랫폼 코드가 고급 커리큘럼(MVU, managed effects)의 살아있는 예제가 된다.
- 이 앱의 UI 복잡도는 낮다(레슨 뷰어, 에디터 패널, 결과 패널, 대시보드). SvelteKit의 생태계 우위가 발휘될 표면적이 작다.
- JS interop이 필요한 지점은 정확히 세 곳 — CodeMirror 마운트, Worker 포트, localStorage — 이고, 전부 얇은 FFI 모듈로 격리 가능하다.
- 리스크(메인테이너 1인)는 실재하지만, MVU 구조상 view 레이어 교체가 국소적이다. 완화책은 §9.

### 2.2 에디터: CodeMirror 6 (추천)

- **CodeMirror 6** + `@exercism/codemirror-lang-gleam` (npm, Lezer grammar, v1.0.0 2023-07). 2023년 이후 키워드(`assert`, `echo`, label shorthand)가 빠져 있으므로 **포크해서 grammar에 추가**한다. Gleam 문법은 1.0 이후 안정적이라 드리프트는 제한적.
- Monaco: Gleam grammar 부재(Monarch grammar 직접 작성 필요) + 번들 무거움 → 기각.
- CodeFlask(tour가 사용): 가볍지만 textarea 오버레이라 **inline diagnostic squiggle, 빈칸(hole) 위젯, read-only 영역**을 만들 수 없음 → 기각. 우리 퍼즐 타입(fill-hole, fix-error)에는 데코레이션이 필수다.
- 레슨 본문의 비편집 코드 블록은 CodeMirror를 띄우지 않고 **tree-sitter-gleam 기반 정적 하이라이팅**(콘텐츠 빌드 시 HTML로 사전 렌더)으로 처리한다. 런타임 비용 0.

### 2.3 백엔드: M1–M2 없음 → M3 Wisp + SQLite

| 옵션 | 평가 |
|---|---|
| **없음 (localStorage)** | M1–M2 추천. GitHub Pages/Cloudflare Pages에 정적 배포. 비용 0, 운영 0 |
| Wisp 2.2.2 + Mist 6.0.3 + SQLite(+Litestream) | M3 추천. Gleam 단일 스택 유지, VPS 1대, 활발히 유지보수됨 (월 ~20k 다운로드) |
| Supabase/Firebase | 더 빠르지만 비-Gleam 의존 + 벤더 락인. 데이터 모델이 단순(이벤트 로그 + 파생 상태)해서 BaaS의 이점이 작음 → 기각 |
| Lustre server components | 서버 보유 상태 + WebSocket 상시 연결 — 레슨/드릴 플랫폼에 과잉이고 인터랙션마다 지연 추가 → 기각 (연구 결론과 동일) |

호스팅 주의: `.wasm`에 `application/wasm` MIME 필요(Pages 계열 기본 지원), SharedArrayBuffer를 쓰지 않으므로 COOP/COEP 헤더 불필요.

---

## 3. 핵심: 인브라우저 Gleam 컴파일/실행 파이프라인

tour.gleam.run(gleam-lang/language-tour)의 아키텍처를 기반으로 채택하되, 트레이닝 플랫폼에 필수인 두 가지 — **무한루프 방어**와 **채점 하니스** — 를 추가한다. 참조 구현: language-tour의 `static/compiler.js`(~90줄), `static/worker.js`(~80줄).

### 3.1 전체 구조

```
Main thread (Lustre SPA)
 └─ compile_service.mjs  (Lustre effect에서 호출하는 FFI 포트)
     ├─ compiler.worker.js   ← 장수명. WASM init + stdlib write_module을 1회만 지불
     │    1) write_module(pid, "solution", userCode)
     │    2) write_module(pid, "runner_test", hiddenTestSource)   // 채점 시
     │    3) compile_package(pid, "javascript")
     │    4) read_compiled_javascript(pid, m) for m in [solution, runner_test]
     │    5) pop_warning 드레인 → postMessage({js: {...}, warnings} | {error: prettyText})
     │
     └─ runner.worker.js     ← 일회용. 실행마다 생성, watchdog가 terminate
          1) import 경로 재작성 (stdlib → /precompiled/, 모듈 간 → data: URL)
          2) console.log 몽키패치로 출력 캡처
          3) await import("data:text/javascript;base64," + ...) → main()
          4) postMessage({log, error}) → 종료
```

**워커를 둘로 나누는 이유**: tour는 컴파일과 실행을 한 워커에서 하고 watchdog이 없어 무한루프에 영구히 멈춘다. watchdog로 `worker.terminate()`하면 되지만, 컴파일 워커를 죽이면 WASM 초기화 + stdlib ~50개 모듈 `write_module` 비용을 매번 다시 지불한다. **무한루프는 런타임에 발생하지 컴파일 타임에는 발생하지 않으므로**, 비싼 컴파일 워커는 살려두고 싼 러너 워커만 죽인다. 러너 워커는 WASM도 stdlib 쓰기도 없이 스크립트 로드뿐이라 respawn 비용이 수 ms다.

### 3.2 WASM 컴파일러 로딩

- 배포물: GitHub 릴리스 자산 `gleam-v1.17.0-browser.tar.gz` (1.66 MB, wasm-pack `--target web` 산출물: `gleam_wasm.js` glue + `gleam_wasm_bg.wasm`). **공식 npm 패키지는 없다** — tour의 `bin/download-compiler`처럼 빌드 스크립트에서 curl|tar로 받아 `public/compiler/`에 정적 서빙한다. 릴리스 자산이 사라질 위험에 대비해 tarball을 자체 스토리지(R2/repo LFS)에 미러링한다.
- 로딩 (compiler.worker.js 내부):

```js
const wasm = await import("/compiler/gleam_wasm.js?v=" + COMPILER_VERSION);
await wasm.default();          // wasm-pack init
wasm.initialise_panic_hook(false);
```

- `?v=` 캐시버스터(tour 방식) + Service Worker로 wasm/stdlib 번들을 버전 키로 영구 캐시. 컴파일러는 **첫 인터랙티브 연습 진입 시점에 lazy-load**한다 — 레슨 prose 읽기와 predict/choice형 퍼즐은 컴파일러 없이 동작하므로 앱 셸 초기 로드는 가볍게 유지된다.

### 3.3 stdlib 제공 (tour의 2면 메커니즘 그대로)

빌드 타임에 더미 Gleam 프로젝트를 `gleam build`한 뒤:

1. **타입체킹용 소스**: `build/packages/gleam_stdlib/src/gleam/*.gleam` 전체를 `stdlib.js`(모듈명→소스 맵)로 임베드. 컴파일 워커가 부팅 시 모듈마다 `write_module`을 호출해 유저 패키지의 일부로 stdlib을 함께 타입체크/컴파일한다 (tour의 `generate_stdlib_bundle` 패턴, deprecated 모듈 제외).
2. **런타임용 프리컴파일**: `build/dev/javascript/gleam_stdlib`의 `.mjs`(FFI 포함)와 prelude `gleam.mjs`를 `public/precompiled/`에 복사 (tour의 `copy_compiled_stdlib` 패턴).

stdlib 외 패키지가 필요한 레슨(예: gleam_json)은 **LiveCodes 검증 패턴**으로 동일 처리: 패키지 `.gleam` 소스를 `write_module`로 주입 + 프리컴파일 `.mjs`/FFI를 `/precompiled/`에 서빙. compiler-wasm의 의존성 미지원(이슈 gleam-lang/gleam#3245, 2026-06 현재 open)을 기다리지 않는다.

### 3.4 실행과 import 재작성 — 멀티 모듈 주의점

Gleam이 내놓는 JS는 ES module이라 `eval()` 불가 → base64 data-URL 동적 import(tour 방식). 단, **우리는 모듈이 2개(solution + runner_test)라서 tour의 단일 정규식 재작성(`from "./..."` → `/precompiled/...`)을 그대로 쓰면 `runner_test`의 `import "./solution.mjs"`까지 precompiled로 잘못 재작성된다.** 러너 워커에서 의존성 역순(leaf-first)으로 처리한다:

```js
// runner.worker.js — 토폴로지 순서: solution 먼저, runner_test 나중
function rewriteStdlib(js) {
  return js.replaceAll(/from\s+"\.\/(.+)"/g, `from "${origin}/precompiled/$1"`);
}
const solutionUrl = "data:text/javascript;base64," +
  toBase64(rewriteStdlib(modules["solution"]));
const testJs = rewriteStdlib(modules["runner_test"])
  .replaceAll(`"${origin}/precompiled/solution.mjs"`, `"${solutionUrl}"`);
const mod = await import("data:text/javascript;base64," + toBase64(testJs));
mod.main();
```

출력/에러 캡처(tour와 동일):

- `console.log` 몽키패치로 라인 누적 — JS 타깃에서 `io.println`/`echo` 출력이 모두 잡힌다.
- 런타임 예외는 try/catch 후 `toString()`. **무한 재귀는 JS에서 `RangeError: Maximum call stack size exceeded`로 잡히므로** watchdog 없이도 즉시 교육적 피드백("꼬리 호출 위치를 확인하세요")으로 변환 가능 — 비-꼬리재귀 드릴에서 적극 활용한다.
- 컴파일 경고는 `pop_warning(project_id)` 드레인.

### 3.5 타임아웃/무한루프 방어 (watchdog)

```js
// main thread: compile_service.mjs
async function run(modules, timeoutMs /* 퍼즐 메타데이터에서, 기본 3000 */) {
  const worker = new Worker("/runner.worker.js", { type: "module" });
  return new Promise((resolve) => {
    const t = setTimeout(() => {
      worker.terminate();                       // 동기 무한루프는 이것만이 유일한 수단
      resolve({ kind: "timeout", timeoutMs });
    }, timeoutMs);
    worker.onmessage = (e) => { clearTimeout(t); worker.terminate(); resolve(e.data); };
    worker.postMessage(modules);
  });
}
```

- 러너 워커는 항상 일회용: 정상 종료든 timeout이든 terminate. 상태 누수·몽키패치 잔존 없음.
- 컴파일 워커에도 **안전망 watchdog 30s**를 둔다(컴파일러 자체 행은 비정상이지만 panic 가능성 대비). 이 경우에만 풀 respawn 비용(WASM init + stdlib 쓰기)을 지불.
- timeout 결과는 채점상 실패로 처리하되 UI 메시지는 진단적으로: "3초 안에 끝나지 않았습니다 — 종료 조건 없는 재귀일 가능성이 큽니다."
- 타임드 모드(Storm)는 timeout을 오답과 동일하게 −10s/콤보 리셋으로 매핑.

### 3.6 샌드박싱 수위

- MVP: **same-origin Web Worker**. 이는 응답성 경계이지 보안 경계가 아니다(연구 결론). 유저가 직접 작성한 코드만 실행하므로 tour와 동일하게 수용. 값싼 강화책으로 CSP `connect-src 'self'`를 걸어 fetch 남용을 차단(워커는 페이지 CSP를 상속).
- 타 유저 코드 공유/커뮤니티 퍼즐을 도입하는 시점(M3 이후)에는 **sandboxed cross-origin iframe 안에 러너 워커**를 넣는 구조로 격상. 컴파일 워커는 그대로, 러너만 iframe `postMessage` 너머로 이동하면 되도록 `compile_service`의 인터페이스를 지금부터 message-passing 형태로 고정해 둔다.

### 3.7 진단(diagnostics) 처리

`compile_package` 에러와 경고는 ANSI 없는 pretty-printed 평문 (`Error::pretty_string()`, `Buffer::no_color()`): 파일:행:열, 캐럿 밑줄 발췌, 설명, 힌트 포함. 구조화 진단(`gleam_core`의 `to_diagnostics()`)은 WASM 경계로 노출되지 않는다.

- **M1**: 평문 그대로 결과 패널에 표시 + tour처럼 `src/(\w+)\.gleam:(\d+):(\d+)` 정규식으로 위치를 추출해 CodeMirror 라인 하이라이트. 에러 첫 줄(`error: ...`)을 제목으로 파싱해 "이 에러 유형이 처음이라면 → 관련 레슨" 링크를 단다(fix-compile-error 퍼즐의 핵심 UX).
- **M2 옵션**: compiler-wasm 포크(단일 lib.rs)에 `read_diagnostics(project_id) -> JsValue`(JSON: title/text/hint/path/SrcSpan start·end) export 추가 → 정확한 inline squiggle. 비용: 컴파일러 업그레이드마다 Rust/wasm-pack 빌드 유지. **평문 정규식 파싱이 골든 테스트로 보호되는 한 포크는 미루는 것을 기본값으로 한다.**

### 3.8 채점용 테스트 하니스

원리: **히든 테스트 모듈을 유저 모듈과 같은 WASM 프로젝트에 `write_module`로 함께 컴파일** → 테스트 모듈의 `main()`을 호출 → 캡처된 출력 프로토콜을 파싱. v1.11의 `assert` 키워드가 풍부한 실패 정보를 공짜로 준다.

플랫폼이 모든 프로젝트에 주입하는 하니스 모듈:

```gleam
// harness.gleam — 채점 프레임워크 (모든 채점 컴파일에 자동 주입)
import gleam/io
import gleam/list

pub fn test(name: String, body: fn() -> Nil) -> #(String, fn() -> Nil) {
  #(name, body)
}

// JS 타깃에서 assert 실패(예외)를 잡기 위한 작은 FFI
@external(javascript, "./harness_ffi.mjs", "rescue")
fn rescue(body: fn() -> Nil) -> Result(Nil, String)

pub fn suite(tests: List(#(String, fn() -> Nil))) -> Nil {
  list.each(tests, fn(t) {
    let #(name, body) = t
    case rescue(body) {
      Ok(_) -> io.println("__T__|pass|" <> name)
      Error(msg) -> io.println("__T__|fail|" <> name <> "|" <> msg)
    }
  })
}
```

```js
// harness_ffi.mjs — /precompiled/에 서빙, import 재작성으로 해석됨
import { Ok, Error } from "./gleam.mjs";
export function rescue(body) {
  try { body(); return new Ok(undefined); }
  catch (e) { return new Error(e.message ?? String(e)); }
}
```

퍼즐별 히든 테스트 예 (저작자가 작성):

```gleam
// runner_test.gleam — 퍼즐 "sum-basics-003"의 히든 테스트
import harness
import solution

pub fn main() {
  harness.suite([
    harness.test("빈 리스트의 합은 0", fn() {
      assert solution.sum([]) == 0
    }),
    harness.test("음수를 포함한 합", fn() {
      assert solution.sum([1, -2, 3]) == 2
    }),
    harness.test("긴 리스트 (꼬리 재귀 확인용)", fn() {
      assert solution.sum(solution.range(1, 10_000)) == 50_005_000
    }),
  ])
}
```

- 러너 워커가 `__T__|` 프리픽스 라인을 파싱해 per-test 결과를 만들고, 나머지 라인은 유저의 stdout으로 분리 표시한다.
- 내부 결과 계약은 **Exercism results.json v2 스키마**(status pass/fail/error + per-test name/status/message/test_code)를 차용 — M3에서 서버사이드(Erlang 타깃) 러너를 추가해도 계약이 그대로 호환된다.
- "긴 리스트" 테스트처럼 **스택 오버플로를 유도하는 입력**으로 꼬리재귀 여부를 행동적으로 채점할 수 있다(JS 타깃의 RangeError가 fail 메시지로 잡힘).
- 한계(정직하게): 테스트 소스는 클라이언트에 전송되므로 결연한 유저는 읽거나 출력을 위조할 수 있다. 출력 스푸핑은 런마다 난수 토큰을 프리픽스에 섞어 1차 방어하되, **클라이언트 채점은 본질적으로 신뢰 기반**이다. MVP 레이팅은 로컬 전용이라 무해하고, M3에서 공개 리더보드를 만든다면 서버 재검증을 전제로 한다.
- 채점 모드 3종: `tests`(위 방식), `exact_output`(predict형 — main() 출력 문자열 비교), `choice`(컴파일 불필요).

---

## 4. 콘텐츠 저작 포맷과 빌드 파이프라인

### 4.1 디렉토리 구조 (git repo가 곧 CMS)

```
content/
├── concepts.toml              # 콘셉트 택소노미 + prerequisite 그래프
├── units/
│   └── 02-result-option/
│       ├── unit.toml          # id, title.{ko,en}, order, concepts
│       └── lessons/
│           └── 03-railway/
│               ├── lesson.toml
│               ├── prose.ko.md          # 짧은 설명 청크 (Brilliant식: 청크→체크 반복)
│               ├── prose.en.md
│               └── steps/
│                   ├── 01-predict/      # step.toml + code.gleam + answer.txt
│                   ├── 02-fill/         # step.toml + starter.gleam + solution.gleam + test.gleam
│                   └── 03-fix/          # step.toml + starter.gleam + solution.gleam + hints.ko.md ...
└── puzzles/
    └── exhaustive-shapes-001/
        ├── puzzle.toml
        ├── starter.gleam
        ├── solution.gleam
        ├── test.gleam               # tests 모드일 때
        ├── hints.ko.md              # --- 구분자로 단계적 힌트 1..n
        └── explanation.ko.md        # 해설 (정답 후 표시)
```

- **콘셉트 택소노미는 Exercism Gleam 트랙의 36개 슬러그를 시드로 차용**한다(basics, case-expressions, custom-types, recursion, tail-call-optimisation, pipe-operator, results, options, use-expressions, opaque-types, phantom-types, ...). 슬러그 체계만 차용하고 **본문/테스트 텍스트는 라이선스 확인 전 재사용 금지**, gleam-test-runner(AGPL-3.0) 코드는 절대 vendoring 금지.
- 콘셉트 태그가 lichess의 퍼즐 테마(fork, pin, ...)에 1:1 대응한다 — 테마별 드릴, 테마별 레이팅, 약점 대시보드의 키가 된다.

### 4.2 메타데이터 스키마

```toml
# puzzle.toml
id = "exhaustive-shapes-001"
type = "fix_compile_error"        # fix_compile_error | fill_hole | predict_output | write_function | choice
themes = ["case-expressions", "custom-types", "exhaustiveness"]
seed_rating = 1150                # 저작자 추정 (lichess validator의 estimated rating에 대응)
seed_rd = 350                     # 높게 시작 → 시도 데이터로 빠르게 수렴
compiler = "1.17.0"
timeout_ms = 3000
grading = "tests"                 # tests | exact_output | choice
editable = "all"                  # all | hole-only (CodeMirror read-only 영역 제어)
srs_item = "case-exhaustiveness"  # 이 퍼즐이 갱신하는 SRS 마이크로 스킬 ID
```

실제 퍼즐 예 (fix_compile_error — Gleam 컴파일러의 친절한 에러가 곧 교보재):

```gleam
// starter.gleam — 컴파일되지 않는다: case가 모든 variant를 다루지 않음
pub type Shape {
  Circle(radius: Float)
  Rect(width: Float, height: Float)
}

pub fn area(shape: Shape) -> Float {
  case shape {
    Circle(r) -> 3.14 *. r *. r
  }
}
```

predict_output 예 (fold의 누적 방향 이해를 드릴):

```gleam
import gleam/io
import gleam/list

pub fn main() {
  ["g", "l", "e", "a", "m"]
  |> list.fold("", fn(acc, ch) { ch <> acc })
  |> io.println
}
// 정답: "maelg" — 빌드 파이프라인이 실제 실행으로 검증·고정
```

### 4.3 콘텐츠 빌드 파이프라인 (CI 골든 검증)

빌드 스크립트는 Gleam 프로그램(tour의 사이트 제너레이터와 동일한 접근)이며, GitHub Actions에서 모든 PR에 대해 실행한다:

1. **스키마 검증**: TOML 필수 필드, 테마 슬러그가 concepts.toml에 존재, prerequisite 그래프 무사이클.
2. **골든 컴파일 검증 — 반드시 브라우저와 동일한 WASM 컴파일러로**: Node 18+에서 `gleam_wasm.js`를 bytes로 init해 런타임 파이프라인과 자구까지 동일한 경로로 실행한다 (네이티브 CLI로 검증하면 에러 텍스트·동작 괴리 위험).
   - `solution.gleam` + `test.gleam` → 컴파일 성공 + 전 테스트 pass.
   - `fix_compile_error` 타입: `starter.gleam`이 **실제로 컴파일 실패**하고, 에러 제목이 메타데이터의 기대 카테고리와 일치.
   - `predict_output` 타입: 코드를 실행해 출력을 `answer.txt`로 고정(스냅샷) — 컴파일러 업그레이드 시 드리프트가 CI에서 즉시 드러남.
   - `fill_hole` 타입: starter가 `todo`로 컴파일은 통과하되 테스트는 실패함을 확인 (빈칸이 실제로 채점을 좌우하는지 검증).
3. **번들 산출**: 레슨/퍼즐을 단위별 JSON 청크로 직렬화(prose는 사전 렌더된 HTML + tree-sitter 하이라이팅 포함), 앱이 lazy-load. 전체 콘텐츠를 한 덩어리로 싣지 않는다.
4. **컴파일러 업그레이드 절차**: 핀 버전 bump → 전체 골든 재실행 → 달라진 에러 텍스트/출력 diff를 사람이 리뷰 → 콘텐츠 수정 커밋과 함께 머지. 이것이 §9의 버전 리스크 완화 장치다.

### 4.4 i18n

- 콘텐츠: 로케일별 파일(`prose.ko.md`/`prose.en.md`, `hints.ko.md`/...) — **코드·테스트·메타데이터는 공유**, 산문만 분기. 누락 로케일은 빌드가 fallback(en→ko 또는 역방향)을 기록하고 경고만 낸다(이중 작성 강제 금지 — 1인 저작 현실 반영).
- UI 문자열: Gleam 모듈의 단순 key-value 함수 2벌(`i18n/ko.gleam`, `i18n/en.gleam`). 라이브러리 불필요.
- 전략: **ko 우선 저작, en은 트래픽이 증명된 유닛부터** 역번역.

---

## 5. 데이터 모델

### 5.1 도메인 타입 (Gleam — 프론트/백엔드 공유)

```gleam
pub type Glicko {
  Glicko(rating: Float, deviation: Float, volatility: Float)
}

pub type Outcome {
  Passed
  Failed(reason: String)     // 테스트 실패 / 컴파일 에러 / 오답
  TimedOut
  GaveUp                     // 명시적 포기 — SRS 간격 축소의 유일한 트리거
}

pub type Attempt {
  Attempt(
    id: String,              // uuid — 서버 병합 시 중복 제거 키
    puzzle_id: String,
    at_ms: Int,              // client unix ms
    outcome: Outcome,
    duration_ms: Int,
    hints_used: Int,         // 1 이상이면 rated = False (lichess 규칙)
    rated: Bool,
    rating_before: Float,
    rating_after: Float,
  )
}

pub type SrsItem {
  SrsItem(item_id: String, level: Int, due_at_ms: Int, lapses: Int)
  // level 1..8 → 간격 4h/1d/3d/1w/2w/1mo/3mo/6mo, 실패 시 level=1
}
```

### 5.2 localStorage 스키마 (M1–M2)

네임스페이스 + 스키마 버전으로 키를 고정. 시도 로그(가변 크기)와 프로필(스칼라 상태)을 분리:

```jsonc
// key: "fpdojo.v1.profile"  — 파생/스칼라 상태 (리플레이로 재계산 가능)
{
  "schema": 1,
  "user_id": "c0ffee-uuid",            // 로컬 생성, M3 계정 연결 시 매핑
  "compiler_seen": "1.17.0",
  "ratings": {
    "overall": { "r": 1200.0, "rd": 350.0, "vol": 0.06 },
    "by_theme": { "recursion": { "r": 1080.0, "rd": 290.0, "vol": 0.06 } }
  },
  "lessons":  { "u02-l03": { "status": "completed", "steps_done": 6 } },
  "srs":      { "case-exhaustiveness": { "level": 3, "due_at_ms": 0, "lapses": 1 } },
  "settings": { "locale": "ko", "difficulty_band": 0 }   // lichess식 ±오프셋
}

// key: "fpdojo.v1.attempts" — append-only 이벤트 로그 (진실의 원천)
[ { "id": "...", "puzzle_id": "...", "at_ms": 0, "outcome": "passed",
    "duration_ms": 41200, "hints_used": 0, "rated": true,
    "rating_before": 1200.0, "rating_after": 1213.5 } ]
```

운영 규칙:

- localStorage ~5MB 한도 대비: attempts는 최근 N=2,000건 유지, 초과분은 테마별 집계(승/패 카운트)로 컴팩션 후 절단. 레이팅·SRS는 이미 profile에 물질화되어 있어 손실 없음.
- **JSON 내보내기/가져오기 버튼은 M1 필수 기능** — 계정 없는 동안 기기 분실·브라우저 초기화가 유일한 데이터 손실 경로이므로.
- 퍼즐 레이팅: MVP에서는 콘텐츠 번들의 `seed_rating/seed_rd`를 정적 사용. 로컬 유저 레이팅만 Glicko-2로 갱신(유저 vs 정적 퍼즐의 rated game). 퍼즐 쪽 레이팅의 전역 보정은 시도 데이터가 모이는 M3 서버 배치 작업에서 — lichess가 validator 추정치로 시드하고 시도 데이터로 수렴시킨 것과 동일한 경로.

### 5.3 서버 마이그레이션 경로 (M3)

이벤트 소싱 덕에 마이그레이션은 기계적이다:

1. 계정 생성(이메일 매직 링크) → 클라이언트가 `attempts` 로그 전체 + profile을 업로드.
2. 서버는 attempt를 `id`(uuid) 기준 union — 멱등, 다기기 병합 자동 해결. profile 스칼라는 서버 리플레이로 재계산(클라이언트 계산을 신뢰하지 않음).
3. 이후 동기화 = "마지막 커서 이후 이벤트 업로드 + 서버 파생 상태 다운로드". 오프라인 우선 유지.
4. SQLite 스키마는 5.1의 타입을 그대로 테이블화: `users`, `attempts`(uuid PK), `srs_items`, `rating_history`(스냅샷), `puzzle_ratings`(전역 보정 결과, nightly Glicko-2 배치).

---

## 6. 트레이닝 모드와 레이팅·SRS 메커니즘 (아키텍처 관점 요약)

모든 모드는 **단일 프리미티브 — "rated exercise 시도" — 위의 얇은 레이어**다 (체스 플랫폼 분석의 핵심 교훈):

- **레슨 스텝**: 짧은 prose 청크 → 임베디드 체크(predict/fill/fix) 5–10개, 시도마다 즉각 피드백(chess.com 레슨 구조). 순차 unlock + 건너뛰기 확인 프롬프트. unlock 조건은 Execute Program식 — 선행 레슨을 읽었고 **최근 리뷰에 성공**했을 것.
- **레이팅 퍼즐**: 매 첫 무힌트 시도 = 유저 vs 퍼즐의 Glicko-2 rated game. 힌트 사용 시 unrated. 난이도 밴드는 유저 레이팅 대비 오프셋(lichess의 ±300/600). Glicko-2 구현은 Glickman 논문 기준 순수 함수 ~150줄 Gleam — 단위 테스트 용이.
- **Streak**: 시드 레이팅 오름차순, 무제한 시간, 1회 실수로 종료, 스킵 1회 (lichess 규칙 그대로).
- **Storm**: 3분, 1스텝 마이크로 문제(choice/predict/한 줄 fill), 콤보 5/12/20/30+10마다 +3/+5/+7/+10s, 오답 −10s + 콤보 리셋, unrated. timeout=오답 매핑(§3.5).
- **SRS**: 아이템 = 마이크로 스킬(`srs_item` 태그). MoveTrainer식 8레벨(4h/1d/3d/1w/2w/1mo/3mo/6mo), 실패 시 L1 리셋. Execute Program 규칙 차용: 재시도 무벌점, 명시적 "포기"만 간격 축소, **일일 신규 아이템 상한**으로 몰아보기 방지. Learn 모드 = 정답을 보여준 뒤 재구성 요구, Review 모드 = 순수 회상. L8 성공 시 retire(Execute Program의 ~4회 성공 retire와 Chessable 무한 유지의 절충).
- **실수 리뷰**: 실패 attempt 로그에서 테마별 약점 대시보드(90일 윈도) + 실패 퍼즐 재출제 큐 — 추가 데이터 없이 attempts 로그의 뷰일 뿐이다.

---

## 7. MVP 로드맵

### M1 — "컴파일 파이프라인 + 레슨 엔진" (약 8주)

범위:

- 컴파일/실행/채점 파이프라인 전체 (§3): 듀얼 워커, watchdog, 하니스, 진단 정규식 파싱. **1주차 스파이크로 중급 Android 실기기에서 컴파일 지연 측정**(다이제스트상 미측정 — 최우선 미지수 제거).
- Lustre 앱 셸 + CodeMirror 통합(grammar 포크 포함) + localStorage 저장 + JSON 내보내기/가져오기.
- 콘텐츠 빌드 파이프라인 + CI 골든 검증 (§4.3).
- 콘텐츠: 유닛 2개(예: "Gleam 기초·파이프라인", "case와 custom types") = 레슨 ~10개 × 스텝 5–8개, 퍼즐 20개(타입: fix_compile_error, fill_hole, predict_output 3종).

완료 정의 (DoD): 낯선 사용자가 정적 URL에서 두 유닛을 끝까지 완료할 수 있다; 새로고침해도 진행도가 유지된다; 무한루프 제출이 3초 내 진단 메시지로 복구된다; CI가 전 콘텐츠를 골든 검증한다; 중급 모바일 컴파일 p95 측정치가 기록되어 있다.

규모 감: 파이프라인 자체는 tour 참조 구현(~170줄) + watchdog/하니스로 1.5–2주. 나머지는 레슨 엔진 UI와 콘텐츠 저작이 지배한다.

### M2 — "레이팅 + 전 퍼즐 타입 + 트레이닝 모드" (약 6주)

범위:

- Glicko-2(로컬) + 시드 레이팅 보정 워크플로; 퍼즐 타입 5종 완성(write_function, choice 추가); 난이도 밴드 선택.
- 트레이닝 모드: 테마별 드릴 / healthy mix / Streak / Storm.
- 미니 대시보드(테마별 레이팅, 실패 퍼즐 재출제 큐).
- 콘텐츠: 퍼즐 150개+ (저작 도구: `scaffold` CLI — TOML/파일 템플릿 생성), 유닛 1–2개 추가.

DoD: 유저가 자기 레이팅 ±밴드의 퍼즐을 무한 공급받는 루프가 동작; Storm/Streak 런이 종료 화면·기록 저장까지 완결; 퍼즐당 평균 저작 시간 측정치 ≤ 45분.

### M3 — "계정/서버, SRS, 대시보드" (약 8주)

범위:

- Wisp + Mist + SQLite(+Litestream) 백엔드, 이메일 매직 링크 계정, attempt 로그 동기화(§5.3).
- 퍼즐 레이팅 전역 보정 nightly 배치(Glicko-2, 시도 데이터 집계).
- SRS 전체(8레벨 스케줄, Learn/Review 모드, 일일 큐, 신규 상한) — 레슨 unlock 조건에 리뷰 성공 연동.
- 강약점 대시보드(90일), 실수 리뷰 큐 고도화.
- OTP/actor 캡스톤 유닛은 **read-only 콘텐츠**(JS 타깃에서 실행 불가 — gleam_otp는 Erlang VM 전용)로 추가; 서버사이드 Erlang 러너는 이 시점에도 만들지 않는다(필요성이 증명될 때까지).

DoD: 두 기기에서 같은 계정으로 진행도·레이팅·SRS 큐가 일치; 퍼즐 레이팅이 시드에서 이탈해 수렴하는 그래프 확인; 일일 리뷰 큐가 10분 분량으로 생성된다.

---

## 8. 의도적으로 하지 않는 것

- 서버사이드 코드 실행 (Docker 샌드박스) — Erlang 타깃 채점·임의 Hex 의존성·비공개 테스트가 **증명된 수요**가 되기 전까지.
- Monaco, 인브라우저 LSP(존재하지 않음 — Gleam LS는 네이티브 바이너리 전용), Lustre server components.
- compiler-wasm 포크 — 평문 파싱 골든 테스트가 깨지기 시작할 때만.
- 실시간 멀티플레이(Clash of Code류) — 퍼즐 뱅크 프리미티브 위 레이어로 언제든 후행 추가 가능.
- 타입클래스/커링/매크로/지연평가 콘텐츠를 "구현"하는 것 — 대신 각각을 "왜 Gleam에는 없는가" 단문 레슨으로(공식 FAQ 인용). 커리큘럼 표면적 축소는 1인 개발의 생존 전략이다.

---

## 9. 리스크와 완화

| # | 리스크 | 영향 | 완화 |
|---|---|---|---|
| R1 | **콘텐츠 제작 비용 (최대 리스크)** — 레슨·퍼즐·힌트·해설·2개 언어를 1인이 저작 | 플랫폼이 비어 보이면 메커니즘이 아무리 좋아도 무의미 | (a) 원자적 퍼즐 포맷(30–90초 풀이)으로 저작 단가 최소화 — Rustlings식 fix-error는 컴파일러 에러가 해설의 절반을 대신함. (b) generator→validator 파이프라인: 검증된 솔루션 코드에 변이(버그 1개 주입, 구멍 1개 뚫기)를 가한 후보를 스크립트로 양산, CI가 "정확히 의도된 수정 1개로 통과"를 검증, 사람은 선별만. (c) 시드 레이팅 정밀도에 시간 쓰지 않기 — 높은 초기 RD로 Glicko-2가 자가 보정. (d) Exercism 36 슬러그 택소노미 차용(콘텐츠 본문은 라이선스 확인 전 금지, AGPL 러너 코드 금지). (e) ko 우선, en은 후행 |
| R2 | WASM 컴파일러 API 비공식·미문서 — 릴리스마다 시그니처 변경 가능, npm 배포 없음 | 업그레이드 시 파이프라인 파손 | v1.17.0 핀 + tarball 자체 미러. WASM API 접점을 단일 어댑터 모듈(compiler.worker.js)로 격리. 업그레이드는 §4.3 절차(전 콘텐츠 골든 재검증)로만 |
| R3 | 에러 평문 파싱 취약성 — pretty 포맷은 안정 보장 없음 | inline 위치 표시·에러 분류 파손 | 파서를 골든 테스트(대표 에러 코퍼스)로 보호; 깨지면 그때 compiler-wasm 포크(`read_diagnostics`)로 전환 — 포크 비용(릴리스마다 Rust 빌드)은 명시적으로 인지하고 연기 |
| R4 | 모바일 성능 — 1.66MB WASM + stdlib 번들 + 미측정 컴파일 지연 | 모바일 이탈 | M1 1주차 실측 스파이크. 컴파일러 lazy-load + Service Worker 영구 캐시(?v= 키). **choice/predict형은 컴파일러 불필요** — 모바일 SRS 리뷰 큐를 비컴파일 타입 위주로 구성하는 폴백 |
| R5 | 무한루프/중재귀로 탭 행 | 신뢰 손상 | §3.5 듀얼 워커 + watchdog가 설계 차원에서 해결. 러너 일회용화로 상태 누수 차단 |
| R6 | localStorage 데이터 유실 (M3 전) | 진행도 소실 → 이탈 | JSON 내보내기/가져오기 M1 필수. attempts 컴팩션으로 한도 방어. M3 동기화가 근본 해결 |
| R7 | 클라이언트 채점 신뢰성 — 테스트가 클라이언트에 노출, 출력 위조 가능 | 레이팅 오염(공개 경쟁 도입 시) | MVP 레이팅은 로컬 전용(무해). 런별 난수 토큰으로 캐주얼 스푸핑 방지. 공개 리더보드는 서버 재검증 전까지 만들지 않음 |
| R8 | Lustre 메인테이너 1인 / 소규모 생태계 | 장기 유지보수 | MVU 구조상 view 레이어 국소적; FFI 접점(에디터·워커·storage) 3곳을 포트 패턴으로 격리해 최악의 경우 view만 이식. 스폰서십·정기 릴리스(v5.7.0, 2026-05)로 단기 리스크는 낮음 |
| R9 | Erlang 타깃 의미론(OTP, 정수 크기 등)을 브라우저에서 시연 불가 | 고급 커리큘럼 제약 | OTP는 read-only 캡스톤으로 명시 설계(M3). "컴파일러가 타깃별 지원을 표현식 단위로 추적한다"는 사실 자체를 레슨 소재로 전환 |
| R10 | i18n 이중 유지보수 | 저작 속도 절반 | 코드·테스트·메타데이터 공유, 산문만 분기, fallback 렌더 허용. 번역은 수요 증명 후 |
| R11 | 컴파일러 버전 업그레이드가 기대 에러·출력을 바꿈 | 콘텐츠 무더기 파손 | predict 출력·기대 에러를 전부 CI 스냅샷으로 고정 → 업그레이드 diff가 전수 가시화 (§4.3) |

---

## 10. 참조 소스 (구현 시 정독 목록)

- `gleam-lang/language-tour` — `static/compiler.js`, `static/worker.js`(파이프라인 참조 구현), `src/tour.gleam`의 `generate_stdlib_bundle`/`copy_compiled_stdlib`, `bin/download-compiler`.
- `gleam-lang/gleam` — `compiler-wasm/src/lib.rs`(WASM API 전체), 이슈 #3245(의존성 미지원 추적).
- LiveCodes Gleam 문서 — Hex 패키지 vendoring 패턴.
- `ornicar/lichess-puzzler` — generator→validator→tagger 파이프라인 구조.
- Glickman, "Example of the Glicko-2 system" — 레이팅 구현 명세.
- Exercism `config.json`(Gleam 트랙) — 콘셉트 슬러그 36개, prerequisites/practices 스키마; test-runner results.json v2 계약.