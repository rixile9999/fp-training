//// CodeMirror 6 custom element 래퍼 (PLAN §5.1 에디터 결정, FFI: editor_ffi.mjs).
////
//// `@exercism/codemirror-lang-gleam` 포크(assert/echo/label shorthand 패치,
//// PLAN §8-⑤)를 `<code-editor>` 커스텀 엘리먼트로 감싸 Lustre vdom과는
//// attribute/이벤트로만 통신한다 — FFI 3접점(에디터/워커/storage) 포트
//// 격리 원칙(PLAN 리스크 R8). 레슨 본문의 비편집 코드 블록은 이 에디터를
//// 쓰지 않고 콘텐츠 빌드 시 사전 렌더된 HTML을 쓴다(PLAN §5.1).
////
//// 모바일/접근성 (PLAN §5.4): 특수문자 툴바(`|>` `_` `->` `#(` 등),
//// autocorrect/자동대문자 off, 진단 출력 ARIA 라벨, 색상 단독 의존 금지.
////
//// 의존 방향: ui/editor → core/types. (engine/error_explain이 추출한 스팬을
//// ui/app이 set_error_markers로 전달하는 구도 — 이 모듈은 engine을 모른다.)

import fpdojo/core/types
import lustre/element.{type Element}

/// `<code-editor>` 커스텀 엘리먼트를 customElements.define으로 등록.
/// 앱 부트(ui/app.main)에서 1회 호출, 이미 등록돼 있으면 no-op.
/// CodeMirror 6 본체 연결은 FFI 쪽 TODO(패키지 미설치) — 현재는 textarea 폴백.
@external(javascript, "./editor_ffi.mjs", "register")
pub fn register() -> Nil

/// 에디터 엘리먼트 생성.
///
/// - `id`: 인스턴스 식별자 — attribute `editor-id`로 직렬화되어
///   `set_error_markers`의 대상 지정에 쓰인다 (화면당 보통 1개지만
///   체크포인트·비교 화면의 복수 에디터 대비)
/// - `source`: 초기 소스(변형의 starter 코드)
/// - `read_only_ranges`: 편집 금지 (시작줄, 끝줄) 구간 목록 (1-기반, 양끝 포함)
///   — fill_hole(P3)의 hole-only 편집 제어 (step.toml `editable` 필드)
/// - `on_change`: 전체 소스 텍스트 변경 콜백 — `types.CodeSubmission`의 원천
///
/// 불변식: source/read_only_ranges는 마운트 시 1회 직렬화되는 attribute이고,
/// 이후 텍스트 상태의 진실은 커스텀 엘리먼트 내부에 있다(재렌더로 리셋 금지).
pub fn editor(
  id: String,
  source: String,
  read_only_ranges: List(#(Int, Int)),
  on_change: fn(String) -> msg,
) -> Element(msg) {
  todo as "<code-editor>에 editor-id·source·read-only 구간을 attribute로 직렬화하고 change 이벤트 detail을 on_change로 디코드"
}

/// 컴파일 에러 스팬을 CodeMirror 인라인 마커로 표시 (PLAN §4.5 —
/// `src/\w+\.gleam:L:C` 정규식 추출 결과의 시각화 단계).
/// `id`: editor()에 준 인스턴스 식별자. `spans`: 1-기반 (line, column).
/// 명령형 escape hatch — vdom 밖에서 동작하므로 Effect 안에서만 호출할 것.
/// FFI editor_ffi.setErrorMarkers(id, spans)로 직접 위임 — JS 쪽이 spans를
/// CodeMirror Decoration으로 변환(스텁: editor_ffi TODO).
@external(javascript, "./editor_ffi.mjs", "setErrorMarkers")
pub fn set_error_markers(id: String, spans: List(types.Span)) -> Nil
