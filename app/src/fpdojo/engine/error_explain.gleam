//// 에러 번역 사전 — 컴파일 에러 2단 표시의 2면 (PLAN §4.5).
////
//// 1면은 컴파일러 pretty 출력 원문 보존(에러 독해가 곧 커리큘럼)이고,
//// 이 모듈은 2면을 만든다: `error: <제목>` 카테고리 × 퍼즐 테마 × 로케일로
//// 저작된 한국어 해설을 찾는다. 미번역이면 None — 컴파일러 원문만 표시하는
//// graceful fallback(i18n 갭 해소, ko 우선).
////
//// 평문 파싱 주의(R3): pretty 포맷은 안정 보장이 없다 — category/extract_spans
//// 정규식은 대표 에러 코퍼스 골든 테스트로 보호하고, 깨지면 그때
//// compiler-wasm 포크(read_diagnostics)로 전환한다(architecture.md §3.7).
////
//// 의존 방향: core/types, engine/runner(CrashKind)만 import.
//// engine/compiler의 CompileFailure.category/spans 추출과 동일한 텍스트 계약을
//// 공유한다(compiler는 이 모듈을 import할 수 없으므로 — 의존 그래프 상위).

import fpdojo/core/types
import fpdojo/engine/runner
import gleam/dict
import gleam/dynamic/decode
import gleam/option

/// 에러 번역 사전 — 로케일 파일(콘텐츠 빌드 산출물)에서 로드해 주입한다
/// (PLAN §4.5 "에러 번역 사전과 태그 표시명은 로케일 파일에 포함").
/// 모듈에 하드코딩하지 않는다 — i18n graceful fallback의 전제.
///
/// 키 스킴(문서화된 계약):
/// - `"<locale>:<category>"` — 카테고리 일반 해설
/// - `"<locale>:<category>|<tag_key>"` — 테마 특화 해설 (types.tag_key 형식)
/// - `"<locale>:crash:stack_overflow"` / `"<locale>:crash:other"` — 크래시 메시지
pub type Lexicon {
  Lexicon(entries: dict.Dict(String, String))
}

/// 로케일 청크(`locales/<locale>.json`)의 에러 사전 부분 디코더.
pub fn lexicon_decoder() -> decode.Decoder(Lexicon) {
  todo as "로케일 JSON의 평면 키-값 사전을 Lexicon으로 디코드"
}

/// pretty 출력 첫 부분의 `error: <제목>`에서 카테고리를 추출한다.
/// 예: "error: Type mismatch" → Some("Type mismatch"),
///     "Inexhaustive patterns" 류 제목이 Attempt.error_category로 적재된다
///     (core/types.Attempt — 약점 분석·"이 에러 유형이 처음이라면" 링크 UX).
/// error 라인이 없으면 None.
pub fn category(pretty: String) -> option.Option(String) {
  todo as "pretty 평문에서 error: 제목 라인을 찾아 카테고리 문자열로 추출"
}

/// `src/\w+\.gleam:L:C` 정규식으로 위치를 전부 추출한다 (PLAN §4.5) —
/// CodeMirror 인라인 마커용 1-기반 좌표. 매칭 없으면 빈 리스트.
pub fn extract_spans(pretty: String) -> List(types.Span) {
  todo as "src/모듈.gleam:행:열 패턴을 정규식으로 전부 찾아 Span 리스트로 변환"
}

/// (카테고리 × 퍼즐 테마 × 로케일) → 저작된 한국어 해설 (PLAN §4.5).
/// 테마가 주어지면 테마 특화 해설(예: exhaustiveness 퍼즐의 Inexhaustive
/// patterns 해설)을 우선하고, 없으면 카테고리 일반 해설로 폴백.
/// 미번역 로케일/미등록 카테고리는 None — 호출자는 원문만 표시한다.
pub fn explain(
  lexicon: Lexicon,
  category: String,
  themes: List(types.Tag),
  locale: String,
) -> option.Option(String) {
  todo as "카테고리×테마×로케일 사전에서 저작 해설을 조회하고 테마 특화를 우선"
}

/// 무한 재귀 이원 매핑 (PLAN §4.5 확정):
/// - StackOverflow(RangeError 즉시): "스택 한계 도달 — 재귀 인자가 줄어드는지
///   (종료 조건), 그리고 재귀 호출이 마지막 동작(꼬리 호출)인지 확인하세요"
/// - OtherCrash: 일반 런타임 오류 안내.
/// (Timeout 쪽 메시지 — "종료 조건을 확인하세요" — 는 RunTimedOut을 다루는
/// 호출자가 사용하며, 이 함수는 크래시 경로만 담당한다.)
pub fn crash_message(
  lexicon: Lexicon,
  kind: runner.CrashKind,
  locale: String,
) -> String {
  todo as "CrashKind별 교육 메시지를 사전에서 조회하고 미번역 시 ko로 폴백"
}
