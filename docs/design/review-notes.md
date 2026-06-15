# Stub-단계 인터페이스 리뷰 결과 (2026-06-13)

4차원 어드버서리얼 리뷰(coverage/consistency/contract/content) → 발견을 적대적
검증(진짜 문제인가 / 본구현으로 미룰 수 있는가) → 반영. 이 문서는 무엇이
고쳐졌고 무엇이 의도적으로 본구현으로 미뤄졌는지의 기록이다.

## 반영 완료 — must_fix (5)

1. **placement-test-runner** — 배치 테스트(PLAN §2)를 구동할 인터페이스가 없었음.
   → `session/placement.gleam` 신설(순수 상태머신). 밴드→유닛/태그 매핑은
   호스트가 manifest에서 도출(level_gate 패턴). `progress.seed_unit` 추가.
2. **checkpoint-session** — `UnitProgress.checkpoint_passed`의 생산자가 없었음
   (게이트의 핵심 입력, M1 DoD). → `session/checkpoint.gleam` 신설.
3. **rated-flag-no-owner** — 플랫폼 중심 프리미티브인 `rated` 판정의 주체가 없었음
   (Mixed/ThemeDrill엔 세션 타입조차 없었음). → `training.AttemptSession` +
   `AttemptEvent`/`AttemptCmd`(PersistAttempt) + 순수 `is_rated` 규칙 추가.
4. **grade-init-and-crash-mapping** — 인프라 크래시(컴파일러 워커 panic·watchdog)를
   표현할 outcome이 없어 rated 시도가 인프라 장애로 레이팅을 잃을 수 있었음.
   → `types.Outcome`에 `Crashed(message)` + `grading.InfraCrashDetail` 추가,
   grade의 outcome 매핑·init 시퀀싱(멱등 lazy-init) 문서화, record_rated 계약 갱신.
5. **predict-variant-no-runnable-module** — 골든이 실행할 predict 입력 아티팩트
   컨벤션이 없었음(~250 패밀리가 이 공백 위에 저작될 뻔). → predict는
   `variants/<id>/starter.gleam`이 실행 가능한 완전 모듈(보여주는 코드=실행하는
   코드 단일 출처). build-content ③-5/③-6, verify ②-4에 규칙·후행 개행 trim 문서화.
   데모 변형에 실제 starter.gleam 채움.

## 반영 완료 — worth_noting (cheap)

- **editor-set-error-markers-no-external** — `set_error_markers`를 editor_ffi에
  직접 `@external` 위임으로 와이어링(todo 제거).
- **interfaces-view-signature-mismatch** — interfaces.md를 실제 stub(인자 없는
  `view()` 자리표시자)에 맞추고 본구현 확장 경로(`view(vm)`) 명시.
- **answer-txt-trailing-newline-trim** — build-content ③-6에 양쪽 후행 \n trim 규칙 문서화.
- **plan-fieldname-drift** — PLAN §5.3 디렉토리 주석의 `seed_rating`/`srs_item`을
  schema의 canonical `seed_tier`/`srs_label`로 정정.

## 본구현으로 미룸 — worth_noting (인터페이스 영향 없음)

- **daily-explanation-gating** (PLAN §4.3) — `daily_key`는 있으나 "해설 잠금 해제
  여부" 판정 함수 부재. 본구현에서 `fn explanation_unlocked(date_key, now_ms) -> Bool`
  추가 — 순수 비교라 인터페이스 재작업 없음.
- **unit-skip-and-cap-enforcement** (PLAN §2/§3.1) — 데이터 모델(seed_unit,
  learned_tags False, new_lessons_today)은 충분. 건너뛰기 확인·캡 집행은
  ui/app의 오케스트레이션 로직 — 본구현 시 배선.
- **pwa-sw-badge** (PLAN §4.4/§5.4) — Service Worker 파일·복귀 배지 미작성.
  PLAN상 M2(PWA)/M3(알림) 항목이라 일정상 정상.
- **review-build-due-badge-source** — `review.build`의 `served_today`는 호스트가
  attempt 로그(unrated 포함)에서 집계. 본구현 시 집계 헬퍼 위치만 정하면 됨.
- **lesson-revealed-no-srs-shrink-cmd** (PLAN §3.2) — `RegisterSrs(family_ids)`가
  '정답 보기'한 스텝 정보를 SRS 인터벌 축소로 전달하지 않음. 본구현에서
  `RegisterSrs`에 축소 대상 family를 동봉하거나 별도 cmd로 분리 검토.

## 검증에서 기각된 발견 (false alarm)

- **rated-attempt-state-machine** (중복) — must_fix #3로 흡수됨.
- **record-rated-hides-new-rating** — record_rated 계약은 순환이 아님(입력은
  attempt+puzzle_rating, 출력은 갱신된 Profile). 사실 오인.
- **variant-starter-missing-vs-nonoptional** — `Variant.starter: String`(비옵션)은
  의도된 설계. predict는 #5에서 starter.gleam 컨벤션으로 해소.
