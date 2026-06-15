//// 콘텐츠 도메인 모델 + JSON 디코더 (PLAN §5.3, §3.2, §4.1).
////
//// 저작은 TOML(`content/` 트리) → `tools/build-content.mjs`가 단위별 JSON
//// 청크로 빌드(prose 사전 렌더 포함, PLAN §5.3 ③) → 앱은 이 모듈의
//// `gleam/dynamic/decode` 디코더로 JSON만 읽는다. TOML 파싱은 런타임에 없다.
//// 스키마 위반·태그 오용·타입×채점 매트릭스 위반은 전부 CI 골든(§5.3 ①~②)이
//// 빌드 시점에 걸러내므로, 런타임은 디코드 성공 = 신뢰 가능한 콘텐츠로 본다.
////
//// 의존 방향: `fpdojo/core/types`, `fpdojo/content/registry`만 import한다.
//// `content/loader`, `engine/grading`, `session/*`, `ui/*`가 이 모듈을
//// 내려다본다 — 역방향 import 금지.

import fpdojo/content/registry
import fpdojo/core/types
import gleam/dict
import gleam/dynamic/decode
import gleam/option

// ── 매니페스트 ────────────────────────────────────────────────────

/// 콘텐츠 릴리스 1개의 루트 메타. 앱 기동 시 가장 먼저 로드한다.
/// `content_version`은 프로필의 `content_version`과 비교해 마이그레이션 맵
/// 적용 여부를 판단하는 키 (PLAN §5.3 콘텐츠/ID 라이프사이클).
/// `compiler_version`은 핀 고정된 WASM 컴파일러 버전("1.17.0") —
/// 컴파일러 핀 bump는 콘텐츠 릴리스로만 수행한다 (PLAN §5.3 ④).
pub type Manifest {
  Manifest(
    content_version: String,
    compiler_version: String,
    units: List(UnitMeta),
    tags: registry.TagRegistry,
  )
}

/// 유닛 1개의 가벼운 메타 (본문은 `Unit` 청크를 lazy-load).
/// `prerequisites`는 유닛 id 목록 — 선수 그래프 무사이클은 CI 검증(§5.3 ①).
/// `level`은 1~4 (PLAN §3.1), `order`는 레벨 내 표시 순서.
/// `concepts`는 이 유닛이 다루는 개념 태그(잠금/대시보드 표시용).
pub type UnitMeta {
  UnitMeta(
    id: String,
    title: String,
    order: Int,
    level: Int,
    concepts: List(types.Tag),
    prerequisites: List(String),
    lesson_ids: List(String),
  )
}

// ── 유닛 / 레슨 (PLAN §3.2) ──────────────────────────────────────

/// 유닛 JSON 청크 1개의 전체 내용: 메타 + 레슨들 + 체크포인트.
pub type Unit {
  Unit(meta: UnitMeta, lessons: List(Lesson), checkpoint: Checkpoint)
}

/// 레슨 = 설명 세그먼트 3~5개 × 마이크로 연습 5~10개 교차 (PLAN §3.2).
/// `emits_tags`: 레슨 완료 시 프로필 `learned_tags`에서 "학습됨"으로 전환되는
/// 태그 — 트레이닝 풀 편입 트리거 (PLAN §2 맞물림 규칙).
/// `srs_items`: 완료 시 SRS에 등록되는 핵심 패밀리 id 2~4개 (PLAN §4.4 —
/// 카드 단위 = family_id).
pub type Lesson {
  Lesson(
    id: String,
    unit_id: String,
    title: String,
    emits_tags: List(types.Tag),
    srs_items: List(String),
    blocks: List(LessonBlock),
  )
}

/// 레슨 본문의 한 블록. 순서는 저작된 그대로(설명↔연습 교차).
pub type LessonBlock {
  /// 설명 세그먼트 (각 ≤90초 분량). `segment_id`는 안정적 anchor —
  /// 체크포인트 실패 문항의 `lesson#segment` 역링크 대상 (PLAN §3.2).
  /// `markdown`은 빌드가 사전 렌더한 본문.
  Prose(segment_id: String, markdown: String)
  /// 마이크로 연습 1개.
  Exercise(step: Step)
}

/// 레슨 마이크로 연습 — 퍼즐 패밀리보다 단순(변형·레이팅 없음).
/// 타입은 P1~P5만 사용한다 (PLAN §3.2, §4.1 — 레슨도 동일 레지스트리).
/// `answer`: grading이 Choice면 0-기반 정답 인덱스 문자열("1"),
/// ExactOutput이면 골든이 실행으로 고정한 출력 스냅샷,
/// Tests 계열(P3~P5)에선 None.
/// `test_code`: Tests 계열 채점에서 주입되는 runner_test 소스 (PLAN §5.2
/// 하니스 프로토콜) — 무컴파일 채점(Choice/ExactOutput)에선 None.
/// `starter`: 에디터 초기 코드 또는 predict가 보여줄 코드.
pub type Step {
  Step(
    id: String,
    puzzle_type: types.PuzzleType,
    grading: types.Grading,
    prompt_md: String,
    starter: String,
    choices: List(String),
    answer: option.Option(String),
    test_code: option.Option(String),
    feedback: FeedbackMap,
    tags: List(types.Tag),
  )
}

/// Step → Variant 어댑터. engine/grading.grade는 Variant만 받으므로
/// (채점 진입점 단일화), 레슨 마이크로 연습도 이 변환을 거쳐 동일 경로로
/// 채점한다. solutions/parsons_lines/bug_span 등 Step에 없는 필드는 빈 값.
pub fn step_to_variant(step: Step) -> Variant {
  todo as "Step 필드를 Variant로 매핑 (id/prompt/starter/choices/answer/test_code→runner_test, 나머지 빈 값)"
}

/// 유닛 체크포인트 — 콘텐츠 스키마의 1급 엔티티 (PLAN §3.2, §5.4).
/// 유닛 태그 혼합 10문항, `pass_threshold`(=8) 이상 통과 시 합격.
pub type Checkpoint {
  Checkpoint(unit_id: String, items: List(CheckpointItem), pass_threshold: Int)
}

/// 체크포인트 문항. `backlink`는 실패 시 되돌아갈 딥링크 —
/// `"lesson#segment"` 형식 (PLAN §3.2의 `unit/lesson#segment_id` 역링크).
pub type CheckpointItem {
  CheckpointItem(step: Step, backlink: String)
}

// ── 퍼즐 패밀리 (PLAN §4.1, §4.4, §5.3) ──────────────────────────

/// 트레이닝/SRS의 출제 단위. `id`(family_id)가 SRS 카드 키이며 불변·재사용
/// 금지 (PLAN §5.3 ID 라이프사이클). `srs_label`은 대시보드 그룹핑 라벨로
/// 격하된 마이크로 스킬 문자열(카드 키 아님 — PLAN §4.4).
/// `seed_tier`: 1~9 → 시드 레이팅 800..2600, RD 350 (PLAN §4.2).
/// `rush/streak_eligible`: 타임드 적합성 — Rush 풀 = P1(선택지형)/P2/P3(한 줄)/
/// P7(4~6줄)/P8(1단계), Streak = Rush 풀 + P4 + P8(2단계), P5·P6은 둘 다 제외
/// (PLAN §4.3 확정). `mobile_friendly`: P1/P2/P7/P8-1단계 = O (PLAN §5.4).
/// `timeout_ms`: 러너 watchdog — 기본 3000, write_fn 상한 5000 (PLAN §5.2).
/// `compiler_version`: 이 패밀리의 골든이 고정된 핀 버전.
pub type PuzzleFamily {
  PuzzleFamily(
    id: String,
    puzzle_type: types.PuzzleType,
    grading: types.Grading,
    primary_theme: types.Tag,
    themes: List(types.Tag),
    srs_label: String,
    seed_tier: Int,
    timeout_ms: Int,
    srs_eligible: Bool,
    rush_eligible: Bool,
    streak_eligible: Bool,
    mobile_friendly: Bool,
    compiler_version: String,
    variants: List(Variant),
    hints: HintSet,
    explanation_md: String,
  )
}

/// 패밀리 내 파라미터 변형 1개 (3~5개 보유, 회전 출제로 암기 방지 —
/// PLAN §4.4). 채점 방식에 따라 쓰는 필드가 다르다:
/// - `solutions`: 모범 답안 복수 허용 (PLAN §5.3 `solution*.gleam`)
/// - `runner_test`: Tests 계열의 히든 테스트(하니스 자동 주입, PLAN §5.2)
/// - `choices`/`answer`: predict 선택지형·mcq용 — answer는 골든이 고정
/// - `parsons_lines`: P7 — 저자가 인덴트 포함 저작, 채점은 순서만 (PLAN §4.1)
/// - `bug_span`: P8 1단계 정답 위치
pub type Variant {
  Variant(
    id: String,
    prompt_md: String,
    starter: String,
    solutions: List(String),
    runner_test: option.Option(String),
    choices: List(String),
    answer: option.Option(String),
    parsons_lines: List(String),
    bug_span: option.Option(types.Span),
    feedback: FeedbackMap,
  )
}

/// 3단계 힌트 (PLAN §4.5): H1 개념 환기 → H2 스팬 지목 → H3 정답+해설.
/// H1부터 unrated, H3는 SRS L1 리셋 트리거. 저작 원천은 `hints.ko.md`
/// (`---` 구분 3단: H1 텍스트 / H2 스팬 JSON / H3 해설 — PLAN §5.3).
pub type HintSet {
  HintSet(recall_md: String, span: option.Option(types.Span), reveal_md: String)
}

/// 오답 패턴 키 → 사전 저작된 진단 문장 (PLAN §3.2, §4.5).
/// distractor 인덱스는 `"choice:0"` 형식 키(0-기반). engine/grading이
/// `GradeReport.feedback_key`로 이 맵을 조회한다.
pub type FeedbackMap {
  FeedbackMap(entries: dict.Dict(String, String))
}

// ── JSON 디코더 (gleam/dynamic/decode) ───────────────────────────

/// `priv/static/content/manifest.json` 디코더. 태그 레지스트리 청크는
/// `registry.registry_decoder`에 위임한다.
pub fn manifest_decoder() -> decode.Decoder(Manifest) {
  todo as "manifest.json 청크를 Manifest로 디코드 (units 메타 + 태그 레지스트리 포함)"
}

/// 유닛 청크(`units/<unit_id>.json`) 디코더 — 레슨 블록 직조 결과와
/// 체크포인트까지 한 청크에 들어 있다.
pub fn unit_decoder() -> decode.Decoder(Unit) {
  todo as "유닛 JSON 청크를 Unit(메타+레슨들+체크포인트)으로 디코드"
}

/// 퍼즐 패밀리 청크(`families/<family_id>.json`) 디코더.
/// puzzle_type/grading 문자열 enum → types 변환과 타입별 허용 조합(§4.1 표)
/// 위반 검출은 빌드 책임이므로 여기서는 형태만 디코드한다.
pub fn family_decoder() -> decode.Decoder(PuzzleFamily) {
  todo as "패밀리 JSON 청크를 PuzzleFamily(변형·힌트·해설 포함)로 디코드"
}
