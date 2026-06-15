# Gleam FP 학습 플랫폼 — FP 이론 트랙 커리큘럼 설계 문서

> 범위: **FP 이론 트랙(이론 세션) 전체**. 실용 언어 트랙(레슨 U1–U15)은 [`curriculum.md`](curriculum.md), 트레이닝 세션(레이팅 퍼즐·타임드·SRS)은 [`training-system.md`](training-system.md)와 [`../../PLAN.md`](../../PLAN.md)가 다룬다. 본 문서는 실용 트랙이 **의도적으로 미뤄둔** 개념층(curriculum.md §3의 scope-out: "모나드 일반론", type class 흉내, 커링, 카테고리론)을 담당하며, 그 트랙이 소비할 **이론 태그·트리키 파트·아이템 출처**까지 정의한다.
>
> 검증 노트: 본 문서의 **모든 Gleam 예제·predict 출력·의도적 컴파일 에러 메시지는 플랫폼이 핀한 `gleam 1.17.0`(browser WASM와 동일한 JS 타깃 코드젠 + `gleam_stdlib`)에서 실제 컴파일·실행 검증**되었다(`tools/golden`의 핀 CLI 오라클과 동일 바이너리). 따라서 콘텐츠 repo 투입 시 CI 골든(PLAN §5.3)은 재검증·스냅샷 고정만 수행하면 된다. 연습 타입 표기는 **PLAN §4.1의 통합 레지스트리 P1–P8**을 따른다(구 curriculum.md의 E1–E6 표기는 폐기됨 — 본 트랙은 현행 canonical 분류로 저작되었다).

---

## 0. 왜 이론 트랙인가 — 실용 트랙과의 분업

실용 트랙(U1–U15)은 **"Gleam으로 무엇을, 어떻게 쓰는가"**를 가르친다. 값·함수·case·커스텀 타입·재귀·list 모듈·Result/use·opaque 타입까지, 손이 먼저 익는 트랙이다. 그 트랙은 의식적으로 **이론을 미뤘다** — curriculum.md §3은 "모나드 일반론, type class 흉내, 커링, 매크로"를 명시적 scope-out으로 선언하고, U14("Gleam에 없는 것들")에서 *왜 없는가*만 다룬다. **이론 트랙은 바로 그 유보된 층이 사는 곳이다.** "왜 그렇게 쓰는가, 그 패턴의 이름은 무엇인가, 그것이 지키는 법칙은 무엇인가"를 다룬다.

체스로 대응하면 명확하다.

| 체스 학습 | 본 플랫폼 |
|---|---|
| 전술 퍼즐·오프닝 암기를 반복해 **자동화**(automaticity)한다 | 실용 트랙(레슨) + 트레이닝(레이팅 퍼즐·SRS) — 손이 먼저 |
| 포지션 이론·엔드게임 이론을 공부해 **수 뒤의 '왜'**를 이해한다 | **이론 트랙** — 패턴·법칙·구조를 이름 붙여 일반화 |
| 이론 공부는 대국을 *막지 않는다* — 병행하며 깊이를 더한다 | 이론 트랙은 실용 레벨 해제를 **게이팅하지 않는다**(선택·병렬). 단, 이론 레슨 완료는 그 테마의 트레이닝 퍼즐을 연다 |

이 분업에서 세 가지 설계 원칙이 나온다.

1. **"보여주고 → 재현"이 아니라 "보여주고 → 일반화".** 실용 트랙은 Chessable식 "보여준 코드를 빈 에디터에 재현"으로 끝난다. 이론 트랙은 학습자가 **이미 써본** 구체 사례를 나란히 놓고 *공통 모양을 이름 붙인다*. `list.map`·`option.map`·`result.map`(U8/U9)은 → **펑터**(TU9), `result.try`·`use`(U10)는 → **모나드 bind**(TU10), 손으로 쓴 `fold`(U6/U8)는 → **카타모피즘**(TU12), `<>`·`+`·`list.append`는 → **모노이드**(TU8)다. 이론 유닛의 선수에 반드시 *대응 실용 유닛*이 들어가는 이유다(§1.4). 이는 "퍼즐로 개념을 처음 배우는 일 방지"(PLAN §2)라는 플랫폼 철학의 이론판 — **이론은 새 개념을 도입하지 않고, 이미 만난 것에 이름을 준다**.

2. **패턴이지 인터페이스가 아니다 — 정직성의 척추.** Gleam에는 **타입클래스도 고계 타입(HKT)도 없고**, 자동 커링도 없으며, 평가는 eager다. 따라서 본 트랙은 펑터·모노이드·모나드를 *구현하는 인터페이스*로 가르치지 **않는다**. "여러 구체 타입에서 **알아보는 패턴**"으로 가르친다. "아무 펑터에나 동작하는 단일 `map`"은 Gleam에서 **작성 불가**이며(TU9에서 `f(a)` 시도가 실제로 Syntax error로 막히는 것을 보인다), 모든 추상화 유닛은 U14①("타입클래스 없음", 공식 FAQ 논거: 혼란스러운 에러·컴파일 시간·런타임 비용)으로 명시적으로 되돌아온다. 타입클래스 언어(Haskell 계열)를 흉내 내지 않는 이 정직함이 경쟁 FP 강의 대비 본 트랙의 차별점이다.

3. **법칙은 실행 가능한 프로퍼티다.** 펑터 법칙·모노이드 법칙·모나드 법칙은 추상적 구호가 아니라, 플랫폼의 `assert` 하니스로 **표본 입력에서 돌려보는 프로퍼티**로 제시된다(`assert map(map(x, g), f) == map(x, fn(a){ f(g(a)) })`). 법칙을 깨는 가짜 구현(순서 뒤집기·중복·누락)을 골라내는 `spot_bug`(P8)가 이 트랙의 대표 연습이 된다.

---

## 1. 구조: 이론 레벨 → 이론 유닛, 그리고 실용 트랙과의 맞물림

### 1.1 구조 규칙

- **이론 유닛(TU)**: 2~4개 레슨. 실용 유닛과 같은 교차 구조(설명 세그먼트 ↔ 마이크로 연습, §2)지만 연습이 P1/P2/P8/P5/P6에 치우친다(무컴파일·법칙형 비중↑).
- **이론 레벨(TL)**: 2~4개 유닛 + **레벨 체크포인트** 1개. 실용 트랙이 유닛마다 체크포인트를 두는 것과 달리, 이론 유닛은 작고 개념적이므로 **레벨 단위 체크포인트**(혼합 10문항, 8개 이상 통과, 주로 P1/P2/P8)로 묶는다.
- **잠금 해제**: 한 이론 유닛은 `(그 유닛의 실용 선수가 모두 완료) ∧ (선행 이론 유닛 완료)`일 때 열린다(§1.4 그래프). 이론 트랙은 **실용 레벨 해제를 게이팅하지 않는다** — 체스의 이론 공부처럼 병렬·선택이다. 건너뛰기는 확인 프롬프트 후 허용(실용 트랙과 동일).
- **레슨 완료 시**: (a) 핵심 이론 아이템 1~3개가 SRS 큐에 등록, (b) 레슨의 이론 태그가 "학습됨"으로 마킹 → 트레이닝 세션이 해당 `theory:` 테마 퍼즐을 서빙하기 시작.
- **마무리 = "일반화 카드"**: 실용 트랙의 "재구성 연습"을 대체. 방금 본 패턴을, 학습자가 실용 트랙에서 써온 구체 사례 2~3개에 다시 대응시켜 보이는 요약 카드.

### 1.2 이론 레벨 개요

| 레벨 | 이름 | 유닛 | 한 줄 질문 | 핵심 |
|---|---|---|---|---|
| **TL1** | 함수와 계산의 본질 | TU1–TU3 | "계산이란 무엇인가" | 순수성·참조 투명성, 등식적 추론·치환 모델, 평가 전략(eager/lazy) |
| **TL2** | 타입의 대수 | TU4–TU6 | "타입이란 무엇인가" | ADT를 대수로(카디널리티), 동형과 데이터 모델링, 타입=명제(커리-하워드)·파라메트리시티 |
| **TL3** | 구조 위의 추상화 — 패턴이지 타입클래스가 아니다 | TU7–TU10 | "이 모양에 이름이 있다" | 합성·항등, 모노이드, 펑터, 모나드/애플리커티브 — **모두 패턴으로, no-HKT 정직성과 함께** |
| **TL4** | 토대와 한계 | TU11–TU12 | "바닥과 천장" | 람다 계산·처치 인코딩(계산의 바닥), HKT 부재의 종합·카타모피즘·다음 경로(추상화의 천장) |

### 1.3 이론 유닛 전체 표

| # | 유닛 | 핵심 개념 | 선수(실용 + 이론) | 레슨 | 핵심 방출 태그 |
|---|---|---|---|---|---|
| TU1 | 순수성과 참조 투명성 | 순수 함수, RT, 부작용, 효과를 값으로 미루기 | U1, U2, U3 | 3 | `purity` `referential-transparency` `side-effect` |
| TU2 | 등식적 추론과 치환 모델 | 치환 모델, 리팩터링=등식 변환, 구조적 귀납 | TU1, U1, U6 | 3 | `equational-reasoning` `substitution-model` `structural-induction` |
| TU3 | 평가 전략: eager와 lazy | applicative vs normal order, 단락, thunk | TU1, U7, U14 | 3 | `eager-vs-lazy` `short-circuit` `thunk` |
| TU4 | 대수적 데이터 타입의 대수 | 카디널리티, 합/곱/지수 타입, unit/void | U4, U11 | 3 | `adt-algebra` `cardinality` `sum-product-types` `unit-void-types` |
| TU5 | 동형과 데이터 모델링 | 동형(왕복 항등), 불법 상태 제거 = 카디널리티 축소 | TU4, U9, U12 | 3 | `type-isomorphism` `cardinality-modelling` |
| TU6 | 커리-하워드와 파라메트리시티 | 타입=명제, 공짜 정리(순수·전체 단서) | TU4, TU5, U11 | 2 | `curry-howard` `parametricity` `free-theorems` |
| TU7 | 합성과 항등 | 함수 합성, 결합법칙, 항등원, 카테고리(맛보기) | U2, U7 | 2 | `composition` `identity-law` `composition-associativity` |
| TU8 | 모노이드 ★ | 결합+항등, fold = 모노이드 요약, 재배열/병렬 | U8, TU2, TU7 | 4 | `monoid` `monoid-laws` `monoid-fold` |
| TU9 | 펑터 패턴 | map 한 모양, 펑터 2법칙, **no-HKT 정직성** | U8, U9, TU7, U14 | 4 | `functor` `functor-laws` `no-hkt` |
| TU10 | 모나드와 애플리커티브 ★ | bind = try/use, 모나드 3법칙, map vs bind | U10, TU9 | 4 | `monad` `monad-laws` `applicative` `bind-vs-map` |
| TU11 | 람다 계산과 처치 인코딩 | λ-계산, β-환원, 처치 인코딩, 고정점(eager Y 발산) | U7, TU3, TU1 | 3 | `lambda-calculus` `beta-reduction` `church-encoding` `fixpoint` |
| TU12 | 캡스톤 — 한계·재귀 스킴·다음 경로 | no-HKT 종합, 카타모피즘, 다음 학습 경로 | TU8, TU9, TU10, TU11 | 3 | `no-hkt` `catamorphism` `recursion-scheme` |

총 **37 이론 레슨 + 4 레벨 체크포인트**. ★ = 핵심 이론 유닛(실용 트랙의 U8처럼 트리키 파트가 집중되는 유닛). 출시 전략: 이론 트랙은 **실용 v1(L1+L2) 이후의 부가 트랙**으로, TL1(계산의 본질)을 먼저 열고 TL2~TL4를 순차 릴리스한다 — TL3·TL4는 대응 실용 유닛(U8~U11, U14)이 출시된 뒤라야 선수가 충족된다.

### 1.4 실용 트랙과의 선수 그래프

이론 유닛은 자신이 일반화하는 **구체 사례를 학습자가 이미 만났을 때**만 열린다. 화살표 `A → B` = "A를 먼저".

```
실용 트랙(curriculum.md):  U1 U2 U3 → U4 → U5 U6 U7 → U8 U9 → U10 U11 → U12 U13 U14 U15

이론 트랙(본 문서):
  U1,U2,U3            ─→ TU1 ─→ TU2            (TL1: 순수성·등식추론)
  U7,U14 + TU1        ─→ TU3                    (TL1: 평가 전략)
  U4,U11             ─→ TU4 ─→ TU5            (TL2: ADT 대수·동형)
  U11 + TU4,TU5       ─→ TU6                    (TL2: 커리-하워드)
  U2,U7              ─→ TU7                    (TL3: 합성)
  U8 + TU2,TU7        ─→ TU8                    (TL3: 모노이드)
  U8,U9,U14 + TU7     ─→ TU9 ─→ TU10           (TL3: 펑터 → 모나드)   [TU10도 U10 필요]
  U7 + TU1,TU3        ─→ TU11                   (TL4: 람다 계산)
  TU8,TU9,TU10,TU11  ─→ TU12                   (TL4: 캡스톤)
```

핵심 관찰: **TL3(추상화)는 U8~U10과 U14가 모두 출시된 뒤라야 의미가 있다.** 펑터를 "이미 써본 세 map의 공통 모양"으로 가르치려면 학습자가 U8(`list.map`)·U9(`option.map`/`result.map`)를 거쳤어야 하고, "왜 단일 map이 없나"를 말하려면 U14(타입클래스 없음)를 거쳤어야 한다. 이 의존성이 출시 순서(§1.3)를 강제한다.

---

## 2. 레슨 내부 구조 & 연습 타입 (이론 트랙 특수성)

### 2.1 교차 구조

실용 트랙(curriculum.md §2)과 동일한 "설명 세그먼트(≤90초) ↔ 마이크로 연습(5~10개)" 교차. 차이는 **마무리가 "재구성 연습"이 아니라 "일반화 카드"**(§1.1)라는 점, 그리고 설명 세그먼트가 거의 항상 **학습자가 이미 본 실용 트랙 코드를 다시 불러와** 그 위에 이름을 얹는다는 점이다.

### 2.2 연습 타입 — P1~P8 레지스트리(PLAN §4.1)와 이론 트랙의 사용 분포

본 트랙은 **구 E1~E6 표기를 쓰지 않고** 현행 통합 레지스트리를 쓴다.

| ID | 타입 | 이론 트랙에서의 쓰임 | 빈도 |
|---|---|---|---|
| P1 | `predict` | β-환원 한 스텝, 펑터/모나드 법칙 결과, 카디널리티 계산, 평가 순서 예측 | ◎ 매우 높음 |
| P2 | `mcq` | "이 (집합,연산,원소)는 모노이드인가?", "이 시그니처의 전체 함수는?", 동형 판별, no-HKT 이유 | ◎ 매우 높음 |
| P8 | `spot_bug` | **법칙을 깨는 구현 고르기**(가짜 map/monoid), 비결합 연산, 참조 투명성 위반 | ◎ 매우 높음 |
| P5 | `write_fn` | 동형 왕복 함수, 처치 인코딩, 트리 카타모피즘, **법칙을 assert로 검사하는 main** | ○ 높음 |
| P6 | `refactor` | 등식 보존 재작성(중첩 case → use, 합성 재배치, `Result(Result)` 평탄화) | ○ 중간 |
| P3 | `fill_hole` | 항등원 채우기, 처치 인코딩 빈칸 | △ 보통 |
| P4 | `fix_error` | `Nil`을 값으로 쓴 함수 고치기, 타입 불일치 | △ 보통 |
| P7 | `parsons` | 등식 증명 단계 재배열, 귀납 증명 단계 정렬 | △ 낮음 |

### 2.3 이론 트랙 고유 연습 관용구 — "법칙을 실행 가능한 프로퍼티로"

이론 트랙의 시그니처 연습은 **법칙을 코드로 돌려보는 것**이다. 플랫폼의 채점 하니스(PLAN §5.2, `assert` 기반)를 그대로 재사용한다.

```gleam
import gleam/list
import gleam/function.{identity}

pub fn main() -> Nil {
  let xs = [1, 2, 3]
  let f = fn(x) { x + 1 }
  let g = fn(x) { x * 10 }
  // 펑터 항등 법칙
  assert list.map(xs, identity) == xs
  // 펑터 합성 법칙
  assert list.map(list.map(xs, g), f) == list.map(xs, fn(a) { f(g(a)) })
  Nil
}
```

- **P5형**: 빈 `map` 골격을 주고 "두 법칙을 모두 통과시키는 구현을 작성"(숨김 테스트가 표본 입력에서 법칙을 `assert`).
- **P8형**: 네 개의 `map` 구현(하나는 결과 순서를 뒤집음) 중 **법칙 위반자 고르기** — 위반은 합성 법칙 `assert`가 실패하는 것으로 객관적으로 판정된다.

이 관용구가 추상적 "법칙"을 **틀리면 빨갛게 터지는 테스트**로 바꿔, 이론을 트레이닝 세션의 rated 퍼즐로 흘려보낼 수 있게 만든다.

### 2.4 피드백·체크포인트 정책

- 피드백 정책은 실용 트랙과 동일(chess.com "모든 수에 코멘터리"): 정답 시에도 한 줄 코멘터리, 오답 시 보기별 사전 저작 해설, 2연속 오답 시 near-neighbor 변형, 재시도 무벌점, '정답 보기'만 SRS 인터벌 축소.
- **레벨 체크포인트**(TL1~TL4 각 1개): 해당 레벨 이론 태그 혼합 10문항(주로 P1/P2/P8), 8개 이상 통과. 실패 문항은 `이론유닛/레슨#segment_id` 딥링크로 역링크.
- **고급 맛보기 표기**: TU6(파라메트리시티)·TU11(고정점/Y 콤비네이터) 일부 세그먼트는 "고급 맛보기"로 표기하고 SRS 등록에서 제외해 부담을 조절한다.

---

## 3. 커버 개념 전체 목록 (이론 개념 → 유닛 매핑, + 대응 실용 유닛)

| 이론 개념 | 이론 유닛 | 이 개념이 *이름 붙이는* 실용 사례(선수) |
|---|---|---|
| 순수성·참조 투명성·결정성 | TU1 | U1 불변성, U2 함수(반환=마지막 표현식) |
| 효과를 값으로 미루기(thunk 맛보기) | TU1, TU3 | U7 익명 함수, U14③ eager |
| 등식적 추론·치환 모델 | TU2 | U1 불변성, U2 파이프(= 등식 변환), U7 캡처 |
| 구조적 귀납 | TU2 | U5 구조적 재귀, U6 |
| 평가 전략(eager/lazy)·단락 | TU3 | U14③ eager, U3 case |
| ADT의 대수(합·곱·지수·unit·void) | TU4 | U4 커스텀 타입, U11 tuple/제네릭 |
| 카디널리티·동형·불법 상태 제거 | TU4, TU5 | U9 Option/Result, U12 opaque/invalid-states |
| 커리-하워드(타입=명제) | TU6 | U4 합/곱 타입, U13 의도적 크래시(전체성 단서) |
| 파라메트리시티·공짜 정리 | TU6 | U11 제네릭 |
| 합성·항등·결합법칙(카테고리 맛보기) | TU7 | U2 파이프, U7 고차 함수 |
| 모노이드와 그 법칙 | TU8 | U8 fold, `<>`·`+`·`list.append` |
| 펑터와 그 법칙 | TU9 | U8 `list.map`, U9 `option.map`/`result.map`, U11② `map_box` |
| 모나드/애플리커티브와 그 법칙 | TU10 | U10 `result.try`/`use`, U9 |
| 람다 계산·β-환원·처치 인코딩·고정점 | TU11 | U7 익명 함수, U5/U6 named recursion |
| 재귀 스킴(카타모피즘) | TU12 | U6/U8 손으로 쓴 fold |
| HKT 부재의 일관성(no-typeclass의 이론) | TU9, TU10, TU12 | U14① 타입클래스 없음(공식 FAQ) |

명시적 **scope-out**은 §7에서 다룬다(자연 변환·수반·의존 타입·효과 시스템·코모나드·free monad 등 — Gleam의 no-HKT 천장 위에 있는 것들).

## 4. 유닛별 상세 설계 + 예시 레슨

각 유닛: 레슨 목록 → 예시 레슨 2개(세그먼트 요지 + 실제 연습 + 정답 + 오답 피드백) → 방출 태그. 모든 Gleam 예제·predict 출력·의도적 컴파일 에러는 핀 **gleam 1.17.0**(JS 타깃)에서 컴파일·실행 검증되었다.

---

> ### 이론 레벨 TL1 — 함수와 계산의 본질

### TU1. 순수성과 참조 투명성 (Purity & Referential Transparency) [TL1]

**레슨**: ① 순수 함수 — 같은 입력, 같은 출력, 그리고 "그 외엔 아무 일도 없음" ② 참조 투명성 — 표현식을 그 값으로 바꿔도 프로그램이 변하지 않는다 ③ Gleam의 현실 — 부작용은 허용되지만 타입이 숨기지 않는다(`Nil`이라는 신호), 그리고 효과를 값으로 미루기

> 선수: U1(값·불변성·표현식), U2(함수·파이프), U3(case·early return 없음). 이 유닛은 너가 이미 U1~U3에서 *그냥 그렇게 써온* 함수들이 사실 어떤 약속을 지키고 있었는지를 이름 붙여 되짚는다. "값을 바꾸는 게 아니라 새 값을 만든다(U1)"는 규칙이 사실은 순수성의 한 단면이었음을 여기서 회수한다.

**예시 레슨 TU1-① 「참조 투명성 — 표현식을 값으로 치환하기」**

- 세그먼트 1 요지: **순수 함수**는 두 가지를 약속한다. (1) 같은 입력이면 항상 같은 출력(**결정성**), (2) 출력을 내는 것 말고 관찰 가능한 다른 일을 하지 않음(부작용 없음). 이 두 약속이 지켜지면 그 함수 호출 표현식은 **참조 투명(referentially transparent)**하다 — 즉 코드 어디서든 `double(5)`라는 표현식을 그것의 값 `10`으로 바꿔치기해도 프로그램의 의미가 변하지 않는다. 이건 단순한 정의가 아니라 **너가 머릿속에서 코드를 계산해도 되는 허가증**이다. (검증된 예제)

```gleam
import gleam/int
import gleam/io

fn double(x: Int) -> Int {
  x * 2
}

pub fn main() -> Nil {
  let a = double(5) + double(5)
  let b = 10 + 10
  let v = double(5)
  let c = v + v
  io.println(int.to_string(a))
  io.println(int.to_string(b))
  io.println(int.to_string(c))
}
```

  세 표현식 `a`, `b`, `c`는 *서로 다르게 쓰였지만* 같은 값이다. `double(5)`를 `10`으로(또는 `v`로) 마음대로 치환할 수 있기 때문이다 — 이게 참조 투명성의 정의 그 자체.

- 연습 1 (P1 `predict`): 위 코드의 출력 세 줄은?
  보기: (a) `10` / `20` / `20` (b) `20` / `20` / `20` (c) `20` / `20` / `10` (d) 컴파일 에러 — **정답 (b)**.
  - 정답 코멘터리: "세 식 모두 결국 `20`. 참조 투명하면 '어떻게 쓰였나'가 아니라 '무슨 값인가'만 남는다."
  - 오답 (a) 피드백: "`double(5)`는 `5 + 5`가 아니라 `5 * 2 = 10`입니다. 그리고 `a = double(5) + double(5) = 10 + 10 = 20`. 호출이 두 번 나와도 각각 같은 값 `10`을 내므로 합은 `20`입니다 — 첫 호출만 `10`이고 다음이 다른 값이 되는 일은 순수 함수에선 절대 없습니다."
  - 오답 (c) 피드백: "`c = v + v`에서 `v`는 `double(5)`를 한 번 묶어둔 이름입니다. `let`은 값을 고정합니다(U1). `v`는 `10`이고 `v + v = 20`. 이름으로 묶든 식을 두 번 쓰든 결과가 같다는 게 핵심입니다."

- 세그먼트 2 요지: 참조 투명성이 깨지는 전형은 함수 안에 **숨은 효과**가 있을 때다. 아래 `logged`는 겉보기엔 "받은 값을 그대로 돌려주는 함수"지만, 부수적으로 화면에 찍는다. 그러면 `logged(7)`을 그 값 `7`로 치환하는 순간 **출력 한 줄이 사라진다** — 의미가 변한 것이므로 참조 투명하지 않다. (검증된 예제)

```gleam
import gleam/io
import gleam/int

fn square(x: Int) -> Int {
  x * x
}

fn logged(x: Int) -> Int {
  io.println("saw " <> int.to_string(x))
  x
}

pub fn main() -> Nil {
  let p = square(7) + square(7)
  let q = logged(7) + logged(7)
  io.println(int.to_string(p))
  io.println(int.to_string(q))
}
```

- 연습 2 (P8 `spot_bug`): 위 코드에서 "호출을 그 결과값으로 안전하게 치환할 수 있는" 함수는 어느 쪽이며, 그렇지 못한 쪽은 왜인가? (`square` / `logged` 중 참조 투명성을 깨는 것을 고르고 이유 선택)
  보기: (a) `square` — 곱셈은 비결정적이라서 (b) `logged` — `x`를 돌려주지만 부수적으로 `io.println` 효과를 내므로, 호출을 값으로 바꾸면 출력이 사라진다 (c) 둘 다 순수하므로 차이 없음 (d) `logged` — 반환 타입이 `Int`라서 — **정답 (b)**.
  - 정답 코멘터리: "실행해 보면 `saw 7`이 **두 번** 찍힌다. `logged(7)`을 `7`로 치환하면 그 두 줄이 증발한다 — 효과가 결과에 안 담겨 있기 때문. 그래서 효과 있는 호출은 '값으로 미룰 수 없다'."
  - 오답 (a) 피드백: "`square`는 순수합니다. `*`는 결정적입니다 — `square(7)`은 언제나 `49`. 곱셈이 비결정적인 일은 없습니다."
  - 오답 (c) 피드백: "둘은 다릅니다. 출력을 보면 `square` 쪽은 화면에 아무 흔적도 안 남기지만 `logged`는 호출마다 한 줄씩 찍습니다 — 그 흔적이 곧 부작용이고, 그게 치환을 막습니다."
  - 정직성 노트: Gleam은 이렇게 **부작용을 기본적으로 허용**한다(`logged`는 멀쩡히 컴파일된다). 효과의 유무를 타입으로 강제하지 않는다는 뜻 — 그 책임은 설계자에게 있다. 이 한계와 그 대처(효과를 값으로 미루기)는 ②에서 이어진다.

**예시 레슨 TU1-② 「Nil은 '아무것도 아님'이 아니다 — 효과의 신호, 그리고 효과를 값으로 미루기」**

- 세그먼트 1 요지: `io.println`의 반환 타입은 `Nil`이다. 초심자는 `Nil`을 "아무것도 안 함 / 무(無)"로 오해하기 쉽지만, 정반대다. `Nil`은 "이 함수는 **돌려줄 쓸모 있는 값이 없다 — 너는 이걸 효과 때문에 부른다**"라는 신호다. 즉 `Nil` 반환은 '함수가 한 일이 화면에 찍는 것뿐'이라는 표식이다. Gleam은 효과를 타입으로 숨기지 않으므로(IO 모나드 같은 게 없다), 이 `Nil`이 우리가 가진 거의 유일한 단서다. 그래서 `Nil`을 진짜 값처럼 쓰려 하면 컴파일러가 막는다. (의도적 컴파일 실패 예제)

```gleam
import gleam/io

pub fn shout(name: String) -> String {
  io.println(name)
}

pub fn main() -> Nil {
  io.println(shout("hi"))
}
```

  학습자에게 보여주는 **실제 컴파일러 출력**(검증됨; 줄 번호는 위 스니펫 그대로의 배치 기준 — `io.println(name)`은 4번째 줄):

```
error: Type mismatch
  ┌─ src/oracle.gleam:4:3
  │
4 │   io.println(name)
  │   ^^^^^^^^^^^^^^^^

The type of this returned value doesn't match the return type
annotation of this function.

Expected type:

    String

Found type:

    Nil
```

- 연습 1 (P4 `fix_error`): 위 `shout`는 컴파일되지 않는다. 에러를 읽고, `name`을 대문자로 외쳐 **문자열을 돌려주도록** 고쳐라(화면 출력은 호출하는 쪽의 책임으로 넘긴다). 구멍은 `shout` 본문.
  **정답**:
  ```gleam
  import gleam/string
  pub fn shout(name: String) -> String {
    string.uppercase(name) <> "!"
  }
  ```
  - 정답 코멘터리: "이제 `shout`는 순수 — 값을 *돌려주고*, 찍는 일은 `main`의 `io.println(shout(\"hi\"))`이 맡는다. '계산'과 '효과'를 분리한 것."
  - 오답 (`io.println(name) name` 식으로 끼워 맞추기) 피드백: "`io.println`을 한 줄 더 두고 그 아래 `name`을 둬도 타입은 맞지만, 그러면 `shout`는 다시 *부수적으로 찍는* 함수가 됩니다 — ①에서 본 `logged`와 같은 함정입니다. `Nil`은 '값 없음'이 아니라 '효과 때문에 부르는 함수'라는 신호이고, 그 효과를 함수 깊숙이 숨기는 대신 가장자리(여기선 `main`)로 밀어내는 게 관용입니다."
  - 정직성 노트: 다른 언어의 `IO String` 같은 효과 타입은 Gleam에 없다. Gleam에는 **타입클래스도 HKT도 없어서**(→ U14①) IO 모나드를 라이브러리로 흉내 내기도 어렵다. 대신 규율은 단순하다 — "값을 돌려주는 함수는 순수하게, 효과는 `Nil` 반환 함수로 따로, 효과 호출은 가장자리로".

- 세그먼트 2 요지: 그럼 효과를 "지금 당장 실행" 말고 "나중에 실행하도록 **값으로** 들고 다닐" 수는 없을까? 있다. 효과를 일으키는 코드를 `fn() { ... }` 안에 감싸면, 그건 *실행*이 아니라 *실행 설명서(thunk)*가 된다 — 호출하기 전까지 아무 효과도 안 난다. Gleam은 **eager 평가**라 인자는 호출 직전 평가되지만, `fn()`으로 감싸진 본문은 `()`로 부르기 전까지 잠든다. 이게 "효과를 데이터로 미루기"의 맛보기이고, 함수를 값으로 다루는 U7로 곧장 이어진다. (검증된 예제)

```gleam
import gleam/io

pub fn main() -> Nil {
  let action = fn() { io.println("BOOM") }
  io.println("before")
  action()
  action()
  io.println("after")
}
```

- 연습 2 (P1 `predict`): 위 코드의 출력 순서는?
  보기: (a) `before` / `after` (효과는 미뤄졌으니 `BOOM`은 안 찍힘) (b) `BOOM` / `before` / `BOOM` / `after` (c) `before` / `BOOM` / `BOOM` / `after` (d) `before` / `BOOM` / `after` — **정답 (c)**.
  - 정답 코멘터리: "`let action = fn() {...}`은 *정의*일 뿐 실행이 아니다 — 그래서 `before`가 먼저. 그 뒤 `action()`을 **두 번** 부르니 `BOOM`이 두 번. eager 평가는 '문장을 위에서 아래로 차례대로 실행'한다."
  - 오답 (a) 피드백: "`fn()`으로 감싸면 *정의 시점*엔 안 찍히는 게 맞습니다 — 하지만 `action()`이라고 `()`를 붙이는 순간 thunk를 깨워 실행합니다. 미룬 효과도 '부르면' 일어납니다. 두 번 불렀으니 두 번 났습니다."
  - 오답 (d) 피드백: "`action()`이 두 줄입니다. 함수 호출은 매번 본문을 새로 실행합니다(메모이제이션 같은 자동 캐싱은 없습니다). 두 번 부르면 두 번 `BOOM`."
  - 정직성 노트: 여기서 `action`은 인자 없는 `fn() -> Nil` 값이다. 부분 적용·자동 커링은 Gleam에 없으므로(→ U7/U14②), "인자를 덜 준 함수가 알아서 효과를 들고 다니는" 식의 마술은 없다. 효과를 미루려면 **명시적으로** `fn()`로 감싸야 한다.

> 보상 한 단락(왜 이걸 배우나): 함수가 순수하고 호출이 참조 투명하면 세 가지가 공짜로 따라온다. (1) **메모이제이션 안전** — `tax(200)`을 한 번 계산해 캐시에 박아두고 이후 호출을 그 캐시값으로 치환해도 의미가 안 변한다. (2) **테스트 용이** — `assert full_name(\"Ada\", \"Lovelace\") == \"Ada Lovelace\"` 한 줄로 끝, 환경 준비가 없다. (3) **재배열·병렬 안전** — 서로 의존 없는 순수 계산은 순서를 바꿔도 결과가 같다. 이 (3)이 바로 TU8(모노이드)에서 결합법칙이 "어디서부터 접어도 같다 → 분할·병렬해도 안전"으로 일반화되는 복선이다. 부작용을 가장자리로 밀고 핵심을 순수하게 유지하는 이유가 전부 여기 있다.

**방출 태그**: `theory:purity` `theory:referential-transparency` `theory:side-effect` `theory:hidden-effect` `theory:determinism` `theory:effects-as-values`

---

### TU2. 등식적 추론과 치환 모델 (Equational Reasoning & the Substitution Model) [TL1]

**레슨**: ① 프로그램을 등식으로 읽기 — `let`을 치환으로 펼치기(불변성이 안전하게 만든다, U1·TU1 연결) ② 리팩터링 = 의미 보존 재작성 — 파이프·캡처·`use` 디슈가링이 전부 등식 변환(U2·U7·U10), 그리고 부작용이 끼면 치환이 깨진다 ③ 구조적 귀납 — 구조적 재귀(U5)의 증명 짝: `length(append(xs, ys)) == length(xs) + length(ys)`를 귀납으로 논증하고 실행 가능한 프로퍼티로 검사.

**예시 레슨 TU2-① 「프로그램을 등식으로 읽기」**

- 세그먼트 1 요지: Gleam 코드는 명령의 나열이 아니라 **등식의 모음**으로 읽을 수 있다. `let name = expr`는 "이름 `name`은 `expr`과 *같다*"는 등식이고, 따라서 `name`이 나오는 자리에 `expr`을 **그대로 끼워 넣어도(치환, substitution) 의미가 변하지 않는다**. 이것이 가능한 *유일한* 이유는 U1·TU1에서 배운 **불변성**이다 — 한 번 정한 이름은 절대 다른 값으로 바뀌지 않으므로, 그 이름은 영원히 같은 정의를 가리킨다. (검증된 예제)

```gleam
import gleam/int
import gleam/io

pub fn price(qty: Int) -> Int {
  let unit = 30
  let subtotal = unit * qty
  let shipping = 5
  subtotal + shipping
}

pub fn main() -> Nil {
  // price(2) 를 손으로 펼치면:
  //   let unit = 30
  //   let subtotal = 30 * 2  == 60
  //   let shipping = 5
  //   60 + 5  == 65
  io.println(int.to_string(price(2)))
}
```

- 연습 1 (P1 `predict`): `price(2)`의 값은? 머릿속에서 `unit`을 `30`으로, `subtotal`을 `unit * qty`로, 다시 `30 * 2`로 한 단계씩 치환해 보세요.
  보기: (a) `65` (b) `60` (c) `35` (d) `70` — **정답 (a)**. 정답 코멘터리: "이렇게 이름을 정의로 한 칸씩 바꿔 끼우는 것이 **치환 모델**입니다. 각 줄을 등식으로 보면 계산은 그저 등식을 따라 항을 줄여 가는 일입니다."
  - 오답 (b) 피드백: "`shipping`(= 5)을 더하는 마지막 등식을 빠뜨렸습니다. 마지막 표현식 `subtotal + shipping`이 함수의 값이고, 이는 `60 + 5`로 치환됩니다."
  - 오답 (c) 피드백: "`unit * qty`를 `unit + qty`로 읽었습니다. `subtotal = 30 * 2 = 60`입니다. 치환할 때 연산자까지 정의 그대로 옮겨야 합니다."

- 세그먼트 2 요지: 치환이 안전한 까닭을 거꾸로 음미해 보자. 명령형 언어라면 `let` 사이에서 `unit`이 재대입되어 값이 바뀔 수 있고, 그러면 "이름 = 정의"라는 등식이 무너진다. Gleam에는 재대입이 없고(U1), 같은 이름의 재-`let`은 **새 바인딩(shadowing)** 일 뿐이다(이전 이름을 가리던 코드는 옛 등식을 그대로 유지한다, TU1). 그래서 어떤 이름이든 "그 줄의 정의"로 마음 놓고 바꿔 끼울 수 있다 — 이 성질을 **참조 투명성(referential transparency)** 이라 부른다.

- 연습 2 (P2 `mcq`): "`let`으로 이름 붙인 값은 코드 어디서나 그 정의로 치환해도 의미가 같다"가 Gleam에서 항상 성립하는 근본 이유로 가장 정확한 것은?
  보기: (a) Gleam이 모든 `let`을 상수로 인라인 최적화하기 때문 (b) 이름이 한 번 바인딩되면 다시 다른 값으로 변하지 않기 때문(불변성/참조 투명성) (c) Gleam이 자동으로 함수를 커링하기 때문 (d) 컴파일러가 타입을 추론하기 때문 — **정답 (b)**. 정답 코멘터리: "치환의 토대는 컴파일러 최적화가 아니라 **언어의 의미론적 불변식**입니다 — 값이 변하지 않으니 이름은 영원히 같은 정의를 뜻합니다."
  - 오답 (a) 피드백: "최적화는 *결과*이지 *근거*가 아닙니다. 옵티마이저가 없어도 등식은 참입니다. 안전성의 출처는 불변성입니다."
  - 오답 (c) 피드백: "Gleam에는 **자동 커링이 없습니다**(부분 적용은 캡처 `f(10, _)`로 명시 — U7/U14②). 커링과 치환 안전성은 무관합니다."

**예시 레슨 TU2-② 「리팩터링은 의미 보존 재작성이다」**

- 세그먼트 1 요지: 좋은 리팩터링이란 "보기 좋게 다시 쓰되 **값이 같음을 등식으로 보장**한 변환"이다. 사실 우리가 이미 쓰는 문법 설탕 대부분이 등식 변환이다. `x |> f` 는 정의상 `f(x)` 와 같고(U2), 캡처 `f(_, k)` 는 `fn(s) { f(s, k) }` 와 같으며(U7), `use a <- result.try(r)` 는 `result.try(r, fn(a) { …나머지… })` 와 같다(U10). 아래 네 갈래는 **글자만 다른 같은 계산**이며 `assert`로 서로 같음을 표본 검사한다. (검증된 예제)

```gleam
import gleam/string
import gleam/io

// 네 가지 표기는 모두 *같은 계산*을 적는 등식적으로 동등한 방법이다.
pub fn main() -> Nil {
  let name = "  lucy "

  // (1) 중첩 호출
  let a = string.append(string.uppercase(string.trim(name)), "!")
  // (2) 파이프: x |> f 는 정의상 f(x)
  let b = name |> string.trim |> string.uppercase |> string.append("!")
  // (3) 캡처: string.append(_, "!") 는 fn(s) { string.append(s, "!") } 의 설탕
  let shout = string.append(_, "!")
  let c = shout(string.uppercase(string.trim(name)))

  assert a == b
  assert b == c
  assert a == "LUCY!"
  io.println(a)
}
```

- 연습 1 (P6 `refactor`): 아래 `slow`를 **값을 바꾸지 않고** `list.map`을 한 번만 쓰도록 재작성하세요(map fusion: `map f (map g xs) == map (fn(x) { f(g(x)) }) xs`). 숨김 테스트는 무작위 리스트로 `slow(xs) == your_fast(xs)`를 검사합니다.

```gleam
import gleam/io
import gleam/int
import gleam/list

fn add1(x: Int) -> Int {
  x + 1
}

fn times2(x: Int) -> Int {
  x * 2
}

// 변경 전
pub fn slow(xs: List(Int)) -> List(Int) {
  xs |> list.map(add1) |> list.map(times2)
}

// 변경 후 (등식 보존): map f (map g xs) == map (fn x { f(g(x)) }) xs
pub fn fast(xs: List(Int)) -> List(Int) {
  xs |> list.map(fn(x) { times2(add1(x)) })
}

pub fn main() -> Nil {
  let xs = [1, 2, 3, 10]
  assert slow(xs) == fast(xs)
  assert slow([]) == fast([])
  io.println(slow(xs) |> list.map(int.to_string) |> string_join(", "))
}

fn string_join(parts: List(String), sep: String) -> String {
  case parts {
    [] -> ""
    [only] -> only
    [first, ..rest] -> first <> sep <> string_join(rest, sep)
  }
}
```

  **모범답**: `xs |> list.map(fn(x) { times2(add1(x)) })`. 정답 코멘터리: "두 번 순회하던 것을 한 번으로 줄이면서 결과는 **증명 가능하게 동일**합니다. 단, 이 map-fusion 등식은 List라는 *구체 타입*에서만 성립하는 것으로 다룹니다 — Gleam에는 **타입클래스도 HKT도 없어** '모든 Functor에 동작하는 map' 같은 단일 일반 함수를 쓸 수 없기 때문입니다(U14①: 혼란스러운 에러·컴파일 시간·런타임 비용을 이유로 의도적으로 배제)."
  - 오답 `xs |> list.map(fn(x) { add1(times2(x)) })` 피드백: "합성 순서를 뒤집었습니다. 원본은 `add1`을 *먼저* 적용하므로 안쪽이 `add1(x)`여야 합니다 — `times2(add1(x))`. 등식 보존 리팩터는 순서까지 보존해야 합니다."
  - 오답 `xs |> list.filter(fn(x) { times2(add1(x)) })` 피드백: "`filter`는 `Bool`을 받는데 `times2(add1(x))`는 `Int`라 컴파일되지 않습니다. 그리고 `filter`는 `map`과 다른 계산입니다 — 의미를 바꾸면 리팩터가 아닙니다."

- 세그먼트 2 요지: 치환과 등식 변환에는 **결정적 단서**가 하나 있다 — **부작용(effect)이 없어야** 한다. Gleam에는 예외도 뮤테이션도 없지만(불변·Result 모델), `io.println`처럼 화면 출력이라는 부작용을 갖는 표현식은 예외다. 효과가 있는 식을 이름으로 한 번 묶었다가 그 이름을 정의로 "펼치면" 효과가 일어나는 **횟수가 달라진다**. 아래에서 `named`는 `"hi"`를 한 번, 펼친 `inlined`는 두 번 출력한다 — 같은 텍스트인데 의미가 다르다. (검증된 예제)

```gleam
import gleam/io

// 부작용(effect)이 끼면 "let 을 펼치는" 치환이 의미를 바꾼다.
// io.println 은 Nil 을 반환하지만 *화면 출력*이라는 부작용을 갖는다.

// 버전 A: 한 번 이름 붙이고 두 번 사용
pub fn named() -> Nil {
  let logged = io.println("hi")
  let _ = logged
  let _ = logged
  Nil
}

// 버전 B: 그 이름을 정의로 "치환"해 두 곳에 펼침
pub fn inlined() -> Nil {
  let _ = io.println("hi")
  let _ = io.println("hi")
  Nil
}

pub fn main() -> Nil {
  io.println("--A (named, 펼치기 전)--")
  named()
  io.println("--B (inlined, 펼친 후)--")
  inlined()
}
```

- 연습 2 (P1 `predict`): 위 `main`의 전체 출력은? (`named`에서 `logged`를 정의로 치환하면 무슨 일이 생기는지 생각하세요.)
  보기: (a) `--A …` / `hi` / `--B …` / `hi`  (b) `--A …` / `hi` / `--B …` / `hi` / `hi`  (c) `--A …` / `hi` / `hi` / `--B …` / `hi` / `hi`  (d) 컴파일 에러 — **정답 (b)**. 정답 코멘터리: "`named`는 `io.println('hi')`를 **한 번** 실행해 `Nil`을 `logged`에 묶고, 이후엔 그 `Nil` 값을 두 번 들여다볼 뿐이라 출력은 한 번입니다. `inlined`는 효과식을 두 자리에 적었으니 두 번 출력됩니다. **즉 효과가 있으면 `let logged = io.println(…)`을 정의로 치환할 수 없습니다** — 등식적 추론의 전제(참조 투명성)가 깨지는 지점입니다(TU1 연결)."
  - 오답 (a) 피드백: "`inlined`에 `io.println('hi')`가 두 줄 있다는 점을 놓쳤습니다. eager 평가라 두 식 모두 호출 시점에 즉시 실행됩니다(게으름 없음 — 지연하려면 `fn() -> a` thunk)."
  - 오답 (c) 피드백: "`named`의 `let _ = logged`는 *이미 계산된 `Nil` 값*을 버리는 것이지 `io.println`을 다시 호출하는 게 아닙니다. 효과는 **이름을 바인딩하는 순간 한 번** 일어납니다(eager). 그래서 `named`의 출력은 'hi' 한 번뿐입니다."

**예시 레슨 TU2-③ 「구조적 귀납 — 재귀의 증명 짝」**

- 세그먼트 1 요지: U5의 구조적 재귀(`[]` 기저 + `[first, ..rest]` 단계)에는 **증명의 쌍둥이**가 있다 — **구조적 귀납(structural induction)**. 어떤 성질 `P(xs)`가 *모든* 리스트에서 성립함을 보이려면 두 가지만 보이면 된다: (기저) `P([])`가 성립한다; (귀납 단계) 임의의 `rest`에서 `P(rest)`를 *가정*하면 `P([first, ..rest])`도 성립한다. "빈 리스트에서 성립 ∧ 머리 하나 더 얹어도 보존 ⇒ 모든 리스트에서 성립." 재귀가 리스트를 한 머리씩 *벗기며* 내려가듯, 귀납은 한 머리씩 *얹으며* 성질을 끌어올린다. (검증된 예제)

```gleam
import gleam/io
import gleam/int
import gleam/list

// 손으로 쓴 length 와 append (U5 의 구조적 재귀)
pub fn length(xs: List(a)) -> Int {
  case xs {
    [] -> 0
    [_, ..rest] -> 1 + length(rest)
  }
}

pub fn append(xs: List(a), ys: List(a)) -> List(a) {
  case xs {
    [] -> ys
    [first, ..rest] -> [first, ..append(rest, ys)]
  }
}

// 정리: length(append(xs, ys)) == length(xs) + length(ys)
pub fn main() -> Nil {
  // 귀납의 표본 검사: 여러 입력에서 등식이 성립하는지 assert 로 확인
  let xs = [1, 2, 3]
  let ys = [4, 5]
  assert length(append(xs, ys)) == length(xs) + length(ys)
  assert length(append([], ys)) == length([]) + length(ys)
  assert length(append(xs, [])) == length(xs) + length([])

  io.println(int.to_string(length(append(xs, ys))))
  // 손으로 쓴 length 가 stdlib 와 일치
  assert length(xs) == list.length(xs)
}
```

- 연습 1 (P2 `mcq`): 정리 `length(append(xs, ys)) == length(xs) + length(ys)`를 `xs`에 대한 구조적 귀납으로 증명할 때, **귀납 단계**에서 `xs = [first, ..rest]`라 하자. `length(append([first, ..rest], ys))`를 `length`와 `append`의 *정의 등식*으로 한 단계 펼치면 무엇과 같은가? (정의: `append([f, ..r], ys) = [f, ..append(r, ys)]`, `length([_, ..t]) = 1 + length(t)`)
  보기: (a) `1 + length(append(rest, ys))` (b) `length(append(rest, ys))` (c) `1 + length(rest) + length(ys)` (d) `length(rest) + length(ys)` — **정답 (a)**. 정답 코멘터리: "두 정의를 차례로 치환합니다. 먼저 `append`로 `length([first, ..append(rest, ys)])`, 다시 `length`로 `1 + length(append(rest, ys))`. 그다음 **귀납 가설** `length(append(rest, ys)) == length(rest) + length(ys)`를 끼워 넣으면 `1 + length(rest) + length(ys) == length([first, ..rest]) + length(ys)`로 닫혀 증명이 완성됩니다. 한 단계 한 단계가 모두 **등식 치환**입니다(TU2① 연결)."
  - 오답 (c) 피드백: "그건 귀납 가설까지 적용한 *두 단계 뒤* 모습입니다. 문제는 정의로 **한 단계만** 펼친 결과를 물었습니다 — 아직 `append(rest, ys)`가 통째로 남아 있어야 합니다."
  - 오답 (b) 피드백: "`length([f, ..t]) = 1 + length(t)`의 `1 +`를 빠뜨렸습니다. 머리 하나가 길이에 정확히 1을 더한다는 게 이 단계의 핵심입니다."

- 세그먼트 2 요지: 손증명은 강력하지만 사람은 실수한다. 그래서 플랫폼은 정리를 **실행 가능한 프로퍼티**로 바꿔 표본 입력에서 `assert`로 반증을 찾는다 — 통과가 증명을 *대체*하진 않지만, 깨진 등식은 즉시 크래시로 드러난다(P5/P8의 토대). 아래는 그 프로퍼티 함수와 표본 검사 하니스다. (검증된 예제)

```gleam
import gleam/io
import gleam/int
import gleam/list

pub fn length(xs: List(a)) -> Int {
  case xs {
    [] -> 0
    [_, ..rest] -> 1 + length(rest)
  }
}

pub fn append(xs: List(a), ys: List(a)) -> List(a) {
  case xs {
    [] -> ys
    [first, ..rest] -> [first, ..append(rest, ys)]
  }
}

// 학습자가 작성할 프로퍼티 함수
pub fn check_length_append(xs: List(Int), ys: List(Int)) -> Bool {
  length(append(xs, ys)) == length(xs) + length(ys)
}

pub fn main() -> Nil {
  let samples = [
    #([], []),
    #([1], []),
    #([], [2, 3]),
    #([1, 2], [3, 4, 5]),
  ]
  list.each(samples, fn(pair) {
    let #(xs, ys) = pair
    assert check_length_append(xs, ys)
  })
  io.println("all samples hold: " <> int.to_string(list.length(samples)))
}
```

- 연습 2 (P8 `spot_bug`): 세 개발자가 `sum(xs) = case xs { [] -> 0; [first, ..rest] -> first + sum(rest) }`를 "등식 보존" 리팩터라며 다시 썼다고 주장한다. **법칙(원래와 같은 값)을 위반한** 버전을 고르세요.

```gleam
import gleam/io
import gleam/int
import gleam/list

// 후보 A: 등식 보존 리팩터 (sum 의 정의를 그대로 펼침)
pub fn sum_a(xs: List(Int)) -> Int {
  case xs {
    [] -> 0
    [first, ..rest] -> first + sum_a(rest)
  }
}

// 후보 B: list.fold 로 재작성 — 등식 보존?
pub fn sum_b(xs: List(Int)) -> Int {
  list.fold(xs, 0, fn(acc, x) { acc + x })
}

// 후보 C: "리팩터"라며 초기값을 1 로 바꿈 — 등식 위반!
pub fn sum_c(xs: List(Int)) -> Int {
  list.fold(xs, 1, fn(acc, x) { acc + x })
}

pub fn main() -> Nil {
  let xs = [1, 2, 3]
  assert sum_a(xs) == sum_b(xs)
  // C 는 깨진다: 6 vs 7
  io.println(int.to_string(sum_a(xs)))
  io.println(int.to_string(sum_c(xs)))
}
```

  보기: (a) `sum_a` (b) `sum_b` (c) `sum_c` — **정답 (c)**. 정답 코멘터리: "`sum_c`는 `fold`의 **초기값을 0에서 1로** 바꿔 모든 입력에서 답이 1만큼 커집니다 — `sum([])`이 0이 아니라 1이 되면서 기저 등식부터 깨집니다. 표본 `[1,2,3]`에서 `6 vs 7`로 `assert`가 즉시 반증을 잡아냅니다. `sum_b`는 손으로 쓴 재귀를 그대로 일반화한 fold(U8: '손으로 쓴 fold가 사실은 list.fold')로 **등식이 보존**됩니다."
  - 오답 (b) 피드백: "`list.fold(xs, 0, fn(acc, x) { acc + x })`는 정확히 같은 합을 냅니다. U8에서 손으로 쓴 누산 재귀(U6)가 사실은 `list.fold`였음을 떠올리세요 — 이름만 바뀐 같은 계산이라 법칙을 지킵니다."
  - 오답 (a) 피드백: "`sum_a`는 원본 정의를 글자 그대로 옮긴 것이라 같은 값입니다. 등식을 위반하려면 정의의 *수치적 의미*를 바꿔야 하는데, `sum_a`는 그러지 않았습니다."

**방출 태그**: `theory:equational-reasoning` `theory:substitution-model` `theory:substitution-unsound-with-effects` `theory:refactor-is-rewrite` `theory:structural-induction`

---

### TU3. 평가 전략: eager와 lazy (Evaluation Strategy: Eager vs Lazy) [TL1]

**레슨**: ① 환원과 평가 순서 — 식은 어떻게 값이 되는가 (applicative order = strict/eager, Gleam의 선택) ② 단락 평가(short-circuit) — `&&`/`||`·`bool.guard`가 언어 차원의 유일한 "지연 비슷한 것" ③ 게으름 흉내내기 — `fn() -> a` thunk로 평가 미루기, 그리고 eager가 놀라게 하는 순간(비싼/크래시 인자가 미리 평가됨)

이 유닛은 U14③(「게으름이 없다 — eager 평가와 gleam_yielder」)에서 *실용적으로* 마주친 사실 — "인자는 호출 전에 평가된다" — 을 **계산 모델 차원**에서 일반화한다. 식을 한 단계씩 환원(reduce)하는 두 가지 순서를 비교하고, Gleam이 왜 applicative order(eager)를 택했는지, 그리고 그 결과 무엇이 **불가능**한지(무한 시퀀스, 비용 없는 미평가 인자)를 정직하게 못박는다. 게으름을 원하면 언어가 주지 않으므로 *직접* thunk로 흉내내야 한다 — 이것이 U7의 함수 값이 단순한 "함수를 넘기기"를 넘어 **평가 제어 도구**라는 두 번째 의미를 얻는 지점이다.

**예시 레슨 TU3-① 「환원과 평가 순서」**

- 세그먼트 1 요지: 프로그램 실행이란 식을 더 단순한 식으로 **환원(reduction)**하는 과정이다. `square(2 + 3)`을 값으로 만드는 데는 두 길이 있다. **applicative order**(strict/eager): 인자를 *먼저* 값으로 환원하고(`2 + 3` → `5`) 그 다음 함수에 적용한다(`square(5)` → `25`). **normal order**(lazy): 함수를 *먼저* 적용하고(`square(2+3)` → `(2+3) * (2+3)`) 필요할 때 인자를 환원한다. Gleam은 **applicative order = eager**다. 즉 함수에 들어가기 전에 인자가 반드시 값이 되어 있다.

```gleam
import gleam/int

pub fn square(x: Int) -> Int {
  x * x
}

pub fn demo() -> Int {
  // eager: 2 + 3 이 먼저 5 로 환원된 뒤 square 에 들어간다
  square(2 + 3)
}
// demo() == 25,  int.to_string(demo()) == "25"
```

- 연습 1 (P1 `predict`, exact_output): 아래 코드의 stdout을 예측하라. `shout`은 자기 인자를 출력하고 그대로 돌려준다. `pick_first`은 두 번째 인자를 *쓰지 않는다*(`_b`).
```gleam
import gleam/io
import gleam/int

pub fn pick_first(a: Int, _b: Int) -> Int {
  a
}

pub fn shout(x: Int) -> Int {
  io.println("evaluated " <> int.to_string(x))
  x
}

pub fn main() -> Nil {
  let _ = pick_first(1, shout(99))
  Nil
}
```
  보기: (가) `evaluated 99` 한 줄 / (나) 아무것도 출력 안 함 / (다) `evaluated 99` 두 줄 — **정답 (가)**. 코멘터리: "`_b`로 무시하지만, eager 언어에서는 *함수 본문에 들어가기 전에* 모든 인자가 평가됩니다. `shout(99)`는 쓰이든 안 쓰이든 한 번 실행됩니다." 오답 (나) 피드백: "그건 normal order(lazy)의 답입니다. lazy라면 `_b`가 한 번도 쓰이지 않으니 `shout(99)`는 환원될 필요가 없어 출력이 없겠죠. 하지만 Gleam은 eager라 사용 여부와 무관하게 인자를 미리 평가합니다 — 이 차이가 이 유닛의 핵심입니다." 오답 (다) 피드백: "인자는 호출당 한 번만 평가됩니다. 두 번 찍히는 건 normal order가 인자를 본문 안에서 *여러 번* 환원할 때 생기는 현상인데, Gleam은 애초에 인자를 미리 한 번 값으로 만들어 둡니다."

- 세그먼트 2 요지: 두 순서의 차이는 성능 취향이 아니라 **종료성(termination)**의 문제이기도 하다 — 이론적으로 normal order는 더 많은 식을 종료시킨다(쓰이지 않는 인자가 무한 루프여도 결과가 나옴). Gleam이 eager를 택한 대가로, "쓰이지 않을 수도 있는 비싼/위험한 인자"를 그냥 넘기면 무조건 평가된다. 이 한계 위에서 Gleam이 제공하는 *유일한* 언어 차원의 예외가 다음 레슨의 단락 평가다. (eager는 Gleam의 다른 결핍들 — 자동 커링 없음, 타입클래스 없음, 예외 없음 — 과 같은 "예측 가능성 우선" 설계 철학의 한 줄기다. U14에서 본 그 일관성.)

- 연습 2 (P2 `mcq`): "normal order(lazy)가 applicative order(eager)보다 **항상** 더 효율적이다"는 주장은? 보기: (가) 참 — lazy는 안 쓰는 인자를 건너뛰니까 / (나) 거짓 — lazy는 미평가 식(thunk)을 만들고 관리하는 비용·메모리가 들고, 쓰이는 인자를 여러 번 마주치면 재평가될 수도 있다 / (다) 참 — lazy에는 단락 평가가 내장이라 — **정답 (나)**. 코멘터리: "lazy의 장점은 '종료성을 더 많이 보장하고 안 쓰는 건 안 한다'이지 '항상 빠르다'가 아닙니다. 미평가를 표현하려면 thunk라는 런타임 표현이 필요하고, 공유(sharing) 없이 구현하면 같은 인자를 재평가합니다. Gleam이 eager를 고른 이유 중 하나가 바로 이 예측 가능한 비용 — U14의 '런타임 비용' 논거와 같은 결입니다." 오답 (다) 피드백: "단락 평가는 lazy 언어의 전유물이 아닙니다. Gleam(eager)에도 `&&`/`||`의 단락이 있죠 — 다음 레슨 주제입니다."

**예시 레슨 TU3-③ 「게으름 흉내내기 — thunk」**

- 세그먼트 1 요지: Gleam은 게으름을 언어로 주지 않으니, 평가를 미루려면 식을 인자 없는 함수 `fn() -> a`(=**thunk**)로 감싸 넘긴다. thunk를 받은 쪽이 `()`로 *호출할 때만* 안의 식이 환원된다. U7의 함수 값이 여기서 두 번째 정체를 드러낸다 — "함수를 넘긴다"가 곧 "평가를 미룬다"다. 이것이 무한 시퀀스나 비싼 fallback을 stdlib만으로 다룰 때의 기본기다(진짜 무한 스트림은 언어/stdlib가 아니라 `gleam_yielder` 라이브러리 영역 — U14③에서 명시).

```gleam
import gleam/io
import gleam/int

// 두 번째 인자를 미사용. 단, 이제 thunk 라서 호출 전에는 평가되지 않는다.
pub fn pick_first_lazy(a: Int, _thunk: fn() -> Int) -> Int {
  a
}

pub fn shout(x: Int) -> Int {
  io.println("evaluated " <> int.to_string(x))
  x
}

pub fn main() -> Nil {
  // TU3-① 와 달리: shout(99) 가 thunk 안에 갇혀 있어 호출되지 않음 → 아무 출력 없음
  let _ = pick_first_lazy(1, fn() { shout(99) })
  io.println("done")
  Nil
}
// stdout: "done" 한 줄뿐
```

- 연습 1 (P1 `predict`, exact_output): 위 `main`의 stdout을 예측하라. 보기: (가) `evaluated 99` 다음 `done` / (나) `done` 한 줄 / (다) 아무것도 없음 — **정답 (나)**. 코멘터리: "`fn() { shout(99) }`는 *함수 값*일 뿐 호출이 아닙니다. eager 평가는 인자(=이 함수 값 자체)를 만들지만, 그 안의 `shout(99)`는 누군가 `thunk()`로 호출해야 환원됩니다. `pick_first_lazy`는 thunk를 무시하므로 영영 호출되지 않죠." 오답 (가) 피드백: "그건 thunk로 감싸기 *전* 버전(TU3-①)의 출력입니다. `shout(99)`를 직접 넘기면 eager라 즉시 평가되지만, `fn() { shout(99) }`로 감싸면 호출을 미룹니다 — 이 한 겹의 `fn()`이 eager 세계에서 게으름을 흉내내는 전부입니다." 오답 (다) 피드백: "`io.println(\"done\")`은 그대로 실행됩니다. 미뤄지는 건 thunk 안의 식뿐이에요."

- 세그먼트 2 요지: thunk를 안 씌우면 eager가 우리를 놀라게 한다 — **비싸거나 크래시할 수 있는 인자가 쓰이기도 전에 평가**된다. 가장 함정인 곳은 stdlib의 "기본값" 류 함수다. `bool.guard(when:, return:, otherwise:)`에서 `return`은 **즉시 평가되는 값**이고 `otherwise`만 thunk(`fn() -> a`)다. 그래서 `return`에 무거운 식을 직접 쓰면, 그 가지가 선택되지 않아도 인자로서 먼저 평가된다. 미평가 기본값을 원하면 두 가지를 모두 thunk로 받는 `bool.lazy_guard`, 또는 `option.lazy_unwrap`/`result.lazy_unwrap`을 쓴다. (정직성: 이런 `lazy_*` 변종이 *함수마다 따로* 존재하는 이유가 바로 Gleam엔 HKT·타입클래스가 없어 "모든 게으른 기본값에 동작하는 단일 일반 함수"를 쓸 수 없기 때문이다 — U14①의 직접적 귀결.)

```gleam
import gleam/io
import gleam/int
import gleam/bool

pub fn heavy(tag: String) -> Int {
  io.println("heavy " <> tag)
  100
}

pub fn main() -> Nil {
  // when: False 라 'otherwise' 가 선택되지만,
  // 'return: heavy("R")' 는 인자라서 호출 전에 이미 평가된다 (eager 함정!)
  let r =
    bool.guard(when: False, return: heavy("R"), otherwise: fn() { heavy("O") })
  io.println("r=" <> int.to_string(r))
  Nil
}
// stdout: "heavy R" → "heavy O" → "r=100"
```

- 연습 2 (P8 `spot_bug`): 아래 세 코드는 모두 "캐시에 값이 있으면 그걸, 없으면 비싼 `recompute()`를 쓰기"를 의도한다. **불필요하게 `recompute()`를 항상 실행하는** 비관용적 코드를 고르라.
```gleam
import gleam/option.{type Option}

// (A)
pub fn get_a(cache: Option(Int)) -> Int {
  option.lazy_unwrap(cache, or: fn() { recompute() })
}

// (B)
pub fn get_b(cache: Option(Int)) -> Int {
  option.unwrap(cache, or: recompute())
}

// (C)
pub fn get_c(cache: Option(Int)) -> Int {
  case cache {
    option.Some(v) -> v
    option.None -> recompute()
  }
}

pub fn recompute() -> Int {
  // ...비싼 계산...
  0
}
```
  **정답 (B)**. 코멘터리: "`option.unwrap`의 기본값 `or:`는 **eager 값** 인자라, `Some(v)`로 캐시가 채워져 있어도 `recompute()`가 인자로서 먼저 실행됩니다. (A)는 `lazy_unwrap`이 기본값을 thunk `fn() -> a`로 받아 `None`일 때만 호출하고, (C)는 `case`로 `None` 가지에서만 호출하므로 둘 다 관용적입니다." 오답 (A) 선택 피드백: "(A)의 `fn() { recompute() }`는 *호출이 아니라 thunk*입니다. `lazy_unwrap`은 `None`일 때만 그 thunk를 부르니 캐시 적중 시 `recompute()`는 실행되지 않습니다 — 정확히 우리가 원하는 동작이에요." 오답 (C) 선택 피드백: "(C)는 가장 솔직한 형태입니다. `case`의 가지는 선택될 때만 평가되므로(분기 자체가 일종의 단락), `None`일 때만 `recompute()`가 돕니다. `lazy_unwrap`은 사실 이 `case`를 한 함수로 포장한 것."

**방출 태그**: `theory:eager-vs-lazy` `theory:evaluation-order` `theory:short-circuit` `theory:eager-eval-surprise` `theory:thunk` `theory:normal-order-termination`

---

> ### 이론 레벨 TL2 — 타입의 대수

### TU4. 대수적 데이터 타입의 대수 (The Algebra of Algebraic Data Types) [TL2]

**레슨**: ① 타입은 값들의 *집합*이다 — 카디널리티 세기 (Bool=2, Nil=1, void=0) ② 곱 #(a,b)·레코드 = |a|×|b|, 합(variants) = |a|+|b| — `Option(a)=|a|+1`, `Result(a,e)=|a|+|e|` ③ 함수 타입 `fn(a)->b` = |b|^|a|, "대수적"인 이유(+·×·^ 의 법칙이 타입에 대응 — TU5 복선)

> U4에서 손으로 짠 `pub type Shape { Circle(..) Rectangle(..) }`와 U11의 제네릭 `Box(a)`·`#(a, a)`는 사실 전부 *대수식*이었다. 이 유닛은 "왜 이것을 **대수적** 데이터 타입(ADT)이라 부르는가"에 답한다. **정직성 노트**: Gleam에는 타입클래스도 HKT도 없으므로(공식 FAQ: 혼란스러운 에러·컴파일 시간·런타임 비용 — 실용 U14①) 여기서 배우는 "대수"는 *컴파일러가 강제하는 일반 기계*가 아니라 **타입을 읽고 셈하는 사고 도구**다. "모든 곱 타입에 동작하는 단일 일반 함수" 같은 건 쓸 수 없다. 셈은 사람이 한다.

**예시 레슨 TU4-① 「타입은 값들의 집합 — 카디널리티 세기」**

- 세그먼트 1 요지: 한 타입을 "그 타입이 가질 수 있는 값들의 *집합*"으로 보면, 각 타입에는 **카디널리티**(원소 개수, |T|로 표기)가 붙는다. `Bool`은 `{True, False}` 두 개라 |Bool|=2. 생성자 없는 variant들의 합 타입(enum)은 variant 개수만큼이다. (검증된 예제)

```gleam
pub type Direction {
  North
  South
  East
  West
}
// |Direction| = 4  (North, South, East, West — 다른 값은 존재 불가)
```

- 연습 1 (P1 `predict`): `Direction`의 모든 값을 한 리스트에 빠짐없이 모은 뒤 길이를 출력한다. 무엇이 찍히는가?
```gleam
import gleam/io
import gleam/list
import gleam/int

pub type Direction {
  North
  South
  East
  West
}

pub fn main() -> Nil {
  // List(Direction) 자체는 println 불가 → length만 찍어 카디널리티를 본다.
  io.println(int.to_string(list.length([North, South, East, West])))
}
```
  보기: `2` / `4` / `무한` — **정답 (4)**. 정답 코멘터리: "한 enum의 카디널리티 = variant 개수. `[North, South, East, West]`는 가능한 값을 *전부* 적은 것이라 길이 4가 곧 |Direction|. 타입을 '가능한 값들의 집합'으로 읽는 첫 근육입니다." 오답 (무한) 피드백: "Direction에는 North/South/East/West 외의 값이 *표현 자체로* 불가능합니다 — `Int`처럼 무한하지 않아요. ADT의 핵심은 '가능한 상태를 유한하게 봉인'하는 것이고, 그 개수가 곧 카디널리티입니다. U4의 exhaustiveness 검사가 가능한 이유도 바로 이 유한성 덕입니다." (채점은 위 실행 출력 골든 스냅샷 `4`에 고정 — exact_output.)

- 세그먼트 2 요지: 두 극단을 못 박자. **`Nil`은 카디널리티 1**이다 — 값이 정확히 하나(`Nil`)뿐이라 "아무 정보도 없음"을 뜻하는 unit 타입. 반대로 **생성자가 하나도 없는 `pub type Void`는 카디널리티 0**이다 — *어떤 값도 만들 수 없다*. `Nil`을 0으로 착각하지 말 것: 0은 값이 없는 것이고, 1은 "값이 딱 하나"라 선택지가 없는 것이다. void 타입을 만들려 하면 컴파일러가 막는다. (검증된 예제 — 의도적 컴파일 실패)

```gleam
pub type Void

pub fn impossible() -> Void {
  Void
}
```

  실제 컴파일러 출력(검증됨)을 그대로 보여준다:

```
error: Unknown variable
  ┌─ src/main.gleam:5:3
  │
5 │   Void
  │   ^^^^

`Void` is a type, it cannot be used as a value.
```

- 연습 2 (P2 `mcq`): 다음 중 카디널리티가 **1**인 타입은?
  보기: (a) `Bool` (b) `Nil` (c) `pub type Void`(생성자 없음) (d) `Int` — **정답 (b) `Nil`**. 정답 코멘터리: "`Nil`은 값이 딱 하나(`Nil`)뿐 — |Nil|=1. '정보 0비트'를 담는 자리." 오답 (c) 피드백: "그건 카디널리티 **0**입니다(void). 생성자가 없으니 값을 *하나도* 만들 수 없어요 — 방금 본 `Void` 컴파일 에러가 그 증거입니다. 0(값 없음)과 1(값이 정확히 하나)은 전혀 다릅니다. 이 혼동은 TU5의 0·1 항등원 논의에서 다시 다룹니다."

**예시 레슨 TU4-② 「곱·합·함수 — 더하고, 곱하고, 거듭제곱하기」**

- 세그먼트 1 요지: 곱 타입(`#(a, b)` 또는 모든 필드를 가진 레코드)의 값 하나는 "`a` 하나 **그리고** `b` 하나"다. 가능한 조합은 |a|×|b|개 — 그래서 **곱**이다. 합 타입(여러 variant)의 값은 "이 variant **또는** 저 variant"라 |a|+|b|개 — 그래서 **합**이다. U11의 `#(a, a)`가 곱이었고, U4의 variant 나열이 합이었다. (검증된 예제)

```gleam
pub type Light {
  Off
  On(brightness: Bool)
}
// |Light| = |Off| + |On(Bool)| = 1 + 2 = 3
// 모든 값 열거:  Off, On(False), On(True)

pub type Pair2 {
  Pair2(a: Bool, b: Bool)
}
// |Pair2| = |Bool| × |Bool| = 2 × 2 = 4
```

- 연습 1 (P1 `predict`): `Option(Bool)`의 값을 빠짐없이 한 리스트에 모은 뒤 길이를 출력한다. 무엇이 찍히는가?
```gleam
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/int

pub fn all_option_bool() -> List(Option(Bool)) {
  [None, Some(False), Some(True)]
}

pub fn main() -> Nil {
  io.println(int.to_string(list.length(all_option_bool())))
}
```
  보기: `2` / `3` / `4` — **정답 (3)**. 정답 코멘터리: "`Option(a) = None | Some(a)`는 합 타입이라 |Option(a)| = 1 + |a|. `Option(Bool)` = 1 + 2 = 3 (`None`, `Some(False)`, `Some(True)`). 같은 공식으로 `Result(a, e)` = |a| + |e|입니다." 오답 (4) 피드백: "4는 `Result(Bool, Bool)`(=2+2)이나 `#(Bool, Bool)`(=2×2)의 답입니다. `Option`은 한쪽에만 `Some`이 값을 싣고 `None`은 값 0개를 더하므로 1+2=3이에요. 합이지 곱이 아닙니다 — `None`은 '`Bool` 하나 *그리고*'가 아니라 '값 없는 갈래'."

- 세그먼트 2 요지: 함수 타입 `fn(a) -> b`의 값 하나는 "정의역의 *각* 입력마다 출력을 하나씩 고른 표"다. 입력이 |a|개, 각각 |b|가지 출력 → 가능한 함수는 **|b|^|a|개** (밑이 출력 |b|, 지수가 입력 |a|). 그래서 합·곱·**거듭제곱**까지 갖춰 "타입의 대수"가 완성된다. **정직성 노트**: 이 셈은 *전역(total)이며 순수한* 함수 기준이다. Gleam의 함수 타입 시그니처는 전역·순수를 **강제하지 않는다** — `fn(Bool) -> Bool` 시그니처를 가진 함수가 `panic`/`todo`로 중단하거나, 무한 재귀로 발산하거나, 부수효과(`io.*`)를 일으켜도 *똑같이 타입 검사를 통과한다*(핀 1.17.0에서 네 변종 모두 컴파일 확인). 따라서 |b|^|a|가 정확히 맞는 것은 *추상적 전역·순수 함수 집합*에서이고, 실제 Gleam 코드는 그 부분집합을 **컨벤션으로 약속**할 뿐 — 컴파일러가 보장하는 게 아니다(실용 U13 `let assert`·`panic` 단서와 연결). 열거하는 네 함수 자체는 모두 전역·순수라 |fn(Bool)->Bool|=4 라는 수치는 정확하다. 또한 "임의의 펑터/모나드에 동작하는 단일 일반 함수"는 HKT가 없어 못 쓴다 — 대수는 *읽기* 도구이지 디스패치 기계가 아니다(실용 U14①과 연결). (검증된 예제)

```gleam
import gleam/io
import gleam/list
import gleam/int

// 전역·순수인 fn(Bool) -> Bool 은 정확히 2^2 = 4개. 그 넷을 전부 열거한다.
// 주의: panic/todo·무한재귀 발산·io.* 부수효과를 끼우면 같은 시그니처라도
//       이 4개 밖의 '함수값'이 되지만(셋 다 컴파일은 통과), 카디널리티 셈은
//       전역·순수 함수만 친다 — 비전체·비순수는 셈에서 제외.
pub fn all_bool_functions() -> List(fn(Bool) -> Bool) {
  [
    fn(_b) { False },
    fn(b) { b },
    fn(b) { !b },
    fn(_b) { True },
  ]
}

pub fn main() -> Nil {
  let fns = all_bool_functions()
  assert list.length(fns) == 4
  io.println(int.to_string(list.length(fns)))
}
```

- 연습 2 (P8 `spot_bug`): 세 학생이 `fn(Direction) -> Bool`의 값 개수를 셌다. *틀린* 풀이를 고르라. (`|Direction|=4`, `|Bool|=2`)
  - (A) "|Bool|^|Direction| = 2^4 = **16**개."
  - (B) "각 방향마다 True/False를 독립으로 고르니 2×2×2×2 = **16**개."
  - (C) "정의역이 4개, 공역이 2개니 |Direction|^|Bool| = 4^2 = **16**개."
  **정답: (C)가 틀렸다.** 정답 코멘터리: "공식은 |b|^|a| = (출력)^(입력) = 2^4입니다. (C)는 밑과 지수를 뒤집었어요 — 여기선 우연히 답이 같지만 `fn(3원소) -> Bool`이면 2^3=**8**(맞음) vs 3^2=9(틀림)로 갈라집니다. (A)는 공식 그대로, (B)는 그 거듭제곱을 곱으로 펼친 같은 셈입니다." 오답으로 (A)나 (B)를 고른 경우 피드백: "(A)·(B)는 둘 다 옳습니다. (B)는 (A)의 2^4를 '입력 4개 각각 출력 2지 → 곱'으로 풀어 쓴 것일 뿐 — 거듭제곱이 곧 반복된 곱이라는 TU5의 복선이에요. 밑·지수를 뒤집은 (C)가 함정입니다. 그리고 이 셈도 §2 정직성 노트대로 전역·순수 함수에 한합니다."

**방출 태그**: `theory:adt-algebra` `theory:cardinality` `theory:cardinality-miscount` `theory:sum-product-types` `theory:unit-void-types`
<!-- 태그 네임스페이스 메모(트랙 레지스트리 확정 전 임시): theory:cardinality 는 concept 부류,
     theory:cardinality-miscount 는 tricky(함정) 부류로 의도적으로 분리 운용한다. 둘 다 이 유닛이
     방출하므로 두 슬러그를 emittedTags 에 모두 명시 등록해 빌드 시 미등록-태그 거부를 피한다.
     theory: 트랙 레지스트리가 repo에 생기면 [concept]/[tricky] 섹션에 각각 옮겨 등록할 것. -->

---

### TU5. 동형과 데이터 모델링 (Isomorphism & Data Modelling) [TL2]

**레슨**: ① 동형이란 무엇인가 — 카디널리티 같음 + 무손실 양방향 변환(`to`/`from`, 왕복 항등 `to∘from=id`·`from∘to=id`) ② 카탈로그 — `Result(a, Nil) ≅ Option(a)`, `#(a, Nil) ≅ a`, 커링 동형 `fn(#(a,b))->c ≅ fn(a,b)->c` ③ 카디널리티로 모델링하기 — make-illegal-states-unrepresentable과 가짜 동형(왕복 항등이 깨지는 손실 변환)

TU4에서 우리는 타입을 **개수(카디널리티)** 로 읽는 법을 배웠다(`Bool`=2, `#(Bool, Bool)`=4, 합타입=덧셈, 곱타입=곱셈). 이번 유닛은 그 "개수"가 무엇을 뜻하는지 끝까지 밀어붙인다: **카디널리티가 같고, 정보를 잃지 않고 왕복할 수 있으면 두 타입은 같은 것이다 — 표현만 다를 뿐**. 이것이 동형(isomorphism)이다. 실용 트랙 U9에서 `Option`과 `Result(a, Nil)`을 따로 배웠고, U12에서 "잘못된 상태를 표현 불가능하게(make-illegal-states-unrepresentable)" 만드는 opaque 패턴을 손으로 익혔다 — 이번 유닛은 그 둘이 사실 **같은 한 가지 원리**(정보량 = 카디널리티)의 두 얼굴임을 드러낸다.

**예시 레슨 TU5-① 「동형이란 무엇인가」**

- 세그먼트 1 요지: 두 타입 `A`, `B`가 **동형**(`A ≅ B`)이라는 것은, 변환쌍 `to : A -> B`와 `from : B -> A`가 존재하여 **양방향 왕복이 제자리로 돌아온다**는 뜻이다 — `from(to(a)) = a` (모든 `a`)이고 `to(from(b)) = b` (모든 `b`). 둘 중 한쪽만 성립하면 동형이 아니다(그건 나중에 볼 "가짜 동형"). U9에서 따로 배운 `Option(a)`와 `Result(a, Nil)`이 첫 사례다: `Some ↔ Ok`, `None ↔ Error(Nil)`로 1:1 대응되고, 카디널리티도 둘 다 `a의 개수 + 1`로 같다. (검증된 예제)

```gleam
import gleam/io
import gleam/option.{type Option, None, Some}

pub fn result_to_option(r: Result(a, Nil)) -> Option(a) {
  case r {
    Ok(x) -> Some(x)
    Error(Nil) -> None
  }
}

pub fn option_to_result(o: Option(a)) -> Result(a, Nil) {
  case o {
    Some(x) -> Ok(x)
    None -> Error(Nil)
  }
}

pub fn main() -> Nil {
  // from ∘ to = id  과  to ∘ from = id  를 표본으로 단언한다
  assert option_to_result(result_to_option(Ok(7))) == Ok(7)
  assert option_to_result(result_to_option(Error(Nil))) == Error(Nil)
  assert result_to_option(option_to_result(Some(7))) == Some(7)
  assert result_to_option(option_to_result(None)) == None
  io.println("iso ok")
}
```

- 연습 1 (P1 `predict`): 위 `main`을 실행하면 무엇이 출력되는가? 보기: `iso ok` / (크래시 — assert 실패) / (출력 없음) — **정답 `iso ok`**. 정답 코멘터리: "네 개의 `assert`가 모두 통과했다는 뜻 — 즉 `Ok(7)`을 `Option`으로 갔다가 돌아오면 여전히 `Ok(7)`이고, 반대 방향도 마찬가지. 이게 왕복 항등이 표본 위에서 성립함을 *실행 가능한 프로퍼티*로 본 것입니다(법칙은 코드로 검사할 수 있다 — TU 트랙 내내 반복되는 주제)." 오답 (크래시) 피드백: "`assert`는 식이 `False`일 때만 크래시합니다. `option_to_result(result_to_option(Ok(7)))`은 `Ok(7) -> Some(7) -> Ok(7)`로 제자리에 돌아오므로 `== Ok(7)`은 `True` — 크래시하지 않습니다. 이 '제자리로 돌아옴'이 바로 동형의 정의입니다."
- 세그먼트 2 요지: 동형의 핵심 직관은 **"표현은 달라도 정보량이 같다"** 이다. `Option(Int)`로 적든 `Result(Int, Nil)`로 적든, 담을 수 있는 서로 다른 값의 *개수*는 정확히 같다(둘 다 무한한 정수 + "없음" 한 칸). 표현을 바꾸는 것은 정보를 더하거나 버리지 않는다 — 그래서 stdlib가 `Result(a, Nil)`을 즐겨 쓰면서도 우리가 `Option`으로 자유롭게 옮겨 적을 수 있는 것이다. **정직성**: 만약 Gleam에 타입클래스가 있었다면 "모든 동형을 한 줄로 표현하는 일반 `Iso(a, b)` 인터페이스"를 만들었겠지만, Gleam엔 타입클래스도 HKT도 없으므로 동형은 *구체 타입쌍마다 `to`/`from` 함수를 직접 적어 알아보는 패턴*일 뿐이다(U14① 연결: "혼란스러운 에러·컴파일 시간·런타임 비용" 때문에 의도적으로 뺐다).
- 연습 2 (P5 `write_fn`): `safe_head`가 `Option(Int)`을 반환하도록 작성하라 — `[]`면 `None`, `[first, ..]`면 `Some(first)`. (숨김 테스트: `safe_head([5, 6]) == Some(5)`, `safe_head([]) == None`. 추가로 채점기는 `result_to_option`을 거쳐 동형 파트너 `Result(Int, Nil)`로도 같은 결과가 나오는지 확인한다.) 시작 코드:

```gleam
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/int

pub fn safe_head(xs: List(Int)) -> Option(Int) {
  case xs {
    [] -> None
    [first, ..] -> Some(first)
  }
}

pub fn main() -> Nil {
  let r = case safe_head([5, 6]) {
    Some(x) -> int.to_string(x)
    None -> "none"
  }
  io.println(r)
}
```

  정답 코멘터리: "방금 적은 `safe_head`는 `list.first`(이것은 `Result(a, Nil)`을 반환)의 동형 파트너입니다 — 같은 정보를 `Option`으로 적었을 뿐. 어느 쪽을 쓸지는 정보량이 아니라 *읽는 사람에게 주는 신호*('없음이 정상'이면 Option, '실패'면 Result, U9-④)의 문제입니다." 흔한 오답 — `Some(first)`를 `Ok(first)`로 적음 → Type mismatch(`Option`을 반환해야 하는데 `Result`를 줌): "동형이라고 해서 *같은 타입*인 것은 아닙니다. 정보량이 같을 뿐, 컴파일러에게는 엄연히 다른 타입이라 `to`/`from`을 명시적으로 거쳐야 합니다."

**예시 레슨 TU5-③ 「카디널리티로 모델링하기」**

- 세그먼트 1 요지: 동형의 실전 무기화가 **make-illegal-states-unrepresentable**(U12-③의 재방문)이다. 절차는 단순하다 — (1) 표현하려는 *정당한 상태의 개수*를 세고, (2) 타입의 카디널리티가 정확히 그 수가 되게 만든다. 예: 네트워크 연결을 `#(Bool, Bool)`("연결 시도 중?", "연결됨?")로 적으면 카디널리티는 `2 × 2 = 4`지만, 정당한 상태는 셋뿐이다(끊김 / 시도 중 / 연결됨). 4번째 `#(True, True)`("시도 중이면서 동시에 연결됨")는 의미 없는데도 *표현 가능*하다 — 카디널리티가 정당한 상태 수보다 크면, 그 초과분만큼 버그가 들어올 문이 열린다. 컴파일러의 exhaustiveness가 그 초과 카디널리티를 정직하게 드러낸다. (검증된 예제 — 일부러 컴파일 실패)

```gleam
import gleam/io

// 연결을 #(Bool, Bool)로 모델링하면 의미 없는 4번째 상태까지
// 다뤄야 한다. exhaustiveness 검사가 초과 카디널리티를 폭로한다.
pub fn describe(state: #(Bool, Bool)) -> String {
  case state {
    #(False, False) -> "off"
    #(True, False) -> "..."
    #(False, True) -> "on"
  }
}

pub fn main() -> Nil {
  io.println(describe(#(False, True)))
}
```

- 연습 1 (P1 `predict`): 위 코드는 컴파일될까, 안 될까? 컴파일된다면 출력은? 보기: `on` 출력 / 컴파일 에러(Inexhaustive patterns) / 런타임 크래시 — **정답: 컴파일 에러(Inexhaustive patterns)**. 실제 컴파일러 출력(검증됨):

```
error: Inexhaustive patterns

The missing patterns are:

    #(True, True)
```

  정답 코멘터리: "컴파일러가 `#(True, True)`를 빠뜨렸다고 정확히 짚어줍니다. 이 '빠진 한 칸'이 바로 `#(Bool, Bool)`의 카디널리티 4 중 정당하지 않은 1입니다 — 타입이 현실보다 한 칸 *큰* 것이죠." 오답 (`on` 출력) 피드백: "case가 네 경우 중 셋만 다루므로 Gleam은 *컴파일 자체를 거부*합니다(early return도 없고, '나머지는 알아서' 같은 암묵적 처리도 없음). 빈 칸을 `_ -> ...`로 메우거나 — 더 나은 방법은, 애초에 카디널리티가 3인 타입으로 바꿔 그 칸이 존재하지 못하게 하는 것입니다."
- 세그먼트 2 요지: 해법은 카디널리티 3짜리 타입, 즉 3-variant 합타입으로 옮기는 것이다 — `#(Bool, Bool)`(4)에서 정당한 3상태만 남긴 `Connection`(3)으로. 이제 `#(True, True)`라는 상태는 *타입에 존재하지 않으므로* 다룰 필요도, 다룰 수도 없다(U12 "표현 불가능하게"의 정확한 의미). (검증된 예제)

```gleam
import gleam/io

pub type Connection {
  Disconnected
  Connecting
  Connected
}

pub fn describe(c: Connection) -> String {
  case c {
    Disconnected -> "off"
    Connecting -> "..."
    Connected -> "on"
  }
}

pub fn main() -> Nil {
  assert describe(Disconnected) == "off"
  assert describe(Connecting) == "..."
  assert describe(Connected) == "on"
  io.println(describe(Connecting))
}
```

- 세그먼트 3 요지(가짜 동형 주의보): "카디널리티가 같다"는 동형의 *필요조건일 뿐 충분조건이 아니다*. 왕복 항등까지 성립해야 진짜 동형이다. 흔한 함정: `Bool`(2)과 "0 또는 1인 Int"를 동형이라 착각하기 — `bool_to_int`은 멀쩡하지만, 그 짝으로 흔히 쓰는 `int_to_bool(n) = n != 0`은 *모든 Int를 받아들인다*. 그래서 `bool_to_int(int_to_bool(7)) = 1 ≠ 7` — Int 쪽에서 출발한 왕복이 제자리로 안 돌아온다. 이건 **손실 변환**이고, 동형이 아니라 한 방향(`Bool -> Int`)만 무손실인 *단사(injection)* 일 뿐이다. (검증된 예제 — 가짜 동형 시연)

```gleam
import gleam/io
import gleam/bool

pub fn bool_to_int(b: Bool) -> Int {
  case b {
    True -> 1
    False -> 0
  }
}

pub fn int_to_bool(n: Int) -> Bool {
  n != 0
}

pub fn main() -> Nil {
  // bool_to_int(int_to_bool(7)) 는 1 — 7로 돌아오지 않는다. 항등 깨짐!
  assert bool_to_int(int_to_bool(7)) == 1
  assert int_to_bool(bool_to_int(True)) == True
  io.println(bool.to_string(int_to_bool(7)))
}
```

- 연습 2 (P8 `spot_bug`): 네 개의 "`A ≅ B` 동형이다"라는 주장 중 **틀린(가짜 동형) 것**을 고르라. 보기: (가) `Result(a, Nil) ≅ Option(a)` (`Ok↔Some`, `Error(Nil)↔None`) / (나) `#(a, Nil) ≅ a` (`#(x, Nil)↔x`) / (다) `Bool ≅ Int` (`bool_to_int` / `int_to_bool(n)=n != 0`) / (라) `fn(#(a, b)) -> c ≅ fn(a, b) -> c` (uncurry/curry) — **정답: (다)**. 정답 코멘터리: "(다)만 왕복 항등이 깨집니다: `int_to_bool`이 `7`, `2`, `99`를 전부 `True`로 뭉개므로 `bool_to_int ∘ int_to_bool ≠ id`. 카디널리티부터가 다르죠 — `Bool`은 2, `Int`는 (사실상) 무한. 카디널리티가 다르면 애초에 동형일 수 없습니다." 오답 (나)를 고름 피드백: "(나)는 진짜 동형입니다. `Nil`은 카디널리티 1짜리 타입이라 `#(a, Nil)`의 카디널리티는 `a의 개수 × 1 = a의 개수` — `a`와 똑같습니다. `Nil`은 곱셈의 1과 같아서(TU4의 대수 규칙) 정보를 전혀 더하지 않죠. `#(x, Nil) ↔ x` 왕복은 완벽히 제자리입니다." 오답 (라)를 고름 피드백: "(라)도 진짜 동형입니다. Gleam엔 **자동 커링이 없지만**(U14② — `add(10)`은 부분 적용이 아니라 인자 부족 에러, 부분 적용은 캡처 `add(10, _)`로 명시), 두 함수 *모양* 사이의 무손실 변환쌍(`uncurry`/`curry`)은 직접 적을 수 있습니다. '동형이 존재한다'와 '언어가 자동으로 변환해 준다'는 별개입니다 — Gleam은 전자만 인정하고 후자는 명시를 요구합니다."

**방출 태그**: `theory:type-isomorphism` `theory:cardinality-modelling` `theory:false-isomorphism`

---

### TU6. 타입과 명제: 커리-하워드와 파라메트리시티 (Curry–Howard & Parametricity (a taste)) [TL2]

**선수**: TU4, TU5, U11. *(고급 맛보기 유닛 — 일부 연습은 SRS 등록 제외로 부담 조절.)*

**레슨**: ① 타입은 명제, 값은 증명 — 커리-하워드 사전(a×b↔∧, a+b↔∨, a→b↔함의, Nil(1)↔참, void(0)↔거짓) ② 시그니처가 구현을 묶는다 — 파라메트리시티와 공짜 정리(그리고 "순수·전체라면" 단서)

**예시 레슨 TU6-① 「타입은 명제, 값은 증명」**

- 세그먼트 1 요지: TU5에서 본 곱타입·합타입에 두 번째 독해가 있다. 타입을 **명제**로, 그 타입의 값을 그 명제의 **증명**으로 읽는 것 — 커리-하워드 대응이다. 사전은 이렇다: 곱타입 `#(a, b)`(또는 `And(a, b)`)는 "a 이고 b"(∧), 합타입은 "a 이거나 b"(∨), 함수 타입 `fn(a) -> b`는 함의 "a이면 b". "그 타입의 값을 *만들 수 있다*"가 곧 "그 명제를 *증명할 수 있다*"이다. 예컨대 `And(a, b)`에서 좌변을 꺼내는 `proj_left`는 논리식 `(a ∧ b) → a`의 증명이다. (검증된 예제)

```gleam
import gleam/io

// a×b ↔ ∧ (그리고): 곱타입은 "a 이고 b" 의 증명
pub type And(a, b) {
  And(left: a, right: b)
}

// a+b ↔ ∨ (또는): 합타입은 "a 이거나 b" 의 증명
pub type Or(a, b) {
  InL(a)
  InR(b)
}

// ∧ → 좌변: "a 이고 b" 가 증명되면 "a" 도 증명된다
pub fn proj_left(p: And(a, b)) -> a {
  p.left
}

pub fn main() -> Nil {
  let p = And(left: 1, right: "two")
  assert proj_left(p) == 1
  io.println("ok")
}
```

- 연습 1 (P1 `predict`): 위 코드에서 `io.println("ok")`까지 도달하면 출력은 무엇인가? 보기: `ok` / `1` / `런타임 크래시` — **정답 `ok`**. *코멘터리: `proj_left(p) == 1`이 참이라 `assert`가 통과하고, 마지막 `io.println`이 찍힙니다. 여러분은 방금 `(a ∧ b) → a`라는 명제의 증명을 실행한 셈입니다.* 오답 `런타임 크래시` 피드백: "`assert`는 식이 **거짓일 때만** 크래시합니다. `And(1, "two")`의 left는 1이고 `1 == 1`은 참이니 통과합니다 — 증명이 닫혔다는 신호죠."

- 세그먼트 2 요지: 양 극단도 사전에 있다. **`Nil`(원소 1개) ↔ 참(⊤)**: 언제나 손쉽게 만들 수 있는 자명한 증명이며 정보량은 0이다(그래서 부수효과 함수의 반환이 흔히 `Nil`). 반대편 **void(원소 0개) ↔ 거짓(⊥)**: 거주자가 *하나도 없는* 타입이라 "값을 만들 수 없다 = 증명 불가"를 그대로 인코딩한다. Gleam에서는 생성자가 0개인 타입 `pub type Void`로 흉내 낼 수 있다. **정직한 단서**: 논리에서 `⊥ → a`(ex falso)는 자명하지만, Gleam 1.17은 거주자 없는 타입의 `case`마저 자동 exhaustive로 인정하지 *않는다* — `case v {}`는 `Inexhaustive patterns` 에러를 낸다. 그래서 아래처럼 `_` 한 갈래에 `panic`을 두는데, 이 `panic`은 "도달 불가라서 안전"하지만 그 안전을 **컴파일러가 증명해 주지는 않는다**(이 틈이 ②와 U13으로 이어진다). (검증된 예제)

```gleam
import gleam/io

// Nil(1) ↔ 참(⊤): 언제나 만들 수 있는 자명한 증명. 정보는 0.
pub fn trivial() -> Nil {
  Nil
}

// void(0) ↔ 거짓(⊥): 거주자가 없는 타입. "값을 만들 수 없다"는 곧 "증명 불가".
// Gleam에는 생성자 0개 타입을 쓸 수 있다. ⊥ → a (ex falso) 는 다룰 case가 없다.
pub type Void

pub fn absurd(v: Void) -> a {
  case v {
    _ -> panic
  }
}

pub fn main() -> Nil {
  let _ = trivial()
  io.println("ok")
}
```

- 연습 2 (P2 `mcq`): `pub type Void`(생성자 0개)에 대해 옳은 설명은? 보기: ① "`Void` 타입의 값을 정상적으로 만들 방법이 없다 — 명제 ⊥(거짓)에 대응한다" / ② "`Void`는 `Nil`과 같다" / ③ "`absurd`는 `Void` 값으로 아무 `a`나 만들어 주므로 ⊥에서 임의 명제가 진짜로 증명된다" — **정답 ①**. *코멘터리: 거주자가 없으니 `absurd`를 정상 호출할 길도 없습니다. ⊥↔void의 핵심은 바로 이 "만들 수 없음"입니다.* 오답 ③ 피드백: "함정입니다. `absurd`가 컴파일되는 건 맞지만, 그건 `panic`(런타임 크래시) 덕분이지 컴파일러가 ex falso를 증명한 게 아닙니다. 게다가 `Void` 값 자체를 못 만드니 `absurd`를 호출할 수도 없죠. Gleam은 정리 증명기가 아니라 — 이 한계가 다음 레슨과 U13의 주제입니다." 오답 ② 피드백: "`Nil`은 원소 *1개*(↔참), `Void`는 원소 *0개*(↔거짓)입니다. 정반대 극단이에요."

**예시 레슨 TU6-② 「시그니처가 구현을 묶는다 — 파라메트리시티」**

- 세그먼트 1 요지: 제네릭 시그니처는 생각보다 훨씬 많은 것을 *결정한다*. 함수가 타입 변수 `a`를 받으면 그 함수 안에서는 `a`가 Int인지 String인지 알 길이 없어 — 들여다보거나 새 `a`를 만들 수 없다. 그래서 **(순수·전체라고 가정하면)** `fn(a) -> a`의 거주자는 **항등함수 단 하나**, `fn(a, b) -> a`는 **첫 인자를 돌려주는 것**뿐이다. 이렇게 "시그니처만 보고 공짜로 따라 나오는 사실"을 *공짜 정리(free theorem)*라 하며, 그 뿌리가 파라메트리시티다. U11①에서 만든 `pair_map`이나 U8의 제네릭 헬퍼들이 사실 이 제약 아래 있었다. (검증된 예제)

```gleam
import gleam/io
import gleam/list

// fn(a) -> a : a 의 구체 정체를 절대 알 수 없으므로 손댈 수 없다.
// (순수·전체라면) 항등함수가 유일한 거주자.
pub fn id(x: a) -> a {
  x
}

// fn(a, b) -> a : 반환 자리에 놓을 수 있는 a 값은 첫 인자뿐.
pub fn const_first(x: a, _y: b) -> a {
  x
}

// fn(List(a)) -> List(a) : 원소를 들여다볼 수 없으니 자르고/뒤집고/복제만 가능.
pub fn same_or_rev(xs: List(a)) -> List(a) {
  list.reverse(xs)
}

pub fn main() -> Nil {
  assert id(42) == 42
  assert const_first(1, "ignored") == 1
  assert same_or_rev([1, 2, 3]) == [3, 2, 1]
  io.println("ok")
}
```

- 연습 1 (P1 `predict`): 본문을 가린 `fn(a, b) -> a` 함수 `mystery`를 `int.to_string(mystery(7, "hello"))`로 출력한다. 출력은? 보기: `7` / `hello` / `7hello` — **정답 `7`**. *코멘터리: 시그니처가 답을 알려줍니다. 반환 타입이 `a`(= 첫 인자의 타입)이고, 함수 몸체가 새 `a`를 *지어낼* 수 없으니, 순수·전체라면 돌려줄 수 있는 건 첫 인자 `7`뿐입니다. 본문을 안 봐도 맞힐 수 있죠.* 오답 `hello` 피드백: "`hello`는 둘째 인자(타입 `b`)입니다. 반환 타입이 `a`라 `b` 값은 애초에 그 자리에 들어갈 수 없어요 — 들어가면 타입 에러입니다."

```gleam
import gleam/io
import gleam/int

// 시그니처는 fn(a, b) -> a. 본문은 가렸다. 호출 결과만 예측하라.
pub fn mystery(x: a, _y: b) -> a {
  x
}

pub fn main() -> Nil {
  io.println(int.to_string(mystery(7, "hello")))
}
```

- 세그먼트 2 요지: 공짜 정리는 "할 수 없는 일"도 콕 집어 준다. 다만 *무엇을* 못 하는지 정확히 말해야 한다. `fn(List(a)) -> List(a)`가 보장하는 건 **출력에 나타나는 원소는 모두 입력에서 온 것뿐**이라는 사실이다 — `a`가 뭔지 모르므로 새 `a`를 *지어낼* 수도, `a` 자리에 외부 상수를 *끼워 넣을* 수도 없다. 시도해 보면 컴파일러가 막는다: `[5, ..xs]`는 `5: Int`라 `List(a)`와 충돌해 `Type mismatch`다. **여기서 흔한 과대주장을 정정하자**: 이 정리는 *길이*에 대해서는 아무것도 말해 주지 않는다. 원소를 *복제·재배열*하는 건 얼마든지 가능하므로, `list.append(xs, xs)`처럼 길이를 두 배로 늘리는 순수·전체 함수도 **같은 시그니처**를 갖는다(길이 3 → 6). 즉 "길이를 절대 늘릴 수 없다"거나 "결과는 부분수열·순열뿐"이라는 말은 *거짓*이다(append 가 반례). 공짜 정리가 보장하는 건 오직 "출력 원소의 *출처*가 입력"이라는 점이다. 그래서 아래 세 후보는 본문이 달라도(그대로 두기 / 첫 원소 버리기 / 두 번 이어붙이기) 모두 같은 공짜 정리를 만족한다 — 어느 것도 입력에 없던 원소를 지어내지 않는다. (검증된 예제)

```gleam
import gleam/io
import gleam/list

// 후보 A: 시그니처 fn(List(a)) -> List(a)
pub fn keep_all(xs: List(a)) -> List(a) {
  xs
}

// 후보 B: 같은 시그니처 — 첫 원소를 버린다
pub fn drop_first(xs: List(a)) -> List(a) {
  case xs {
    [] -> []
    [_, ..rest] -> rest
  }
}

// 후보 C: 같은 시그니처 — 입력을 두 번 이어붙여 길이를 *늘린다*(복제).
//   '길이를 못 늘린다'는 거짓임을 보여주는 반례. 그래도 새 원소는 없다.
pub fn dup(xs: List(a)) -> List(a) {
  list.append(xs, xs)
}

pub fn main() -> Nil {
  // 공짜 정리: 순수·전체인 fn(List(a))->List(a) 의 출력 원소는 *모두 입력에서* 온다
  //   (새 a 를 지어낼 수 없으므로). 보장은 '원소 출처'뿐 — '길이'가 아니다.
  let sample = [10, 20, 30]
  // 출처 보장: 나타나는 원소는 전부 입력 [10,20,30] 에 있던 것뿐, 외부 상수 없음.
  assert keep_all(sample) == [10, 20, 30]
  assert drop_first(sample) == [20, 30]
  // 같은 시그니처인데 길이가 2배! '길이를 못 늘린다'는 주장의 반례.
  assert dup(sample) == [10, 20, 30, 10, 20, 30]
  assert list.length(dup(sample)) == 6
  io.println("세 후보 모두 입력에 없던 원소를 지어내지 못한다 — 단, 길이는 복제로 변할 수 있다")
}
```

- 연습 2 (P8 `spot_bug`): 아래 세 정의 모두 시그니처 `fn(a) -> a`를 *주장한다*. **공짜 정리("항등뿐")를 위반하는 — 즉 순수·전체였다면 불가능했을 — 코드 하나**를 고르라. 보기:
  - (A) `pub fn f1(x: a) -> a { x }`
  - (B) `pub fn f2(x: a) -> a { let assert [_] = [x] x }` *(쓸데없지만 결국 x를 돌려줌)*
  - (C) `pub fn f3(_x: a) -> a { io.println("부수효과!") panic as "값을 안 돌려준다" }`
  — **정답 (C)**. *코멘터리: (C)는 같은 시그니처를 달았지만 부수효과를 내고 결국 값을 돌려주지 않습니다(panic). 시그니처만 보면 (A)와 구별이 안 되죠 — 이게 핵심입니다.* 오답 (B) 피드백: "(B)는 우회로가 지저분하지만 `let assert`가 통과하면 결국 `x`를 그대로 돌려줍니다. 외부 관측상 항등과 같아요. 정작 약속을 깨는 건 (C)입니다." **정직한 단서(아주 중요)**: 그래서 "`fn(a) -> a`는 항등뿐"은 무조건 참이 아니라 **"순수하고 전체(total)라면"**이라는 단서가 붙는다. Gleam은 totality·순수성을 *강제하지 않으므로*(`panic`/`let assert`/`io` 가능), (C) 같은 시그니처는 컴파일된다. 공짜 정리를 Gleam에서 "법칙"으로 신뢰하려면 그 함수가 순수·전체임을 *우리가* 책임져야 한다 — 의도적 크래시(U13)와 결핍의 일관성(U14)이 바로 이 책임의 반대편이다.

```gleam
import gleam/io

// "fn(a) -> a 는 항등뿐" 은 *순수·전체* 가정 아래의 정리다.
// Gleam은 그 가정을 강제하지 않는다 — 아래도 같은 시그니처를 갖지만 항등이 아니다.
pub fn sneaky(_x: a) -> a {
  io.println("부수효과! 항등이 약속한 적 없는 일")
  panic as "혹은 아예 값을 안 돌려줄 수도"
}

pub fn main() -> Nil {
  let _ = sneaky(1)
  Nil
}
```

> **한계 메모(매 관련 유닛 반복)**: 이 모든 추론은 *타입 시그니처*에 대한 것이지 타입클래스/HKT 기능이 아니다. Gleam엔 타입클래스도 고계 타입도 없어(공식 FAQ: 혼란스러운 에러·컴파일 시간·런타임 비용 — U14①) "모든 펑터/모나드에 동작하는 단일 일반 함수"는 작성 불가다. 파라메트리시티는 그런 추상화 *없이도* 제네릭 시그니처 하나하나가 이미 강한 보장을 준다는 사실이며, 그 보장에는 항상 "순수·전체라면"이 붙는다.

**방출 태그**: `theory:curry-howard` `theory:parametricity` `theory:free-theorems` `theory:parametricity-overclaim`

---

> ### 이론 레벨 TL3 — 구조 위의 추상화 — 패턴이지 타입클래스가 아니다

### TU7. 합성과 항등 (Composition & Identity) [TL3]

**레슨**: ① 합성은 FP의 곱셈이다 — `compose`를 손으로 짓고 파이프와 맞춰보기 ② 두 법칙: 항등원과 결합법칙 — 모든 이후 법칙의 모태

> **선수**: U2(파이프 `|>`), U7(함수 값·고차 함수·캡처). 이 유닛은 U2에서 "데이터가 흐르는 방향"으로 배운 `|>`와 U7에서 "함수를 값으로" 다룬 경험을, *함수를 합치는 한 가지 연산*으로 일반화한다.

**예시 레슨 TU7-① 「합성은 FP의 곱셈이다」**

- 세그먼트 1 요지: 함수 합성은 "한 함수의 출력을 다음 함수의 입력으로" 잇는 기본 연산이다. 수학 기호로 `(f ∘ g)(x) = f(g(x))` — **g가 먼저** 돈다. Gleam에는 합성 연산자(`>>` 같은 것)도, stdlib `compose`도 **없다**. 그래서 우리가 직접 짓는다. 짓고 나면 정체가 드러난다: U2의 파이프 `x |> g |> f` 가 사실 같은 합성을 *값 우선*으로 쓴 것일 뿐이다. (검증된 예제 — 경고 0으로 깨끗이 빌드, 출력 `11`)

```gleam
import gleam/io
import gleam/int

// Gleam has no `>>` operator and no `compose` in stdlib — we write it.
pub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {
  fn(x) { f(g(x)) }
}

fn inc(x: Int) -> Int { x + 1 }
fn double(x: Int) -> Int { x * 2 }

pub fn main() -> Nil {
  let inc_after_double = compose(inc, double)
  assert inc_after_double(5) == 11
  // compose(f, g) and x |> g |> f compute the same thing:
  assert inc_after_double(5) == { 5 |> double |> inc }
  io.println(int.to_string(inc_after_double(5)))
}
```

  여기서 정직하게 한 가지 짚는다. 이 `compose`는 **평범한 함수 `fn(a) -> b` 위에서만** 일반적이다. "모든 Functor/Monad를 잇는 단 하나의 합성"은 Gleam에 타입클래스도 고계 타입(HKT)도 없어서 **작성할 수 없다**(U14①의 결론을 여기서 미리 만난다). 합성·항등은 *언어 기능*이 아니라 여러 구체 타입에서 우리가 *알아보는 패턴*이다.

- 연습 1 (P1 `predict`): 위 코드에서 `compose(inc, double)` 대신 `compose(double, inc)(5)`의 값은?
  보기: (a) `11` (b) `12` (c) `7` — **정답 (b)**. 코멘터리: "`compose(f, g)`는 g를 먼저 돌립니다. `compose(double, inc)`는 inc 먼저 → `5+1=6` → `6*2=12`. 같은 두 함수라도 순서를 바꾸면 결과가 다릅니다 — 합성은 교환법칙이 성립하지 **않습니다**." 오답 (a) 피드백: "`11`은 `compose(inc, double)`의 값입니다. double을 먼저(=`5*2=10`) 돌린 뒤 inc(=`11`). 두 호출의 인자 순서가 뒤바뀐 걸 못 보신 겁니다 — `compose`의 첫 인자가 *나중에* 실행되는 함수라는 비대칭에 주의하세요."

- 세그먼트 2 요지: 그렇다면 파이프와 `compose`는 무슨 관계인가? `x |> g |> f` 는 g 먼저, 왼쪽→오른쪽으로 **읽는 순서 = 실행 순서**다. 반면 수학식 `f ∘ g`(우리 `compose(f, g)`)는 g 먼저 실행이지만 **읽는 순서는 반대**(왼쪽 f가 나중 실행). 즉 `compose(f, g)(x)` ≡ `x |> g |> f`. 같은 계산을 두 방향으로 적은 것뿐이다. 트리키한 건 정확히 이 "읽기 방향 ↔ 실행 방향" 어긋남이다. (검증된 예제, 출력 `8` / `8` / `7`)

```gleam
import gleam/io
import gleam/int

fn inc(x: Int) -> Int { x + 1 }
fn double(x: Int) -> Int { x * 2 }

pub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {
  fn(x) { f(g(x)) }
}

pub fn main() -> Nil {
  io.println(int.to_string(3 |> inc |> double))        // inc 먼저: 4 -> 8
  io.println(int.to_string(compose(double, inc)(3)))   // inc 먼저: 4 -> 8
  io.println(int.to_string(compose(inc, double)(3)))   // double 먼저: 6 -> 7
}
```

- 연습 2 (P6 `refactor`): 등식을 보존하며 재작성하세요. 아래 파이프 표현을 `compose`를 써서 **동일한 값**을 내도록 한 줄 함수 값으로 바꾸세요(점-자유 스타일).

```gleam
// 주어진 것 (이 표현과 모든 입력에서 같은 결과를 내야 함):
//   fn(x) { x |> double |> inc }
// 빈칸을 채워 compose 버전을 완성하세요:
fn step(x: Int) -> Int { x |> double |> inc }
// 동치:  let step2 = compose(???, ???)
```

  **정답**: `compose(inc, double)`. 코멘터리: "파이프는 `double` 먼저 → `inc`. 같은 실행 순서를 `compose`로 적으려면 *나중에 도는 함수를 앞에* 둡니다: `compose(inc, double)`. 읽는 순서가 뒤집힌다는 게 이 유닛의 핵심 반사신경입니다." 대표 오답 `compose(double, inc)` 피드백: "그건 `x |> inc |> double`과 같습니다 — inc가 먼저 돕니다. 파이프 `|> double |> inc`의 실행 순서(double→inc)를 `compose`로 옮기면 *역순*으로 적어야 해서 `compose(inc, double)`이 됩니다. P1 연습에서 본 비교환성과 같은 함정입니다." 대표 오답 `compose(double, inc)(x)` 피드백: "재작성 목표는 *함수 값* 하나(`fn(Int) -> Int`)입니다. `(x)`를 붙이면 값이 되어버려 점-자유 스타일이 아닙니다 — 인자 `x`는 받지 말고 합성만 돌려주세요."

**예시 레슨 TU7-② 「두 법칙: 항등원과 결합법칙」**

- 세그먼트 1 요지: 합성에는 곱셈의 `1`에 해당하는 **항등원**이 있다 — `function.identity`(`fn(x) { x }`). 항등 법칙: `id ∘ f == f == f ∘ id`. 앞에 붙이든 뒤에 붙이든 아무것도 안 한다. 이건 단순한 사실이 아니라 *법칙*이고, 우리는 법칙을 **실행 가능한 프로퍼티**로 표본 검사할 수 있다 — `assert`로 여러 입력에서 등식이 성립하는지 본다(U13의 `assert`를 법칙 시연 도구로 재사용). (검증된 예제, "laws hold" 출력)

```gleam
import gleam/io
import gleam/list
import gleam/function

pub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {
  fn(x) { f(g(x)) }
}

fn double(x: Int) -> Int { x * 2 }
fn inc(x: Int) -> Int { x + 1 }

// Law as an executable property: identity law sampled over inputs.
fn check_identity_law(f: fn(Int) -> Int, samples: List(Int)) -> Bool {
  let id = function.identity
  list.all(samples, fn(x) {
    compose(id, f)(x) == f(x) && compose(f, id)(x) == f(x)
  })
}

pub fn main() -> Nil {
  let samples = [-2, 0, 1, 5, 100]
  assert check_identity_law(double, samples)
  assert check_identity_law(inc, samples)
  io.println("laws hold")
}
```

- 연습 1 (P8 `spot_bug`): 아래 네 개의 "항등 법칙 시연" 중 **법칙을 잘못 주장하는** 것을 고르세요.
  (a) `compose(function.identity, f)(x) == f(x)` (b) `compose(f, function.identity)(x) == f(x)` (c) `function.identity(f(x)) == f(x)` (d) `compose(f, g)(x) == compose(g, f)(x)` — **정답 (d)**. 코멘터리: "(d)는 *교환법칙*이고, 합성에는 성립하지 않습니다(TU7-① P1에서 확인). (a)(b)는 항등 법칙의 양변, (c)는 `identity`의 정의 그 자체로 모두 참입니다." 오답 (b) 피드백: "(b)는 참입니다 — `f ∘ id`. 오른쪽에 `id`를 붙여도 입력이 그대로 f로 들어가니 `f`와 같습니다. 항등 법칙은 *왼쪽이든 오른쪽이든* 성립한다는 게 요점입니다." 오답 (c) 피드백: "(c)는 `identity`의 정의 자체입니다(`identity(y) == y`이므로 `y = f(x)`를 넣으면 참). 법칙 위반이 아닙니다 — 위반은 교환을 가정한 (d)뿐입니다."

- 세그먼트 2 요지: 두 번째 법칙은 **결합법칙**: `(f ∘ g) ∘ h == f ∘ (g ∘ h)`. 셋을 이을 때 괄호를 어디 치든 결과가 같다 — 그래서 우리는 보통 괄호를 *생략*하고 `f ∘ g ∘ h`라 쓴다(파이프 체인 `|> h |> g |> f`가 평평하게 읽히는 이유이기도 하다). 항등 + 결합, 이 두 법칙이 성립하는 "대상=타입, 사상=함수" 세계를 수학에서 **카테고리(category)**라 부른다. 이름만 알아두면 된다 — 우리가 깊이 들어가진 않는다. 중요한 건 이 *두 법칙이 곧 이후 functor/monad 법칙의 모태*라는 점이다(functor가 합성과 항등을 보존한다는 게 functor 법칙의 전부다). (검증된 예제, "assoc holds" 출력)

```gleam
import gleam/io
import gleam/list

pub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {
  fn(x) { f(g(x)) }
}

fn inc(x: Int) -> Int { x + 1 }
fn double(x: Int) -> Int { x * 2 }
fn square(x: Int) -> Int { x * x }

// Associativity sampled as an executable property.
fn check_assoc(
  f: fn(Int) -> Int,
  g: fn(Int) -> Int,
  h: fn(Int) -> Int,
  samples: List(Int),
) -> Bool {
  list.all(samples, fn(x) {
    compose(compose(f, g), h)(x) == compose(f, compose(g, h))(x)
  })
}

pub fn main() -> Nil {
  let samples = [-2, 0, 1, 5, 100]
  assert check_assoc(inc, double, square, samples)
  io.println("assoc holds")
}
```

- 연습 2 (P1 `predict`): `compose(compose(inc, double), inc)(3)` 의 값은? (`inc(x)=x+1`, `double(x)=x*2`)
  보기: (a) `9` (b) `10` (c) `8` — **정답 (a)**. 코멘터리: "가장 안쪽 인자부터: `inc(3)=4` → `double(4)=8` → `inc(8)=9`. 결합법칙 덕분에 `compose(inc, compose(double, inc))(3)`로 괄호를 옮겨도 똑같이 `9`가 나옵니다 — 그게 이 레슨에서 시연한 프로퍼티입니다." 오답 (b) 피드백: "`10`은 `double(inc(inc(3)))` 같은 순서를 떠올렸을 때 나오는 값입니다. `compose`의 첫 인자가 *바깥쪽(나중 실행)*이라는 비대칭을 다시 확인하세요: `compose(F, G)`는 G부터, 여기선 가장 안쪽 `inc`가 맨 먼저 돕니다." 오답 (c) 피드백: "`8`은 마지막 `inc`를 빠뜨린 값(`double(inc(3))`)입니다. 합성이 셋이면 함수도 셋 모두 한 번씩 적용됩니다."

> **정직성 메모(매 관련 유닛 반복)**: Gleam엔 타입클래스·HKT가 없으므로 "임의의 카테고리/펑터에 동작하는 일반 합성"은 못 만든다. 우리가 만든 `compose`는 평범한 함수에 한정된다. 자동 커링도 없어서 부분 적용은 캡처 `compose(inc, _)`처럼 빈칸으로 *명시*하고(U7/U14②), 평가는 eager라 `compose`가 만든 함수도 *호출되는 순간* 인자가 먼저 평가된다(게으른 합성이 필요하면 `fn() -> a` thunk, U14③). 이 한계는 약점이 아니라 설계 선택이며 U14①(혼란스러운 에러·컴파일 시간·런타임 비용)과 이어진다.

**방출 태그**: `theory:composition` `theory:identity-law` `theory:composition-associativity` `theory:composition-order`

---

### TU8. 모노이드 (Monoids) [TL3]

**레슨**: ① 같은 모양 두 개를 하나로 — 이항연산 ⊕와 항등원 e (모노이드의 정의, (Int,+,0)·(String,<>,"")·(List,append,[])·(Bool,&&,True)·(Bool,||,False) 인스턴스 순회) ② 법칙은 실행 가능한 프로퍼티다 — 결합법칙과 좌우 항등을 `assert`로 표본 검사, 그리고 같은 fold 골격에 (e, ⊕)만 갈아 끼우기 ③ `list.fold(xs, e, ⊕)`는 "모노이드로 요약하기"다 — U8의 손으로 쓴 fold가 사실은 이것 ④ 모노이드가 *아닌* 것들 — 뺄셈·나눗셈(비결합), 평균(비결합 + 항등원 없음), 그리고 (Int,×)에 0을 항등으로 쓰는 함정

**예시 레슨 TU8-① 「같은 모양 두 개를 하나로 — ⊕와 e」**

- 세그먼트 1 요지: 모노이드는 거창한 게 아니라 **세 가지 묶음**이다 — 어떤 타입 `T`, 같은 타입 두 개를 하나로 합치는 이항연산 `⊕ : (T, T) -> T`, 그리고 "아무것도 더하지 않음"에 해당하는 **항등원** `e : T`. 당신은 이미 여럿을 안다: `(Int, +, 0)`, `(Int, *, 1)`, `(String, <>, "")`, `(List, append, [])`. "두 개를 합쳐 같은 종류 하나가 나온다 + 합칠 게 없을 때의 기본값이 있다"가 핵심 직관이다.

```gleam
import gleam/list

// (List, append, []) 가 모노이드라는 사실을 fold 로 "요약"
pub fn concat(xss: List(List(a))) -> List(a) {
  list.fold(xss, [], fn(acc, xs) { list.append(acc, xs) })
}
// concat([[1, 2], [3], [4, 5]]) == [1, 2, 3, 4, 5]
```

- 연습 1 (P1 `predict`, choice): `concat([[1, 2], [3], [4, 5]])`의 값은?
  보기: `[1, 2, 3, 4, 5]` / `[[1, 2], [3], [4, 5]]` / `[5, 4, 3, 2, 1]` — **정답 `[1, 2, 3, 4, 5]`**. 코멘터리: "`⊕ = list.append`, `e = []`로 왼쪽부터 접으면 모든 조각이 순서대로 한 리스트로 평탄화됩니다 — 이게 '모노이드로 요약'의 가장 시각적인 예." 오답 `[5, 4, 3, 2, 1]` 피드백: "그건 `[x, ..acc]`(prepend)로 접었을 때의 뒤집힘 현상(U8-④, `acc-reverse`)입니다. 여기서 `⊕`는 prepend가 아니라 `list.append`이고, append는 순서를 보존합니다."

- 세그먼트 2 요지: `Bool`도 두 가지 방식으로 모노이드다 — `(Bool, &&, True)`와 `(Bool, ||, False)`. 항등원을 고르는 감각: `e ⊕ a == a`가 성립하려면 e가 "결과를 바꾸지 않는 중립값"이어야 한다. `&&`에서는 `True && a == a`이므로 항등원이 `True`, `||`에서는 `False || a == a`이므로 `False`다. 같은 타입이라도 **연산이 바뀌면 항등원도 바뀐다**.

```gleam
import gleam/list

pub fn all_true(xs: List(Bool)) -> Bool {
  list.fold(xs, True, fn(acc, b) { acc && b })
}

pub fn any_true(xs: List(Bool)) -> Bool {
  list.fold(xs, False, fn(acc, b) { acc || b })
}
// all_true([True, True, False]) == False
// any_true([False, False, True]) == True
```

- 연습 2 (P2 `mcq`): "다음 중 항등원 짝이 **잘못** 연결된 것은?"
  보기: `(Int, +) → 0` / `(Int, *) → 1` / `(String, <>) → ""` / `(Bool, &&) → False` — **정답 `(Bool, &&) → False`** (올바른 항등원은 `True`). 코멘터리: "`False && a`는 항상 `False`라 a를 통째로 삼켜버립니다 — 그건 항등원이 아니라 *흡수원*(zero)이죠." 오답으로 `(Int, *) → 1`을 고른 경우 피드백: "`1 * a == a`라서 곱셈의 항등원은 1이 맞습니다. 덧셈의 0과 자리만 다를 뿐 정확히 같은 역할입니다. 다음 레슨에서 '곱셈에 0을 항등으로 쓰면?'이라는 함정을 직접 봅니다."

**예시 레슨 TU8-② 「법칙은 실행 가능한 프로퍼티다」**

- 세그먼트 1 요지: 모노이드가 **법칙을 따른다**는 말은 추상적 약속이 아니라 **참이어야 하는 등식**이다. 두 가지뿐: **결합법칙** `a ⊕ (b ⊕ c) == (a ⊕ b) ⊕ c`, **좌·우 항등** `e ⊕ a == a == a ⊕ e`. Gleam엔 프로퍼티 테스트 프레임워크가 stdlib에 없지만, TU1에서 본 참조 투명성 덕에 우리는 법칙을 **표본 입력에 대해 `assert`로 직접 실행**해 볼 수 있다 — 법칙이 "보이는" 순간이다. 다만 정직하게 짚자: **표본 `assert`는 법칙을 *증명*하지 않는다.** 그것은 특정 입력에서의 *반증 시도*(프로퍼티 테스트의 축소판)에 가깝다 — `(Int, +, 0)`처럼 잘 아는 전체(total) 연산에서는 표본 통과가 강한 신뢰를 주지만, 일반적으로 한 표본의 통과가 *모든* 입력에 대한 보장은 아니다(반례는 레슨 ④의 비결합 연산에서 직접 본다, TU1 RT 연결).

```gleam
import gleam/io
import gleam/list
import gleam/int

fn op(a: Int, b: Int) -> Int {
  a + b
}

fn empty() -> Int {
  0
}

pub fn main() -> Nil {
  let a = 5
  let b = 8
  let c = 13
  // 결합법칙: 묶는 순서를 바꿔도 결과가 같다 (이 표본에서 반증 실패 = 통과)
  assert op(a, op(b, c)) == op(op(a, b), c)
  // 좌 항등 / 우 항등
  assert op(empty(), a) == a
  assert op(a, empty()) == a
  io.println("monoid sample checks passed for (Int, +, 0)")
  // op 가 fn(acc, x) 와 모양이 같으므로 그대로 fold 에 넘길 수 있다
  io.println(int.to_string(list.fold([1, 2, 3], empty(), op)))
}
// 출력:
// monoid sample checks passed for (Int, +, 0)
// 6
```

- 연습 1 (P1 `predict`, exact_output): 위 `main`의 출력은 무엇인가?
  보기(exact): 두 줄 `monoid sample checks passed for (Int, +, 0)` 와 `6` — **정답: 두 줄 모두 출력**. 코멘터리: "세 `assert`가 이 표본에서 모두 통과(법칙을 반증하지 못함)했으므로 크래시 없이 두 `io.println`에 도달합니다. `op`는 시그니처가 `fn(Int, Int) -> Int`라 fold 콜백 `fn(acc, x)` 자리에 *그대로* 들어갑니다." 오답 "Assertion failed로 크래시" 피드백: "`(Int, +, 0)`은 진짜 모노이드라 이 표본 검사를 통과합니다. `assert`가 터지는 건 법칙이 *깨질* 때(반례를 만났을 때)인데, 그 경우를 레슨 ④에서 봅니다 — 정직성: Gleam에는 예외가 없으므로(TU9/U9) 실패한 `assert`는 *반환*하는 게 아니라 프로그램을 **크래시**시킵니다."

- 세그먼트 2 요지: 정직성 한 단락 — **Gleam에는 Monoid 타입클래스가 없다.** 위 `op`/`empty`는 "이 타입이 Monoid임을 컴파일러에 등록하는" 선언이 **아니다**. 단지 우리가 손으로 만든 보통 함수일 뿐이고, fold에 `e`와 `⊕`를 **직접 넘긴다**. Gleam엔 타입클래스도 HKT(고계 타입)도 없어서 "모든 모노이드에 동작하는 단 하나의 일반 `mconcat`"은 **작성할 수 없다** — 타입마다 `e`와 `⊕`를 그때그때 fold에 넘기는 게 관용이다. 이 한계와 그 이유(공식 FAQ: 혼란스러운 에러 메시지·컴파일 시간·런타임 비용)는 실용 트랙 **U14①**에서 정면으로 다룬다. 핵심 패턴은 하나다: **같은 fold 골격에 (e, ⊕)만 갈아 끼운다.** 합(`0`, `+`), 곱(`1`, `*`), 문자열 이어붙이기(`""`, `<>`)가 전부 `list.fold(xs, e, ⊕)`의 한 형틀에서 나온다. 모노이드는 여기서 "구현하는 인터페이스"가 아니라 **여러 구체 타입에서 알아보는 패턴**이다.

```gleam
import gleam/list
import gleam/string

// 같은 fold 골격에 (e, ⊕)만 바꿔 끼운다 — 타입클래스 디스패치가 아니라 '손으로 넘김'
pub fn sum(xs: List(Int)) -> Int {
  list.fold(xs, 0, fn(acc, x) { acc + x })
}

pub fn product(xs: List(Int)) -> Int {
  list.fold(xs, 1, fn(acc, x) { acc * x })
}

pub fn join_all(xs: List(String)) -> String {
  list.fold(xs, "", fn(acc, s) { acc <> s })
}

// 구분자가 필요하면 stdlib 의 string.join 도 같은 '모노이드 요약'의 변주다
pub fn join_csv(xs: List(String)) -> String {
  string.join(xs, ", ")
}
// sum([1, 2, 3, 4]) == 10
// product([1, 2, 3, 4]) == 24
// join_all(["a", "b", "c"]) == "abc"
// join_csv(["a", "b", "c"]) == "a, b, c"
```

- 연습 2 (P6 `refactor`): 위 세 함수 `sum`/`product`/`join_all`은 한 글자도 다르지 않은 **같은 fold 골격**에 `(e, ⊕)`만 바꿔 끼운 것이다. 등식을 보존하면서, "초기값 `e`와 결합 함수 `⊕`를 인자로 받아 fold를 한 번만 쓰는" 공통 골격으로 `sum`을 재작성하라(숨김 테스트: `sum([1, 2, 3, 4]) == 10`, 빈 리스트에 대해 `sum([]) == 0` 유지). **모범 답**: `pub fn sum(xs: List(Int)) -> Int { list.fold(xs, 0, fn(acc, x) { acc + x }) }`를 그대로 유지하되, 골격이 같음을 드러내려면 `fold_with`처럼 `(e, ⊕)`를 받는 도우미로 추출한다 — 예: `fn fold_with(xs, e, op) { list.fold(xs, e, op) }` 후 `sum(xs) = fold_with(xs, 0, fn(a, x) { a + x })`. 코멘터리: "재작성해도 출력은 동일해야 합니다(등식 보존) — 바뀌는 건 *어디서 (e, ⊕)를 고르느냐*뿐입니다. 이 추출이 바로 Gleam에서 '모노이드 요약'을 표현하는 관용입니다: 타입클래스 디스패치가 없으니 `(e, ⊕)`를 **값으로 손에 들고 다닌다**." 오답으로 "`sum`의 초기값을 `1`로 바꿔도 합은 같다"고 본 경우 피드백: "아니요 — `e`는 결합 함수에 따라 정해진 *항등원*입니다. `+`의 항등은 `0`이라 `e`를 `1`로 바꾸면 `sum([]) == 1`이 되어 등식이 깨집니다. 재작성은 *값을 보존*해야 하므로 골격을 옮길 때 `(e, ⊕)` 짝을 통째로 함께 옮겨야 합니다."

**방출 태그**: `theory:monoid` `theory:monoid-laws` `theory:monoid-fold` `theory:monoid-non-associativity` `theory:wrong-identity-element`

---

### TU9. 펑터 패턴 (The Functor Pattern) [TL3]

**레슨**: ① map의 한 가지 모양 — "구조는 유지, 내용물만 변환" ② 같은 모양의 재등장 — list/option/result, 그리고 함수 합성(function functor) ③ 펑터 법칙 둘 — 항등·합성을 *실행 가능한 프로퍼티*로 ④ 가짜 map 사냥 — 법칙을 깨는 구현(순서 뒤집기·중복·누락)과 "왜 Gleam엔 단일 map이 없나"(no-HKT 복선)

**예시 레슨 TU9-① 「map의 한 가지 모양」**

- 세그먼트 1 요지: U8에서 `list.map`을, U9에서 `option.map`·`result.map`을 따로따로 배웠다. 이제 셋을 나란히 놓고 보면 **같은 모양**이 보인다 — "감싸진 구조(`List`/`Option`/`Result`)는 그대로 두고, 안의 *내용물에만* 함수를 적용한다". 리스트는 길이가 안 변하고, `Some`은 `Some`인 채, `Ok`는 `Ok`인 채로 값만 바뀐다. 이 "구조 보존 + 내용물 변환" 모양을 **펑터(functor)**라 부른다. 펑터는 *타입클래스나 인터페이스가 아니라*, 여러 구체 타입에서 반복적으로 **알아보는 패턴**이다.

```gleam
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

pub fn shapes() -> #(List(Int), Option(Int), Result(Int, Nil)) {
  let xs = list.map([1, 2, 3], fn(x) { x * 10 })
  let o = option.map(Some(5), fn(x) { x * 10 })
  let r = result.map(Ok(7), fn(x) { x * 10 })
  #(xs, o, r)
}
// shapes() == #([10, 20, 30], Some(50), Ok(70))
```

- 연습 1 (P1 `predict`, choice): `option.map(Some(10), fn(x) { x + 5 })`와 `option.map(None, fn(x: Int) { x + 5 })`의 값은? 보기: ① `Some(15)` / `None` ② `Some(15)` / `Some(0)` ③ `15` / `None` — **정답 ① `Some(15)` / `None`**. 정답 코멘터리: "구조 보존이 핵심입니다 — `Some`은 `Some`으로, `None`은 `None`으로 남고, 함수는 *내용물이 있을 때만* 적용됩니다." 오답 ③ `15`/`None` 피드백: "map은 절대 포장을 벗기지 않습니다. `Some(15)`를 돌려주지 맨몸 `15`를 주지 않아요 — U9에서 'Result/Option의 값은 맨몸으로 안 나온다'고 했던 그 규칙이 여기서도 그대로입니다. 꺼내려면 `case`나 `option.unwrap`이 따로 필요합니다." 오답 ② `Some(0)` 피드백: "`None`에는 적용할 내용물이 없습니다. map의 함수는 *호출되지 않고* `None`이 그대로 통과합니다 — 이 단락(short-circuit) 동작이 바로 펑터가 '구조'를 존중한다는 뜻입니다."
- 세그먼트 2 요지: 세 호출의 *함수 인자*(`fn(x) { x * 10 }`)는 똑같다. 다른 건 어느 모듈의 `map`을 부르느냐뿐이다. 여기서 정직한 사실: **Gleam에는 `Functor` 타입클래스도 고계 타입(HKT)도 없다**. 그래서 "어떤 펑터든 받는 단일 `map`"을 쓸 수 없고, 타입마다 `list.map`/`option.map`/`result.map`을 *각각* 불러야 한다. 펑터는 "구현하는 인터페이스"가 아니라 머릿속에서 "알아보는 패턴"이다(U14①의 "타입클래스 없음" 결정과 직결 — §4의 그 결핍이 여기서 구체적 불편으로 나타난다).

```gleam
import gleam/list

// "아무 펑터에나 동작하는 단일 map"을 시도하면…
// 컨테이너 타입 자체를 타입변수 f 로 두고 f(a) 라고 적어야 하는데,
// Gleam에는 HKT가 없어 타입변수를 다른 타입에 적용(f(a))할 수 없다.
pub fn generic_map(container: f(a), fun: fn(a) -> b) -> f(b) {
  list.map(container, fun)
}
```

- 연습 2 (P2 `mcq`): 위 `generic_map`을 컴파일하면? 보기: ① 정상 컴파일 ② Syntax error — `f(a)`에서 `(`를 기대하지 않았다 ③ Type mismatch ④ 런타임 크래시 — **정답 ② Syntax error**. 정답 코멘터리: "`f(a)`는 '타입변수를 타입에 적용'하는 표현인데, 그건 고계 타입(HKT)이고 Gleam엔 없습니다. 파서가 타입 인자 자리에서 `(`를 만나 거기서 막힙니다." 오답 ① 피드백: "다른 언어(Haskell의 `Functor f => f a -> f b`)라면 가능합니다. Gleam은 의도적으로 HKT를 빼서 — U14①의 FAQ 논거대로 '혼란스러운 에러 메시지·긴 컴파일 시간·런타임 비용'을 피합니다. 대가는 타입마다 map을 따로 부르는 약간의 반복이고, 보상은 단순함입니다." 오답 ③ 피드백: "타입이 안 맞아서가 아니라 *문장 자체가 문법이 아니라서* 막힙니다 — 타입 검사 단계까지 가지도 못합니다."

**예시 레슨 TU9-② 「펑터 법칙 둘」**

- 세그먼트 1 요지: 어떤 `map`이 '진짜 펑터'이려면 두 법칙을 지켜야 한다. ① **항등(identity)**: `map(x, identity) == x` — 아무것도 안 하는 함수로 매핑하면 원본 그대로. ② **합성(composition)**: `map(map(x, g), f) == map(x, fn(a) { f(g(a)) })` — "두 번 매핑 = 합성한 함수로 한 번 매핑". 법칙은 추상적 약속이 아니라 **실행 가능한 프로퍼티**다 — `main` 안에서 표본 입력에 `assert`로 직접 검사할 수 있다(U6의 `list.map`·`function.identity`, TU7의 합성을 그대로 재활용).

```gleam
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/function

pub fn main() -> Nil {
  // 항등 법칙: map(x, identity) == x
  assert list.map([1, 2, 3], function.identity) == [1, 2, 3]
  assert option.map(Some(7), function.identity) == Some(7)
  assert option.map(None, function.identity) == None

  // 합성 법칙: map(map(x, g), f) == map(x, fn(a) { f(g(a)) })
  let g = fn(n: Int) { n + 1 }
  let f = fn(n: Int) { n * 10 }
  assert list.map(list.map([1, 2], g), f) == list.map([1, 2], fn(a) { f(g(a)) })

  io.println("all functor laws hold on the sample")
}
// 출력: all functor laws hold on the sample
```

- 연습 1 (P1 `predict`, exact_output): 위 `main`을 실행하면 stdout에 무엇이 찍히나? **정답 `all functor laws hold on the sample`**. 정답 코멘터리: "모든 `assert`가 `True`라 아무도 안 멈추고, 마지막 `println`까지 도달합니다 — `list.map`과 `option.map`은 둘 다 펑터 법칙을 지킵니다." 오답 "런타임 에러(assert 실패)" 피드백: "stdlib의 `map`들은 법칙을 만족하도록 구현돼 있어 표본 검사가 통과합니다. assert가 깨지는 건 *법칙을 어긴 가짜 map*을 검사할 때고, 그건 다음 레슨에서 사냥합니다." (참고: 합성 법칙은 좌변 `[(1+1)*10, (2+1)*10] = [20, 30]`, 우변도 `[20, 30]`로 일치.)
- 세그먼트 2 요지: 이 법칙은 직접 만든 펑터에도 똑같이 요구된다. U11②에서 작성한 `map_box`(`Box(a)` 위의 map)도 펑터다 — "당신은 그때 `result.map`의 사촌을 만들었다"던 그 코드가 사실 펑터 인스턴스였다. 같은 두 법칙을 `Box`에 대해 표본 검사할 수 있다. (정직성: 이 검사도 `Box`용으로 *손으로* 작성해야 한다 — '모든 펑터의 법칙을 한 번에 검사하는' 일반 함수는 HKT가 없어 못 만든다.)

```gleam
import gleam/function

pub type Box(a) {
  Box(inner: a)
}

pub fn map_box(box: Box(a), f: fn(a) -> b) -> Box(b) {
  Box(f(box.inner))
}

pub fn box_laws_hold() -> Bool {
  let b = Box(4)
  let g = fn(x: Int) { x + 1 }
  let f = fn(x: Int) { x * 2 }
  let identity_ok = map_box(b, function.identity) == b
  let composition_ok =
    map_box(map_box(b, g), f) == map_box(b, fn(a) { f(g(a)) })
  identity_ok && composition_ok
}
// box_laws_hold() == True
```

- 연습 2 (P5 `write_fn`): `pub fn map_box_obeys_identity(b: Box(Int)) -> Bool`을 작성하라 — 임의의 `Box(Int)`에 대해 항등 법칙(`map_box(b, identity) == b`)이 성립하는지 돌려준다. 숨김 테스트는 `Box(0)`, `Box(-3)`, `Box(99)`에 대해 모두 `True`를 기대한다. 정답 코멘터리: "`map_box(b, function.identity) == b` 한 줄이면 됩니다 — 법칙은 곧 코드입니다. 이렇게 법칙을 실행 가능한 프로퍼티로 적어 두면, 나중에 누가 `map_box`를 '최적화'하다 망가뜨려도 이 검사가 잡아냅니다." 흔한 오답 — `function`을 import하지 않고 `identity`만 쓰기 → `Unknown variable` 에러. 피드백: "`function.identity`는 `gleam/function` 모듈에 있습니다. `import gleam/function`을 잊지 마세요 — 직접 `fn(x) { x }`로 적어도 동치입니다." 또 다른 오답 — `map_box(b, ...) == b.inner`처럼 포장을 벗겨 비교 → Type mismatch. 피드백: "양변의 타입을 맞추세요. `map_box`의 결과는 `Box(Int)`이지 `Int`가 아닙니다 — 펑터 법칙은 항상 *구조째로* 비교합니다."

**예시 레슨 TU9-③ 「가짜 map 사냥」** *(이 유닛의 핵심 트리키 파트 레슨)*

- 세그먼트 요지: 시그니처 `fn(List(a), fn(a) -> b) -> List(b)`만 맞으면 컴파일은 통과한다. 하지만 그게 *진짜 펑터*라는 보장은 아니다. 법칙이 진짜 map과 사기꾼을 가른다. 세 가지 흔한 사기: **순서 뒤집기**(`reverse` 끼워넣기), **중복**(원소를 두 번 내보냄), **누락**(첫 원소를 떨어뜨림). 셋 다 항등 법칙을 깬다.

```gleam
import gleam/list
import gleam/function

// 사기꾼 1: 결과를 뒤집는다 (순서)
pub fn bad_map_reverse(xs: List(a), f: fn(a) -> b) -> List(b) {
  list.reverse(list.map(xs, f))
}

pub fn identity_holds(xs: List(Int)) -> Bool {
  bad_map_reverse(xs, function.identity) == xs
}
// identity_holds([1, 2, 3]) == False
```

- 연습 (P8 `spot_bug` × 3): 네 개의 `List` map 구현이 주어진다 — (A) `list.map(xs, f)` 그대로, (B) `list.reverse(list.map(xs, f))`, (C) `list.append(list.map(xs, f), list.map(xs, f))`(중복), (D) `case list.map(xs, f) { [] -> [] [_, ..rest] -> rest }`(첫 원소 누락). "펑터 법칙을 *지키는* 단 하나"를 고르라. **정답 (A)**. 정답 코멘터리: "법칙을 만족하는 건 A뿐입니다. 나머지는 모두 `map(xs, identity) == xs`를 깹니다 — `function.identity`로 매핑해도 구조가 변하니까요." 오답 (B) 피드백: "타입은 완벽히 맞지만 `bad_map_reverse([1,2,3], identity)`는 `[3,2,1]`이라 항등 법칙 위반입니다. U8-④의 'fold-prepend가 reverse가 된다'와 같은 함정 가족 — 시그니처는 사기꾼을 못 거릅니다." 오답 (C) 피드백: "중복도 항등 위반입니다: `map([1], identity)`가 `[1, 1]`이 되어 원본과 다릅니다. 길이가 바뀌면 '구조 보존'이 깨진 것." 오답 (D) 피드백: "누락도 마찬가지 — 첫 원소를 떨어뜨리면 `map([1,2], identity) == [2]`. 펑터는 컨테이너의 *모양*을 한 톨도 안 건드려야 합니다." 보조 노출: 이 세 사기꾼은 합성 법칙도 동시에 깨는지 학습자에게 표본 `assert`로 직접 확인하게 유도한다(법칙 = 실행 가능한 프로퍼티).

**방출 태그**: `theory:functor` `theory:functor-laws` `theory:functor-instances` `theory:functor-law-violation` `theory:no-hkt`

---

### TU10. 모나드와 애플리커티브 패턴 (Monad & Applicative Patterns) [TL3]

**레슨**: ① 맥락 한 겹: 펑터 복습과 "맥락 속 계산"이란 무엇인가 ② 애플리커티브 — 서로 독립인 두 맥락을 결합하기 ③ 모나드 — 의존적 순차와 단락(`result.try`/`use`의 정체), 그리고 "U10에서 너는 이미 모나드를 썼다" ④ 세 모나드 법칙을 실행 가능한 프로퍼티로 보기 + 정직한 한계(타입클래스도 HKT도 없다)

> 이 유닛은 실용 트랙 **U10**(Result 체이닝과 use)과 이론 트랙 **TU9**(펑터: `map`이라는 한 겹 맥락 보존 변환)를 일반화한다. 핵심 전언은 **"이건 타입이 아니라 패턴이다"**: Gleam에는 `Monad` 인터페이스가 없다. `Result`와 `Option`이 *각각 따로* 같은 모양을 보일 뿐이고, 우리는 그 모양에 이름을 붙여 알아본다.

**예시 레슨 TU10-② 「독립인 두 맥락을 결합하기 (애플리커티브)」**

- 세그먼트 1 요지: TU9에서 `result.map(r, f)`는 맥락(`Result`) 한 겹을 *보존*하며 안의 값 하나를 변환했다(펑터). 그런데 입력이 **두 개**고 둘 다 맥락에 싸여 있다면? `parse_age(a)`와 `parse_age(b)`는 **서로를 보지 않는 독립적인 두 계산**이다. 이렇게 "독립인 여러 맥락을 모아 하나로 조립"하는 패턴이 애플리커티브다. Gleam에 `Applicative` 타입클래스는 없으므로, 우리는 그 패턴을 **두 Result를 동시에 `case`로 까서** 직접 손으로 표현한다.

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

// 애플리커티브 패턴: 독립인 두 맥락을 결합. 첫 Error에서 멈춘다.
pub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {
  case parse_age(a), parse_age(b) {
    Ok(x), Ok(y) -> Ok(x + y)
    Error(e), _ -> Error(e)
    _, Error(e) -> Error(e)
  }
}
// add_ages("3", "4") == Ok(7)
// add_ages("3", "x") == Error(NotANumber)
```

- 연습 1 (P1 `predict`): `add_ages("3", "x")`의 값은? 보기: `Ok(3)` / `Error(NotANumber)` / `Error(Negative)` — **정답 `Error(NotANumber)`**. 코멘터리: "두 인자는 *독립*이라 둘 다 평가되지만, 결합 규칙은 '둘 다 `Ok`라야 `Ok`'이고 그렇지 않으면 첫 `Error`를 내보낸다 — 정확히 너가 손으로 쓴 두 번째·세 번째 `case` 가지다." 오답 `Ok(3)` 피드백: "맥락이 살아있는 한 안의 값은 맨몸으로 나오지 않습니다. `b`가 실패한 이상 함수 전체가 실패 맥락을 반환해야 합니다 — TU9에서 본 '맥락 보존'이 여기서는 '맥락 결합'으로 확장된 것입니다. `+`는 *둘 다 성공일 때만* 일어납니다."
- 세그먼트 2 요지: 같은 애플리커티브 패턴을 `use`로도 쓸 수 있다. `use x <- result.try(parse_age(a))` 두 줄 뒤 `Ok(x + y)`로 **조립**하는 것. 단 여기엔 함정이 있다: `use`/`result.try`는 사실 모나드(다음 레슨) 도구다. 두 계산이 *정말로 독립*이라면 어느 쪽으로 써도 결과가 같지만, 표현하고 싶은 의도가 "독립 결합"이라는 점은 `case a, b`가 더 정직하게 드러낸다. **정직한 한계**: Gleam엔 `Applicative`도 HKT도 없으므로, 하스켈의 `(+) <$> pa <*> pb` 같은 *임의 애플리커티브 위 단일 표기*는 없다. 매번 그 타입에 맞게 손으로 조립한다 (→ U14①과 연결).

```gleam
import gleam/result

// 같은 애플리커티브 의도를 use 두 줄 + Ok 조립으로
pub fn add_ages_use(a: String, b: String) -> Result(Int, AgeError) {
  use x <- result.try(parse_age(a))
  use y <- result.try(parse_age(b))
  Ok(x + y)
}
// add_ages_use("3", "4") == Ok(7)
```

- 연습 2 (P7 `parsons`): 줄 조각 `use y <- result.try(parse_age(b))` / `Ok(x + y)` / `use x <- result.try(parse_age(a))` 를 올바른 순서로 재배열해 `add_ages_use`를 완성하라(숨김 테스트: `("3","4")->Ok(7)`, `("x","4")->Error(NotANumber)`). 흔한 오답 — 마지막 줄을 `x + y`로 두고 `Ok(...)`를 빠뜨림. 피드백: "두 맥락을 다 깠어도 함수 반환 타입은 여전히 `Result(Int, AgeError)`입니다. 결합 결과를 다시 맥락에 *재포장*하는 `Ok(...)`가 애플리커티브 '조립' 단계입니다 — U10③의 '마지막 Ok 누락' 단골이 이론 트랙에서 재등장한 것입니다." 두 번째 오답 — `use a <- ...`처럼 이미 쓰인 이름을 또 바인딩. 피드백: "독립인 두 계산이라도 결과 이름은 서로 달라야 둘 다 마지막 줄에서 쓸 수 있습니다."

**예시 레슨 TU10-④ 「세 모나드 법칙, 그리고 정직한 한계」**

- 세그먼트 1 요지: 이전 레슨에서 `result.try(m, f)`(= `use`)가 "맥락이 *살아있으면* 다음 계산으로, 죽었으면 단락"이라는 **의존적 순차**임을 봤다 — 이것이 모나드의 `bind`다. **폭로**: U10에서 `parse_age` 두 개를 `use`로 이어 쓴 그 순간, 너는 이미 Result 모나드를 쓰고 있었다. 모나드가 진짜 모나드이려면 세 법칙을 지켜야 하고, Gleam엔 법칙을 강제하는 타입클래스가 없으니 우리는 법칙을 **실행 가능한 프로퍼티**로 — `main` 안 `assert`로 표본 검사한다.

```gleam
import gleam/io
import gleam/result

pub type AgeError {
  NotANumber
  Negative
}

pub fn main() -> Nil {
  let f = fn(x: Int) -> Result(Int, AgeError) { Ok(x + 1) }
  let g = fn(x: Int) -> Result(Int, AgeError) { Ok(x * 10) }
  let m: Result(Int, AgeError) = Ok(5)

  // 좌항등 (left identity):  try(Ok(a), f) == f(a)
  assert result.try(Ok(5), f) == f(5)

  // 우항등 (right identity): try(m, Ok) == m   (Ok가 곧 'return/순수')
  assert result.try(m, Ok) == m

  // 결합 (associativity):    try(try(m, f), g) == try(m, fn(x){ try(f(x), g) })
  assert result.try(result.try(m, f), g)
    == result.try(m, fn(x) { result.try(f(x), g) })

  io.println("monad laws hold (sampled)")
}
```

- 연습 1 (P8 `spot_bug`): 네 개의 `assert` 중 모나드 법칙을 *잘못* 적은 것 하나를 골라라. 후보에 `assert result.try(Ok(5), f) == f(5)`(좌항등, 정상), `assert result.try(m, Ok) == m`(우항등, 정상), `assert result.try(m, fn(x) { Ok(x) }) == m`(우항등의 다른 표현, 정상), 그리고 **결함 후보** `assert result.try(Ok(5), f) == Ok(5)`(좌항등을 `f(5)`가 아니라 `Ok(5)`와 비교 — `f`가 `Ok(6)`을 주므로 거짓)을 둔다. **정답: 마지막 것**. 코멘터리: "좌항등은 `try(Ok(a), f) == f(a)`입니다 — `f`를 *통과한* 값이지, 원래 값 `Ok(a)`가 아닙니다. `f(5) == Ok(6) ≠ Ok(5)`이므로 이 assert는 런타임에 깨집니다(`assert`가 실패하면 크래시 — TU/U13의 assert 의미)." 오답으로 우항등 줄을 고른 학습자에겐: "`Ok`는 이 모나드의 '순수(return)'입니다. `try(m, Ok)`는 '맥락을 풀었다가 곧장 같은 맥락으로 되돌리는' 무위 연산이므로 항상 `m`과 같습니다 — 정상 법칙입니다."
- 세그먼트 2 요지: **`map`인가 `try`인가**(`bind-vs-map`). 콜백이 **맨몸 값**을 돌려주면 맥락이 그대로 한 겹이니 `map`. 콜백이 또 **맥락에 싼 값**(`Result`)을 돌려주면 맥락이 *두 겹*이 되어 `Result(Result(a, e), e)`가 생긴다 — 이 중첩을 **평탄화**하는 게 `try`의 일이다. 도구를 잘못 고르면 타입이 어긋나거나, 어긋나지 않아도 의미가 망가진다.

```gleam
import gleam/result

pub fn halve(n: Int) -> Result(Int, AgeError) {
  case n % 2 == 0 {
    True -> Ok(n / 2)
    False -> Error(NotANumber)
  }
}

// map: 콜백이 또 Result를 주므로 맥락이 두 겹 → 중첩
pub fn parse_then_halve_map(
  s: String,
) -> Result(Result(Int, AgeError), AgeError) {
  result.map(parse_age(s), halve)
}
// parse_then_halve_map("8") == Ok(Ok(4))   <- 평탄화 안 됨

// try: 한 겹으로 평탄화
pub fn parse_then_halve_try(s: String) -> Result(Int, AgeError) {
  result.try(parse_age(s), halve)
}
// parse_then_halve_try("8") == Ok(4)
// parse_then_halve_try("7") == Error(NotANumber)
```

- 연습 2 (P1 `predict`): `parse_then_halve_map("8")` 과 `parse_then_halve_try("8")` 의 값은 각각? 보기: `Ok(4)` / `Ok(Ok(4))` / `Error(NotANumber)` 조합 — **정답 `Ok(Ok(4))` 와 `Ok(4)`**. 코멘터리: "`halve`가 `Result`를 돌려주므로 `map`은 맥락을 한 겹 더 *쌓아* `Ok(Ok(4))`를 만들고, `try`는 그 한 겹을 흡수(평탄화)해 `Ok(4)`로 잇습니다. '맥락이 한 겹 더 생기면 `try`, 아니면 `map`'이 선택 규칙입니다." 오답 `parse_then_halve_map("8") == Ok(4)` 피드백: "`map`은 절대 평탄화하지 않습니다 — 콜백 결과를 *그대로* 맥락 안에 넣을 뿐입니다. 콜백이 이미 `Result`라면 `Ok(Ok(...))` 중첩이 그대로 보존됩니다. 이 중첩 `Result(Result(a,e),e)`가 보이면 거의 항상 `map`을 `try`로 바꿔야 한다는 신호입니다." (실용 트랙에서 이 함정은 `Type mismatch` 컴파일 에러로 먼저 데인 적이 있다.)
- 세그먼트 3 요지(**정직한 한계, U14 연결**): Gleam엔 `Monad` 타입클래스도 HKT도 없다. 그래서 (1) **임의 모나드 위 do-notation은 없다** — `use`는 "나머지 줄 전체가 마지막 인자 콜백으로 들어가는" 설탕(U10④)일 뿐, 타입클래스 디스패치가 아니다. `result.try`는 오직 `Result`에만, `option.then`은 오직 `Option`에만 쓴다. (2) **"모든 모나드 공통 `sequence`/`bind`"는 작성 불가**다. 아래는 그 한계를 일부러 컴파일 에러로 박제한 예다.

```gleam
import gleam/option
import gleam/result

pub fn main() -> Nil {
  // result.try는 Result 전용. Option을 넣으면 컴파일 거부.
  let _ = result.try(option.Some(1), fn(x) { option.Some(x + 1) })
  Nil
}
```

- 마무리 코멘터리: 위 코드는 `Expected type: Result(Int, a) / Found type: option.Option(Int)`로 거부된다. "`Result`와 `Option`은 *각자* 모나드 법칙을 만족하지만, 둘을 묶는 공통 인터페이스가 없어서 한 함수로 둘 다 처리할 수 없습니다. 이게 'HKT 없음'의 구체적 대가입니다(→ U14①: 공식 FAQ — 타입클래스의 혼란스러운 에러·컴파일 시간·런타임 비용을 피하려는 의도적 선택). Gleam의 길은 '하나의 추상 함수'가 아니라 '각 타입마다 명시적 `result.try` / `option.then`'입니다 — 패턴은 같되 디스패치는 손으로."

**방출 태그**: `theory:monad` `theory:monad-laws` `theory:applicative` `theory:bind-vs-map` `theory:map-vs-bind-confusion` `theory:no-hkt`

---

> ### 이론 레벨 TL4 — 토대와 한계

### TU11. 람다 계산과 처치 인코딩 (Lambda Calculus & Church Encoding) [TL4]

> 캡스톤급 이론 유닛. 선수: U7(함수를 값으로), TU3(평가 전략·eager/strict), TU1(치환과 등식추론). 일부 레슨은 SRS에서 제외(인코딩 자체는 일상 코드가 아니라 "함수만으로 충분하다"는 *깨달음*을 주는 용도). 선행 사례: U7에서 익명함수를 값으로 넘겼고, TU3에서 eager 평가가 인자를 호출 전에 강제함을 봤다 — 이 유닛은 그 둘이 합쳐져 "함수 하나로 만든 우주"가 어떻게 살아 움직이고 어디서 무너지는지를 보여준다.

**레슨**: ① 최소 계산: 변수·추상(λ)·적용 셋과 β-환원 (TU3의 평가를 손으로) ② 모든 것이 함수다 — Church Bool·pair·수를 Gleam으로 실제 인코딩하고 디코드해 확인 ③ 재귀의 이름 — 고정점 콤비네이터 Y, eager에선 왜 발산하는가(→Z), 그리고 Gleam엔 named recursion이 있어 애초에 필요 없다는 정직한 결론

**예시 레슨 TU11-① 「(λx.M)N → M[x:=N] — β-환원과 변수 포획」**

- 세그먼트 1 요지: 람다 계산은 문법이 셋뿐인 계산 모델이다 — **변수** `x`, **추상** `λx.M`("`x`를 받아 `M`을 돌려주는 함수"), **적용** `M N`("`M`에 `N`을 먹임"). 그게 전부다. 계산은 단 한 규칙, **β-환원**: 함수에 인자를 주면 본문의 매개변수를 인자로 바꿔 끼운다 — `(λx.M)N → M[x:=N]`. TU3에서 "평가는 식을 더 단순한 식으로 줄이는 것"이라 했는데, β-환원이 바로 그 한 걸음이다. Gleam에서 `λx.M`은 `fn(x) { m }`, 적용은 `f(n)`, β-환원은 Gleam 런타임이 함수 호출 시 실제로 하는 일이다.

```gleam
import gleam/io
import gleam/int

// (λx. x + x) 3  --β-->  3 + 3  -->  6
pub fn main() -> Nil {
  let double = fn(x: Int) { x + x }
  io.println(int.to_string(double(3)))
  Nil
}
```

- 연습 1 (P1 `predict`, `exact_output`): 위 `double(3)`를 β-환원으로 손으로 줄이면 `3 + 3`이 되고 그 다음은? 무엇이 출력되는가?
  보기: `6` / `33` / `double(3)` — **정답 `6`**. 코멘터리: "`(λx. x+x) 3`에서 본문 `x+x`의 모든 `x`를 인자 `3`으로 치환 → `3+3` → `6`. β-환원은 '문자열 끼워넣기'가 아니라 '값의 치환'이라 `Int +`가 동작한다." 오답 `33` 피드백: "`33`은 문자열 결합(`<>`)의 결과처럼 보입니다. 여기서 `+`는 **Int 덧셈**입니다(Gleam은 Int `+`와 Float `+.`, 문자열 `<>`를 엄격히 구분 — U1③). β-환원은 매개변수 `x`를 *값* 3으로 치환할 뿐, 두 토큰을 이어붙이지 않습니다."

- 세그먼트 2 요지: 치환에는 함정이 있다 — **변수 포획(variable capture)**. `M[x:=N]`을 할 때, `N` 안의 자유 변수가 `M` 안의 다른 λ에 *붙잡혀* 의미가 뒤바뀌면 안 된다. 예: `(λx. λy. x)`는 "두 인자 중 첫째를 돌려주는 함수"다. 여기에 `y`를 순진하게 치환하면 `λy. y`("둘째를 돌려줌")가 되어 의미가 *반대로* 망가진다 — 안쪽 `λy`가 바깥에서 온 `y`를 포획했기 때문. 올바른 환원은 먼저 묶인 변수의 이름을 바꿔(α-변환) 충돌을 피한다: `λy'. y`. TU1의 "등식추론은 치환을 보존한다"가 성립하려면 이 capture-avoiding 규칙이 필수다. Gleam에서는 컴파일러가 스코프를 정확히 추적하므로 *직접* 포획 버그를 만들 수는 없지만, 손으로 환원할 때 우리가 저지르는 실수를 컴파일러는 절대 하지 않는다는 점을 코드로 확인할 수 있다.

```gleam
import gleam/io

// (λx. λy. x) 적용: 첫째 인자를 고정해 "상수 함수"를 만든다.
// const_y 는 y를 무시하고 항상 처음 받은 값을 돌려준다 — 포획이 없다.
pub fn main() -> Nil {
  let const_fn = fn(x: String) { fn(_y: String) { x } }
  let always_a = const_fn("a")
  io.println(always_a("b"))
  // == "a"  (만약 y에 포획됐다면 "b"가 나왔을 것)
  Nil
}
```

- 연습 2 (P8 `spot_bug`): 다음 세 개의 "`(λx. λy. x)` 치환" 손계산 중 **틀린(포획이 일어난)** 것을 고르라.
  (A) `(λx. λy. x)` 에 `z` 치환 → `λy. z` ✓
  (B) `(λx. λy. x)` 에 `y` 치환 → `λy. y` ✗
  (C) `(λx. λy. x)` 에 `y` 치환, 먼저 `λy`→`λy'` 개명 후 → `λy'. y` ✓
  — **정답: (B)**. 코멘터리: "(B)는 바깥에서 들어온 자유변수 `y`가 안쪽 `λy`에 *포획*되어 '상수 함수'가 '항등 비슷한 것'으로 둔갑했습니다 — 의미가 바뀌었으니 잘못된 환원입니다." 오답 (C)를 고른 경우 피드백: "(C)는 정확히 capture-avoiding의 정석입니다 — 충돌하는 묶인 변수를 α-변환으로 먼저 개명(`λy'`)한 뒤 치환하므로 의미가 보존됩니다. 이게 올바른 β-환원이며, Gleam 컴파일러가 내부적으로 보장하는 스코핑과 같은 원리입니다."

**예시 레슨 TU11-② 「모든 것이 함수다 — Church Bool·pair·수를 Gleam으로」**

- 세그먼트 1 요지: 람다 계산엔 `True`도 `42`도 `(a, b)`도 없다. 함수밖에 없는데 어떻게 데이터를 표현할까? **처치 인코딩(Church encoding)**: 데이터를 "그 데이터로 *무엇을 할지*"로 정의한다. **Church Bool**은 "두 선택지 중 하나를 고르는 함수"다 — `ctrue`는 첫째를, `cfalse`는 둘째를 고른다. 그러면 `if`는 그냥 "그 불리언을 두 가지에 적용"하는 것이다. Gleam은 정적 타입이라 untyped λ-계산과 달리 타입이 붙는다: 두 선택지가 같은 타입 `a`여야 하므로 Church Bool의 타입은 **`fn(a, a) -> a`**. (검증된 예제 — 1.17.0 컴파일·실행 확인)

```gleam
import gleam/io

// Church Bool : fn(a, a) -> a  — 둘 중 하나를 고른다
pub fn ctrue(t: a, _f: a) -> a {
  t
}

pub fn cfalse(_t: a, f: a) -> a {
  f
}

// cif b then else  ==  b(then, else) : 불리언을 두 선택지에 적용
pub fn cif(b: fn(a, a) -> a, then: a, els: a) -> a {
  b(then, els)
}

pub fn main() -> Nil {
  assert cif(ctrue, "yes", "no") == "yes"
  assert cif(cfalse, "yes", "no") == "no"
  io.println(cif(ctrue, "yes", "no"))
  // == "yes"
  Nil
}
```

> 정직성 노트: `ctrue`에서 둘째 인자 `_f`를 안 쓴다고 `_`를 붙였다(U1에서 본 "안 쓰는 인자" 관용구). 이름 그대로 `f`로 두면 컴파일은 되지만 "Unused function argument" 경고가 뜬다 — λ-계산에선 인자를 버리는 게 정상이라 Gleam의 경고와 미묘하게 어긋나는 지점이다.

- 연습 1 (P1 `predict`, `choice`): `cfalse("A", "B")`를 직접 호출(`cif` 없이)하면? 보기: `"A"` / `"B"` / 컴파일 에러 — **정답 `"B"`**. 코멘터리: "`cfalse(t, f) = f`이므로 둘째 인자 `\"B\"`를 그대로 돌려줍니다. Church Bool은 그 자체가 '선택 함수'라 적용만으로 분기가 끝납니다." 오답 `"A"` 피드백: "그건 `ctrue`의 동작입니다. `cfalse`는 첫째(`_t`)를 *버리고* 둘째 `f`를 고릅니다 — 함수 본문 `{ f }`를 다시 보세요."

- 세그먼트 2 요지: 수도 함수로 표현한다 — **Church 수**는 "함수 `f`를 값 `x`에 *몇 번* 적용하느냐"다. `czero`는 0번(그냥 `x`), `csucc(n)`은 `n`번 적용한 뒤 한 번 더. 자연수가 곧 "반복 횟수"가 되는 셈이다. 그리고 `cadd m n`은 "먼저 `n`번, 이어서 `m`번 적용" = `(m+n)`번. Gleam Int로 **디코드**해 진짜 맞는지 확인할 수 있다: `f`를 `fn(k){k+1}`, `x`를 `0`으로 주면 적용 횟수가 그대로 Int로 떨어진다. (검증된 예제 — `to_int(cadd(two, two)) == 4` 확인)

```gleam
import gleam/io
import gleam/int

// Church 수 : f 를 x 에 n 번 적용
pub fn czero(_f: fn(a) -> a, x: a) -> a {
  x
}

pub fn csucc(n: fn(fn(a) -> a, a) -> a) -> fn(fn(a) -> a, a) -> a {
  fn(f, x) { f(n(f, x)) }
}

// add m n : 먼저 n번, 그 위에 m번 더 적용 = (m+n)번
pub fn cadd(
  m: fn(fn(a) -> a, a) -> a,
  n: fn(fn(a) -> a, a) -> a,
) -> fn(fn(a) -> a, a) -> a {
  fn(f, x) { m(f, n(f, x)) }
}

// 디코드: +1 을 n번 적용해 Int로 환산
pub fn to_int(n: fn(fn(Int) -> Int, Int) -> Int) -> Int {
  n(fn(k) { k + 1 }, 0)
}

pub fn main() -> Nil {
  let one = csucc(czero)
  let two = csucc(one)
  assert to_int(czero) == 0
  assert to_int(two) == 2
  assert to_int(cadd(two, two)) == 4
  io.println(int.to_string(to_int(cadd(two, two))))
  // == "4"
  Nil
}
```

- 연습 2 (P5 `write_fn`): `cmul(m, n)`("`m` 곱하기 `n`")을 작성하라. 힌트: `m`은 "어떤 함수를 `m`번 적용"하는 도구다. `n`을 한 번 적용하는 것을 `m`번 반복하면 된다 — `fn(f, x) { m(fn(y) { n(f, y) }, x) }`. 숨김 테스트: `to_int(cmul(two, three)) == 6`, `to_int(cmul(czero, three)) == 0`. **정답** `pub fn cmul(m, n) { fn(f, x) { m(fn(y) { n(f, y) }, x) } }`. 코멘터리: "곱셈은 '덧셈의 반복'이듯, Church 곱셈은 '적용의 합성을 반복'입니다 — `m`이 바깥 루프, `n`이 안쪽 루프." 대표 오답 `fn(f, x) { m(f, n(f, x)) }`(이건 `cadd`다) 피드백: "그건 덧셈입니다 — `n`번 적용한 *위에* `m`번 더하면 `m+n`. 곱셈은 'n번-적용'이라는 한 덩어리를 `m`번 *반복*해야 하므로, `m`의 함수 인자 자리에 `fn(y){ n(f, y) }`를 통째로 넘겨야 합니다."

> 정직성 노트 (no-HKT / no-typeclass): Church **pair**도 같은 정신이다 — `cpair(a, b) = fn(sel){ sel(a, b) }`, `cfst(p) = p(fn(a,_){a})`. 하지만 Gleam의 정적 타입이 여기서 송곳니를 드러낸다. 셀렉터의 반환 타입이 타입 변수 `c`에 고정되므로, **하나의 `cpair` 값**을 `cfst`와 `csnd`에 *둘 다* 넘기면 `c`가 첫 사용에서 `a`로, 둘째에서 `b`로 양립 불가능하게 결정되어 **타입 불일치**가 난다. 회피책은 선택마다 `cpair(10, "x")`를 새로 만드는 것뿐(검증함). untyped λ-계산엔 없던 제약이고, "모든 펑터/모나드에 통하는 단일 일반 함수"가 Gleam에서 불가능한 것과 **같은 뿌리** — 타입클래스도 HKT도 없어서다. 이 한계는 실용 U14①(타입클래스 없음: 혼란스러운 에러·컴파일 시간·런타임 비용이라는 공식 FAQ 논거)과 정확히 이어진다.

**예시 레슨 TU11-③ 「재귀의 이름 — Y, eager 발산, 그리고 Gleam엔 필요 없다는 결론」**

- 세그먼트 1 요지: 익명함수에는 **자기 이름이 없다** — 그래서 자기 자신을 호출(재귀)할 방법이 없어 보인다. λ-계산의 해법은 **고정점 콤비네이터** `Y`: "자기참조 능력"을 외부에서 주입한다. 발상은 `fact = fix(facter)`로, `facter`는 "자기 자신(`self`)을 받아 진짜 함수를 만들어내는 생성기"다. `Y`의 핵심 트릭은 **자기 적용** `x(x)` — 함수에 자기를 먹여 무한 반복을 만든다. 그런데 Gleam에서 `x(x)`를 그대로 쓰면 컴파일러가 **무한 타입**이라며 거부한다(이건 우연이 아니라 단순 타입 람다계산이 `Y`를 타입화할 수 없다는 유명한 결과다). 그래서 재귀 *데이터 타입* `Rec`로 매듭을 묶어 타입 검사기를 통과시킨다. (검증된 예제 — 1.17.0 컴파일·실행, `z(facter)(5) == 120`)

```gleam
import gleam/io
import gleam/int

// 자기 적용 x(x)는 직접 타입화 불가 → 재귀 데이터 타입으로 매듭을 묶는다.
pub type Rec(a, b) {
  Rec(fn(Rec(a, b)) -> fn(a) -> b)
}

// Z 콤비네이터: eager 언어용 strict 고정점.
// 핵심은 η-확장 fn(v){ ... (v) } — 재귀 펼침을 인자가 올 때까지 *지연*한다.
pub fn z(f: fn(fn(a) -> b) -> fn(a) -> b) -> fn(a) -> b {
  let g =
    Rec(fn(r: Rec(a, b)) {
      let Rec(rf) = r
      fn(v: a) { f(rf(r))(v) }
    })
  let Rec(gf) = g
  gf(g)
}

pub fn main() -> Nil {
  // 생성기: self 를 받아 진짜 fact 를 만든다 (이름 없는 재귀를 흉내)
  let facter = fn(self: fn(Int) -> Int) {
    fn(n: Int) {
      case n {
        0 -> 1
        _ -> n * self(n - 1)
      }
    }
  }
  let zfact = z(facter)
  assert zfact(5) == 120
  io.println(int.to_string(zfact(5)))
  // == "120"
  Nil
}
```

- 연습 1 (P8 `spot_bug`): 위 `z`에서 `fn(v: a) { f(rf(r))(v) }`를 **η-확장 없이** `f(rf(r))`로 줄이면(이게 순진한 `Y`다) 무슨 일이 나는가? 보기: ⓐ 그대로 잘 동작한다 ⓑ 컴파일은 되지만 **호출 전에 무한 루프(스택 오버플로)** ⓒ 컴파일 에러 — **정답 ⓑ**. 코멘터리: "Gleam은 **eager**(TU3)라 `f(rf(r))`의 인자 `rf(r)`가 *즉시* 평가되고, 그게 다시 `rf(r)`을 강제해 인자가 도착하기도 전에 발산합니다. 실제로 실행하면 `zfact`를 한 번도 호출하지 않았는데 구성 시점에 스택이 터집니다(검증함)." 오답 ⓐ 피드백: "lazy 언어(예: Haskell)라면 ⓐ가 맞습니다 — 거기선 `rf(r)`가 필요할 때까지 미뤄지니까요. 하지만 Gleam은 strict/eager라 `fn(v){ ... (v) }`로 **한 겹 감싸**(η-확장) 평가를 지연시켜야 합니다. 이게 `Y`(lazy)와 `Z`(strict)를 가르는 단 하나의 차이입니다."

- 세그먼트 2 요지: 여기서 가장 중요한 정직한 결론 — **Gleam에서는 `Y`도 `Z`도 쓸 일이 없다.** 위 `Rec` 매듭은 "함수만으로 재귀를 *만들 수 있다*"는 이론적 시연일 뿐, 실무 코드가 아니다. Gleam의 `pub fn`(과 모듈 안 함수)은 **이름으로 자기 자신을 부를 수 있다**(named recursion) — U5·U6에서 줄곧 그렇게 써왔다. 익명함수만 자기 이름이 없을 뿐, 이름 붙은 함수는 처음부터 고정점을 공짜로 받는다. 람다 계산은 "함수만 있어도 *충분하다*"(곧 **튜링 완전**: Church 수·Bool·재귀로 어떤 계산이든 표현 가능)를 증명하지만, "함수만 *써야 한다*"는 뜻은 아니다 — 실용 언어는 이름·타입·패턴매칭을 더해 같은 능력을 훨씬 읽기 쉽게 준다.

```gleam
import gleam/int

// Gleam은 named recursion이 있다 — Y/Z 없이 그냥 자기 이름을 부른다.
pub fn fact(n: Int) -> Int {
  case n {
    0 -> 1
    _ -> n * fact(n - 1)
  }
}
// fact(5) == 120
```

- 연습 2 (P2 `mcq`): "Gleam에서 계승(factorial)을 쓰는 가장 관용적인 방법은?" 보기: ⓐ `Rec` 타입으로 `Z` 콤비네이터를 구성해 적용 ⓑ `pub fn fact`로 named recursion ⓒ `for` 루프 ⓓ Church 수로 인코딩 후 디코드 — **정답 ⓑ**. 코멘터리: "Gleam엔 named recursion이 있어 `fact`가 본문에서 `fact`를 직접 부르면 됩니다 — 이게 U5/U6에서 배운 정석입니다." 오답 ⓐ 피드백: "`Z` 콤비네이터는 '함수만으로도 재귀가 가능하다'는 *이론 시연*입니다. Gleam은 이름 붙은 함수가 자기참조를 공짜로 주므로 `Rec`·`Z`는 불필요한 복잡성입니다." 오답 ⓒ 피드백: "Gleam엔 `for`/`while`이 없습니다(플랫폼 불변식) — 반복은 재귀 또는 `list` 모듈로 합니다(U5/U8)." 오답 ⓓ 피드백: "Church 수는 '수가 곧 함수'라는 깨달음을 주지만 `Int`보다 느리고 디코드가 필요합니다 — 실무에선 native `Int`를 씁니다."

**방출 태그**: `theory:lambda-calculus` `theory:beta-reduction` `theory:beta-reduction-capture` `theory:church-encoding` `theory:church-numerals` `theory:fixpoint` `theory:eager-fixpoint` `theory:turing-complete`

---

### TU12. 캡스톤 — 한계, 재귀 스킴, 다음 경로 (Capstone: Limits, Recursion Schemes, Next Paths) [TL4]

**레슨**: ① 결핍의 일관성 — 왜 Gleam은 단 하나의 `map`을 못 만드나 (HKT 부재의 이론적 해명, U14 전면 연결) ② 재귀 스킴 — `fold`는 ADT 위의 *유일한 구조 존중 붕괴*다 (catamorphism, U6/U8이 사실 무엇이었나) ③ 종합 과제 + 다음 경로 — 나만의 `Tree(a)`에 catamorphism·functor map·법칙을 직접 쓰고, "이론은 패턴을 보는 눈"으로 마무리

**예시 레슨 TU12-① 「결핍의 일관성 — 왜 단 하나의 `map`을 못 만드나」**

- 세그먼트 1 요지: 이 트랙 내내 우리는 `list.map`, `option.map`, `result.map`이 **같은 모양의 패턴**(`map(container, fn(a)->b) -> container_of_b`)임을 보았다. 자연스러운 질문: "그럼 *아무 컨테이너*에나 도는 `map` 하나를 쓰면 안 되나?" Gleam의 답은 **불가능**이다. 타입 변수는 `Int`, `String` 같은 *완성된 타입*만 받을 수 있고, `List`·`Option`처럼 인자를 더 받아야 완성되는 **타입 생성자**를 변수로 받을 수 없다. 이것이 "고계 타입(higher-kinded types, HKT)이 없다"의 정확한 의미다. 그래서 우리가 할 수 있는 건 타입마다 `map`을 *따로* 쓰는 것뿐이다(검증된 예제, 셋 다 깨끗하게 컴파일된다 — 세 import 모두 쓰이므로 경고도 없다).

```gleam
import gleam/list
import gleam/option.{type Option}
import gleam/result

// 같은 패턴, 그러나 타입마다 따로 — 하나로 합칠 수 없다.
pub fn map_list(xs: List(a), f: fn(a) -> b) -> List(b) {
  list.map(xs, f)
}

pub fn map_option(o: Option(a), f: fn(a) -> b) -> Option(b) {
  option.map(o, f)
}

pub fn map_result(r: Result(a, e), f: fn(a) -> b) -> Result(b, e) {
  result.map(r, f)
}
```

- 연습 1 (P8 `spot_bug`): 네 개의 시그니처 중 "Gleam에서 *작성 자체가 불가능*한" 것 하나를 고르라.
  보기:
  (a) `pub fn map_list(xs: List(a), f: fn(a) -> b) -> List(b)`
  (b) `pub fn map_pair(p: #(a, a), f: fn(a) -> b) -> #(b, b)`
  (c) `pub fn generic_map(c: f(a), f2: fn(a) -> b) -> f(b)`
  (d) `pub fn map_result(r: Result(a, e), f: fn(a) -> b) -> Result(b, e)`

  — **정답 (c)**.

  정답 코멘터리: "맞습니다. `f(a)`는 *타입 변수 `f`를 타입에 적용*하려는 시도인데, Gleam의 타입 변수는 그런 능력이 없습니다(HKT 부재). 실제로 컴파일러는 타입이 아니라 *문법* 단계에서 막습니다 — 에러 제목은 `Syntax error`, 메시지는 `I was not expecting this`이고 캐럿이 `f` 뒤의 여는 괄호 `(`를 가리킵니다(`Found \`(\`, expected one of: \`)\` / a function parameter`). 즉 타입 검사까지 가지도 못합니다."
  오답 (b) 피드백: "이건 멀쩡합니다. `#(a, a)`는 *완성된 타입*만 변수로 쓰고 컨테이너 모양(`#(_, _)`)은 코드에 직접 박혀 있습니다 — 타입 생성자를 변수로 받는 게 아니라서 HKT가 필요 없죠. TU11의 `pair_map`이 바로 이것입니다." 오답 (d) 피드백: "`Result(a, e)`도 컨테이너 모양이 시그니처에 *고정*되어 있습니다. 변하는 건 안에 든 타입 변수 `a`, `e`뿐이라 1차(first-order)로 충분합니다."

```gleam
// (c)를 실제로 쓰면 — HKT가 없다는 한계를 문법이 먼저 거부한다.
pub fn generic_map(container: f(a), fun: fn(a) -> b) -> f(b) {
  container
}
```

- 세그먼트 2 요지: 이건 Gleam이 "덜 만들어져서"가 아니라 **의도된 트레이드오프**다. Haskell/PureScript/Scala는 타입클래스 + HKT로 `class Functor f where fmap :: (a -> b) -> f a -> f b` 같은 *단일 추상*을 표현한다. Gleam은 공식 FAQ에서 타입클래스를 *의도적으로* 배제한다 — 근거는 (1) 디스패치 실패 시 **혼란스러운 에러 메시지**, (2) **컴파일 시간** 증가, (3) 사전(dictionary) 전달로 인한 **런타임 비용**. 그 대신 Gleam은 "필요한 동작을 *함수 인자로 명시적으로 넘긴다*". 이것이 U14①이 다룬 바로 그 결정이고, TU 트랙 전체에서 "단일 일반 Functor/Monad 함수는 못 쓴다"고 매번 정직하게 명시해 온 이유의 *이론적 뿌리*다. (실패하는 코드라 실행 불가 — `compile-error` 의도)

- 연습 2 (P1 `predict`): 위 `generic_map`을 컴파일하면 무엇이 나오는가?
  보기: ① 정상 컴파일 ② `Syntax error`(타입 변수 적용 거부) ③ `Type mismatch` ④ 런타임 크래시 — **정답 ②**.
  정답 코멘터리: "타입 변수에 `(...)`를 붙이는 순간 문법 파서가 거부합니다. 핀 1.17.0 실측 출력은 제목 `Syntax error`, 본문 `I was not expecting this`(캐럿이 `f(`의 여는 괄호를 가리킴)입니다. HKT의 부재는 '타입 검사 실패'가 아니라 *애초에 표현할 문법이 없음*으로 나타납니다 — 가장 깊은 종류의 '없음'이죠."
  오답 ① 피드백: "이게 통과하려면 `f`가 타입 생성자를 받는 *고계* 변수여야 합니다. 그게 HKT이고, Gleam엔 없습니다." 오답 ③ 피드백: "타입 단계까지 가지도 못합니다. `f(` 에서 파서가 먼저 멈춥니다 — 이것이 '결핍의 일관성'의 가장 순수한 형태입니다."

**예시 레슨 TU12-② 「재귀 스킴 — `fold`는 유일한 구조 존중 붕괴다」**

- 세그먼트 1 요지: U6에서 손으로 쓴 `sum_loop`, U8에서 만난 `list.fold` — 그 둘은 사실 같은 이름을 갖는다: **catamorphism(카타모피즘)**. 어떤 ADT든, 그 *각 생성자마다 함수 하나씩*을 주면 구조를 따라 한 번에 "붕괴(collapse)"시키는 연산이 정확히 하나 있다. 리스트의 두 생성자(`[]`, `[_, ..]`)에 `initial`과 `fn(acc, x)`를 준 게 `list.fold`였다. 트리도 똑같다 — 생성자가 `Leaf`/`Node` 둘이니, 함수도 둘 준다. 이 "생성자 개수 = 인자 개수" 대응이 catamorphism의 본질이다(검증된 예제: sum=6, depth=3).

```gleam
import gleam/int

pub type Tree(a) {
  Leaf(a)
  Node(Tree(a), Tree(a))
}

// catamorphism: Leaf용 함수 하나, Node용 함수 하나. 그 외 선택지는 없다.
pub fn fold_tree(tree: Tree(a), on_leaf: fn(a) -> b, on_node: fn(b, b) -> b) -> b {
  case tree {
    Leaf(value) -> on_leaf(value)
    Node(left, right) ->
      on_node(fold_tree(left, on_leaf, on_node), fold_tree(right, on_leaf, on_node))
  }
}

pub fn sum_tree(tree: Tree(Int)) -> Int {
  fold_tree(tree, fn(x) { x }, fn(l, r) { l + r })
}

pub fn depth(tree: Tree(a)) -> Int {
  fold_tree(tree, fn(_) { 1 }, fn(l, r) { 1 + int.max(l, r) })
}
```

- 연습 1 (P1 `predict`): `Node(Node(Leaf(1), Leaf(2)), Leaf(3))`에 대해 잎(Leaf)의 개수를 세는 catamorphism은 아래와 같다. 출력은?

```gleam
import gleam/io
import gleam/int

pub type Tree(a) {
  Leaf(a)
  Node(Tree(a), Tree(a))
}

pub fn fold_tree(tree: Tree(a), on_leaf: fn(a) -> b, on_node: fn(b, b) -> b) -> b {
  case tree {
    Leaf(value) -> on_leaf(value)
    Node(left, right) ->
      on_node(fold_tree(left, on_leaf, on_node), fold_tree(right, on_leaf, on_node))
  }
}

pub fn main() -> Nil {
  let t = Node(Node(Leaf(1), Leaf(2)), Leaf(3))
  let count = fold_tree(t, fn(_) { 1 }, fn(l, r) { l + r })
  io.println(int.to_string(count))
  Nil
}
```

  **정답 `3`** — 각 `Leaf`가 1을 내고, 각 `Node`가 두 자식을 더한다. 정답 코멘터리: "`on_leaf`가 *씨앗 값*, `on_node`가 *합치는 법*. 잎이 3개이니 1+1+1=3. 만약 `on_leaf = fn(x) { x }`, `on_node = fn(l, r) { l + r }`였다면 그건 `sum_tree`였고 1+2+3=6이었겠죠 — 같은 catamorphism, 다른 두 함수." 오답 `6` 피드백: "그건 잎의 *값*을 더한 `sum_tree`입니다. 여기서는 `on_leaf = fn(_) { 1 }` 이라 값을 버리고 1만 셉니다. catamorphism의 동작은 오직 당신이 넘긴 두 함수가 결정합니다." 오답 `2` 피드백: "`Node`는 두 개지만 우리가 세는 건 *잎*입니다. 내부 노드 수가 아니라 `Leaf` 호출 횟수를 세고 있다는 점을 보세요."

- 세그먼트 2 요지: catamorphism은 ADT를 *접어 없애는* 방향(아래→위)이다. 반대로 씨앗 하나에서 구조를 *펼쳐 만드는* 방향(위→아래)이 **anamorphism(ana)**, 둘을 합친 게 **paramorphism(para, 자식의 원본까지 함께 보는 fold)**이다 — 이름만 맛본다. 여기서 중요한 미묘한 점 하나: catamorphism은 *각 생성자마다 함수 하나*만 주면 무엇이든 될 수 있다. 결과 타입을 바꿀 수도(합·깊이), 심지어 같은 `Tree`를 다시 짓되 자식을 *재배치*할 수도 있다(예: 리스트 `reverse`도 fold로 표현된다). 즉 "catamorphism이다"가 곧 "구조를 보존한다"는 뜻은 *아니다*. functor map은 그 수많은 catamorphism 중 **구조를 그대로 보존하는**(생성자를 그 자리에서, 자식 순서를 유지한 채 다시 짓는) *특수한* 알지브라일 뿐이다 — 이 구별이 다음 연습의 핵심이다. 또 하나의 "정직한 한계": Gleam엔 *모든 ADT에 자동으로 도는 일반 fold*가 없다(그건 HKT가 필요하다, TU12①). 그래서 catamorphism은 타입마다 **손으로** 쓴다. 하지만 일단 보는 눈이 생기면, U6의 `sum_loop`도 U8의 `list.fold`도 위의 `fold_tree`도 *같은 패턴의 다른 인스턴스*임이 보인다 — 그것이 "이론은 패턴을 보는 눈"이다.

- 연습 2 (P8 `spot_bug`): 아래 세 개의 `fold_tree` 알지브라는 **셋 모두 적법한 catamorphism**이다. 그중 **functor map처럼 구조를 보존하지 *않는*(자식 순서를 재배치하는)** 것 하나를 고르라.
  보기:
  (a) `fold_tree(tree, fn(x) { [x] }, fn(l, r) { list.append(l, r) })` — 잎을 리스트로 모은다
  (b) `fold_tree(tree, fn(x) { x }, fn(l, r) { l + r })` — 합
  (c) `fold_tree(tree, fn(x) { Leaf(x) }, fn(l, r) { Node(r, l) })` — 좌우를 *뒤집어* 다시 트리로

  — **정답 (c)**.

  정답 코멘터리: "(c)도 형식상 **완전히 적법한 catamorphism**입니다 — 생성자마다 함수 하나(F-알지브라)를 주었고, 핀 1.17.0에서 컴파일·실행되어 좌우가 뒤집힌 `Tree`를 돌려줍니다. catamorphism은 자식을 *재배치*할 수 있습니다(리스트 `reverse`도 fold로 표현되듯). 다만 (c)는 `on_node`에서 `Node(r, l)`로 **자식 순서를 바꿔** 구조를 보존하지 *않으므로*, functor map의 골격으로는 부적격합니다. functor map은 '각 생성자를 그 자리에서, 순서를 유지한 채 대치'해야 하니까요. 구체적으로: (c)의 *알지브라*(`on_leaf = Leaf`, `on_node = fn(l, r) { Node(r, l) }`)를 그대로 `map_tree`의 골격으로 끼워 넣으면, 그 `map`은 identity 법칙 `map(t, id) == t`를 깨뜨립니다(자식이 뒤집혀 돌아오니까). 정리하면 — (c)는 *적법한 catamorphism*이지만 *구조 보존을 깨는* 변환이고, 그래서 *map의 골격으로 쓰면* 안 되는 것입니다." 오답 (a) 피드백: "(a)도 적법한 catamorphism이고, 구조를 보존합니다. `on_leaf`/`on_node`가 각각 잎과 노드를 *그 자리에서* 다른 타입(리스트)으로 대치할 뿐, 좌우 순서는 `list.append(l, r)`로 보존됩니다." 오답 (b) 피드백: "(b)는 교과서적 `sum_tree`입니다. 자리 바꿈 없이 두 자식 결과를 그냥 더하니 구조 존중이 완벽합니다 — 이 역시 적법한 catamorphism입니다."

**예시 레슨 TU12-③ 「종합 과제 — 나만의 `Tree`에 catamorphism·functor·법칙」**

- 세그먼트 요지(종합 write): 이제 TU9(functor 법칙)·U11②(`map_box` = `result.map`의 사촌)·이 유닛의 catamorphism을 *총동원*한다. `Tree(a)`에 ① `fold_tree`(catamorphism), ② 그것으로 정의한 `map_tree`(functor map), ③ functor 두 법칙(identity·composition)을 표본 검사하는 `main` 안 `assert`를 작성한다. Gleam엔 단일 Functor 추상이 없으므로(TU12①) 우리는 "`Tree`라는 *구체 타입에서 functor 패턴을 알아보고 손으로 구현*"하는 것이다 — 이것이 이 트랙의 마지막 정직한 진술이다. (검증된 예제 — `assert` 전부 통과해 정상 종료, 출력 없음)

```gleam
import gleam/function

pub type Tree(a) {
  Leaf(a)
  Node(Tree(a), Tree(a))
}

pub fn fold_tree(tree: Tree(a), on_leaf: fn(a) -> b, on_node: fn(b, b) -> b) -> b {
  case tree {
    Leaf(value) -> on_leaf(value)
    Node(left, right) ->
      on_node(fold_tree(left, on_leaf, on_node), fold_tree(right, on_leaf, on_node))
  }
}

// functor map을 catamorphism으로 정의한다: 구조는 그대로, 잎 값만 f로 옮긴다.
pub fn map_tree(tree: Tree(a), f: fn(a) -> b) -> Tree(b) {
  fold_tree(tree, fn(x) { Leaf(f(x)) }, fn(l, r) { Node(l, r) })
}

// 숨김 테스트: 법칙을 실행 가능한 프로퍼티로 표본 검사한다 (TU9 총동원).
pub fn main() -> Nil {
  let t = Node(Node(Leaf(1), Leaf(2)), Leaf(3))
  // identity 법칙: map(t, id) == t
  assert map_tree(t, function.identity) == t
  // composition 법칙: map(t, g∘f) == map(map(t, f), g)
  let inc = fn(x) { x + 1 }
  let dbl = fn(x) { x * 2 }
  assert map_tree(t, fn(x) { dbl(inc(x)) }) == map_tree(map_tree(t, inc), dbl)
  // 구조 보존 표본
  assert map_tree(Leaf(7), fn(x) { x * x }) == Leaf(49)
  Nil
}
```

- 연습 1 (P5 `write_fn`): `pub fn map_tree(tree: Tree(a), f: fn(a) -> b) -> Tree(b)`를 **`fold_tree`만 써서**(직접 `case` 재귀 금지) 작성하라. 숨김 테스트는 위 `main`의 세 `assert`(identity·composition·구조 표본)다.
  정답 코멘터리: "핵심은 `on_node`를 `fn(l, r) { Node(l, r) }`로 — 즉 **구조를 그대로, 자식 순서까지 유지한 채 다시 짓는** 것입니다. `on_leaf`에서만 `f`를 적용하죠. 방금 당신은 `Tree`에서 functor 패턴을 *알아보고* 구현했습니다. Gleam은 이걸 자동으로 안 해줍니다(HKT 없음) — 그래서 손으로, 그러나 catamorphism이라는 단 하나의 도구로." 흔한 오답 1 — `on_node`를 `fn(l, r) { Node(r, l) }`로: "동작은 컴파일·실행되고 그 자체로는 적법한 catamorphism이지만(TU12②-연습2의 (c) 바로 그것), 자식 순서를 뒤집으므로 *구조를 보존하지 않습니다*. 그래서 identity 법칙 `assert map_tree(t, id) == t`가 실패하며 크래시합니다 — `map(t, id) != t`가 되니까요." 흔한 오답 2 — `fold_tree` 대신 직접 `case`로 재귀: "동작은 맞을 수 있지만 이 과제의 요점은 *catamorphism이 map을 표현하기에 충분*함을 체득하는 것입니다. `fold_tree`로 환원하세요."

- 연습 2 (P2 `mcq`): "이 트랙을 마친 뒤, *단일 일반 Functor 추상* 같은 깊이를 더 배우려면 어디로?"
  보기:
  (a) Haskell / PureScript의 타입클래스 + HKT, 그리고 카테고리론 텍스트
  (b) Gleam에 타입클래스를 추가하는 컴파일러 플래그를 켠다
  (c) 본 플랫폼의 트레이닝 모드(레이팅 퍼즐·SRS)로 *Gleam 실전 관용구*를 굳힌다
  (d) (a)와 (c) 둘 다 — 이론의 깊이는 (a), 손에 붙이는 건 (c)
  — **정답 (d)**.
  정답 코멘터리: "이론의 깊이(왜 Functor/Monad가 *법칙으로* 정의되는가, HKT가 어떻게 단일 추상을 가능케 하는가)는 Haskell/PureScript와 카테고리론에서, *Gleam에서 그 패턴을 알아보고 손으로 쓰는 반사신경*은 본 플랫폼 트레이닝에서 굳힙니다. 두 길은 경쟁하지 않습니다 — 이론은 패턴을 보는 눈을 주고, 연습은 그 눈으로 코드를 짜게 합니다." 오답 (b) 피드백: "그런 플래그는 없습니다. 타입클래스 부재는 버그가 아니라 *설계*입니다(U14①: 에러 명료성·컴파일 속도·런타임 비용). '켜는' 게 아니라 '명시적 함수 전달'로 대체하는 겁니다." 오답 (a)만 피드백: "이론만으로는 Gleam 코드가 손에 붙지 않습니다. 패턴을 *보는* 것과 관용적으로 *쓰는* 것은 다른 근육입니다 — 그래서 (c)도 필요합니다."

**방출 태그**: `theory:no-hkt` `theory:catamorphism` `theory:recursion-scheme` `theory:capstone-theory` `theory:functor-laws` `theory:no-typeclass` `theory:why-not-faq` `theory:eager-eval` `theory:no-currying` `theory:patterns-as-eyes`

## 5. 이론 트리키 파트 카탈로그 → 트레이닝 세션 매핑

이론 트랙이 방출하는 트리키 파트. **노출 시점** = 해당 이론 유닛 완료 직후 트레이닝 세션에 그 테마 아이템이 서빙되기 시작하는 시점(실용 트랙 §5와 동일 계약). ★ = **핵심 이론 트리키 파트** — SRS 기본 등록 + Code Rush 고배점 테마.

| # | 트리키 파트 (canonical 태그) | 전형적 함정 | 노출 시점 | 주 퍼즐 타입 | 출처 유닛 |
|---|---|---|---|---|---|
| T1 | `theory:hidden-effect` | io.println의 반환 타입 Nil을 '아무것도 안 함 / 빈 값'으로 오해해, Nil 반환 함수를 '효과 없는 함수'로 착각한다. 사실 Nil은 '돌려줄 값이 없음 → 효과 때문에 부르는 함수'라는 신호이며, Nil을 String 등 진짜 값처럼 쓰려 하면 Type mismatch로 막힌다. | TU1 이후 | P4 | TU1 |
| ★T2 | `theory:referential-transparency` | 함수 호출을 그 결과값으로 치환하는 것이 항상 안전하다고 일반화한다. 그러나 함수 안에 숨은 효과(io.println)가 있으면 치환 시 효과가 사라져 의미가 변한다 — 참조 투명성은 순수 함수에만 성립한다. | TU1 이후 | P8 | TU1 |
| T3 | `theory:effects-as-values` | fn()으로 감싸 효과를 미루면 영영 실행 안 된다고 보거나, 반대로 정의 시점에 이미 실행된다고 본다. thunk는 ()로 부르기 전까지 잠들고, 부를 때마다 매번 다시 실행된다(자동 캐싱 없음, eager 평가). | TU1 이후 | P1 | TU1 |
| T4 | `theory:determinism` | 순수 함수 호출이 매번 다른 값을 낼 수 있다고 생각해, double(5)+double(5)에서 두 호출 결과가 다를 수 있다고 본다. 결정성은 같은 입력→항상 같은 출력을 보장한다. | TU1 이후 | P1 | TU1 |
| T5 | `theory:substitution-model` | 학습자가 치환(let을 정의로 펼치기)을 '컴파일러 최적화'로 오해하거나, 명령형 습관 탓에 이름이 중간에 값이 바뀔 수 있다고 가정한다. 치환이 안전한 진짜 근거는 불변성/참조 투명성임을 놓침. | TU2 이후 | P2 | TU2 |
| T6 | `theory:substitution-unsound-with-effects` | io.println 같은 효과식을 let으로 묶었다가 그 이름을 정의로 '펼치면' 효과 발생 횟수가 달라진다(1회→2회). eager 평가라 바인딩 순간 즉시 1회 실행되는데, 학습자는 let _ = logged 가 println을 다시 호출한다고 오해하거나, 게으름이 있다고 가정한다. | TU2 이후 | P1 | TU2 |
| T7 | `theory:refactor-is-rewrite` | map fusion 같은 리팩터에서 합성 순서를 뒤집어(times2(add1(x)) vs add1(times2(x))) 의미를 바꾸거나, 'Functor 일반 map'을 기대해 HKT/타입클래스 부재(U14)와 충돌. filter/map을 혼동해 타입 에러. | TU2 이후 | P6 | TU2 |
| T8 | `theory:structural-induction` | 귀납 단계에서 정의를 '한 단계' 펼치는 것과 '귀납 가설 적용 후'를 혼동(1 + length(append(rest,ys)) 대 1 + length(rest) + length(ys)). 또는 length([_, ..t]) = 1 + length(t)의 +1을 누락해 기저/단계 등식을 잘못 닫음. | TU2 이후 | P2 | TU2 |
| T9 | `theory:equational-reasoning` | 리팩터가 '등식 보존'이라는 주장을 검증 없이 받아들임. fold 초기값을 0→1로 바꾸면 기저 등식(sum([])==0)부터 깨져 모든 답이 1만큼 어긋나는데, 표면이 비슷해 spot 실패. 손으로 쓴 재귀=list.fold(U8) 동치는 보존됨을 구별 못함. | TU2 이후 | P8 | TU2 |
| T10 | `theory:eager-vs-lazy` | 학습자는 쓰이지 않는 인자(`_b`)는 평가되지 않으리라 기대한다(lazy 직관). Gleam은 eager라 사용 여부와 무관하게 호출 전에 모든 인자를 평가한다. | TU3 이후 | P1 | TU3 |
| T11 | `theory:evaluation-order` | normal order(lazy)가 applicative order(eager)보다 '항상 더 효율적'이라는 오해. 실제로는 thunk 생성·관리 비용과 (공유 없을 시) 재평가 비용이 있고, lazy의 장점은 속도가 아니라 종료성 보장이다. | TU3 이후 | P2 | TU3 |
| T12 | `theory:short-circuit` | 단락 평가를 lazy 언어 전용 기능으로 오해. eager인 Gleam에도 `&&`/`\|\|`·`bool.guard`라는 언어 차원의 단락이 있으며 이것이 미평가를 표현하는 거의 유일한 내장 수단이다. | TU3 이후 | P2 | TU3 |
| T13 | `theory:eager-eval-surprise` | `bool.guard(return:)`·`option.unwrap(or:)`처럼 '기본값'을 받는 함수에 비싸거나 크래시할 식을 직접 넘기면, 그 가지가 선택되지 않아도 eager 인자로 먼저 평가된다(또는 크래시한다). lazy 변종(`lazy_guard`/`lazy_unwrap`)이나 case가 필요하다. | TU3 이후 | P8 | TU3 |
| T14 | `theory:thunk` | `fn() { expr }`를 넘기면 `expr`이 이미 실행됐다고 착각. 함수 값을 만드는 것과 그 함수를 호출하는 것은 다르다 — thunk 안의 식은 `thunk()`로 강제할 때만 환원된다. | TU3 이후 | P1 | TU3 |
| T15 | `theory:normal-order-termination` | 두 평가 순서가 같은 결과를 낸다는 가정. 쓰이지 않는 인자가 발산(무한 루프)할 때 normal order는 종료하지만 eager는 그 인자를 먼저 평가하다 종료하지 못한다 — 순서가 결과(종료성)를 바꾼다. | TU3 이후 | P2 | TU3 |
| ★T16 | `theory:cardinality-miscount` | 함수 타입 fn(a)->b 의 값 개수를 \|a\|^\|b\|(정의역^공역)로 뒤집어 셈 — 올바른 공식은 \|b\|^\|a\|(출력^입력). fn(3원소)->Bool 에서 3^2=9(틀림) vs 2^3=8(맞음)으로 드러난다. (tricky 부류 슬러그; 개념 슬러그 theory:cardinality 와 의도적 분리, 둘 다 emittedTags 등록.) | TU4 이후 | P8 | TU4 |
| T17 | `theory:unit-void-types` | Nil(카디널리티 1, 값이 정확히 하나)을 0으로 착각하고, 생성자 없는 pub type Void(카디널리티 0, 값 생성 불가)와 혼동. void 타입을 값으로 쓰면 'X is a type, it cannot be used as a value' 컴파일 에러. | TU4 이후 | P2 | TU4 |
| T18 | `theory:sum-product-types` | Option(a)=\|a\|+1 을 곱(\|a\|×1 또는 \|a\|×2)으로 오인. None은 값 0개를 더하는 갈래라 합이지 곱이 아님 — Option(Bool)=3이지 4가 아니다. Result(a,e)=\|a\|+\|e\| 도 같은 합 패턴. | TU4 이후 | P1 | TU4 |
| T19 | `theory:adt-algebra` | +·×·^ 가 타입의 '대수'로 대응한다는 것을 비유로만 받아들이고, 거듭제곱이 반복된 곱(fn 열거 = 입력마다 출력 독립 선택)임을 놓침. 더해서 \|b\|^\|a\| 셈이 전역·순수 함수에만 정확하다는 단서(시그니처는 panic/발산/부수효과를 막지 않음)도 흘리기 쉬움. TU5의 동형/항등원 논의로 가는 다리를 놓치기 쉬움. | TU4 이후 | P8 | TU4 |
| T20 | `theory:type-isomorphism` | 동형을 '같은 타입'으로 오해하거나(정보량만 같지 타입은 다름 — to/from을 명시적으로 거쳐야 함), 한 방향 변환만 보고 동형이라 단정한다(왕복 항등 to∘from=id·from∘to=id 양쪽 다 필요). | TU5 이후 | P1 | TU5 |
| T21 | `theory:cardinality-modelling` | 정당한 상태 수보다 카디널리티가 큰 타입(#(Bool,Bool)=4인데 정당 상태 3)을 쓰면 의미 없는 초과 상태(#(True,True))가 표현 가능해져 버그 문이 열린다. exhaustiveness 에러가 그 초과 칸을 폭로하지만, _ -> 로 메우는 대신 카디널리티를 정당 상태 수에 맞춘 합타입으로 옮기는 것이 정답(make-illegal-states-unrepresentable, U12 연결). | TU5 이후 | P1 | TU5 |
| T22 | `theory:false-isomorphism` | 카디널리티가 같다(또는 같아 보인다)는 이유만으로 동형이라 착각하는 가짜 동형. Bool↔Int(int_to_bool(n)=n!=0)처럼 back-map이 여러 값을 한 값으로 뭉개면 왕복 항등이 깨지는 손실 변환 = 동형이 아니라 단사일 뿐. 카디널리티 같음은 필요조건이지 충분조건이 아님(왕복 항등까지 성립해야 함). | TU5 이후 | P8 | TU5 |
| T23 | `theory:curry-howard` | 타입=명제, 값=증명 대응을 외형만 받아들이고 'Gleam 함수가 컴파일되면 그 명제가 증명된 것'으로 착각한다. 실제로는 panic/todo/무한루프/let assert 가 있는 함수도 컴파일되므로 Gleam은 일관된(consistent) 증명 논리가 아니다 — Nil↔참은 맞지만 void↔거짓에서 ex falso는 컴파일러가 증명해 주지 않고 panic으로 메운다. | TU6 이후 | P2 | TU6 |
| T24 | `theory:parametricity` | 제네릭 시그니처가 구현을 제약한다는 직관 자체를 못 잡아서, fn(a,b)->a 의 출력으로 둘째 인자(타입 b)나 b 값을 답으로 고른다. 반환 타입 a 자리에는 첫 인자(또는 그로부터 나온 a)만 올 수 있다는 것을 시그니처만으로 읽어내지 못한다. | TU6 이후 | P1 | TU6 |
| T25 | `theory:free-theorems` | fn(List(a))->List(a) 가 입력에 없던 새 원소(상수)를 끼워 넣을 수 있다고 믿는다. 원소 타입 a 를 모르므로 새 a 를 만들 수 없고([5,..xs] 는 Type mismatch), 출력 원소는 모두 입력에서 온다는 공짜 정리를 놓친다. 반대 함정(과대주장)도 막아야 한다: 이 정리는 '길이'를 보장하지 않는다 — 복제·재배열은 가능하므로 list.append(xs,xs)(길이 3→6)가 같은 시그니처의 반례다. 보장의 핵심은 '출력 원소의 출처가 입력'이지 '길이 불변'도 '부분수열·순열'도 아니다. | TU6 이후 | P8 | TU6 |
| T26 | `theory:parametricity-overclaim` | 'fn(a)->a 는 항등뿐'을 무조건 참인 법칙으로 과대주장한다. Gleam은 totality·순수성을 강제하지 않으므로(panic/let assert/io 가능) 같은 시그니처의 비항등 함수가 컴파일된다 — 공짜 정리에는 '순수·전체라면' 단서가 필수이며 그 책임은 작성자(U13/U14)에게 있다. | TU6 이후 | P8 | TU6 |
| T27 | `theory:composition` | stdlib에 compose/`>>`가 있다고 가정하거나, compose가 평범한 함수가 아니라 임의의 Functor/Monad에도 일반적으로 동작한다고 착각(HKT·타입클래스 부재로 불가능) | TU7 이후 | P6 | TU7 |
| T28 | `theory:identity-law` | id를 한쪽(앞 또는 뒤)에만 붙여도 되는 줄 알거나, `function.identity` 정의(identity(y)==y)를 법칙 위반과 혼동 | TU7 이후 | P8 | TU7 |
| T29 | `theory:composition-associativity` | compose 3개에서 괄호 위치가 결과를 바꾼다고 착각하거나, 적용 순서를 거꾸로 세어 안쪽 함수를 빠뜨림 | TU7 이후 | P1 | TU7 |
| T30 | `theory:composition-order` | 수학 합성 f∘g(g 먼저)와 파이프 x\|>g\|>f(읽기=실행 g 먼저)의 읽기 방향이 반대임을 혼동 — compose의 첫 인자가 나중에 실행됨을 놓쳐 비교환 합성의 값을 뒤바꿈 | TU7 이후 | P1 | TU7 |
| T31 | `theory:monoid` | 모노이드를 '구현해야 하는 인터페이스/타입클래스'로 오해 — Gleam엔 타입클래스도 HKT도 없어 '모든 모노이드에 동작하는 단일 일반 함수'는 작성 불가. 타입마다 (e, ⊕)를 fold에 손으로 넘기는 게 관용(U14① 연결). | TU8 이후 | P2 | TU8 |
| ★T32 | `theory:monoid-laws` | 법칙을 '암기할 문구'로만 보고 검증 가능한 등식임을 놓침. 결합법칙·좌우 항등을 표본 입력에 assert로 실행하면 참/거짓이 즉시 드러난다. 단 표본 assert는 *증명*이 아니라 *반증 시도*(프로퍼티 테스트의 축소판) — 한 표본 통과가 모든 입력 보장은 아님. 실패한 assert는 반환이 아니라 크래시(예외 없음). | TU8 이후 | P1 | TU8 |
| T33 | `theory:monoid-fold` | U8에서 손으로 쓴 list.fold(xs, e, ⊕)가 사실은 '모노이드로 요약하기'임을 못 알아봄. sum/product/join_all이 같은 fold 골격에 (e, ⊕)만 갈아 끼운 것임을 인식하지 못하고 매번 새로 짠다. P6 재작성(골격 추출, (e,⊕)를 값으로 들고 다니기)으로 등식 보존하며 패턴을 드러낸다. | TU8 이후 | P6 | TU8 |
| ★T34 | `theory:monoid-non-associativity` | 뺄셈·나눗셈·평균을 모노이드로 착각. (10-4)-3=3 ≠ 10-(4-3)=9, avg(avg(0,10),20)=12.5 ≠ avg(0,avg(10,20))=7.5 — 비결합이면 fold의 묶는 순서가 결과를 바꾸고 분할정복/병렬화 정당화가 깨진다(map-reduce 직관, TU1 RT 연결). 평균은 항등원도 없다. Gleam에서 실제 예제로 보이면 평균은 Float 연산이므로 +. /. 와 2.0 을 써야 한다(예: { a +. b } /. 2.0). | TU8 이후 | P1 | TU8 |
| T35 | `theory:wrong-identity-element` | (Int, *)의 항등원을 1이 아닌 0으로, (Bool, &&)의 항등원을 True가 아닌 False로 사용. 0*a==0, False&&a==False처럼 흡수원을 항등원으로 착각하면 fold가 컴파일은 통과하면서 조용히 틀린 값을 낸다. | TU8 이후 | P8 | TU8 |
| T36 | `theory:functor` | map이 포장을 벗긴다고 착각(Some(15)을 맨몸 15로 예측), 또는 None/Error에도 함수가 적용된다고 오해. 펑터=구조 보존+내용물만 변환이라는 핵심을 놓침. | TU9 이후 | P1 | TU9 |
| ★T37 | `theory:functor-laws` | 항등/합성 법칙을 추상 약속으로만 보고 실행 가능한 프로퍼티로 못 적음. 합성 법칙에서 map(map(x,g),f)와 map(x, f∘g)의 순서(g 먼저, f 나중)를 뒤집음. | TU9 이후 | P5 | TU9 |
| T38 | `theory:functor-instances` | list/option/result/함수합성/직접 만든 Box가 모두 같은 패턴임을 못 알아봄. 각 타입의 map을 별개의 무관한 함수로 기억(map_box가 result.map의 사촌임을 놓침). | TU9 이후 | P2 | TU9 |
| ★T39 | `theory:functor-law-violation` | 시그니처만 맞으면 진짜 펑터라고 믿음. reverse/중복/누락이 끼어든 가짜 map이 타입검사를 통과하지만 항등·합성 법칙을 깬다는 걸 못 봄(U8-④ fold-reverse 함정 가족의 재등장). | TU9 이후 | P8 | TU9 |
| ★T40 | `theory:no-hkt` | '모든 펑터에 동작하는 단일 map'을 쓸 수 있다고 가정(Haskell Functor f => 사고). f(a)처럼 타입변수를 타입에 적용하면 Type mismatch가 아니라 Syntax error로 막힌다는 것, 그래서 타입마다 map을 따로 불러야 한다는 정직한 한계(U14① 타입클래스 없음 FAQ)를 인지 못함. | TU9 이후 | P2 | TU9 |
| T41 | `theory:monad` | use/result.try를 '특수 문법'으로 보고 모나드라는 패턴 이름을 못 알아본다. U10에서 이미 모나드를 썼다는 사실을 놓침. | TU10 이후 | P1 | TU10 |
| ★T42 | `theory:monad-laws` | 좌항등을 try(Ok(a), f) == Ok(a)로 잘못 적음(실제는 f(a)). 우항등의 Ok가 '순수/return' 역할임을 모름. 법칙을 암기 대상으로만 보고 실행 가능한 프로퍼티(assert 표본검사)로 다루지 못함. | TU10 이후 | P8 | TU10 |
| T43 | `theory:applicative` | 독립적 두 맥락 결합(case a,b 또는 use 2개+Ok)을 의존적 순차와 혼동. 결합 단계에서 마지막 Ok(...) 재포장을 빠뜨려 타입 불일치. | TU10 이후 | P7 | TU10 |
| T44 | `theory:bind-vs-map` | 콜백 반환이 맨몸 값인지 맥락에 싼 값인지로 map/try를 골라야 하는데 반사적으로 한쪽만 씀. 콜백이 Result를 주는데 map을 써서 맥락 한 겹을 더 쌓음. | TU10 이후 | P1 | TU10 |
| T45 | `theory:map-vs-bind-confusion` | result.map으로 Result-반환 콜백을 처리해 Result(Result(a,e),e) 중첩을 만들고 평탄화를 기대함. 중첩 맥락을 try로 흡수해야 함을 모름. | TU10 이후 | P1 | TU10 |
| ★T46 | `theory:no-hkt` | Monad/Applicative 타입클래스나 HKT가 있다고 가정해 '모든 모나드 공통 sequence/bind'를 작성하려 함. result.try가 Option을 받지 못함을 모름. use를 타입클래스 디스패치로 오해. | TU10 이후 | P8 | TU10 |
| T47 | `theory:beta-reduction-capture` | (λx.λy.x)에 자유변수 y를 순진하게 치환하면 안쪽 λy가 그 y를 '포획'해 상수함수가 다른 함수로 둔갑한다. 학습자는 α-변환(개명) 없이 그대로 끼워넣는 실수를 한다. | TU11 이후 | P8 | TU11 |
| T48 | `theory:church-encoding` | Gleam은 정적 타입이라 하나의 Church pair 값을 cfst와 csnd에 둘 다 넘기면 셀렉터 반환 타입 c가 양립 불가하게 고정되어 타입 불일치가 난다(untyped λ엔 없는 제약). HKT/타입클래스 부재의 같은 뿌리. | TU11 이후 | P5 | TU11 |
| T49 | `theory:eager-fixpoint` | 순진한 Y(η-확장 없는 f(rf(r)))는 Gleam이 eager라서 인자가 도착하기 전 구성 시점에 무한 루프/스택오버플로로 발산한다. lazy 언어라면 동작한다는 착각. Z는 fn(v){...(v)}로 지연. | TU11 이후 | P8 | TU11 |
| ★T50 | `theory:beta-reduction` | (λx.x+x)3의 본문 치환을 문자열 결합(33)으로 착각. β-환원은 값 치환이며 Gleam의 Int +는 문자열 <>와 다르다. | TU11 이후 | P1 | TU11 |
| T51 | `theory:fixpoint` | Gleam에 named recursion이 있어 Y/Z가 불필요한데, 학습자가 이론 시연(Rec/Z)을 실무 패턴으로 오해해 계승을 콤비네이터로 작성하려 한다. | TU11 이후 | P2 | TU11 |
| T52 | `theory:church-numerals` | Church 곱셈을 덧셈(m(f, n(f,x)))으로 잘못 정의. 곱셈은 'n번-적용' 덩어리를 m번 반복해야 하므로 m의 함수 인자에 fn(y){n(f,y)}를 통째로 넘겨야 한다. | TU11 이후 | P5 | TU11 |
| ★T53 | `theory:no-hkt` | 타입 변수 f를 List/Option처럼 타입 생성자로 착각해 f(a)로 적용하려 함 — '아무 컨테이너에나 도는 단일 map'을 쓸 수 있다고 기대. 실제로는 Gleam에 고계 타입(HKT)이 없어 타입 단계가 아니라 문법 단계에서 거부된다(제목 Syntax error, 메시지 I was not expecting this, 캐럿이 f 뒤 여는 괄호를 가리킴). #(a,a)·Result(a,e)처럼 컨테이너 모양이 시그니처에 고정된 1차 제네릭과 혼동. | TU12 이후 | P8 | TU12 |
| T54 | `theory:catamorphism` | 'catamorphism = 구조를 보존(재배치 안 함)'이라고 잘못 등치. 실제로는 각 생성자마다 함수 하나만 주면 무엇이든 catamorphism이며, on_node에서 자식을 재배치(Node(r,l))해도 여전히 적법한 catamorphism이다(리스트 reverse도 fold). functor map은 그중 '구조를 보존하는'(자리·순서 유지) 특수 알지브라일 뿐. 재배치 알지브라를 map의 골격으로 쓰면 functor identity 법칙(map(t,id)==t)이 깨진다 — '깨는 것은 catamorphism임이 아니라 구조 보존성'. | TU12 이후 | P8 | TU12 |
| T55 | `theory:recursion-scheme` | leaf-count(on_leaf=fn(_){1})와 sum(on_leaf=fn(x){x})을 같은 fold_tree의 다른 두 함수 선택으로 보지 못하고 출력을 혼동(3 vs 6). 생성자 개수=fold에 넘기는 함수 개수라는 대응을 놓침. ana/para는 이름 맛보기일 뿐 Gleam엔 자동 일반 fold가 없어 타입마다 손으로 쓴다는 한계와 묶임. | TU12 이후 | P1 | TU12 |
| T56 | `theory:capstone-theory` | Tree에 map_tree를 직접 case 재귀로 짜거나 on_node를 Node(r,l)로 잘못 짜서 identity 법칙 assert가 크래시. Node(r,l) 알지브라는 그 자체로는 컴파일·실행되는 적법한 catamorphism이지만 구조를 보존하지 않아 map의 골격으로는 부적격. 또한 Gleam이 functor를 자동 제공한다고 착각 — 실제로는 '구체 타입 Tree에서 functor 패턴을 알아보고 손으로 구현'해야 하며(HKT/타입클래스 없음), 깊은 이론은 Haskell/PureScript·카테고리론, 실전 반사신경은 본 플랫폼 트레이닝으로 분리됨. | TU12 이후 | P5 | TU12 |

> 연계 규칙은 실용 트랙과 동일하다(PLAN §3.4): 레슨에서 틀린 마이크로 연습은 태그와 함께 실패 로그로 적재되어 개인화 재훈련 큐에 들어가고, 유닛 완료 시 해당 테마가 트레이닝 풀에 편입된다. 이론 트리키 파트는 대부분 무컴파일(P1/P2/P8)이라 모바일·Code Rush 친화적이며, 법칙류(`functor-laws`·`monad-laws`·`monoid-laws`)는 P5/P8로 *실행 가능한 프로퍼티 검사*로도 출제된다.

## 6. 태그 레지스트리 확장 — `theory:` 네임스페이스

이론 트랙은 `content/registry/tags.toml`에 신규 `[theory]` 섹션을 추가한다(기존 `[concept]` Exercism 36 / `[tricky]` 16과 병렬). 콘텐츠 파일은 `theory:<slug>` 직렬 표기(core/types.tag_key)로 참조하며, 미등록 태그는 빌드가 거부한다 — 실용 트랙과 동일 규칙. 아래가 이 문서가 방출하는 전체 `theory` 슬러그(64개)다.

```toml
[theory]
# FP 이론 트랙(docs/design/fp-theory-curriculum.md)이 방출하는 슬러그.
# 개념 슬러그와 트리키 슬러그를 한 네임스페이스로 묶는다(이론 트랙에선 둘의 경계가 흐릿 —
# 법칙 위반 자체가 개념이자 함정이므로).
slugs = [
  # ── TL1 함수와 계산의 본질 ──
  "determinism",
  "eager-eval-surprise",
  "eager-vs-lazy",
  "effects-as-values",
  "equational-reasoning",
  "evaluation-order",
  "hidden-effect",
  "normal-order-termination",
  "purity",
  "refactor-is-rewrite",
  "referential-transparency",
  "short-circuit",
  "side-effect",
  "structural-induction",
  "substitution-model",
  "substitution-unsound-with-effects",
  "thunk",
  # ── TL2 타입의 대수 ──
  "adt-algebra",
  "cardinality",
  "cardinality-miscount",
  "cardinality-modelling",
  "curry-howard",
  "false-isomorphism",
  "free-theorems",
  "parametricity",
  "parametricity-overclaim",
  "sum-product-types",
  "type-isomorphism",
  "unit-void-types",
  # ── TL3 구조 위의 추상화 — 패턴이지 타입클래스가 아니다 ──
  "applicative",
  "bind-vs-map",
  "composition",
  "composition-associativity",
  "composition-order",
  "functor",
  "functor-instances",
  "functor-law-violation",
  "functor-laws",
  "identity-law",
  "map-vs-bind-confusion",
  "monad",
  "monad-laws",
  "monoid",
  "monoid-fold",
  "monoid-laws",
  "monoid-non-associativity",
  "no-hkt",
  "wrong-identity-element",
  # ── TL4 토대와 한계 ──
  "beta-reduction",
  "beta-reduction-capture",
  "capstone-theory",
  "catamorphism",
  "church-encoding",
  "church-numerals",
  "eager-eval",
  "eager-fixpoint",
  "fixpoint",
  "lambda-calculus",
  "no-currying",
  "no-typeclass",
  "patterns-as-eyes",
  "recursion-scheme",
  "turing-complete",
  "why-not-faq",
]
```

### 6.1 트레이닝 시스템에 넘기는 인터페이스 요약

- **아이템 스키마**: 실용 트랙과 동일(PLAN §4.1·§5.4). 이론 아이템은 `themes: ["theory:<주>", ...]`를 달고, 대부분 `puzzle_type ∈ {predict, mcq, spot_bug}`(무컴파일)이라 `mobile_friendly=true`·`rush_eligible=true`. 법칙 검사형은 `write_fn`/`spot_bug`(`grading=tests`, 숨김 테스트가 표본 입력에서 `assert <법칙>`).
- **SRS 출처**: ★ 핵심 이론 트리키 파트(`functor-laws`·`monad-laws`·`monoid-laws`·`cardinality`·`beta-reduction`·`no-hkt`·`referential-transparency`)가 `srs_eligible=true`. 패밀리 변형은 파라미터(법칙에 넣는 표본 함수/값, 카디널리티 문제의 타입)를 회전시켜 암기를 막는다.
- **seed_tier**: 이론 트랙은 실용 레이팅과 별개의 테마 서브 레이팅으로 측정. TL1~TL2는 티어 3~5(1200~1600), TL3은 4~6(1400~1800), TL4(람다 계산·캡스톤)는 6~8(1800~2300) 권장 — 시드는 RD 350으로 자가 보정.

---

## 7. 범위 밖(scope-out) & 정직성 원칙

### 7.1 no-HKT 천장 — 한 번 못 박는 정직성

Gleam에는 **고계 타입(higher-kinded types)이 없다.** 타입 변수는 *완성된 타입*만 받을 수 있고, `List`·`Option`·`Result` 같은 **타입 생성자 자체를 변수로 추상화할 수 없다**(`fn map(c: f(a)) -> f(b)`의 `f(a)`가 TU9에서 실제로 Syntax error로 막힌다). 따라서:

- 펑터·모노이드·모나드는 **구현하는 인터페이스가 아니라 알아보는 패턴**이 천장이다. "아무 펑터에나 동작하는 단일 `map`", "아무 모나드에나 동작하는 `sequence`"는 Gleam에서 작성 불가다.
- 이것은 결함이 아니라 **교육 언어로서의 의도된 선택**이다 — 공식 FAQ(U14① 인용)는 타입클래스/HKT가 "혼란스러운 에러 메시지·긴 컴파일 시간·런타임 비용"을 부른다고 본다. 본 트랙은 이 트레이드를 숨기지 않고, 매 추상화 유닛에서 정면으로 가르친다.

### 7.2 의도적으로 다루지 않는 것

no-HKT 천장 위에 있거나, 패턴 인식의 범위를 넘는 주제는 다루지 않는다. 각각은 "어디로 가면 만나는가"만 TU12에서 포인터로 남긴다.

| 다루지 않는 것 | 이유 | 어디서 |
|---|---|---|
| 타입클래스/딕셔너리 패싱으로 펑터·모나드 *인터페이스 흉내* | no-HKT 천장. 흉내는 가능해도 비관용·취약하며 본 트랙의 "정직성" 원칙에 반함 | Haskell/PureScript/Scala (TU12 다음 경로) |
| 자연 변환·수반(adjunction)·극한 등 본격 카테고리론 | 이름(카테고리)만 TU7에서 맛보기. 패턴 인식의 범위를 넘음 | 카테고리론 텍스트 (TU12) |
| 의존 타입·정제 타입(refinement) | Gleam 타입 시스템 밖. opaque + smart constructor(U12)가 런타임 검증으로 *근사* | Idris/Agda (TU12) |
| 효과 시스템·대수적 효과·free monad·comonad | HKT 위에 서는 구조. Gleam은 효과를 타입으로 추적하지 않음(TU1 정직성 노트) | (포인터만) |
| 게으른 무한 구조의 본격 다룸 | 언어가 eager. `gleam_yielder`는 stdlib 밖 라이브러리 | TU3에서 맛보기 + 라이브러리 안내 |
| OTP/actor의 동시성 이론 | Erlang 타깃 전용, 브라우저 실행 불가 | 실용 U15(읽기 전용) |

### 7.3 마무리 — "이론은 패턴을 보는 눈"

이 트랙의 목표는 학습자를 카테고리론자로 만드는 것이 아니다. **이미 써본 코드에서 반복되는 모양을 알아보고, 그 모양이 지키는 법칙을 실행해 확인하고, Gleam이 그 추상화를 어디까지 표현하고 어디서 멈추는지를 정직하게 아는 눈**을 주는 것이다. 그 눈을 얻은 학습자는 `result.try`를 보며 "아, 이건 bind고 단락은 모나드 법칙의 귀결이지"라고 읽고, 새 `map`을 만들 때 펑터 법칙을 반사적으로 `assert`로 건다. 이론은 트레이닝(자동화)과 실용(생산)을 잇는 세 번째 다리다.

---

## 8. 다른 문서와의 관계 & 후속 작업 체크리스트

- **[`curriculum.md`](curriculum.md)** (실용 트랙 U1–U15): 본 트랙의 모든 선수이자 "구체 사례"의 출처. 표기 차이 주의 — curriculum.md는 구 E1–E6, 본 문서·PLAN은 현행 P1–P8.
- **[`../../PLAN.md`](../../PLAN.md)**: 퍼즐 레지스트리(§4.1 P1–P8), 채점 하니스(§5.2), CI 골든(§5.3), SRS(§4.4)의 단일 기준. 본 트랙은 이를 그대로 소비한다.
- **[`training-system.md`](training-system.md)**: `theory:` 테마가 레이팅·SRS·Code Rush로 흘러가는 메커니즘.

후속 작업(콘텐츠 repo 투입 시):

1. **태그 레지스트리 확장** — `content/registry/tags.toml`에 §6의 `[theory]` 섹션(64 슬러그) 추가. 빌드 검증(`tools/build-content.mjs`)이 `theory:` 네임스페이스를 인식하도록 확장.
2. **PLAN/README 반영** — PLAN §3에 이론 트랙을 부가 트랙으로 등재(실용 v1 이후 릴리스), README 콘텐츠 현황에 한 줄 추가.
3. **골든 재검증** — 본 문서 예제는 핀 1.17.0에서 검증되었으나, 콘텐츠 TOML로 옮길 때 CI 골든(PLAN §5.3)으로 스냅샷 고정(특히 처치 인코딩·법칙 assert·의도적 컴파일 에러 7종의 에러 제목).
4. **저작 비용** — 이론 레슨은 실용 레슨보다 코드가 적고 P1/P2/P8 비중이 높아 저작이 가볍다(≈ 레슨당 2.5h 추정). 37레슨 + 4체크포인트 ≈ **약 110시간**.
