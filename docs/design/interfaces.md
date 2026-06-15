# 모듈 인터페이스 맵 (stub 단계 기준 문서)

> 이 문서가 **공개 인터페이스의 유일 기준**이다. stub 작성자는 여기 정의된
> pub 타입·시그니처를 자구 그대로 구현하고(본문은 `todo as "..."`),
> private 헬퍼·doc comment는 자유. 시그니처를 바꿔야 한다면 바꾸지 말고
> 파일 끝에 `// INTERFACE-ISSUE: ...` 주석으로 제안만 남길 것.
>
> 공유 어휘는 `fpdojo/core/types`(작성 완료)에 있다: `Tag`, `PuzzleType`,
> `Grading`, `Outcome`, `Attempt`, `HintLevel`, `Span`, `Submission`.
> 시간은 어디서나 `now_ms: Int` 인자로 주입한다(core는 순수하게 유지).

## 의존 그래프 (위 → 아래로만 import)

```
core/types
  ├─ core/rating          ├─ content/schema ── content/registry
  ├─ core/srs             │       └─ content/loader (rsvp)
  ├─ core/progress ───────┤
  ├─ core/profile (rating, srs, progress 사용)
  ├─ engine/compiler ── engine/runner ── engine/grading (schema 사용)
  │       └─ engine/error_explain
  ├─ session/{lesson,checkpoint,placement,training,review} (core/*, content/schema, engine/* 사용)
  ├─ storage/local (core/profile 직렬화)
  └─ ui/* (전부 사용; Lustre)
```

> **공유 어휘 변경(리뷰 반영):** `types.Outcome`에 `Crashed(message: String)` 추가 —
> 인프라 크래시(컴파일러 워커 panic·watchdog 30s)는 비채점·재시도 경로로,
> Win/Loss 어디에도 매핑하지 않으며 record_rated 호출 금지. PLAN §5.2.

---

## core/rating — Glicko-2 (PLAN §4.2)

```gleam
pub type Rating { Rating(value: Float, deviation: Float, volatility: Float) }
pub type GameResult { Win Loss }

pub fn new_user() -> Rating                       // 1500 / 350 / 0.06
pub fn placement_seed(score_band: Int) -> Rating  // 배치 테스트: 800~1900, RD 300
pub fn new_puzzle(tier: Int) -> Rating            // 티어 1~9 → 800..2600, RD 350
pub fn new_theme(global: Rating) -> Rating        // 글로벌에서 분기, RD 250

/// 1대국 즉시 갱신(lichess식). rd_floor: 유저 45 / 테마 60 / 퍼즐 75.
pub fn update(player: Rating, opponent: Rating, result: GameResult, rd_floor: Float) -> Rating
/// rated 대국 1회: 유저·퍼즐 동시 갱신. 테마 서브는 파생값 — 퍼즐 쪽에 비반영.
pub fn rate_attempt(user: Rating, puzzle: Rating, result: GameResult) -> #(Rating, Rating)
/// 난이도 밴드 오프셋: -400 / -200 / ±150 / +200 / +400~600 (PLAN §4.2)
pub type Band { MuchEasier Easier Normal Harder MuchHarder }
pub fn band_range(user: Rating, band: Band) -> #(Float, Float)
```

## core/srs — 8레벨 간격 반복 (PLAN §4.4)

```gleam
pub type SrsCard {
  SrsCard(family_id: String, level: Int, due_at_ms: Int,
    consecutive_successes: Int, lapses: Int, last_variant: String)
}
pub type ReviewOutcome { ReviewPassed ReviewFailed AnswerRevealed }

pub fn new_card(family_id: String, now_ms: Int) -> SrsCard   // L1, due = now + 4h
pub fn interval_ms(level: Int) -> Int   // 4h 1d 3d 1w 2w 1mo 3mo 6mo (1..8 클램프)
pub fn apply_review(card: SrsCard, outcome: ReviewOutcome, now_ms: Int) -> SrsCard
  // Passed: +1레벨·연속+1 / Failed·Revealed: L1 리셋·lapses+1·연속 0
pub fn is_due(card: SrsCard, now_ms: Int) -> Bool
pub fn is_retired(card: SrsCard) -> Bool   // 간격을 둔 연속 성공 4회 → 졸업
```

## core/progress — 잠금 규칙 (PLAN §3.1)

```gleam
pub type UnitProgress { UnitProgress(lessons_done: List(String), checkpoint_passed: Bool) }
pub type Gate {
  Open
  /// SRS 1회차 리뷰 대기 — UI는 카운트다운 표시
  OpenAt(ms: Int)
  RequiresUnits(unit_ids: List(String))
  RequiresReview(family_ids: List(String))
}

pub fn unit_gate(unit_id: String, prerequisites: List(String),
  units: dict.Dict(String, UnitProgress)) -> Gate
/// 레벨 해제 = 이전 레벨 전 유닛 완료 ∧ 그 레벨 SRS 1회차 리뷰 통과.
/// 레벨→유닛/패밀리 매핑은 콘텐츠 소관이라 호출자가 도출해 내려준다.
pub fn level_gate(prev_level_unit_ids: List(String), level_family_ids: List(String),
  units: dict.Dict(String, UnitProgress),
  srs: dict.Dict(String, srs.SrsCard), now_ms: Int) -> Gate
pub fn new_lessons_today(attempt_log_dates: List(Int), now_ms: Int) -> Int  // 캡 5 검사용
pub const daily_new_lesson_cap = 5
/// 선해제(잠정 완료) 유닛 — 배치 선해제·유닛 건너뛰기용 (checkpoint_passed:True, lessons_done:[])
pub fn seed_unit() -> UnitProgress
```

## core/profile — 유저 상태의 단일 루트 (PLAN §5.4)

```gleam
pub type Settings { Settings(locale: String, reduced_motion: Bool, timed_multiplier: Float) }
pub type Profile {
  Profile(user_id: String, content_version: String,
    overall: rating.Rating,
    by_theme: dict.Dict(String, rating.Rating),   // 키 = types.tag_key
    units: dict.Dict(String, progress.UnitProgress),
    /// 레슨이 연 태그 (학습됨/잠정 학습됨) — 트레이닝 풀 필터
    learned_tags: dict.Dict(String, Bool),         // True=학습됨, False=잠정
    srs: dict.Dict(String, srs.SrsCard),           // 키 = family_id
    settings: Settings)
}
pub fn new(user_id: String) -> Profile
/// rated 시도 1건 반영: overall+테마 서브 갱신, attempt는 호출자가 별도 append
pub fn record_rated(profile: Profile, attempt: types.Attempt,
  puzzle_rating: rating.Rating, themes: List(types.Tag)) -> Profile
```

---

## content/schema — 콘텐츠 도메인 + JSON 디코더 (PLAN §5.3)

콘텐츠는 TOML로 저작 → `tools/build-content.mjs`가 단위별 JSON 청크로 빌드 →
앱은 JSON만 디코드한다(`gleam/dynamic/decode`).

```gleam
pub type Manifest { Manifest(content_version: String, compiler_version: String,
  units: List(UnitMeta), tags: registry.TagRegistry) }
pub type UnitMeta { UnitMeta(id: String, title: String, order: Int, level: Int,
  concepts: List(types.Tag), prerequisites: List(String), lesson_ids: List(String)) }

pub type Unit { Unit(meta: UnitMeta, lessons: List(Lesson), checkpoint: Checkpoint) }
pub type Lesson { Lesson(id: String, unit_id: String, title: String,
  emits_tags: List(types.Tag), srs_items: List(String),  // family_id 2~4개
  blocks: List(LessonBlock)) }
pub type LessonBlock {
  Prose(segment_id: String, markdown: String)     // 체크포인트 역링크 anchor
  Exercise(step: Step)
}
/// 레슨 마이크로 연습 — 패밀리보다 단순(변형·레이팅 없음). 타입은 P1~P5만.
pub type Step { Step(id: String, puzzle_type: types.PuzzleType, grading: types.Grading,
  prompt_md: String, starter: String, choices: List(String),
  answer: option.Option(String),   // Tests 계열(P3~P5)은 None
  test_code: option.Option(String), feedback: FeedbackMap, tags: List(types.Tag)) }
/// Step→Variant 어댑터 — engine/grading 진입점 단일화용
pub fn step_to_variant(step: Step) -> Variant

pub type Checkpoint { Checkpoint(unit_id: String, items: List(CheckpointItem),
  pass_threshold: Int) }
pub type CheckpointItem { CheckpointItem(step: Step, backlink: String) } // "lesson#segment"

pub type PuzzleFamily { PuzzleFamily(id: String, puzzle_type: types.PuzzleType,
  grading: types.Grading, primary_theme: types.Tag, themes: List(types.Tag),
  srs_label: String, seed_tier: Int, timeout_ms: Int, srs_eligible: Bool,
  rush_eligible: Bool, streak_eligible: Bool, mobile_friendly: Bool,
  compiler_version: String, variants: List(Variant), hints: HintSet,
  explanation_md: String) }
pub type Variant { Variant(id: String, prompt_md: String, starter: String,
  solutions: List(String), runner_test: option.Option(String),
  choices: List(String), answer: option.Option(String),  // predict/mcq용
  parsons_lines: List(String), bug_span: option.Option(types.Span),
  feedback: FeedbackMap) }
pub type HintSet { HintSet(recall_md: String, span: option.Option(types.Span),
  reveal_md: String) }
/// 오답 패턴 키 → 저작된 진단 문장 (distractor 인덱스는 "choice:0" 형식 키)
pub type FeedbackMap { FeedbackMap(entries: dict.Dict(String, String)) }

pub fn manifest_decoder() -> decode.Decoder(Manifest)
pub fn unit_decoder() -> decode.Decoder(Unit)
pub fn family_decoder() -> decode.Decoder(PuzzleFamily)
```

## content/registry — 태그 레지스트리

```gleam
pub type TagRegistry { TagRegistry(concepts: List(String), tricky: List(String),
  aliases: dict.Dict(String, String)) }
pub fn registry_decoder() -> decode.Decoder(TagRegistry)
pub fn validate(registry: TagRegistry, tag: types.Tag) -> Result(types.Tag, String)
pub fn display_name(registry: TagRegistry, tag: types.Tag, locale: String) -> String
```

## content/loader — JSON 청크 fetch (rsvp → lustre Effect)

```gleam
pub type LoadError { NetworkError(String) DecodeError(String) NotFound(String) }
pub fn load_manifest(on: fn(Result(schema.Manifest, LoadError)) -> msg) -> effect.Effect(msg)
pub fn load_unit(id: String, on: fn(Result(schema.Unit, LoadError)) -> msg) -> effect.Effect(msg)
pub fn load_family(id: String, on: fn(Result(schema.PuzzleFamily, LoadError)) -> msg) -> effect.Effect(msg)
```

---

## engine/compiler — 컴파일 워커 포트 (PLAN §5.2, 장수명 워커)

Promise 기반(gleam_javascript). FFI는 `compiler_ffi.mjs`(콜로케이션) →
`priv/static/workers/compiler.worker.js`와 message-passing.

```gleam
pub type SourceModule { SourceModule(name: String, code: String) }
pub type CompiledModule { CompiledModule(name: String, js: String) }
pub type CompileFailure { CompileFailure(pretty: String, spans: List(types.Span),
  category: option.Option(String)) }  // category = "error: <제목>" 추출
pub type CompileOutcome { CompileOk(modules: List(CompiledModule), warnings: List(String))
  CompileFailed(failure: CompileFailure)
  CompileCrashed(message: String) }  // 워커 panic·watchdog 30s — 유저 코드 문제 아님

pub fn init() -> promise.Promise(Result(Nil, String))   // WASM lazy-load
/// solution(+runner_test, harness 자동 주입)을 JS로 컴파일
pub fn compile(modules: List(SourceModule)) -> promise.Promise(CompileOutcome)
```

## engine/runner — 일회용 러너 워커 (PLAN §5.2)

```gleam
pub type CrashKind { StackOverflow OtherCrash }   // RangeError → StackOverflow
pub type TestReport { TestReport(name: String, passed: Bool, detail: option.Option(String)) }
pub type RunOutcome {
  RunCompleted(stdout: List(String), tests: List(TestReport))  // 하니스 프로토콜 파싱 결과
  RunTimedOut(after_ms: Int)
  RunCrashed(kind: CrashKind, message: String) }

/// 워커 생성→실행→무조건 terminate. 하니스 토큰은 런별 난수 생성(FFI).
pub fn run(modules: List(compiler.CompiledModule), entry_module: String,
  timeout_ms: Int) -> promise.Promise(RunOutcome)
```

## engine/grading — 채점 디스패치 (PLAN §4.1 grading 6종)

```gleam
pub type GradeDetail {
  ChoiceDetail(correct_index: Int, chosen: Int)
  OutputDetail(expected: String, actual: String)
  TestsDetail(tests: List(runner.TestReport))
  LintDetail(tests: List(runner.TestReport), lint_passed: Bool, lint_message: String)
  CompileErrorDetail(failure: compiler.CompileFailure)  // 유저 코드 오답
  InfraCrashDetail(message: String)                     // 인프라 크래시 → 재시도, 비채점
  SpanDetail(correct: types.Span, chosen_line: Int) }
pub type GradeReport { GradeReport(outcome: types.Outcome, detail: GradeDetail,
  feedback_key: option.Option(String)) }  // schema.FeedbackMap 조회 키

/// grading 종류별 비동기 채점. Choice/ExactOutput(predict 선택지형)·Span 1단계는
/// 컴파일 없이 동기 판정이지만 인터페이스는 Promise로 통일.
/// init 시퀀싱: 컴파일 경로는 내부에서 compiler.init()을 먼저 await(멱등) — 호출자 부담 없음.
/// outcome 매핑: CompileOk+테스트통과→Passed / CompileFailed→Failed+CompileErrorDetail /
///   CompileCrashed→Crashed+InfraCrashDetail / RunCrashed→Failed / RunTimedOut→TimedOut.
pub fn grade(variant: schema.Variant, grading: types.Grading,
  submission: types.Submission, timeout_ms: Int) -> promise.Promise(GradeReport)
/// 레슨 스텝용 — step_to_variant 후 grade 위임, timeout 3000ms 고정
pub fn grade_step(step: schema.Step, submission: types.Submission)
  -> promise.Promise(GradeReport)
/// 무컴파일 동기 채점 — Choice·ExactOutput만 (M1 컴파일러-free 학습 루프). [구현됨]
/// 컴파일 필요 grading은 Failed로 표시 → 비동기 grade로 가야 함.
pub fn grade_step_sync(step: schema.Step, submission: types.Submission) -> GradeReport
```

## engine/error_explain — 에러 번역 사전 (PLAN §4.5)

```gleam
/// 에러 번역 사전 — 로케일 파일에서 로드해 주입 (하드코딩 금지, PLAN §4.5).
/// 키 스킴: "<locale>:<category>" | "<locale>:<category>|<tag_key>" | "<locale>:crash:<kind>"
pub type Lexicon { Lexicon(entries: dict.Dict(String, String)) }
pub fn lexicon_decoder() -> decode.Decoder(Lexicon)
/// pretty 출력에서 "error: <제목>" 카테고리 추출
pub fn category(pretty: String) -> option.Option(String)
/// `src/\w+\.gleam:L:C` 정규식 → CodeMirror 마커용 스팬
pub fn extract_spans(pretty: String) -> List(types.Span)
/// (카테고리 × 퍼즐 테마 × 로케일) → 저작된 한국어 해설. 미번역 시 None(원문만 표시)
pub fn explain(lexicon: Lexicon, category: String, themes: List(types.Tag),
  locale: String) -> option.Option(String)
/// 무한 재귀 이원 매핑: StackOverflow → 꼬리 호출 점검 / Timeout → 종료 조건 점검
pub fn crash_message(lexicon: Lexicon, kind: runner.CrashKind, locale: String) -> String
```

---

## session/lesson — 레슨 진행 상태머신 (PLAN §3.2, 순수)

```gleam
pub type LessonSession   // opaque: 위치, 연속 오답 수, 완료 스텝, 시작 시각
pub type LessonEvent { Submitted(submission: types.Submission)
  Graded(report: grading.GradeReport) HintRequested(level: types.HintLevel)
  Continued Revealed }
pub type LessonCmd { RunGrade(step: schema.Step, submission: types.Submission)
  RegisterSrs(family_ids: List(String)) MarkTagsLearned(tags: List(types.Tag))
  LessonCompleted InsertEasierVariant(step_id: String)  // 2연속 오답 시
  ShowFeedback(markdown: String) }

pub fn start(lesson: schema.Lesson, now_ms: Int) -> LessonSession
pub fn current_block(session: LessonSession) -> option.Option(schema.LessonBlock)
pub fn handle(session: LessonSession, event: LessonEvent, now_ms: Int)
  -> #(LessonSession, List(LessonCmd))
pub fn progress_ratio(session: LessonSession) -> Float
/// UI 화면 분기용 국면 투영 (opaque Phase를 노출하지 않음) — [구현됨]
pub type Status { AtProse AtExercise AtResult AtEnd }
pub fn status(session: LessonSession) -> Status
```

> **[구현 상태]** session/lesson 은 M1에서 완전 구현됨(start/current_block/
> handle/progress_ratio/status). RunGrade는 호스트가 동기(grade_step_sync) 또는
> 비동기(grade) 채점으로 해석. 나머지 세션(checkpoint/placement/training/review)은
> 아직 stub.

## session/checkpoint — 유닛 체크포인트 상태머신 (PLAN §3.2, 순수)

`UnitProgress.checkpoint_passed`의 유일한 생산자 — 10문항/8통과(pass_threshold),
실패 문항 backlink 수집. 채점은 grading.grade_step에 위임(레슨과 동형).

```gleam
pub type CheckpointSession   // opaque
pub type CheckpointEvent { Submitted(submission) Graded(report) Continued }
pub type CheckpointCmd { RunGrade(step, submission)
  CheckpointPassed(unit_id: String)
  CheckpointFailed(unit_id: String, failed_backlinks: List(String)) }
pub fn start(checkpoint: schema.Checkpoint, now_ms: Int) -> CheckpointSession
pub fn current_item(session) -> option.Option(schema.CheckpointItem)
pub fn handle(session, event: CheckpointEvent, now_ms: Int) -> #(CheckpointSession, List(CheckpointCmd))
pub fn progress_ratio(session) -> Float
```

## session/placement — 배치 테스트(온보딩) 상태머신 (PLAN §2, 순수)

12~15 무컴파일 문항 사다리 → 점수 밴드(Int). 콘텐츠 무지식: 문항은 호출자가
manifest에서 주입, 밴드→{선해제 유닛, 태그} 매핑도 호출자(ui/app)가 도출
(level_gate의 "호출자가 도출해 내려준다" 패턴). 무컴파일이라 동기 채점.

```gleam
pub type PlacementSession   // opaque
pub type PlacementEvent { Answered(submission) Skipped }
pub type PlacementCmd { PlacementCompleted(score_band: Int) }
  // 호스트 적용: rating.placement_seed(band)→overall, manifest로 band→유닛/태그 도출
  //   → progress.seed_unit + learned_tags(배치/처음부터=True, 트레이닝만/건너뛰기=False), save
pub fn start(items: List(schema.Step), seed: Int) -> PlacementSession
pub fn current_item(session) -> option.Option(schema.Step)
pub fn handle(session, event: PlacementEvent) -> #(PlacementSession, List(PlacementCmd))
pub fn score_band(session) -> Int      // rating.placement_seed 입력 도메인
pub fn progress_ratio(session) -> Float
```

## session/training — 출제·모드 상태머신 (PLAN §4.3, 순수)

```gleam
pub type TrainingMode { Mixed ThemeDrill(theme: types.Tag) Rush(format: RushFormat)
  Streak Daily(date_key: String) }
pub type RushFormat { ThreeMin FiveMin Survival }
pub type PickError { PoolEmpty NoneLearned CoolingDown }

/// interleaving: 같은 주테마 연속 2회·같은 타입 연속 3회 금지, 약점 테마 +30%,
/// 14일 쿨다운, learned_tags 필터, 모드별 eligible 플래그 필터.
/// target_rating: Some이면 Rush/Streak 램프 난이도 기준(호출자가 summary에서 전달),
/// None이면 모드 기준 레이팅 ± band_range.
/// seed: 결정적 의사난수 시드(호출자가 주입 — 테스트 가능성).
pub fn pick_next(pool: List(schema.PuzzleFamily), profile: profile.Profile,
  mode: TrainingMode, recent: List(types.Attempt),
  target_rating: Option(Float), seed: Int)
  -> Result(#(schema.PuzzleFamily, schema.Variant), PickError)

// rated 시도 세션 (Mixed/ThemeDrill) — rated 판정의 소유자 (PLAN §4.2 중심 프리미티브).
// Rush/Streak/Daily는 unrated라 이 세션을 쓰지 않는다.
pub type AttemptSession  // opaque: family, variant, mode, submitted, hints_used, started_at
pub type AttemptEvent { Submitted(submission) Graded(report) HintRequested(level) Revealed }
pub type AttemptCmd {
  RunGrade(variant, grading, submission, timeout_ms)
  /// 채점 확정 — 호스트가 Attempt 완성(uuid·rating_before/after stamp)·persist:
  ///   rated→record_rated+append / unrated→append만 / Crashed→둘 다 skip+재시도UI
  PersistAttempt(outcome: types.Outcome, rated: Bool, hints_used: Int, duration_ms: Int,
    puzzle_rating: rating.Rating, themes: List(types.Tag), error_category: Option(String))
  ShowHint(level) ShowFeedback(markdown) }
pub fn attempt_start(family, variant, mode: TrainingMode, now_ms: Int) -> AttemptSession
pub fn attempt_handle(session, event: AttemptEvent, now_ms: Int) -> #(AttemptSession, List(AttemptCmd))
/// 순수 rated 규칙(테스트용): Mixed/ThemeDrill ∧ 첫 제출 ∧ 무힌트 ∧ 비-Crashed
pub fn is_rated(mode: TrainingMode, first_submit: Bool, hints_used: Int, outcome: types.Outcome) -> Bool

pub type RushState   // opaque: lives, combo, score, deadline, difficulty, history, seed
pub fn rush_start(format: RushFormat, user: rating.Rating, seed: Int, now_ms: Int) -> RushState
pub fn rush_answer(state: RushState, correct: Bool, now_ms: Int) -> RushState
  // 콤보 5/12/20/30→+3/+5/+7/+10s, 이후 10회마다 +10s; 오답 = 콤보리셋 -10s -1목숨
pub fn rush_is_over(state: RushState, now_ms: Int) -> Bool
/// UI용 읽기 전용 스냅샷 — opaque 상태의 유일한 관측 창구
pub type RushSummary { RushSummary(lives: Int, combo: Int, score: Int,
  time_left_ms: Option(Int), difficulty: Float) }
pub fn rush_summary(state: RushState, now_ms: Int) -> RushSummary
pub type StreakState // opaque: 현재 난이도, 정답 수, 스킵 사용 여부, alive
pub fn streak_start() -> StreakState
pub fn streak_answer(state: StreakState, correct: Bool) -> StreakState
pub fn streak_skip(state: StreakState) -> Result(StreakState, Nil)  // 스킵 1회 (PLAN §4.3)
pub type StreakSummary { StreakSummary(solved: Int, skip_used: Bool, alive: Bool,
  difficulty: Float) }
pub fn streak_summary(state: StreakState) -> StreakSummary
pub fn daily_key(now_ms: Int) -> String   // Asia/Seoul 자정 결정적 해시 (PLAN §4.3)
```

## session/review — SRS 복습 큐 (PLAN §4.4, 순수)

```gleam
pub type ReviewQueue   // opaque
pub type ReviewItem { ReviewItem(card: srs.SrsCard, family: schema.PuzzleFamily,
  variant: schema.Variant) }  // last_variant 회피 회전

pub const daily_new_cap = 10
pub const daily_review_cap = 50
/// served_today: 당일 기 소화 (신규, 리뷰) — 캡은 하루 단위 (호출자가 attempt 로그에서 집계)
pub fn build(profile: profile.Profile, families: List(schema.PuzzleFamily),
  served_today: #(Int, Int), now_ms: Int, seed: Int) -> ReviewQueue
pub fn next(queue: ReviewQueue) -> option.Option(ReviewItem)
pub fn apply(queue: ReviewQueue, profile: profile.Profile, family_id: String,
  outcome: srs.ReviewOutcome, now_ms: Int) -> #(ReviewQueue, profile.Profile)
pub fn remaining(queue: ReviewQueue) -> Int
/// 세션 종료/이탈 정리 — retry 잔여 카드 = 세션 종료 시점 실패 → L1 리셋 (PLAN §4.4)
pub fn finalize(queue: ReviewQueue, profile: profile.Profile, now_ms: Int) -> profile.Profile
```

---

## storage/local — localStorage (PLAN §5.4, FFI: local_ffi.mjs)

키: `fpdojo.v1.profile`, `fpdojo.v1.attempts` (append-only, 2,000건 컴팩션)

```gleam
pub type StorageError { NotAvailable QuotaExceeded DecodeFailed(String) }
pub fn load_profile() -> Result(option.Option(profile.Profile), StorageError)
pub fn save_profile(profile: profile.Profile) -> Result(Nil, StorageError)
pub fn append_attempt(attempt: types.Attempt) -> Result(Nil, StorageError)
pub fn load_attempts() -> Result(List(types.Attempt), StorageError)
pub fn export_json() -> Result(String, StorageError)     // M1 필수
pub fn import_json(json: String) -> Result(Nil, StorageError)
```

## fpdojo/platform — 시간·uuid·로케일 (FFI: platform_ffi.mjs)

```gleam
pub fn now_ms() -> Int
pub fn new_uuid() -> String
pub fn random_seed() -> Int
```

## ui/* — Lustre SPA

- `ui/app.gleam`: `pub type Model`, `pub type Msg`, `pub fn init/update/view`,
  라우팅(`Route` enum: Home Onboarding Lesson Training Review Dashboard),
  `pub fn main()` 엔트리. update는 session/* 순수 상태머신
  (lesson/checkpoint/placement/training의 AttemptSession/review)에 위임하고
  각 Cmd 리스트를 Effect로 해석 — 특히 AttemptCmd.PersistAttempt에서
  rated→profile.record_rated+storage.append_attempt, PlacementCmd→
  rating.placement_seed+progress.seed_unit+learned_tags, CheckpointCmd→
  UnitProgress.checkpoint_passed 갱신을 수행.
- `ui/pages/{home,onboarding,lesson,training,review,dashboard}.gleam`:
  현재 stub은 인자 없는 `pub fn view() -> element.Element(msg)` 자리표시자.
  본구현에서 각 페이지별 view-model 인자(`view(vm: PageVm)`)를 받도록 확장한다
  (ui/app이 Model에서 페이지 vm을 투영해 전달).
- `ui/editor.gleam`: CodeMirror 6 custom element 래퍼 (FFI: editor_ffi.mjs).
  ```gleam
  pub fn register() -> Nil                       // <code-editor> 등록
  pub fn editor(id: String, source: String, read_only_ranges: List(#(Int, Int)),
    on_change: fn(String) -> msg) -> element.Element(msg)  // id → attribute "editor-id"
  @external(javascript, "./editor_ffi.mjs", "setErrorMarkers")  // 직접 위임
  pub fn set_error_markers(id: String, spans: List(types.Span)) -> Nil
  ```

## JS 자산 (gleam 모듈 아님)

- `src/fpdojo/engine/compiler_ffi.mjs` — 워커 스폰·message-passing 포트.
  인터페이스 고정(후일 iframe 격상 대비): `initCompiler()`, `compileModules(modules)`.
- `src/fpdojo/engine/runner_ffi.mjs` — 일회용 러너 스폰, watchdog, 결과 파싱.
- `priv/static/workers/compiler.worker.js` — 장수명. 프로토콜:
  `{id, type:"init"|"compile", modules:[{name,code}]}` →
  `{id, ok:true, modules:[{name,js}], warnings:[]} | {id, ok:false, pretty}`.
- `priv/static/workers/runner.worker.js` — import 재작성(stdlib→/precompiled/,
  모듈간→data URL leaf-first), console.log 캡처, 하니스 프로토콜 stdout 수집.
- `priv/static/harness/harness.gleam` — 주입용 하니스 (suite/test, rescue FFI).
- `priv/static/harness/harness_ffi.mjs` — try/catch rescue,
  `__<토큰>__|pass|이름` / `__<토큰>__|fail|이름|메시지` 프로토콜 방출.

## tools/ (Node, stub)

- `tools/build-content.mjs` — content/ TOML → priv/static/content/*.json 청크.
- `tools/golden/verify.mjs` — 핀 버전 WASM 컴파일러를 Node에서 구동, 전 변형
  골든 검증(PLAN §5.3의 ①~④ 단계를 TODO 주석으로 명시).
- `tools/scaffold.mjs` — 레슨/퍼즐 템플릿 생성 CLI.
