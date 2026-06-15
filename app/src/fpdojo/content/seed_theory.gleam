//// FP 이론 트랙 임베드 콘텐츠 (docs/design/fp-theory-curriculum.md).
////
//// seed.gleam 의 자매 모듈 — 무컴파일 학습 루프(mcq/predict)용 이론 트랙.
//// 12개 이론 유닛(TU1~TU12)을 이론 레벨 TL1~TL4(= UnitMeta.level 5~8)로 묶는다.
//// 모든 예제 Gleam 코드는 핀 gleam 1.17.0 에서 컴파일·실행 검증되었다(설계 문서 §검증 노트).
//// 의존 방향: content/schema · core/types 만 import (콘텐츠는 도메인 데이터).

import fpdojo/content/schema.{
  type Lesson, type LessonBlock, type Unit, type UnitMeta, Checkpoint,
  CheckpointItem, Exercise, FeedbackMap, Lesson, Prose, Step, Unit, UnitMeta,
}
import fpdojo/core/types.{type Tag, Choice, Mcq, Predict, Theory}
import gleam/dict
import gleam/int
import gleam/list
import gleam/option

/// 이론 트랙 전체 유닛 — ui/app이 부트 시 로드한다.
pub fn theory_units() -> List(Unit) {
  [
    unit_tu01(),
    unit_tu02(),
    unit_tu03(),
    unit_tu04(),
    unit_tu05(),
    unit_tu06(),
    unit_tu07(),
    unit_tu08(),
    unit_tu09(),
    unit_tu10(),
    unit_tu11(),
    unit_tu12(),
  ]
}

/// id로 이론 레슨 1개 조회 (편의).
pub fn lesson(id: String) -> Result(Lesson, Nil) {
  theory_units()
  |> list.flat_map(fn(u) { u.lessons })
  |> list.find(fn(l) { l.id == id })
}

// ── 헬퍼 (seed.gleam 패턴 재사용) ─────────────────────────────────

fn tprose(segment_id: String, markdown: String) -> LessonBlock {
  Prose(segment_id, markdown)
}

fn tpredict(
  id: String,
  prompt: String,
  code: String,
  choices: List(String),
  answer_idx: Int,
  correct_fb: String,
  wrong_fbs: List(#(Int, String)),
) -> LessonBlock {
  texercise(id, Predict, prompt, code, choices, answer_idx, correct_fb, wrong_fbs)
}

fn tmcq(
  id: String,
  prompt: String,
  choices: List(String),
  answer_idx: Int,
  correct_fb: String,
  wrong_fbs: List(#(Int, String)),
) -> LessonBlock {
  texercise(id, Mcq, prompt, "", choices, answer_idx, correct_fb, wrong_fbs)
}

fn texercise(
  id: String,
  ptype: types.PuzzleType,
  prompt: String,
  code: String,
  choices: List(String),
  answer_idx: Int,
  correct_fb: String,
  wrong_fbs: List(#(Int, String)),
) -> LessonBlock {
  let entries =
    [#("correct", correct_fb)]
    |> list.append(
      list.map(wrong_fbs, fn(pair) {
        let #(i, text) = pair
        #("choice:" <> int.to_string(i), text)
      }),
    )
    |> dict.from_list
  Exercise(Step(
    id: id,
    puzzle_type: ptype,
    grading: Choice,
    prompt_md: prompt,
    starter: code,
    choices: choices,
    answer: option.Some(int.to_string(answer_idx)),
    test_code: option.None,
    feedback: FeedbackMap(entries: entries),
    tags: [],
  ))
}

fn tlesson(
  id: String,
  unit_id: String,
  title: String,
  emits_tags: List(Tag),
  blocks: List(LessonBlock),
) -> Lesson {
  Lesson(
    id: id,
    unit_id: unit_id,
    title: title,
    emits_tags: emits_tags,
    srs_items: [],
    blocks: blocks,
  )
}

fn tunit(meta: UnitMeta, lessons: List(Lesson)) -> Unit {
  Unit(meta: meta, lessons: lessons, checkpoint: tcheckpoint(meta.id, lessons))
}

fn tcheckpoint(unit_id: String, lessons: List(Lesson)) -> schema.Checkpoint {
  let items =
    lessons
    |> list.filter_map(fn(l) {
      case list.find(l.blocks, is_exercise) {
        Ok(Exercise(step)) ->
          Ok(CheckpointItem(step: step, backlink: l.id <> "#intro"))
        _ -> Error(Nil)
      }
    })
  Checkpoint(unit_id: unit_id, items: items, pass_threshold: 1)
}

fn is_exercise(block: LessonBlock) -> Bool {
  case block {
    Exercise(_) -> True
    _ -> False
  }
}

// ── 유닛 정의 (TU1~TU12) ──────────────────────────────────────────

// ── tu01-purity ─────────────────────────────────────────────
fn l_01_a() -> Lesson {
  tlesson(
    "tu01-purity-l01-ref-transparency",
    "tu01-purity",
    "참조 투명성 — 표현식을 값으로 치환하기",
    [Theory("purity"), Theory("referential-transparency"), Theory("determinism")],
    [
      tprose(
        "rt-intro",
        "**순수 함수**는 두 가지를 약속한다. (1) 같은 입력이면 항상 같은 출력(**결정성**), (2) 출력을 내는 것 말고 관찰 가능한 다른 일을 하지 않음(부작용 없음). 이 두 약속이 지켜지면 그 함수 호출 표현식은 **참조 투명(referentially transparent)**하다 — 즉 코드 어디서든 `double(5)`라는 표현식을 그것의 값 `10`으로 바꿔치기해도 프로그램의 의미가 변하지 않는다. 이건 단순한 정의가 아니라 **너가 머릿속에서 코드를 계산해도 되는 허가증**이다.\n\n```gleam\nimport gleam/int\nimport gleam/io\n\nfn double(x: Int) -> Int {\n  x * 2\n}\n\npub fn main() -> Nil {\n  let a = double(5) + double(5)\n  let b = 10 + 10\n  let v = double(5)\n  let c = v + v\n  io.println(int.to_string(a))\n  io.println(int.to_string(b))\n  io.println(int.to_string(c))\n}\n```\n\n세 표현식 `a`, `b`, `c`는 *서로 다르게 쓰였지만* 같은 값이다. `double(5)`를 `10`으로(또는 `v`로) 마음대로 치환할 수 있기 때문이다 — 이게 참조 투명성의 정의 그 자체.",
      ),
      tpredict(
        "rt-predict-out",
        "위 코드의 출력 세 줄은?",
        "import gleam/int\nimport gleam/io\n\nfn double(x: Int) -> Int {\n  x * 2\n}\n\npub fn main() -> Nil {\n  let a = double(5) + double(5)\n  let b = 10 + 10\n  let v = double(5)\n  let c = v + v\n  io.println(int.to_string(a))\n  io.println(int.to_string(b))\n  io.println(int.to_string(c))\n}",
        [
          "`10` / `20` / `20`",
          "`20` / `20` / `20`",
          "`20` / `20` / `10`",
          "컴파일 에러",
        ],
        1,
        "세 식 모두 결국 `20`. 참조 투명하면 '어떻게 쓰였나'가 아니라 '무슨 값인가'만 남는다.",
        [
          #(0, "`double(5)`는 `5 + 5`가 아니라 `5 * 2 = 10`입니다. 그리고 `a = double(5) + double(5) = 10 + 10 = 20`. 호출이 두 번 나와도 각각 같은 값 `10`을 내므로 합은 `20`입니다 — 첫 호출만 `10`이고 다음이 다른 값이 되는 일은 순수 함수에선 절대 없습니다."),
          #(2, "`c = v + v`에서 `v`는 `double(5)`를 한 번 묶어둔 이름입니다. `let`은 값을 고정합니다(U1). `v`는 `10`이고 `v + v = 20`. 이름으로 묶든 식을 두 번 쓰든 결과가 같다는 게 핵심입니다."),
        ],
      ),
      tprose(
        "rt-hidden-effect",
        "참조 투명성이 깨지는 전형은 함수 안에 **숨은 효과**가 있을 때다. 아래 `logged`는 겉보기엔 \"받은 값을 그대로 돌려주는 함수\"지만, 부수적으로 화면에 찍는다. 그러면 `logged(7)`을 그 값 `7`로 치환하는 순간 **출력 한 줄이 사라진다** — 의미가 변한 것이므로 참조 투명하지 않다.\n\n```gleam\nimport gleam/io\nimport gleam/int\n\nfn square(x: Int) -> Int {\n  x * x\n}\n\nfn logged(x: Int) -> Int {\n  io.println(\"saw \" <> int.to_string(x))\n  x\n}\n\npub fn main() -> Nil {\n  let p = square(7) + square(7)\n  let q = logged(7) + logged(7)\n  io.println(int.to_string(p))\n  io.println(int.to_string(q))\n}\n```\n\n정직성 노트: Gleam은 이렇게 **부작용을 기본적으로 허용**한다(`logged`는 멀쩡히 컴파일된다). 효과의 유무를 타입으로 강제하지 않는다는 뜻 — 그 책임은 설계자에게 있다.",
      ),
      tmcq(
        "rt-spot-bug",
        "위 코드에서 \"호출을 그 결과값으로 안전하게 치환할 수 있는\" 함수는 어느 쪽이며, 그렇지 못한 쪽은 왜인가? (`square` / `logged` 중 참조 투명성을 깨는 것을 고르고 이유 선택)",
        [
          "`square` — 곱셈은 비결정적이라서",
          "`logged` — `x`를 돌려주지만 부수적으로 `io.println` 효과를 내므로, 호출을 값으로 바꾸면 출력이 사라진다",
          "둘 다 순수하므로 차이 없음",
          "`logged` — 반환 타입이 `Int`라서",
        ],
        1,
        "실행해 보면 `saw 7`이 **두 번** 찍힌다. `logged(7)`을 `7`로 치환하면 그 두 줄이 증발한다 — 효과가 결과에 안 담겨 있기 때문. 그래서 효과 있는 호출은 '값으로 미룰 수 없다'.",
        [
          #(0, "`square`는 순수합니다. `*`는 결정적입니다 — `square(7)`은 언제나 `49`. 곱셈이 비결정적인 일은 없습니다."),
          #(2, "둘은 다릅니다. 출력을 보면 `square` 쪽은 화면에 아무 흔적도 안 남기지만 `logged`는 호출마다 한 줄씩 찍습니다 — 그 흔적이 곧 부작용이고, 그게 치환을 막습니다."),
          #(3, "반환 타입은 순수성과 무관합니다. `Int`를 돌려주더라도 본문에서 `io.println`으로 화면에 찍으면 그 효과 때문에 호출을 값으로 치환할 수 없습니다."),
        ],
      ),
    ],
  )
}

fn l_01_b() -> Lesson {
  tlesson(
    "tu01-purity-l02-nil-effects",
    "tu01-purity",
    "Nil은 '아무것도 아님'이 아니다 — 효과의 신호, 그리고 효과를 값으로 미루기",
    [Theory("side-effect"), Theory("hidden-effect"), Theory("effects-as-values")],
    [
      tprose(
        "nil-signal",
        "`io.println`의 반환 타입은 `Nil`이다. 초심자는 `Nil`을 \"아무것도 안 함 / 무(無)\"로 오해하기 쉽지만, 정반대다. `Nil`은 \"이 함수는 **돌려줄 쓸모 있는 값이 없다 — 너는 이걸 효과 때문에 부른다**\"라는 신호다. 즉 `Nil` 반환은 '함수가 한 일이 화면에 찍는 것뿐'이라는 표식이다. Gleam은 효과를 타입으로 숨기지 않으므로(IO 모나드 같은 게 없다), 이 `Nil`이 우리가 가진 거의 유일한 단서다. 그래서 `Nil`을 진짜 값처럼 쓰려 하면 컴파일러가 막는다.\n\n```gleam\nimport gleam/io\n\npub fn shout(name: String) -> String {\n  io.println(name)\n}\n\npub fn main() -> Nil {\n  io.println(shout(\"hi\"))\n}\n```\n\n위 `shout`의 본문 `io.println(name)`은 `Nil`을 돌려주는데, 함수는 `String`을 돌려준다고 선언했다. 타입이 어긋난다.",
      ),
      tmcq(
        "nil-compile-result",
        "위 `shout` 코드를 그대로 컴파일하면 어떤 일이 일어나는가?",
        [
          "정상 컴파일되어 `hi`가 한 줄 찍힌다",
          "`Type mismatch` — `io.println(name)`이 `Nil`을 돌려주는데 함수는 `String`을 돌려준다고 선언했다",
          "런타임에서야 에러가 난다(컴파일은 통과)",
          "`shout`의 인자 `name`이 쓰이지 않았다는 경고만 난다",
        ],
        1,
        "컴파일러는 `Type mismatch`를 낸다: `io.println(name)`의 타입은 `Nil`이지만 함수의 반환 타입 선언은 `String`이라 어긋난다. `Nil`은 '값 없음'이 아니라 '효과 때문에 부르는 함수'라는 신호이고, 이를 `String` 자리에 끼워 넣을 수 없다.",
        [
          #(0, "컴파일되지 않습니다. `io.println(name)`은 화면에 찍은 뒤 `Nil`을 돌려주는데, `shout`는 `String`을 돌려준다고 선언했으므로 타입이 어긋나 `Type mismatch`가 납니다."),
          #(2, "Gleam은 정적 타입 검사라 이 불일치를 **컴파일 시점**에 잡습니다. 런타임까지 미뤄지지 않습니다."),
          #(3, "단순 경고가 아니라 컴파일을 멈추는 **타입 에러**입니다. 고치려면 `shout`가 실제로 `String`을 돌려주도록 본문을 `string.uppercase(name) <> \"!\"` 같이 바꾸고, 찍는 일은 `main`의 `io.println(shout(\"hi\"))`에 맡깁니다 — '계산'과 '효과'를 분리한 것."),
        ],
      ),
      tprose(
        "defer-effect",
        "그럼 효과를 \"지금 당장 실행\" 말고 \"나중에 실행하도록 **값으로** 들고 다닐\" 수는 없을까? 있다. 효과를 일으키는 코드를 `fn() { ... }` 안에 감싸면, 그건 *실행*이 아니라 *실행 설명서(thunk)*가 된다 — 호출하기 전까지 아무 효과도 안 난다. Gleam은 **eager 평가**라 인자는 호출 직전 평가되지만, `fn()`으로 감싸진 본문은 `()`로 부르기 전까지 잠든다. 이게 \"효과를 데이터로 미루기\"의 맛보기다.\n\n```gleam\nimport gleam/io\n\npub fn main() -> Nil {\n  let action = fn() { io.println(\"BOOM\") }\n  io.println(\"before\")\n  action()\n  action()\n  io.println(\"after\")\n}\n```\n\n정직성 노트: 여기서 `action`은 인자 없는 `fn() -> Nil` 값이다. 부분 적용·자동 커링은 Gleam에 없으므로, \"인자를 덜 준 함수가 알아서 효과를 들고 다니는\" 식의 마술은 없다. 효과를 미루려면 **명시적으로** `fn()`로 감싸야 한다.",
      ),
      tpredict(
        "defer-predict-order",
        "위 코드의 출력 순서는?",
        "import gleam/io\n\npub fn main() -> Nil {\n  let action = fn() { io.println(\"BOOM\") }\n  io.println(\"before\")\n  action()\n  action()\n  io.println(\"after\")\n}",
        [
          "`before` / `after` (효과는 미뤄졌으니 `BOOM`은 안 찍힘)",
          "`BOOM` / `before` / `BOOM` / `after`",
          "`before` / `BOOM` / `BOOM` / `after`",
          "`before` / `BOOM` / `after`",
        ],
        2,
        "`let action = fn() {...}`은 *정의*일 뿐 실행이 아니다 — 그래서 `before`가 먼저. 그 뒤 `action()`을 **두 번** 부르니 `BOOM`이 두 번. eager 평가는 '문장을 위에서 아래로 차례대로 실행'한다.",
        [
          #(0, "`fn()`으로 감싸면 *정의 시점*엔 안 찍히는 게 맞습니다 — 하지만 `action()`이라고 `()`를 붙이는 순간 thunk를 깨워 실행합니다. 미룬 효과도 '부르면' 일어납니다. 두 번 불렀으니 두 번 났습니다."),
          #(1, "정의(`let action = ...`)는 효과를 내지 않으므로 `BOOM`이 `before`보다 먼저 나올 수 없습니다. `before`가 먼저 찍히고, 그 다음 `action()` 호출에서 `BOOM`이 납니다."),
          #(3, "`action()`이 두 줄입니다. 함수 호출은 매번 본문을 새로 실행합니다(메모이제이션 같은 자동 캐싱은 없습니다). 두 번 부르면 두 번 `BOOM`."),
        ],
      ),
    ],
  )
}

fn unit_tu01() -> Unit {
  tunit(
    UnitMeta(
      id: "tu01-purity",
      title: "순수성과 참조 투명성",
      order: 1,
      level: 5,
      concepts: [
        Theory("purity"),
        Theory("referential-transparency"),
        Theory("side-effect"),
        Theory("effects-as-values"),
      ],
      prerequisites: [],
      lesson_ids: [
        "tu01-purity-l01-ref-transparency",
        "tu01-purity-l02-nil-effects",
      ],
    ),
    [l_01_a(), l_01_b()],
  )
}

// ── tu02-equational ─────────────────────────────────────────────
fn l_02_a() -> Lesson {
  tlesson(
    "tu02-equational-l01-substitution",
    "tu02-equational",
    "프로그램을 등식으로 읽기",
    [Theory("equational-reasoning"), Theory("substitution-model")],
    [
      tprose(
        "read-as-equations",
        "Gleam 코드는 명령의 나열이 아니라 **등식의 모음**으로 읽을 수 있다. `let name = expr`는 \"이름 `name`은 `expr`과 *같다*\"는 등식이고, 따라서 `name`이 나오는 자리에 `expr`을 **그대로 끼워 넣어도(치환, substitution) 의미가 변하지 않는다**. 이것이 가능한 *유일한* 이유는 U1·TU1에서 배운 **불변성**이다 — 한 번 정한 이름은 절대 다른 값으로 바뀌지 않으므로, 그 이름은 영원히 같은 정의를 가리킨다.\n\n```gleam\nimport gleam/int\nimport gleam/io\n\npub fn price(qty: Int) -> Int {\n  let unit = 30\n  let subtotal = unit * qty\n  let shipping = 5\n  subtotal + shipping\n}\n\npub fn main() -> Nil {\n  // price(2) 를 손으로 펼치면:\n  //   let unit = 30\n  //   let subtotal = 30 * 2  == 60\n  //   let shipping = 5\n  //   60 + 5  == 65\n  io.println(int.to_string(price(2)))\n}\n```",
      ),
      tpredict(
        "price-predict",
        "`price(2)`의 값은? 머릿속에서 `unit`을 `30`으로, `subtotal`을 `unit * qty`로, 다시 `30 * 2`로 한 단계씩 치환해 보세요.",
        "pub fn price(qty: Int) -> Int {\n  let unit = 30\n  let subtotal = unit * qty\n  let shipping = 5\n  subtotal + shipping\n}\n\nprice(2)",
        ["`65`", "`60`", "`35`", "`70`"],
        0,
        "이렇게 이름을 정의로 한 칸씩 바꿔 끼우는 것이 **치환 모델**입니다. 각 줄을 등식으로 보면 계산은 그저 등식을 따라 항을 줄여 가는 일입니다.",
        [
          #(
            1,
            "`shipping`(= 5)을 더하는 마지막 등식을 빠뜨렸습니다. 마지막 표현식 `subtotal + shipping`이 함수의 값이고, 이는 `60 + 5`로 치환됩니다.",
          ),
          #(
            2,
            "`unit * qty`를 `unit + qty`로 읽었습니다. `subtotal = 30 * 2 = 60`입니다. 치환할 때 연산자까지 정의 그대로 옮겨야 합니다.",
          ),
        ],
      ),
      tprose(
        "why-safe",
        "치환이 안전한 까닭을 거꾸로 음미해 보자. 명령형 언어라면 `let` 사이에서 `unit`이 재대입되어 값이 바뀔 수 있고, 그러면 \"이름 = 정의\"라는 등식이 무너진다. Gleam에는 재대입이 없고(U1), 같은 이름의 재-`let`은 **새 바인딩(shadowing)** 일 뿐이다(이전 이름을 가리던 코드는 옛 등식을 그대로 유지한다, TU1). 그래서 어떤 이름이든 \"그 줄의 정의\"로 마음 놓고 바꿔 끼울 수 있다 — 이 성질을 **참조 투명성(referential transparency)** 이라 부른다.",
      ),
      tmcq(
        "why-substitution-mcq",
        "\"`let`으로 이름 붙인 값은 코드 어디서나 그 정의로 치환해도 의미가 같다\"가 Gleam에서 항상 성립하는 근본 이유로 가장 정확한 것은?",
        [
          "Gleam이 모든 `let`을 상수로 인라인 최적화하기 때문",
          "이름이 한 번 바인딩되면 다시 다른 값으로 변하지 않기 때문(불변성/참조 투명성)",
          "Gleam이 자동으로 함수를 커링하기 때문",
          "컴파일러가 타입을 추론하기 때문",
        ],
        1,
        "치환의 토대는 컴파일러 최적화가 아니라 **언어의 의미론적 불변식**입니다 — 값이 변하지 않으니 이름은 영원히 같은 정의를 뜻합니다.",
        [
          #(
            0,
            "최적화는 *결과*이지 *근거*가 아닙니다. 옵티마이저가 없어도 등식은 참입니다. 안전성의 출처는 불변성입니다.",
          ),
          #(
            2,
            "Gleam에는 **자동 커링이 없습니다**(부분 적용은 캡처 `f(10, _)`로 명시 — U7/U14②). 커링과 치환 안전성은 무관합니다.",
          ),
        ],
      ),
    ],
  )
}

fn l_02_b() -> Lesson {
  tlesson(
    "tu02-equational-l02-refactor",
    "tu02-equational",
    "리팩터링은 의미 보존 재작성이다",
    [Theory("refactor-is-rewrite"), Theory("substitution-unsound-with-effects")],
    [
      tprose(
        "refactor-as-rewrite",
        "좋은 리팩터링이란 \"보기 좋게 다시 쓰되 **값이 같음을 등식으로 보장**한 변환\"이다. 사실 우리가 이미 쓰는 문법 설탕 대부분이 등식 변환이다. `x |> f` 는 정의상 `f(x)` 와 같고(U2), 캡처 `f(_, k)` 는 `fn(s) { f(s, k) }` 와 같으며(U7), `use a <- result.try(r)` 는 `result.try(r, fn(a) { …나머지… })` 와 같다(U10). 아래 네 갈래는 **글자만 다른 같은 계산**이며 `assert`로 서로 같음을 표본 검사한다.\n\n```gleam\nimport gleam/string\nimport gleam/io\n\n// 네 가지 표기는 모두 *같은 계산*을 적는 등식적으로 동등한 방법이다.\npub fn main() -> Nil {\n  let name = \"  lucy \"\n\n  // (1) 중첩 호출\n  let a = string.append(string.uppercase(string.trim(name)), \"!\")\n  // (2) 파이프: x |> f 는 정의상 f(x)\n  let b = name |> string.trim |> string.uppercase |> string.append(\"!\")\n  // (3) 캡처: string.append(_, \"!\") 는 fn(s) { string.append(s, \"!\") } 의 설탕\n  let shout = string.append(_, \"!\")\n  let c = shout(string.uppercase(string.trim(name)))\n\n  assert a == b\n  assert b == c\n  assert a == \"LUCY!\"\n  io.println(a)\n}\n```",
      ),
      tmcq(
        "map-fusion-mcq",
        "아래 `slow`를 **값을 바꾸지 않고** `list.map`을 한 번만 쓰도록 재작성하려 한다(map fusion: `map f (map g xs) == map (fn(x) { f(g(x)) }) xs`). 원본은 `xs |> list.map(add1) |> list.map(times2)` 이다. **등식을 보존하는** 재작성은?",
        [
          "`xs |> list.map(fn(x) { times2(add1(x)) })`",
          "`xs |> list.map(fn(x) { add1(times2(x)) })`",
          "`xs |> list.filter(fn(x) { times2(add1(x)) })`",
        ],
        0,
        "두 번 순회하던 것을 한 번으로 줄이면서 결과는 **증명 가능하게 동일**합니다. 원본은 `add1`을 먼저, `times2`를 나중에 적용하므로 안쪽이 `add1(x)`인 `times2(add1(x))`가 맞습니다. 단, 이 map-fusion 등식은 List라는 *구체 타입*에서만 성립하는 것으로 다룹니다 — Gleam에는 **타입클래스도 HKT도 없어** '모든 Functor에 동작하는 map' 같은 단일 일반 함수를 쓸 수 없기 때문입니다(U14①).",
        [
          #(
            1,
            "합성 순서를 뒤집었습니다. 원본은 `add1`을 *먼저* 적용하므로 안쪽이 `add1(x)`여야 합니다 — `times2(add1(x))`. 등식 보존 리팩터는 순서까지 보존해야 합니다.",
          ),
          #(
            2,
            "`filter`는 `Bool`을 받는데 `times2(add1(x))`는 `Int`라 컴파일되지 않습니다. 그리고 `filter`는 `map`과 다른 계산입니다 — 의미를 바꾸면 리팩터가 아닙니다.",
          ),
        ],
      ),
      tprose(
        "effects-break-substitution",
        "치환과 등식 변환에는 **결정적 단서**가 하나 있다 — **부작용(effect)이 없어야** 한다. Gleam에는 예외도 뮤테이션도 없지만(불변·Result 모델), `io.println`처럼 화면 출력이라는 부작용을 갖는 표현식은 예외다. 효과가 있는 식을 이름으로 한 번 묶었다가 그 이름을 정의로 \"펼치면\" 효과가 일어나는 **횟수가 달라진다**. 아래에서 `named`는 `\"hi\"`를 한 번, 펼친 `inlined`는 두 번 출력한다 — 같은 텍스트인데 의미가 다르다.\n\n```gleam\nimport gleam/io\n\n// 부작용(effect)이 끼면 \"let 을 펼치는\" 치환이 의미를 바꾼다.\n// io.println 은 Nil 을 반환하지만 *화면 출력*이라는 부작용을 갖는다.\n\n// 버전 A: 한 번 이름 붙이고 두 번 사용\npub fn named() -> Nil {\n  let logged = io.println(\"hi\")\n  let _ = logged\n  let _ = logged\n  Nil\n}\n\n// 버전 B: 그 이름을 정의로 \"치환\"해 두 곳에 펼침\npub fn inlined() -> Nil {\n  let _ = io.println(\"hi\")\n  let _ = io.println(\"hi\")\n  Nil\n}\n\npub fn main() -> Nil {\n  io.println(\"--A (named, 펼치기 전)--\")\n  named()\n  io.println(\"--B (inlined, 펼친 후)--\")\n  inlined()\n}\n```",
      ),
      tpredict(
        "effects-predict",
        "위 `main`의 전체 출력은? (`named`에서 `logged`를 정의로 치환하면 무슨 일이 생기는지 생각하세요.)",
        "pub fn named() -> Nil {\n  let logged = io.println(\"hi\")\n  let _ = logged\n  let _ = logged\n  Nil\n}\n\npub fn inlined() -> Nil {\n  let _ = io.println(\"hi\")\n  let _ = io.println(\"hi\")\n  Nil\n}\n\npub fn main() -> Nil {\n  io.println(\"--A (named, 펼치기 전)--\")\n  named()\n  io.println(\"--B (inlined, 펼친 후)--\")\n  inlined()\n}",
        [
          "`--A …` / `hi` / `--B …` / `hi`",
          "`--A …` / `hi` / `--B …` / `hi` / `hi`",
          "`--A …` / `hi` / `hi` / `--B …` / `hi` / `hi`",
          "컴파일 에러",
        ],
        1,
        "`named`는 `io.println('hi')`를 **한 번** 실행해 `Nil`을 `logged`에 묶고, 이후엔 그 `Nil` 값을 두 번 들여다볼 뿐이라 출력은 한 번입니다. `inlined`는 효과식을 두 자리에 적었으니 두 번 출력됩니다. **즉 효과가 있으면 `let logged = io.println(…)`을 정의로 치환할 수 없습니다** — 등식적 추론의 전제(참조 투명성)가 깨지는 지점입니다(TU1 연결).",
        [
          #(
            0,
            "`inlined`에 `io.println('hi')`가 두 줄 있다는 점을 놓쳤습니다. eager 평가라 두 식 모두 호출 시점에 즉시 실행됩니다(게으름 없음 — 지연하려면 `fn() -> a` thunk).",
          ),
          #(
            2,
            "`named`의 `let _ = logged`는 *이미 계산된 `Nil` 값*을 버리는 것이지 `io.println`을 다시 호출하는 게 아닙니다. 효과는 **이름을 바인딩하는 순간 한 번** 일어납니다(eager). 그래서 `named`의 출력은 'hi' 한 번뿐입니다.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu02() -> Unit {
  tunit(
    UnitMeta(
      id: "tu02-equational",
      title: "등식적 추론과 치환 모델",
      order: 2,
      level: 5,
      concepts: [
        Theory("equational-reasoning"),
        Theory("substitution-model"),
        Theory("refactor-is-rewrite"),
        Theory("substitution-unsound-with-effects"),
      ],
      prerequisites: ["tu01-purity"],
      lesson_ids: [
        "tu02-equational-l01-substitution",
        "tu02-equational-l02-refactor",
      ],
    ),
    [l_02_a(), l_02_b()],
  )
}

// ── tu03-evaluation ─────────────────────────────────────────────
fn l_03_a() -> Lesson {
  tlesson(
    "tu03-evaluation-l01-reduction",
    "tu03-evaluation",
    "환원과 평가 순서",
    [
      Theory("evaluation-order"),
      Theory("eager-vs-lazy"),
      Theory("normal-order-termination"),
    ],
    [
      tprose(
        "reduction-intro",
        "프로그램 실행이란 식을 더 단순한 식으로 **환원(reduction)**하는 과정이다. `square(2 + 3)`을 값으로 만드는 데는 두 길이 있다.\n\n- **applicative order**(strict/eager): 인자를 *먼저* 값으로 환원하고(`2 + 3` -> `5`) 그 다음 함수에 적용한다(`square(5)` -> `25`).\n- **normal order**(lazy): 함수를 *먼저* 적용하고(`square(2+3)` -> `(2+3) * (2+3)`) 필요할 때 인자를 환원한다.\n\nGleam은 **applicative order = eager**다. 즉 함수에 들어가기 전에 인자가 반드시 값이 되어 있다.\n\n```gleam\nimport gleam/int\n\npub fn square(x: Int) -> Int {\n  x * x\n}\n\npub fn demo() -> Int {\n  // eager: 2 + 3 이 먼저 5 로 환원된 뒤 square 에 들어간다\n  square(2 + 3)\n}\n// demo() == 25,  int.to_string(demo()) == \"25\"\n```",
      ),
      tpredict(
        "pick-first-eager",
        "아래 코드의 stdout을 예측하라. `shout`은 자기 인자를 출력하고 그대로 돌려준다. `pick_first`은 두 번째 인자를 *쓰지 않는다*(`_b`).",
        "import gleam/io\nimport gleam/int\n\npub fn pick_first(a: Int, _b: Int) -> Int {\n  a\n}\n\npub fn shout(x: Int) -> Int {\n  io.println(\"evaluated \" <> int.to_string(x))\n  x\n}\n\npub fn main() -> Nil {\n  let _ = pick_first(1, shout(99))\n  Nil\n}",
        ["`evaluated 99` 한 줄", "아무것도 출력 안 함", "`evaluated 99` 두 줄"],
        0,
        "`_b`로 무시하지만, eager 언어에서는 *함수 본문에 들어가기 전에* 모든 인자가 평가됩니다. `shout(99)`는 쓰이든 안 쓰이든 한 번 실행됩니다.",
        [
          #(
            1,
            "그건 normal order(lazy)의 답입니다. lazy라면 `_b`가 한 번도 쓰이지 않으니 `shout(99)`는 환원될 필요가 없어 출력이 없겠죠. 하지만 Gleam은 eager라 사용 여부와 무관하게 인자를 미리 평가합니다 — 이 차이가 이 유닛의 핵심입니다.",
          ),
          #(
            2,
            "인자는 호출당 한 번만 평가됩니다. 두 번 찍히는 건 normal order가 인자를 본문 안에서 *여러 번* 환원할 때 생기는 현상인데, Gleam은 애초에 인자를 미리 한 번 값으로 만들어 둡니다.",
          ),
        ],
      ),
      tprose(
        "termination-tradeoff",
        "두 순서의 차이는 성능 취향이 아니라 **종료성(termination)**의 문제이기도 하다 — 이론적으로 normal order는 더 많은 식을 종료시킨다(쓰이지 않는 인자가 무한 루프여도 결과가 나옴). Gleam이 eager를 택한 대가로, \"쓰이지 않을 수도 있는 비싼/위험한 인자\"를 그냥 넘기면 무조건 평가된다.\n\n이 한계 위에서 Gleam이 제공하는 *유일한* 언어 차원의 예외가 다음 레슨의 단락 평가다. eager는 Gleam의 다른 결핍들 — 자동 커링 없음, 타입클래스 없음, 예외 없음 — 과 같은 \"예측 가능성 우선\" 설계 철학의 한 줄기다.",
      ),
      tmcq(
        "lazy-not-always-faster",
        "\"normal order(lazy)가 applicative order(eager)보다 **항상** 더 효율적이다\"는 주장은?",
        [
          "참 — lazy는 안 쓰는 인자를 건너뛰니까",
          "거짓 — lazy는 미평가 식(thunk)을 만들고 관리하는 비용·메모리가 들고, 쓰이는 인자를 여러 번 마주치면 재평가될 수도 있다",
          "참 — lazy에는 단락 평가가 내장이라",
        ],
        1,
        "lazy의 장점은 '종료성을 더 많이 보장하고 안 쓰는 건 안 한다'이지 '항상 빠르다'가 아닙니다. 미평가를 표현하려면 thunk라는 런타임 표현이 필요하고, 공유(sharing) 없이 구현하면 같은 인자를 재평가합니다. Gleam이 eager를 고른 이유 중 하나가 바로 이 예측 가능한 비용입니다.",
        [
          #(
            0,
            "lazy가 안 쓰는 인자를 건너뛰는 건 맞지만 그것만으로 '항상' 더 빠른 건 아닙니다. 미평가 식을 표현하고 관리하는 thunk 비용이 추가로 듭니다.",
          ),
          #(
            2,
            "단락 평가는 lazy 언어의 전유물이 아닙니다. Gleam(eager)에도 `&&`/`||`의 단락이 있죠 — 다음 레슨 주제입니다.",
          ),
        ],
      ),
    ],
  )
}

fn l_03_b() -> Lesson {
  tlesson(
    "tu03-evaluation-l02-thunk",
    "tu03-evaluation",
    "게으름 흉내내기 — thunk",
    [Theory("thunk"), Theory("eager-eval-surprise")],
    [
      tprose(
        "thunk-intro",
        "Gleam은 게으름을 언어로 주지 않으니, 평가를 미루려면 식을 인자 없는 함수 `fn() -> a`(=**thunk**)로 감싸 넘긴다. thunk를 받은 쪽이 `()`로 *호출할 때만* 안의 식이 환원된다.\n\nU7의 함수 값이 여기서 두 번째 정체를 드러낸다 — \"함수를 넘긴다\"가 곧 \"평가를 미룬다\"다. 이것이 무한 시퀀스나 비싼 fallback을 stdlib만으로 다룰 때의 기본기다(진짜 무한 스트림은 `gleam_yielder` 라이브러리 영역).\n\n```gleam\nimport gleam/io\nimport gleam/int\n\n// 두 번째 인자를 미사용. 단, 이제 thunk 라서 호출 전에는 평가되지 않는다.\npub fn pick_first_lazy(a: Int, _thunk: fn() -> Int) -> Int {\n  a\n}\n\npub fn shout(x: Int) -> Int {\n  io.println(\"evaluated \" <> int.to_string(x))\n  x\n}\n\npub fn main() -> Nil {\n  // shout(99) 가 thunk 안에 갇혀 있어 호출되지 않음 -> 아무 출력 없음\n  let _ = pick_first_lazy(1, fn() { shout(99) })\n  io.println(\"done\")\n  Nil\n}\n// stdout: \"done\" 한 줄뿐\n```",
      ),
      tpredict(
        "thunk-deferred",
        "위 `main`의 stdout을 예측하라.",
        "import gleam/io\nimport gleam/int\n\npub fn pick_first_lazy(a: Int, _thunk: fn() -> Int) -> Int {\n  a\n}\n\npub fn shout(x: Int) -> Int {\n  io.println(\"evaluated \" <> int.to_string(x))\n  x\n}\n\npub fn main() -> Nil {\n  let _ = pick_first_lazy(1, fn() { shout(99) })\n  io.println(\"done\")\n  Nil\n}",
        ["`evaluated 99` 다음 `done`", "`done` 한 줄", "아무것도 없음"],
        1,
        "`fn() { shout(99) }`는 *함수 값*일 뿐 호출이 아닙니다. eager 평가는 인자(=이 함수 값 자체)를 만들지만, 그 안의 `shout(99)`는 누군가 `thunk()`로 호출해야 환원됩니다. `pick_first_lazy`는 thunk를 무시하므로 영영 호출되지 않죠.",
        [
          #(
            0,
            "그건 thunk로 감싸기 *전* 버전의 출력입니다. `shout(99)`를 직접 넘기면 eager라 즉시 평가되지만, `fn() { shout(99) }`로 감싸면 호출을 미룹니다 — 이 한 겹의 `fn()`이 eager 세계에서 게으름을 흉내내는 전부입니다.",
          ),
          #(
            2,
            "`io.println(\"done\")`은 그대로 실행됩니다. 미뤄지는 건 thunk 안의 식뿐이에요.",
          ),
        ],
      ),
      tprose(
        "eager-surprise",
        "thunk를 안 씌우면 eager가 우리를 놀라게 한다 — **비싸거나 크래시할 수 있는 인자가 쓰이기도 전에 평가**된다. 가장 함정인 곳은 stdlib의 \"기본값\" 류 함수다.\n\n`bool.guard(when:, return:, otherwise:)`에서 `return`은 **즉시 평가되는 값**이고 `otherwise`만 thunk(`fn() -> a`)다. 그래서 `return`에 무거운 식을 직접 쓰면, 그 가지가 선택되지 않아도 인자로서 먼저 평가된다.\n\n미평가 기본값을 원하면 두 가지를 모두 thunk로 받는 `bool.lazy_guard`, 또는 `option.lazy_unwrap`/`result.lazy_unwrap`을 쓴다. 이런 `lazy_*` 변종이 *함수마다 따로* 존재하는 이유가 바로 Gleam엔 HKT·타입클래스가 없어 \"모든 게으른 기본값에 동작하는 단일 일반 함수\"를 쓸 수 없기 때문이다.\n\n```gleam\nimport gleam/io\nimport gleam/int\nimport gleam/bool\n\npub fn heavy(tag: String) -> Int {\n  io.println(\"heavy \" <> tag)\n  100\n}\n\npub fn main() -> Nil {\n  // when: False 라 'otherwise' 가 선택되지만,\n  // 'return: heavy(\"R\")' 는 인자라서 호출 전에 이미 평가된다 (eager 함정!)\n  let r =\n    bool.guard(when: False, return: heavy(\"R\"), otherwise: fn() { heavy(\"O\") })\n  io.println(\"r=\" <> int.to_string(r))\n  Nil\n}\n// stdout: \"heavy R\" -> \"heavy O\" -> \"r=100\"\n```",
      ),
      tmcq(
        "spot-eager-default",
        "아래 세 코드는 모두 \"캐시에 값이 있으면 그걸, 없으면 비싼 `recompute()`를 쓰기\"를 의도한다. **불필요하게 `recompute()`를 항상 실행하는** 비관용적 코드를 고르라.\n\n```gleam\nimport gleam/option.{type Option}\n\n// (A)\npub fn get_a(cache: Option(Int)) -> Int {\n  option.lazy_unwrap(cache, or: fn() { recompute() })\n}\n\n// (B)\npub fn get_b(cache: Option(Int)) -> Int {\n  option.unwrap(cache, or: recompute())\n}\n\n// (C)\npub fn get_c(cache: Option(Int)) -> Int {\n  case cache {\n    option.Some(v) -> v\n    option.None -> recompute()\n  }\n}\n\npub fn recompute() -> Int {\n  // ...비싼 계산...\n  0\n}\n```",
        ["(A)", "(B)", "(C)"],
        1,
        "`option.unwrap`의 기본값 `or:`는 **eager 값** 인자라, `Some(v)`로 캐시가 채워져 있어도 `recompute()`가 인자로서 먼저 실행됩니다. (A)는 `lazy_unwrap`이 기본값을 thunk `fn() -> a`로 받아 `None`일 때만 호출하고, (C)는 `case`로 `None` 가지에서만 호출하므로 둘 다 관용적입니다.",
        [
          #(
            0,
            "(A)의 `fn() { recompute() }`는 *호출이 아니라 thunk*입니다. `lazy_unwrap`은 `None`일 때만 그 thunk를 부르니 캐시 적중 시 `recompute()`는 실행되지 않습니다 — 정확히 우리가 원하는 동작이에요.",
          ),
          #(
            2,
            "(C)는 가장 솔직한 형태입니다. `case`의 가지는 선택될 때만 평가되므로(분기 자체가 일종의 단락), `None`일 때만 `recompute()`가 돕니다. `lazy_unwrap`은 사실 이 `case`를 한 함수로 포장한 것.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu03() -> Unit {
  tunit(
    UnitMeta(
      id: "tu03-evaluation",
      title: "평가 전략: eager와 lazy",
      order: 3,
      level: 5,
      concepts: [
        Theory("eager-vs-lazy"),
        Theory("evaluation-order"),
        Theory("thunk"),
        Theory("eager-eval-surprise"),
      ],
      prerequisites: ["tu01-purity"],
      lesson_ids: ["tu03-evaluation-l01-reduction", "tu03-evaluation-l02-thunk"],
    ),
    [l_03_a(), l_03_b()],
  )
}

// ── tu04-adt-algebra ─────────────────────────────────────────────
fn l_04_a() -> Lesson {
  tlesson(
    "tu04-adt-algebra-l01-cardinality",
    "tu04-adt-algebra",
    "타입은 값들의 집합 — 카디널리티 세기",
    [Theory("cardinality"), Theory("unit-void-types")],
    [
      tprose(
        "card-intro",
        "한 타입을 \"그 타입이 가질 수 있는 값들의 *집합*\"으로 보면, 각 타입에는 **카디널리티**(원소 개수, |T|로 표기)가 붙습니다. `Bool`은 `{True, False}` 두 개라 |Bool|=2. 생성자 없는 variant들의 합 타입(enum)은 variant 개수만큼입니다.\n\n```gleam\npub type Direction {\n  North\n  South\n  East\n  West\n}\n// |Direction| = 4  (North, South, East, West — 다른 값은 존재 불가)\n```",
      ),
      tpredict(
        "card-direction",
        "`Direction`의 모든 값을 한 리스트에 빠짐없이 모은 뒤 길이를 출력합니다. 무엇이 찍힐까요?",
        "import gleam/io\nimport gleam/list\nimport gleam/int\n\npub type Direction {\n  North\n  South\n  East\n  West\n}\n\npub fn main() -> Nil {\n  // List(Direction) 자체는 println 불가 → length만 찍어 카디널리티를 본다.\n  io.println(int.to_string(list.length([North, South, East, West])))\n}",
        ["`2`", "`4`", "`무한`"],
        1,
        "한 enum의 카디널리티 = variant 개수. `[North, South, East, West]`는 가능한 값을 *전부* 적은 것이라 길이 4가 곧 |Direction|. 타입을 '가능한 값들의 집합'으로 읽는 첫 근육입니다.",
        [
          #(2, "Direction에는 North/South/East/West 외의 값이 *표현 자체로* 불가능합니다 — `Int`처럼 무한하지 않아요. ADT의 핵심은 '가능한 상태를 유한하게 봉인'하는 것이고, 그 개수가 곧 카디널리티입니다. U4의 exhaustiveness 검사가 가능한 이유도 바로 이 유한성 덕입니다."),
        ],
      ),
      tprose(
        "card-unit-void",
        "두 극단을 못 박읍시다. **`Nil`은 카디널리티 1**입니다 — 값이 정확히 하나(`Nil`)뿐이라 \"아무 정보도 없음\"을 뜻하는 unit 타입. 반대로 **생성자가 하나도 없는 `pub type Void`는 카디널리티 0**입니다 — *어떤 값도 만들 수 없습니다*. `Nil`을 0으로 착각하지 마세요: 0은 값이 없는 것이고, 1은 \"값이 딱 하나\"라 선택지가 없는 것입니다.\n\n```gleam\npub type Void\n\npub fn impossible() -> Void {\n  Void\n}\n```\n\n실제 컴파일러 출력(검증됨):\n\n```\nerror: Unknown variable\n  ┌─ src/main.gleam:5:3\n  │\n5 │   Void\n  │   ^^^^\n\n`Void` is a type, it cannot be used as a value.\n```",
      ),
      tmcq(
        "card-which-one",
        "다음 중 카디널리티가 **1**인 타입은?",
        ["`Bool`", "`Nil`", "`pub type Void`(생성자 없음)", "`Int`"],
        1,
        "`Nil`은 값이 딱 하나(`Nil`)뿐 — |Nil|=1. '정보 0비트'를 담는 자리.",
        [
          #(0, "`Bool`은 `{True, False}` 두 개라 |Bool|=2입니다. 1이 아니에요."),
          #(2, "그건 카디널리티 **0**입니다(void). 생성자가 없으니 값을 *하나도* 만들 수 없어요 — 방금 본 `Void` 컴파일 에러가 그 증거입니다. 0(값 없음)과 1(값이 정확히 하나)은 전혀 다릅니다. 이 혼동은 TU5의 0·1 항등원 논의에서 다시 다룹니다."),
          #(3, "`Int`는 값이 무한히 많습니다 — |Int|은 1이 아니라 사실상 무한이에요."),
        ],
      ),
    ],
  )
}

fn l_04_b() -> Lesson {
  tlesson(
    "tu04-adt-algebra-l02-sum-product-exp",
    "tu04-adt-algebra",
    "곱·합·함수 — 더하고, 곱하고, 거듭제곱하기",
    [Theory("sum-product-types"), Theory("cardinality-miscount"), Theory("adt-algebra")],
    [
      tprose(
        "spe-intro",
        "곱 타입(`#(a, b)` 또는 모든 필드를 가진 레코드)의 값 하나는 \"`a` 하나 **그리고** `b` 하나\"입니다. 가능한 조합은 |a|×|b|개 — 그래서 **곱**입니다. 합 타입(여러 variant)의 값은 \"이 variant **또는** 저 variant\"라 |a|+|b|개 — 그래서 **합**입니다.\n\n```gleam\npub type Light {\n  Off\n  On(brightness: Bool)\n}\n// |Light| = |Off| + |On(Bool)| = 1 + 2 = 3\n// 모든 값 열거:  Off, On(False), On(True)\n\npub type Pair2 {\n  Pair2(a: Bool, b: Bool)\n}\n// |Pair2| = |Bool| × |Bool| = 2 × 2 = 4\n```",
      ),
      tpredict(
        "spe-option-bool",
        "`Option(Bool)`의 값을 빠짐없이 한 리스트에 모은 뒤 길이를 출력합니다. 무엇이 찍힐까요?",
        "import gleam/io\nimport gleam/list\nimport gleam/option.{type Option, None, Some}\nimport gleam/int\n\npub fn all_option_bool() -> List(Option(Bool)) {\n  [None, Some(False), Some(True)]\n}\n\npub fn main() -> Nil {\n  io.println(int.to_string(list.length(all_option_bool())))\n}",
        ["`2`", "`3`", "`4`"],
        1,
        "`Option(a) = None | Some(a)`는 합 타입이라 |Option(a)| = 1 + |a|. `Option(Bool)` = 1 + 2 = 3 (`None`, `Some(False)`, `Some(True)`). 같은 공식으로 `Result(a, e)` = |a| + |e|입니다.",
        [
          #(0, "2는 `Bool` 자체(|Bool|=2)의 답입니다. `Option`은 거기에 `None` 갈래를 1개 더하므로 1+2=3이에요."),
          #(2, "4는 `Result(Bool, Bool)`(=2+2)이나 `#(Bool, Bool)`(=2×2)의 답입니다. `Option`은 한쪽에만 `Some`이 값을 싣고 `None`은 값 0개를 더하므로 1+2=3이에요. 합이지 곱이 아닙니다 — `None`은 '`Bool` 하나 *그리고*'가 아니라 '값 없는 갈래'."),
        ],
      ),
      tprose(
        "spe-exp",
        "함수 타입 `fn(a) -> b`의 값 하나는 \"정의역의 *각* 입력마다 출력을 하나씩 고른 표\"입니다. 입력이 |a|개, 각각 |b|가지 출력 → 가능한 함수는 **|b|^|a|개** (밑이 출력 |b|, 지수가 입력 |a|). 그래서 합·곱·**거듭제곱**까지 갖춰 \"타입의 대수\"가 완성됩니다.\n\n**정직성 노트**: 이 셈은 *전역(total)이며 순수한* 함수 기준입니다. Gleam의 함수 타입 시그니처는 전역·순수를 **강제하지 않습니다** — `panic`/`todo` 중단, 무한 재귀 발산, 부수효과를 일으켜도 똑같이 타입 검사를 통과합니다. 따라서 |b|^|a|가 정확히 맞는 것은 *추상적 전역·순수 함수 집합*에서이고, 실제 Gleam 코드는 그 부분집합을 **컨벤션으로 약속**할 뿐입니다.\n\n```gleam\nimport gleam/io\nimport gleam/list\nimport gleam/int\n\n// 전역·순수인 fn(Bool) -> Bool 은 정확히 2^2 = 4개. 그 넷을 전부 열거한다.\npub fn all_bool_functions() -> List(fn(Bool) -> Bool) {\n  [\n    fn(_b) { False },\n    fn(b) { b },\n    fn(b) { !b },\n    fn(_b) { True },\n  ]\n}\n\npub fn main() -> Nil {\n  let fns = all_bool_functions()\n  assert list.length(fns) == 4\n  io.println(int.to_string(list.length(fns)))\n}\n```",
      ),
      tmcq(
        "spe-spot-bug",
        "세 학생이 `fn(Direction) -> Bool`의 값 개수를 셌습니다 (`|Direction|=4`, `|Bool|=2`). *틀린* 풀이를 고르세요.",
        [
          "(A) \"|Bool|^|Direction| = 2^4 = **16**개.\"",
          "(B) \"각 방향마다 True/False를 독립으로 고르니 2×2×2×2 = **16**개.\"",
          "(C) \"정의역이 4개, 공역이 2개니 |Direction|^|Bool| = 4^2 = **16**개.\"",
        ],
        2,
        "공식은 |b|^|a| = (출력)^(입력) = 2^4입니다. (C)는 밑과 지수를 뒤집었어요 — 여기선 우연히 답이 같지만 `fn(3원소) -> Bool`이면 2^3=**8**(맞음) vs 3^2=9(틀림)로 갈라집니다. (A)는 공식 그대로, (B)는 그 거듭제곱을 곱으로 펼친 같은 셈입니다.",
        [
          #(0, "(A)·(B)는 둘 다 옳습니다. (A)는 |b|^|a| 공식 그대로예요. 밑·지수를 뒤집은 (C)가 함정입니다. 그리고 이 셈도 전역·순수 함수에 한합니다."),
          #(1, "(A)·(B)는 둘 다 옳습니다. (B)는 (A)의 2^4를 '입력 4개 각각 출력 2지 → 곱'으로 풀어 쓴 것일 뿐 — 거듭제곱이 곧 반복된 곱이라는 TU5의 복선이에요. 밑·지수를 뒤집은 (C)가 함정입니다."),
        ],
      ),
    ],
  )
}

fn unit_tu04() -> Unit {
  tunit(
    UnitMeta(
      id: "tu04-adt-algebra",
      title: "대수적 데이터 타입의 대수",
      order: 4,
      level: 6,
      concepts: [
        Theory("adt-algebra"),
        Theory("cardinality"),
        Theory("sum-product-types"),
        Theory("unit-void-types"),
      ],
      prerequisites: [],
      lesson_ids: [
        "tu04-adt-algebra-l01-cardinality",
        "tu04-adt-algebra-l02-sum-product-exp",
      ],
    ),
    [l_04_a(), l_04_b()],
  )
}

// ── tu05-isomorphism ─────────────────────────────────────────────
fn l_05_a() -> Lesson {
  tlesson(
    "tu05-isomorphism-l01-what-is-iso",
    "tu05-isomorphism",
    "동형이란 무엇인가",
    [Theory("type-isomorphism")],
    [
      tprose(
        "iso-def",
        "두 타입 `A`, `B`가 **동형**(`A ≅ B`)이라는 것은, 변환쌍 `to : A -> B`와 `from : B -> A`가 존재하여 **양방향 왕복이 제자리로 돌아온다**는 뜻이다 — `from(to(a)) = a` (모든 `a`)이고 `to(from(b)) = b` (모든 `b`). 둘 중 한쪽만 성립하면 동형이 아니다(그건 나중에 볼 \"가짜 동형\"). U9에서 따로 배운 `Option(a)`와 `Result(a, Nil)`이 첫 사례다: `Some ↔ Ok`, `None ↔ Error(Nil)`로 1:1 대응되고, 카디널리티도 둘 다 `a의 개수 + 1`로 같다.\n\n```gleam\nimport gleam/io\nimport gleam/option.{type Option, None, Some}\n\npub fn result_to_option(r: Result(a, Nil)) -> Option(a) {\n  case r {\n    Ok(x) -> Some(x)\n    Error(Nil) -> None\n  }\n}\n\npub fn option_to_result(o: Option(a)) -> Result(a, Nil) {\n  case o {\n    Some(x) -> Ok(x)\n    None -> Error(Nil)\n  }\n}\n\npub fn main() -> Nil {\n  // from ∘ to = id  과  to ∘ from = id  를 표본으로 단언한다\n  assert option_to_result(result_to_option(Ok(7))) == Ok(7)\n  assert option_to_result(result_to_option(Error(Nil))) == Error(Nil)\n  assert result_to_option(option_to_result(Some(7))) == Some(7)\n  assert result_to_option(option_to_result(None)) == None\n  io.println(\"iso ok\")\n}\n```",
      ),
      tpredict(
        "iso-roundtrip-predict",
        "위 `main`을 실행하면 무엇이 출력되는가?",
        "assert option_to_result(result_to_option(Ok(7))) == Ok(7)\nassert option_to_result(result_to_option(Error(Nil))) == Error(Nil)\nassert result_to_option(option_to_result(Some(7))) == Some(7)\nassert result_to_option(option_to_result(None)) == None\nio.println(\"iso ok\")",
        ["`iso ok`", "크래시 — assert 실패", "출력 없음"],
        0,
        "네 개의 `assert`가 모두 통과했다는 뜻 — 즉 `Ok(7)`을 `Option`으로 갔다가 돌아오면 여전히 `Ok(7)`이고, 반대 방향도 마찬가지. 이게 왕복 항등이 표본 위에서 성립함을 *실행 가능한 프로퍼티*로 본 것입니다(법칙은 코드로 검사할 수 있다 — TU 트랙 내내 반복되는 주제).",
        [
          #(1, "`assert`는 식이 `False`일 때만 크래시합니다. `option_to_result(result_to_option(Ok(7)))`은 `Ok(7) -> Some(7) -> Ok(7)`로 제자리에 돌아오므로 `== Ok(7)`은 `True` — 크래시하지 않습니다. 이 '제자리로 돌아옴'이 바로 동형의 정의입니다."),
        ],
      ),
      tprose(
        "iso-info",
        "동형의 핵심 직관은 **\"표현은 달라도 정보량이 같다\"** 이다. `Option(Int)`로 적든 `Result(Int, Nil)`로 적든, 담을 수 있는 서로 다른 값의 *개수*는 정확히 같다(둘 다 무한한 정수 + \"없음\" 한 칸). 표현을 바꾸는 것은 정보를 더하거나 버리지 않는다 — 그래서 stdlib가 `Result(a, Nil)`을 즐겨 쓰면서도 우리가 `Option`으로 자유롭게 옮겨 적을 수 있는 것이다. **정직성**: 만약 Gleam에 타입클래스가 있었다면 \"모든 동형을 한 줄로 표현하는 일반 `Iso(a, b)` 인터페이스\"를 만들었겠지만, Gleam엔 타입클래스도 HKT도 없으므로 동형은 *구체 타입쌍마다 `to`/`from` 함수를 직접 적어 알아보는 패턴*일 뿐이다.",
      ),
      tmcq(
        "iso-safe-head-type",
        "`safe_head`가 `Option(Int)`을 반환해야 하는데, `[first, ..]` 가지에서 `Some(first)` 대신 `Ok(first)`를 적었다. 이 코드를 컴파일하면?",
        ["정상 컴파일된다 — 동형이므로 `Ok`와 `Some`은 호환된다", "Type mismatch — `Option`을 반환해야 하는데 `Result`를 줌", "Inexhaustive patterns 에러"],
        1,
        "방금 적은 `safe_head`는 `list.first`(이것은 `Result(a, Nil)`을 반환)의 동형 파트너입니다 — 같은 정보를 `Option`으로 적었을 뿐. 동형이라고 해서 *같은 타입*인 것은 아닙니다. 정보량이 같을 뿐, 컴파일러에게는 엄연히 다른 타입이라 `to`/`from`을 명시적으로 거쳐야 합니다.",
        [
          #(0, "동형이라고 해서 *같은 타입*인 것은 아닙니다. 정보량이 같을 뿐, 컴파일러에게는 `Option`과 `Result`가 엄연히 다른 타입이라 `to`/`from`을 명시적으로 거쳐야 합니다."),
          #(2, "case의 두 가지(`[]`, `[first, ..]`)는 리스트를 빠짐없이 다룹니다. 문제는 가지 개수가 아니라 반환 타입입니다 — `Some` 가지와 `Ok` 가지가 섞여 `Option`과 `Result`가 충돌합니다."),
        ],
      ),
    ],
  )
}

fn l_05_b() -> Lesson {
  tlesson(
    "tu05-isomorphism-l02-cardinality-modelling",
    "tu05-isomorphism",
    "카디널리티로 모델링하기",
    [Theory("cardinality-modelling"), Theory("false-isomorphism")],
    [
      tprose(
        "model-illegal",
        "동형의 실전 무기화가 **make-illegal-states-unrepresentable**(U12-③의 재방문)이다. 절차는 단순하다 — (1) 표현하려는 *정당한 상태의 개수*를 세고, (2) 타입의 카디널리티가 정확히 그 수가 되게 만든다. 예: 네트워크 연결을 `#(Bool, Bool)`(\"연결 시도 중?\", \"연결됨?\")로 적으면 카디널리티는 `2 × 2 = 4`지만, 정당한 상태는 셋뿐이다(끊김 / 시도 중 / 연결됨). 4번째 `#(True, True)`(\"시도 중이면서 동시에 연결됨\")는 의미 없는데도 *표현 가능*하다 — 카디널리티가 정당한 상태 수보다 크면, 그 초과분만큼 버그가 들어올 문이 열린다. 컴파일러의 exhaustiveness가 그 초과 카디널리티를 정직하게 드러낸다.\n\n```gleam\nimport gleam/io\n\n// 연결을 #(Bool, Bool)로 모델링하면 의미 없는 4번째 상태까지\n// 다뤄야 한다. exhaustiveness 검사가 초과 카디널리티를 폭로한다.\npub fn describe(state: #(Bool, Bool)) -> String {\n  case state {\n    #(False, False) -> \"off\"\n    #(True, False) -> \"...\"\n    #(False, True) -> \"on\"\n  }\n}\n\npub fn main() -> Nil {\n  io.println(describe(#(False, True)))\n}\n```",
      ),
      tmcq(
        "model-inexhaustive-predict",
        "위 코드는 컴파일될까, 안 될까? 컴파일된다면 출력은?",
        ["`on` 출력", "컴파일 에러(Inexhaustive patterns — 빠진 패턴 `#(True, True)`)", "런타임 크래시"],
        1,
        "컴파일러가 `#(True, True)`를 빠뜨렸다고 정확히 짚어줍니다. 이 '빠진 한 칸'이 바로 `#(Bool, Bool)`의 카디널리티 4 중 정당하지 않은 1입니다 — 타입이 현실보다 한 칸 *큰* 것이죠.",
        [
          #(0, "case가 네 경우 중 셋만 다루므로 Gleam은 *컴파일 자체를 거부*합니다(early return도 없고, '나머지는 알아서' 같은 암묵적 처리도 없음). 빈 칸을 `_ -> ...`로 메우거나 — 더 나은 방법은, 애초에 카디널리티가 3인 타입으로 바꿔 그 칸이 존재하지 못하게 하는 것입니다."),
          #(2, "런타임에 도달하기도 전에 컴파일러가 `#(True, True)`가 빠졌다며 컴파일을 거부합니다. exhaustiveness 검사는 컴파일 타임에 일어납니다."),
        ],
      ),
      tprose(
        "model-fix-and-false",
        "해법은 카디널리티 3짜리 타입, 즉 3-variant 합타입으로 옮기는 것이다 — `#(Bool, Bool)`(4)에서 정당한 3상태만 남긴 `Connection`(3)으로. 이제 `#(True, True)`라는 상태는 *타입에 존재하지 않으므로* 다룰 필요도, 다룰 수도 없다.\n\n```gleam\npub type Connection {\n  Disconnected\n  Connecting\n  Connected\n}\n```\n\n**가짜 동형 주의보**: \"카디널리티가 같다\"는 동형의 *필요조건일 뿐 충분조건이 아니다*. 왕복 항등까지 성립해야 진짜 동형이다. 흔한 함정: `Bool`(2)과 \"0 또는 1인 Int\"를 동형이라 착각하기 — `bool_to_int`은 멀쩡하지만, 그 짝으로 흔히 쓰는 `int_to_bool(n) = n != 0`은 *모든 Int를 받아들인다*. 그래서 `bool_to_int(int_to_bool(7)) = 1 ≠ 7` — Int 쪽에서 출발한 왕복이 제자리로 안 돌아온다. 이건 **손실 변환**이고, 동형이 아니라 한 방향(`Bool -> Int`)만 무손실인 *단사(injection)* 일 뿐이다.\n\n```gleam\npub fn bool_to_int(b: Bool) -> Int {\n  case b {\n    True -> 1\n    False -> 0\n  }\n}\n\npub fn int_to_bool(n: Int) -> Bool {\n  n != 0\n}\n```",
      ),
      tmcq(
        "model-spot-false-iso",
        "네 개의 \"`A ≅ B` 동형이다\"라는 주장 중 **틀린(가짜 동형) 것**을 고르라.",
        ["`Result(a, Nil) ≅ Option(a)` (`Ok↔Some`, `Error(Nil)↔None`)", "`#(a, Nil) ≅ a` (`#(x, Nil)↔x`)", "`Bool ≅ Int` (`bool_to_int` / `int_to_bool(n)=n != 0`)", "`fn(#(a, b)) -> c ≅ fn(a, b) -> c` (uncurry/curry)"],
        2,
        "(다)만 왕복 항등이 깨집니다: `int_to_bool`이 `7`, `2`, `99`를 전부 `True`로 뭉개므로 `bool_to_int ∘ int_to_bool ≠ id`. 카디널리티부터가 다르죠 — `Bool`은 2, `Int`는 (사실상) 무한. 카디널리티가 다르면 애초에 동형일 수 없습니다.",
        [
          #(0, "(가)는 진짜 동형입니다. `Some ↔ Ok`, `None ↔ Error(Nil)`로 1:1 대응되고 카디널리티도 둘 다 `a의 개수 + 1`로 같으며, 양방향 왕복이 제자리로 돌아옵니다. 가짜 동형은 따로 있습니다."),
          #(1, "(나)는 진짜 동형입니다. `Nil`은 카디널리티 1짜리 타입이라 `#(a, Nil)`의 카디널리티는 `a의 개수 × 1 = a의 개수` — `a`와 똑같습니다. `Nil`은 곱셈의 1과 같아서(TU4의 대수 규칙) 정보를 전혀 더하지 않죠. `#(x, Nil) ↔ x` 왕복은 완벽히 제자리입니다."),
          #(3, "(라)도 진짜 동형입니다. Gleam엔 **자동 커링이 없지만**(U14② — `add(10)`은 부분 적용이 아니라 인자 부족 에러, 부분 적용은 캡처 `add(10, _)`로 명시), 두 함수 *모양* 사이의 무손실 변환쌍(`uncurry`/`curry`)은 직접 적을 수 있습니다. '동형이 존재한다'와 '언어가 자동으로 변환해 준다'는 별개입니다 — Gleam은 전자만 인정하고 후자는 명시를 요구합니다."),
        ],
      ),
    ],
  )
}

fn unit_tu05() -> Unit {
  tunit(
    UnitMeta(
      id: "tu05-isomorphism",
      title: "동형과 데이터 모델링",
      order: 5,
      level: 6,
      concepts: [
        Theory("type-isomorphism"),
        Theory("cardinality-modelling"),
        Theory("false-isomorphism"),
      ],
      prerequisites: ["tu04-adt-algebra"],
      lesson_ids: [
        "tu05-isomorphism-l01-what-is-iso",
        "tu05-isomorphism-l02-cardinality-modelling",
      ],
    ),
    [l_05_a(), l_05_b()],
  )
}

// ── tu06-curry-howard ─────────────────────────────────────────────
fn l_06_a() -> Lesson {
  tlesson(
    "tu06-curry-howard-l01-types-as-props",
    "tu06-curry-howard",
    "타입은 명제, 값은 증명",
    [Theory("curry-howard")],
    [
      tprose(
        "ch-prose-1",
        "TU5에서 본 곱타입·합타입에 두 번째 독해가 있습니다. 타입을 **명제**로, 그 타입의 값을 그 명제의 **증명**으로 읽는 것 — 커리-하워드 대응입니다.\n\n사전은 이렇습니다: 곱타입 `#(a, b)`(또는 `And(a, b)`)는 \"a 이고 b\"(∧), 합타입은 \"a 이거나 b\"(∨), 함수 타입 `fn(a) -> b`는 함의 \"a이면 b\". \"그 타입의 값을 *만들 수 있다*\"가 곧 \"그 명제를 *증명할 수 있다*\"입니다. 예컨대 `And(a, b)`에서 좌변을 꺼내는 `proj_left`는 논리식 `(a ∧ b) → a`의 증명입니다.\n\n```gleam\nimport gleam/io\n\n// a×b ↔ ∧ (그리고): 곱타입은 \"a 이고 b\" 의 증명\npub type And(a, b) {\n  And(left: a, right: b)\n}\n\n// a+b ↔ ∨ (또는): 합타입은 \"a 이거나 b\" 의 증명\npub type Or(a, b) {\n  InL(a)\n  InR(b)\n}\n\n// ∧ → 좌변: \"a 이고 b\" 가 증명되면 \"a\" 도 증명된다\npub fn proj_left(p: And(a, b)) -> a {\n  p.left\n}\n\npub fn main() -> Nil {\n  let p = And(left: 1, right: \"two\")\n  assert proj_left(p) == 1\n  io.println(\"ok\")\n}\n```",
      ),
      tpredict(
        "ch-ex-1",
        "위 코드에서 `io.println(\"ok\")`까지 도달하면 출력은 무엇인가?",
        "import gleam/io\n\npub type And(a, b) {\n  And(left: a, right: b)\n}\n\npub fn proj_left(p: And(a, b)) -> a {\n  p.left\n}\n\npub fn main() -> Nil {\n  let p = And(left: 1, right: \"two\")\n  assert proj_left(p) == 1\n  io.println(\"ok\")\n}",
        ["`ok`", "`1`", "`런타임 크래시`"],
        0,
        "`proj_left(p) == 1`이 참이라 `assert`가 통과하고, 마지막 `io.println`이 찍힙니다. 여러분은 방금 `(a ∧ b) → a`라는 명제의 증명을 실행한 셈입니다.",
        [
          #(2, "`assert`는 식이 **거짓일 때만** 크래시합니다. `And(1, \"two\")`의 left는 1이고 `1 == 1`은 참이니 통과합니다 — 증명이 닫혔다는 신호죠."),
        ],
      ),
      tprose(
        "ch-prose-2",
        "양 극단도 사전에 있습니다. **`Nil`(원소 1개) ↔ 참(⊤)**: 언제나 손쉽게 만들 수 있는 자명한 증명이며 정보량은 0입니다(그래서 부수효과 함수의 반환이 흔히 `Nil`). 반대편 **void(원소 0개) ↔ 거짓(⊥)**: 거주자가 *하나도 없는* 타입이라 \"값을 만들 수 없다 = 증명 불가\"를 그대로 인코딩합니다. Gleam에서는 생성자가 0개인 타입 `pub type Void`로 흉내 낼 수 있습니다.\n\n**정직한 단서**: 논리에서 `⊥ → a`(ex falso)는 자명하지만, Gleam 1.17은 거주자 없는 타입의 `case`마저 자동 exhaustive로 인정하지 *않습니다* — `case v {}`는 `Inexhaustive patterns` 에러를 냅니다. 그래서 아래처럼 `_` 한 갈래에 `panic`을 두는데, 이 `panic`은 \"도달 불가라서 안전\"하지만 그 안전을 **컴파일러가 증명해 주지는 않습니다**.\n\n```gleam\nimport gleam/io\n\n// Nil(1) ↔ 참(⊤): 언제나 만들 수 있는 자명한 증명. 정보는 0.\npub fn trivial() -> Nil {\n  Nil\n}\n\n// void(0) ↔ 거짓(⊥): 거주자가 없는 타입. \"값을 만들 수 없다\"는 곧 \"증명 불가\".\npub type Void\n\npub fn absurd(v: Void) -> a {\n  case v {\n    _ -> panic\n  }\n}\n\npub fn main() -> Nil {\n  let _ = trivial()\n  io.println(\"ok\")\n}\n```",
      ),
      tmcq(
        "ch-ex-2",
        "`pub type Void`(생성자 0개)에 대해 옳은 설명은?",
        [
          "`Void` 타입의 값을 정상적으로 만들 방법이 없다 — 명제 ⊥(거짓)에 대응한다",
          "`Void`는 `Nil`과 같다",
          "`absurd`는 `Void` 값으로 아무 `a`나 만들어 주므로 ⊥에서 임의 명제가 진짜로 증명된다",
        ],
        0,
        "거주자가 없으니 `absurd`를 정상 호출할 길도 없습니다. ⊥↔void의 핵심은 바로 이 \"만들 수 없음\"입니다.",
        [
          #(1, "`Nil`은 원소 *1개*(↔참), `Void`는 원소 *0개*(↔거짓)입니다. 정반대 극단이에요."),
          #(2, "함정입니다. `absurd`가 컴파일되는 건 맞지만, 그건 `panic`(런타임 크래시) 덕분이지 컴파일러가 ex falso를 증명한 게 아닙니다. 게다가 `Void` 값 자체를 못 만드니 `absurd`를 호출할 수도 없죠. Gleam은 정리 증명기가 아닙니다."),
        ],
      ),
    ],
  )
}

fn l_06_b() -> Lesson {
  tlesson(
    "tu06-curry-howard-l02-parametricity",
    "tu06-curry-howard",
    "시그니처가 구현을 묶는다 — 파라메트리시티",
    [Theory("parametricity"), Theory("free-theorems"), Theory("parametricity-overclaim")],
    [
      tprose(
        "param-prose-1",
        "제네릭 시그니처는 생각보다 훨씬 많은 것을 *결정합니다*. 함수가 타입 변수 `a`를 받으면 그 함수 안에서는 `a`가 Int인지 String인지 알 길이 없어 — 들여다보거나 새 `a`를 만들 수 없습니다.\n\n그래서 **(순수·전체라고 가정하면)** `fn(a) -> a`의 거주자는 **항등함수 단 하나**, `fn(a, b) -> a`는 **첫 인자를 돌려주는 것**뿐입니다. 이렇게 \"시그니처만 보고 공짜로 따라 나오는 사실\"을 *공짜 정리(free theorem)*라 하며, 그 뿌리가 파라메트리시티입니다.\n\n```gleam\nimport gleam/io\nimport gleam/list\n\n// fn(a) -> a : a 의 구체 정체를 절대 알 수 없으므로 손댈 수 없다.\n// (순수·전체라면) 항등함수가 유일한 거주자.\npub fn id(x: a) -> a {\n  x\n}\n\n// fn(a, b) -> a : 반환 자리에 놓을 수 있는 a 값은 첫 인자뿐.\npub fn const_first(x: a, _y: b) -> a {\n  x\n}\n\n// fn(List(a)) -> List(a) : 원소를 들여다볼 수 없으니 자르고/뒤집고/복제만 가능.\npub fn same_or_rev(xs: List(a)) -> List(a) {\n  list.reverse(xs)\n}\n\npub fn main() -> Nil {\n  assert id(42) == 42\n  assert const_first(1, \"ignored\") == 1\n  assert same_or_rev([1, 2, 3]) == [3, 2, 1]\n  io.println(\"ok\")\n}\n```",
      ),
      tpredict(
        "param-ex-1",
        "본문을 가린 `fn(a, b) -> a` 함수 `mystery`를 `int.to_string(mystery(7, \"hello\"))`로 출력한다. 출력은?",
        "import gleam/io\nimport gleam/int\n\n// 시그니처는 fn(a, b) -> a. 본문은 가렸다. 호출 결과만 예측하라.\npub fn mystery(x: a, _y: b) -> a {\n  x\n}\n\npub fn main() -> Nil {\n  io.println(int.to_string(mystery(7, \"hello\")))\n}",
        ["`7`", "`hello`", "`7hello`"],
        0,
        "시그니처가 답을 알려줍니다. 반환 타입이 `a`(= 첫 인자의 타입)이고, 함수 몸체가 새 `a`를 *지어낼* 수 없으니, 순수·전체라면 돌려줄 수 있는 건 첫 인자 `7`뿐입니다. 본문을 안 봐도 맞힐 수 있죠.",
        [
          #(1, "`hello`는 둘째 인자(타입 `b`)입니다. 반환 타입이 `a`라 `b` 값은 애초에 그 자리에 들어갈 수 없어요 — 들어가면 타입 에러입니다."),
        ],
      ),
      tprose(
        "param-prose-2",
        "공짜 정리는 \"할 수 없는 일\"도 콕 집어 줍니다. 다만 *무엇을* 못 하는지 정확히 말해야 합니다. `fn(List(a)) -> List(a)`가 보장하는 건 **출력에 나타나는 원소는 모두 입력에서 온 것뿐**이라는 사실입니다 — `a`가 뭔지 모르므로 새 `a`를 *지어낼* 수도, `a` 자리에 외부 상수를 *끼워 넣을* 수도 없습니다. 시도해 보면 컴파일러가 막습니다: `[5, ..xs]`는 `5: Int`라 `List(a)`와 충돌해 `Type mismatch`입니다.\n\n**여기서 흔한 과대주장을 정정합니다**: 이 정리는 *길이*에 대해서는 아무것도 말해 주지 않습니다. 원소를 *복제·재배열*하는 건 얼마든지 가능하므로, `list.append(xs, xs)`처럼 길이를 두 배로 늘리는 순수·전체 함수도 **같은 시그니처**를 갖습니다(길이 3 → 6). 즉 \"길이를 절대 늘릴 수 없다\"거나 \"결과는 부분수열·순열뿐\"이라는 말은 *거짓*입니다(append 가 반례). 공짜 정리가 보장하는 건 오직 \"출력 원소의 *출처*가 입력\"이라는 점입니다.\n\n```gleam\nimport gleam/io\nimport gleam/list\n\n// 후보 A: 시그니처 fn(List(a)) -> List(a)\npub fn keep_all(xs: List(a)) -> List(a) {\n  xs\n}\n\n// 후보 B: 같은 시그니처 — 첫 원소를 버린다\npub fn drop_first(xs: List(a)) -> List(a) {\n  case xs {\n    [] -> []\n    [_, ..rest] -> rest\n  }\n}\n\n// 후보 C: 같은 시그니처 — 입력을 두 번 이어붙여 길이를 *늘린다*(복제).\npub fn dup(xs: List(a)) -> List(a) {\n  list.append(xs, xs)\n}\n\npub fn main() -> Nil {\n  let sample = [10, 20, 30]\n  assert keep_all(sample) == [10, 20, 30]\n  assert drop_first(sample) == [20, 30]\n  assert dup(sample) == [10, 20, 30, 10, 20, 30]\n  assert list.length(dup(sample)) == 6\n  io.println(\"세 후보 모두 입력에 없던 원소를 지어내지 못한다 — 단, 길이는 복제로 변할 수 있다\")\n}\n```",
      ),
      tmcq(
        "param-ex-2",
        "아래 세 정의 모두 시그니처 `fn(a) -> a`를 *주장한다*. **공짜 정리(\"항등뿐\")를 위반하는 — 즉 순수·전체였다면 불가능했을 — 코드 하나**를 고르라.",
        [
          "`pub fn f1(x: a) -> a { x }`",
          "`pub fn f2(x: a) -> a { let assert [_] = [x] x }`",
          "`pub fn f3(_x: a) -> a { io.println(\"부수효과!\") panic as \"값을 안 돌려준다\" }`",
        ],
        2,
        "(C)는 같은 시그니처를 달았지만 부수효과를 내고 결국 값을 돌려주지 않습니다(panic). 시그니처만 보면 (A)와 구별이 안 되죠 — 이게 핵심입니다. 그래서 \"`fn(a) -> a`는 항등뿐\"은 무조건 참이 아니라 **\"순수하고 전체(total)라면\"**이라는 단서가 붙습니다. Gleam은 totality·순수성을 강제하지 않으므로 (C) 같은 시그니처도 컴파일됩니다.",
        [
          #(0, "(A)는 글자 그대로 항등함수입니다. 공짜 정리를 위반하기는커녕 정확히 그 정리가 말하는 유일한 거주자입니다."),
          #(1, "(B)는 우회로가 지저분하지만 `let assert`가 통과하면 결국 `x`를 그대로 돌려줍니다. 외부 관측상 항등과 같아요. 정작 약속을 깨는 건 (C)입니다."),
        ],
      ),
    ],
  )
}

fn unit_tu06() -> Unit {
  tunit(
    UnitMeta(
      id: "tu06-curry-howard",
      title: "커리-하워드와 파라메트리시티",
      order: 6,
      level: 6,
      concepts: [
        Theory("curry-howard"),
        Theory("parametricity"),
        Theory("free-theorems"),
        Theory("parametricity-overclaim"),
      ],
      prerequisites: ["tu04-adt-algebra", "tu05-isomorphism"],
      lesson_ids: [
        "tu06-curry-howard-l01-types-as-props",
        "tu06-curry-howard-l02-parametricity",
      ],
    ),
    [l_06_a(), l_06_b()],
  )
}

// ── tu07-composition ─────────────────────────────────────────────
fn l_07_a() -> Lesson {
  tlesson(
    "tu07-composition-l01-compose",
    "tu07-composition",
    "합성은 FP의 곱셈이다",
    [Theory("composition"), Theory("composition-order")],
    [
      tprose(
        "compose-intro",
        "함수 합성은 \"한 함수의 출력을 다음 함수의 입력으로\" 잇는 기본 연산이다. 수학 기호로 `(f ∘ g)(x) = f(g(x))` — **g가 먼저** 돈다. Gleam에는 합성 연산자(`>>` 같은 것)도, stdlib `compose`도 **없다**. 그래서 우리가 직접 짓는다. 짓고 나면 정체가 드러난다: U2의 파이프 `x |> g |> f` 가 사실 같은 합성을 *값 우선*으로 쓴 것일 뿐이다.\n\n```gleam\nimport gleam/io\nimport gleam/int\n\n// Gleam has no `>>` operator and no `compose` in stdlib — we write it.\npub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {\n  fn(x) { f(g(x)) }\n}\n\nfn inc(x: Int) -> Int { x + 1 }\nfn double(x: Int) -> Int { x * 2 }\n\npub fn main() -> Nil {\n  let inc_after_double = compose(inc, double)\n  assert inc_after_double(5) == 11\n  // compose(f, g) and x |> g |> f compute the same thing:\n  assert inc_after_double(5) == { 5 |> double |> inc }\n  io.println(int.to_string(inc_after_double(5)))\n}\n```\n\n여기서 정직하게 한 가지 짚는다. 이 `compose`는 **평범한 함수 `fn(a) -> b` 위에서만** 일반적이다. \"모든 Functor/Monad를 잇는 단 하나의 합성\"은 Gleam에 타입클래스도 고계 타입(HKT)도 없어서 **작성할 수 없다**. 합성·항등은 *언어 기능*이 아니라 여러 구체 타입에서 우리가 *알아보는 패턴*이다.",
      ),
      tpredict(
        "compose-order-predict",
        "위 코드에서 `compose(inc, double)` 대신 `compose(double, inc)(5)`의 값은?",
        "compose(double, inc)(5)",
        ["`11`", "`12`", "`7`"],
        1,
        "`compose(f, g)`는 g를 먼저 돌립니다. `compose(double, inc)`는 inc 먼저 → `5+1=6` → `6*2=12`. 같은 두 함수라도 순서를 바꾸면 결과가 다릅니다 — 합성은 교환법칙이 성립하지 **않습니다**.",
        [
          #(
            0,
            "`11`은 `compose(inc, double)`의 값입니다. double을 먼저(=`5*2=10`) 돌린 뒤 inc(=`11`). 두 호출의 인자 순서가 뒤바뀐 걸 못 보신 겁니다 — `compose`의 첫 인자가 *나중에* 실행되는 함수라는 비대칭에 주의하세요.",
          ),
        ],
      ),
      tprose(
        "pipe-vs-compose",
        "그렇다면 파이프와 `compose`는 무슨 관계인가? `x |> g |> f` 는 g 먼저, 왼쪽→오른쪽으로 **읽는 순서 = 실행 순서**다. 반면 수학식 `f ∘ g`(우리 `compose(f, g)`)는 g 먼저 실행이지만 **읽는 순서는 반대**(왼쪽 f가 나중 실행). 즉 `compose(f, g)(x)` ≡ `x |> g |> f`. 같은 계산을 두 방향으로 적은 것뿐이다. 트리키한 건 정확히 이 \"읽기 방향 ↔ 실행 방향\" 어긋남이다.\n\n```gleam\nfn inc(x: Int) -> Int { x + 1 }\nfn double(x: Int) -> Int { x * 2 }\n\npub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {\n  fn(x) { f(g(x)) }\n}\n\npub fn main() -> Nil {\n  io.println(int.to_string(3 |> inc |> double))        // inc 먼저: 4 -> 8\n  io.println(int.to_string(compose(double, inc)(3)))   // inc 먼저: 4 -> 8\n  io.println(int.to_string(compose(inc, double)(3)))   // double 먼저: 6 -> 7\n}\n```",
      ),
      tmcq(
        "pipe-to-compose-mcq",
        "등식을 보존하며 재작성하세요. 파이프 표현 `fn(x) { x |> double |> inc }`와 모든 입력에서 같은 값을 내는 점-자유 스타일의 합성은? (빈칸: `let step2 = compose(???, ???)`)",
        ["`compose(inc, double)`", "`compose(double, inc)`", "`compose(double, inc)(x)`"],
        0,
        "파이프는 `double` 먼저 → `inc`. 같은 실행 순서를 `compose`로 적으려면 *나중에 도는 함수를 앞에* 둡니다: `compose(inc, double)`. 읽는 순서가 뒤집힌다는 게 이 유닛의 핵심 반사신경입니다.",
        [
          #(
            1,
            "그건 `x |> inc |> double`과 같습니다 — inc가 먼저 돕니다. 파이프 `|> double |> inc`의 실행 순서(double→inc)를 `compose`로 옮기면 *역순*으로 적어야 해서 `compose(inc, double)`이 됩니다. 앞 연습에서 본 비교환성과 같은 함정입니다.",
          ),
          #(
            2,
            "재작성 목표는 *함수 값* 하나(`fn(Int) -> Int`)입니다. `(x)`를 붙이면 값이 되어버려 점-자유 스타일이 아닙니다 — 인자 `x`는 받지 말고 합성만 돌려주세요.",
          ),
        ],
      ),
    ],
  )
}

fn l_07_b() -> Lesson {
  tlesson(
    "tu07-composition-l02-laws",
    "tu07-composition",
    "두 법칙: 항등원과 결합법칙",
    [Theory("identity-law"), Theory("composition-associativity")],
    [
      tprose(
        "identity-law-intro",
        "합성에는 곱셈의 `1`에 해당하는 **항등원**이 있다 — `function.identity`(`fn(x) { x }`). 항등 법칙: `id ∘ f == f == f ∘ id`. 앞에 붙이든 뒤에 붙이든 아무것도 안 한다. 이건 단순한 사실이 아니라 *법칙*이고, 우리는 법칙을 **실행 가능한 프로퍼티**로 표본 검사할 수 있다 — `assert`로 여러 입력에서 등식이 성립하는지 본다.\n\n```gleam\nimport gleam/io\nimport gleam/list\nimport gleam/function\n\npub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {\n  fn(x) { f(g(x)) }\n}\n\nfn double(x: Int) -> Int { x * 2 }\nfn inc(x: Int) -> Int { x + 1 }\n\n// Law as an executable property: identity law sampled over inputs.\nfn check_identity_law(f: fn(Int) -> Int, samples: List(Int)) -> Bool {\n  let id = function.identity\n  list.all(samples, fn(x) {\n    compose(id, f)(x) == f(x) && compose(f, id)(x) == f(x)\n  })\n}\n\npub fn main() -> Nil {\n  let samples = [-2, 0, 1, 5, 100]\n  assert check_identity_law(double, samples)\n  assert check_identity_law(inc, samples)\n  io.println(\"laws hold\")\n}\n```",
      ),
      tmcq(
        "identity-law-spot-bug",
        "아래 네 개의 \"항등 법칙 시연\" 중 **법칙을 잘못 주장하는** 것을 고르세요.",
        [
          "`compose(function.identity, f)(x) == f(x)`",
          "`compose(f, function.identity)(x) == f(x)`",
          "`function.identity(f(x)) == f(x)`",
          "`compose(f, g)(x) == compose(g, f)(x)`",
        ],
        3,
        "(d)는 *교환법칙*이고, 합성에는 성립하지 않습니다(이전 레슨 P1에서 확인). (a)(b)는 항등 법칙의 양변, (c)는 `identity`의 정의 그 자체로 모두 참입니다.",
        [
          #(
            1,
            "(b)는 참입니다 — `f ∘ id`. 오른쪽에 `id`를 붙여도 입력이 그대로 f로 들어가니 `f`와 같습니다. 항등 법칙은 *왼쪽이든 오른쪽이든* 성립한다는 게 요점입니다.",
          ),
          #(
            2,
            "(c)는 `identity`의 정의 자체입니다(`identity(y) == y`이므로 `y = f(x)`를 넣으면 참). 법칙 위반이 아닙니다 — 위반은 교환을 가정한 (d)뿐입니다.",
          ),
        ],
      ),
      tprose(
        "associativity-intro",
        "두 번째 법칙은 **결합법칙**: `(f ∘ g) ∘ h == f ∘ (g ∘ h)`. 셋을 이을 때 괄호를 어디 치든 결과가 같다 — 그래서 우리는 보통 괄호를 *생략*하고 `f ∘ g ∘ h`라 쓴다(파이프 체인 `|> h |> g |> f`가 평평하게 읽히는 이유이기도 하다). 항등 + 결합, 이 두 법칙이 성립하는 \"대상=타입, 사상=함수\" 세계를 수학에서 **카테고리(category)**라 부른다. 이름만 알아두면 된다 — 우리가 깊이 들어가진 않는다. 중요한 건 이 *두 법칙이 곧 이후 functor/monad 법칙의 모태*라는 점이다(functor가 합성과 항등을 보존한다는 게 functor 법칙의 전부다).\n\n```gleam\npub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {\n  fn(x) { f(g(x)) }\n}\n\nfn inc(x: Int) -> Int { x + 1 }\nfn double(x: Int) -> Int { x * 2 }\nfn square(x: Int) -> Int { x * x }\n\n// Associativity sampled as an executable property.\nfn check_assoc(f, g, h, samples: List(Int)) -> Bool {\n  list.all(samples, fn(x) {\n    compose(compose(f, g), h)(x) == compose(f, compose(g, h))(x)\n  })\n}\n```",
      ),
      tpredict(
        "assoc-predict",
        "`compose(compose(inc, double), inc)(3)` 의 값은? (`inc(x)=x+1`, `double(x)=x*2`)",
        "compose(compose(inc, double), inc)(3)",
        ["`9`", "`10`", "`8`"],
        0,
        "가장 안쪽 인자부터: `inc(3)=4` → `double(4)=8` → `inc(8)=9`. 결합법칙 덕분에 `compose(inc, compose(double, inc))(3)`로 괄호를 옮겨도 똑같이 `9`가 나옵니다 — 그게 이 레슨에서 시연한 프로퍼티입니다.",
        [
          #(
            1,
            "`10`은 `double(inc(inc(3)))` 같은 순서를 떠올렸을 때 나오는 값입니다. `compose`의 첫 인자가 *바깥쪽(나중 실행)*이라는 비대칭을 다시 확인하세요: `compose(F, G)`는 G부터, 여기선 가장 안쪽 `inc`가 맨 먼저 돕니다.",
          ),
          #(
            2,
            "`8`은 마지막 `inc`를 빠뜨린 값(`double(inc(3))`)입니다. 합성이 셋이면 함수도 셋 모두 한 번씩 적용됩니다.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu07() -> Unit {
  tunit(
    UnitMeta(
      id: "tu07-composition",
      title: "합성과 항등",
      order: 7,
      level: 7,
      concepts: [
        Theory("composition"),
        Theory("identity-law"),
        Theory("composition-associativity"),
        Theory("composition-order"),
      ],
      prerequisites: [],
      lesson_ids: ["tu07-composition-l01-compose", "tu07-composition-l02-laws"],
    ),
    [l_07_a(), l_07_b()],
  )
}

// ── tu08-monoid ─────────────────────────────────────────────
fn l_08_a() -> Lesson {
  tlesson(
    "tu08-monoid-l01-op-and-e",
    "tu08-monoid",
    "같은 모양 두 개를 하나로 — ⊕와 e",
    [Theory("monoid"), Theory("monoid-fold")],
    [
      tprose(
        "l01-s1",
        "모노이드는 거창한 게 아니라 **세 가지 묶음**이다 — 어떤 타입 `T`, 같은 타입 두 개를 하나로 합치는 이항연산 `⊕ : (T, T) -> T`, 그리고 \"아무것도 더하지 않음\"에 해당하는 **항등원** `e : T`. 당신은 이미 여럿을 안다: `(Int, +, 0)`, `(Int, *, 1)`, `(String, <>, \"\")`, `(List, append, [])`. \"두 개를 합쳐 같은 종류 하나가 나온다 + 합칠 게 없을 때의 기본값이 있다\"가 핵심 직관이다.\n\n```gleam\nimport gleam/list\n\n// (List, append, []) 가 모노이드라는 사실을 fold 로 \"요약\"\npub fn concat(xss: List(List(a))) -> List(a) {\n  list.fold(xss, [], fn(acc, xs) { list.append(acc, xs) })\n}\n// concat([[1, 2], [3], [4, 5]]) == [1, 2, 3, 4, 5]\n```",
      ),
      tpredict(
        "l01-p1",
        "`concat([[1, 2], [3], [4, 5]])`의 값은?",
        "concat([[1, 2], [3], [4, 5]])",
        ["`[1, 2, 3, 4, 5]`", "`[[1, 2], [3], [4, 5]]`", "`[5, 4, 3, 2, 1]`"],
        0,
        "`⊕ = list.append`, `e = []`로 왼쪽부터 접으면 모든 조각이 순서대로 한 리스트로 평탄화됩니다 — 이게 '모노이드로 요약'의 가장 시각적인 예.",
        [
          #(2, "그건 `[x, ..acc]`(prepend)로 접었을 때의 뒤집힘 현상(U8-④, `acc-reverse`)입니다. 여기서 `⊕`는 prepend가 아니라 `list.append`이고, append는 순서를 보존합니다."),
        ],
      ),
      tprose(
        "l01-s2",
        "`Bool`도 두 가지 방식으로 모노이드다 — `(Bool, &&, True)`와 `(Bool, ||, False)`. 항등원을 고르는 감각: `e ⊕ a == a`가 성립하려면 e가 \"결과를 바꾸지 않는 중립값\"이어야 한다. `&&`에서는 `True && a == a`이므로 항등원이 `True`, `||`에서는 `False || a == a`이므로 `False`다. 같은 타입이라도 **연산이 바뀌면 항등원도 바뀐다**.\n\n```gleam\nimport gleam/list\n\npub fn all_true(xs: List(Bool)) -> Bool {\n  list.fold(xs, True, fn(acc, b) { acc && b })\n}\n\npub fn any_true(xs: List(Bool)) -> Bool {\n  list.fold(xs, False, fn(acc, b) { acc || b })\n}\n// all_true([True, True, False]) == False\n// any_true([False, False, True]) == True\n```",
      ),
      tmcq(
        "l01-p2",
        "다음 중 항등원 짝이 **잘못** 연결된 것은?",
        ["`(Int, +) → 0`", "`(Int, *) → 1`", "`(String, <>) → \"\"`", "`(Bool, &&) → False`"],
        3,
        "`False && a`는 항상 `False`라 a를 통째로 삼켜버립니다 — 그건 항등원이 아니라 *흡수원*(zero)이죠. 올바른 항등원은 `True`입니다.",
        [
          #(1, "`1 * a == a`라서 곱셈의 항등원은 1이 맞습니다. 덧셈의 0과 자리만 다를 뿐 정확히 같은 역할입니다. 다음 레슨에서 '곱셈에 0을 항등으로 쓰면?'이라는 함정을 직접 봅니다."),
        ],
      ),
    ],
  )
}

fn l_08_b() -> Lesson {
  tlesson(
    "tu08-monoid-l02-laws-as-properties",
    "tu08-monoid",
    "법칙은 실행 가능한 프로퍼티다",
    [Theory("monoid-laws"), Theory("monoid-fold")],
    [
      tprose(
        "l02-s1",
        "모노이드가 **법칙을 따른다**는 말은 추상적 약속이 아니라 **참이어야 하는 등식**이다. 두 가지뿐: **결합법칙** `a ⊕ (b ⊕ c) == (a ⊕ b) ⊕ c`, **좌·우 항등** `e ⊕ a == a == a ⊕ e`. Gleam엔 프로퍼티 테스트 프레임워크가 stdlib에 없지만, TU1에서 본 참조 투명성 덕에 우리는 법칙을 **표본 입력에 대해 `assert`로 직접 실행**해 볼 수 있다 — 법칙이 \"보이는\" 순간이다. 다만 정직하게 짚자: **표본 `assert`는 법칙을 *증명*하지 않는다.** 그것은 특정 입력에서의 *반증 시도*(프로퍼티 테스트의 축소판)에 가깝다.\n\n```gleam\nimport gleam/io\nimport gleam/list\nimport gleam/int\n\nfn op(a: Int, b: Int) -> Int {\n  a + b\n}\n\nfn empty() -> Int {\n  0\n}\n\npub fn main() -> Nil {\n  let a = 5\n  let b = 8\n  let c = 13\n  // 결합법칙: 묶는 순서를 바꿔도 결과가 같다\n  assert op(a, op(b, c)) == op(op(a, b), c)\n  // 좌 항등 / 우 항등\n  assert op(empty(), a) == a\n  assert op(a, empty()) == a\n  io.println(\"monoid sample checks passed for (Int, +, 0)\")\n  io.println(int.to_string(list.fold([1, 2, 3], empty(), op)))\n}\n// 출력:\n// monoid sample checks passed for (Int, +, 0)\n// 6\n```",
      ),
      tpredict(
        "l02-p1",
        "위 `main`의 출력은 무엇인가?",
        "pub fn main() -> Nil {\n  let a = 5\n  let b = 8\n  let c = 13\n  assert op(a, op(b, c)) == op(op(a, b), c)\n  assert op(empty(), a) == a\n  assert op(a, empty()) == a\n  io.println(\"monoid sample checks passed for (Int, +, 0)\")\n  io.println(int.to_string(list.fold([1, 2, 3], empty(), op)))\n}",
        ["두 줄: `monoid sample checks passed for (Int, +, 0)` 와 `6`", "Assertion failed로 크래시", "`6` 한 줄만 출력"],
        0,
        "세 `assert`가 이 표본에서 모두 통과(법칙을 반증하지 못함)했으므로 크래시 없이 두 `io.println`에 도달합니다. `op`는 시그니처가 `fn(Int, Int) -> Int`라 fold 콜백 `fn(acc, x)` 자리에 *그대로* 들어갑니다.",
        [
          #(1, "`(Int, +, 0)`은 진짜 모노이드라 이 표본 검사를 통과합니다. `assert`가 터지는 건 법칙이 *깨질* 때(반례를 만났을 때)인데, 그 경우를 레슨 ④에서 봅니다 — 정직성: Gleam에는 예외가 없으므로 실패한 `assert`는 *반환*하는 게 아니라 프로그램을 **크래시**시킵니다."),
        ],
      ),
      tprose(
        "l02-s2",
        "정직성 한 단락 — **Gleam에는 Monoid 타입클래스가 없다.** 위 `op`/`empty`는 \"이 타입이 Monoid임을 컴파일러에 등록하는\" 선언이 **아니다**. 단지 우리가 손으로 만든 보통 함수일 뿐이고, fold에 `e`와 `⊕`를 **직접 넘긴다**. Gleam엔 타입클래스도 HKT도 없어서 \"모든 모노이드에 동작하는 단 하나의 일반 `mconcat`\"은 **작성할 수 없다** — 타입마다 `e`와 `⊕`를 그때그때 fold에 넘기는 게 관용이다. 핵심 패턴은 하나다: **같은 fold 골격에 (e, ⊕)만 갈아 끼운다.**\n\n```gleam\nimport gleam/list\nimport gleam/string\n\npub fn sum(xs: List(Int)) -> Int {\n  list.fold(xs, 0, fn(acc, x) { acc + x })\n}\n\npub fn product(xs: List(Int)) -> Int {\n  list.fold(xs, 1, fn(acc, x) { acc * x })\n}\n\npub fn join_all(xs: List(String)) -> String {\n  list.fold(xs, \"\", fn(acc, s) { acc <> s })\n}\n\n// 구분자가 필요하면 stdlib 의 string.join 도 같은 '모노이드 요약'의 변주다\npub fn join_csv(xs: List(String)) -> String {\n  string.join(xs, \", \")\n}\n// sum([1, 2, 3, 4]) == 10\n// product([1, 2, 3, 4]) == 24\n// join_all([\"a\", \"b\", \"c\"]) == \"abc\"\n// join_csv([\"a\", \"b\", \"c\"]) == \"a, b, c\"\n```",
      ),
      tmcq(
        "l02-p2",
        "위 `sum`을 \"등식을 보존하며\" 같은 골격으로 옮기려 한다. `sum`의 초기값 `e`를 `0`에서 `1`로 바꾸면 어떻게 되는가?",
        ["`sum([]) == 1`이 되어 등식이 깨진다", "합은 그대로라 아무 문제 없다", "컴파일 에러가 난다"],
        0,
        "`e`는 결합 함수에 따라 정해진 *항등원*입니다. `+`의 항등은 `0`이라 `e`를 `1`로 바꾸면 `sum([]) == 1`이 되어 등식이 깨집니다. 재작성은 *값을 보존*해야 하므로 골격을 옮길 때 `(e, ⊕)` 짝을 통째로 함께 옮겨야 합니다.",
        [
          #(1, "아니요 — 빈 리스트에서 드러납니다. `e`를 `1`로 바꾸면 `sum([]) == 1`이 되어 `+`의 항등원(`0`)이 아니게 되고 등식이 깨집니다. 바뀌는 건 *어디서 (e, ⊕)를 고르느냐*뿐, `(e, ⊕)` 짝은 통째로 함께 옮겨야 합니다."),
          #(2, "타입은 그대로 `Int`라 컴파일은 됩니다 — 문제는 *값*입니다. `e`를 `1`로 바꾸면 `sum([]) == 1`이 되어 등식이 깨집니다."),
        ],
      ),
    ],
  )
}

fn unit_tu08() -> Unit {
  tunit(
    UnitMeta(
      id: "tu08-monoid",
      title: "모노이드",
      order: 8,
      level: 7,
      concepts: [Theory("monoid"), Theory("monoid-laws"), Theory("monoid-fold")],
      prerequisites: ["tu07-composition", "tu02-equational"],
      lesson_ids: ["tu08-monoid-l01-op-and-e", "tu08-monoid-l02-laws-as-properties"],
    ),
    [l_08_a(), l_08_b()],
  )
}

// ── tu09-functor ─────────────────────────────────────────────
fn l_09_a() -> Lesson {
  tlesson(
    "tu09-functor-l01-shape",
    "tu09-functor",
    "map의 한 가지 모양",
    [Theory("functor"), Theory("functor-instances"), Theory("no-hkt")],
    [
      tprose(
        "shape-intro",
        "U8에서 `list.map`을, U9에서 `option.map`·`result.map`을 따로따로 배웠다. 이제 셋을 나란히 놓고 보면 **같은 모양**이 보인다 — \"감싸진 구조(`List`/`Option`/`Result`)는 그대로 두고, 안의 *내용물에만* 함수를 적용한다\". 리스트는 길이가 안 변하고, `Some`은 `Some`인 채, `Ok`는 `Ok`인 채로 값만 바뀐다. 이 \"구조 보존 + 내용물 변환\" 모양을 **펑터(functor)**라 부른다. 펑터는 *타입클래스나 인터페이스가 아니라*, 여러 구체 타입에서 반복적으로 **알아보는 패턴**이다.\n\n```gleam\nimport gleam/int\nimport gleam/list\nimport gleam/option.{type Option, None, Some}\nimport gleam/result\n\npub fn shapes() -> #(List(Int), Option(Int), Result(Int, Nil)) {\n  let xs = list.map([1, 2, 3], fn(x) { x * 10 })\n  let o = option.map(Some(5), fn(x) { x * 10 })\n  let r = result.map(Ok(7), fn(x) { x * 10 })\n  #(xs, o, r)\n}\n// shapes() == #([10, 20, 30], Some(50), Ok(70))\n```",
      ),
      tpredict(
        "shape-predict",
        "`option.map(Some(10), fn(x) { x + 5 })`와 `option.map(None, fn(x: Int) { x + 5 })`의 값은?",
        "import gleam/option.{None, Some}\n\npub fn run() -> #(option.Option(Int), option.Option(Int)) {\n  let a = option.map(Some(10), fn(x) { x + 5 })\n  let b = option.map(None, fn(x: Int) { x + 5 })\n  #(a, b)\n}",
        ["`Some(15)` / `None`", "`Some(15)` / `Some(0)`", "`15` / `None`"],
        0,
        "구조 보존이 핵심입니다 — `Some`은 `Some`으로, `None`은 `None`으로 남고, 함수는 *내용물이 있을 때만* 적용됩니다.",
        [
          #(
            1,
            "`None`에는 적용할 내용물이 없습니다. map의 함수는 *호출되지 않고* `None`이 그대로 통과합니다 — 이 단락(short-circuit) 동작이 바로 펑터가 '구조'를 존중한다는 뜻입니다.",
          ),
          #(
            2,
            "map은 절대 포장을 벗기지 않습니다. `Some(15)`를 돌려주지 맨몸 `15`를 주지 않아요 — U9에서 'Result/Option의 값은 맨몸으로 안 나온다'고 했던 그 규칙이 여기서도 그대로입니다. 꺼내려면 `case`나 `option.unwrap`이 따로 필요합니다.",
          ),
        ],
      ),
      tprose(
        "shape-nohkt",
        "세 호출의 *함수 인자*(`fn(x) { x * 10 }`)는 똑같다. 다른 건 어느 모듈의 `map`을 부르느냐뿐이다. 여기서 정직한 사실: **Gleam에는 `Functor` 타입클래스도 고계 타입(HKT)도 없다**. 그래서 \"어떤 펑터든 받는 단일 `map`\"을 쓸 수 없고, 타입마다 `list.map`/`option.map`/`result.map`을 *각각* 불러야 한다. 펑터는 \"구현하는 인터페이스\"가 아니라 머릿속에서 \"알아보는 패턴\"이다.\n\n```gleam\nimport gleam/list\n\n// \"아무 펑터에나 동작하는 단일 map\"을 시도하면…\n// 컨테이너 타입 자체를 타입변수 f 로 두고 f(a) 라고 적어야 하는데,\n// Gleam에는 HKT가 없어 타입변수를 다른 타입에 적용(f(a))할 수 없다.\npub fn generic_map(container: f(a), fun: fn(a) -> b) -> f(b) {\n  list.map(container, fun)\n}\n```",
      ),
      tmcq(
        "shape-generic-map",
        "위 `generic_map`을 컴파일하면 어떻게 되나?",
        [
          "정상 컴파일",
          "Syntax error — `f(a)`에서 `(`를 기대하지 않았다",
          "Type mismatch",
          "런타임 크래시",
        ],
        1,
        "`f(a)`는 '타입변수를 타입에 적용'하는 표현인데, 그건 고계 타입(HKT)이고 Gleam엔 없습니다. 파서가 타입 인자 자리에서 `(`를 만나 거기서 막힙니다.",
        [
          #(
            0,
            "다른 언어(Haskell의 `Functor f => f a -> f b`)라면 가능합니다. Gleam은 의도적으로 HKT를 빼서 '혼란스러운 에러 메시지·긴 컴파일 시간·런타임 비용'을 피합니다. 대가는 타입마다 map을 따로 부르는 약간의 반복이고, 보상은 단순함입니다.",
          ),
          #(
            2,
            "타입이 안 맞아서가 아니라 *문장 자체가 문법이 아니라서* 막힙니다 — 타입 검사 단계까지 가지도 못합니다.",
          ),
        ],
      ),
    ],
  )
}

fn l_09_b() -> Lesson {
  tlesson(
    "tu09-functor-l02-laws",
    "tu09-functor",
    "펑터 법칙 둘",
    [Theory("functor-laws"), Theory("functor-law-violation"), Theory("functor")],
    [
      tprose(
        "laws-intro",
        "어떤 `map`이 '진짜 펑터'이려면 두 법칙을 지켜야 한다. ① **항등(identity)**: `map(x, identity) == x` — 아무것도 안 하는 함수로 매핑하면 원본 그대로. ② **합성(composition)**: `map(map(x, g), f) == map(x, fn(a) { f(g(a)) })` — \"두 번 매핑 = 합성한 함수로 한 번 매핑\". 법칙은 추상적 약속이 아니라 **실행 가능한 프로퍼티**다 — `main` 안에서 표본 입력에 `assert`로 직접 검사할 수 있다.\n\n```gleam\nimport gleam/io\nimport gleam/list\nimport gleam/option.{None, Some}\nimport gleam/function\n\npub fn main() -> Nil {\n  // 항등 법칙: map(x, identity) == x\n  assert list.map([1, 2, 3], function.identity) == [1, 2, 3]\n  assert option.map(Some(7), function.identity) == Some(7)\n  assert option.map(None, function.identity) == None\n\n  // 합성 법칙: map(map(x, g), f) == map(x, fn(a) { f(g(a)) })\n  let g = fn(n: Int) { n + 1 }\n  let f = fn(n: Int) { n * 10 }\n  assert list.map(list.map([1, 2], g), f) == list.map([1, 2], fn(a) { f(g(a)) })\n\n  io.println(\"all functor laws hold on the sample\")\n}\n// 출력: all functor laws hold on the sample\n```",
      ),
      tpredict(
        "laws-predict",
        "위 `main`을 실행하면 stdout에 무엇이 찍히나?",
        "import gleam/io\nimport gleam/list\nimport gleam/option.{None, Some}\nimport gleam/function\n\npub fn main() -> Nil {\n  assert list.map([1, 2, 3], function.identity) == [1, 2, 3]\n  assert option.map(Some(7), function.identity) == Some(7)\n  assert option.map(None, function.identity) == None\n\n  let g = fn(n: Int) { n + 1 }\n  let f = fn(n: Int) { n * 10 }\n  assert list.map(list.map([1, 2], g), f) == list.map([1, 2], fn(a) { f(g(a)) })\n\n  io.println(\"all functor laws hold on the sample\")\n}",
        ["`all functor laws hold on the sample`", "런타임 에러(assert 실패)", "아무것도 안 찍힘"],
        0,
        "모든 `assert`가 `True`라 아무도 안 멈추고, 마지막 `println`까지 도달합니다 — `list.map`과 `option.map`은 둘 다 펑터 법칙을 지킵니다. (합성 법칙은 좌변 `[(1+1)*10, (2+1)*10] = [20, 30]`, 우변도 `[20, 30]`로 일치.)",
        [
          #(
            1,
            "stdlib의 `map`들은 법칙을 만족하도록 구현돼 있어 표본 검사가 통과합니다. assert가 깨지는 건 *법칙을 어긴 가짜 map*을 검사할 때고, 그건 다음 레슨에서 사냥합니다.",
          ),
          #(
            2,
            "assert가 모두 통과하면 마지막 `io.println`이 실행되어 한 줄이 찍힙니다 — 중간에 멈출 이유가 없습니다.",
          ),
        ],
      ),
      tprose(
        "laws-box",
        "이 법칙은 직접 만든 펑터에도 똑같이 요구된다. `Box(a)` 위의 `map_box`도 펑터다 — 같은 두 법칙을 `Box`에 대해 표본 검사할 수 있다. (정직성: 이 검사도 `Box`용으로 *손으로* 작성해야 한다 — '모든 펑터의 법칙을 한 번에 검사하는' 일반 함수는 HKT가 없어 못 만든다.)\n\n```gleam\nimport gleam/function\n\npub type Box(a) {\n  Box(inner: a)\n}\n\npub fn map_box(box: Box(a), f: fn(a) -> b) -> Box(b) {\n  Box(f(box.inner))\n}\n\npub fn map_box_obeys_identity(b: Box(Int)) -> Bool {\n  map_box(b, function.identity) == b\n}\n// map_box_obeys_identity(Box(0)) == True\n```",
      ),
      tmcq(
        "laws-write-fn",
        "`pub fn map_box_obeys_identity(b: Box(Int)) -> Bool`을 작성한다 — 임의의 `Box(Int)`에 항등 법칙(`map_box(b, identity) == b`)이 성립하는지 돌려준다. `Box(0)`/`Box(-3)`/`Box(99)`에 모두 `True`를 기대한다. 올바른 본문은?",
        [
          "`map_box(b, b.inner)`",
          "`map_box(b, function.identity) == b`",
          "`map_box(b, function.identity) == b.inner`",
          "`identity(b) == b`",
        ],
        1,
        "`map_box(b, function.identity) == b` 한 줄이면 됩니다 — 법칙은 곧 코드입니다. 이렇게 법칙을 실행 가능한 프로퍼티로 적어 두면, 나중에 누가 `map_box`를 '최적화'하다 망가뜨려도 이 검사가 잡아냅니다.",
        [
          #(
            0,
            "`map_box`의 둘째 인자는 *함수*여야 합니다. `b.inner`는 `Int` 값이지 `fn(a) -> b`가 아니라 타입이 안 맞습니다.",
          ),
          #(
            2,
            "양변의 타입을 맞추세요. `map_box`의 결과는 `Box(Int)`이지 `Int`가 아닙니다 — 펑터 법칙은 항상 *구조째로* 비교합니다.",
          ),
          #(
            3,
            "법칙은 `map_box`를 *통과시킨* 결과를 원본과 비교해야 의미가 있습니다. `identity(b)`는 map을 거치지 않으니 `map_box`가 구조를 보존하는지 전혀 검사하지 못합니다.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu09() -> Unit {
  tunit(
    UnitMeta(
      id: "tu09-functor",
      title: "펑터 패턴",
      order: 9,
      level: 7,
      concepts: [
        Theory("functor"),
        Theory("functor-laws"),
        Theory("functor-instances"),
        Theory("no-hkt"),
      ],
      prerequisites: ["tu07-composition"],
      lesson_ids: ["tu09-functor-l01-shape", "tu09-functor-l02-laws"],
    ),
    [l_09_a(), l_09_b()],
  )
}

// ── tu10-monad ─────────────────────────────────────────────
fn l_10_a() -> Lesson {
  tlesson(
    "tu10-monad-l01-applicative",
    "tu10-monad",
    "독립인 두 맥락을 결합하기 (애플리커티브)",
    [Theory("applicative")],
    [
      tprose(
        "ap-intro",
        "TU9에서 `result.map(r, f)`는 맥락(`Result`) 한 겹을 *보존*하며 안의 값 하나를 변환했다(펑터). 그런데 입력이 **두 개**고 둘 다 맥락에 싸여 있다면? `parse_age(a)`와 `parse_age(b)`는 **서로를 보지 않는 독립적인 두 계산**이다. 이렇게 \"독립인 여러 맥락을 모아 하나로 조립\"하는 패턴이 애플리커티브다. Gleam에 `Applicative` 타입클래스는 없으므로, 우리는 그 패턴을 **두 Result를 동시에 `case`로 까서** 직접 손으로 표현한다.\n\n```gleam\nimport gleam/int\n\npub type AgeError {\n  NotANumber\n  Negative\n}\n\npub fn parse_age(input: String) -> Result(Int, AgeError) {\n  case int.parse(input) {\n    Error(Nil) -> Error(NotANumber)\n    Ok(n) ->\n      case n < 0 {\n        True -> Error(Negative)\n        False -> Ok(n)\n      }\n  }\n}\n\n// 애플리커티브 패턴: 독립인 두 맥락을 결합. 첫 Error에서 멈춘다.\npub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  case parse_age(a), parse_age(b) {\n    Ok(x), Ok(y) -> Ok(x + y)\n    Error(e), _ -> Error(e)\n    _, Error(e) -> Error(e)\n  }\n}\n// add_ages(\"3\", \"4\") == Ok(7)\n// add_ages(\"3\", \"x\") == Error(NotANumber)\n```",
      ),
      tpredict(
        "ap-predict-add",
        "`add_ages(\"3\", \"x\")`의 값은?",
        "add_ages(\"3\", \"x\")",
        ["`Ok(3)`", "`Error(NotANumber)`", "`Error(Negative)`"],
        1,
        "두 인자는 *독립*이라 둘 다 평가되지만, 결합 규칙은 '둘 다 `Ok`라야 `Ok`'이고 그렇지 않으면 첫 `Error`를 내보낸다 — 정확히 너가 손으로 쓴 두 번째·세 번째 `case` 가지다.",
        [
          #(0, "맥락이 살아있는 한 안의 값은 맨몸으로 나오지 않습니다. `b`가 실패한 이상 함수 전체가 실패 맥락을 반환해야 합니다 — TU9에서 본 '맥락 보존'이 여기서는 '맥락 결합'으로 확장된 것입니다. `+`는 *둘 다 성공일 때만* 일어납니다."),
          #(2, "맥락이 살아있는 한 안의 값은 맨몸으로 나오지 않습니다. `b`가 실패한 이상 함수 전체가 실패 맥락을 반환해야 합니다 — TU9에서 본 '맥락 보존'이 여기서는 '맥락 결합'으로 확장된 것입니다. `+`는 *둘 다 성공일 때만* 일어납니다."),
        ],
      ),
      tprose(
        "ap-use",
        "같은 애플리커티브 패턴을 `use`로도 쓸 수 있다. `use x <- result.try(parse_age(a))` 두 줄 뒤 `Ok(x + y)`로 **조립**하는 것. 단 여기엔 함정이 있다: `use`/`result.try`는 사실 모나드(다음 레슨) 도구다. 두 계산이 *정말로 독립*이라면 어느 쪽으로 써도 결과가 같지만, 표현하고 싶은 의도가 \"독립 결합\"이라는 점은 `case a, b`가 더 정직하게 드러낸다. **정직한 한계**: Gleam엔 `Applicative`도 HKT도 없으므로, 하스켈의 `(+) <$> pa <*> pb` 같은 *임의 애플리커티브 위 단일 표기*는 없다. 매번 그 타입에 맞게 손으로 조립한다.\n\n```gleam\nimport gleam/result\n\n// 같은 애플리커티브 의도를 use 두 줄 + Ok 조립으로\npub fn add_ages_use(a: String, b: String) -> Result(Int, AgeError) {\n  use x <- result.try(parse_age(a))\n  use y <- result.try(parse_age(b))\n  Ok(x + y)\n}\n// add_ages_use(\"3\", \"4\") == Ok(7)\n```",
      ),
      tmcq(
        "ap-order-use",
        "다음 줄 조각을 올바른 순서로 재배열해 `add_ages_use`를 완성하라(`(\"3\",\"4\")->Ok(7)`, `(\"x\",\"4\")->Error(NotANumber)`). 어느 순서가 맞는가?",
        [
          "`use x <- result.try(parse_age(a))` → `use y <- result.try(parse_age(b))` → `Ok(x + y)`",
          "`use x <- result.try(parse_age(a))` → `use y <- result.try(parse_age(b))` → `x + y`",
          "`use a <- result.try(parse_age(a))` → `use a <- result.try(parse_age(b))` → `Ok(a + a)`",
        ],
        0,
        "두 독립 맥락을 차례로 깐 뒤, 결합 결과를 다시 맥락에 *재포장*하는 `Ok(...)`가 애플리커티브 '조립' 단계입니다. 이름이 서로 달라야(`x`, `y`) 마지막 줄에서 둘 다 쓸 수 있습니다.",
        [
          #(1, "두 맥락을 다 깠어도 함수 반환 타입은 여전히 `Result(Int, AgeError)`입니다. 결합 결과를 다시 맥락에 *재포장*하는 `Ok(...)`가 애플리커티브 '조립' 단계입니다 — U10③의 '마지막 Ok 누락' 단골이 이론 트랙에서 재등장한 것입니다."),
          #(2, "독립인 두 계산이라도 결과 이름은 서로 달라야 둘 다 마지막 줄에서 쓸 수 있습니다."),
        ],
      ),
    ],
  )
}

fn l_10_b() -> Lesson {
  tlesson(
    "tu10-monad-l02-monad-laws",
    "tu10-monad",
    "세 모나드 법칙, 그리고 정직한 한계",
    [Theory("monad"), Theory("monad-laws"), Theory("bind-vs-map"), Theory("no-hkt")],
    [
      tprose(
        "ml-intro",
        "이전 레슨에서 `result.try(m, f)`(= `use`)가 \"맥락이 *살아있으면* 다음 계산으로, 죽었으면 단락\"이라는 **의존적 순차**임을 봤다 — 이것이 모나드의 `bind`다. **폭로**: U10에서 `parse_age` 두 개를 `use`로 이어 쓴 그 순간, 너는 이미 Result 모나드를 쓰고 있었다. 모나드가 진짜 모나드이려면 세 법칙을 지켜야 하고, Gleam엔 법칙을 강제하는 타입클래스가 없으니 우리는 법칙을 **실행 가능한 프로퍼티**로 — `main` 안 `assert`로 표본 검사한다.\n\n```gleam\nimport gleam/io\nimport gleam/result\n\npub type AgeError {\n  NotANumber\n  Negative\n}\n\npub fn main() -> Nil {\n  let f = fn(x: Int) -> Result(Int, AgeError) { Ok(x + 1) }\n  let g = fn(x: Int) -> Result(Int, AgeError) { Ok(x * 10) }\n  let m: Result(Int, AgeError) = Ok(5)\n\n  // 좌항등 (left identity):  try(Ok(a), f) == f(a)\n  assert result.try(Ok(5), f) == f(5)\n\n  // 우항등 (right identity): try(m, Ok) == m   (Ok가 곧 'return/순수')\n  assert result.try(m, Ok) == m\n\n  // 결합 (associativity):    try(try(m, f), g) == try(m, fn(x){ try(f(x), g) })\n  assert result.try(result.try(m, f), g)\n    == result.try(m, fn(x) { result.try(f(x), g) })\n\n  io.println(\"monad laws hold (sampled)\")\n}\n```",
      ),
      tmcq(
        "ml-spot-bug",
        "네 개의 `assert` 중 모나드 법칙을 *잘못* 적은 것 하나를 골라라.",
        [
          "`assert result.try(Ok(5), f) == f(5)`",
          "`assert result.try(m, Ok) == m`",
          "`assert result.try(m, fn(x) { Ok(x) }) == m`",
          "`assert result.try(Ok(5), f) == Ok(5)`",
        ],
        3,
        "좌항등은 `try(Ok(a), f) == f(a)`입니다 — `f`를 *통과한* 값이지, 원래 값 `Ok(a)`가 아닙니다. `f(5) == Ok(6) != Ok(5)`이므로 이 assert는 런타임에 깨집니다(`assert`가 실패하면 크래시 — TU/U13의 assert 의미).",
        [
          #(0, "이것은 좌항등 `try(Ok(a), f) == f(a)`의 정확한 표현입니다. `f`를 통과한 값과 비교하므로 정상 법칙입니다."),
          #(1, "`Ok`는 이 모나드의 '순수(return)'입니다. `try(m, Ok)`는 '맥락을 풀었다가 곧장 같은 맥락으로 되돌리는' 무위 연산이므로 항상 `m`과 같습니다 — 정상 법칙입니다."),
          #(2, "`Ok`는 이 모나드의 '순수(return)'입니다. `fn(x) { Ok(x) }`는 `Ok`와 같은 함수이므로 `try(m, Ok) == m`의 다른 표현일 뿐, 정상 법칙입니다."),
        ],
      ),
      tprose(
        "ml-map-vs-try",
        "**`map`인가 `try`인가**(`bind-vs-map`). 콜백이 **맨몸 값**을 돌려주면 맥락이 그대로 한 겹이니 `map`. 콜백이 또 **맥락에 싼 값**(`Result`)을 돌려주면 맥락이 *두 겹*이 되어 `Result(Result(a, e), e)`가 생긴다 — 이 중첩을 **평탄화**하는 게 `try`의 일이다. 도구를 잘못 고르면 타입이 어긋나거나, 어긋나지 않아도 의미가 망가진다.\n\n```gleam\nimport gleam/result\n\npub fn halve(n: Int) -> Result(Int, AgeError) {\n  case n % 2 == 0 {\n    True -> Ok(n / 2)\n    False -> Error(NotANumber)\n  }\n}\n\n// map: 콜백이 또 Result를 주므로 맥락이 두 겹 -> 중첩\npub fn parse_then_halve_map(\n  s: String,\n) -> Result(Result(Int, AgeError), AgeError) {\n  result.map(parse_age(s), halve)\n}\n// parse_then_halve_map(\"8\") == Ok(Ok(4))   <- 평탄화 안 됨\n\n// try: 한 겹으로 평탄화\npub fn parse_then_halve_try(s: String) -> Result(Int, AgeError) {\n  result.try(parse_age(s), halve)\n}\n// parse_then_halve_try(\"8\") == Ok(4)\n// parse_then_halve_try(\"7\") == Error(NotANumber)\n```\n\n**정직한 한계(U14 연결)**: Gleam엔 `Monad` 타입클래스도 HKT도 없다. `use`는 \"나머지 줄 전체가 마지막 인자 콜백으로 들어가는\" 설탕일 뿐 타입클래스 디스패치가 아니다. `result.try`는 오직 `Result`에만, `option.then`은 오직 `Option`에만 쓴다. `result.try(option.Some(1), ...)`처럼 섞으면 `Expected type: Result(Int, a) / Found type: option.Option(Int)`로 컴파일 거부된다 — 이게 'HKT 없음'의 구체적 대가다. Gleam의 길은 '하나의 추상 함수'가 아니라 '각 타입마다 명시적 `result.try` / `option.then`'이다 — 패턴은 같되 디스패치는 손으로.",
      ),
      tpredict(
        "ml-predict-map-try",
        "`parse_then_halve_map(\"8\")` 과 `parse_then_halve_try(\"8\")` 의 값은 각각?",
        "parse_then_halve_map(\"8\")\nparse_then_halve_try(\"8\")",
        [
          "`Ok(4)` 와 `Ok(Ok(4))`",
          "`Ok(Ok(4))` 와 `Ok(4)`",
          "`Ok(4)` 와 `Ok(4)`",
        ],
        1,
        "`halve`가 `Result`를 돌려주므로 `map`은 맥락을 한 겹 더 *쌓아* `Ok(Ok(4))`를 만들고, `try`는 그 한 겹을 흡수(평탄화)해 `Ok(4)`로 잇습니다. '맥락이 한 겹 더 생기면 `try`, 아니면 `map`'이 선택 규칙입니다.",
        [
          #(0, "순서가 뒤바뀌었습니다. `map`은 절대 평탄화하지 않으므로 `Ok(Ok(4))`를, `try`는 평탄화해 `Ok(4)`를 냅니다."),
          #(2, "`map`은 절대 평탄화하지 않습니다 — 콜백 결과를 *그대로* 맥락 안에 넣을 뿐입니다. 콜백이 이미 `Result`라면 `Ok(Ok(...))` 중첩이 그대로 보존됩니다. 이 중첩 `Result(Result(a,e),e)`가 보이면 거의 항상 `map`을 `try`로 바꿔야 한다는 신호입니다."),
        ],
      ),
    ],
  )
}

fn unit_tu10() -> Unit {
  tunit(
    UnitMeta(
      id: "tu10-monad",
      title: "모나드와 애플리커티브 패턴",
      order: 10,
      level: 7,
      concepts: [Theory("monad"), Theory("applicative"), Theory("monad-laws"), Theory("bind-vs-map")],
      prerequisites: ["tu09-functor"],
      lesson_ids: ["tu10-monad-l01-applicative", "tu10-monad-l02-monad-laws"],
    ),
    [l_10_a(), l_10_b()],
  )
}

// ── tu11-lambda ─────────────────────────────────────────────
// TU11-① 「(λx.M)N → M[x:=N] — β-환원과 변수 포획」
fn l_11_a() -> Lesson {
  tlesson(
    "tu11-lambda-l01-beta",
    "tu11-lambda",
    "(λx.M)N → M[x:=N] — β-환원과 변수 포획",
    [Theory("lambda-calculus"), Theory("beta-reduction"), Theory("beta-reduction-capture")],
    [
      tprose(
        "beta-intro",
        "람다 계산은 문법이 셋뿐인 계산 모델입니다 — **변수** `x`, **추상** `λx.M`(\"`x`를 받아 `M`을 돌려주는 함수\"), **적용** `M N`(\"`M`에 `N`을 먹임\"). 그게 전부입니다. 계산은 단 한 규칙, **β-환원**: 함수에 인자를 주면 본문의 매개변수를 인자로 바꿔 끼웁니다 — `(λx.M)N → M[x:=N]`. TU3에서 \"평가는 식을 더 단순한 식으로 줄이는 것\"이라 했는데, β-환원이 바로 그 한 걸음입니다. Gleam에서 `λx.M`은 `fn(x) { m }`, 적용은 `f(n)`, β-환원은 Gleam 런타임이 함수 호출 시 실제로 하는 일입니다.\n\n```gleam\nimport gleam/io\nimport gleam/int\n\n// (λx. x + x) 3  --β-->  3 + 3  -->  6\npub fn main() -> Nil {\n  let double = fn(x: Int) { x + x }\n  io.println(int.to_string(double(3)))\n  Nil\n}\n```",
      ),
      tpredict(
        "double-beta",
        "위 `double(3)`를 β-환원으로 손으로 줄이면 `3 + 3`이 되고 그 다음은? 무엇이 출력되는가?",
        "let double = fn(x: Int) { x + x }\ndouble(3)\n// (λx. x + x) 3  --β-->  3 + 3  -->  ?",
        ["`6`", "`33`", "`double(3)`"],
        0,
        "`(λx. x+x) 3`에서 본문 `x+x`의 모든 `x`를 인자 `3`으로 치환 → `3+3` → `6`. β-환원은 '문자열 끼워넣기'가 아니라 '값의 치환'이라 `Int +`가 동작합니다.",
        [
          #(1, "`33`은 문자열 결합(`<>`)의 결과처럼 보입니다. 여기서 `+`는 **Int 덧셈**입니다(Gleam은 Int `+`와 Float `+.`, 문자열 `<>`를 엄격히 구분 — U1③). β-환원은 매개변수 `x`를 *값* 3으로 치환할 뿐, 두 토큰을 이어붙이지 않습니다."),
        ],
      ),
      tprose(
        "capture-intro",
        "치환에는 함정이 있습니다 — **변수 포획(variable capture)**. `M[x:=N]`을 할 때, `N` 안의 자유 변수가 `M` 안의 다른 λ에 *붙잡혀* 의미가 뒤바뀌면 안 됩니다. 예: `(λx. λy. x)`는 \"두 인자 중 첫째를 돌려주는 함수\"입니다. 여기에 `y`를 순진하게 치환하면 `λy. y`(\"둘째를 돌려줌\")가 되어 의미가 *반대로* 망가집니다 — 안쪽 `λy`가 바깥에서 온 `y`를 포획했기 때문입니다. 올바른 환원은 먼저 묶인 변수의 이름을 바꿔(α-변환) 충돌을 피합니다: `λy'. y`. TU1의 \"등식추론은 치환을 보존한다\"가 성립하려면 이 capture-avoiding 규칙이 필수입니다. Gleam에서는 컴파일러가 스코프를 정확히 추적하므로 *직접* 포획 버그를 만들 수는 없지만, 손으로 환원할 때 우리가 저지르는 실수를 컴파일러는 절대 하지 않는다는 점을 코드로 확인할 수 있습니다.\n\n```gleam\nimport gleam/io\n\n// (λx. λy. x) 적용: 첫째 인자를 고정해 \"상수 함수\"를 만든다.\n// const_y 는 y를 무시하고 항상 처음 받은 값을 돌려준다 — 포획이 없다.\npub fn main() -> Nil {\n  let const_fn = fn(x: String) { fn(_y: String) { x } }\n  let always_a = const_fn(\"a\")\n  io.println(always_a(\"b\"))\n  // == \"a\"  (만약 y에 포획됐다면 \"b\"가 나왔을 것)\n  Nil\n}\n```",
      ),
      tmcq(
        "capture-spot",
        "다음 세 개의 \"`(λx. λy. x)` 치환\" 손계산 중 **틀린(포획이 일어난)** 것을 고르세요.",
        [
          "(A) `(λx. λy. x)` 에 `z` 치환 → `λy. z`",
          "(B) `(λx. λy. x)` 에 `y` 치환 → `λy. y`",
          "(C) `(λx. λy. x)` 에 `y` 치환, 먼저 `λy`→`λy'` 개명 후 → `λy'. y`",
        ],
        1,
        "(B)는 바깥에서 들어온 자유변수 `y`가 안쪽 `λy`에 *포획*되어 '상수 함수'가 '항등 비슷한 것'으로 둔갑했습니다 — 의미가 바뀌었으니 잘못된 환원입니다.",
        [
          #(2, "(C)는 정확히 capture-avoiding의 정석입니다 — 충돌하는 묶인 변수를 α-변환으로 먼저 개명(`λy'`)한 뒤 치환하므로 의미가 보존됩니다. 이게 올바른 β-환원이며, Gleam 컴파일러가 내부적으로 보장하는 스코핑과 같은 원리입니다."),
        ],
      ),
    ],
  )
}

// TU11-② 「모든 것이 함수다 — Church Bool·pair·수를 Gleam으로」
fn l_11_b() -> Lesson {
  tlesson(
    "tu11-lambda-l02-church",
    "tu11-lambda",
    "모든 것이 함수다 — Church Bool·pair·수를 Gleam으로",
    [Theory("church-encoding"), Theory("church-numerals")],
    [
      tprose(
        "church-bool-intro",
        "람다 계산엔 `True`도 `42`도 `(a, b)`도 없습니다. 함수밖에 없는데 어떻게 데이터를 표현할까요? **처치 인코딩(Church encoding)**: 데이터를 \"그 데이터로 *무엇을 할지*\"로 정의합니다. **Church Bool**은 \"두 선택지 중 하나를 고르는 함수\"입니다 — `ctrue`는 첫째를, `cfalse`는 둘째를 고릅니다. 그러면 `if`는 그냥 \"그 불리언을 두 가지에 적용\"하는 것입니다. Gleam은 정적 타입이라 untyped λ-계산과 달리 타입이 붙습니다: 두 선택지가 같은 타입 `a`여야 하므로 Church Bool의 타입은 **`fn(a, a) -> a`**.\n\n```gleam\nimport gleam/io\n\n// Church Bool : fn(a, a) -> a  — 둘 중 하나를 고른다\npub fn ctrue(t: a, _f: a) -> a {\n  t\n}\n\npub fn cfalse(_t: a, f: a) -> a {\n  f\n}\n\n// cif b then else  ==  b(then, else) : 불리언을 두 선택지에 적용\npub fn cif(b: fn(a, a) -> a, then: a, els: a) -> a {\n  b(then, els)\n}\n\npub fn main() -> Nil {\n  assert cif(ctrue, \"yes\", \"no\") == \"yes\"\n  assert cif(cfalse, \"yes\", \"no\") == \"no\"\n  io.println(cif(ctrue, \"yes\", \"no\"))\n  // == \"yes\"\n  Nil\n}\n```\n\n> 정직성 노트: `ctrue`에서 둘째 인자 `_f`를 안 쓴다고 `_`를 붙였습니다(U1에서 본 \"안 쓰는 인자\" 관용구). 이름 그대로 `f`로 두면 컴파일은 되지만 \"Unused function argument\" 경고가 뜹니다 — λ-계산에선 인자를 버리는 게 정상이라 Gleam의 경고와 미묘하게 어긋나는 지점입니다.",
      ),
      tpredict(
        "cfalse-call",
        "`cfalse(\"A\", \"B\")`를 직접 호출(`cif` 없이)하면?",
        "pub fn cfalse(_t: a, f: a) -> a {\n  f\n}\n\ncfalse(\"A\", \"B\")",
        ["`\"A\"`", "`\"B\"`", "컴파일 에러"],
        1,
        "`cfalse(t, f) = f`이므로 둘째 인자 `\"B\"`를 그대로 돌려줍니다. Church Bool은 그 자체가 '선택 함수'라 적용만으로 분기가 끝납니다.",
        [
          #(0, "그건 `ctrue`의 동작입니다. `cfalse`는 첫째(`_t`)를 *버리고* 둘째 `f`를 고릅니다 — 함수 본문 `{ f }`를 다시 보세요."),
        ],
      ),
      tprose(
        "church-num-intro",
        "수도 함수로 표현합니다 — **Church 수**는 \"함수 `f`를 값 `x`에 *몇 번* 적용하느냐\"입니다. `czero`는 0번(그냥 `x`), `csucc(n)`은 `n`번 적용한 뒤 한 번 더. 자연수가 곧 \"반복 횟수\"가 되는 셈입니다. 그리고 `cadd m n`은 \"먼저 `n`번, 이어서 `m`번 적용\" = `(m+n)`번. Gleam Int로 **디코드**해 진짜 맞는지 확인할 수 있습니다: `f`를 `fn(k){k+1}`, `x`를 `0`으로 주면 적용 횟수가 그대로 Int로 떨어집니다.\n\n```gleam\nimport gleam/io\nimport gleam/int\n\n// Church 수 : f 를 x 에 n 번 적용\npub fn czero(_f: fn(a) -> a, x: a) -> a {\n  x\n}\n\npub fn csucc(n: fn(fn(a) -> a, a) -> a) -> fn(fn(a) -> a, a) -> a {\n  fn(f, x) { f(n(f, x)) }\n}\n\n// add m n : 먼저 n번, 그 위에 m번 더 적용 = (m+n)번\npub fn cadd(\n  m: fn(fn(a) -> a, a) -> a,\n  n: fn(fn(a) -> a, a) -> a,\n) -> fn(fn(a) -> a, a) -> a {\n  fn(f, x) { m(f, n(f, x)) }\n}\n\n// 디코드: +1 을 n번 적용해 Int로 환산\npub fn to_int(n: fn(fn(Int) -> Int, Int) -> Int) -> Int {\n  n(fn(k) { k + 1 }, 0)\n}\n\npub fn main() -> Nil {\n  let one = csucc(czero)\n  let two = csucc(one)\n  assert to_int(czero) == 0\n  assert to_int(two) == 2\n  assert to_int(cadd(two, two)) == 4\n  io.println(int.to_string(to_int(cadd(two, two))))\n  // == \"4\"\n  Nil\n}\n```",
      ),
      tmcq(
        "cmul-pick",
        "`cmul(m, n)`(\"`m` 곱하기 `n`\")의 올바른 정의를 고르세요. 힌트: `m`은 \"어떤 함수를 `m`번 적용\"하는 도구입니다 — `n`을 한 번 적용하는 것을 `m`번 반복하면 됩니다. (숨김 테스트: `to_int(cmul(two, three)) == 6`, `to_int(cmul(czero, three)) == 0`)",
        [
          "`fn(f, x) { m(fn(y) { n(f, y) }, x) }`",
          "`fn(f, x) { m(f, n(f, x)) }`",
          "`fn(f, x) { m(f, x) + n(f, x) }`",
        ],
        0,
        "곱셈은 '덧셈의 반복'이듯, Church 곱셈은 '적용의 합성을 반복'입니다 — `m`이 바깥 루프, `n`이 안쪽 루프. `m`의 함수 인자 자리에 `fn(y){ n(f, y) }`를 통째로 넘겨 'n번-적용'이라는 한 덩어리를 `m`번 반복합니다.",
        [
          #(1, "그건 덧셈입니다(`cadd`) — `n`번 적용한 *위에* `m`번 더하면 `m+n`. 곱셈은 'n번-적용'이라는 한 덩어리를 `m`번 *반복*해야 하므로, `m`의 함수 인자 자리에 `fn(y){ n(f, y) }`를 통째로 넘겨야 합니다."),
          #(2, "Church 수는 `Int`가 아니라 '적용 횟수를 표현하는 함수'입니다 — `+`로 더할 수 있는 값이 아닙니다. 곱셈은 적용을 *합성해 반복*하는 것이지 디코드된 수를 더하는 게 아닙니다."),
        ],
      ),
    ],
  )
}

fn unit_tu11() -> Unit {
  tunit(
    UnitMeta(
      id: "tu11-lambda",
      title: "람다 계산과 처치 인코딩",
      order: 11,
      level: 8,
      concepts: [
        Theory("lambda-calculus"),
        Theory("beta-reduction"),
        Theory("church-encoding"),
        Theory("church-numerals"),
      ],
      prerequisites: ["tu03-evaluation", "tu01-purity"],
      lesson_ids: ["tu11-lambda-l01-beta", "tu11-lambda-l02-church"],
    ),
    [l_11_a(), l_11_b()],
  )
}

// ── tu12-capstone ─────────────────────────────────────────────
fn l_12_a() -> Lesson {
  tlesson(
    "tu12-capstone-l01-no-hkt",
    "tu12-capstone",
    "결핍의 일관성 — 왜 단 하나의 `map`을 못 만드나",
    [Theory("no-hkt"), Theory("no-typeclass"), Theory("why-not-faq")],
    [
      tprose(
        "l01-seg1",
        "이 트랙 내내 우리는 `list.map`, `option.map`, `result.map`이 **같은 모양의 패턴**(`map(container, fn(a)->b) -> container_of_b`)임을 보았다. 자연스러운 질문: \"그럼 *아무 컨테이너*에나 도는 `map` 하나를 쓰면 안 되나?\" Gleam의 답은 **불가능**이다. 타입 변수는 `Int`, `String` 같은 *완성된 타입*만 받을 수 있고, `List`·`Option`처럼 인자를 더 받아야 완성되는 **타입 생성자**를 변수로 받을 수 없다. 이것이 \"고계 타입(higher-kinded types, HKT)이 없다\"의 정확한 의미다. 그래서 우리가 할 수 있는 건 타입마다 `map`을 *따로* 쓰는 것뿐이다.\n\n```gleam\nimport gleam/list\nimport gleam/option.{type Option}\nimport gleam/result\n\n// 같은 패턴, 그러나 타입마다 따로 — 하나로 합칠 수 없다.\npub fn map_list(xs: List(a), f: fn(a) -> b) -> List(b) {\n  list.map(xs, f)\n}\n\npub fn map_option(o: Option(a), f: fn(a) -> b) -> Option(b) {\n  option.map(o, f)\n}\n\npub fn map_result(r: Result(a, e), f: fn(a) -> b) -> Result(b, e) {\n  result.map(r, f)\n}\n```",
      ),
      tmcq(
        "l01-ex1",
        "네 개의 시그니처 중 \"Gleam에서 *작성 자체가 불가능*한\" 것 하나를 고르라.",
        [
          "`pub fn map_list(xs: List(a), f: fn(a) -> b) -> List(b)`",
          "`pub fn map_pair(p: #(a, a), f: fn(a) -> b) -> #(b, b)`",
          "`pub fn generic_map(c: f(a), f2: fn(a) -> b) -> f(b)`",
          "`pub fn map_result(r: Result(a, e), f: fn(a) -> b) -> Result(b, e)`",
        ],
        2,
        "맞습니다. `f(a)`는 *타입 변수 `f`를 타입에 적용*하려는 시도인데, Gleam의 타입 변수는 그런 능력이 없습니다(HKT 부재). 실제로 컴파일러는 타입이 아니라 *문법* 단계에서 막습니다 — 에러 제목은 `Syntax error`, 메시지는 `I was not expecting this`이고 캐럿이 `f` 뒤의 여는 괄호 `(`를 가리킵니다. 즉 타입 검사까지 가지도 못합니다.",
        [
          #(1, "이건 멀쩡합니다. `#(a, a)`는 *완성된 타입*만 변수로 쓰고 컨테이너 모양(`#(_, _)`)은 코드에 직접 박혀 있습니다 — 타입 생성자를 변수로 받는 게 아니라서 HKT가 필요 없죠. TU11의 `pair_map`이 바로 이것입니다."),
          #(3, "`Result(a, e)`도 컨테이너 모양이 시그니처에 *고정*되어 있습니다. 변하는 건 안에 든 타입 변수 `a`, `e`뿐이라 1차(first-order)로 충분합니다."),
        ],
      ),
      tprose(
        "l01-seg2",
        "이건 Gleam이 \"덜 만들어져서\"가 아니라 **의도된 트레이드오프**다. Haskell/PureScript/Scala는 타입클래스 + HKT로 `class Functor f where fmap :: (a -> b) -> f a -> f b` 같은 *단일 추상*을 표현한다. Gleam은 공식 FAQ에서 타입클래스를 *의도적으로* 배제한다 — 근거는 (1) 디스패치 실패 시 **혼란스러운 에러 메시지**, (2) **컴파일 시간** 증가, (3) 사전(dictionary) 전달로 인한 **런타임 비용**. 그 대신 Gleam은 \"필요한 동작을 *함수 인자로 명시적으로 넘긴다*\". 이것이 TU 트랙 전체에서 \"단일 일반 Functor/Monad 함수는 못 쓴다\"고 매번 정직하게 명시해 온 이유의 *이론적 뿌리*다.",
      ),
      tpredict(
        "l01-ex2",
        "아래 `generic_map`을 컴파일하면 무엇이 나오는가?",
        "// (c)를 실제로 쓰면 — HKT가 없다는 한계를 문법이 먼저 거부한다.\npub fn generic_map(container: f(a), fun: fn(a) -> b) -> f(b) {\n  container\n}",
        [
          "정상 컴파일",
          "`Syntax error`(타입 변수 적용 거부)",
          "`Type mismatch`",
          "런타임 크래시",
        ],
        1,
        "타입 변수에 `(...)`를 붙이는 순간 문법 파서가 거부합니다. 핀 1.17.0 실측 출력은 제목 `Syntax error`, 본문 `I was not expecting this`(캐럿이 `f(`의 여는 괄호를 가리킴)입니다. HKT의 부재는 '타입 검사 실패'가 아니라 *애초에 표현할 문법이 없음*으로 나타납니다 — 가장 깊은 종류의 '없음'이죠.",
        [
          #(0, "이게 통과하려면 `f`가 타입 생성자를 받는 *고계* 변수여야 합니다. 그게 HKT이고, Gleam엔 없습니다."),
          #(2, "타입 단계까지 가지도 못합니다. `f(` 에서 파서가 먼저 멈춥니다 — 이것이 '결핍의 일관성'의 가장 순수한 형태입니다."),
        ],
      ),
    ],
  )
}

fn l_12_b() -> Lesson {
  tlesson(
    "tu12-capstone-l02-recursion-scheme",
    "tu12-capstone",
    "재귀 스킴 — `fold`는 유일한 구조 존중 붕괴다",
    [Theory("catamorphism"), Theory("recursion-scheme"), Theory("functor-laws"), Theory("patterns-as-eyes")],
    [
      tprose(
        "l02-seg1",
        "U6에서 손으로 쓴 `sum_loop`, U8에서 만난 `list.fold` — 그 둘은 사실 같은 이름을 갖는다: **catamorphism(카타모피즘)**. 어떤 ADT든, 그 *각 생성자마다 함수 하나씩*을 주면 구조를 따라 한 번에 \"붕괴(collapse)\"시키는 연산이 정확히 하나 있다. 리스트의 두 생성자(`[]`, `[_, ..]`)에 `initial`과 `fn(acc, x)`를 준 게 `list.fold`였다. 트리도 똑같다 — 생성자가 `Leaf`/`Node` 둘이니, 함수도 둘 준다. 이 \"생성자 개수 = 인자 개수\" 대응이 catamorphism의 본질이다(검증된 예제: sum=6, depth=3).\n\n```gleam\nimport gleam/int\n\npub type Tree(a) {\n  Leaf(a)\n  Node(Tree(a), Tree(a))\n}\n\n// catamorphism: Leaf용 함수 하나, Node용 함수 하나. 그 외 선택지는 없다.\npub fn fold_tree(tree: Tree(a), on_leaf: fn(a) -> b, on_node: fn(b, b) -> b) -> b {\n  case tree {\n    Leaf(value) -> on_leaf(value)\n    Node(left, right) ->\n      on_node(fold_tree(left, on_leaf, on_node), fold_tree(right, on_leaf, on_node))\n  }\n}\n\npub fn sum_tree(tree: Tree(Int)) -> Int {\n  fold_tree(tree, fn(x) { x }, fn(l, r) { l + r })\n}\n\npub fn depth(tree: Tree(a)) -> Int {\n  fold_tree(tree, fn(_) { 1 }, fn(l, r) { 1 + int.max(l, r) })\n}\n```",
      ),
      tpredict(
        "l02-ex1",
        "`Node(Node(Leaf(1), Leaf(2)), Leaf(3))`에 대해 잎(Leaf)의 개수를 세는 catamorphism은 아래와 같다. 출력은?",
        "import gleam/io\nimport gleam/int\n\npub type Tree(a) {\n  Leaf(a)\n  Node(Tree(a), Tree(a))\n}\n\npub fn fold_tree(tree: Tree(a), on_leaf: fn(a) -> b, on_node: fn(b, b) -> b) -> b {\n  case tree {\n    Leaf(value) -> on_leaf(value)\n    Node(left, right) ->\n      on_node(fold_tree(left, on_leaf, on_node), fold_tree(right, on_leaf, on_node))\n  }\n}\n\npub fn main() -> Nil {\n  let t = Node(Node(Leaf(1), Leaf(2)), Leaf(3))\n  let count = fold_tree(t, fn(_) { 1 }, fn(l, r) { l + r })\n  io.println(int.to_string(count))\n  Nil\n}",
        [
          "`3`",
          "`6`",
          "`2`",
          "`1`",
        ],
        0,
        "`on_leaf`가 *씨앗 값*, `on_node`가 *합치는 법*. 잎이 3개이니 1+1+1=3. 만약 `on_leaf = fn(x) { x }`, `on_node = fn(l, r) { l + r }`였다면 그건 `sum_tree`였고 1+2+3=6이었겠죠 — 같은 catamorphism, 다른 두 함수.",
        [
          #(1, "그건 잎의 *값*을 더한 `sum_tree`입니다. 여기서는 `on_leaf = fn(_) { 1 }` 이라 값을 버리고 1만 셉니다. catamorphism의 동작은 오직 당신이 넘긴 두 함수가 결정합니다."),
          #(2, "`Node`는 두 개지만 우리가 세는 건 *잎*입니다. 내부 노드 수가 아니라 `Leaf` 호출 횟수를 세고 있다는 점을 보세요."),
          #(3, "잎은 하나가 아니라 셋입니다. `on_node`가 두 자식의 결과를 더하므로 1+1+1=3이 됩니다."),
        ],
      ),
      tprose(
        "l02-seg2",
        "catamorphism은 ADT를 *접어 없애는* 방향(아래→위)이다. 반대로 씨앗 하나에서 구조를 *펼쳐 만드는* 방향(위→아래)이 **anamorphism(ana)**, 둘을 합친 게 **paramorphism(para, 자식의 원본까지 함께 보는 fold)**이다 — 이름만 맛본다. 여기서 중요한 미묘한 점 하나: catamorphism은 *각 생성자마다 함수 하나*만 주면 무엇이든 될 수 있다. 결과 타입을 바꿀 수도(합·깊이), 심지어 같은 `Tree`를 다시 짓되 자식을 *재배치*할 수도 있다(예: 리스트 `reverse`도 fold로 표현된다). 즉 \"catamorphism이다\"가 곧 \"구조를 보존한다\"는 뜻은 *아니다*. functor map은 그 수많은 catamorphism 중 **구조를 그대로 보존하는**(생성자를 그 자리에서, 자식 순서를 유지한 채 다시 짓는) *특수한* 알지브라일 뿐이다. 또 하나의 \"정직한 한계\": Gleam엔 *모든 ADT에 자동으로 도는 일반 fold*가 없다(그건 HKT가 필요하다). 그래서 catamorphism은 타입마다 **손으로** 쓴다. 하지만 일단 보는 눈이 생기면, U6의 `sum_loop`도 U8의 `list.fold`도 위의 `fold_tree`도 *같은 패턴의 다른 인스턴스*임이 보인다 — 그것이 \"이론은 패턴을 보는 눈\"이다.",
      ),
      tmcq(
        "l02-ex2",
        "아래 세 개의 `fold_tree` 알지브라는 **셋 모두 적법한 catamorphism**이다. 그중 **functor map처럼 구조를 보존하지 *않는*(자식 순서를 재배치하는)** 것 하나를 고르라.",
        [
          "`fold_tree(tree, fn(x) { [x] }, fn(l, r) { list.append(l, r) })` — 잎을 리스트로 모은다",
          "`fold_tree(tree, fn(x) { x }, fn(l, r) { l + r })` — 합",
          "`fold_tree(tree, fn(x) { Leaf(x) }, fn(l, r) { Node(r, l) })` — 좌우를 *뒤집어* 다시 트리로",
        ],
        2,
        "(c)도 형식상 **완전히 적법한 catamorphism**입니다 — 생성자마다 함수 하나(F-알지브라)를 주었고, 핀 1.17.0에서 컴파일·실행되어 좌우가 뒤집힌 `Tree`를 돌려줍니다. catamorphism은 자식을 *재배치*할 수 있습니다(리스트 `reverse`도 fold로 표현되듯). 다만 (c)는 `on_node`에서 `Node(r, l)`로 **자식 순서를 바꿔** 구조를 보존하지 *않으므로*, functor map의 골격으로는 부적격합니다. 이 알지브라를 그대로 `map_tree`의 골격으로 끼워 넣으면 identity 법칙 `map(t, id) == t`를 깨뜨립니다.",
        [
          #(0, "(a)도 적법한 catamorphism이고, 구조를 보존합니다. `on_leaf`/`on_node`가 각각 잎과 노드를 *그 자리에서* 다른 타입(리스트)으로 대치할 뿐, 좌우 순서는 `list.append(l, r)`로 보존됩니다."),
          #(1, "(b)는 교과서적 `sum_tree`입니다. 자리 바꿈 없이 두 자식 결과를 그냥 더하니 구조 존중이 완벽합니다 — 이 역시 적법한 catamorphism입니다."),
        ],
      ),
    ],
  )
}

fn unit_tu12() -> Unit {
  tunit(
    UnitMeta(
      id: "tu12-capstone",
      title: "캡스톤 — 한계, 재귀 스킴, 다음 경로",
      order: 12,
      level: 8,
      concepts: [
        Theory("no-hkt"),
        Theory("catamorphism"),
        Theory("recursion-scheme"),
        Theory("patterns-as-eyes"),
      ],
      prerequisites: ["tu08-monoid", "tu09-functor", "tu10-monad", "tu11-lambda"],
      lesson_ids: ["tu12-capstone-l01-no-hkt", "tu12-capstone-l02-recursion-scheme"],
    ),
    [l_12_a(), l_12_b()],
  )
}

