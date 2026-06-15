// <code-editor> 커스텀 엘리먼트 skeleton (fpdojo/ui/editor FFI).
//
// TODO(CodeMirror 6): `codemirror` + `@exercism/codemirror-lang-gleam` 포크
// (assert/echo/label shorthand 하이라이트 패치, PLAN §8-⑤)가 아직 설치되지
// 않았다. 설치 후 connectedCallback의 textarea 폴백을 EditorView로 교체:
//   - EditorState.changeFilter로 read-only-ranges 구간 편집 차단 (P3 hole-only)
//   - 진단 Decoration.mark + lint gutter (setErrorMarkers)
//   - ARIA 라벨, prefers-reduced-motion 존중 (PLAN §5.4 접근성)
//   - 모바일 특수문자 툴바: |> _ -> #( 등 (PLAN §5.4)
//
// attribute 계약 (fpdojo/ui/editor.editor가 직렬화):
//   source           — 초기 소스 코드
//   read-only-ranges — JSON [[startLine, endLine], ...] (1-기반, 양끝 포함)
//   editor-id        — setErrorMarkers 상관용 식별자 (INTERFACE-ISSUE 참고)
// 이벤트 계약:
//   "change" CustomEvent — detail = 전체 소스 문자열

const TAG = "code-editor";

// editor-id → 엘리먼트. setErrorMarkers가 대상 인스턴스를 찾는 색인.
const instances = new Map();

export function register() {
  if (typeof globalThis.customElements === "undefined") return undefined;
  if (globalThis.customElements.get(TAG)) return undefined;

  class CodeEditorElement extends HTMLElement {
    connectedCallback() {
      if (this.__mounted) return;
      this.__mounted = true;

      // TODO(CodeMirror 6): 여기서 EditorView를 생성한다. 아래는 change
      // 이벤트 계약만 성립시키는 임시 textarea 폴백.
      const textarea = document.createElement("textarea");
      textarea.value = this.getAttribute("source") ?? "";
      textarea.spellcheck = false;
      textarea.autocapitalize = "off"; // PLAN §5.4 모바일: 자동대문자 off
      textarea.setAttribute("autocorrect", "off");
      textarea.addEventListener("input", () => {
        this.dispatchEvent(new CustomEvent("change", { detail: textarea.value }));
      });
      this.appendChild(textarea);

      const id = this.getAttribute("editor-id");
      if (id) instances.set(id, this);
    }

    disconnectedCallback() {
      const id = this.getAttribute("editor-id");
      if (id && instances.get(id) === this) instances.delete(id);
    }
  }

  globalThis.customElements.define(TAG, CodeEditorElement);
  return undefined;
}

// 에러 스팬({line, column}, 1-기반)을 해당 에디터에 마커로 표시.
// TODO(CodeMirror 6): Decoration.mark/lint diagnostics로 적용하고,
// 색상 단독 의존 금지 — 아이콘+텍스트 병기 (PLAN §5.4 접근성).
export function setErrorMarkers(id, spans) {
  const el = instances.get(id);
  if (!el) return undefined;
  void spans; // TODO: Gleam List(Span) 순회 → CodeMirror StateEffect 디스패치
  return undefined;
}
