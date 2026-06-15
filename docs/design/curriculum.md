# Gleam FP 학습 플랫폼 — 커리큘럼(학습 세션) 설계 문서

> 범위: **학습 세션(레슨) 커리큘럼 전체**. 트레이닝 세션(레이팅 퍼즐/타임드 드릴/SRS)은 별도 문서가 다루며, 본 문서는 그 시스템이 소비할 **태그·트리키 파트·아이템 출처**까지만 정의한다.
>
> 검증 노트: 본 문서의 모든 Gleam 예제 코드와 컴파일러 에러 메시지는 **Gleam 1.16.0 + gleam_stdlib 1.0.3**에서 실제 컴파일/실행 검증되었다. 플랫폼은 브라우저 WASM 아티팩트(`gleam-vX.Y.Z-browser.tar.gz`) 기준 **v1.17.0을 핀**하고, 커리큘럼 릴리스 단위로만 컴파일러를 올린다(연습 문제의 기대 에러 메시지가 버전에 민감하므로 — language-tour가 v1.15.2를 핀하는 것과 같은 이유).

---

## 0. 설계 원칙 (체스 플랫폼 → FP 학습 매핑)

| 체스 플랫폼 메커니즘 | 본 커리큘럼의 대응 |
|---|---|
| chess.com 레슨: 짧은 개념 영상 → 5~10개 보드 챌린지, 모든 수에 즉각 코멘터리 | 짧은 텍스트/애니메이션 세그먼트 → 5~10개 인터랙티브 마이크로 연습, 정답·오답 모두 즉각 피드백 |
| 4단계 스킬 레벨(New to Chess→Advanced) > 코스 > 레슨, 순차 잠금 해제 + 건너뛰기 확인 프롬프트 | **레벨(4) > 유닛(15) > 레슨(~70)**, 유닛 첫 레슨만 열림, 나머지 순차 해제, 건너뛰기 시 확인 프롬프트 |
| Lichess Learn 스테이지별 별점(수 효율) | 레슨별 별점: 힌트 0회 + 첫 시도 정답률 기반 (★~★★★) |
| Lichess Practice의 카테고리 진행률 % | 레벨별 진행률 % 표시 |
| Chessable Learn 모드(보여주고 → 재현시키기) | 레슨 마지막 "재구성 연습": 방금 본 핵심 코드를 빈 에디터에 다시 작성 |
| 퍼즐 테마 태그(fork, pin, …) | 모든 마이크로 연습·레슨이 **개념 태그**를 방출 → 트레이닝 세션의 퍼즐 테마가 됨 |
| Execute Program: 선수 레슨을 읽고 + 리뷰 통과해야 다음 잠금 해제, 재시도 무벌점 | 다음 **레벨** 해제 조건에 SRS 1회차 리뷰 통과 포함, 재시도 무제한 무벌점, '정답 보기'만 SRS 인터벌 축소 |
| Brilliant: 오답 시 near-neighbor 변형 문제 | 오답 2회 시 같은 개념의 더 쉬운 변형 문제 자동 삽입 |

기술 전제 (research digest 기준, 본 문서 전체에 적용):

- 모든 연습은 **브라우저 내 WASM 컴파일 + JS 타깃 실행**(language-tour 아키텍처: Web Worker, `write_module`, base64 data-URL dynamic import, `console.log` 몽키패치). 채점은 사용자 모듈 옆에 **숨김 테스트 모듈**을 같은 WASM 프로젝트에 `write_module`로 써넣고 `main()`을 호출, `assert`/`let assert`의 풍부한 실패 메시지를 출력 캡처로 회수.
- 무한 루프 대비 **watchdog(worker.terminate + respawn)** 필수 — 특히 재귀 유닛(U5, U6)에서 학습자가 종료 조건을 빠뜨리는 것이 *정상적인 학습 경로*이므로, "시간 초과: 재귀가 끝나지 않는 것 같아요. 종료 조건(빈 리스트 케이스)을 확인하세요" 같은 교육적 타임아웃 메시지로 변환한다.
- **OTP/actor 콘텐츠는 브라우저에서 실행 불가**(Erlang 타깃 전용). U15에서 읽기 전용(read-only, 정적 하이라이팅) 콘텐츠로만 다룬다.
- 개념 분류 체계(taxonomy)는 Exercism Gleam 트랙의 36개 concept slug를 시드로 하되, 본 플랫폼의 트리키 파트 태그를 추가 확장한다. (Exercism 콘텐츠 자체의 재사용은 라이선스 확인 전 금지, gleam-test-runner는 AGPL-3.0이므로 코드 벤더링 금지.)

---

## 1. 3단계 구조: 레벨 → 유닛 → 레슨

### 1.1 구조 규칙

- **레슨**: 5~10분. 3~5개 설명 세그먼트와 5~10개 마이크로 연습의 교차(§2). 완료 = 모든 마이크로 연습 통과(재시도 무제한).
- **유닛**: 3~6개 레슨 + **체크포인트 드릴** 1개. 체크포인트 = 해당 유닛 태그의 혼합 10문항(시간 제한 없음), 8문항 이상 정답 시 통과. 실패 시 약한 태그의 레슨 세그먼트로 역링크.
- **유닛 완료 조건** = 모든 레슨 완료 ∧ 체크포인트 통과.
- **잠금 해제**: 유닛 내 레슨은 순차 해제(첫 레슨만 열림). 유닛 간에는 선수 유닛 완료 시 해제. 건너뛰기는 확인 프롬프트("이 유닛은 X, Y 개념을 전제합니다. 그래도 진행할까요?") 후 허용 — chess.com 방식.
- **레벨 해제**: 이전 레벨의 전 유닛 완료 ∧ 그 레벨에서 SRS 큐에 들어간 아이템의 1회차 리뷰(4h~1d 인터벌) 통과 — Execute Program 방식. 신규 레슨은 하루 N개(기본 5)로 캡, 폭식 학습 방지.
- 레슨 완료 시: (a) 레슨의 핵심 아이템 2~4개가 SRS 큐에 등록, (b) 레슨 태그가 사용자 프로필에 "학습됨" 마킹 → 트레이닝 세션이 해당 테마 퍼즐을 서빙하기 시작.

### 1.2 레벨 개요 (체스 대응)

| 레벨 | 이름 | 체스 대응 | 유닛 | 목표 |
|---|---|---|---|---|
| L1 | 입문 — 값과 함수 | New to Chess (기물 움직임) | U1–U3 | 표현식 중심 사고, 불변성, 파이프, case. "기물이 어떻게 움직이는가" |
| L2 | 초급 — 데이터의 모양 | Beginner (기본 전술) | U4–U7 | 커스텀 타입, 리스트, 재귀, 고차 함수. 루프 없는 세계에서 살아남기 |
| L3 | 중급 — 함수형 도구상자 | Intermediate (전술 조합) | U8–U11 | list 모듈, Result/Option, use, 제네릭. "직접 재귀 → 추상화된 도구" |
| L4 | 고급 — 타입으로 설계하기 | Advanced (전략/플랜) | U12–U15 | opaque type, 의도적 크래시, Gleam의 의도적 결핍, 캡스톤 |

### 1.3 유닛 전체 표

| # | 유닛 | 핵심 개념 | 선수 유닛 | 레슨 수 | 완료 조건(공통 규칙 외 특이사항) |
|---|---|---|---|---|---|
| U1 | 값, 불변성, 표현식 | Int/Float/String/Bool, let, immutability, shadowing, block, expressions-everywhere, `echo`/`io.println` | 없음 | 5 | — |
| U2 | 함수와 파이프 | 함수 정의, 타입 표기, `|>`, 파이프 우선 스타일 | U1 | 4 | — |
| U3 | case와 분기 — 사고 전환 I | case 표현식, guard, `_`, 리터럴 패턴, **no early return** | U2 | 4 | 체크포인트에 "명령형 → 표현식 변환" 문항 필수 포함 |
| U4 | 커스텀 타입과 레코드 | variants, records, labelled fields, record update, 타입 패턴 매칭, **exhaustiveness** | U3 | 5 | 체크포인트에 "빠진 케이스 찾기" 문항 2개 이상 |
| U5 | 리스트와 재귀 | `List(a)`, `[x, ..rest]` 패턴, 구조적 재귀, **종료 조건**, prepend O(1) | U4 | 5 | — |
| U6 | 꼬리 재귀와 누산기 | TCO, accumulator 패턴, public wrapper + private loop, accumulate-then-reverse | U5 | 4 | — |
| U7 | 함수를 값으로 | 익명 함수 `fn(){}`, 고차 함수, 함수 캡처 `f(_, x)`, labelled arguments + shorthand | U5 | 4 | U6과 병렬 수강 가능(선수는 U5만) |
| U8 | list 모듈 — 재귀의 추상화 | `list.map/filter/fold/fold_right`, **fold 방향과 누산기**, 도구 선택 | U6, U7 | 5 | 체크포인트에 "어떤 도구?(map/filter/fold)" 분류 문항 |
| U9 | Option과 Result | `Nil`, `Option(a)`, `Result(a, e)`, 커스텀 에러 타입, case 기반 핸들링, Option vs Result 선택 | U4 | 5 | U8과 병렬 가능(선수는 U4) |
| U10 | Result 체이닝과 use | `result.map/try`, 중첩 case 계단 문제, `use` 표현식(디슈가링 포함), railway-oriented 사고 | U8, U9 | 4 | 체크포인트에 case 계단 → use 리팩터링 문항 필수 |
| U11 | 제네릭과 타입 설계 기초 | type variables, 제네릭 커스텀 타입, type alias, tuple vs custom type, Dict/Set 개요 | U8, U9 | 4 | — |
| U12 | Opaque Type과 API 설계 | opaque types, smart constructor, make-invalid-states-unrepresentable, phantom types(맛보기) | U10, U11 | 4 | — |
| U13 | 의도적 크래시 | `todo`, `panic`, `let assert`, `assert`, "언제 크래시가 옳은가" | U9 | 3 | — |
| U14 | Gleam에 없는 것들 — 사고 전환 II | no type classes / no currying(캡처로 대체) / no laziness(eager) / no macros / no exceptions / no mutation — 공식 FAQ 근거 | U10, U11 | 4 | 객관식·predict 중심, 코드 작성 최소 |
| U15 | 캡스톤 | 종합 프로젝트형 레슨(파서, 상태 기계), OTP/actor **읽기 전용** 소개, 다음 학습 경로 | U12, U13, U14 | 4 | 캡스톤 과제 1개 제출(숨김 테스트 전부 통과) |

총 ~62 레슨 + 15 체크포인트. 솔로 개발 출시 전략: **L1+L2(31레슨)를 v1으로 출시**하고 L3, L4를 순차 릴리스. 트레이닝 세션은 U3 완료 시점부터 의미 있는 태그 풀이 생기므로 v1에서 함께 열 수 있다.

---

## 2. 레슨 내부 구조 (5~10분)

### 2.1 교차 구조

```
[세그먼트 1: 설명 ≤90초 분량 텍스트/다이어그램]
  → [연습 1] [연습 2]        (세그먼트당 1~3개)
[세그먼트 2: 설명]
  → [연습 3] [연습 4] [연습 5]
[세그먼트 3: 설명]
  → [연습 6] [연습 7]
[마무리: 요약 카드 + 재구성 연습(선택적) + SRS 등록 안내]
```

- 설명 세그먼트는 **항상 실행 가능한 예제 코드**를 포함(정적 하이라이팅은 tree-sitter-gleam, 편집 가능 블록은 CodeMirror 6 + @exercism/codemirror-lang-gleam 포크).
- 연습 5~10개, 개당 30~90초. chess.com의 "보드 챌린지 5~10개"에 대응.
- 레슨당 신규 개념은 **정확히 1개** (Exercism concept exercise 원칙).

### 2.2 마이크로 연습 6종

| 타입 | 설명 | 채점 방식 | 비고 |
|---|---|---|---|
| E1 `predict` | 출력/값 예측 | 객관식 또는 단답 문자열 매칭 | 컴파일 불필요, 가장 저렴. retrieval practice |
| E2 `hole` | 코드 한 곳 빈칸 채우기(`todo` 또는 마킹된 구멍 1개) | 컴파일 + 숨김 테스트 | "한 수만 두면 되는" 퍼즐. 정답 다양성 문제를 구멍 1개로 제약 |
| E3 `fix` | 컴파일 에러/테스트 실패 수정 (Rustlings 모델) | 컴파일 성공 + 숨김 테스트 | Gleam의 친절한 에러 메시지가 자체 힌트 역할 |
| E4 `write` | 작은 함수 처음부터 작성 | 컴파일 + 숨김 테스트(입출력/프로퍼티) | 레슨 후반·체크포인트용. 정답 다양성 허용 |
| E5 `type` | 표현식/함수의 타입 고르기 | 객관식 | 타입 추론 감각 훈련 |
| E6 `spot` | 4개 코드 중 버그/비관용 코드 고르기 | 객관식 | 코드 리딩 훈련, 모바일 친화적 |

### 2.3 피드백 정책 (chess.com "모든 수에 코멘터리")

- **정답 시에도** 한 줄 코멘터리: 왜 이게 관용적인지, 대안은 무엇인지.
- **오답 시**: (1) 컴파일 에러면 컴파일러의 pretty-print 출력을 그대로 보여주고(파일:행:열 + 캐럿 밑줄 포함) 그 아래 플랫폼의 교육적 해설 한 단락을 덧붙임. (2) 오답 패턴별 사전 저작 피드백(저자가 예상 오답 2~4개에 피드백을 매핑). (3) 2회 연속 오답 시 near-neighbor 변형(더 쉬운 같은 개념 문제) 삽입 — Brilliant 방식. (4) 재시도 무벌점, **'정답 보기'만** 해당 아이템의 SRS 인터벌을 축소 — Execute Program 방식.
- 컴파일 에러의 행:열은 pretty-text를 정규식 파싱해 에디터 인라인 표시(v1), 추후 compiler-wasm 포크로 `Vec<Diagnostic>` JSON 노출(v2).

### 2.4 채점 파이프라인 (참고 구현 계약)

```
사용자 코드 → write_module(project, "main", user_code)
숨김 테스트 → write_module(project, "main_test", hidden_test_code)   // assert 기반
compile_package(project, "javascript")
  ├─ Err(pretty_string) → E3가 아니면 오답 처리 + 에러 표시
  └─ Ok → main_test의 main()을 data-URL import로 실행
        ├─ 출력 캡처(console.log 패치)에서 결과 파싱
        ├─ assert 실패 → 풍부한 실패 메시지를 피드백으로 변환
        └─ watchdog 5s 초과 → terminate + "재귀 종료 조건" 교육적 메시지
결과는 Exercism results.json v2 스키마(status, per-test name/status/message)로 내부 표준화
```

---

## 3. 커버 개념 전체 목록 (개념 → 유닛 매핑)

요구된 개념이 모두 포함되며, Exercism slug와 정렬:

| 개념 | 유닛 | Exercism slug 대응 |
|---|---|---|
| immutability (재바인딩 vs 변경) | U1 | basics |
| expressions-everywhere (문장 없음, block 값) | U1 | basics |
| Int/Float 분리 연산자 (`+` vs `+.`) | U1 | ints, floats |
| 함수 정의·타입 표기 | U2 | basics |
| pipe operator `|>` | U2 | pipe-operator |
| pattern matching / case / guard / 대안 패턴 | U3, U4 | case-expressions |
| no early return / no loops / no mutation (사고 전환) | U3, U5, U14 | (플랫폼 고유) |
| custom types / records / labelled fields / record update | U4 | custom-types, labelled-fields |
| exhaustiveness | U4 (U9에서 강화) | case-expressions |
| List와 `[x, ..rest]` | U5 | lists |
| recursion + 종료 조건 | U5 | recursion |
| tail recursion + accumulator | U6 | tail-call-optimisation |
| 익명 함수, higher-order functions | U7 | anonymous-functions |
| 함수 캡처 `f(_, x)` | U7 | (basics 내) |
| labelled arguments + shorthand | U7 | labelled-arguments |
| list 모듈: map / filter / fold (+ fold_right) | U8 | lists |
| Option | U9 | options, nil |
| Result + 커스텀 에러 타입 | U9 | results |
| Result 체이닝 (`result.map/try`) | U10 | results |
| use expressions | U10 | use-expressions |
| generics (type variables, 제네릭 커스텀 타입) | U11 | generics |
| type aliases, Dict, Set | U11 | type-aliases, dicts, sets |
| opaque types + smart constructor | U12 | opaque-types |
| phantom types (맛보기) | U12 | phantom-types |
| todo / panic / let assert / assert | U13 | let-assertions |
| no type classes / no currying / no laziness / no macros / no exceptions (FAQ 기반) | U14 | (플랫폼 고유 차별화) |
| OTP/actor 개요 (읽기 전용) | U15 | external — 브라우저 실행 불가 |

명시적 **scope-out**: type class 흉내, 커링, 모나드 일반론(Result/Option의 구체 패턴으로만), 매크로, OTP 실습(서버 샌드박스 도입 전까지). 각각 U14에서 "왜 Gleam에 없는가" 레슨으로 전환 — Haskell 계열 강의 대비 차별점이자 솔로 개발자의 커리큘럼 표면적 축소 수단.

---

## 4. 유닛별 상세 설계 + 예시 레슨

각 유닛: 레슨 목록 → 예시 레슨 2개(설명 요지 + 실제 연습 + 정답 + 오답 피드백) → 방출 태그.

---

### U1. 값, 불변성, 표현식 (L1)

**레슨**: ① 값과 let ② 한 번 정하면 끝 — 불변성과 shadowing ③ Int와 Float는 남남 ④ 모든 것이 표현식 ⑤ String과 Bool, 그리고 echo

**예시 레슨 U1-② 「한 번 정하면 끝 — 불변성과 shadowing」**

- 세그먼트 1 요지: Gleam에는 변수 "수정"이 없다. `let`은 이름에 값을 붙일 뿐이며, 같은 이름으로 다시 `let` 하면 **새 바인딩이 이전 것을 가린다(shadowing)** — 값이 바뀐 게 아니라 이름이 새 값을 가리킬 뿐. 이전 값을 참조하던 코드는 영향받지 않는다.

- 연습 1 (E1 `predict`): 다음 코드의 출력은?

```gleam
import gleam/int
import gleam/io

pub fn main() -> Nil {
  let x = 1
  let f = fn() { x }
  let x = x + 10
  io.println(int.to_string(x))
  io.println(int.to_string(f()))
}
```

  보기: (a) `11` / `11` (b) `11` / `1` (c) 컴파일 에러 (d) `1` / `1` — **정답 (b)**.
  - 오답 (a) 피드백: "shadowing은 mutation이 아닙니다. `f`는 첫 번째 `x`(= 1)를 캡처했고, 세 번째 줄의 `let x`는 **새로운** 바인딩을 만들 뿐 `f`가 본 값을 바꾸지 못합니다."
  - 오답 (c) 피드백: "같은 이름의 재-`let`은 Gleam에서 합법입니다(shadowing). 금지된 것은 `x = x + 10`처럼 `let` 없는 재대입입니다."

- 세그먼트 2 요지: 그래서 "값을 바꾸고 싶으면" 항상 **새 값을 만들어 새 이름(또는 같은 이름)에 붙인다**. 이것이 이후 record update(U4), accumulator(U6)까지 이어지는 핵심 사고.

- 연습 2 (E3 `fix`): 컴파일되지 않는 아래 코드를 고치세요 (구멍은 `total` 갱신 줄 하나).

```gleam
pub fn add_bonus(score: Int) -> Int {
  let total = score
  total = total + 100   // ← 이 줄을 고치세요
  total
}
```

  **정답**: `let total = total + 100` — 오답(예: `total := …`, `mut total`) 피드백: 컴파일러 에러 전문을 그대로 노출 후 "Gleam에는 재대입 연산자가 없습니다. 새 `let`으로 이전 이름을 가리세요."

**예시 레슨 U1-④ 「모든 것이 표현식」**

- 세그먼트 1 요지: Gleam에는 문장(statement)이 없다. `case`, block `{ … }`, 심지어 조건 분기도 전부 **값을 내는 표현식**이다. 그러므로 "if에서 변수에 대입"이 아니라 "case 표현식의 결과를 let에 바인딩"한다. (검증된 예제)

```gleam
pub fn grade(score: Int) -> String {
  let label = case score {
    s if s >= 90 -> "A"
    s if s >= 80 -> "B"
    _ -> "F"
  }
  label
}
// grade(85) == "B"
```

- 연습 1 (E1 `predict`): `grade(85)`의 값은? — **정답 `"B"`**. 오답 `"A"` 피드백: "guard는 위에서부터 순서대로 검사되고, 첫 번째로 참인 가지가 선택됩니다. `85 >= 90`은 거짓이므로 다음 가지로 내려갑니다."

- 세그먼트 2 요지: Int와 Float는 연산자도 다르다(`+`/`+.`). 컴파일러가 친절하게 알려준다.

- 연습 2 (E3 `fix`): 아래 코드는 컴파일되지 않습니다. 에러 메시지를 읽고 고치세요.

```gleam
pub fn add_half(x: Float) -> Float {
  x + 0.5
}
```

  학습자에게 보여주는 **실제 컴파일러 출력**(검증됨):

```
error: Type mismatch
  ┌─ src/main.gleam:2:5
  │
2 │   x + 0.5
  │     ^ Use +. instead

The + operator can only be used on Ints.
```

  **정답**: `x +. 0.5`. 플랫폼 해설: "Gleam은 암묵적 숫자 변환이 없습니다. Float 연산자는 점이 붙습니다: `+. -. *. /.`"

**방출 태그**: `immutability`, `shadowing`, `expressions-everywhere`, `int-float-ops`, `blocks`

---

### U2. 함수와 파이프 (L1)

**레슨**: ① 함수 정의와 타입 표기 ② 파이프 `|>` — 데이터가 흐르는 방향 ③ 중첩 호출을 파이프로 ④ 파이프 우선 스타일과 한계

**예시 레슨 U2-③ 「중첩 호출을 파이프로」**

- 세그먼트 1 요지: `c(b(a(x)))`는 안쪽부터 읽어야 하지만, `x |> a |> b |> c`는 데이터가 변환되는 순서대로 읽힌다. `|>`는 왼쪽 값을 오른쪽 함수의 **첫 번째 인자**로 넣는다. (검증된 예제)

```gleam
import gleam/string

pub fn shout(name: String) -> String {
  name
  |> string.trim
  |> string.uppercase
  |> string.append("!")
}
// shout("  lucy ") == "LUCY!"
```

- 연습 1 (E2 `hole`): 아래 함수를 파이프 체인으로 완성하세요. 구멍은 한 줄.

```gleam
import gleam/string

// "gleam" -> "G-L-E-A-M" 처럼 대문자화 후 글자 사이에 "-" 삽입… 대신:
// 공백 제거 → 대문자화가 되도록 빈칸을 채우세요.
pub fn normalize(raw: String) -> String {
  raw
  |> string.trim
  |> ???
}
```

  **정답**: `string.uppercase`. 오답 `string.uppercase(raw)` 피드백: "파이프 오른쪽에는 *호출 결과*가 아니라 *함수*(또는 인자가 모자란 호출)가 옵니다. `raw`는 이미 파이프가 넣어줍니다 — 다시 넣으면 인자가 두 개가 됩니다."

- 연습 2 (E1 `predict`): `"  lucy " |> string.trim |> string.uppercase |> string.append("!")`의 값은? 보기 (a) `"LUCY!"` (b) `"!LUCY"` (c) `"  LUCY !"` — **정답 (a)**. 오답 (b) 피드백: "`string.append(a, b)`는 `a` 뒤에 `b`를 붙입니다. 파이프는 왼쪽 값을 **첫 번째** 인자 자리에 넣으므로 `string.append("LUCY", "!")`이 됩니다." (이 한 문제가 U7의 캡처 `string.append(_, "!")` 복선이 된다.)

**예시 레슨 U2-① 「함수 정의와 타입 표기」**

- 세그먼트 요지: `pub fn name(arg: Type) -> ReturnType { body }`. 본문 마지막 표현식이 반환값 — `return` 키워드 자체가 없다(사고 전환 I의 복선).
- 연습 (E5 `type`): `pub fn double(x: Int) -> ??? { x * 2 }`에서 `???`에 올 타입은? 보기 Int/Float/String/Bool — **정답 Int**. 오답 Float 피드백: "`*`는 Int 연산자입니다. Float였다면 `*.`와 `2.0`이 필요합니다."

**방출 태그**: `pipe`, `function-definition`, `type-annotation`

---

### U3. case와 분기 — 사고 전환 I (L1)

**레슨**: ① case 표현식 해부 ② guard와 `_`, 대안 패턴 ③ early return은 없다 ④ 사고 전환 훈련: 명령형 코드 번역하기

**예시 레슨 U3-③ 「early return은 없다」**

- 세그먼트 1 요지: 다른 언어의 `if (invalid) return early;` 패턴은 Gleam에 없다. 함수는 **하나의 표현식**이고, 모든 경로가 값으로 수렴한다. "일찍 나가는" 코드는 case의 **가지 하나**가 된다. 가드 절(early return) 사고를 "분기 트리" 사고로 바꾸는 것이 이 레슨의 전부다.

- 연습 1 (E4 `write`): 다음 의사코드(명령형)를 Gleam으로 번역하세요.

```
// 의사코드:
// if n < 0: return "negative"
// if n == 0: return "zero"
// return "positive"
```

  **모범답** (숨김 테스트는 -5, 0, 7 입력 검증):

```gleam
pub fn sign_label(n: Int) -> String {
  case n {
    _ if n < 0 -> "negative"
    0 -> "zero"
    _ -> "positive"
  }
}
```

  - 오답(case 두 개를 연달아 쓰고 마지막에 도달 불가 코드) 피드백: "case 가지들이 곧 당신의 return들입니다. 모든 '조기 반환'을 한 case의 가지로 모으세요."
- 연습 2 (E6 `spot`): 네 가지 답안 중 비관용적인 것 고르기 — 정답: `Bool`을 또 case로 받아 `True -> True, False -> False` 하는 코드. 피드백: "조건식 자체가 이미 Bool 값입니다."

**예시 레슨 U3-② 「guard와 `_`, 대안 패턴」**

- 세그먼트 요지: 가지 순서가 의미를 가진다(위에서 아래). `_`는 "나머지 전부". `1 | 2 | 3 ->`처럼 대안 패턴으로 가지를 합칠 수 있다.
- 연습 (E1 `predict`): U1-④의 `grade`를 변형해 가지 순서를 뒤집은 코드(`_ -> "F"`가 첫 가지)를 제시 — "출력은?" **정답: 모든 입력에서 `"F"`**. 피드백: "`_`는 모든 값과 매치되므로 첫 가지에 두면 아래 가지는 죽은 코드입니다. (이런 경우 컴파일러가 unreachable 경고를 냅니다 — 경고도 읽는 습관을 들이세요.)"

**방출 태그**: `case-basics`, `guards`, `no-early-return`, `branch-order`

---

### U4. 커스텀 타입과 레코드 (L2)

**레슨**: ① variant로 상태 표현하기 ② record와 labelled fields ③ 타입에 패턴 매칭 + exhaustiveness ④ record update — "수정"의 정체 ⑤ Bool 대신 커스텀 타입

**예시 레슨 U4-③ 「빠짐없이 다루기 — exhaustiveness」**

- 세그먼트 1 요지: case는 커스텀 타입의 **모든 variant**를 다뤄야 컴파일된다. 이것이 FP의 안전망: variant를 추가하면 컴파일러가 고칠 곳을 전부 알려준다. (검증된 예제)

```gleam
pub type Shape {
  Circle(radius: Float)
  Rectangle(width: Float, height: Float)
}

pub fn area(shape: Shape) -> Float {
  case shape {
    Circle(radius: r) -> 3.14159 *. r *. r
    Rectangle(width: w, height: h) -> w *. h
  }
}
```

- 연습 1 (E3 `fix`): `Rectangle` 가지를 지운 버전을 제시. **실제 컴파일러 출력**(검증됨)을 그대로 보여준다:

```
error: Inexhaustive patterns
  ┌─ src/main.gleam:7:3
  │
7 │ ╭   case shape {
8 │ │     Circle(radius: r) -> 3.14159 *. r *. r
9 │ │   }
  │ ╰───^

This case expression does not have a pattern for all possible values.
The missing patterns are:

    Rectangle(width:, height:)
```

  **정답**: `Rectangle(width: w, height: h) -> w *. h` 가지 추가. 오답(`_ -> 0.0` 추가) 피드백: "컴파일은 되지만 함정입니다. `_`는 exhaustiveness 검사를 꺼버려서, 나중에 `Triangle`을 추가해도 컴파일러가 침묵합니다. variant를 명시하세요. — 이 함정은 트레이닝 세션 `exhaustiveness` 테마에서 계속 등장합니다."

- 연습 2 (E1 `predict`): `area(Circle(radius: 2.0))`의 값은? **정답 `12.56636`** (검증됨).

**예시 레슨 U4-④ 「record update — '수정'의 정체」**

- 세그먼트 요지: `Player(..p, level: p.level + 1)`은 p를 바꾸지 않는다. **새 레코드**를 만든다(구조 공유로 저렴). U1의 불변성이 데이터 구조로 확장된 것. (검증된 예제)

```gleam
pub type Player {
  Player(name: String, score: Int, level: Int)
}

pub fn level_up(p: Player) -> Player {
  Player(..p, level: p.level + 1)
}
```

- 연습 (E1 `predict`):

```gleam
let p1 = Player(name: "lucy", score: 10, level: 1)
let p2 = level_up(p1)
// p1.level 과 p2.level 은 각각?
```

  **정답: 1과 2**. 오답 "2와 2" 피드백: "record update는 원본을 건드리지 않습니다. `p1`은 영원히 level 1입니다. '바꾼다'가 아니라 '바뀐 복사본을 만든다'로 읽으세요."

**방출 태그**: `custom-types`, `records`, `labelled-fields`, `record-update`, `exhaustiveness`, `pattern-match-types`

---

### U5. 리스트와 재귀 (L2)

**레슨**: ① List(a)와 prepend ② `[first, ..rest]` — 리스트를 분해하는 패턴 ③ 첫 재귀: 길이 세기 ④ 종료 조건 — 재귀의 생명줄 ⑤ 인덱스 없는 세계 (no loops)

**예시 레슨 U5-③ 「첫 재귀: 길이 세기」**

- 세그먼트 1 요지: Gleam에는 for/while이 **없다**. 반복 = "리스트의 머리를 처리하고, 꼬리에 대해 자신을 다시 호출". 모든 재귀는 두 가지 질문: (1) 가장 작은 입력(빈 리스트)이면 답이 뭔가? (2) 머리 하나를 처리했으면 남은 문제는 뭔가?

```gleam
pub fn length(xs: List(Int)) -> Int {
  case xs {
    [] -> 0
    [_, ..rest] -> 1 + length(rest)
  }
}
```

- 연습 1 (E2 `hole`): 리스트 합계 — 구멍은 재귀 가지 하나.

```gleam
pub fn total(xs: List(Int)) -> Int {
  case xs {
    [] -> 0
    [first, ..rest] -> ???
  }
}
```

  **정답**: `first + total(rest)`. 오답 `first + total(xs)` 피드백 + **watchdog 발동**: "시간 초과 — 재귀가 끝나지 않았습니다. `total(xs)`는 *같은* 리스트로 자신을 다시 부릅니다. 문제가 작아지려면 `rest`를 넘겨야 합니다." (watchdog이 worker를 종료·재기동하고 이 메시지로 변환 — §2.4)

- 연습 2 (E1 `predict`): `length([])`는? **정답 0** — "종료 조건이 곧 답의 씨앗입니다."

**예시 레슨 U5-④ 「종료 조건 — 재귀의 생명줄」**

- 세그먼트 요지: 무한 재귀의 3대 원인 — (1) 빈 리스트 케이스 누락, (2) 같은 인자로 재호출, (3) 줄어들지 않는 인자. exhaustiveness 덕분에 (1)은 컴파일러가 잡아준다(`[]` 패턴이 없으면 Inexhaustive 에러) — 컴파일러가 종료 조건을 *강제로 생각하게* 만든다는 점을 명시적으로 가르친다.
- 연습 (E3 `fix`): countdown 함수에서 `n - 1` 대신 `n`을 넘기는 버그 수정. 오답 시 watchdog 메시지 + "재귀 호출의 인자가 매 호출마다 '작아지는지' 확인하는 습관 — 이것이 트레이닝 테마 `termination`입니다."

**방출 태그**: `lists`, `head-tail-pattern`, `recursion`, `termination`, `no-loops`

---

### U6. 꼬리 재귀와 누산기 (L2)

**레슨**: ① 스택이 자라는 재귀, 자라지 않는 재귀 ② accumulator 패턴 ③ wrapper + private loop 관용구 ④ 누산의 부작용: 뒤집힌 결과

**예시 레슨 U6-② 「accumulator 패턴」**

- 세그먼트 1 요지: `1 + total(rest)`는 재귀가 돌아온 *뒤에* 할 일(+1)이 남아 스택에 쌓인다. "지금까지의 답"을 인자(누산기)로 들고 내려가면 재귀 호출이 **마지막 동작**이 되고(tail call), Gleam이 이를 점프로 컴파일해 스택이 자라지 않는다. 관용구: public 함수는 얇은 wrapper, 실제 재귀는 private `_loop`. (검증된 예제)

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

- 연습 1 (E2 `hole`): `[] -> ???` — **정답 `acc`**. 오답 `0` 피드백: "종료 시점의 누산기가 *바로 답*입니다. 0을 반환하면 지금까지 모은 것을 버리는 셈입니다. (비-꼬리 버전에서 `[] -> 0`이었던 것과 헷갈리기 쉬운 지점 — 트레이닝 테마 `accumulator`의 단골 문제입니다.)"
- 연습 2 (E6 `spot`): 네 버전 중 꼬리 재귀가 **아닌** 것 고르기(재귀 결과에 `1 +`를 덧붙이는 버전). 피드백: "재귀 호출 *결과로 무언가를 더 하면* 꼬리 호출이 아닙니다."

**예시 레슨 U6-④ 「누산의 부작용: 뒤집힌 결과」**

- 세그먼트 요지: 리스트를 누산기에 **prepend로 쌓으면 결과가 뒤집힌다** (prepend가 O(1)이라 이렇게 쌓는 게 옳다). 관용구는 "쌓고 마지막에 `list.reverse`" (accumulate-then-reverse). 이것은 버그가 아니라 패턴이다.
- 연습 (E1 `predict`):

```gleam
fn double_loop(xs: List(Int), acc: List(Int)) -> List(Int) {
  case xs {
    [] -> acc
    [first, ..rest] -> double_loop(rest, [first * 2, ..acc])
  }
}
// double_loop([1, 2, 3], []) 의 값은?
```

  **정답 `[6, 4, 2]`**. 오답 `[2, 4, 6]` 피드백: "1이 *먼저* 들어가 가장 *깊이* 깔립니다. prepend 누산은 순서를 뒤집습니다 — 그래서 wrapper에서 `list.reverse(double_loop(xs, []))`로 마무리하는 것이 관용구입니다."

**방출 태그**: `tail-call`, `accumulator`, `acc-reverse`, `wrapper-loop-idiom`

---

### U7. 함수를 값으로 (L2)

**레슨**: ① 익명 함수와 함수 값 ② 고차 함수 — 함수를 받는 함수 ③ 함수 캡처 `f(_, x)` ④ labelled arguments

**예시 레슨 U7-③ 「함수 캡처」**

- 세그먼트 1 요지: Gleam에는 자동 커링이 없다. 대신 **캡처**: `add(10, _)`는 "한 자리만 비워둔 호출"로, `fn(b) { add(10, b) }`의 단축이다. 빈칸 `_`는 정확히 한 개. (검증된 예제)

```gleam
import gleam/list

pub fn add(a: Int, b: Int) -> Int {
  a + b
}

pub fn captures_demo() -> List(Int) {
  list.map([1, 2, 3], add(10, _))
}
// == [11, 12, 13]
```

- 연습 1 (E2 `hole`): `list.map(["a", "b"], string.append(_, "!"))` 꼴 완성 — U2-③의 파이프 복선 회수. 오답 `string.append("!", _)` 피드백: "빈칸의 *위치*가 어느 인자가 비는지를 정합니다. `append(_, \"!\")`는 각 원소 *뒤에* `!`를 붙입니다."
- 연습 2 (E5 `type`): `add(10, _)`의 타입은? 보기 `fn(Int) -> Int` / `Int` / `fn(Int, Int) -> Int` — **정답 `fn(Int) -> Int`**.

**예시 레슨 U7-④ 「labelled arguments」**

- 세그먼트 요지: 인자에 라벨을 붙이면 호출부가 문장처럼 읽히고 순서에서 자유로워진다. (검증된 예제)

```gleam
import gleam/string

pub fn replace(
  in string: String,
  each pattern: String,
  with replacement: String,
) -> String {
  string.replace(string, pattern, replacement)
}

pub fn demo() -> String {
  replace(in: "a,b,c", each: ",", with: " ")
  // == "a b c"
}
```

- 연습 (E1 `predict`): `replace(each: ",", with: " ", in: "a,b,c")`의 값은? — **정답 `"a b c"`** (라벨이 있으면 순서 무관). 오답 피드백: "라벨 호출은 순서가 아니라 이름으로 매칭됩니다."

**방출 태그**: `anonymous-fn`, `hof`, `captures`, `labelled-args`

---

### U8. list 모듈 — 재귀의 추상화 (L3)

**레슨**: ① 당신이 쓴 재귀에는 이름이 있다 (map) ② filter ③ fold — 만능 접기 ④ fold 방향과 누산기 ⑤ 도구 선택: map인가 filter인가 fold인가

**예시 레슨 U8-④ 「fold 방향과 누산기」** *(커리큘럼 전체에서 가장 중요한 트리키 파트 레슨)*

- 세그먼트 1 요지: `list.fold(xs, initial, f)`는 **왼쪽부터** 접는다. 콜백 시그니처는 `fn(acc, item)` — **누산기가 첫 번째**다. U6에서 손으로 쓴 `sum_loop`가 정확히 fold다.

```gleam
import gleam/list

pub fn total(xs: List(Int)) -> Int {
  list.fold(xs, 0, fn(acc, x) { acc + x })
}
```

- 연습 1 (E1 `predict`): (검증된 예제)

```gleam
list.fold([1, 2, 3], [], fn(acc, x) { [x, ..acc] })
```

  **정답 `[3, 2, 1]`** — fold로 prepend하면 reverse가 된다(U6-④와 동일 현상의 재등장 = interleaving). 오답 `[1, 2, 3]` 피드백: "fold는 왼쪽부터: 1이 먼저 acc에 박히고, 그 *위에* 2, 3이 쌓입니다. 순서를 보존하며 리스트를 만들고 싶다면 `list.fold_right` 또는 fold 후 `list.reverse`."
- 연습 2 (E3 `fix`): 콜백 인자 순서를 `fn(x, acc)`로 쓴 버그 코드(문자열 이어붙이기라 결과가 뒤집혀 테스트 실패). **정답**: `fn(acc, x)`로 교정. 피드백: "Gleam stdlib의 fold 콜백은 `fn(acc, item)`입니다. 다른 언어(예: Haskell foldr)와 순서가 다를 수 있어 — 트레이닝 테마 `fold-direction`이 이 반사신경을 훈련합니다."

**예시 레슨 U8-⑤ 「도구 선택」**

- 세그먼트 요지: 길이가 변하면(선별) filter, 각 원소가 1:1 변환되면 map, **타입/모양 자체가 바뀌면**(리스트→숫자 하나) fold. 셋의 조합이 파이프라인. (검증된 예제, 출력 20)

```gleam
import gleam/list

pub fn process(xs: List(Int)) -> Int {
  xs
  |> list.filter(fn(x) { x % 2 == 0 })
  |> list.map(fn(x) { x * x })
  |> list.fold(0, fn(acc, x) { acc + x })
}
// process([1, 2, 3, 4]) == 20
```

- 연습 (E6 `spot` × 3연발): "짝수의 개수를 센다 / 각 단어를 대문자화한다 / 최댓값을 찾는다" 각각에 어울리는 도구 고르기. 오답 피드백은 항상 반환 *타입*으로 환원: "결과가 `List`가 아니라 `Int` 하나라면 map만으로는 끝나지 않습니다."

**방출 태그**: `list-map`, `list-filter`, `fold`, `fold-direction`, `tool-choice`, `pipeline`

---

### U9. Option과 Result (L3)

**레슨**: ① 없을 수도 있는 값 — Option ② 실패할 수 있는 연산 — Result ③ 나만의 에러 타입 ④ Option vs Result 선택 기준 ⑤ stdlib의 Result들 (`int.parse`, `list.first`…)

**예시 레슨 U9-② 「실패할 수 있는 연산 — Result」**

- 세그먼트 1 요지: Gleam에는 예외가 **없다**. 실패 가능성은 반환 타입 `Result(성공, 실패)`에 적히고, 호출자는 case로 **두 경우 모두** 다루도록 컴파일러가 강제한다(exhaustiveness의 재등장). `int.parse`는 `Result(Int, Nil)`을 반환한다. (검증된 예제)

```gleam
import gleam/int

pub type AgeError {
  NotANumber
  Negative
}

pub fn parse_age(input: String) -> Result(Int, AgeError) {
  case int.parse(input) {
    Error(Nil) -> Error(NotANumber)
    Ok(n) ->
      case n < 0 {
        True -> Error(Negative)
        False -> Ok(n)
      }
  }
}
// parse_age("-3") == Error(Negative)
```

- 연습 1 (E1 `predict`): `parse_age("-3")` / `parse_age("abc")` / `parse_age("8")`의 값은? **정답 `Error(Negative)` / `Error(NotANumber)` / `Ok(8)`**. 오답 `-3` 피드백: "Result에서 값은 절대 '맨몸'으로 나오지 않습니다. 성공이어도 `Ok(8)`로 포장되어 있습니다 — 꺼내려면 패턴 매칭."
- 연습 2 (E3 `fix`): `Ok` 가지만 처리한 case(Inexhaustive 에러 — U4-③에서 본 것과 동일한 에러 형식) 고치기. 피드백: "에러를 '안 다루는' 선택지가 타입 시스템에 없습니다. 이것이 예외 대신 Result를 쓰는 대가이자 보상입니다."

**예시 레슨 U9-④ 「Option vs Result 선택 기준」**

- 세그먼트 요지: **"없음이 정상적인 상태"면 Option, "실패이고 이유가 있으면" Result**. Gleam stdlib는 실패 이유가 하나뿐일 때도 `Result(a, Nil)`을 자주 쓴다(`int.parse`, `list.first`) — Result가 기본값, Option은 "레코드의 선택적 필드"처럼 *부재가 데이터인* 자리에. (검증된 예제)

```gleam
import gleam/option.{type Option, None, Some}

pub type Profile {
  Profile(name: String, nickname: Option(String))
}
```

- 연습 (E6 `spot`): 네 개의 함수 시그니처 중 타입 선택이 어색한 것 고르기 — 정답: `fn divide(a: Int, b: Int) -> Option(Int)` (0으로 나누기는 *실패*이므로 Result가 적절). 피드백에 선택 기준 한 줄 요약 재노출.

**방출 태그**: `option`, `result`, `custom-error-types`, `option-vs-result`, `exhaustiveness`(강화)

---

### U10. Result 체이닝과 use (L3)

**레슨**: ① case 계단의 고통 ② `result.map`과 `result.try` ③ use — 계단을 펴는 설탕 ④ use의 정체(디슈가링)와 한계

**예시 레슨 U10-③ 「use — 계단을 펴는 설탕」**

- 세그먼트 1 요지: Result 두 개를 이어 쓰면 case가 중첩 계단이 된다. `result.try`는 "Ok면 계속, Error면 그대로 단락(short-circuit)"이고, `use`는 그 연쇄를 위에서 아래로 펴서 쓰게 해준다. (검증된 예제: U9의 `parse_age` 재사용 — 커리큘럼 내 코드 연속성)

```gleam
import gleam/result

pub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {
  use age_a <- result.try(parse_age(a))
  use age_b <- result.try(parse_age(b))
  Ok(age_a + age_b)
}
// add_ages("3", "x") == Error(NotANumber)
```

- 연습 1 (E1 `predict`): `add_ages("3", "x")`의 값은? **정답 `Error(NotANumber)`** — 두 번째 parse에서 단락. 오답 `Ok(3)` 피드백: "use 줄에서 Error가 나오면 그 아래는 *실행되지 않고* Error가 그대로 함수의 반환값이 됩니다. early return이 없다더니, Result 체이닝이 그 역할을 타입 안전하게 수행하는 셈입니다."
- 연습 2 (E4 `write`, 리팩터링): 중첩 case 2단짜리 함수를 제시하고 `use` 2줄로 리팩터링(숨김 테스트는 동작 동일성 검증). 흔한 오답 — 마지막 줄을 `age_a + age_b`로 쓰고 `Ok(...)`를 빠뜨림 → 실제 Type mismatch 에러 노출 후: "use를 다 펴도 함수의 반환 타입은 여전히 `Result`입니다. 마지막 성공값을 `Ok`로 포장하는 것을 잊는 실수는 트레이닝 테마 `use-expr`의 1번 단골입니다."

**예시 레슨 U10-④ 「use의 정체」**

- 세그먼트 요지: `use x <- f(arg)`는 마법이 아니라 `f(arg, fn(x) { …아래 전부… })`의 설탕 — "나머지 코드 전체가 마지막 인자(콜백)로 넘어간다". 그래서 `result.try`뿐 아니라 *마지막 인자가 함수인 어떤 함수와도* 쓸 수 있고(`list.map`도 가능하지만 비관용), 남용하면 오히려 읽기 어렵다.
- 연습 (E6 `spot`): `use`로 쓴 코드 4개 중 디슈가링이 *틀리게* 짝지어진 것 고르기. 피드백: "use 아래의 '모든 줄'이 콜백 본문입니다. 일부만 들어가는 게 아닙니다."

**방출 태그**: `result-chaining`, `use-expr`, `short-circuit`, `desugaring`

---

### U11. 제네릭과 타입 설계 기초 (L3)

**레슨**: ① 타입 변수 — 아무거나 한 가지 ② 제네릭 커스텀 타입 ③ type alias와 tuple vs custom type ④ Dict와 Set 한 바퀴

**예시 레슨 U11-① 「타입 변수」**

- 세그먼트 요지: 소문자 타입 이름은 "아무 타입이지만 같은 자리끼리는 같은 타입". 컴파일러가 추론으로 묶는다. (검증된 예제)

```gleam
pub fn pair_map(pair: #(a, a), f: fn(a) -> b) -> #(b, b) {
  let #(x, y) = pair
  #(f(x), f(y))
}
// pair_map(#(1, 2), int.to_string) == #("1", "2")
```

- 연습 1 (E5 `type`): `pair_map(#(1, 2), int.to_string)`의 반환 타입은? 보기 `#(String, String)` / `#(Int, Int)` / `#(a, b)` — **정답 `#(String, String)`**. 오답 `#(a, b)` 피드백: "타입 변수는 호출 시점에 구체 타입으로 *채워집니다*. `a = Int`, `b = String`."
- 연습 2 (E3 `fix`): `pair_map(#(1, "x"), …)` 호출이 내는 unification 에러 읽고 고치기 — 피드백: "`#(a, a)`는 두 원소가 *같은* 타입이어야 한다는 약속입니다."

**예시 레슨 U11-② 「제네릭 커스텀 타입」**

- 세그먼트 요지: `Result(a, e)`도, `List(a)`도, `Option(a)`도 전부 제네릭 커스텀 타입일 뿐 — 직접 만들 수 있다. (검증된 예제)

```gleam
pub type Box(a) {
  Box(inner: a)
}

pub fn unbox(box: Box(a)) -> a {
  box.inner
}
```

- 연습 (E4 `write`): `pub fn map_box(box: Box(a), f: fn(a) -> b) -> Box(b)` 작성 — "당신은 방금 `result.map`의 사촌을 만들었습니다"라는 정답 코멘터리로 U10과 연결.

**방출 태그**: `generics`, `generic-types`, `type-alias`, `tuples`, `dicts`

---

### U12. Opaque Type과 API 설계 (L4)

**레슨**: ① 잘못된 값을 만들 수 없게 — opaque + smart constructor ② 불변식은 모듈 경계에서 지킨다 ③ make-invalid-states-unrepresentable ④ phantom types 맛보기

**예시 레슨 U12-① 「opaque + smart constructor」**

- 세그먼트 1 요지: `pub opaque type`은 타입 이름만 공개하고 생성자는 모듈 안에 가둔다. 검증을 통과한 값만 존재할 수 있게 만드는 패턴 = smart constructor. (검증된 예제 — 2모듈 구성, 멀티 모듈은 WASM 프로젝트에 `write_module` 2회로 그대로 재현 가능)

```gleam
// ---- 모듈 bank.gleam ----
pub opaque type Amount {
  Amount(cents: Int)
}

pub fn new(cents: Int) -> Result(Amount, String) {
  case cents >= 0 {
    True -> Ok(Amount(cents))
    False -> Error("amount must not be negative")
  }
}

pub fn cents(amount: Amount) -> Int {
  amount.cents
}
```

- 연습 1 (E1 `predict`): 다른 모듈에서 `bank.Amount(-999)`를 호출하면? — **정답: 컴파일 에러**. 실제 에러(검증됨) 노출:

```
error: Unknown module value
bank.Amount is a type constructor, it cannot be used as a value
```

  피드백: "opaque의 요점입니다: 음수 Amount는 *표현조차 불가능*합니다. 런타임 검증이 아니라 컴파일 타임 봉인."
- 연습 2 (E4 `write`): `Email` opaque 타입 + `new` smart constructor 작성(`"@"` 포함 검증, `string.contains` 사용). 숨김 테스트가 `new("a@b")`는 Ok, `new("ab")`는 Error인지 검증.

**예시 레슨 U12-④ 「phantom types 맛보기」**

- 세그먼트 요지: 타입 파라미터가 값에는 등장하지 않고 **타입 단계에서만 구분자**로 쓰일 수 있다 — 단위 혼동(미터 vs 피트)을 컴파일 에러로. (검증된 예제)

```gleam
pub type Meters

pub type Feet

pub type Length(unit) {
  Length(amount: Float)
}

pub fn add_lengths(a: Length(unit), b: Length(unit)) -> Length(unit) {
  Length(a.amount +. b.amount)
}
```

- 연습 (E1 `predict`): `Length(Meters)`와 `Length(Feet)`를 `add_lengths`에 넣으면? — **정답: Type mismatch 컴파일 에러**. "고급 맛보기" 표기, SRS 등록 제외(부담 조절).

**방출 태그**: `opaque-types`, `smart-constructor`, `invalid-states`, `phantom-types`

---

### U13. 의도적 크래시 (L4)

**레슨**: ① todo와 panic — 아직 vs 절대 ② let assert — "이건 반드시 맞는다" ③ assert와 테스트 — 크래시가 옳은 순간

**예시 레슨 U13-② 「let assert」**

- 세그먼트 요지: `let assert`는 부분 패턴을 강제 매칭하고, 틀리면 **즉시 크래시**한다. "이 시점에 이 모양이 아닌 것은 프로그래머의 버그"일 때만 쓴다 — Result로 *다룰 수 있는* 실패에 쓰면 안 된다. (검증된 예제)

```gleam
pub fn first_or_crash(xs: List(Int)) -> Int {
  let assert [first, ..] = xs
  first
}
```

- 연습 1 (E6 `spot`): 시나리오 4개("사용자 입력 파싱" / "방금 내가 만든 3원소 리스트의 head" / "설정 파일 읽기" / "네트워크 응답") 중 `let assert`가 정당한 것 고르기 — **정답: 직접 만든 리스트의 head**. 피드백: "외부에서 온 값의 실패는 데이터(Result), 내 코드의 불변식 위반은 버그(crash). 이 구분이 이 유닛의 전부입니다."
- 연습 2 (E1 `predict`): `first_or_crash([])` 실행 결과는? — **정답: 런타임 크래시(패턴 불일치)**. 플랫폼은 캡처된 예외 메시지를 그대로 보여준다.

**예시 레슨 U13-③ 「assert와 테스트」**

- 세그먼트 요지: `assert`(v1.11+)는 Bool 표현식을 단언하고 실패 시 *양변의 값까지 담긴* 풍부한 메시지로 크래시한다. — "사실 여러분이 이 플랫폼에서 푸는 모든 `write` 문제의 숨김 테스트가 정확히 이걸로 만들어져 있습니다" (메타 공개로 동기 부여).

```gleam
pub fn main() -> Nil {
  assert total([1, 2, 3]) == 6
  assert total([]) == 0
  Nil
}
```

- 연습 (E4 `write`): "직접 채점기 만들기" — 자신이 U6에서 작성한 `sum`에 대한 assert 3개짜리 테스트 main 작성.

**방출 태그**: `todo-panic`, `let-assert`, `assert`, `crash-vs-result`

---

### U14. Gleam에 없는 것들 — 사고 전환 II (L4)

**레슨**: ① type class가 없는 이유와 그 대신 (명시적 함수 전달) ② 커링이 없는 이유와 캡처 ③ 게으름이 없다 — eager 평가와 gleam_yielder ④ 예외·뮤테이션·매크로 — 결핍의 일관성

각 레슨은 공식 FAQ의 논거(타입 클래스: "혼란스러운 에러 메시지·컴파일 시간·런타임 비용"; 뮤테이션: 구조 공유 불변 데이터; 매크로: 가독성·컴파일 속도 보존 시에만 열려 있음)를 인용하고, "그 대신 Gleam은 무엇을 주는가"를 코드로 보인다. Haskell 경험자가 겪는 전이 마찰을 정면으로 다루는, 경쟁 FP 강의에 없는 차별화 유닛.

**예시 레슨 U14-② 「커링이 없는 이유와 캡처」**

- 세그먼트 요지: `add(10)`은 Gleam에서 부분 적용이 아니라 **인자 부족 컴파일 에러**다. 부분 적용 의도는 캡처 `add(10, _)`로 *명시*한다 — 실수(인자 빠뜨림)와 의도(부분 적용)가 문법으로 구분되는 것이 설계 이유.
- 연습 1 (E1 `predict`): `list.map([1, 2], add(10))`은? — **정답: 컴파일 에러(인자 개수 불일치)**. 오답 `[11, 12]` 피드백: "Haskell이라면 맞습니다. Gleam은 자동 커링이 없으므로 `add(10, _)`로 빈자리를 명시하세요."
- 연습 2 (E2 `hole`): 같은 식을 캡처로 고치기.

**예시 레슨 U14-③ 「게으름이 없다」**

- 세그먼트 요지: Gleam은 eager — 인자는 호출 *전에* 평가된다. 무한 시퀀스 같은 게으른 구조는 언어가 아니라 라이브러리(gleam_yielder, stdlib 아님)의 영역.
- 연습 (E1 `predict`): `bool.guard`류 함수에 비싼 연산을 인자로 직접 넘기는 코드 — "이 연산은 조건이 False여도 실행될까?" **정답: 실행된다(eager)** → "그래서 지연이 필요하면 `fn() { … }`로 감싸 넘깁니다" — 익명 함수(U7)가 게으름의 수동 대체재임을 연결.

**방출 태그**: `no-typeclass`, `no-currying`, `eager-eval`, `why-not-lessons`

---

### U15. 캡스톤 (L4)

**레슨**: ① 종합 1 — CSV 한 줄 파서 (custom types + Result + use + list 모듈 총동원) ② 종합 2 — 상태 기계 (variant 전이 + exhaustiveness) ③ OTP와 actor — 다음 세계 (읽기 전용) ④ 수료와 다음 경로 (Exercism Gleam 트랙, CodeCrafters, 본 플랫폼 트레이닝 모드 상시 운영 안내)

**예시 레슨 U15-① 「CSV 한 줄 파서」** (10분, write 중심)

- 단계적으로 `"lucy,8"` → `Result(Player, ParseError)` 파서를 완성. 세그먼트마다 한 함수씩: `string.split` → 필드 개수 검증(case로 `[name, age]` 패턴) → `parse_age` 재사용(U9) → `use`로 조립(U10). 숨김 테스트는 정상/필드 부족/나이 비숫자 3경로 검증.
- 이 레슨의 모든 부분 단계가 그대로 트레이닝 퍼즐 뱅크의 고난도 아이템(`pipeline`+`result-chaining`+`use-expr` 복합 태그)으로 재수출된다.

**예시 레슨 U15-③ 「OTP와 actor — 다음 세계」** (읽기 전용)

- 명시 배너: "이 레슨의 코드는 Erlang VM 전용이라 브라우저에서 실행되지 않습니다(JS 타깃 미지원 — 컴파일러가 타깃별 지원을 표현식 단위로 추적합니다). 읽고 이해하는 레슨입니다."
- gleam_otp의 typed actor 예제를 정적 하이라이팅으로 제시, 연습은 E1/E6 객관식만(코드 실행 없음). 서버 사이드 샌드박스 도입 시 실습 전환 예약.

**방출 태그**: `capstone`, `parsing`, `state-machine`(+ 복합 태그 재수출)

---

## 5. 트리키 파트 카탈로그 → 트레이닝 세션 매핑

명시적으로 추출한 트리키 파트 16종. **노출 시점** = 해당 유닛 완료 직후 트레이닝 세션(레이팅 퍼즐·SRS·타임드)에 해당 테마 아이템이 서빙되기 시작하는 시점. 각 항목은 트레이닝 시스템의 퍼즐 테마 태그와 1:1로 연결된다.

| # | 트리키 파트 | 전형적 함정 | 노출 시점 | 테마 태그 | 주 연습 타입 |
|---|---|---|---|---|---|
| T1 | Int/Float 연산자 분리 | `x + 0.5`, `/` vs `/.` | U1 이후 | `int-float-ops` | E3 fix |
| T2 | shadowing ≠ mutation | 캡처된 옛 값 vs 새 바인딩 | U1 이후 | `shadowing` | E1 predict |
| T3 | early return 없음 — 분기 재구성 | 가드절 사고를 case 트리로 | U3 이후 | `no-early-return` | E4 write |
| T4 | case 가지 순서·죽은 가지 | `_`를 먼저 둠, guard 순서 | U3 이후 | `branch-order` | E1/E6 |
| T5 | exhaustive match 빠진 케이스 | variant 추가 후 누락, `_` 남용으로 검사 무력화 | U4 이후 (U9에서 Result로 강화) | `exhaustiveness` | E3 fix |
| T6 | record update는 복사 | 원본이 안 바뀜을 잊음 | U4 이후 | `record-update` | E1 predict |
| T7 | 재귀 종료 조건 | 빈 리스트 케이스 누락, 같은 인자 재호출(무한 재귀→watchdog) | U5 이후 | `termination` | E3 fix |
| T8 | 인덱스 없는 리스트 사고 | `xs[i]` 부재, prepend O(1)/append O(n) | U5 이후 | `head-tail-pattern` | E2/E6 |
| T9 | tail call 변환 | 비-꼬리 재귀 → wrapper+acc로 변환, `[] -> acc` vs `[] -> 0` | U6 이후 | `tail-call`, `accumulator` | E4 write |
| T10 | 누산기 결과 뒤집힘 | prepend 누산 후 reverse 누락 | U6 이후 (U8 fold에서 재등장) | `acc-reverse` | E1 predict |
| T11 | 캡처 vs 커링 | `f(10)` 부분 적용 착각, `_` 위치 | U7 이후 (U14에서 재강화) | `captures`, `no-currying` | E3 fix |
| T12 | fold 방향과 콜백 인자 순서 | fold vs fold_right, `fn(acc, x)` 순서, fold-prepend=reverse | U8 이후 | `fold-direction` | E1/E3 |
| T13 | map/filter/fold 도구 선택 | 반환 타입으로 도구 고르기 | U8 이후 | `tool-choice` | E6 spot |
| T14 | Option vs Result 선택, `Result(a, Nil)` 관용 | 부재=데이터 vs 실패=이유 | U9 이후 | `option-vs-result` | E6 spot |
| T15 | case 계단 → use 전환 | 디슈가링 오해, 마지막 `Ok(...)` 누락, 단락 동작 예측 실패 | U10 이후 | `use-expr`, `result-chaining` | E4 write |
| T16 | 크래시 도구 오남용 | 다룰 수 있는 실패에 `let assert`, 외부 입력에 panic | U13 이후 | `crash-vs-result` | E6 spot |

트레이닝 세션 운영 규칙(연결 계약): (1) 레슨에서 학습자가 틀린 마이크로 연습은 해당 테마 태그와 함께 실패 로그로 적재되어 개인화 재훈련 큐(lichess "failed puzzles by theme" 방식)에 들어간다. (2) 유닛 완료 시 해당 테마들이 "healthy mix" 풀에 편입된다. (3) T7, T9, T12, T15는 본 커리큘럼이 지정하는 **핵심 4대 트리키 파트**로, SRS 등록이 기본이고 타임드 모드(Code Storm)의 고배점 테마다.

---

## 6. 퍼즐 테마 태그 체계 (레슨 → 트레이닝 연결 고리)

### 6.1 태그 방출 규칙

- 모든 마이크로 연습은 **주 태그 1개 + 보조 태그 0~2개**를 가진다 (lichess 퍼즐의 다중 테마 태깅 대응).
- 레슨 완료 = 그 레슨의 주 태그가 사용자 프로필에서 "학습됨" 상태가 됨 → 트레이닝 세션이 그 테마의 레이팅 퍼즐 서빙을 시작 (학습 전 테마는 서빙하지 않음 — 퍼즐로 처음 배우는 일 방지).
- 체크포인트·캡스톤 문항은 복합 태그(2~3개)를 가지며, 트레이닝에서 고난도 아이템으로 재사용된다.

### 6.2 유닛 → 태그 총괄표

| 유닛 | 방출 태그 (Exercism slug 정렬 가능 항목은 동일 명명) |
|---|---|
| U1 | `immutability` `shadowing` `expressions-everywhere` `int-float-ops` `blocks` |
| U2 | `pipe` `function-definition` `type-annotation` |
| U3 | `case-basics` `guards` `branch-order` `no-early-return` |
| U4 | `custom-types` `records` `labelled-fields` `record-update` `exhaustiveness` `pattern-match-types` |
| U5 | `lists` `head-tail-pattern` `recursion` `termination` `no-loops` |
| U6 | `tail-call` `accumulator` `acc-reverse` `wrapper-loop-idiom` |
| U7 | `anonymous-fn` `hof` `captures` `labelled-args` |
| U8 | `list-map` `list-filter` `fold` `fold-direction` `tool-choice` `pipeline` |
| U9 | `option` `result` `custom-error-types` `option-vs-result` |
| U10 | `result-chaining` `use-expr` `short-circuit` `desugaring` |
| U11 | `generics` `generic-types` `type-alias` `tuples` `dicts` |
| U12 | `opaque-types` `smart-constructor` `invalid-states` `phantom-types` |
| U13 | `todo-panic` `let-assert` `assert` `crash-vs-result` |
| U14 | `no-typeclass` `no-currying` `eager-eval` `why-not-lessons` |
| U15 | `capstone` `parsing` `state-machine` + 전 태그 복합 |

### 6.3 트레이닝 시스템에 넘기는 인터페이스 요약

- **아이템 스키마**: `{ id, type: E1..E6, theme_tags: [주, 보조...], unit: Un, seed_rating, code, holes/choices, hidden_test, feedback_map: {오답패턴: 해설}, srs_eligible: bool }` — Glicko-2 레이팅·RD는 트레이닝 시스템 소관, 커리큘럼은 `seed_rating`(저자 추정, lichess validator의 수동 추정 레이팅에 대응)만 공급.
- **타임드 적합성**: E1/E5/E6(컴파일 불필요·1스텝)은 Code Storm용, E2/E3은 Streak용, E4는 비타임드 레이팅 퍼즐 전용으로 표기.
- **SRS 아이템 출처**: 레슨당 2~4개 핵심 아이템(주로 E2 재구성형)이 `srs_eligible: true`로 방출되어 MoveTrainer식 8레벨(4h/1d/3d/1w/2w/1mo/3mo/6mo) 큐에 등록된다.
- **콘텐츠 생산 파이프라인**(generator→validator→tagger 대응): 본 커리큘럼의 검증된 예제 함수들을 시드로, (a) 정상 코드에 단일 변이 주입(연산자 교체, 가지 삭제, 인자 순서 교환 — 각각 T1, T5, T12 생성기), (b) 구멍 뚫기(E2 생성기)로 후보를 자동 생산하고, 컴파일러+숨김 테스트로 "의도된 정답이 유일하게 통과"함을 기계 검증 후 저자가 seed_rating을 매겨 투입한다.