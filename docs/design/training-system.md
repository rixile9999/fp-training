# 트레이닝 시스템 설계 — 퍼즐/드릴 (Gleam FP 학습 플랫폼)

> 범위: 체스 퍼즐에 대응하는 트레이닝 시스템 전체 — 퍼즐 타입 분류, Glicko-2 레이팅, 6개 모드, 힌트/피드백, 브라우저 내 채점, 진행/동기 시스템.
> 전제 인프라: language-tour 아키텍처 (공식 WASM 컴파일러 `gleam-v1.17.0-browser.tar.gz` 핀 고정, Web Worker 내 `compile_package(project_id, "javascript")`, precompiled stdlib `.mjs`, base64 data-URL dynamic import, `console.log` 캡처) + 본 문서에서 추가하는 watchdog/채점 하니스.
> 본 문서의 모든 Gleam 코드는 gleam 1.16.0 (JS target)에서 컴파일·실행 검증 완료. 인용된 컴파일러 에러/경고 문구는 실제 출력 그대로다.

---

## 0. 설계 원칙

1. **단일 primitive 위의 박막(thin layer) 구조.** 모든 모드는 하나의 공통 primitive — "rated puzzle attempt" (퍼즐 1개 + 채점 1회 + 레이팅 이벤트 0~1회) — 를 재사용한다. 빌드 순서도 이를 따른다: 퍼즐 러너 → 레이팅 → Rush/Streak (러너 + 타이머) → SRS (러너 + 스케줄 테이블) → 대시보드.
2. **퍼즐은 30~120초 단위.** Exercism 연습문제 크기가 아니라 lichess 퍼즐 크기. SRS 리뷰 슬롯과 Rush 타이머에 맞는 원자성이 핵심이다.
3. **체스 퍼즐의 "한 수 틀리면 실패" 의미론을 코드에 맞게 번역.** 코드는 정답이 여럿이므로, 정답 판정은 exact-match가 아니라 *제약된 문제 형태* (단일 홀, 선택지, 줄 순서) 또는 *테스트 동치성*으로 한다. rated 판정 이벤트는 "첫 무힌트 제출 1회"로 고정한다.
4. **컴파일러가 제1의 채점자이자 튜터.** Gleam의 친절한 에러 메시지를 채점(컴파일 성공 여부)과 피드백(에러 번역 레이어) 양쪽에 활용한다.
5. **게이미피케이션은 rated 루프 밖에.** lichess Storm이 unrated이듯, 시간압박 모드와 리더보드는 레이팅과 분리한다.

---

## 1. 퍼즐 타입 분류 체계

퍼즐은 **타입(형식) × 테마(개념 태그)** 의 2축으로 분류한다. 타입은 "어떤 인지 기술을 훈련하는가", 테마는 "어떤 Gleam 개념을 훈련하는가"를 결정한다.

### 1.1 타입 요약표

| ID | 타입 | 훈련하는 인지 기술 | 채점 방식 | Rush 사용 |
|----|------|------------------|----------|----------|
| T1 | predict-the-output | **Tracing/멘탈 시뮬레이션** — 평가 순서, 데이터 흐름 추적 | 선택지 또는 출력 텍스트 비교 | O (선택지형) |
| T2 | fix-the-compile-error | **진단(diagnosis)** — 타입 시스템 멘탈모델, 컴파일러 메시지 독해 | 컴파일 성공 + 히든 테스트 | X |
| T3 | fill-the-hole | **타입 주도 생성(type-directed synthesis)** — 표현식 단위 생산 | 홀 치환 후 컴파일 + 히든 테스트 | O (한 줄 홀) |
| T4 | refactor-to-idiom | **변환(transformation)** — 관용구 인식, 동치 보존 리팩토링 | 히든 테스트 + 구조 린트 | X |
| T5 | write-function-against-tests | **종합 생성(generation)** — 시그니처에서 구현까지 | 히든 테스트 (per-test 결과) | X |
| T6 | Parsons problem | **시퀀싱(sequencing)** — 제어 흐름/구조 감각, 낮은 타이핑 부담 | 조립 후 컴파일 + 테스트 | O (4~6줄) |
| T7 | spot-the-bug | **평가(evaluation)/디버깅** — 컴파일은 통과하는 논리 결함 탐지 | 1단계: 줄 지목, 2단계: 수정 후 테스트 | O (1단계만) |
| T8 | micro-MCQ | **개념 변별** — 디슈가링, 타입 판별 등 즉답형 | 선택지 비교 (실행 불필요) | O (전용) |

타입 분포 가이드: 레슨 직후 드릴은 T1/T3/T6 (인지 부하 낮음), rated 풀의 중심은 T2/T3/T7, 고난도 영역은 T4/T5.

### 1.2 T1 — predict-the-output (출력 예측)

코드를 읽고 출력을 예측한다. 실행 전 머릿속 평가기를 훈련한다 — pipe 체인의 데이터 흐름, `fold`의 누적 순서, 평가 의미론. 인지적으로는 retrieval practice의 가장 순수한 형태(재인이 아닌 산출)이며, 선택지형으로 만들면 distractor마다 특정 오개념을 짝지을 수 있다 (Brilliant의 misconception targeting).

```gleam
import gleam/int
import gleam/io
import gleam/list

pub fn main() {
  [1, 2, 3, 4, 5]
  |> list.filter(fn(n) { n % 2 == 1 })
  |> list.map(fn(n) { n * n })
  |> list.fold(0, fn(acc, n) { acc + n })
  |> int.to_string
  |> io.println
}
```

- 정답: `35` (1 + 9 + 25). 검증된 실제 출력.
- distractor 설계: `30` (filter를 짝수로 오해), `55` (filter 누락으로 오해), `225` (map과 fold 혼동). 각 distractor에 오답 선택 시 표시할 1줄 코멘트를 붙인다.
- 테마 태그 예: `pipe-operator`, `lists`, `anonymous-functions`.

### 1.3 T2 — fix-the-type-error (컴파일 에러 수정)

Rustlings 계보의 "고장난 작은 프로그램". 컴파일러 에러를 읽고 최소 수정으로 통과시킨다. 타입 시스템에 대한 멘탈모델과 에러 메시지 독해력을 훈련한다 — Gleam 학습에서 가장 빈번한 실제 작업이므로 rated 풀의 주력 타입이다.

```gleam
import gleam/io

pub fn main() {
  let count = 3
  io.println("count: " <> count)
}
```

학습자가 보는 실제 컴파일러 출력(검증됨):

```
error: Type mismatch
  ┌─ /src/main.gleam:5:27
  │
5 │   io.println("count: " <> count)
  │                           ^^^^^

The <> operator expects arguments of this type:

    String

But this argument has this type:

    Int
```

- 모범 답안: `io.println("count: " <> int.to_string(count))` (검증됨).
- 채점: 컴파일 성공 **그리고** 히든 테스트 통과. 테스트 없이는 해당 줄 삭제 같은 퇴행적 수정도 통과해 버린다.
- 변형: **exhaustiveness 퍼즐** — `case`에서 variant 하나를 빼면 컴파일러가 `error: Inexhaustive patterns ... The missing patterns are: Triangle(base:, height:)` (실제 문구, 검증됨)를 내므로, "누락된 패턴 추가" 퍼즐을 대량 자동 생성할 수 있다. 테마: `case-expressions`, `custom-types`, `results`, `generics`.

### 1.4 T3 — fill-the-hole (빈칸 채우기)

홀 1개에 표현식을 채운다. 핵심 설계: **홀 마커는 `todo`다.** Gleam에서 `todo`는 임의 타입으로 unify되므로 템플릿 자체가 항상 컴파일되고, 컴파일러가 홀의 기대 타입을 경고로 알려준다.

```gleam
import gleam/list

pub fn first_even(numbers: List(Int)) -> Result(Int, Nil) {
  list.find(numbers, todo)
}
```

이 템플릿을 컴파일하면 실제로 다음 경고가 나온다(검증됨):

```
warning: Todo found
  ...
Hint: I think its type is `fn(Int) -> Bool`.
```

즉 **1단계 힌트("이 자리에 필요한 타입")를 컴파일러에게서 공짜로 얻는다** — `pop_warning`으로 드레인해서 파싱만 하면 된다.

- 모범 답안: `fn(n) { n % 2 == 0 }` (히든 테스트 `assert first_even([1, 3, 4, 5]) == Ok(4)`, `assert first_even([1, 3]) == Error(Nil)` 통과 검증됨).
- 입력 제약: 단일 표현식만 허용 — `import`/`pub`/줄바꿈 다수 금지(§5.4 가드 참조). 이 제약이 "한 수" 단위의 원자성을 보장한다.
- 인지 기술: 타입에서 구현을 역산하는 type-directed thinking. Gleam이 type class 없이 명시적 함수 전달을 쓰는 언어라서 특히 가치가 높다.

### 1.5 T4 — refactor-to-idiom (관용구 리팩토링)

동작은 같지만 비관용적인 코드를 Gleam 관용구로 변환한다. "동치 보존 변환" 능력과 idiom 어휘를 훈련한다. pipe, `use`, function capture `f(_, x)`, label shorthand가 주요 대상.

제시 코드 (중첩 호출):

```gleam
import gleam/list
import gleam/string

pub fn shout(words: List(String)) -> String {
  string.uppercase(string.join(list.map(words, string.trim), " "))
}
```

모범 답안 (둘 다 `[" hello ", "gleam "]` → `"HELLO GLEAM"` 동작 검증됨):

```gleam
pub fn shout(words: List(String)) -> String {
  words
  |> list.map(string.trim)
  |> string.join(" ")
  |> string.uppercase
}
```

- 채점: (1) 컴파일, (2) 히든 테스트로 동작 보존 확인, (3) **구조 린트** — 소스에 `|>`가 3회 이상 등장하고 중첩 깊이 조건을 만족하는지 (tree-sitter-gleam 쿼리 또는 정규식). 테스트만으로는 "리팩토링 안 하고 제출"을 못 거른다.
- 변형: callback 지옥 → `use result.try` 변환, `fn(x) { f(x, k) }` → `f(_, k)` capture 변환.

### 1.6 T5 — write-function-against-tests (테스트 대상 함수 작성)

시그니처와 공개 테스트 일부를 보고 함수를 구현한다. 가장 무거운 타입(60~120초 상한)으로, 종합 생성 능력을 훈련한다. Gleam에 루프가 없으므로 재귀/fold 선택 자체가 학습 포인트다.

제시:

```gleam
/// 리스트에서 Ok 값만 순서대로 추출하라.
pub fn keep_oks(results: List(Result(a, e))) -> List(a) {
  todo
}
```

모범 답안(검증됨):

```gleam
pub fn keep_oks(results: List(Result(a, e))) -> List(a) {
  case results {
    [] -> []
    [Ok(value), ..rest] -> [value, ..keep_oks(rest)]
    [Error(_), ..rest] -> keep_oks(rest)
  }
}
```

- 히든 테스트는 v1.11+의 `assert` 키워드 기반: `assert keep_oks([Ok(1), Error("x"), Ok(3)]) == [1, 3]`, `assert keep_oks([]) == []` (통과 검증됨).
- 해설 단계에서 복수 모범 답안 제시: 위 재귀 버전, `list.fold` + `list.reverse` 버전, `result.values` 한 줄 버전 — "stdlib에 이미 있다"는 어휘 확장도 해설의 일부다.

### 1.7 T6 — Parsons problem (코드 줄 순서 맞추기)

섞인 코드 줄을 드래그해서 올바른 프로그램을 조립한다. 타이핑 부담 없이 **구조와 제어 흐름 감각**(시퀀싱)을 훈련한다. 초심자 구간과 모바일에서 핵심 타입. 꼬리 재귀 accumulator 패턴처럼 "구조가 곧 내용"인 테마에 최적이다.

정답 프로그램(검증됨) — 학습자에게는 7줄이 섞여서 제시된다:

```gleam
pub fn sum(numbers: List(Int)) -> Int {
  sum_loop(numbers, 0)
}

fn sum_loop(numbers: List(Int), acc: Int) -> Int {
  case numbers {
    [] -> acc
    [first, ..rest] -> sum_loop(rest, acc + first)
  }
}
```

- 채점: 조립된 소스를 그대로 컴파일 + 히든 테스트 (`assert sum([1, 2, 3, 4]) == 10` 검증됨). **저자가 지정한 유일 순서와의 비교가 아니라 "컴파일되고 테스트를 통과하는 임의 순서"를 정답으로 인정** — 두 `case` arm의 순서처럼 교환 가능한 줄 문제를 자동으로 해결한다.
- 인덴테이션은 시스템이 `gleam format` 규칙으로 자동 부여하므로 순서만 채점 대상이다. distractor 줄(예: `[first, ..rest] -> sum_loop(rest, acc)` — acc 갱신 누락) 1~2개를 섞는 고난도 변형 가능.

### 1.8 T7 — spot-the-bug (논리 버그 찾기)

**컴파일은 통과하지만** 의도와 다르게 동작하는 코드에서 버그를 찾는다. 타입 시스템이 못 잡는 결함을 다루므로 T2와 상보적이며, 코드 리뷰/디버깅이라는 상위 인지 기술(평가)을 훈련한다.

```gleam
import gleam/list

/// 의도: 단어들을 공백 한 칸으로 이어붙인다. ["hello", "world"] -> "hello world"
pub fn join_words(words: List(String)) -> String {
  list.fold(words, "", fn(acc, word) { word <> " " <> acc })
}
```

- 실제 동작(검증됨): `["hello", "world", "gleam"]` → `"gleam world hello "` — 순서 역전 + 끝 공백. `list.fold` 콜백의 `fn(acc, item)` 인자 순서와 누적 방향에 대한 오해는 Gleam 입문자의 대표적 함정이다 (tricky-part 태그 `fold-arg-order`).
- 2단계 채점: (1) 버그가 있는 줄/스팬 클릭 (저자 지정 스팬과 비교), (2) 수정 제출 → 히든 테스트. Rush에서는 1단계만 사용.
- 모범 수정: `acc` 결합 방향 교정 또는 idiomatic하게 `string.join(words, " ")`.

### 1.9 T8 — micro-MCQ (Rush 전용 즉답형)

실행 없이 5~15초에 답하는 개념 변별 문제. Rush/Streak의 난이도 하단을 채운다. 대표 소재 — `use` 디슈가링(검증된 코드):

```gleam
import gleam/int
import gleam/result

pub fn parse_both(a: String, b: String) -> Result(#(Int, Int), Nil) {
  use x <- result.try(int.parse(a))
  use y <- result.try(int.parse(b))
  Ok(#(x, y))
}
```

문항 예: "`use x <- result.try(int.parse(a))`는 무엇의 sugar인가?" → 정답: `result.try(int.parse(a), fn(x) { ... })` (trailing anonymous function 전달). 기타 소재: "이 표현식의 타입은?", "이 패턴이 매칭하는 값은?", "`let assert`와 `assert`의 차이는?".

### 1.10 테마 태그 체계 (타입과 직교)

초기 분류는 **Exercism Gleam 트랙의 36개 concept slug를 그대로 채택**한다 (basics, case-expressions, custom-types, recursion, tail-call-optimisation, pipe-operator, results, options, generics, opaque-types, use-expressions, labelled-arguments, phantom-types 등) — 레슨 트리와 퍼즐 테마가 같은 어휘를 쓰게 되어 "레슨 ↔ 드릴" 연결이 공짜로 생긴다. 여기에 **tricky-part 태그**를 추가한다:

`fold-arg-order`, `tail-call-accumulator`, `exhaustiveness`, `use-desugaring`, `result-chaining`, `shadowing`, `label-shorthand`, `capture-vs-currying`, `int-float-operators` (`+` vs `+.`), `string-vs-int-concat`, `empty-list-base-case`, `option-vs-result`.

퍼즐 1개 = 타입 1개 + 테마 1~3개 (주 테마 1개 필수). 체스의 fork/pin 테마 태그와 동일한 역할: 테마 트레이닝의 필터, 대시보드의 축, SRS 카드의 그룹 키.

---

## 2. 레이팅 시스템 (Glicko-2)

### 2.1 기본 구조 — "퍼즐과의 rated 대국"

lichess 의미론을 그대로 채택한다: **모든 첫 무힌트 시도는 유저와 퍼즐 간의 Glicko-2 rated 게임**이다. 풀면 유저가 점수를 얻고 퍼즐이 잃으며, 실패하면 반대. 양쪽 모두 (rating `r`, deviation `RD`, volatility `σ`)를 보유한다.

| 엔티티 | 초기 rating | 초기 RD | σ | RD 하한 |
|--------|-----------|---------|---|---------|
| 유저 (글로벌) | 1500 | 350 | 0.06 | 45 |
| 유저 (테마별 서브) | 글로벌 현재값에서 분기 | 250 | 0.06 | 60 |
| 퍼즐 | 난이도 티어 매핑 (아래) | 300 | 0.06 | 75 |

기대 승률은 Glicko의 표준식 — E = 1 / (1 + 10^(−g(RD_p)·(r_u − r_p)/400)) — 을 쓰고, 업데이트는 Glickman 논문의 절차를 그대로 구현한다 (구현 참조: lichess lila, 오픈소스). 수학은 작다; 함수 3개면 된다.

**rated 판정 규칙:**
- rated 이벤트는 퍼즐당 유저별 **최초 1회**, 무힌트 첫 제출만. (재도전, SRS 복습, Rush, Streak, Daily는 전부 unrated.)
- 힌트를 한 단계라도 열면 그 시도는 unrated (lichess와 동일).
- 다단계 퍼즐(T7의 지목+수정)은 모든 단계를 첫 시도에 통과해야 승리 — "한 수라도 틀리면 패배" 의미론의 번역.
- watchdog 시간 초과(무한 루프)는 오답으로 판정.
- 풀이 시간은 레이팅에 **반영하지 않고** 기록만 한다 (대시보드와 FSRS 마이그레이션용 데이터).

### 2.2 퍼즐 초기 레이팅과 캘리브레이션

lichess의 generator → validator → tagger 파이프라인을 모사한다.

1. **생성(generator):** 검증된 정상 코드에서 (a) 버그 1개 주입(뮤테이션: 인자 순서 교환, variant 누락, base case 변경, 연산자 교체 `+`→`+.`), (b) 홀 1개 굴착, (c) 줄 섞기. 각 후보는 자동 검증 — "의도된 수정이 정확히 1개"인지 컴파일 + 테스트로 확인 (뮤턴트가 테스트를 통과해 버리면 폐기).
2. **검증(validator):** 저자/리뷰어가 품질 0~5점과 **난이도 티어 1~9** (Exercism difficulty 스케일 재사용)를 부여. 티어 → 초기 레이팅 매핑: `1→800, 2→1000, 3→1200, 4→1400, 5→1600, 6→1800, 7→2000, 8→2300, 9→2600`.
3. **보정(calibration):** 초기 RD 300이므로 초반 20~30회 시도로 빠르게 수렴한다. 신규 퍼즐에는 **placement boost** — 믹스드 큐에서 출제 확률 가중치 1.5배(RD가 150 아래로 내려갈 때까지) — 를 줘서 수렴을 앞당긴다.
4. **품질 격리(quarantine):** (a) 실측 승률이 레이팅 기대 승률과 지속적으로 ±25%p 이상 괴리, (b) 레이팅이 보정 중 600점 이상 이동, (c) "문제가 모호함" 신고 누적 — 셋 중 하나면 rated 풀에서 자동 제외하고 저자 리뷰 큐로 보낸다. 코드 퍼즐 특유의 위험(의도치 않은 복수 정답, 환경 의존)을 거르는 안전망이다.

### 2.3 테마별 서브 레이팅

체스 대시보드의 테마별 성적에 대응. **글로벌 레이팅만이 퍼즐 레이팅과 점수를 주고받는 유일한 rated 게임**이고, 테마 서브 레이팅은 같은 시도 결과를 입력으로 테마별 Glicko-2를 *병렬로* 굴린 파생값이다 (퍼즐 레이팅에는 비반영 — 태그가 3개인 퍼즐이 3배로 점수를 뺏기는 더블카운팅 방지).

- 시도한 퍼즐의 주/부 테마 각각에 대해 유저의 해당 서브 레이팅 vs 퍼즐 글로벌 레이팅으로 업데이트.
- 용도: (1) 테마 트레이닝의 난이도 매칭 기준, (2) 강약점 대시보드, (3) 믹스드 큐에서 약한 테마 가중 출제.
- 시도 수 10회 미만인 테마는 "측정 중"으로 표시하고 대시보드 순위에서 제외 (RD가 높아 노이즈).

### 2.4 난이도 밴드

lichess의 5밴드를 채택하되 오프셋은 유저의 해당 모드 기준 레이팅(믹스드=글로벌, 테마=서브)에 상대적이다: 가장 쉬움 −400, 쉬움 −200, 보통 ±150, 어려움 +200, 가장 어려움 +400~+600. 기본값 "보통"이 desirable difficulty (현재 실력 바로 위)를 구현한다.

### 2.5 솔로 개발자를 위한 단계적 배포

- **v1 (정적 사이트만):** 퍼즐 레이팅은 시드 추정값으로 고정. 유저 레이팅·시도 로그는 localStorage에서 클라이언트 사이드 Glicko-2로 즉시 갱신. 시도 로그는 익명 이벤트로 수집만.
- **v2 (Wisp/Mist 백엔드 추가):** 계정·동기화 + **퍼즐 레이팅 배치 갱신** — Glicko-2는 원래 rating period 기반이므로, 수집된 시도를 일 단위 배치로 돌려 퍼즐 레이팅을 갱신하는 것이 알고리즘적으로도 자연스럽다. 유저 레이팅은 계속 시도 즉시 갱신(단일 게임 근사).

---

## 3. 모드 설계

### 3.1 (a) 테마 트레이닝

특정 개념/트리키 파트 집중 (blocked practice). 테마 1개 선택 → 해당 테마 서브 레이팅 ± 밴드에서 출제. **rated** (첫 시도 한정, 글로벌과 서브 레이팅 모두 갱신). 진입점이 둘이다: (1) 테마 브라우저에서 직접 선택, (2) 레슨 완료 화면과 대시보드 약점 카드의 "이 테마 드릴하기" 버튼. 같은 퍼즐의 재출제는 14일 쿨다운.

### 3.2 (b) 믹스드 퍼즐 (healthy mix)

기본 rated 모드. 글로벌 레이팅 ± 밴드에서 출제하되 **interleaving 규칙**을 적용한다:

- 같은 주 테마 연속 2회 금지, 같은 타입 연속 3회 금지.
- 최근 30일 내 실패율이 높은 테마에 출제 가중 +30% (단, 직전 실패 테마를 즉시 재출제하지는 않음 — 그건 복습 큐의 일).
- 신규 퍼즐 placement boost 적용 (§2.2).
- 풀이 직후: 결과, 레이팅 변동(±n), 해설 토글, "다음 퍼즐" — lichess 퍼즐 루프 그대로.

### 3.3 (c) Code Rush (Puzzle Rush 대응)

시간제한 + 난이도 상승 + 3목숨.

- **포맷:** 3분 / 5분 / 서바이벌(무제한, 정확도 승부) — chess.com Rush의 3포맷.
- **3 strikes:** 오답 3회 누적 시 즉시 종료 (서바이벌 포함 전 포맷 공통).
- **출제 풀:** 마이크로 타입만 — T1 선택지형, T3 한 줄 홀, T6 4~6줄, T7 1단계(줄 지목), T8. 시작 난이도 `max(600, 유저 레이팅 − 600)`, 정답마다 +40~60씩 상승 (Storm식 점진 램프).
- **콤보 시간 보너스 (Storm 차용):** 연속 정답 5/12/20/30회에 +3s/+5s/+7s/+10s, 이후 10회마다 +10s. 오답은 콤보 리셋 + 10초 차감 + 목숨 1 차감.
- **unrated.** 점수 = 정답 수. 개인 최고 기록 + 일간/주간 리더보드(§6).
- **기술 요건:** watchdog 3초 (초과 즉시 오답 처리), 백그라운드에 **예열된 예비 worker** 1개 상시 유지 — terminate 후 respawn하면 WASM 초기화 + stdlib `write_module` 비용을 다시 내야 하므로, kill 시 예비 worker로 즉시 스왑하고 새 예비를 백그라운드 초기화한다. Rush 시작 전 풀의 퍼즐 30개를 프리페치.

### 3.4 (d) Streak (Puzzle Streak 대응)

- 시계 없음. 난이도 600부터 **오름차순 고정 램프** (정답마다 +30~50).
- **한 번이라도 틀리면 종료.** 힌트 사용 불가. **스킵 정확히 1회** 허용 (lichess와 동일).
- unrated, 출제 풀은 전 타입 (시간압박이 없으므로 T5도 포함하되 짧은 것만). 개인 최장 기록 추적.

### 3.5 (e) 데일리 퍼즐

- 전 유저 동일한 퍼즐 1개/일 (정적 사이트에서도 날짜 해시로 결정 가능). 난이도 1500~1800 고정대.
- unrated. 풀든 못 풀든 다음 날 00:00에 전체 해설 공개. 데일리 퍼즐 해결이 데일리 스트릭(§6)의 가장 쉬운 충족 조건.
- 콘텐츠는 큐레이션 — "오늘의 트리키 파트"로 spot-the-bug나 predict 타입 위주 (해설 읽는 재미가 있는 타입).

### 3.6 (f) 복습 큐 (spaced repetition)

Chessable MoveTrainer + Execute Program의 합성. **카드 단위는 퍼즐 인스턴스가 아니라 "스킬 아이템"** — (테마, 타입) 쌍에 묶인 퍼즐 패밀리.

**큐에 들어가는 것:**
1. **실패 퍼즐** — rated/테마 모드에서 틀린 퍼즐 (lichess "replay failed puzzles"의 SRS화).
2. **개념 카드** — 레슨 세션 완료 시 해당 개념의 드릴 카드 자동 생성 (Execute Program: 레슨은 읽기만으로 끝나지 않고 리뷰로 유지되어야 함. 레슨 시스템 쪽 언락 조건 "선행 레슨을 읽고 + 최근 리뷰 성공"과 이 큐가 맞물린다).

**스케줄 (Chessable 8레벨, 검증된 공식 간격):**

```
L1=4시간, L2=1일, L3=3일, L4=1주, L5=2주, L6=1개월, L7=3개월, L8=6개월
```

- 성공 → 레벨 +1. **실패 → L1 리셋** (Chessable 규칙). 단, Execute Program의 관용 규칙을 결합: **세션 내 재시도는 무벌점** — 같은 리뷰 세션에서 다시 풀어 맞히면 리셋하지 않고 레벨 유지(+0). 명시적 "정답 보기(give up)"만 L1 리셋.
- **졸업:** 간격을 둔 성공 4회 연속이면 카드 은퇴 (EP의 retire-after-4th-success, 약 2개월 시점). 은퇴 카드는 6개월 후 1회 확인 리뷰.
- **일일 상한:** 신규 카드 10개/일, 리뷰 50개/일 상한 (EP의 binge 방지 캡). 예상 일일 부담 ~10분.
- **정답 암기 방지 — 변형 회전:** 카드를 리뷰할 때 동일 퍼즐을 다시 내지 않고 같은 (테마, 타입) 패밀리의 **파라미터화 변형**(식별자/리터럴/자료형만 다른 near-neighbor)을 낸다. 생성 파이프라인(§2.2)이 패밀리당 변형 3~5개를 미리 만든다. 답을 외우는 게 아니라 스킬을 인출하게 강제하는, 코드 도메인이 체스보다 유리한 지점이다.
- **Learn vs Review (Chessable 구분):** 카드 최초 진입(레슨 직후)은 Learn 모드 — 모범 답안을 먼저 보여주고 재구성을 요구. 이후 리뷰는 Review 모드 — 아무것도 보여주지 않는 순수 recall.
- **FSRS 마이그레이션 경로:** SM-2 계열 8레벨은 v1 출시용 (구현 = 간격 테이블 1개). 시도 로그에 (경과 시간, 성공 여부, 풀이 시간)을 처음부터 기록해 두면, 후일 FSRS(분석상 SM-2 대비 리텐션 효율 20~30% 우위 주장)로 파라미터 적합 후 교체할 수 있다. 스케줄러를 `fn(card_history) -> next_due` 인터페이스 뒤에 격리해 둔다.

---

## 4. 힌트/피드백 설계

### 4.1 3단계 힌트

| 단계 | 내용 | 출처 | 레이팅 영향 |
|------|------|------|------------|
| H1 개념 환기 | 주 테마 태그 공개 + 1줄 개념 리마인더 ("fold의 콜백은 `fn(acc, item)` 순서다") + T3는 컴파일러가 추론한 홀 타입 (`todo` 경고의 `Hint: I think its type is ...`를 파싱 — §1.4에서 검증) | 저자 작성 + 컴파일러 경고 | 이후 시도 unrated |
| H2 위치 지목 | 문제 줄/스팬 하이라이트 (T2는 에러 스팬, T7은 버그 스팬, T6는 "첫 k줄은 확정" 공개) | 저자 메타데이터 + 에러 파싱 | unrated 유지 |
| H3 정답 + 해설 | 모범 답안 표시 → 카드가 있으면 SRS L1로, 없으면 실패 퍼즐 카드 생성. "정답 보고 재구성" (Chessable Learn 모드의 실패 처리) | 저자 작성 | 실패로 기록 |

### 4.2 컴파일러 에러 번역 레이어

WASM API는 pretty-printed 평문만 반환하므로 (구조화 diagnostics 미노출), 2단 표시를 한다:

1. **원문 보존:** 컴파일러 출력을 monospace로 그대로 표시. 에러 메시지 독해 자체가 커리큘럼이다 — 가리면 안 된다.
2. **학습자 언어 주석:** 에러 텍스트를 정규식으로 분류 — 첫 줄 `error: <제목>` 으로 카테고리 판별(`Type mismatch`, `Inexhaustive patterns`, `Unknown variable`, `Unknown module` 등 유한 집합), `┌─ /src/main.gleam:L:C` 패턴으로 위치 추출(tour도 같은 정규식 하이라이트를 씀) — 한 후, 카테고리 × 퍼즐 테마별 한국어 설명 사전을 매칭한다. 예: `Type mismatch` + 테마 `string-vs-int-concat` → "Gleam은 Int를 자동으로 String으로 바꿔주지 않아요. `int.to_string`으로 명시적으로 변환해야 합니다 — 이게 타입 추론 언어의 약속입니다."
3. 에디터에는 추출한 L:C로 인라인 마커 표시 (CodeMirror 6 + `@exercism/codemirror-lang-gleam`).
4. **로드맵:** compiler-wasm 포크(단일 lib.rs)에 `read_diagnostics(project_id) -> JsValue` (gleam_core의 `Vec<Diagnostic>` — 스팬/라벨/힌트 — JSON 직렬화) 추가 시 정규식 파싱을 대체하고 정밀 squiggle을 얻는다. v1은 무포크 정규식으로 출시.

### 4.3 오답 피드백과 풀이 후 해설

- **per-distractor 코멘트 (T1/T8):** 선택지마다 "왜 그렇게 생각했는지"를 짚는 코멘트 — chess.com 레슨의 "right or wrong, focused commentary".
- **테스트 실패 시 (T3/T4/T5):** `assert` 실패 객체에서 추출한 기대값/실제값을 표시 — "`keep_oks([Ok(1), Error(\"x\"), Ok(3)])`가 `[1]`을 반환했어요. 기대값은 `[1, 3]` — `Error`를 만난 뒤 재귀를 멈추고 있지 않나요?" (실제값은 §5.2의 구조화 에러에서 자동 추출, 진단 문장은 저자가 흔한 오답 패턴별로 작성).
- **near-neighbor 제안 (Brilliant):** 같은 카드 패밀리의 한 단계 쉬운 변형을 "비슷한 문제로 다시 해보기"로 제안.
- **풀이 후 해설:** 모범 답안 1~3개(재귀/fold/stdlib 버전), 왜 이게 idiom인지, 관련 레슨 딥링크, 전체 유저 정답률·흔한 오답 top 3 (v2, 로그 수집 후).

---

## 5. 채점 방식 (전부 브라우저 내)

### 5.1 실행 파이프라인

language-tour 패턴 + 채점 하니스. Web Worker 안에서:

```
reset_filesystem(pid)
→ write_module(pid, "main", 사용자_코드_또는_치환된_템플릿)
→ write_module(pid, "puzzle_test", 히든_테스트_모듈)        // 같은 WASM 프로젝트에 다중 모듈
→ stdlib 모듈들 write_module (세션 시작 시 1회, worker 재사용)
→ compile_package(pid, "javascript")                        // Err(String)이면 컴파일 단계 판정
→ read_compiled_javascript → import 재작성(precompiled/) → base64 data-URL dynamic import
→ JS 쪽에서 테스트 함수 개별 호출 (아래)
```

- **watchdog:** 일반 모드 5초 / Rush 3초. 초과 시 `worker.terminate()` 후 예열된 예비 worker로 스왑 (§3.3). 시간 초과 = 오답 + "무한 루프 또는 종료하지 않는 재귀예요 — base case를 확인하세요" 피드백.
- **결정성 규칙:** 퍼즐 코드와 테스트에 시간/난수/네트워크 사용 금지 (저작 린트로 강제). 같은 입력 = 같은 판정 보장.
- 보안 메모: Worker는 응답성 경계지 보안 샌드박스가 아니다. v1은 자기 코드만 실행하므로 tour와 같은 수용 범위; 유저 제작 퍼즐 공유 기능을 열 때 sandboxed iframe + CSP를 도입한다.

### 5.2 per-test 결과 추출 (검증된 메커니즘)

Gleam에는 예외가 없어 Gleam 쪽에서 assert 실패를 잡을 수 없다. 대신 **히든 테스트 모듈이 테스트를 개별 `pub fn`으로 export**하고, worker의 JS가 각각을 try/catch로 호출한다:

```gleam
// 히든 모듈 puzzle_test.gleam (사용자에게 비공개)
import main

pub fn test_basic() {
  assert main.keep_oks([Ok(1), Error("x"), Ok(3)]) == [1, 3]
}

pub fn test_empty() {
  assert main.keep_oks([]) == []
}
```

검증된 사실: JS 타깃에서 `assert` 실패는 JS `Error`를 throw하며, 그 객체에 구조화 필드가 붙어 있다 —
`{ message: "Assertion failed.", gleam_error: "assert", module, fn, line, kind: "binary_operator", left: {kind, value, start, end}, right: {kind, value, ...} }`.
즉 `left.value`(실제값)와 `right.value`(기대값), 소스 스팬까지 **포크 없이** 얻는다. worker는 export된 `test_*`를 순회 호출하고 catch한 객체에서 per-test 결과를 만든다.

내부 결과 스키마는 **Exercism results.json v2 호환** (`status: pass|fail|error`, 테스트별 `name/status/message/output` — output 500자 캡)으로 고정한다. 후일 Erlang 타깃 콘텐츠용 서버 러너(Docker)를 붙여도 채점 계약이 동일하게 유지된다. (단, AGPL인 gleam-test-runner 코드는 vendor하지 않고 스키마만 차용.)

### 5.3 타입별 판정 매트릭스

| 타입 | 컴파일 | 실행/테스트 | 정적 비교 | 판정 규칙 |
|------|--------|------------|----------|----------|
| T1 predict | 불필요 (저작 시 1회 실행해 정답 고정) | — | 선택지 id 또는 정규화 텍스트(공백/개행 정규화) 비교 | 일치 = 정답 |
| T2 fix-error | 필수 | 히든 테스트 전부 pass | — | 컴파일 실패 = 오답(에러 번역 표시), 테스트 실패 = 오답 |
| T3 fill-hole | 홀 치환 후 필수 | 히든 테스트 | 입력 가드(§5.4) | 가드 통과 ∧ 컴파일 ∧ 테스트 |
| T4 refactor | 필수 | 히든 테스트 (동작 보존) | 구조 린트: 토큰/패턴 요구·금지 목록 (`|>` ≥ 3 등) | 셋 다 통과 |
| T5 write-fn | 필수 | 히든 테스트 per-test | — | 전 테스트 pass; 부분 pass는 per-test 피드백만 |
| T6 Parsons | 조립 소스 필수 | 히든 테스트 | — | 컴파일 ∧ 테스트면 어떤 순서든 정답 |
| T7 spot-bug | 1단계 불필요 / 2단계 필수 | 2단계 히든 테스트 | 1단계: 클릭 스팬 ⊆ 저자 버그 스팬 | 두 단계 모두 통과 |
| T8 MCQ | 불필요 | — | 선택지 id | 일치 = 정답 |

### 5.4 입력 가드 (T3)

홀 입력은 채점 전 정적 검사: (1) `import`/`pub`/`fn `(이름 있는 함수 정의) 토큰 금지 — 익명 `fn(...)`은 허용, (2) 길이 상한 120자, (3) 치환 후 모듈이 홀 바깥과 diff 없음을 확인(템플릿 무결성). 우회 방지가 아니라 (자기 브라우저에서 자기를 속일 뿐) 퍼즐의 원자성 유지가 목적이다.

---

## 6. 진행/동기 시스템

- **레이팅 그래프:** 글로벌 퍼즐 레이팅 시계열 (rated 시도만). 모드별 오염 없음 — rated 모드가 믹스드/테마 둘뿐이므로 그래프 의미가 깨끗하다.
- **테마 강약점 대시보드 (lichess Puzzle Dashboard 대응):** 90일 윈도우. 테마별 서브 레이팅, 시도 수, 정답률, 글로벌 대비 Δ로 강점/약점 정렬. 약점 카드마다 [이 테마 드릴하기]와 [틀린 퍼즐 다시 풀기] (테마별 그룹핑된 실패 퍼즐 리플레이) 버튼. 시도 10회 미만 테마는 "측정 중".
- **데일리 스트릭:** "오늘의 활동" = 데일리 퍼즐 1개 또는 복습 큐 소진 또는 rated 5문제 중 하나. 잃기 어렵고 SRS 복귀를 유도하는 설계 (스트릭의 진짜 목적은 리뷰 이탈 방지).
- **개인 기록:** Rush 최고점(포맷별), Streak 최장, 콤보 최장.
- **리더보드:** unrated 모드(Rush 일간/주간)에만, opt-in. rated 루프와 격리 — Storm이 unrated인 이유와 동일하게, 레이팅을 지키려는 회피 행동을 막는다.
- **뱃지 최소화:** 마일스톤형만 (첫 rated 100문제, 테마 서브 레이팅 1800 도달, 카드 50개 졸업, 데일리 30일). 알림성 보상·XP·레벨 시스템은 두지 않는다. 핵심 동기 장치는 뱃지가 아니라 **레이팅 곡선과 약점이 강점으로 바뀌는 대시보드**다.

---

## 7. 데이터 모델 스케치 (Gleam)

플랫폼 자체가 Lustre(MVU)로 작성되므로 도메인 모델도 Gleam 타입으로 정의한다:

```gleam
pub type PuzzleType {
  PredictOutput(choices: List(Choice), answer_id: Int)
  FixCompileError(broken: String, hidden_tests: String)
  FillHole(template: String, hidden_tests: String, hole_hint_type: String)
  RefactorToIdiom(source: String, hidden_tests: String, lint: StructureLint)
  WriteFunction(stub: String, public_tests: String, hidden_tests: String)
  Parsons(lines: List(String), distractors: List(String), hidden_tests: String)
  SpotTheBug(source: String, bug_span: Span, hidden_tests: String)
  MicroMcq(prompt: String, choices: List(Choice), answer_id: Int)
}

pub type Puzzle {
  Puzzle(
    id: String,
    puzzle_type: PuzzleType,
    primary_theme: String,        // Exercism concept slug 또는 tricky-part 태그
    themes: List(String),
    rating: Float,                // Glicko-2
    rating_deviation: Float,
    family_id: String,            // SRS 변형 회전용 패밀리 키
    hints: #(String, Span, String),  // H1 개념 환기, H2 스팬, H3 해설
    solutions: List(String),
  )
}

pub type Attempt {
  Attempt(
    puzzle_id: String,
    rated: Bool,                  // 첫 무힌트 시도만 True
    outcome: Outcome,             // Pass | Fail | Timeout | GaveUp
    hints_used: Int,
    elapsed_ms: Int,              // 레이팅 비반영, FSRS/대시보드용
    compile_error_category: option.Option(String),
  )
}

pub type SrsCard {
  SrsCard(
    family_id: String,
    level: Int,                   // 1..8 -> 4h/1d/3d/1w/2w/1mo/3mo/6mo
    due_at: Int,
    consecutive_successes: Int,   // 4회면 졸업
    last_variant_served: String,  // 변형 회전
  )
}
```

저장: v1 — 퍼즐 번들은 빌드 시 생성되는 정적 JSON(+사전 컴파일 검증), 유저 상태는 localStorage. v2 — Wisp/Mist 백엔드로 계정/동기화/퍼즐 레이팅 배치 갱신/리더보드.

---

## 8. 구현 순서 (솔로 개발자 로드맵)

1. **퍼즐 러너:** WASM 컴파일 worker + watchdog/예비 worker + 채점 하니스(§5) + 타입 T1/T2/T3 + 에러 번역 v0 (카테고리 사전 20개). 퍼즐 시드 ~100개 (테마 10개 × 10).
2. **레이팅:** 클라이언트 Glicko-2 + 난이도 밴드 + 믹스드/테마 모드. 시드 레이팅은 티어 매핑.
3. **Rush + Streak:** 러너 + 타이머 + 램프. 신규 코드 최소 (퍼즐 풀과 채점 재사용).
4. **복습 큐:** 8레벨 간격 테이블 + 변형 패밀리. 레슨 시스템과 카드 생성 연동.
5. **대시보드 + 데일리:** 시도 로그 집계. 이후 백엔드(v2), compiler-wasm 포크(구조화 diagnostics), FSRS 교체 순으로 고도화.

**핵심 리스크와 완화:** 초기 유저 풀이 작아 퍼즐 레이팅 수렴이 느림 → 시드 추정 + 높은 초기 RD + 격리 규칙(§2.2). 코드 퍼즐의 복수 정답 문제 → 제약된 타입 설계(홀/선택지/순서) + 테스트 동치성 + 모호함 신고. `@exercism/codemirror-lang-gleam`이 2023년판이라 `assert`/`echo` 등 신규 키워드 하이라이트 누락 → 포크 패치. OTP/actor 테마는 JS 타깃에서 실행 불가 → 트레이닝 풀에서는 읽기 전용 타입(T1 predict 불가, T8 MCQ/T6 Parsons만)으로 한정하고 실행형 퍼즐은 만들지 않는다.