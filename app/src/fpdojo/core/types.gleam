//// 플랫폼 전역 공유 어휘 (shared vocabulary).
////
//// 이 모듈은 다른 fpdojo 모듈을 import하지 않는다 — 의존 그래프의 루트.
//// PLAN.md §4.1(퍼즐 타입 레지스트리), §5.4(데이터 모델)의 canonical 정의.

import gleam/option.{type Option}

// ── 태그 ──────────────────────────────────────────────────────────

/// 단일 태그 레지스트리(content/registry/tags.toml)의 canonical 슬러그.
/// 슬러그 유효성은 콘텐츠 빌드(CI)에서 검증되므로 런타임은 신뢰한다.
pub type Tag {
  /// 개념 태그 — Exercism Gleam 트랙 슬러그 원문 (예: "basics", "use-expressions")
  Concept(slug: String)
  /// 트리키 파트 태그 — PLAN.md §3.4의 16개 (예: "fold-arg-order")
  Tricky(slug: String)
  /// FP 이론 트랙 태그 — docs/design/fp-theory-curriculum.md §6 (예: "functor-laws")
  Theory(slug: String)
}

/// 태그를 localStorage 키·대시보드 키로 쓸 때의 직렬 표현.
/// 예: "concept:basics", "tricky:fold-arg-order"
pub fn tag_key(tag: Tag) -> String {
  case tag {
    Concept(slug) -> "concept:" <> slug
    Tricky(slug) -> "tricky:" <> slug
    Theory(slug) -> "theory:" <> slug
  }
}

// ── 퍼즐 타입 × 채점 (PLAN.md §4.1 — 8타입 × 6채점) ──────────────

/// P1~P8. 레슨 마이크로 연습도 동일 레지스트리를 쓴다(레슨은 주로 P1~P5).
pub type PuzzleType {
  /// P1 predict — 출력/값 예측
  Predict
  /// P2 mcq — 객관식
  Mcq
  /// P3 fill_hole — todo 구멍 채우기
  FillHole
  /// P4 fix_error — 컴파일 실패 코드 수정 (starter는 컴파일 실패가 필수)
  FixError
  /// P5 write_fn — 테스트 대상 함수 작성
  WriteFn
  /// P6 refactor — 동작 보존 리팩터링 (테스트 + 구조 린트)
  Refactor
  /// P7 parsons — 줄 순서 재배열
  Parsons
  /// P8 spot_bug — 버그 스팬 지목(1단계) 후 수정(2단계)
  SpotBug
}

/// 채점 방식 6종. 타입별 허용 조합은 §4.1 표가 강제하며
/// 콘텐츠 빌드(CI)가 검증한다 — 런타임 디스패치는 engine/grading.
pub type Grading {
  /// 선택지 인덱스 비교
  Choice
  /// 실행 stdout을 answer 스냅샷과 정확 비교
  ExactOutput
  /// 히든 테스트 컴파일·실행, per-test 판정
  Tests
  /// Tests + 구조 린트 (예: `|>` 3회 이상)
  TestsLint
  /// 조립 → 컴파일 → 테스트 (순서만 채점, 인덴트는 저작분 유지)
  ParsonsOrder
  /// 1단계 스팬 클릭 → 2단계 수정 테스트
  SpotTwoStage
}

// ── 시도와 결과 (PLAN.md §5.4) ────────────────────────────────────

pub type Outcome {
  Passed
  Failed(reason: String)
  /// watchdog 타임아웃 — 오답 처리 (꼬리 재귀 무한 루프 경로)
  TimedOut
  /// '정답 보기' — SRS L1 리셋 트리거
  GaveUp
  /// 인프라 크래시 — 컴파일러 워커 panic·안전망 watchdog(30s) 등 유저 코드
  /// 문제가 아닌 실패 (engine/compiler.CompileCrashed). 채점되지 않는
  /// 비-스코어링 결과: "다시 시도" UI를 띄우고 rated 시도로 기록하지 않으며
  /// (Attempt append 금지) 레이팅·SRS를 건드리지 않는다. PLAN §5.2.
  /// 주의: 이 경로는 Win/Loss 어디에도 매핑되지 않는다 — record_rated 호출 금지.
  Crashed(message: String)
}

/// append-only 시도 로그의 1행. id는 uuid — M3 서버 병합 키.
pub type Attempt {
  Attempt(
    id: String,
    puzzle_id: String,
    variant: String,
    at_ms: Int,
    outcome: Outcome,
    duration_ms: Int,
    hints_used: Int,
    /// 첫 무힌트 시도만 True (lichess 의미론). 재도전·SRS·Rush·Streak·데일리 = False.
    rated: Bool,
    rating_before: Float,
    rating_after: Float,
    /// 컴파일 에러 제목 카테고리 (예: "Inexhaustive patterns")
    error_category: Option(String),
  )
}

// ── 힌트 (PLAN.md §4.5 — 3단계, H1부터 unrated) ──────────────────

pub type HintLevel {
  /// 개념 환기
  H1
  /// 스팬 지목
  H2
  /// 정답 + 해설 (SRS L1 리셋)
  H3
}

// ── 소스 위치 ─────────────────────────────────────────────────────

/// 에러 스팬·H2 힌트·P8 버그 위치가 공유하는 좌표 (1-기반).
pub type Span {
  Span(line: Int, column: Int)
}

// ── 제출물 (UI → 채점) ───────────────────────────────────────────

pub type Submission {
  /// P1(선택지형)/P2 — 선택지 인덱스 (0-기반)
  ChoiceAnswer(index: Int)
  /// P1(자유입력형) — 예측한 출력 문자열
  OutputAnswer(text: String)
  /// P3/P4/P5/P6, P8 2단계 — 에디터 전체 소스
  CodeSubmission(source: String)
  /// P7 — 제시된 줄 id의 배치 순서
  ParsonsArrangement(line_ids: List(Int))
  /// P8 1단계 — 버그 줄 클릭
  SpanSelection(line: Int)
}
