//// 표시 언어 (display locale) — UI 전역 공유 어휘.
////
//// 콘텐츠(레슨 본문)는 한국어 seed(content/seed·seed_theory)와 영어
//// seed(content/seed_en·seed_theory_en)에 1:1 구조로 나뉘어 있고, UI 크롬
//// 문자열은 `t`로 인라인 분기한다. 이 모듈은 다른 fpdojo 모듈을 import하지
//// 않는다 — 의존 그래프의 잎.

/// 페이지 상단 토글로 전환하는 표시 언어. 기본값은 한국어(Ko).
pub type Locale {
  Ko
  En
}

/// UI 크롬 문자열의 2언어 분기. 콘텐츠가 아니라 버튼·라벨 같은 짧은 문자열용.
/// `t(locale, "목록으로", "Back to list")`.
pub fn t(locale: Locale, ko: String, en: String) -> String {
  case locale {
    Ko -> ko
    En -> en
  }
}

/// localStorage 등 직렬화용 짧은 코드.
pub fn to_code(locale: Locale) -> String {
  case locale {
    Ko -> "ko"
    En -> "en"
  }
}

/// 코드 → Locale (알 수 없으면 Ko).
pub fn from_code(code: String) -> Locale {
  case code {
    "en" -> En
    _ -> Ko
  }
}
