//// localStorage 영속화 (PLAN §5.4, FFI: local_ffi.mjs).
////
//// 키 2개로 분리 저장한다:
////   - `fpdojo.v1.profile`  — 파생/스칼라 상태 (attempts 리플레이로 재계산 가능)
////   - `fpdojo.v1.attempts` — append-only 시도 로그 (진실의 원천).
////     최근 2,000건 유지, 초과분은 테마별 집계로 컴팩션 후 절단
////     (localStorage ~5MB 한도 방어, PLAN §5.4)
////
//// M3 서버 동기화 전에는 기기 분실/브라우저 초기화가 유일한 데이터 손실
//// 경로이므로 JSON 내보내기/가져오기는 M1 필수다 (PLAN §5.4, 리스크 R6).
////
//// 의존 방향: storage/local → core/profile, core/types (interfaces.md 그래프).
//// FFI(local_ffi.mjs)는 원시 get/set/remove + 가용성 탐지만 담당하고,
//// JSON 직렬화·스키마 버전 검사·컴팩션 로직은 전부 이 모듈의 책임이다
//// (FFI 3접점 포트 격리 원칙, PLAN 리스크 R8).

import fpdojo/core/profile
import fpdojo/core/types
import gleam/option

/// localStorage 접근 실패 분류.
pub type StorageError {
  /// localStorage 미지원 또는 차단(프라이빗 모드, 샌드박스 iframe 등).
  /// UI는 "진행이 저장되지 않음" 경고와 함께 메모리 한정 모드로 안내.
  NotAvailable
  /// ~5MB 한도 초과 — 컴팩션 후 1회 재시도, 그래도 실패 시 내보내기 유도.
  QuotaExceeded
  /// 저장된 JSON 파싱/디코드 실패 — 진단용 원문 메시지 보존.
  DecodeFailed(String)
}

/// 프로필 저장 키 (네임스페이스 + 스키마 버전 고정, PLAN §5.4).
const profile_key = "fpdojo.v1.profile"

/// 시도 로그 저장 키 (append-only, PLAN §5.4).
const attempts_key = "fpdojo.v1.attempts"

/// attempts 보존 상한 — 초과분은 테마별 승/패 집계로 컴팩션 후 절단.
/// 레이팅·SRS는 profile에 물질화되어 있어 절단해도 손실 없음 (PLAN §5.4).
const max_attempts = 2000

// ── FFI 원시 함수 (local_ffi.mjs — 실구현) ──────────────────────────

/// localStorage 가용성 탐지 — NotAvailable 판별에 사용.
@external(javascript, "./local_ffi.mjs", "isAvailable")
fn is_available() -> Bool

/// 키 조회. Error(Nil) = 키 없음(가용성은 is_available로 선판별).
@external(javascript, "./local_ffi.mjs", "getItem")
fn get_item(key: String) -> Result(String, Nil)

/// 키 저장. Error 페이로드 = JS 예외 name
/// ("QuotaExceededError" → QuotaExceeded로 매핑).
@external(javascript, "./local_ffi.mjs", "setItem")
fn set_item(key: String, value: String) -> Result(Nil, String)

/// 키 삭제 (import_json의 전체 교체 경로에서 사용).
@external(javascript, "./local_ffi.mjs", "removeItem")
fn remove_item(key: String) -> Nil

// ── 공개 인터페이스 (interfaces.md "storage/local") ─────────────────

/// 프로필 로드. 키 부재는 에러가 아니라 Ok(None) — 첫 방문 신호로,
/// ui/app.init이 온보딩 분기(PLAN §2 첫 방문)의 입력으로 쓴다.
/// content_version 필드는 보존만 한다(마이그레이션 맵 적용은 호출자 몫, PLAN §5.3).
pub fn load_profile() -> Result(option.Option(profile.Profile), StorageError) {
  todo as "fpdojo.v1.profile 키를 읽어 JSON 디코드(스키마 버전 검사 포함), 부재 시 Ok(None)"
}

/// 프로필 전체 저장(스칼라 상태라 항상 통째로 덮어씀).
/// QuotaExceededError 시 QuotaExceeded 반환 — attempts와 달리 컴팩션 여지 없음.
pub fn save_profile(profile: profile.Profile) -> Result(Nil, StorageError) {
  todo as "프로필을 JSON 직렬화해 fpdojo.v1.profile 키에 저장"
}

/// 시도 1건 append (append-only 이벤트 소싱, PLAN §5.4).
/// id는 uuid — M3 서버 union 병합 키. 2,000건 초과 시 오래된 시도를
/// 테마별 집계로 컴팩션 후 절단하고 재시도한다.
pub fn append_attempt(attempt: types.Attempt) -> Result(Nil, StorageError) {
  todo as "attempts 배열을 읽어 1건 append, 2000건 초과 시 컴팩션 후 저장"
}

/// 전체 시도 로그 로드 (대시보드 약점 큐·실패 로그 재출제의 원천, PLAN §2).
/// 키 부재 = Ok([]) (아직 시도 없음).
pub fn load_attempts() -> Result(List(types.Attempt), StorageError) {
  todo as "fpdojo.v1.attempts 키를 읽어 Attempt 리스트로 디코드, 부재 시 빈 리스트"
}

/// 프로필 + 시도 로그를 단일 JSON 문서로 내보내기 — **M1 필수** (PLAN §5.4, R6).
/// M3 데이터 내보내기 엔드포인트(GDPR)가 이 포맷을 재사용한다 (PLAN §5.4).
pub fn export_json() -> Result(String, StorageError) {
  todo as "profile과 attempts 두 키를 묶어 버전 표식 포함 단일 JSON 문자열로 직렬화"
}

/// 내보낸 JSON 문서를 가져와 두 키를 원자적으로 교체.
/// 디코드 실패 시 기존 데이터를 건드리지 않는다(검증 후 쓰기).
pub fn import_json(json: String) -> Result(Nil, StorageError) {
  todo as "JSON 검증·디코드 성공 시에만 profile/attempts 키를 교체 (실패 시 기존 상태 보존)"
}
