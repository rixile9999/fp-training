//// 콘텐츠 JSON 청크 fetch (PLAN §5.3 ③ — 단위별 lazy-load).
////
//// 전체 콘텐츠를 한 덩어리로 싣지 않는다: 매니페스트 → 해제된 유닛 청크 →
//// 출제 시점의 패밀리 청크 순으로 필요할 때만 가져온다. 구현은 rsvp의
//// HTTP fetch를 lustre `effect.Effect`로 감싸고, 응답 본문을
//// `fpdojo/content/schema`의 디코더로 해석한다. Service Worker가 앱 셸과
//// 해제된 유닛 청크를 캐시하므로 오프라인에서도 동일 경로로 동작한다
//// (PLAN §5.4 오프라인/PWA).
////
//// URL 규약(제안): 정적 서빙 루트 아래 `/content/manifest.json`,
//// `/content/units/<unit_id>.json`, `/content/families/<family_id>.json`
//// — `tools/build-content.mjs`의 산출 경로(priv/static/content/)와 1:1.
////
//// 의존 방향: `content/schema`(와 그 아래 registry/types)만 import.
//// ui/app이 이 모듈의 Effect를 구독한다 — 역방향 금지.

import fpdojo/content/schema
import lustre/effect

/// 로드 실패 분류. 호출자(ui)는 이 값으로 재시도/안내 UI를 분기한다.
/// - `NetworkError`: fetch 자체 실패(오프라인·CSP 차단 등) — 메시지 보존
/// - `DecodeError`: 응답은 왔지만 schema 디코더 실패 — content_version
///   불일치(구버전 캐시) 신호일 수 있음
/// - `NotFound`: HTTP 404 — 잘못된 id 또는 은퇴(tombstone)된 콘텐츠
pub type LoadError {
  NetworkError(String)
  DecodeError(String)
  NotFound(String)
}

/// 매니페스트 로드 — 앱 기동 직후 1회. 성공 시 콘텐츠 버전 비교
/// (프로필 `content_version` ↔ 매니페스트)와 유닛 잠금 계산의 입력이 된다.
/// `on`: 결과를 앱 Msg로 감싸는 콜백 (Lustre 관례).
pub fn load_manifest(
  on: fn(Result(schema.Manifest, LoadError)) -> msg,
) -> effect.Effect(msg) {
  todo as "rsvp로 /content/manifest.json을 fetch해 manifest_decoder로 디코드하는 Effect 구성"
}

/// 유닛 청크 로드 — 유닛 진입(또는 SW 프리캐시) 시점에 lazy-load.
/// `id`: UnitMeta.id (예: "u01-values").
pub fn load_unit(
  id: String,
  on: fn(Result(schema.Unit, LoadError)) -> msg,
) -> effect.Effect(msg) {
  todo as "rsvp로 /content/units/<id>.json을 fetch해 unit_decoder로 디코드하는 Effect 구성"
}

/// 퍼즐 패밀리 청크 로드 — 트레이닝 출제·SRS 리뷰 직전에 lazy-load.
/// `id`: PuzzleFamily.id (예: "fold-arg-order-predict-01").
pub fn load_family(
  id: String,
  on: fn(Result(schema.PuzzleFamily, LoadError)) -> msg,
) -> effect.Effect(msg) {
  todo as "rsvp로 /content/families/<id>.json을 fetch해 family_decoder로 디코드하는 Effect 구성"
}
