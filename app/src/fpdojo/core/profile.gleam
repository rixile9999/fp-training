//// 유저 상태의 단일 루트 (PLAN.md §5.4).
////
//// localStorage 키 `fpdojo.v1.profile`로 통째로 직렬화되는 애그리거트 —
//// 직렬화 자체는 storage/local 소관이고, 이 모듈은 순수 도메인 갱신만
//// 담당한다. 시도 로그(`fpdojo.v1.attempts`, append-only 2,000건 컴팩션)는
//// Profile에 포함되지 않는다 — 호출자가 storage/local.append_attempt로
//// 별도 적재.
////
//// 의존 방향: core/types, core/rating, core/srs, core/progress를 사용
//// (의존 그래프상 core/* 의 최하단). 위로는 session/*, storage/local,
//// ui/*가 사용한다.
////
//// M3 마이그레이션(PLAN §5.4): attempts uuid union 업로드 → 서버
//// 리플레이로 파생 상태(이 Profile) 재계산 — 그래서 여기의 갱신 함수는
//// 순수해야 리플레이가 가능하다.

import fpdojo/core/progress
import fpdojo/core/rating
import fpdojo/core/srs
import fpdojo/core/types
import gleam/dict

/// 유저 설정.
/// - `locale`: "ko" 우선, 미번역 시 graceful fallback (PLAN §4.5).
/// - `reduced_motion`: `prefers-reduced-motion` 존중 (PLAN §5.4 접근성).
/// - `timed_multiplier`: 타임드 모드 시간 배수 — 기본 1.0, 접근성 옵션
///   1.5× 제공 (PLAN §5.4).
pub type Settings {
  Settings(locale: String, reduced_motion: Bool, timed_multiplier: Float)
}

/// 유저 상태 루트 (PLAN §5.4 localStorage 스키마와 1:1).
///
/// - `content_version`: 마지막으로 본 콘텐츠 번들 버전 — 콘텐츠 릴리스의
///   마이그레이션 맵(제거/대체 ID) 적용 비교 기준 (PLAN §5.3).
/// - `overall`: 글로벌 Glicko-2 — 퍼즐과 점수를 주고받는 유일한 rated
///   레이팅 (PLAN §4.2).
/// - `by_theme`: 테마 서브 레이팅(파생값). 키 = types.tag_key
///   (예: "tricky:fold-arg-order"). 시도 10회 미만 테마의 "측정 중"
///   표시는 UI 책임.
/// - `units`: 유닛별 진행. 키 = unit id.
/// - `learned_tags`: 레슨이 연 태그 — 트레이닝 풀 필터 (PLAN §2:
///   학습 전 테마 퍼즐은 서빙 안 함). True=학습됨, False=잠정 학습됨
///   (유닛 건너뛰기·배치 선해제 경로).
/// - `srs`: SRS 카드. 키 = family_id.
pub type Profile {
  Profile(
    user_id: String,
    content_version: String,
    overall: rating.Rating,
    by_theme: dict.Dict(String, rating.Rating),
    units: dict.Dict(String, progress.UnitProgress),
    learned_tags: dict.Dict(String, Bool),
    srs: dict.Dict(String, srs.SrsCard),
    settings: Settings,
  )
}

/// 신규 프로필: 글로벌 1500/350/0.06(rating.new_user), 나머지 전부 빈
/// 상태. `content_version`은 ""로 시작해 첫 manifest 로드 시 채워진다.
/// 배치 테스트 경로는 생성 후 overall을 rating.placement_seed로 교체하고
/// 선해제 유닛 태그를 learned_tags에 잠정(False) 마킹한다 (PLAN §2).
pub fn new(user_id: String) -> Profile {
  Profile(
    user_id: user_id,
    content_version: "",
    overall: rating.new_user(),
    by_theme: dict.new(),
    units: dict.new(),
    learned_tags: dict.new(),
    srs: dict.new(),
    settings: Settings(
      locale: "ko",
      reduced_motion: False,
      timed_multiplier: 1.0,
    ),
  )
}

/// rated 시도 1건 반영 (PLAN §4.2). 호출 전제: `attempt.rated == True`
/// (첫 무힌트 시도만 — 재도전·SRS·Rush·Streak·데일리는 호출 금지).
/// 또한 `attempt.outcome`은 `Crashed`가 아니어야 한다 — 인프라 크래시는
/// 비채점이므로 호출자(session)가 record_rated·append_attempt 둘 다 건너뛴다.
///
/// 계약:
/// - attempt.outcome을 GameResult로 매핑: Passed=Win, Failed/TimedOut/GaveUp
///   =Loss. `Crashed`는 도달 금지(위 전제) — 도달 시 프로필 무변경 반환.
///   다단계(P8)는 전 단계 첫 통과 시 승리 — 그 판정은 호출자(session)가
///   outcome에 이미 반영했다고 본다.
/// - overall: rating.rate_attempt(user, puzzle_rating, result)로 갱신.
///   반환된 퍼즐 쪽 갱신값은 M1~M2에서 폐기(시드 고정, PLAN §4.2).
/// - 테마 서브: `themes`(주+부 태그)마다 by_theme[tag_key]를 floor 60으로
///   같은 결과로 병렬 갱신 — 없는 테마는 갱신 전 overall에서
///   rating.new_theme로 분기. 퍼즐 레이팅에는 비반영(더블카운팅 방지).
/// - Attempt 자체는 호출자가 storage/local.append_attempt로 별도 append.
pub fn record_rated(
  profile: Profile,
  attempt: types.Attempt,
  puzzle_rating: rating.Rating,
  themes: List(types.Tag),
) -> Profile {
  todo as "outcome을 Win/Loss로 매핑해 overall은 rate_attempt로, 각 테마 서브는 floor 60 update로(없으면 new_theme 분기) 병렬 갱신한다"
}
