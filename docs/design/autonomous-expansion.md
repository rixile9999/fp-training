# 자율 확장 — 에이전트 오케스트레이션 기반 수직·수평 확장 시스템 설계

> 목표: 학습 플랫폼을 에이전트 오케스트레이션으로 **자율적·지속적으로 수직(트랙 내 심화)
> 및 수평(트랙 간 확대)** 확장하는 시스템을 설계한다. 이 문서는 `content-automation.md`
> (SPEC-as-source + 드리프트 CI)를 **플랫폼 규모로 일반화**한 상위 설계다.
>
> 4개 설계 차원(검증 기층 / 프론티어 모델 / 오케스트레이션 토폴로지 / 수평 스케일링·가드레일)을
> 독립 설계 → 적대적 비평 → 단일 통합으로 도출. **현재 계획 단계(보류)** — 선결 Phase 0가
> 끝나기 전에는 어떤 자율 생성도 켜지 않는다(§7).
>
> 관련: `docs/design/content-automation.md`(이 설계가 운영화하는 보류 설계),
> `PLAN.md` §5.3(골든 검증), `docs/design/training-system.md`(퍼즐 타입·캘리브레이션).

---

## 0. 먼저 — 냉정한 현실(검증됨, 2026-06-14)

> **결정적 그라운딩 사실**: 오라클이 검증하는 `content/` 트리는 **유닛 1 / 레슨 1 /
> 퍼즐패밀리 1개의 스켈레톤 샘플**(`content/units/u01-values/...`,
> `content/puzzles/fold-arg-order-predict-01/`)뿐이다. 반면 **실제 배포되는 15유닛 64레슨은
> 전부 `app/src/fpdojo/content/seed.gleam`(5470줄) 안**에 있어 **오라클 밖**이다.
>
> ⇒ 지금의 "오라클 게이트형 자율 확장"은 *1유닛 샘플*에만 적용되는 주장이다. 배포 코퍼스의
> ~98%가 오라클 거버넌스 밖인 상태에서 OCaml/Rust 같은 수평 확장은 환상이다. **Phase 0
> (`seed.gleam → content/` 마이그레이션)이 모든 자율화의 하드 선결조건**이다(§7).

---

## 1. 핵심 명제와 제1원리

**명제.** fpdojo는 후보 콘텐츠를 **대량 제조**할 수는 있어도 **의미를 자율적으로 출시**할 수는
없다. 이 시스템은 "쏘고 잊는 공장"이 아니라 **파운드리(foundry, 주조소)** 다 — 에이전트들이
고처리량 파이프라인을 돌리되, 그 끝은 항상 **결정적 그린 게이트 + 사람(또는 judge-panel
대리)의 의미 게이트**다.

> "자율"의 정의 = 개발자가 아침에 **오라클-그린 + judge 점수 + diff 준비 완료된 PR들이
> 프론티어 가치 순으로 정렬된 큐**를 받는 것. 사이트에 콘텐츠가 라이브로 올라가 있는 게 아니다.

**제1원리 (각각 제약 또는 비평에서 강제됨):**

1. **오라클은 바닥(floor)이지 천장이 아니다.** `tools/golden/verify.mjs`는 정확히
   *"1.17.0에서 컴파일됨 ∧ stdout이 `answer.txt`와 일치 / tests 통과 / `fix_error`가 실제로
   컴파일 실패"* 만 증명한다. 교육성·distractor 타당성·prose 정확성·"레슨당 새 개념 1개"는
   **판정 불가**. **컴파일 그린이 의미를 자동 승인하는 일은 절대 없다** — 타협 불가능한 척추.
   (오라클은 이미 실버그를 잡았다: `harness.test` ↔ gleam 1.17 예약어 `test` 충돌 →
   `harness.check`로 변경.)
2. **Depth-before-breadth는 미학이 아니라 *근거*다(§0).** 배포 Gleam 코퍼스가 오라클 밖인
   동안 수평 확장은 불가. 깊이 우선이 강제된다.
3. **새 트랙은 콘텐츠 작업이 아니라 *오라클 구축 프로젝트*다.** 오라클 없는 트랙엔 생성 없음.
   언어 오라클(핀 컴파일러 + 러너 + 하니스 프로토콜 + 진단 제목 추출)이 수평 확장 비용의 ~80%.
   LLM 콘텐츠는 싼 부분.
4. **자율성은 레인별로 *벌어서* 얻는다(전역 부여 아님).** "기계적 검증 가능 ∧ 핀 산출물에
   스코프됨"일 때만 사람 없이 머지. prose·컴파일러 핀 bump·개념 순서는 *항상* 사람 게이트.
   (`content-automation.md` 결정 테이블을 확장, 절대 완화 안 함.)
5. **비용 규율 = 콘텐츠 주소화 멱등성.** 모든 모델 호출을 그라운딩 입력 해시로 키잉 →
   입력 불변이면 캐시 히트 → 0 지출. 솔로가 상시 운영을 감당하는 유일한 길.

---

## 2. 시스템 아키텍처 — 3개 평면

배포 제품은 **건드리지 않는다**. 여전히 정적 Lustre SPA가 `app/priv/static/content/*.json`을
fetch할 뿐. 제어 평면과 스튜디오는 CI(GitHub Actions)/개발박스에서만 돌고 **제품 안엔 LLM이
없다**. `server/`(Node + `openai` SDK, DashScope/Qwen 프록시, 키 격리)는 **저작용 LLM
전송로**로 재사용될 뿐 제품 의존성이 아니다.

```
┌──────────────────────────────────────────────────────────────────────────┐
│ 제어 평면 (cron + 상태 + 점수; CI/개발박스 — 제품 아님)                       │
│   coverage-manifest.json ◄── content/ + 오라클 결과에서 도출                 │
│        │ (프론티어: 트랙별 깊이%, 폭 갭, SRS 커버리지, 캘리브레이션)           │
│        ▼                                                                    │
│   [프론티어 모델] ──점수화된 갭──► [스케줄러(cron/수동)] ──콘텐츠주소 캐시키──►   │
│        ▲                                                  [히트? → skip]     │
│        └── measure (머지 후 텔레메트리) ◄────────────────────────┐           │
└───────────────────────────────────┼───────────────────────────┼───────────┘
                                     ▼ dispatch                   │
┌──────────────── 에이전트 스튜디오 (워크플로 패턴) ───────────────┼────────────┐
│ [GENERATE]→[GROUND]→[VERIFY]══BARRIER══►[JUDGE]→[HUMAN GATE]══BARRIER══►[INTEGRATE]
│  author    핀 sig를   오라클           judge-panel  PR 리뷰          golden+merge │
│  (Qwen)    UNTRUSTED  (적대 검증)       (humility)   (diff 준비)                 │
│            +allowlist  ▲      │                                                 │
│            정적검사     └─REPAIR─┘ (loop-until-green, 캡)                        │
└───────────────────────────────────┼────────────────────────────────────────┘
                                     ▼ 사람 승인(merge) 시
┌──────────── 오라클 기층 (이미 존재 — tools/) ─────────────────────────────────┐
│  build-content.mjs : 스키마+태그+선수DAG+(타입×채점)매트릭스 + answer-index      │
│                      (실행 stdout↔choices 유일매칭으로 *도출*, 정답키 불신)       │
│  golden/verify.mjs : 핀 gleam 1.17.0 구동 (predict→answer.txt | tests |        │
│                      fix_error 반드시 실패 | fill_hole)                          │
│  golden/gleam-runner.mjs : compile/run + freshToken 프로토콜                    │
│  golden/bin/gleam-1.17.0 + compiler/*.tar.gz (LICENCE/NOTICE 동봉)             │
│  ★ 트랙별: 새 언어는 tools/golden-<lang>/ 추가 (자체 핀 바이너리/러너/하니스).     │
│            build-content은 언어-불가지론 유지.                                  │
└────────────────────────────────────────────────────────────────────────────┘
        │ npm run golden (build→verify) → app/priv/static/content/*.json → 정적 SPA
```

**어디서 도느냐.** 제어 평면 + 스튜디오는 CI/개발박스 전용, *절대 제품 안이 아님*. `server/`는
저작 LLM 전송로로 재사용(제품 의존성 아님). 배포 SPA는 LLM을 호출하지 않는다.

---

## 3. 능력/프론티어 모델 — "수직 vs 수평"을 *계산*한다

단일 커밋 산출물 **`content/coverage-manifest.json`** 이 시스템의 자기 지도다. 손으로 유지하지
않고 확장된 `build-content.mjs` 패스가 `content/` + 최신 오라클 결과에서 *도출*한다.

| 축 | 차원 | 신호 | 프론티어 메트릭 |
|---|---|---|---|
| **수직** | 유닛별 레슨 깊이 | `lesson.toml` 수 vs 커리큘럼 목표 | `present/planned` |
| 수직 | 개념 태그별 퍼즐패밀리 | 각 `concept:`/`tricky:` 방출 패밀리 | `< N` 패밀리 태그 |
| 수직 | 변형 밀도 | 패밀리당 `variants/` 수 | `< K` 변형 패밀리 |
| 수직 | 퍼즐 *타입* 커버리지 | 개념별 존재하는 8타입 | 고가치 타입 누락 개념 |
| 수직 | SRS / 레이팅 캘리브레이션 | `srs_items`, pass-rate vs Glicko 밴드 | 미커버 태그 / 밴드 이탈 변형 |
| **수평** | 트랙(언어) 존재 | `tools/golden-<lang>/` + 그린 콘텐츠 | 오라클 없는 트랙 |
| 수평 | 로케일 / 타입·모드 가용성 | `prose.<locale>.md`, 빌드·UI 배선 | 로케일/타입/모드 부재 |

**프론티어 점수 함수:**

```
value(gap) = W_strat · 전략가중(축)              // depth-before-breadth 편향
           · 교육레버리지(gap)                    // 선수 체인을 여는가?
           · 학습자수요(gap)                       // 텔레메트리: 유저가 막히는 곳 (Plausible 집계 + opt-in)
           / 비용(gap)                            // 토큰 + 오라클분 + 사람리뷰분
           · feasibility(gap)                     // 트랙에 오라클 없으면 → 하드 0
```

`feasibility = 0`이 **"오라클 없으면 생성 없음"을 기계적으로 강제**한다. `W_strat`은 *현재
트랙이 깊이 임계(예: Gleam 계획 레슨 ≥90%가 오라클 하 + 배포 개념마다 ≥2 패밀리)를 넘기
전까지 모든 수직 갭이 최고 수평 갭을 앞서도록* 설정 — depth-before-breadth를 산수로 구현.

> **비평으로 폐기된 것:** "프론티어 모델이 가르칠 새 개념을 *발견*" 안. 개념 택소노미는
> 교육적으로 의미 있어 사람 소유 커리큘럼 + `registry/tags.toml`에 둔다. 프론티어는 *소유 스펙
> 대비 갭*만 찾지, 커리큘럼을 발명하지 않는다.

---

## 4. 오케스트레이션 루프 — 단 2개의 하드 배리어

```
SENSE→PRIORITIZE→GENERATE→GROUND→VERIFY══BARRIER══►JUDGE→HUMAN GATE══BARRIER══►INTEGRATE→MEASURE
(cron) (프론티어)  (Qwen)  (주입)  (오라클)           (패널) (PR리뷰)            (golden+머지) (텔레메트리)
                  └── pipeline: 후보 N개 병렬 ──┘  └ REPAIR 루프(green까지/캡) ┘
```

| 단계 | 하는 일 | 파이프라인/배리어 |
|---|---|---|
| 1 Sense | manifest 재계산 + drift-watch(컴파일러 태그/exercism/stdlib sig) | async cron |
| 2 Prioritize | 프론티어가 갭 점수화, 예산 내 top-K 선택 | 배리어 (1 랭킹 배치) |
| 3 Generate | author(Qwen via `server/`)가 소유 스펙 슬라이스로 초안 | **pipeline** (N병렬) |
| 4 Ground | 핀 stdlib sig를 **UNTRUSTED-DATA**로 주입 + **allow-list 식별자 정적검사**(비싼 컴파일 *전*) | pipeline |
| 5 Verify | `npm run golden` 후보 슬라이스에 | **하드 배리어** — 비-그린은 전진 불가 |
| 6 Repair | red면 정확한 진단 제목 + 실패 테스트 피드백 재시도, 캡(예 N=3) 후 사람 트리아지 | pipeline, bounded |
| 7 Judge | LLM **judge-panel**이 교육성/distractor/prose/"개념 1개"/"answer.txt가 옳은 예측대상인가"를 *humility + 에스컬레이션 플래그*와 점수화 | pipeline |
| 8 Human gate | 유닛별 batch된 **diff-준비 PR** 리뷰 (judge 점수 + 오라클 리포트 첨부) | **모든 의미에 하드 배리어** |
| 9 Integrate | 승인 시 머지 → 전 코퍼스 `npm run golden` 재실행 → JSON 재빌드 | 배리어 (전수 재검증) |
| 10 Measure | 배포 → pass-rate/stall 텔레메트리 → 프론티어 `학습자수요` + 캘리브레이션 피드백 | async |

**왜 배리어가 딱 둘인가:** (a) red 오라클 후보가 judge 호출이나 사람 주의를 *절대* 소비하면
안 됨 → **Verify는 하드 배리어**; (b) 의미는 기계 검증 불가 → **Human gate는 하드 배리어**.
judge-panel은 *사람 리뷰를 빠르게 만드는 자문 트리아지*일 뿐 자동 승인자가 아니다.

**answer-index 무결성 (실제 코드 근거).** `verify.mjs`는 정답 인덱스를 **실행 stdout↔choices
유일매칭**으로 도출(0개 또는 ≥2개 매칭이면 실패), `build-content.mjs`도 독립적으로 재도출.
**author는 정답키 방출이 금지** — `starter.gleam` + `choices`만 쓰고 인덱스는 오라클이
*계산*한다. ⇒ 환각된 "정답"은 구조적으로 출시 불가(distractor가 실제 출력과 충돌하면 오라클이
후보를 떨군다).

---

## 5. 수평 트랙 구축 레시피 (오라클-우선)

새 언어는 **사이에 배리어를 둔 2단계**로 출시. Phase A가 손저작 시드에서 그린 되기 전엔
콘텐츠 0 생성.

**Phase A — 오라클 세우기 (진짜 비용, 대부분 언어별·1회·수동):**

| 단계 | 언어 간 재사용? | 비고 |
|---|---|---|
| 컴파일러 바이너리/WASM 핀 + LICENCE/NOTICE | 언어별 | 기존 `tools/golden/compiler/` 패턴 미러 |
| `golden-<lang>/runner` (`compile`/`run`/`errorTitle`/`freshToken` 프로토콜) | **인터페이스 재사용**, 구현 언어별 | stdout-토큰 하니스는 재사용, 코드젠/진단 파싱은 언어별 |
| stdout-토큰 하니스 (`__token__\|name\|pass\|detail`) | 언어별 (작음) | `harness.check` 미러 |
| `fix_error` 진단 제목 추출 | 언어별 | 각 컴파일러 에러 포맷 상이 |
| `build-content.mjs` 스키마/태그/DAG/매트릭스/청크 | **완전 재사용** | 언어-불가지론 설계, `TYPE_GRADING`만 확장 가능 |
| 타입별 **시드 5~10개 손저작** + `golden-<lang>` 그린 증명 | 언어별·수동 | 신뢰 앵커 — Gleam 부트스트랩과 동일 |

**배리어:** Phase A 그린 ⇒ 프론티어 모델에서 `feasibility`가 0→양수. 이제야 트랙 자격 부여.

**Phase B — 자율 채움:** §4 루프를 새 트랙에 그대로. 재사용: 프론티어/스케줄러/author
스캐폴딩/ground/judge/PR 배선 전부(언어-불가지론). 언어별 델타: 핀 툴체인, 주입 stdlib sig,
idiom 규칙, 커리큘럼 스펙 슬라이스뿐.

> **비용 직관:** 새 트랙의 ~70~80%가 Phase A(수동·1회). Phase B는 싸고 스튜디오 전부 재사용.
> **함의: 여러 언어로 폭을 넓히기보다 *하나의* 둘째 언어를 끝까지(per-language seam 증명) 먼저.**

---

## 6. 가드레일 · 신뢰-티어 자동머지 테이블 · "절대 자율 금지" 경계

**자동머지 규칙 = "기계적 검증 가능 ∧ 핀 산출물에 스코프됨"일 때만**
(`content-automation.md` 결정 테이블 확장):

| 변경 클래스 | 기계검증? | 핀 스코프? | 처분 |
|---|---|---|---|
| 기존 그린 변형의 새 `answer.txt` 스냅샷 | O | O | **자동머지** |
| 기존 패밀리의 새 **파라미터 변형** (prose 동일, 새 입력) | O | O | **judge ≥ 임계 ∧ 에스컬레이션無면 자동머지** |
| Exercism 슬러그 개명 → `tags.toml` 미러 | O | O | **자동머지** (provenance 기록) |
| stdlib 시그니처 갱신(주입 UNTRUSTED-DATA 셋) | O | O | **자동머지** |
| 새 **레슨** (새 prose/개념 프레이밍) | X | X | **사람 게이트** |
| 새 **퍼즐 패밀리** (새 prompt + distractor + 해설) | 부분(코드 그린, distractor 미검증) | X | **사람 게이트** |
| **컴파일러 핀 bump** (1.17.0 → 차기) | X | X | **항상 사람** |
| 모든 **prose/힌트/한국어 해설** | X | X | **항상 사람** |
| 새 **트랙 자격**(Phase A 시드) | X | X | **항상 사람** |

**기계적 가드레일 (CI 강제):**
- **컴파일 전 allow-list 식별자 정적검사** — 환각 API를 비싼 오라클 분(分) 소비 전에 조기 차단.
- **라이선스 안전:** 사실/시그니처/슬러그만 프롬프트 유입; 생성 prose vs fetch 소스 **n-gram
  중첩 스크린**; **AGPL 코드 절대 벤더링 금지**(results 스키마만 차용, 코드 금지). 항목별 provenance.
- **프롬프트 인젝션 방어:** 모든 fetch/업스트림 입력을 **UNTRUSTED-DATA 라벨**로 주입;
  author는 최소권한(레포 쓰기 無, 프록시 외 네트워크 無).
- **멱등성:** `(스펙 슬라이스 + 그라운딩 sig + 프롬프트 버전 + 컴파일러 핀)` 콘텐츠주소 캐시키.
  불변이면 호출 skip.
- **repair 캡 → 사람 트리아지:** 무한 루프 금지, 캡 후 에스컬레이션.

**"절대 자율 금지" 경계 (하드):**
1. 컴파일러 핀 bump. 2. 학습자에 닿는 모든 prose/힌트/해설. 3. 개념 *순서* 및 선수 DAG 편집.
4. 커리큘럼/택소노미 *정의*. 5. 새 트랙 자격(시드 사인오프). 6. 오라클이 기계 재검증 못 하는
모든 변경. 7. 난이도/Glicko 목표밴드 *정책*(캘리브레이션 *데이터*는 자동, *정책*은 아님).
8. 라이브 콘텐츠 롤백/언퍼블리시.

> **비평으로 폐기된 것:** "judge-panel ≥ 임계면 *새 패밀리*도 자동출시" 안. distractor 타당성과
> prose 정확성은 오라클의 명시적 맹점 — 패널은 트리아지, 사람이 출시. 자동머지는 *이미 사람
> 승인된 패밀리의 새 변형*만(교육성은 이미 검증됐고 기계검증 입력만 바뀜).

---

## 7. 솔로 개발자용 단계별 로드맵

현 상태 그라운딩: 오라클은 **1유닛/1레슨/1패밀리 샘플**에서만 작동; 배포 코퍼스는
**`seed.gleam`의 15유닛/64레슨**으로 *오라클 밖*; `server/` Qwen 프록시 존재;
`content-automation.md` 설계는 존재하나 보류.

| Phase | 빌드 | 왜 먼저 / 왜 대기 | 수동 잔존 |
|---|---|---|---|
| **0 — 신뢰 갭 닫기 (타협 불가 선결)** | `seed.gleam` 15유닛/64레슨을 `content/` TOML 트리로 마이그레이션 → 오라클이 *배포* 콘텐츠를 지배. `build-content.mjs`에 `coverage-manifest.json` 도출 추가 | 배포 콘텐츠가 오라클 밖인 한 "자율 오라클 게이트 확장" 전체가 공허. 현재 98% 미완 — 단일 최고 레버리지 | 전부(수동/스크립트) |
| **1 — 프론티어+스케줄러 (읽기전용)** | manifest에서 갭 계산·랭킹 → *리포트만*, 생성 0 | 싸고 무위험, 깊이가 얇은 곳을 즉시 알려줌 | 리포트에 따른 행동 |
| **2 — 단일레인 수직 자율: 변형만** | GENERATE→GROUND→VERIFY→REPAIR를 **기존 패밀리의 파라미터 변형**(유일 자동머지 코드 클래스)에 배선 + 콘텐츠주소 캐시 | 폭발 반경 최소, answer-index가 오라클 도출이라 환각 출시 불가, 파이프라인 E2E 증명 | 새 패밀리/레슨/prose |
| **3 — judge-panel + PR 배선** | 자문 judge-panel + 유닛별 diff-준비 PR(새 패밀리/레슨, 사람 게이트) | 이제 개발자가 저작 대신 *점수화된 배치를 빠르게 리뷰* | 최종 승인/머지 |
| **4 — drift-watch CI** | 보류 문서대로 `sources.toml`+`sources.lock.json`+`drift/check.mjs`+`drift-watch.yml`, 기계검증 티어만 자동머지 | 핀 세계를 저비용으로 정직하게 유지 | 컴파일러 핀 bump |
| **5 — 둘째 트랙 (수평, Phase A 먼저)** | 언어 *하나* → `tools/golden-<lang>/` + 손저작 시드 그린 → *그 다음* 스튜디오가 채움 | per-language seam을 폭 넓히기 전 정확히 한 번 증명 | Phase A 시드 사인오프 |
| **6 — 텔레메트리→캘리브레이션→피드백** | pass-rate/stall 텔레메트리 수집 → `학습자수요`+Glicko *데이터* 프론티어 환류 | measure 루프 닫기 (실유저 선행) | 캘리브레이션 *정책* |

**가장 오래 수동으로 남는 것:** prose 정확성, 개념 순서, 컴파일러 핀 bump, 새 트랙 시드
사인오프, 난이도 정책 — 설계상 오라클의 영구 맹점.

---

## 8. 위험 순위 + 결정적 완화책

| # | 위험 | 결정적 완화 |
|---|---|---|
| 1 | **배포 코퍼스가 오라클 밖** — `seed.gleam` 64레슨이 `content/`를 우회, "오라클 게이트"는 1항목 샘플 주장 | **Phase 0가 하드 선결**: 마이그레이션 전 *어떤* 자율도 없음. 예외 없음 |
| 2 | judge-panel 스코프 크립이 나쁜 의미 자동출시(그럴듯하지만 틀린 distractor, 미묘하게 틀린 prose) | **사람 게이트는 모든 의미에 하드 배리어**; judge는 자문 트리아지만; 자동머지는 *기검증 패밀리의 새 변형*만 |
| 3 | 수직 깊이 전 수평 난립(Gleam 얕은데 OCaml/Rust 추격) | **`feasibility=0` 하드제로 + `W_strat` 깊이 편향**이 임계 전까지 수직>수평 강제 |
| 4 | 상시 생성/judge 비용 폭주 | **콘텐츠주소 캐시키**(스펙+sig+프롬프트+핀) 불변 호출 skip + 컴파일/judge *전* allow-list 정적검사 |
| 5 | 컴파일러 핀 bump가 신뢰 기반을 조용히 무효화(코드젠/진단 이동, `fix_error` 제목 드리프트) | **bump 절대 비자율** + 전수 `npm run golden` 재실행 게이트 + 옛 `answer.txt` 스냅샷이 회귀망 |
| 6 | 새 업스트림 소스의 라이선스/IP 오염(verbatim prose) | **사실/sig/슬러그만 유입 + n-gram 스크린 + AGPL 코드 금지**(이미 스키마만 차용) |
| 7 | fetch한 stdlib/택소노미 데이터 통한 프롬프트 인젝션 | **UNTRUSTED-DATA 라벨 주입 + 최소권한 author** |
| 8 | repair 루프 스래싱/비종료 | **bounded 재시도 → 사람 트리아지 큐**; 안 풀리면 그건 목표가 아니라 신호 |
| 9 | (수평 시) WASM-in-Node 패리티 — 브라우저와 미세 발산하는 false-pass | 동일 버전 네이티브로 진단·코드젠 일치 게이트(현행) + 트랙별 행위 골든 fixture |
| 10 | 스케줄 워크플로 60일 비활성 자동중단 / `GITHUB_TOKEN` 함정(기본 토큰 PR은 골든 미트리거) | keepalive + **GitHub App 토큰**(PR 생성 워크플로) |

---

## 9. 참조 파일 (모두 절대경로 기준은 repo 루트)

- `tools/build-content.mjs` — 검증 + 청크 도출 + answer-index 유일매칭 (여기에
  `coverage-manifest.json` 도출 확장)
- `tools/golden/verify.mjs` — 결정적 게이트(predict/fix_error/tests/fill_hole)
- `tools/golden/gleam-runner.mjs` — `compile`/`run`/`errorTitle`/`freshToken` 프로토콜
  (트랙별 러너의 재사용 템플릿)
- `tools/golden/bin/gleam-1.17.0` + `tools/golden/compiler/` — 트랙별로 미러할 핀 툴체인 패턴
- `content/` — TOML 진실원천 (현재 1유닛/1레슨/1패밀리 — Phase 0 갭)
- `app/src/fpdojo/content/seed.gleam` — 오라클 하로 옮겨야 할 배포 15유닛/64레슨 코퍼스
- `docs/design/content-automation.md` — 이 설계가 운영화하는 보류 SPEC-as-source + 신뢰-티어
  + 드리프트 설계
- `server/` — 저작 전송로로 재사용되는 Qwen 프록시 (제품 의존성 아님)
