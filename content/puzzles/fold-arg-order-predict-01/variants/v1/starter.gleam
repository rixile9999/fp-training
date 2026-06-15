//// predict 실행 모듈 (단일 출처) — PLAN §3.3 예시 3, §5.3 ②.
////
//// 컨벤션: predict 변형은 이 starter.gleam이 "실행 가능한 완전 모듈"이다
//// (schema.Variant.starter 의 출처). 앱은 이 코드를 학습자에게 그대로
//// 보여주고(예측 대상), CI 골든(verify.mjs ②-4)은 핀 버전 1.17.0 WASM
//// 컴파일러로 이 모듈을 컴파일·실행해 stdout을 answer.txt로 고정한다.
//// 따라서 "보여주는 코드 = 실행하는 코드"가 보장된다(드리프트 불가).
//// grading=choice이면 빌드가 answer.txt(후행 개행 trim)를 choices와 유일
//// 매칭해 정답 인덱스를 도출한다(매칭 0개/2개 이상 = 빌드 실패).

import gleam/io
import gleam/list
import gleam/string

pub fn main() {
  // fold는 왼쪽부터: 1이 먼저 acc에 prepend되고 그 위에 2, 3이 쌓인다.
  list.fold([1, 2, 3], [], fn(acc, x) { [x, ..acc] })
  |> string.inspect
  |> io.println
}
