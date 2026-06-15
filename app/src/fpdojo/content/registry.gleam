//// 단일 태그 레지스트리의 런타임 표상 (PLAN §3.4, §5.3).
////
//// 저작 시점의 원천은 `content/registry/tags.toml`이며, 빌드가 이를
//// manifest JSON에 임베드한다 — 앱은 `registry_decoder`로 읽기만 한다.
//// 슬러그 유효성(미등록 태그 = 빌드 실패, alias 사용 = 경고 후 거부)은
//// CI(`tools/build-content.mjs`)가 강제하므로 런타임 `validate`는
//// 방어적 2차 검사 + 저작 프리뷰(`content dev`)용이다.
////
//// 의존 방향: `fpdojo/core/types`만 import한다. `content/schema`가
//// 이 모듈을 import한다(Manifest가 TagRegistry를 품음) — 역방향 금지.

import fpdojo/core/types
import gleam/dict
import gleam/dynamic/decode

/// 태그 어휘 전체. PLAN §5.3 `tags.toml`의 세 섹션과 1:1:
/// - `concepts`: Exercism Gleam 트랙 concept 슬러그 원문 36개 (예: "basics")
/// - `tricky`: PLAN §3.4 트리키 파트 canonical 슬러그 16개 (예: "fold-arg-order")
/// - `aliases`: 구 문서 명칭 → canonical 매핑. 빌드는 alias 키를 만나면
///   "경고 후 거부"하며 canonical 명칭을 안내한다 (PLAN §5.3).
pub type TagRegistry {
  TagRegistry(
    concepts: List(String),
    tricky: List(String),
    aliases: dict.Dict(String, String),
  )
}

/// manifest JSON 안의 레지스트리 청크 디코더.
/// 기대 형태: `{"concepts": [...], "tricky": [...], "aliases": {...}}`.
pub fn registry_decoder() -> decode.Decoder(TagRegistry) {
  todo as "tags 레지스트리 JSON을 TagRegistry로 디코드하는 디코더 구성"
}

/// 태그가 레지스트리에 등록된 canonical 슬러그인지 검사한다.
/// - Concept 슬러그는 `concepts`에, Tricky 슬러그는 `tricky`에 있어야 통과.
/// - alias에 걸리면 Error로 canonical 명칭을 안내한다(저작 도구가 메시지 표시).
/// - 미등록이면 Error(설명 문자열). CI가 1차 방어이므로 런타임 히트는 버그 신호.
pub fn validate(
  registry: TagRegistry,
  tag: types.Tag,
) -> Result(types.Tag, String) {
  todo as "태그 슬러그를 concepts/tricky 목록과 alias 매핑에 대조해 canonical 여부 판정"
}

/// 태그의 로케일별 표시명 (대시보드·테마 드릴 UI용).
/// PLAN §4.5의 graceful fallback 원칙: 해당 로케일 번역이 없으면
/// 슬러그 원문을 그대로 돌려준다(절대 panic하지 않음). ko 우선 저작.
pub fn display_name(
  registry: TagRegistry,
  tag: types.Tag,
  locale: String,
) -> String {
  todo as "로케일별 태그 표시명 조회, 미번역 시 슬러그 원문 fallback"
}
