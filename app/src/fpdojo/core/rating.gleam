//// Glicko-2 레이팅 — 순수 함수 도메인 모듈 (PLAN.md §4.2).
////
//// "모든 첫 무힌트 시도 = 유저 vs 퍼즐의 rated 대국"(lichess 의미론,
//// PLAN §1·§4.2)을 받치는 수학 계층. ~150줄 순수 Gleam(PLAN §5.1)으로,
//// 시간·난수·저장소에 접근하지 않는다 — 외부 값은 전부 인자로 주입된다.
////
//// 의존 방향: 다른 fpdojo 모듈을 import하지 않는다(core/types 바로 아래
//// 계층). 위로는 core/profile, session/training, ui/*가 사용한다.
////
//// 수치는 전부 PLAN §4.2 표가 canonical:
////
//// | 엔티티       | 초기 rating            | 초기 RD | σ    | RD 하한 |
//// |--------------|------------------------|---------|------|---------|
//// | 유저 글로벌  | 1500 (배치 800~1900)   | 350(배치 300) | 0.06 | 45 |
//// | 유저 테마 서브 | 글로벌에서 분기      | 250     | 0.06 | 60      |
//// | 퍼즐         | 티어 1~9 → 800..2600   | 350     | 0.06 | 75      |
////
//// 단계적 배포(PLAN §4.2): M1~M2는 백엔드 없음 — 퍼즐 레이팅은 시드
//// 고정(갱신값은 호출자가 폐기 가능), 유저 레이팅만 클라이언트에서 즉시
//// 갱신. 크로스 유저 캘리브레이션·격리·리더보드는 M3.

/// Glicko-2 세 값 묶음: rating(r), deviation(RD), volatility(σ).
/// 유저 글로벌·유저 테마 서브·퍼즐 세 엔티티가 모두 이 타입을 공유한다
/// (training-system.md §2.1 — 양쪽 모두 r/RD/σ 보유).
pub type Rating {
  Rating(value: Float, deviation: Float, volatility: Float)
}

/// rated 대국 1판의 결과. 무승부 없음 — 퍼즐은 풀거나 못 풀거나.
/// watchdog 초과·RangeError·GaveUp은 전부 Loss로 매핑된다(PLAN §4.2).
pub type GameResult {
  Win
  Loss
}

/// 콜드 스타트 유저 시드: 1500 / 350 / 0.06 (PLAN §4.2 표).
/// "처음부터" 온보딩 분기(PLAN §2)와 profile.new가 사용.
pub fn new_user() -> Rating {
  Rating(value: 1500.0, deviation: 350.0, volatility: 0.06)
}

/// 배치 테스트(무컴파일 문항 12~15개, PLAN §2) 점수 구간 → 초기 레이팅.
///
/// 계약: 결과 rating은 800.0~1900.0 구간, RD는 300.0(콜드 스타트 350보다
/// 낮춰 빠른 정착), σ는 0.06. `score_band`는 배치 채점기가 산출한 점수
/// 구간 인덱스(낮을수록 하위 구간 → 800 쪽).
pub fn placement_seed(score_band: Int) -> Rating {
  todo as "배치 점수 구간을 800~1900 레이팅으로 매핑해 RD 300, 시그마 0.06으로 시드한다"
}

/// 퍼즐 시드: 난이도 티어 1~9 → 800/1000/1200/1400/1600/1800/2000/2300/2600,
/// RD 350, σ 0.06 (PLAN §4.2 — Exercism difficulty 스케일 재사용,
/// training-system.md §2.2). 범위 밖 티어는 1..9로 클램프.
pub fn new_puzzle(tier: Int) -> Rating {
  let value = case tier {
    2 -> 1000.0
    3 -> 1200.0
    4 -> 1400.0
    5 -> 1600.0
    6 -> 1800.0
    7 -> 2000.0
    8 -> 2300.0
    t if t >= 9 -> 2600.0
    // tier <= 1 클램프
    _ -> 800.0
  }
  Rating(value: value, deviation: 350.0, volatility: 0.06)
}

/// 테마 서브 레이팅의 분기 시드: 글로벌 현재값에서 분기, RD 250, σ 0.06
/// (PLAN §4.2 표). 첫 시도 시점의 글로벌을 넣어 호출한다 — 이후 서브는
/// 같은 시도를 입력으로 병렬 계산되는 파생값(training-system.md §2.3).
pub fn new_theme(global: Rating) -> Rating {
  Rating(value: global.value, deviation: 250.0, volatility: 0.06)
}

/// Glicko-2 1대국 즉시 갱신(lichess lila식 단일 게임 근사,
/// training-system.md §2.1). E = 1/(1+10^(−g(RD_p)·(r_u−r_p)/400)),
/// 이후 Glickman 논문 절차(g → E → v → Δ → σ′ → RD′ → r′)를 그대로 구현.
///
/// 계약:
/// - `player`만 갱신되어 반환된다. `opponent`는 입력일 뿐 — 상대 갱신은
///   호출자가 인자를 뒤집어 별도 호출(rate_attempt 참조).
/// - 갱신 후 RD에 `rd_floor` 하한 적용: 유저 글로벌 45 / 테마 서브 60 /
///   퍼즐 75 (PLAN §4.2 표).
/// - 시스템 상수 τ 등 논문 내부 상수는 구현 세부 — lichess 구현 참조.
/// - 풀이 시간은 레이팅에 비반영(기록만, PLAN §4.2).
pub fn update(
  player: Rating,
  opponent: Rating,
  result: GameResult,
  rd_floor: Float,
) -> Rating {
  todo as "Glicko-2 단일 대국 갱신(g,E,v,delta,sigma',RD',r' 순서) 후 RD에 rd_floor 하한을 적용한다"
}

/// rated 대국 1회: 유저·퍼즐 동시 갱신 → #(새 유저, 새 퍼즐).
///
/// 계약:
/// - 유저는 floor 45, 퍼즐은 floor 75로 `update`를 각각 호출하며 결과는
///   서로 반대(유저 Win = 퍼즐 Loss).
/// - 테마 서브 레이팅은 여기서 다루지 않는다 — 파생값이므로 퍼즐 쪽에
///   비반영(다중 태그 더블카운팅 방지, PLAN §4.2)하고, 갱신은
///   core/profile.record_rated가 floor 60으로 병렬 수행한다.
/// - M1~M2에서는 반환된 퍼즐 레이팅을 호출자가 폐기(시드 고정)해도 된다.
pub fn rate_attempt(
  user: Rating,
  puzzle: Rating,
  result: GameResult,
) -> #(Rating, Rating) {
  todo as "update를 유저(floor 45)와 퍼즐(floor 75)에 결과를 뒤집어 각각 적용해 쌍으로 반환한다"
}

/// 난이도 5밴드 — 유저 기준 오프셋: −400 / −200 / ±150 / +200 / +400~+600
/// (PLAN §4.2, lichess 5밴드 채택). 기본값은 Normal(desirable difficulty).
pub type Band {
  MuchEasier
  Easier
  Normal
  Harder
  MuchHarder
}

/// 밴드 → 출제 레이팅 구간 #(하한, 상한).
///
/// 계약: 기준점은 해당 모드의 유저 레이팅(믹스드=글로벌, 테마 드릴=서브
/// — training-system.md §2.4). Normal은 ±150, MuchHarder는 +400~+600
/// 구간. 반환 구간은 session/training.pick_next의 풀 필터로 쓰인다.
pub fn band_range(user: Rating, band: Band) -> #(Float, Float) {
  todo as "유저 레이팅에 밴드 오프셋(-400/-200/+-150/+200/+400~+600)을 적용한 하한·상한 쌍을 만든다"
}
