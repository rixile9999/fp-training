// P1 predict가 보여줄 코드 (Step.starter) — curriculum.md U1-② 연습 1 원문.
// CI 골든(PLAN §5.3 ②)이 1.17.0 WASM으로 실제 실행해 정답("11" / "1")을 고정한다.
import gleam/int
import gleam/io

pub fn main() -> Nil {
  let x = 1
  let f = fn() { x }
  let x = x + 10
  io.println(int.to_string(x))
  io.println(int.to_string(f()))
}
