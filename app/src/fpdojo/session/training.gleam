//// 트레이닝 출제·모드 상태머신 — PLAN §4.3 (순수 모듈).
////
//// 6개 모드(믹스드/테마 드릴/Code Rush/Streak/데일리/복습)는 전부
//// "rated puzzle attempt" 단일 프리미티브 위의 박막이다
//// (docs/design/training-system.md §0). 본 모듈은 그중 출제 선택과
//// Rush/Streak의 런 상태만 담당하고, 채점·레이팅 갱신·SRS는 각각
//// engine/grading · core/rating · session/review의 일이다.
////
//// rated 의미론(PLAN §4.2): 믹스드·테마 드릴의 첫 무힌트 시도만 rated.
//// Rush/Streak/데일리는 전부 unrated — 게이미피케이션은 rated 루프 밖에
//// 둔다(training-system.md §0-5).
////
//// 의존 방향: core/types · core/rating · core/profile · content/schema 만
//// import. 시간은 `now_ms`, 난수는 `seed`로 주입한다(순수성 유지).

import fpdojo/content/schema
import fpdojo/core/profile
import fpdojo/core/rating
import fpdojo/core/types
import fpdojo/engine/grading
import gleam/option.{type Option}

/// 출제 모드. 난이도 기준이 모드마다 다르다 (PLAN §4.3):
/// Mixed = 글로벌 레이팅 ±밴드 / ThemeDrill = 해당 테마 서브 레이팅 ±밴드 /
/// Rush·Streak = 자체 난이도 램프 / Daily = 1500~1800 큐레이션 고정대.
pub type TrainingMode {
  /// 기본 rated 모드 — interleaving + 약점 가중 (PLAN §4.3 표 1행)
  Mixed
  /// 특정 테마 집중(blocked practice) — 레슨 완료 화면·약점 카드에서 진입
  ThemeDrill(theme: types.Tag)
  /// 통합 타임드 모드 ("Storm"/"Code Storm" 명칭 폐기 — PLAN §4.3)
  Rush(format: RushFormat)
  /// 시계 없음·오름차순 램프·1실수 종료
  Streak
  /// 전 유저 동일 1개/일 — `daily_key`가 만든 날짜 키로 결정적 선택
  Daily(date_key: String)
}

/// Code Rush 3포맷 (chess.com Rush 대응). 3 strikes는 전 포맷 공통이며
/// Survival은 시계 없이 정확도 승부 (PLAN §4.3).
pub type RushFormat {
  ThreeMin
  FiveMin
  Survival
}

/// 출제 실패 사유.
pub type PickError {
  /// 모드별 eligible·쿨다운·interleaving 필터 적용 후 후보가 0개
  PoolEmpty
  /// learned_tags 필터 결과 0개 — 학습 전 테마 퍼즐은 서빙 안 함 (PLAN §2)
  NoneLearned
  /// 남은 후보가 전부 14일 쿨다운 중 (PLAN §4.3 테마 드릴 행)
  CoolingDown
}

/// 다음 퍼즐 1개를 결정적으로 선택한다 — (패밀리, 출제 변형) 쌍 반환.
///
/// 필터·가중 계약 (PLAN §4.3, training-system.md §3.2):
/// - learned_tags 필터: profile.learned_tags(학습됨 True/잠정 False 모두)에
///   포함된 테마의 패밀리만 후보 — 레슨이 태그를 연다 (PLAN §2 맞물림 규칙).
/// - 모드별 eligible 플래그 필터: Rush → rush_eligible(P1 선택지형/P2/P3 한 줄/
///   P7 4~6줄/P8 1단계), Streak → streak_eligible(Rush 풀 + P4 + P8 2단계).
///   P5 write_fn·P6 refactor는 두 타임드 모드 모두 제외 (PLAN §4.3 타임드 적합성).
/// - interleaving: 같은 주테마 연속 2회 금지, 같은 타입 연속 3회 금지 —
///   `recent`의 직전 시도들로 판정.
/// - 약점 테마 +30% 가중 (최근 30일 실패율 기준 — training-system.md §3.2.
///   단, 직전 실패 테마 즉시 재출제는 안 함 — 그건 복습 큐의 일).
/// - 동일 패밀리 14일 쿨다운: `recent`의 at_ms로 판정.
/// - 난이도: `target_rating`이 Some이면 그 값 기준(Rush/Streak 램프 —
///   호출자가 rush_summary/streak_summary의 difficulty를 전달),
///   None이면 모드 기준 레이팅 ± rating.band_range (PLAN §4.2 5밴드).
/// - 변형 선택: seed 기반 결정적 의사난수 (SRS와 달리 last_variant 제약 없음).
///
/// `seed`: 호출자(ui/app의 platform.random_seed)가 주입하는 결정적 시드 —
/// 같은 입력이면 같은 출제 (테스트 가능성).
pub fn pick_next(
  pool: List(schema.PuzzleFamily),
  profile: profile.Profile,
  mode: TrainingMode,
  recent: List(types.Attempt),
  target_rating: Option(Float),
  seed: Int,
) -> Result(#(schema.PuzzleFamily, schema.Variant), PickError) {
  todo as "learned_tags·eligible·쿨다운·interleaving 필터 후 약점 +30% 가중 추첨으로 패밀리·변형 선택"
}

// ── rated 시도 세션 (Mixed/ThemeDrill) ────────────────────────────
//
// PLAN의 중심 프리미티브는 "rated puzzle attempt"인데(PLAN §1), rated 여부
// ("첫 무힌트 시도만", §4.2 lichess 의미론)를 계산할 주체가 필요하다. 이
// 세션이 그 주체다 — 한 퍼즐에 대한 제출·힌트·정답 보기를 추적해 rated를
// 결정하고, 채점 결과를 Attempt 구성 재료로 방출한다. Rush/Streak/Daily는
// 전부 unrated이므로 이 세션을 쓰지 않는다(RushState/StreakState가 별도 담당).

/// Mixed/ThemeDrill 단일 퍼즐 시도 세션 (opaque — rated 판정의 소유자).
///
/// 불변식:
/// - `submitted`: 이 퍼즐에 제출이 한 번이라도 있었는가(첫 시도 판정).
/// - `hints_used`: H1부터 열면 그 시도는 unrated (PLAN §4.5).
pub opaque type AttemptSession {
  AttemptSession(
    family: schema.PuzzleFamily,
    variant: schema.Variant,
    mode: TrainingMode,
    submitted: Bool,
    hints_used: Int,
    started_at_ms: Int,
  )
}

/// 호스트가 주입하는 이벤트 (session/lesson의 LessonEvent와 대칭).
pub type AttemptEvent {
  Submitted(submission: types.Submission)
  Graded(report: grading.GradeReport)
  HintRequested(level: types.HintLevel)
  Revealed
}

/// 세션이 방출하는 커맨드 — ui/app이 Effect로 해석한다.
pub type AttemptCmd {
  /// engine/grading.grade 호출 요청 (Promise → `Graded`로 회송)
  RunGrade(
    variant: schema.Variant,
    grading: types.Grading,
    submission: types.Submission,
    timeout_ms: Int,
  )
  /// 채점 확정 — 호스트가 이 재료로 types.Attempt를 완성(id=uuid,
  /// rating_before/after는 호스트가 stamp)하고 persist한다:
  ///   - rated=True       → profile.record_rated + storage.append_attempt
  ///   - rated=False       → storage.append_attempt만
  ///   - outcome=Crashed   → 둘 다 skip + "다시 시도" UI (PLAN §5.2)
  /// puzzle_rating은 M1~M2 시드 고정(rating.new_puzzle(family.seed_tier)),
  /// themes는 family.primary_theme + family.themes.
  PersistAttempt(
    outcome: types.Outcome,
    rated: Bool,
    hints_used: Int,
    duration_ms: Int,
    puzzle_rating: rating.Rating,
    themes: List(types.Tag),
    error_category: Option(String),
  )
  /// 힌트 단계 표시 (H1~H3). H3는 정답 노출 — 이후 rated 불가.
  ShowHint(level: types.HintLevel)
  /// 코멘터리/오답 진단 표시 (feedback_map 저작 해설)
  ShowFeedback(markdown: String)
}

/// 시도 세션 시작 — pick_next가 고른 (패밀리, 변형)과 모드로 초기화.
pub fn attempt_start(
  family: schema.PuzzleFamily,
  variant: schema.Variant,
  mode: TrainingMode,
  now_ms: Int,
) -> AttemptSession {
  AttemptSession(
    family: family,
    variant: variant,
    mode: mode,
    submitted: False,
    hints_used: 0,
    started_at_ms: now_ms,
  )
}

/// 핵심 전이 — 이벤트 1개를 받아 (다음 상태, 커맨드 목록)을 돌려준다.
///
/// 계약 (PLAN §4.2, §4.5):
/// - `Submitted`: `[RunGrade(variant, family.grading, submission, family.timeout_ms)]`
///   방출. (submitted 플래그는 Graded 도착 시점에 rated 판정에 쓰고 갱신.)
/// - `Graded`: `is_rated`로 rated 결정 후 `PersistAttempt`(+정답 한 줄/오답
///   feedback_map `ShowFeedback`) 방출, submitted=True로 갱신. outcome=Crashed면
///   rated=False·PersistAttempt(Crashed)만(호스트가 비채점·재시도 처리).
/// - `HintRequested`: hints_used+1, `[ShowHint(level)]`. (이후 시도는 unrated.)
/// - `Revealed`: 정답 노출 — GaveUp outcome으로 `PersistAttempt(rated:False)`.
pub fn attempt_handle(
  session: AttemptSession,
  event: AttemptEvent,
  now_ms: Int,
) -> #(AttemptSession, List(AttemptCmd)) {
  todo as "제출→채점 위임, Graded 시 is_rated로 rated 판정해 PersistAttempt 방출, 힌트는 hints_used 증가, 정답 보기는 GaveUp 기록"
}

/// 순수 rated 규칙(테스트용으로 노출) — PLAN §4.2:
/// 첫 제출 ∧ 무힌트(hints_used==0) ∧ 비크래시(outcome != Crashed) ∧
/// 모드가 Mixed/ThemeDrill일 때만 True. 그 외 전부 unrated.
pub fn is_rated(
  mode: TrainingMode,
  first_submit: Bool,
  hints_used: Int,
  outcome: types.Outcome,
) -> Bool {
  todo as "Mixed/ThemeDrill ∧ first_submit ∧ hints_used==0 ∧ outcome가 Crashed 아님 판정"
}

/// Code Rush 런 상태 (opaque — 내부 표현은 본 모듈의 설계 산출물).
///
/// 불변식 (PLAN §4.3):
/// - `lives`: 3에서 시작, 오답마다 −1 — 0이면 종료 (3 strikes, 전 포맷 공통).
/// - `combo`: 연속 정답 수 — 오답 시 0으로 리셋.
/// - `score`: 정답 수 (unrated — 점수가 곧 기록).
/// - `deadline_at_ms`: 절대 마감 시각. ThreeMin/FiveMin은 Some(시작+180s/300s),
///   Survival은 None. 콤보 보너스(+3/+5/+7/+10s…)는 마감을 뒤로 미루고,
///   오답 −10s는 앞으로 당긴다.
/// - `difficulty`: 출제 램프 — 시작 max(600, 유저 레이팅−600), 정답마다 +40~60.
/// - `history`: 정오답 이력 (최신이 head) — 콤보 임계 판정·기록 화면용.
pub opaque type RushState {
  RushState(
    format: RushFormat,
    lives: Int,
    combo: Int,
    score: Int,
    deadline_at_ms: Option(Int),
    difficulty: Float,
    history: List(Bool),
    started_at_ms: Int,
    /// rush_start에서 주입 — 난이도 램프 +40~60 난수 폭의 결정적 시드
    seed: Int,
  )
}

/// Rush 런 시작. 시작 난이도 = max(600, user.value − 600),
/// 마감 = now + 3분/5분 (Survival은 마감 없음). lives 3, combo·score 0.
/// `seed`: 난이도 램프 +40~60의 난수 폭용 결정적 시드 (pick_next와 동일 원칙).
pub fn rush_start(
  format: RushFormat,
  user: rating.Rating,
  seed: Int,
  now_ms: Int,
) -> RushState {
  todo as "포맷별 마감 시각과 max(600, 레이팅-600) 시작 난이도로 RushState 초기화"
}

/// UI 표시용 읽기 전용 스냅샷 — RushState는 opaque이므로 이 함수가 유일한
/// 관측 창구다. `time_left_ms`: Survival은 None, 시계 포맷은 max(0, 잔여).
pub type RushSummary {
  RushSummary(
    lives: Int,
    combo: Int,
    score: Int,
    time_left_ms: Option(Int),
    difficulty: Float,
  )
}

pub fn rush_summary(state: RushState, now_ms: Int) -> RushSummary {
  todo as "RushState 내부 필드를 RushSummary로 투영하고 잔여 시간을 계산"
}

/// 정답/오답 1회 반영 (PLAN §4.3 Code Rush 행):
/// - 정답: score+1, combo+1, difficulty +40~60(결정적 의사난수 — score 기반),
///   콤보 5/12/20/30회 도달 시 +3/+5/+7/+10초, 이후 10회마다 +10초 마감 연장.
/// - 오답: 콤보 리셋, 마감 −10초, lives −1.
/// 종료 판정은 하지 않는다 — `rush_is_over`가 분리 담당 (시계는 매 프레임 검사).
pub fn rush_answer(state: RushState, correct: Bool, now_ms: Int) -> RushState {
  todo as "정답 시 콤보 보너스·난이도 램프, 오답 시 콤보 리셋·-10초·-1목숨 반영"
}

/// 런 종료 여부: lives 0 (3 strikes) 또는 마감 시각 경과 (Survival은 목숨만).
pub fn rush_is_over(state: RushState, now_ms: Int) -> Bool {
  todo as "lives 소진 또는 deadline_at_ms 경과 여부 판정"
}

/// Streak 런 상태 (opaque). 시계 없음·힌트 불가 (PLAN §4.3 Streak 행).
///
/// 불변식: `difficulty` 600에서 시작해 정답마다 +30~50 오름차순 고정 램프,
/// `solved` 정답 수(최장 기록 갱신용), `skip_used` 스킵 1회 사용 여부,
/// `alive` False = 오답 1회로 종료된 상태.
pub opaque type StreakState {
  StreakState(difficulty: Float, solved: Int, skip_used: Bool, alive: Bool)
}

/// Streak 시작 — 난이도 600, 정답 0, 스킵 미사용 (PLAN §4.3).
pub fn streak_start() -> StreakState {
  StreakState(difficulty: 600.0, solved: 0, skip_used: False, alive: True)
}

/// 정답: solved+1, difficulty +30~50 (solved 기반 결정적 의사난수).
/// 오답: alive False — 한 번이라도 틀리면 즉시 종료 (PLAN §4.3).
pub fn streak_answer(state: StreakState, correct: Bool) -> StreakState {
  todo as "정답 시 +30~50 램프 상승, 오답 시 런 종료 처리"
}

/// 스킵 1회 사용 (PLAN §4.3 Streak 행). 이미 사용했거나 종료된 런이면 Error.
/// 스킵은 난이도 램프를 올리지 않고 다음 출제로 넘어간다.
pub fn streak_skip(state: StreakState) -> Result(StreakState, Nil) {
  todo as "skip_used·alive 검사 후 skip_used=True로 전이"
}

/// UI 표시용 읽기 전용 스냅샷 — StreakState는 opaque이므로 이 함수가
/// 유일한 관측 창구다.
pub type StreakSummary {
  StreakSummary(solved: Int, skip_used: Bool, alive: Bool, difficulty: Float)
}

pub fn streak_summary(state: StreakState) -> StreakSummary {
  todo as "StreakState 내부 필드를 StreakSummary로 투영"
}

/// 데일리 퍼즐 날짜 키 — Asia/Seoul 자정 기준 결정적 키 (PLAN §4.3).
/// KST는 UTC+9 고정(서머타임 없음)이므로 now_ms + 9h를 일 단위로 절단해
/// 순수 계산 가능. 반환 키는 `Daily(date_key)` 모드와 해설 다음 날 00:00 KST
/// 클라이언트 게이팅의 입력이 된다.
pub fn daily_key(now_ms: Int) -> String {
  todo as "now_ms를 UTC+9로 보정해 일 단위 날짜 키 문자열 생성"
}
