//// 레슨 진행 상태머신 — PLAN §3.2 (순수 모듈).
////
//// 설명 세그먼트(Prose) 3~5개와 마이크로 연습(Exercise, P1~P5) 5~10개가
//// 교차하는 단일 레슨 1개의 진행을 관리한다. 신규 개념은 레슨당 정확히
//// 1개(PLAN §3.2)이며, 정답 시에도 한 줄 코멘터리·오답 시 feedback_map의
//// 사전 저작 해설·2연속 오답 시 near-neighbor 쉬운 변형 삽입(Brilliant)·
//// 재시도 무벌점·'정답 보기'만 SRS 인터벌 축소 규칙을 구현한다.
////
//// 효과가 필요한 일(채점 실행, SRS 등록, 태그 학습 전환, 피드백 표시)은
//// 직접 수행하지 않고 전부 `LessonCmd` 리스트로 방출한다 — ui/app의
//// update가 이를 lustre Effect로 해석한다(interfaces.md ui/* 절).
////
//// 의존 방향: core/types · content/schema · engine/grading 만 import.
//// 시간은 항상 `now_ms` 인자로 주입한다(순수성 유지 — interfaces.md 서문).

import fpdojo/content/schema
import fpdojo/core/types
import fpdojo/engine/grading
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option}

/// 세션 내부 국면. Prose 블록은 Continued로만 전진하고,
/// Exercise 블록은 Submitted → (RunGrade) → Graded → Continued 사이클을 돈다.
type Phase {
  /// Prose 세그먼트 표시 중 — `Continued`로 다음 블록 전진
  Reading
  /// Exercise 표시 중 — `Submitted` 대기 (힌트 H1~H3 요청 가능, PLAN §4.5)
  Solving
  /// `RunGrade` 커맨드 방출 후 호스트의 `Graded` 이벤트 대기
  AwaitingGrade
  /// 채점 결과·코멘터리 표시 중 — `Continued`로 전진 (오답이면 같은 스텝 재시도)
  ShowingResult
  /// 마지막 블록 통과 — 완료 커맨드 방출 후의 종착 상태
  Done
}

/// 레슨 세션 상태 (opaque — 내부 표현은 본 모듈의 설계 산출물).
///
/// 불변식:
/// - `cursor`는 `lesson.blocks`의 0-기반 인덱스, `Done`이면 블록 범위 밖.
/// - `wrong_streak`은 현재 스텝의 연속 오답 수 — 2 도달 시
///   `InsertEasierVariant` 방출 후 리셋 (PLAN §3.2).
/// - `steps_done`은 통과(또는 정답 보기)한 step id의 누적 — progress_ratio의 분자.
/// - `revealed_steps`는 '정답 보기'한 step id — 레슨 완료 시 SRS 인터벌 축소
///   판단의 근거 (PLAN §3.2 "'정답 보기'만 SRS 인터벌 축소").
pub opaque type LessonSession {
  LessonSession(
    lesson: schema.Lesson,
    cursor: Int,
    phase: Phase,
    wrong_streak: Int,
    steps_done: List(String),
    revealed_steps: List(String),
    /// 현재 스텝에서 연 힌트 수 (H1부터 unrated 의미론은 트레이닝 전용이지만
    /// 레슨도 기록은 남긴다 — PLAN §4.5)
    hints_used: Int,
    started_at_ms: Int,
  )
}

/// 호스트(ui/app)가 세션에 주입하는 이벤트.
pub type LessonEvent {
  /// 학습자가 현재 Exercise에 답을 제출 — `RunGrade` 방출로 이어진다
  Submitted(submission: types.Submission)
  /// 호스트가 engine/grading의 비동기 채점을 끝내고 결과를 회송
  Graded(report: grading.GradeReport)
  /// 3단계 힌트 요청 (H1 개념 환기 / H2 스팬 / H3 정답+해설 — PLAN §4.5)
  HintRequested(level: types.HintLevel)
  /// "계속" — Prose 전진 또는 채점 결과 화면에서 다음 블록으로
  Continued
  /// '정답 보기' (give up) — 스텝을 넘기되 SRS 인터벌 축소 대상으로 기록
  Revealed
}

/// 세션이 방출하는 커맨드 — ui/app이 Effect로 해석한다.
pub type LessonCmd {
  /// engine/grading.grade 호출 요청 (Promise → `Graded` 이벤트로 회송)
  RunGrade(step: schema.Step, submission: types.Submission)
  /// 레슨 완료 시 `lesson.srs_items`(핵심 아이템 2~4개)를 SRS에 등록 (PLAN §2, §4.4)
  RegisterSrs(family_ids: List(String))
  /// 레슨 완료 시 `lesson.emits_tags`를 "학습됨"으로 전환 → 트레이닝 풀 즉시 편입 (PLAN §2)
  MarkTagsLearned(tags: List(types.Tag))
  /// 진행 모델 갱신(UnitProgress.lessons_done append)·완료 화면 전환 트리거
  LessonCompleted
  /// 2연속 오답 → near-neighbor 쉬운 변형 삽입 (Brilliant, PLAN §3.2)
  InsertEasierVariant(step_id: String)
  /// 코멘터리/오답 진단 표시 — 정답 시 한 줄, 오답 시 feedback_map 저작 해설 (PLAN §3.2)
  ShowFeedback(markdown: String)
}

/// 레슨 시작 — 첫 블록(보통 Prose)을 가리키는 초기 세션을 만든다.
/// `now_ms`는 started_at_ms로 기록(소요 시간 통계용, 레이팅 비반영 — PLAN §4.2).
pub fn start(lesson: schema.Lesson, now_ms: Int) -> LessonSession {
  let phase = case block_at(lesson.blocks, 0) {
    option.Some(block) -> phase_for(block)
    option.None -> Done
  }
  LessonSession(
    lesson: lesson,
    cursor: 0,
    phase: phase,
    wrong_streak: 0,
    steps_done: [],
    revealed_steps: [],
    hints_used: 0,
    started_at_ms: now_ms,
  )
}

/// 표시 언어 전환 — 진행 상태(cursor·phase·streak 등)는 그대로 두고 임베드된
/// 레슨만 번역본으로 갈아끼운다. 한/영 seed는 구조(블록 수·순서·id·정답)가
/// 1:1로 동일하다는 불변식(구조 동등성 테스트가 보증)에 기대므로, 같은 cursor가
/// 가리키는 블록의 의미는 보존되고 표시 문구만 바뀐다.
pub fn relocalize(
  session: LessonSession,
  translated: schema.Lesson,
) -> LessonSession {
  LessonSession(..session, lesson: translated)
}

/// 현재 표시할 블록. `Done`이면 `None` — UI는 완료 화면으로 전환한다.
pub fn current_block(session: LessonSession) -> Option(schema.LessonBlock) {
  case session.phase {
    Done -> option.None
    _ -> block_at(session.lesson.blocks, session.cursor)
  }
}

/// UI가 읽는 국면 투영 — opaque 내부 Phase를 노출하지 않고 화면 분기에 쓴다.
pub type Status {
  /// 설명 세그먼트 표시 — "계속" 버튼
  AtProse
  /// 연습 풀이 중 — 답 입력 + "제출" (오답 후 재시도도 이 상태)
  AtExercise
  /// 정답 처리 후 결과 표시 — "계속" 버튼
  AtResult
  /// 레슨 완료
  AtEnd
}

/// 현재 국면을 Status로 투영 (AwaitingGrade는 동기 채점 시 잠깐이라 AtExercise로 본다).
pub fn status(session: LessonSession) -> Status {
  case session.phase {
    Reading -> AtProse
    Solving -> AtExercise
    AwaitingGrade -> AtExercise
    ShowingResult -> AtResult
    Done -> AtEnd
  }
}

/// 핵심 전이 함수 — 이벤트 1개를 받아 (다음 상태, 방출 커맨드 목록)을 돌려준다.
///
/// 계약 (PLAN §3.2, §4.5):
/// - `Submitted`: Solving → AwaitingGrade, `[RunGrade(step, submission)]` 방출.
/// - `Graded(Passed)`: wrong_streak 리셋·steps_done 추가, 정답 한 줄 코멘터리
///   `ShowFeedback` 방출 후 ShowingResult.
/// - `Graded(Failed/..)`: wrong_streak+1, feedback_key로 step.feedback에서 찾은
///   진단 문장을 `ShowFeedback`. 2연속 오답이면 `InsertEasierVariant` 추가 방출.
///   재시도 무벌점 — 같은 스텝을 다시 Solving으로.
/// - `HintRequested`: hints_used+1 기록 (H3는 정답 노출 — Revealed에 준해 기록).
/// - `Continued`: 다음 블록 전진. 마지막 블록을 넘으면 Done +
///   `[RegisterSrs(srs_items), MarkTagsLearned(emits_tags), LessonCompleted]`.
/// - `Revealed`: 스텝 통과 처리 + revealed_steps 기록 (SRS 인터벌 축소 근거).
/// - 국면에 맞지 않는 이벤트는 무시(상태 불변, 커맨드 없음) — 전이 전체가 전함수.
pub fn handle(
  session: LessonSession,
  event: LessonEvent,
  _now_ms: Int,
) -> #(LessonSession, List(LessonCmd)) {
  case session.phase, event {
    // 설명/결과 화면에서 "계속" → 다음 블록 전진
    Reading, Continued -> advance(session)
    ShowingResult, Continued -> advance(session)

    // 연습 제출 → 채점 위임 (호스트가 RunGrade를 grade로 해석해 Graded 회송)
    Solving, Submitted(submission) ->
      case current_step(session) {
        option.Some(step) -> #(LessonSession(..session, phase: AwaitingGrade), [
          RunGrade(step, submission),
        ])
        option.None -> #(session, [])
      }

    // 채점 결과 반영
    AwaitingGrade, Graded(report) ->
      case current_step(session) {
        option.None -> #(session, [])
        option.Some(step) ->
          case report.outcome {
            // 정답 — 통과 처리 + 한 줄 코멘터리
            types.Passed -> #(
              LessonSession(
                ..session,
                phase: ShowingResult,
                wrong_streak: 0,
                steps_done: [step.id, ..session.steps_done],
              ),
              [ShowFeedback(feedback_text(step, "correct", "정답입니다! 잘했어요."))],
            )

            // 인프라 크래시 — 미집계, 같은 연습 재시도 (PLAN §5.2)
            types.Crashed(_) -> #(LessonSession(..session, phase: Solving), [
              ShowFeedback("일시적 오류가 발생했어요. 다시 시도해 주세요."),
            ])

            // 오답/타임아웃 — 재시도 무벌점, feedback_map 해설, 2연속 시 쉬운 변형
            _ -> {
              let ws = session.wrong_streak + 1
              let key = option.unwrap(report.feedback_key, "wrong")
              let fb = feedback_text(step, key, "아직 정답이 아니에요. 다시 살펴보세요.")
              let easier = case ws >= 2 {
                True -> [InsertEasierVariant(step.id)]
                False -> []
              }
              #(LessonSession(..session, phase: Solving, wrong_streak: ws), [
                ShowFeedback(fb),
                ..easier
              ])
            }
          }
      }

    // 힌트 요청 — 레슨 스텝엔 별도 힌트 콘텐츠가 없어 카운트만 (PLAN §4.5 기록)
    Solving, HintRequested(_) -> #(
      LessonSession(..session, hints_used: session.hints_used + 1),
      [],
    )

    // '정답 보기' — 통과로 넘기되 revealed에 기록 (SRS 인터벌 축소 근거)
    Solving, Revealed ->
      case current_step(session) {
        option.None -> #(session, [])
        option.Some(step) -> #(
          LessonSession(
            ..session,
            phase: ShowingResult,
            steps_done: [step.id, ..session.steps_done],
            revealed_steps: [step.id, ..session.revealed_steps],
          ),
          [ShowFeedback(feedback_text(step, "correct", "정답을 확인하세요."))],
        )
      }

    // 국면에 맞지 않는 이벤트는 무시 (전함수)
    _, _ -> #(session, [])
  }
}

/// 진행률 0.0~1.0 — 현재 위치 / 전체 블록 수. 상단 진행 바 표시용.
pub fn progress_ratio(session: LessonSession) -> Float {
  let total = list.length(session.lesson.blocks)
  case total {
    0 -> 0.0
    _ -> {
      let done = case session.phase {
        Done -> total
        _ -> session.cursor
      }
      int.to_float(done) /. int.to_float(total)
    }
  }
}

// ── 내부 헬퍼 ─────────────────────────────────────────────────────

/// 다음 블록으로 전진. 마지막을 넘으면 Done + 완료 커맨드(SRS 등록·태그 학습).
fn advance(session: LessonSession) -> #(LessonSession, List(LessonCmd)) {
  let next = session.cursor + 1
  case block_at(session.lesson.blocks, next) {
    option.Some(block) -> #(
      LessonSession(
        ..session,
        cursor: next,
        phase: phase_for(block),
        wrong_streak: 0,
      ),
      [],
    )
    option.None -> #(LessonSession(..session, cursor: next, phase: Done), [
      RegisterSrs(session.lesson.srs_items),
      MarkTagsLearned(session.lesson.emits_tags),
      LessonCompleted,
    ])
  }
}

fn current_step(session: LessonSession) -> Option(schema.Step) {
  case block_at(session.lesson.blocks, session.cursor) {
    option.Some(schema.Exercise(step)) -> option.Some(step)
    _ -> option.None
  }
}

fn block_at(
  blocks: List(schema.LessonBlock),
  i: Int,
) -> Option(schema.LessonBlock) {
  case i < 0 {
    True -> option.None
    False -> option.from_result(list.first(list.drop(blocks, i)))
  }
}

fn phase_for(block: schema.LessonBlock) -> Phase {
  case block {
    schema.Prose(_, _) -> Reading
    schema.Exercise(_) -> Solving
  }
}

fn feedback_text(step: schema.Step, key: String, fallback: String) -> String {
  case dict.get(step.feedback.entries, key) {
    Ok(text) -> text
    Error(_) -> fallback
  }
}
