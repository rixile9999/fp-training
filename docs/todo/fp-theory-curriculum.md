# (완료) FP 이론 트랙 커리큘럼

> 원 요청: "커리큘럼에 fp theory 섹션을 추가했으면 좋겠다. 기본적인 실증언어는 마찬가지로 gleam으로 가자. 우선 fp theory 커리큘럼 문서를 작성해봐."

→ 설계 문서 작성 완료: **[`../design/fp-theory-curriculum.md`](../design/fp-theory-curriculum.md)**

요지: 실용 트랙(U1–U15)이 의도적으로 미뤄둔 이론층을 담당하는 **병렬 이론 트랙**(TL1–TL4 / TU1–TU12, 37레슨). 순수성·등식추론·평가전략(TL1) → ADT 대수·동형·커리-하워드(TL2) → 합성·모노이드·펑터·모나드(TL3, **패턴이지 타입클래스가 아님**) → 람다 계산·HKT 부재 종합(TL4). 모든 Gleam 예제는 핀 gleam 1.17.0에서 컴파일·실행 검증됨.

남은 후속(콘텐츠 repo 투입 시 — 설계 문서 §8):

- [ ] `content/registry/tags.toml`에 `[theory]` 섹션(64 슬러그) 추가 + `tools/build-content.mjs`가 `theory:` 네임스페이스 인식
- [ ] `PLAN.md` §3에 이론 트랙을 부가 트랙으로 등재, `README.md` 콘텐츠 현황 한 줄 추가
- [ ] 콘텐츠 TOML 이전 시 CI 골든으로 예제 스냅샷 고정(처치 인코딩·법칙 assert·의도적 컴파일 에러 7종)
