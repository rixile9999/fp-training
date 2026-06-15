#!/usr/bin/env node
/**
 * tools/scaffold.mjs — 레슨/퍼즐 템플릿 생성 CLI (PLAN §5.3 저작 도구, §8-③).
 *
 * 1인 저작 비용 모델(레슨 ≈ 4h, 퍼즐 패밀리 ≈ 45분 + 변형당 15분 — PLAN §5.3)을
 * 지키기 위해 보일러플레이트를 기계가 만든다. 생성물은 content/ 디렉토리 계약
 * (PLAN §5.3 트리)과 fpdojo/content/schema 필드에 1:1 정합해야 하며,
 * 생성 직후 build-content 검증을 통과하는 "빈 칸 채우기" 상태여야 한다.
 *
 * 사용법(계획):
 *   node tools/scaffold.mjs lesson <unit-id> <lesson-id>
 *   node tools/scaffold.mjs puzzle <family-id> --type predict --theme tricky:fold-arg-order
 *   node tools/scaffold.mjs checkpoint <unit-id>
 */

import { argv, exit } from 'node:process';

/**
 * 레슨 템플릿 생성.
 *
 * TODO ㉮-1: content/units/<unit>/lessons/<lesson>/{lesson.toml, prose.ko.md,
 *           steps/s01/{step.toml, feedback.ko.toml, starter.gleam}} 생성 —
 *           세그먼트 마커(`<!-- segment: ... -->`)와 blocks 직조 예시 포함.
 * TODO ㉮-2: lesson.toml 의 emits_tags/srs_items 자리에 레지스트리 후보 주석 제공
 *           (신규 개념은 레슨당 정확히 1개 — PLAN §3.2 원칙을 템플릿 주석으로 강제).
 *
 * @param {string} unitId
 * @param {string} lessonId
 * @param {{contentRoot: string}} opts
 * @returns {Promise<string[]>} 생성된 파일 경로 목록
 */
export async function scaffoldLesson(unitId, lessonId, opts) {
  throw new Error('TODO');
}

/**
 * 퍼즐 패밀리 템플릿 생성.
 *
 * TODO ㉯-1: content/puzzles/<family_id>/{family.toml, variants/v1/,
 *           hints.ko.md(3단 구분자 포함), feedback.ko.toml, explanation.ko.md} 생성.
 * TODO ㉯-2: --type 별 변형 파일 분기 — predict: prompt.md+answer.txt /
 *           tests 계열: starter.gleam+solution.gleam+runner_test.gleam /
 *           parsons: 줄 목록 / spot_bug: bug_span 자리.
 * TODO ㉯-3: 타입×채점 매트릭스(PLAN §4.1)와 타임드 적합성 플래그 기본값을
 *           타입에 맞게 자동 기입 (예: P5 생성 시 rush/streak_eligible=false).
 * TODO ㉯-4: --theme 인자를 tags.toml 에 즉시 대조 — 미등록이면 생성 거부.
 *
 * @param {string} familyId
 * @param {{type: string, theme: string, contentRoot: string}} opts
 * @returns {Promise<string[]>} 생성된 파일 경로 목록
 */
export async function scaffoldPuzzle(familyId, opts) {
  throw new Error('TODO');
}

/**
 * 유닛 체크포인트 템플릿 생성 (문항 10개 골격 + pass_threshold=8 — PLAN §3.2).
 *
 * TODO ㉰-1: 유닛의 기존 레슨 세그먼트 id 를 스캔해 backlink 후보 주석 제공.
 *
 * @param {string} unitId
 * @param {{contentRoot: string}} opts
 * @returns {Promise<string[]>}
 */
export async function scaffoldCheckpoint(unitId, opts) {
  throw new Error('TODO');
}

/**
 * 변이 생성기 훅 (M2 — PLAN §5.3 저작 도구, training-system.md 생성기 절).
 *
 * TODO ㉱-1: 검증된 정상 코드에 (a) 버그 1개 주입(인자 순서 교환, variant 누락,
 *           base case 변경, `+`→`+.` 교체), (b) 홀 1개 굴착, (c) 줄 셔플 →
 *           변형 후보 생성. CI 가 "의도된 수정이 유일하게 통과"인지 확인,
 *           사람은 선별·티어 부여만 (R1 완화).
 *
 * @param {string} familyDir
 * @param {{kind: 'bug'|'hole'|'shuffle'}} opts
 * @returns {Promise<string[]>} 생성된 변형 디렉토리 목록
 */
export async function generateVariants(familyDir, opts) {
  throw new Error('TODO');
}

/**
 * 엔트리 포인트 — 서브커맨드(lesson|puzzle|checkpoint|variants) 디스패치.
 *
 * @param {string[]} args
 * @returns {Promise<number>} exit code
 */
export async function main(args) {
  throw new Error('TODO');
}

main(argv.slice(2)).then(exit);
