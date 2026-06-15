# Gleam FP 학습 플랫폼 계획

> 작성일 2026-06-13 · 1인 개발 · 기준 컴파일러: **Gleam v1.17.0 (browser WASM, 2026-06-02 릴리스) + gleam_stdlib 1.0.3 핀 고정**
>
> 본 문서는 커리큘럼·트레이닝·아키텍처 세 설계안을 단일 계획으로 통합한 것이다. 세 설계안에서 충돌했던 항목(퍼즐 타입 분류, 태그 어휘, 채점 하니스, 워커 구조, 타임드 모드, 마일스톤 규모, SRS 게이팅, 수치 파라미터)은 본 문서의 결정이 유일한 기준(canonical)이다.
>
> **컴파일러 버전 정합성 원칙**: 기존 설계안의 코드/에러 메시지는 1.16.0에서 검증되었으나 플랫폼은 v1.17.0을 핀한다. 따라서 **모든 인용 에러 텍스트·predict 정답·todo 힌트 문구는 콘텐츠 repo 투입 시 CI 골든 검증(§5.3)이 핀 버전 1.17.0의 WASM 컴파일러로 전수 재검증·스냅샷 고정**하며, 골든을 통과하지 못한 콘텐츠는 배포되지 않는다. 1.16.0 검증본은 "후보"일 뿐 출처가 아니다. 재검증은 M1 첫 주 작업(§8-②)이다.

---

## 1. 비전과 컨셉

체스 학습은 지난 10년간 "구조화된 레슨 → 레이팅 퍼즐 → 타임드 드릴 → 간격 반복"이라는 검증된 기계로 진화했다(chess.com 레슨, lichess 퍼즐/Storm/Streak, Chessable MoveTrainer). 프로그래밍 학습에는 이 기계의 완성형이 없다: Execute Program은 SRS 메커니즘을 갖췄지만 FP 콘텐츠가 없고, Codewars는 레이팅이 있지만 Gleam과 커리큘럼이 없으며, Exercism은 Gleam 콘텐츠가 있지만 경쟁·스케줄링을 의도적으로 배제한다. **이 교집합 — "lichess/Chessable for functional programming" — 은 비어 있다.** 본 플랫폼은 Gleam(작은 표면적, 친절한 컴파일러, 공식 브라우저 WASM 컴파일러)을 타깃 언어로, 레슨 세션(개념 학습)과 트레이닝 세션(레이팅 퍼즐·타임드 드릴·SRS 복습)을 하나의 rated-attempt 프리미티브 위에 쌓아 올린 정적 사이트로 시작한다. 실행 서버 0대, 콘텐츠가 곧 제품이다.

| 체스 플랫폼 메커니즘 | 본 플랫폼의 대응 |
|---|---|
| chess.com 레슨: 개념 영상 → 5~10개 보드 챌린지, 모든 수에 코멘터리 | 설명 세그먼트 → 5~10개 마이크로 연습, 정답·오답 모두 즉각 피드백 |
| 4 스킬 레벨 > 코스 > 레슨, 순차 잠금 + 건너뛰기 확인 | 레벨(4) > 유닛(15) > 레슨(~62), 순차 해제 + 확인 프롬프트 |
| lichess 퍼즐 = 유저 vs 퍼즐의 Glicko-2 rated 대국 | 첫 무힌트 시도 = rated 이벤트, 퍼즐도 레이팅·RD 보유 |
| 퍼즐 테마 태그(fork, pin…) + 테마별 대시보드 | 단일 태그 레지스트리(개념 36 + 트리키 16), 테마 서브 레이팅 |
| Puzzle Rush / Storm / Streak | Code Rush(통합 타임드 모드) + Streak |
| Chessable MoveTrainer 8레벨 SRS, 실패 시 L1 리셋 | 8레벨 간격(4h~6mo) SRS, 패밀리 변형 회전으로 암기 방지 |
| Execute Program: 리뷰 통과해야 다음 잠금, 재시도 무벌점 | 레벨 해제 = SRS 1회차 리뷰 통과, '정답 보기'만 벌점 |
| lichess "Learn from your mistakes" | 실패 시도 로그 → 테마별 약점 큐 재출제 |
| 온보딩 레이팅 추정(첫 퍼즐들로 빠른 수렴) | 배치 테스트(5분, 무컴파일 문항)로 초기 레이팅·유닛 선해제 |

---

## 2. 핵심 사용자 경험

**하루 사용 흐름 (정착 후 ~20분):**

1. **복습 큐 (5~10분)** — 접속 시 SRS due 카드 우선 노출. 카드는 (테마,타입) 패밀리이며 매번 파라미터 변형이 출제되어 답 암기가 불가능. 큐 소진이 데일리 스트릭의 기본 충족 조건.
2. **레슨 1개 (5~10분)** — 현재 유닛의 다음 레슨. 설명 세그먼트와 마이크로 연습 교차, 완료 시 핵심 아이템 2~4개가 SRS에 등록되고 레슨 태그가 "학습됨"으로 전환 → 트레이닝 풀에 해당 테마 즉시 편입.
3. **트레이닝 (5분~)** — 믹스드 rated 퍼즐 몇 개, 또는 약점 테마 드릴, 또는 Code Rush 한 판. 레슨이 가르친 것을 트레이닝이 자동화(automaticity)한다.

**맞물림 규칙**: 레슨이 태그를 열고(학습 전 테마 퍼즐은 서빙 안 함), 트레이닝 실패가 복습 큐를 채우고, 복습 통과가 다음 레벨을 연다. 레벨 해제 게이트(첫 리뷰 4h~1d)는 "오늘 배운 것을 오늘 저녁에 한 번 더"를 강제한다 — 대기 중에는 카운트다운과 함께 같은 레벨 내 병렬 유닛·트레이닝 모드가 항상 열려 있어 막힌 느낌을 주지 않는다.

**첫 방문 (온보딩·배치 테스트)**: 첫 화면에서 분기 — (a) "처음부터": U1 시작, 레이팅 1500/RD 350. (b) **"배치 테스트" (5분)**: 무컴파일 문항(predict/mcq) 12~15개의 난이도 사다리. 결과로 (i) 초기 레이팅을 800~1900 구간에 시드(RD 300 — 콜드 스타트보다 낮춰 빠른 정착), (ii) 점수 구간별로 유닛 선해제(예: 상위 구간 → U1~U7 해제 + 해당 태그 "학습됨" 마킹 → 트레이닝 풀 즉시 사용 가능). ML 계열 경험자가 U1부터 강제되지 않는다. (c) "트레이닝만": 배치 테스트 필수 → 그 결과 태그 풀에서 출제. 유닛 건너뛰기는 확인 프롬프트 후 허용되며, 건너뛴 유닛의 태그는 "잠정 학습됨"으로 풀에 편입된다.

---

## 3. 커리큘럼

### 3.1 레벨/유닛 전체 맵

| 레벨 | 유닛 | 핵심 개념 | 선수 | 레슨 |
|---|---|---|---|---|
| **L1 입문** | U1 값, 불변성, 표현식 | let, shadowing, Int/Float 분리, 표현식 지향 | — | 5 |
| | U2 함수와 파이프 | 함수 정의, `\|>` | U1 | 4 |
| | U3 case와 분기 — 사고 전환 I | case, guard, no early return | U2 | 4 |
| **L2 초급** | U4 커스텀 타입과 레코드 | variants, record update, **exhaustiveness** | U3 | 5 |
| | U5 리스트와 재귀 | `[x, ..rest]`, 종료 조건, no loops | U4 | 5 |
| | U6 꼬리 재귀와 누산기 | TCO, accumulator, 결과 뒤집힘 | U5 | 4 |
| | U7 함수를 값으로 | 익명 함수, 캡처 `f(_, x)`, labelled args | U5 | 4 |
| **L3 중급** | U8 list 모듈 | map/filter/**fold 방향**, 도구 선택 | U6,U7 | 5 |
| | U9 Option과 Result | 커스텀 에러 타입, Option vs Result | U4 | 5 |
| | U10 Result 체이닝과 use | `result.try`, use 디슈가링 | U8,U9 | 4 |
| | U11 제네릭과 타입 설계 | 타입 변수, Dict/Set | U8,U9 | 4 |
| **L4 고급** | U12 Opaque Type과 API 설계 | smart constructor, phantom types | U10,U11 | 4 |
| | U13 의도적 크래시 | todo/panic/let assert/assert | U9 | 3 |
| | U14 Gleam에 없는 것들 — 사고 전환 II | no typeclass/currying/laziness/macros (공식 FAQ) | U10,U11 | 4 |
| | U15 캡스톤 | CSV 파서, 상태 기계, OTP **읽기 전용** | U12~U14 | 4 |

총 62레슨 + 15 유닛 체크포인트. **v1 = L1+L2 (7유닛, 31레슨)** — 마일스톤 배분은 §6에서 재기준선(M1=U1~U3, M2=U4~U7). L3/L4는 M3 이후 순차 릴리스. OTP/actor는 Erlang 타깃 전용이므로 브라우저 실행 불가 — 읽기 전용 + mcq/parsons만.

**잠금 규칙(확정)**: 유닛 내 레슨 순차 해제 / 유닛 간 선수 유닛 완료 시 해제 / **레벨 해제 = 이전 레벨 전 유닛 완료 ∧ 그 레벨 SRS 아이템의 1회차 리뷰(4h~1d) 통과** (게이트 단위는 레벨로 통일; 레슨 단위 리뷰 게이트는 두지 않음). 신규 레슨 하루 5개 캡.

### 3.2 레슨 구조

- 5~10분 = 설명 세그먼트 3~5개(각 ≤90초 분량, 안정적 `segment_id` 보유 — 체크포인트 역링크 대상) × 마이크로 연습 5~10개(타입은 §4.1 통합 레지스트리의 P1~P5) 교차.
- 신규 개념은 레슨당 정확히 1개. 정답 시에도 한 줄 코멘터리, 오답 시 feedback_map의 사전 저작 해설, 2연속 오답 시 near-neighbor 쉬운 변형 삽입(Brilliant). 재시도 무벌점, '정답 보기'만 SRS 인터벌 축소.
- **유닛 체크포인트**: 유닛 태그 혼합 10문항, 8개 이상 통과. 실패 문항은 `unit/lesson#segment_id` 딥링크로 해당 세그먼트 역링크. 체크포인트는 콘텐츠 스키마의 1급 엔티티(§5.4)이고 진행 모델에 `checkpoint_passed` 필드를 가진다.

### 3.3 대표 예시 (CI 골든이 1.17.0에서 재검증·고정하는 후보)

**예시 1 — U1 「Int와 Float는 남남」(P4 fix_error)**: 아래 코드는 컴파일되지 않는다.

```gleam
pub fn add_half(x: Float) -> Float {
  x + 0.5
}
```

컴파일러 출력(요지: `Use +. instead` 힌트 — 정확한 자구는 골든 스냅샷이 1.17.0 기준으로 고정)을 원문 그대로 보여주고, 정답 `x +. 0.5` 제출 시: "Gleam은 암묵적 숫자 변환이 없습니다. Float 연산자는 점이 붙습니다: `+. -. *. /.`" — 태그 `tricky:int-float-operators`.

**예시 2 — U4 「빠짐없이 다루기」(P4 fix_error)**:

```gleam
pub type Shape {
  Circle(radius: Float)
  Rectangle(width: Float, height: Float)
}

pub fn area(shape: Shape) -> Float {
  case shape {
    Circle(radius: r) -> 3.14159 *. r *. r
  }
}
```

`Inexhaustive patterns` 에러(누락 패턴 목록 포함)를 그대로 노출. `_ -> 0.0`으로 때우는 오답에는 feedback_map: "컴파일은 되지만 `_`는 exhaustiveness 검사를 꺼버립니다 — `Triangle`을 추가해도 컴파일러가 침묵합니다." 이 함정이 트레이닝 테마 `tricky:exhaustiveness`의 자동 생성기(variant 1개 삭제) 시드다.

**예시 3 — U8 「fold 방향과 누산기」(P1 predict)**:

```gleam
list.fold([1, 2, 3], [], fn(acc, x) { [x, ..acc] })
```

정답 `[3, 2, 1]` (골든이 실행으로 고정). distractor `[1, 2, 3]`의 코멘트: "fold는 왼쪽부터 — 1이 먼저 acc에 박히고 그 위에 2, 3이 쌓입니다. 순서 보존이 필요하면 `list.fold_right` 또는 fold 후 `list.reverse`." U6의 누산기 뒤집힘이 fold에서 재등장하는 interleaving 설계. 태그 `tricky:fold-arg-order`, `tricky:accumulator-reverse`.

### 3.4 트리키 파트 목록과 트레이닝 연계

트리키 파트 태그는 **단일 레지스트리(§4.1)의 canonical 명칭**으로만 표기한다(구 문서 명칭은 빌드 시 거부).

| 트리키 파트 (canonical 태그) | 전형적 함정 | 노출 시점 | 주 퍼즐 타입 |
|---|---|---|---|
| `int-float-operators` | `+` vs `+.` | U1 | P4 |
| `shadowing` | 캡처된 옛 값 vs 새 바인딩 | U1 | P1 |
| `no-early-return` | 가드절 사고 → case 트리 | U3 | P5 |
| `branch-order` | `_`를 먼저 둠, 죽은 가지 | U3 | P1/P2 |
| `exhaustiveness` | variant 누락, `_` 남용 | U4 (U9 강화) | P4 |
| `record-update-copy` | 원본이 안 바뀜을 잊음 | U4 | P1 |
| `empty-list-base-case` | 빈 리스트 케이스 누락, 같은 인자 재호출 | U5 | P4 |
| `tail-call-accumulator` | `[] -> acc` vs `[] -> 0`, 비-꼬리 변환 | U6 | P5/P7 |
| `accumulator-reverse` | prepend 누산 후 reverse 누락 | U6 (U8 재등장) | P1 |
| `capture-vs-currying` | `f(10)` 부분 적용 착각, `_` 위치 | U7 (U14 재강화) | P4 |
| `fold-arg-order` | `fn(acc, item)` 순서, fold 방향 | U8 | P1/P8 |
| `tool-choice` | map/filter/fold 선택 | U8 | P2 |
| `option-vs-result` | 부재=데이터 vs 실패=이유 | U9 | P2 |
| `string-vs-int-concat` | `<>`에 Int | U9 주변 | P4 |
| `use-desugaring` | 디슈가링 오해, 마지막 `Ok(...)` 누락 | U10 | P5/P2 |
| `crash-vs-result` | 다룰 수 있는 실패에 `let assert` | U13 | P2 |

핵심 4대(`empty-list-base-case`, `tail-call-accumulator`, `fold-arg-order`, `use-desugaring`)는 SRS 기본 등록 + Code Rush 고배점 테마. 레슨에서 틀린 연습은 태그와 함께 실패 로그로 적재 → 개인화 재훈련 큐.

---

## 4. 트레이닝 시스템

### 4.1 통합 퍼즐 타입 레지스트리 (E/T 분류 폐기, 본 표가 유일 기준)

| ID | 타입 | 구 명칭 | 채점(grading) | Rush | Streak | SRS | 모바일 | 1줄 예시 요지 |
|---|---|---|---|---|---|---|---|---|
| P1 | `predict` | E1/T1 | `choice` 또는 `exact_output` | O(선택지형) | O | O | O | `[1,..5] \|> filter(odd) \|> map(sq) \|> fold(0,+)` → 35 |
| P2 | `mcq` | E5·E6/T8 | `choice` | O | O | O | O | "`use x <- result.try(p)`는 무엇의 sugar?" → `result.try(p, fn(x){…})` |
| P3 | `fill_hole` | E2/T3 | `tests` + 입력 가드 | O(한 줄) | O | O | △ | `list.find(numbers, todo)` — todo 경고의 `Hint: fn(Int) -> Bool`이 공짜 힌트 |
| P4 | `fix_error` | E3/T2 | `tests` (starter는 컴파일 실패 필수) | X | O | O | △ | `"count: " <> count` (Int) → `int.to_string` 추가 |
| P5 | `write_fn` | E4/T5 | `tests` (per-test) | X | X | O(재구성형) | X | `keep_oks(List(Result(a,e))) -> List(a)` 구현 |
| P6 | `refactor` | T4 | `tests_lint` (테스트+구조 린트) | X | X | △ | X | `f(g(h(x)))` → `x \|> h \|> g \|> f` (`\|>` ≥3 린트) |
| P7 | `parsons` | T6 | `parsons` (조립→컴파일→테스트) | O(4~6줄) | O | O | O | wrapper+`sum_loop` 7줄 재배열 |
| P8 | `spot_bug` | T7 | `spot_two_stage` (스팬 클릭→수정 테스트) | O(1단계만) | O | O | O(1단계) | `fold(words,"",fn(acc,w){w<>" "<>acc})` — 순서 역전 버그 줄 지목 |

`puzzle.toml`의 `type`은 위 8개 enum, `grading`은 `choice | exact_output | tests | tests_lint | parsons | spot_two_stage` 6개 enum이며 타입별 허용 조합은 위 표가 강제한다(CI 검증). 레슨 마이크로 연습도 동일 레지스트리를 사용한다(레슨은 주로 P1~P5).

**Parsons 인덴테이션(확정)**: 브라우저 WASM API에 포매터는 없다(write_module/compile_package/read_compiled_* 만 존재). 따라서 **저자가 각 줄의 인덴트를 포함해 저작**하고, 셔플된 줄은 자기 인덴트를 유지한 채 제시되며 채점은 순서만 본다(컴파일+테스트 통과하는 임의 순서 인정 — case arm 교환 등 자동 해결). 깊이 기반 재인덴터는 선택적 후속 과제.

### 4.2 레이팅 — Glicko-2 (수치 확정)

모든 **첫 무힌트 시도 = 유저 vs 퍼즐의 rated 대국**(lichess 의미론). 재도전·SRS·Rush·Streak·데일리는 unrated. 힌트 1단계라도 열면 unrated. 다단계(P8)는 전 단계 첫 통과 시 승리. watchdog 초과/RangeError = 오답. 풀이 시간은 기록만(레이팅 비반영).

| 엔티티 | 초기 rating | 초기 RD | σ | RD 하한 |
|---|---|---|---|---|
| 유저 글로벌 | 1500 (배치 테스트 시 800~1900 시드) | 350 (배치 시 300) | 0.06 | 45 |
| 유저 테마 서브 | 글로벌에서 분기 | 250 | 0.06 | 60 |
| 퍼즐 | 티어 1~9 → 800/1000/1200/1400/1600/1800/2000/2300/2600 | **350** | 0.06 | 75 |

- 난이도 5밴드(유저 기준 오프셋): **−400 / −200 / ±150 / +200 / +400~+600**. 기본 "보통".
- 테마 서브 레이팅은 같은 시도를 입력으로 병렬 계산되는 파생값(퍼즐 레이팅에 비반영 — 다중 태그 더블카운팅 방지). 시도 10회 미만 테마는 "측정 중".
- **단계적 배포(확정)**: M1~M2는 백엔드 없음 — 퍼즐 레이팅은 시드 고정, 유저 레이팅만 localStorage에서 클라이언트 Glicko-2로 갱신. **크로스 유저 시도 수집·퍼즐 캘리브레이션·격리(quarantine) 자동화·전 유저 정답률 표시·공개 리더보드는 전부 M3로 이동**(서버 재검증 전 공개 경쟁 금지 — R7). M1~M2의 "문제 모호함 신고"는 사전 채움된 GitHub 이슈 링크로 처리(전송 인프라 불필요).

### 4.3 모드

| 모드 | 규칙 | rated |
|---|---|---|
| 믹스드 퍼즐 | 글로벌 ±밴드, interleaving(같은 주테마 연속 2회·같은 타입 연속 3회 금지), 약점 테마 +30% 가중 | O |
| 테마 드릴 | 테마 서브 레이팅 ±밴드, 레슨 완료 화면·약점 카드에서 진입, 동일 퍼즐 14일 쿨다운 | O |
| **Code Rush** (통합 타임드 모드 — "Storm"/"Code Storm" 명칭 폐기) | 3분/5분/서바이벌(무제한) 3포맷 · **3 strikes 전 포맷 공통** · 콤보 5/12/20/30회에 +3/+5/+7/+10s, 이후 10회마다 +10s · 오답 = 콤보 리셋 −10s −1목숨 · 시작 난이도 max(600, 레이팅−600), 정답마다 +40~60 | X |
| Streak | 시계 없음, 600부터 오름차순(+30~50), 한 번 틀리면 종료, 스킵 1회, 힌트 불가 | X |
| 데일리 퍼즐 | 전 유저 동일 1개/일, 1500~1800 큐레이션. **날짜 키 = Asia/Seoul 자정 기준 결정적 해시**, 해설은 다음 날 00:00 KST 클라이언트 게이팅(번들에 포함 — 클라이언트 신뢰 모델과 동일 수위). 스트릭은 M3 전 단일 기기 한정임을 명시 | X |
| 복습 큐 (SRS) | §4.4 | X |

**타임드 적합성(확정, 모순 해소)**: Rush 출제 풀 = P1(선택지형)/P2/P3(한 줄)/P7(4~6줄)/P8(1단계). Streak = Rush 풀 + P4 + P8(2단계). **P5 write_fn과 P6 refactor는 두 타임드 모드 모두 제외**(rated/SRS 전용). Rush 리더보드는 M3 전까지 개인 최고 기록만.

### 4.4 SRS 복습 큐 (M1부터 최소 스케줄러 탑재)

- **카드 단위 = `family_id`** (테마×타입으로 묶인 퍼즐 패밀리, 변형 3~5개 보유). 아키텍처의 `srs_item` 마이크로 스킬 문자열은 패밀리의 대시보드 그룹핑 라벨로 격하(카드 키 아님).
- 간격: **L1=4h, L2=1d, L3=3d, L4=1w, L5=2w, L6=1mo, L7=3mo, L8=6mo** (Chessable). 성공 +1레벨. 세션 내 재시도 무벌점(EP), 세션 종료 시점 실패 또는 '정답 보기' → L1 리셋.
- **졸업(확정)**: 간격을 둔 연속 성공 4회 → 은퇴(EP식, 약 2개월) + 6개월 후 확인 리뷰 1회. (아키텍처의 "L8 도달 시 은퇴" 폐기 — 1년 이상 끌고 가지 않는다.)
- 리뷰는 동일 퍼즐이 아니라 **패밀리 내 파라미터 변형 회전** 출제(암기 방지). Learn 모드(최초: 정답 제시 후 재구성) / Review 모드(순수 recall) 구분.
- 일일 상한: 신규 10 / 리뷰 50. 예상 부담 ~10분.
- **M1 탑재 범위(게이팅 정합성 확보)**: 간격 테이블 + due 큐 + 레벨 해제 게이트 — 구현은 테이블 1개와 비교 연산이라 자명. 변형 회전·Learn/Review 구분·일일 큐 UI 고도화는 M3. 스케줄러는 `fn(card_history) -> next_due` 인터페이스 뒤에 격리(후일 FSRS 교체 경로).
- **복귀 트리거**: 헤더 due 배지 + 레벨 게이트 카운트다운(M1), PWA 설치 + 로컬 알림 opt-in(M2), 이메일 다이제스트(M3). 4시간 게이트의 UX: "오늘 저녁에 다시 오세요" 명시 + 대기 중 가능한 활동(트레이닝/병렬 유닛) 제시.

### 4.5 힌트/피드백

3단계 힌트: **H1** 개념 환기(주 테마 + 1줄 리마인더 + P3는 todo 경고의 홀 타입 파싱) → **H2** 스팬 지목(에러/버그 줄 하이라이트) → **H3** 정답+해설(SRS L1 리셋 또는 실패 카드 생성). H1부터 unrated.

컴파일 에러 2단 표시: (1) 컴파일러 pretty 출력 원문 보존(에러 독해가 곧 커리큘럼), (2) `error: <제목>` 카테고리 × 퍼즐 테마로 매칭한 한국어 해설 사전. 위치는 `src/\w+\.gleam:L:C` 정규식 추출 → CodeMirror 인라인 마커. **에러 번역 사전과 태그 표시명은 로케일 파일에 포함**(ko 우선, 미번역 시 컴파일러 원문만 표시하는 graceful fallback — i18n 갭 해소).

**무한 재귀 피드백 — 두 실패 형태 모두 매핑(확정)**:

| 실패 형태 | 원인 | 교육 메시지 |
|---|---|---|
| `RangeError: Maximum call stack size exceeded` (즉시) | 비-꼬리 무한 재귀 또는 깊은 비-꼬리 재귀 | "스택 한계 도달 — 재귀 인자가 줄어드는지(종료 조건), 그리고 재귀 호출이 마지막 동작(꼬리 호출)인지 확인하세요" |
| watchdog 타임아웃 (기본 3s) | 꼬리 재귀 무한 루프 | "시간 초과 — 재귀가 끝나지 않습니다. 빈 리스트 케이스 등 종료 조건을 확인하세요" |

U5-③의 심은 버그 `first + total(xs)`는 비-꼬리라 **RangeError 경로**로 떨어진다 — 해당 연습의 피드백은 첫 행 메시지를 사용한다(구 커리큘럼의 "watchdog 메시지" 기술 정정). 테스트 실패 시 하니스가 캡처한 실패 메시지(기대/실제값)를 표시하고, 흔한 오답 패턴별 진단 문장은 feedback_map에서 저작.

---

## 5. 기술 아키텍처

### 5.1 스택 결정

| 영역 | 결정 | 근거 |
|---|---|---|
| 프론트 | **Lustre v5.x SPA**, 정적 호스팅(Cloudflare Pages) | 도그푸딩 = 신뢰 자산, MVU가 가르치는 패러다임과 동일, UI 복잡도 낮음. FFI 접점 3곳(에디터/워커/storage)만 격리 |
| 에디터 | CodeMirror 6 + `@exercism/codemirror-lang-gleam` **포크**(assert/echo 등 추가) | 유일한 Gleam grammar. Monaco grammar 부재, CodeFlask는 hole 위젯·squiggle 불가. 비편집 코드는 tree-sitter-gleam 사전 렌더 |
| 컴파일/실행 | 공식 `gleam-v1.17.0-browser.tar.gz` (1.66MB), 100% 인브라우저 JS 타깃 | tour/playground/LiveCodes로 검증. 실행 서버 0. tarball은 R2에 자체 미러 |
| 백엔드 | M1~M2 없음(localStorage) → M3 Wisp 2.2.2 + Mist 6.0.3 + SQLite(+Litestream) | 호스팅 비용 0, 1인 운영 부담 최소. 이벤트 소싱으로 마이그레이션 기계화 |
| 레이팅/SRS | Glicko-2(순수 함수 ~150줄 Gleam) / 8레벨 간격 테이블 | §4 |

### 5.2 브라우저 내 컴파일/실행 파이프라인 (듀얼 워커 — 확정)

구 트레이닝 설계의 "예열 예비 워커"는 폐기한다. **유저 코드는 컴파일 워커에서 절대 실행되지 않으므로** 비싼 워커가 죽을 일이 없고, 러너 워커 respawn은 수 ms다.

```
Main thread (Lustre SPA)
 └─ compile_service.mjs (FFI 포트, message-passing 인터페이스 고정 — 후일 iframe 격상 대비)
     ├─ compiler.worker.js  ← 장수명. WASM init + stdlib ~50모듈 write_module 1회만 지불
     │    write_module(pid, "solution", 유저코드)
     │    write_module(pid, "runner_test", 히든테스트)   // 채점 시. harness.gleam 자동 주입
     │    compile_package(pid, "javascript")
     │    read_compiled_javascript × [solution, runner_test, harness]
     │    pop_warning 드레인 → {js, warnings} | {error: prettyText}
     │    [안전망 watchdog 30s — 컴파일러 panic 시에만 풀 respawn]
     │
     └─ runner.worker.js    ← 일회용. 실행마다 생성, 종료/타임아웃 시 무조건 terminate
          import 재작성: stdlib → /precompiled/, 모듈 간 → data: URL (leaf-first 토폴로지 순서,
            solution을 먼저 data-URL화 → runner_test의 "./solution.mjs" 참조를 치환)
          console.log 몽키패치 → 출력 캡처
          await import("data:text/javascript;base64," + …) → runner_test의 main()
          [watchdog: puzzle.toml timeout_ms, 기본 3000, write_fn 상한 5000, Rush 고정 3000]
```

- stdlib 2면 제공(tour 패턴): 빌드 시 `.gleam` 소스를 stdlib.js로 임베드(타입체크용 write_module) + 프리컴파일 `.mjs`를 `/precompiled/`에 서빙. 추가 패키지는 LiveCodes vendoring 패턴(이슈 #3245 미해결 대기 안 함).
- 컴파일러는 첫 인터랙티브 연습 진입 시 lazy-load, `?v=` 캐시버스터 + Service Worker 영구 캐시.
- 샌드박싱: same-origin Worker는 응답성 경계(보안 경계 아님). 자기 코드만 실행하므로 수용, CSP `connect-src 'self'`로 fetch 차단. 커뮤니티 퍼즐 도입 시 sandboxed iframe으로 격상.
- 결정성: 퍼즐/테스트에 시간·난수·네트워크 금지(저작 린트).

**채점 하니스(단일화 — 아키텍처 §3.8 방식 채택, 모듈명 `solution`/`runner_test`/`harness` 통일)**: 플랫폼이 `harness.gleam` + `harness_ffi.mjs`(rescue FFI)를 자동 주입하고, 저자의 `runner_test.gleam`이 `harness.suite([harness.test("이름", fn(){ assert … }), …])`를 `main()`에서 호출한다. rescue가 try/catch로 assert 실패를 잡아 `__<런별 난수 토큰>__|pass|이름` / `…|fail|이름|메시지` 프로토콜로 stdout에 기록 → 러너가 파싱해 per-test 결과 생성(난수 토큰이 출력 스푸핑 1차 방어). JS 타깃 assert 실패 객체의 구조화 필드(left/right 값)는 **존재할 경우** rescue가 메시지 보강에 활용하되 계약은 어디까지나 stdout 프로토콜이다(필드 존재 여부는 1.17.0 골든에서 확인 — 구 설계의 "개별 pub fn test_* 직접 호출" 방식 폐기). 내부 결과 스키마는 Exercism results.json v2 호환(M3 서버 러너 추가 대비). 클라이언트 채점은 신뢰 기반 — 로컬 레이팅 한정으로 무해, 공개 경쟁은 서버 재검증 후.

### 5.3 콘텐츠 저작 포맷과 검증 파이프라인

```
content/
├── registry/tags.toml        # 단일 태그 레지스트리 (유일 기준)
│     [concept]  Exercism 36 슬러그 원문 그대로 (basics … use-expressions)
│     [tricky]   §3.4의 16개 canonical 태그
│     [alias]    구 문서 명칭 → canonical 매핑(빌드 시 경고 후 거부)
├── units/<unit>/
│   ├── unit.toml             # id, title, order, concepts, prerequisites
│   ├── checkpoint.toml       # 문항 10개 참조 + pass_threshold=8 + 문항별 backlink(lesson#segment_id)
│   └── lessons/<lesson>/
│       ├── lesson.toml       # 방출 태그, srs_items(핵심 아이템 2~4)
│       ├── prose.ko.md       # 세그먼트별 안정적 anchor id
│       └── steps/<step>/     # step.toml(type=P1..P5) + code + feedback_map
└── puzzles/<family_id>/
    ├── family.toml           # family_id, type, primary_theme, themes, srs_label(라벨),
    │                         # seed_tier(1~9→800..2600/RD350), timeout_ms, srs_eligible,
    │                         # mobile_friendly, compiler_version="1.17.0"
    │                         # (필드명은 content/schema.PuzzleFamily가 유일 기준)
    ├── variants/v1..v5/      # 변형마다: starter.gleam / solution*.gleam(복수 허용) /
    │                         # runner_test.gleam / answer.txt(predict)
    ├── hints.ko.md           # --- 구분 3단계: H1 텍스트 / H2 스팬(JSON) / H3 해설
    ├── feedback.ko.toml      # per-distractor 코멘트, 오답 패턴별 진단 문장
    └── explanation.ko.md     # 복수 모범 답안 비교 포함
```

**CI 골든 검증(모든 PR)**: ① 스키마/태그/선수 그래프 무사이클 검증 — 미등록 태그는 빌드 실패. ② **브라우저와 동일한 1.17.0 WASM 컴파일러를 Node에서 구동해** 전 변형 검증: solution+test 컴파일·전 테스트 pass / fix_error의 starter는 실제 컴파일 실패 + 에러 제목 일치 / predict는 실행 출력을 answer.txt 스냅샷으로 고정 / fill_hole은 todo 상태로 컴파일 통과·테스트 실패 확인 / 인용 에러 텍스트 전부 스냅샷 고정. ③ 단위별 JSON 청크 직렬화(prose 사전 렌더 포함, lazy-load). ④ **컴파일러 업그레이드 절차**: 핀 bump → 전 골든 재실행 → diff 사람 리뷰 → 콘텐츠 수정과 함께 머지. 콘텐츠 번들에 `content_version` + 핀 버전 기록.

**저작 비용 모델과 도구(1인 현실)**: 레슨 ≈ 4h(prose 1h + 연습 6~8개×20분 + feedback_map), 체크포인트 ≈ 2h, 퍼즐 패밀리 ≈ 45분 + 변형당 15분. v1(31레슨+7체크포인트+퍼즐 250패밀리) ≈ **약 330시간** — M1+M2 14주에 콘텐츠 50% 배분으로 수렴. 지원 도구: `scaffold` CLI(레슨·퍼즐 양쪽 템플릿 생성), `content dev` 핫리로드 프리뷰(저작물을 즉시 플레이테스트), 변이 생성기(검증된 코드에 버그 1개 주입/구멍 굴착/줄 셔플 → CI가 "의도된 수정이 유일하게 통과" 확인 → 사람은 선별·티어 부여만), 셀프 플레이테스트 체크리스트가 에디토리얼 QA를 대신한다.

**콘텐츠/ID 라이프사이클**: puzzle/lesson/family ID는 불변·재사용 금지. 퍼즐 은퇴 시 tombstone 항목이 남아 기존 attempts/SRS 카드가 깨지지 않으며, 카드는 family 키이므로 다른 변형으로 계속 서빙된다. 콘텐츠 릴리스마다 마이그레이션 맵(제거/대체 ID)을 번들에 포함, 클라이언트가 profile의 `content_version`과 비교해 적용. 컴파일러 핀 bump는 콘텐츠 릴리스로만 수행.

### 5.4 데이터 모델 (요지)

```gleam
pub type Outcome { Passed  Failed(reason: String)  TimedOut  GaveUp }

pub type Attempt {
  Attempt(id: String /*uuid, 병합 키*/, puzzle_id: String, variant: String,
    at_ms: Int, outcome: Outcome, duration_ms: Int, hints_used: Int,
    rated: Bool, rating_before: Float, rating_after: Float,
    error_category: option.Option(String))
}

pub type SrsCard {
  SrsCard(family_id: String, level: Int /*1..8*/, due_at_ms: Int,
    consecutive_successes: Int /*4면 졸업*/, lapses: Int, last_variant: String)
}

pub type UnitProgress {
  UnitProgress(lessons_done: List(String), checkpoint_passed: Bool)
}
```

localStorage(M1~M2): `fpdojo.v1.profile`(user_id, content_version, ratings{overall **1500/350**, by_theme}, lessons/units 진행, srs, settings) + `fpdojo.v1.attempts`(append-only 로그, 최근 2,000건 유지 후 집계 컴팩션). **JSON 내보내기/가져오기 M1 필수**. M3 마이그레이션: 매직 링크 계정 → attempts uuid union 업로드 → 서버 리플레이로 파생 상태 재계산 → 이후 커서 기반 동기화.

**오프라인/PWA**: Service Worker가 앱 셸 + 컴파일러 + 해제된 유닛의 콘텐츠 청크를 캐시(PWA installable). M3 전에는 모든 상태가 로컬이므로 본질적으로 offline-first — SRS due 계산·시도 기록 모두 무연결 동작. M3 이후 오프라인 시도는 로그 큐잉 후 재접속 시 uuid union 병합.

**모바일/접근성**: 퍼즐 메타 `mobile_friendly` 플래그(P1/P2/P7/P8-1단계 = O) — 모바일 SRS 큐는 비컴파일 타입 위주 구성. 에디터에 특수문자 툴바(`|>` `_` `->` `#(` 등) + autocorrect/자동대문자 off, 반응형 단일 컬럼 레이아웃. 접근성: Parsons는 드래그 외 키보드 대체(선택 + 화살표 이동), 결과 표시는 색상 단독 의존 금지(아이콘+텍스트 병기, 색맹 안전 팔레트), `prefers-reduced-motion` 존중, 타임드 모드는 무제한 서바이벌 포맷 + 1.5× 시간 설정 제공, CodeMirror/진단 출력에 ARIA 라벨.

**라이선스/법무(출시 전 감사 항목)**: Gleam 컴파일러·gleam_stdlib는 Apache-2.0 — WASM tarball 미러링·stdlib 소스/`.mjs` 번들에 LICENSE+NOTICE 동봉. language-tour 워커 코드는 라이선스 원문 확인 후 차용(미확인 시 패턴만 보고 재구현). `@exercism/codemirror-lang-gleam` 포크는 원 라이선스 고지 유지. Exercism 콘텐츠 본문은 라이선스 확인 전 재사용 금지, gleam-test-runner(AGPL-3.0) 코드는 절대 vendoring 금지(스키마만 차용).

**프라이버시/분석**: M1~M2는 개인 데이터 수집 0 — localStorage 사용 고지 페이지 + 쿠키 없는 Plausible(집계 전용)로 활성화·퍼널 측정. 클라이언트 에러/WASM panic은 opt-in 리포트(유저 코드 미포함, GlitchTip 셀프호스트). 성공 지표: 활성화(첫 퍼즐 해결율), D7/D30 리텐션, 레슨 퍼널 이탈, 리뷰 큐 준수율, 유닛별 트래픽(R10의 en 번역 우선순위 근거). M3: 개인정보처리방침, 이메일(매직 링크) 보관 최소화, 데이터 내보내기(기존 JSON export 재사용)·삭제 엔드포인트(GDPR 기본).

---

## 6. MVP 로드맵 (콘텐츠 규모 재기준선)

| 마일스톤 | 기간 | 범위 | 완료 정의(DoD) |
|---|---|---|---|
| **M1 — 파이프라인 + 레슨 엔진 + L1** | 8주 | 듀얼 워커 컴파일/실행/채점 전체(§5.2, 하니스·watchdog·에러 정규식 파싱) · 1주차 중급 Android 실기기 컴파일 지연 스파이크 · Lustre 셸 + CodeMirror 포크 + localStorage + JSON 내보내기 · CI 골든(1.17.0 전수 재검증 포함) · **온보딩+배치 테스트** · **최소 SRS(간격 테이블+due 큐+레벨 게이트)** · 콘텐츠: **U1~U3(13레슨+3체크포인트) + 퍼즐 80패밀리**(P1~P4 중심) · Plausible | 낯선 사용자가 배치 테스트→U1~U3 완주 가능 · 새로고침/오프라인에도 진행 유지 · 무한루프 제출이 3초 내(또는 RangeError 즉시) 진단 메시지로 복구 · CI가 전 콘텐츠 골든 통과 · 모바일 컴파일 p95 측정치 기록 · L1→L2 게이트(첫 리뷰)가 실동작 |
| **M2 — 레이팅 + 전 타입 + 트레이닝 모드 + L2 (= v1)** | 6주 | 클라이언트 Glicko-2 + 밴드 + 믹스드/테마 모드 · 퍼즐 8타입 완성(P5~P8 추가) · Code Rush + Streak + 데일리 · 미니 대시보드(테마 서브 레이팅, 실패 큐) · PWA 알림 opt-in · scaffold CLI/변이 생성기 · 콘텐츠: **U4~U7(18레슨+4체크포인트), 퍼즐 누적 250패밀리(핵심 패밀리 변형 3개+)** | **v1 = L1+L2(7유닛 31레슨) 전체 플레이 가능** · 레이팅 ±밴드 무한 퍼즐 루프 동작 · Rush/Streak 런 완결(기록 저장) · 퍼즐 패밀리 평균 저작 ≤45분 실측 · 모든 트리키 16태그에 퍼즐 ≥8개 |
| **M3 — 서버 + SRS 완성 + L3 착수** | 8주 | Wisp+Mist+SQLite(+Litestream→R2, 주 1회 복원 드릴) · 매직 링크 계정(Postmark/Resend, SPF/DKIM) · attempt 동기화(레이트리밋+페이로드 캡) · **퍼즐 레이팅 nightly 캘리브레이션 + 격리 자동화 + 공개 Rush 리더보드(서버 검증) + 신고 수집 전환** · SRS 완성(변형 회전, Learn/Review, 일일 큐 UI, 이메일 다이제스트) · 업타임 모니터링/알림 · 개인정보처리방침+삭제/내보내기 · 콘텐츠: U8~U10 릴리스 시작 | 두 기기에서 진행·레이팅·SRS 일치 · 퍼즐 레이팅이 시드에서 수렴하는 그래프 확인 · 일일 리뷰 큐 ~10분 분량 생성 · 백업 복원 드릴 1회 성공 |
| 포스트 M3 | — | L3 완결 + L4(U12~U15, OTP read-only 캡스톤) · **수익화**: 무료(L1+데일리+제한 리뷰) / Pro 월 $9~12 가설(EP $39 대비 저가, VPS+이메일 ~$30/mo 비용 envelope 커버) — 결제는 D30 리텐션 증명 후 도입 · FSRS 교체 검토 · compiler-wasm 포크(`read_diagnostics`)는 평문 파싱 골든이 깨질 때만 | — |

**하지 않는 것**: 서버사이드 코드 실행(수요 증명 전), Monaco, 인브라우저 LSP(존재하지 않음), Lustre server components, 실시간 멀티플레이, 타입클래스/커링/매크로 콘텐츠 구현(대신 U14 "왜 없는가" 레슨).

---

## 7. 리스크와 완화

| # | 리스크 | 완화 |
|---|---|---|
| R1 | **콘텐츠 제작 비용(최대 리스크)** — v1만 ~330시간(레슨 4h·체크포인트 2h·퍼즐 45분+변형 15분) | 원자적 퍼즐 포맷(컴파일러 에러가 해설의 절반) · 변이 생성기+CI 기계 검증으로 사람은 선별만 · scaffold/프리뷰 도구 M1~M2 내장 · 시드 레이팅 정밀도에 시간 안 씀(높은 RD 자가 보정) · ko 우선, en은 트래픽 증명 유닛부터 |
| R2 | WASM API 비공식·미문서, npm 없음 | v1.17.0 핀 + tarball 자체 미러 · 접점을 compiler.worker.js 단일 어댑터로 격리 · 업그레이드는 골든 전수 재검증 절차로만 |
| R3 | 에러 평문 파싱 취약 | 대표 에러 코퍼스 골든 테스트로 파서 보호 · 깨지면 그때 compiler-wasm 포크 전환(비용 명시적 인지 후 연기) |
| R4 | 모바일 성능(1.66MB WASM + 미측정 지연) | M1 1주차 실측 · lazy-load + SW 캐시 · 비컴파일 타입(P1/P2/P7/P8-1) 중심 모바일 폴백 + `mobile_friendly` 플래그 |
| R5 | 무한루프/중재귀 행 | 듀얼 워커 + 일회용 러너 + watchdog(§5.2) · RangeError/타임아웃 이원 피드백 매핑(§4.5) |
| R6 | localStorage 유실(M3 전) | JSON 내보내기 M1 필수 · 컴팩션 · M3 동기화가 근본 해결 |
| R7 | 클라이언트 채점 신뢰성 | 로컬 레이팅 한정 무해 · 난수 토큰 스푸핑 방어 · 공개 리더보드는 서버 재검증(M3) 전 금지 |
| R8 | Lustre 메인테이너 1인 | FFI 3접점 포트 격리, 최악 시 view만 이식 |
| R9 | Erlang 타깃 의미론 브라우저 시연 불가 | OTP는 read-only 캡스톤 명시 설계, "타깃별 지원 추적" 자체를 레슨 소재화 |
| R10 | 컴파일러 업그레이드가 기대 에러·출력 파손 | 전 출력 CI 스냅샷 고정 → 업그레이드 diff 전수 가시화 · 콘텐츠 릴리스 단위 bump |
| R11 | 초기 유저 부족으로 퍼즐 레이팅 미수렴 | 시드 티어 + RD 350 + M3 배치 보정 · 배치 테스트로 유저 측 콜드 스타트도 완화 |
| R12 | 라이선스/법무 누락 | §5.4 감사 항목 — Apache-2.0 NOTICE 동봉, AGPL vendoring 금지, 출시 전 체크리스트(§8-⑤) |

---

## 8. 다음 단계 — 이번 주 시작 작업 5개

1. **컴파일 파이프라인 스파이크**: `gleam-v1.17.0-browser.tar.gz` 다운로드 → language-tour의 `compiler.js`/`worker.js` 정독 → 듀얼 워커(컴파일 장수명 + 러너 일회용 + watchdog 3s) 최소 구현으로 "solution+runner_test+harness 3모듈 컴파일 → `__토큰__|pass|…` 프로토콜 파싱"까지 동작 확인. 무한 꼬리 루프와 비-꼬리 RangeError 두 실패 경로 모두 재현·매핑.
2. **골든 재검증 하네스**: Node에서 1.17.0 WASM을 구동하는 CI 스크립트 작성 → 기존 설계의 검증된 스니펫 전부(Inexhaustive, `Use +. instead`, opaque 에러, todo 홀 타입 힌트, predict 정답들)를 1.17.0에서 재실행해 스냅샷 고정. 자구가 달라진 항목 목록화 — 이것이 콘텐츠 repo의 첫 커밋.
3. **태그 레지스트리 + 콘텐츠 스키마 확정 커밋**: `registry/tags.toml`(concept 36 + tricky 16 + alias 매핑), `family.toml`/`step.toml`/`checkpoint.toml` 스키마, 8타입×6채점 매트릭스 검증 룰을 빌드 스크립트(Gleam)로 구현. scaffold CLI 뼈대 포함.
4. **U1 파일럿 저작**: U1 레슨 5개(prose + 연습 + feedback_map) + 퍼즐 10패밀리를 새 스키마로 저작하며 시간을 실측 → 비용 모델(레슨 4h/퍼즐 45분) 보정. `content dev` 프리뷰로 셀프 플레이테스트.
5. **에디터/라이선스 트랙**: `@exercism/codemirror-lang-gleam` 포크 + `assert`/`echo`/label shorthand 하이라이트 패치, 특수문자 모바일 툴바 프로토타입. 병행으로 라이선스 감사(컴파일러/stdlib Apache-2.0 NOTICE, language-tour 라이선스 원문 확인, Exercism 콘텐츠 repo 라이선스 확인) 체크리스트 완료.