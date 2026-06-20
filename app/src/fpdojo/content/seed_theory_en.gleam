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
  texercise(
    id,
    Predict,
    prompt,
    code,
    choices,
    answer_idx,
    correct_fb,
    wrong_fbs,
  )
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
  Exercise(
    Step(
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
    ),
  )
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
    "Referential Transparency — Substituting an Expression with Its Value",
    [
      Theory("purity"),
      Theory("referential-transparency"),
      Theory("determinism"),
    ],
    [
      tprose(
        "rt-intro",
        "A **pure function** makes two promises. (1) The same input always yields the same output (**determinism**), and (2) it does nothing observable besides producing that output (no side effects). When both promises hold, a call expression to that function is **referentially transparent** — meaning that anywhere in your code you can swap the expression `double(5)` for its value `10` without changing what the program means. This isn't just a definition; it's **your license to evaluate code in your head**.\n\n```gleam\nimport gleam/int\nimport gleam/io\n\nfn double(x: Int) -> Int {\n  x * 2\n}\n\npub fn main() -> Nil {\n  let a = double(5) + double(5)\n  let b = 10 + 10\n  let v = double(5)\n  let c = v + v\n  io.println(int.to_string(a))\n  io.println(int.to_string(b))\n  io.println(int.to_string(c))\n}\n```\n\nThe three expressions `a`, `b`, and `c` are *written differently* yet hold the same value. That's because you can freely substitute `double(5)` with `10` (or with `v`) — which is precisely the definition of referential transparency.",
      ),
      tpredict(
        "rt-predict-out",
        "What are the three output lines of the code above?",
        "import gleam/int\nimport gleam/io\n\nfn double(x: Int) -> Int {\n  x * 2\n}\n\npub fn main() -> Nil {\n  let a = double(5) + double(5)\n  let b = 10 + 10\n  let v = double(5)\n  let c = v + v\n  io.println(int.to_string(a))\n  io.println(int.to_string(b))\n  io.println(int.to_string(c))\n}",
        [
          "`10` / `20` / `20`",
          "`20` / `20` / `20`",
          "`20` / `20` / `10`",
          "Compile error",
        ],
        1,
        "All three expressions end up as `20`. When something is referentially transparent, what remains is not 'how it was written' but 'what value it is'.",
        [
          #(
            0,
            "`double(5)` is not `5 + 5` but `5 * 2 = 10`. And `a = double(5) + double(5) = 10 + 10 = 20`. Even though the call appears twice, each produces the same value `10`, so the sum is `20` — it never happens with a pure function that the first call yields `10` and the next yields a different value.",
          ),
          #(
            2,
            "In `c = v + v`, `v` is a name that binds `double(5)` once. `let` fixes a value (U1). `v` is `10`, and `v + v = 20`. The key point is that you get the same result whether you bind it to a name or write the expression twice.",
          ),
        ],
      ),
      tprose(
        "rt-hidden-effect",
        "The classic way referential transparency breaks is when a function carries a **hidden effect** inside. The `logged` function below looks like \"a function that returns the value it was given, unchanged,\" but as a side effect it prints to the screen. So the moment you substitute `logged(7)` with its value `7`, **a line of output disappears** — the meaning changed, so it is not referentially transparent.\n\n```gleam\nimport gleam/io\nimport gleam/int\n\nfn square(x: Int) -> Int {\n  x * x\n}\n\nfn logged(x: Int) -> Int {\n  io.println(\"saw \" <> int.to_string(x))\n  x\n}\n\npub fn main() -> Nil {\n  let p = square(7) + square(7)\n  let q = logged(7) + logged(7)\n  io.println(int.to_string(p))\n  io.println(int.to_string(q))\n}\n```\n\nHonesty note: Gleam **allows side effects by default** like this (`logged` compiles just fine). That means the presence or absence of effects is not enforced by the type system — that responsibility lies with the designer.",
      ),
      tmcq(
        "rt-spot-bug",
        "In the code above, which function lets you \"safely substitute a call with its result value,\" and why doesn't the other one? (Pick the one — `square` or `logged` — that breaks referential transparency, and the reason.)",
        [
          "`square` — because multiplication is nondeterministic",
          "`logged` — it returns `x` but produces an `io.println` effect as a side effect, so replacing the call with the value makes the output disappear",
          "Both are pure, so there's no difference",
          "`logged` — because its return type is `Int`",
        ],
        1,
        "Run it and `saw 7` is printed **twice**. If you replace `logged(7)` with `7`, those two lines vanish — because the effect is not captured in the result. That's why a call with an effect 'cannot be deferred into a value'.",
        [
          #(
            0,
            "`square` is pure. `*` is deterministic — `square(7)` is always `49`. Multiplication is never nondeterministic.",
          ),
          #(
            2,
            "The two are different. Looking at the output, `square` leaves no trace on the screen, while `logged` prints one line per call — that trace is the side effect, and that's what blocks substitution.",
          ),
          #(
            3,
            "The return type has nothing to do with purity. Even if it returns `Int`, printing to the screen with `io.println` in the body means that effect prevents substituting the call with its value.",
          ),
        ],
      ),
    ],
  )
}

fn l_01_b() -> Lesson {
  tlesson(
    "tu01-purity-l02-nil-effects",
    "tu01-purity",
    "Nil Is Not 'Nothing' — A Signal of Effects, and Deferring Effects as Values",
    [
      Theory("side-effect"),
      Theory("hidden-effect"),
      Theory("effects-as-values"),
    ],
    [
      tprose(
        "nil-signal",
        "The return type of `io.println` is `Nil`. Beginners often mistake `Nil` for \"does nothing / nothingness,\" but it's the opposite. `Nil` is a signal that says \"this function has **no useful value to return — you call it for the effect**.\" In other words, a `Nil` return is a marker that 'all the function did was print to the screen'. Since Gleam doesn't hide effects in types (there's no IO monad or the like), this `Nil` is just about the only clue we have. So if you try to use `Nil` like a real value, the compiler stops you.\n\n```gleam\nimport gleam/io\n\npub fn shout(name: String) -> String {\n  io.println(name)\n}\n\npub fn main() -> Nil {\n  io.println(shout(\"hi\"))\n}\n```\n\nThe body `io.println(name)` of `shout` above returns `Nil`, but the function declared that it returns `String`. The types don't match.",
      ),
      tmcq(
        "nil-compile-result",
        "What happens if you compile the `shout` code above as is?",
        [
          "It compiles fine and prints `hi` on one line",
          "`Type mismatch` — `io.println(name)` returns `Nil`, but the function declared it returns `String`",
          "An error only happens at runtime (compilation passes)",
          "Only a warning that `shout`'s parameter `name` is unused",
        ],
        1,
        "The compiler reports a `Type mismatch`: the type of `io.println(name)` is `Nil`, but the function's declared return type is `String`, so they conflict. `Nil` isn't 'no value' but a signal of 'a function called for its effect', and you can't plug it into a `String` slot.",
        [
          #(
            0,
            "It does not compile. `io.println(name)` prints to the screen and then returns `Nil`, but `shout` declared it returns `String`, so the types conflict and you get a `Type mismatch`.",
          ),
          #(
            2,
            "Gleam is statically type-checked, so it catches this mismatch at **compile time**. It is not deferred until runtime.",
          ),
          #(
            3,
            "It's not a mere warning but a **type error** that halts compilation. To fix it, make `shout` actually return a `String` by changing the body to something like `string.uppercase(name) <> \"!\"`, and leave the printing to `main`'s `io.println(shout(\"hi\"))` — separating 'computation' from 'effect'.",
          ),
        ],
      ),
      tprose(
        "defer-effect",
        "So can we hold an effect \"as a **value** to run later\" instead of \"running it right now\"? Yes. If you wrap the effect-causing code inside `fn() { ... }`, it becomes not an *execution* but a *recipe for execution (a thunk)* — no effect happens until you call it. Gleam uses **eager evaluation**, so arguments are evaluated just before a call, but a body wrapped in `fn()` stays asleep until you invoke it with `()`. This is a taste of \"deferring effects as data.\"\n\n```gleam\nimport gleam/io\n\npub fn main() -> Nil {\n  let action = fn() { io.println(\"BOOM\") }\n  io.println(\"before\")\n  action()\n  action()\n  io.println(\"after\")\n}\n```\n\nHonesty note: here `action` is an argument-less `fn() -> Nil` value. Gleam has no partial application or automatic currying, so there's no magic where 'a function given fewer arguments carries an effect around on its own'. To defer an effect you must wrap it in `fn()` **explicitly**.",
      ),
      tpredict(
        "defer-predict-order",
        "What is the output order of the code above?",
        "import gleam/io\n\npub fn main() -> Nil {\n  let action = fn() { io.println(\"BOOM\") }\n  io.println(\"before\")\n  action()\n  action()\n  io.println(\"after\")\n}",
        [
          "`before` / `after` (the effect was deferred, so `BOOM` is not printed)",
          "`BOOM` / `before` / `BOOM` / `after`",
          "`before` / `BOOM` / `BOOM` / `after`",
          "`before` / `BOOM` / `after`",
        ],
        2,
        "`let action = fn() {...}` is just a *definition*, not an execution — so `before` comes first. After that, calling `action()` **twice** prints `BOOM` twice. Eager evaluation 'runs statements top to bottom in order'.",
        [
          #(
            0,
            "It's true that wrapping in `fn()` means nothing is printed *at definition time* — but the moment you write `action()` with `()`, you wake the thunk and run it. Deferred effects still happen 'when you call them'. You called it twice, so it happened twice.",
          ),
          #(
            1,
            "The definition (`let action = ...`) produces no effect, so `BOOM` can't come before `before`. `before` is printed first, and then `BOOM` happens at the `action()` call.",
          ),
          #(
            3,
            "There are two `action()` lines. A function call runs the body anew each time (there's no automatic caching like memoization). Call it twice and you get `BOOM` twice.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu01() -> Unit {
  tunit(
    UnitMeta(
      id: "tu01-purity",
      title: "Purity and Referential Transparency",
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
    "Reading Programs as Equations",
    [Theory("equational-reasoning"), Theory("substitution-model")],
    [
      tprose(
        "read-as-equations",
        "Gleam code can be read not as a sequence of commands but as a **collection of equations**. `let name = expr` is the equation \"the name `name` *equals* `expr`,\" and so you can **substitute `expr` directly wherever `name` appears (substitution) without changing the meaning**. The *only* reason this works is the **immutability** you learned in U1 and TU1 — once a name is fixed it never changes to a different value, so the name forever points to the same definition.\n\n```gleam\nimport gleam/int\nimport gleam/io\n\npub fn price(qty: Int) -> Int {\n  let unit = 30\n  let subtotal = unit * qty\n  let shipping = 5\n  subtotal + shipping\n}\n\npub fn main() -> Nil {\n  // Expanding price(2) by hand:\n  //   let unit = 30\n  //   let subtotal = 30 * 2  == 60\n  //   let shipping = 5\n  //   60 + 5  == 65\n  io.println(int.to_string(price(2)))\n}\n```",
      ),
      tpredict(
        "price-predict",
        "What is the value of `price(2)`? In your head, substitute `unit` with `30`, then `subtotal` with `unit * qty`, and then with `30 * 2`, one step at a time.",
        "pub fn price(qty: Int) -> Int {\n  let unit = 30\n  let subtotal = unit * qty\n  let shipping = 5\n  subtotal + shipping\n}\n\nprice(2)",
        ["`65`", "`60`", "`35`", "`70`"],
        0,
        "Swapping each name for its definition one step at a time is the **substitution model**. When you read each line as an equation, computation is simply following the equations to reduce the terms.",
        [
          #(
            1,
            "You skipped the final equation that adds `shipping`(= 5). The last expression `subtotal + shipping` is the function's value, and it substitutes to `60 + 5`.",
          ),
          #(
            2,
            "You read `unit * qty` as `unit + qty`. In fact `subtotal = 30 * 2 = 60`. When you substitute, you must carry over the operators from the definition exactly too.",
          ),
        ],
      ),
      tprose(
        "why-safe",
        "Let's savor *why* substitution is safe, in reverse. In an imperative language `unit` could be reassigned between the `let`s so that its value changes, and then the equation \"name = definition\" collapses. Gleam has no reassignment (U1), and re-`let`ting the same name is merely a **new binding (shadowing)** (code that referred to the earlier name keeps the old equation intact, TU1). So you can confidently swap any name for \"the definition on that line\" — this property is called **referential transparency**.",
      ),
      tmcq(
        "why-substitution-mcq",
        "Which is the most accurate fundamental reason why \"a value named with `let` can be substituted by its definition anywhere in the code without changing the meaning\" always holds in Gleam?",
        [
          "Because Gleam inline-optimizes every `let` into a constant",
          "Because once a name is bound it never changes to a different value (immutability / referential transparency)",
          "Because Gleam automatically curries functions",
          "Because the compiler infers types",
        ],
        1,
        "The foundation of substitution is not compiler optimization but the **language's semantic invariant** — since values don't change, a name forever means the same definition.",
        [
          #(
            0,
            "Optimization is a *consequence*, not the *reason*. The equation is true even without an optimizer. The source of safety is immutability.",
          ),
          #(
            2,
            "Gleam has **no automatic currying** (partial application is made explicit with a capture `f(10, _)` — U7/U14②). Currying and substitution safety are unrelated.",
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
    "Refactoring Is Meaning-Preserving Rewriting",
    [Theory("refactor-is-rewrite"), Theory("substitution-unsound-with-effects")],
    [
      tprose(
        "refactor-as-rewrite",
        "A good refactor is \"a transformation that rewrites code more readably while **guaranteeing equal values via equations**.\" In fact, most of the syntactic sugar we already use is an equational transformation. `x |> f` equals `f(x)` by definition (U2), the capture `f(_, k)` equals `fn(s) { f(s, k) }` (U7), and `use a <- result.try(r)` equals `result.try(r, fn(a) { …the rest… })` (U10). The four variants below are **the same computation written differently**, and we spot-check that they are equal with `assert`.\n\n```gleam\nimport gleam/string\nimport gleam/io\n\n// All four notations are equationally equivalent ways to write the *same computation*.\npub fn main() -> Nil {\n  let name = \"  lucy \"\n\n  // (1) nested calls\n  let a = string.append(string.uppercase(string.trim(name)), \"!\")\n  // (2) pipe: x |> f is f(x) by definition\n  let b = name |> string.trim |> string.uppercase |> string.append(\"!\")\n  // (3) capture: string.append(_, \"!\") is sugar for fn(s) { string.append(s, \"!\") }\n  let shout = string.append(_, \"!\")\n  let c = shout(string.uppercase(string.trim(name)))\n\n  assert a == b\n  assert b == c\n  assert a == \"LUCY!\"\n  io.println(a)\n}\n```",
      ),
      tmcq(
        "map-fusion-mcq",
        "We want to rewrite the `slow` code below to use `list.map` only once **without changing the value** (map fusion: `map f (map g xs) == map (fn(x) { f(g(x)) }) xs`). The original is `xs |> list.map(add1) |> list.map(times2)`. Which rewrite **preserves the equation**?",
        [
          "`xs |> list.map(fn(x) { times2(add1(x)) })`",
          "`xs |> list.map(fn(x) { add1(times2(x)) })`",
          "`xs |> list.filter(fn(x) { times2(add1(x)) })`",
        ],
        0,
        "You cut two traversals down to one while the result is **provably identical**. The original applies `add1` first and `times2` later, so `times2(add1(x))` with `add1(x)` on the inside is correct. Note, though, that we treat this map-fusion equation as holding only for the *concrete type* List — Gleam has **neither typeclasses nor HKT**, so you can't write a single generic function like a 'map that works for every Functor' (U14①).",
        [
          #(
            1,
            "You reversed the composition order. The original applies `add1` *first*, so `add1(x)` must be on the inside — `times2(add1(x))`. An equation-preserving refactor must preserve order too.",
          ),
          #(
            2,
            "`filter` takes a `Bool`, but `times2(add1(x))` is an `Int`, so this won't compile. And `filter` is a different computation from `map` — if you change the meaning, it's not a refactor.",
          ),
        ],
      ),
      tprose(
        "effects-break-substitution",
        "Substitution and equational transformation come with one **decisive caveat** — there must be **no side effects**. Gleam has neither exceptions nor mutation (it's an immutable / Result model), but an expression like `io.println` that has the side effect of printing to the screen is the exception. If you bind an effectful expression to a name once and then \"expand\" that name back into its definition, the **number of times the effect happens changes**. Below, `named` prints `\"hi\"` once, while the expanded `inlined` prints it twice — same text, different meaning.\n\n```gleam\nimport gleam/io\n\n// When an effect is involved, the substitution of \"expanding a let\" changes the meaning.\n// io.println returns Nil but has the *screen output* side effect.\n\n// Version A: name it once and use it twice\npub fn named() -> Nil {\n  let logged = io.println(\"hi\")\n  let _ = logged\n  let _ = logged\n  Nil\n}\n\n// Version B: \"substitute\" that name with its definition, expanding it in two places\npub fn inlined() -> Nil {\n  let _ = io.println(\"hi\")\n  let _ = io.println(\"hi\")\n  Nil\n}\n\npub fn main() -> Nil {\n  io.println(\"--A (named, before expanding)--\")\n  named()\n  io.println(\"--B (inlined, after expanding)--\")\n  inlined()\n}\n```",
      ),
      tpredict(
        "effects-predict",
        "What is the full output of `main` above? (Think about what happens if you substitute `logged` with its definition in `named`.)",
        "pub fn named() -> Nil {\n  let logged = io.println(\"hi\")\n  let _ = logged\n  let _ = logged\n  Nil\n}\n\npub fn inlined() -> Nil {\n  let _ = io.println(\"hi\")\n  let _ = io.println(\"hi\")\n  Nil\n}\n\npub fn main() -> Nil {\n  io.println(\"--A (named, before expanding)--\")\n  named()\n  io.println(\"--B (inlined, after expanding)--\")\n  inlined()\n}",
        [
          "`--A …` / `hi` / `--B …` / `hi`",
          "`--A …` / `hi` / `--B …` / `hi` / `hi`",
          "`--A …` / `hi` / `hi` / `--B …` / `hi` / `hi`",
          "compile error",
        ],
        1,
        "`named` runs `io.println('hi')` **once**, binding the resulting `Nil` to `logged`, and afterward just looks at that `Nil` value twice — so it prints once. `inlined` writes the effectful expression in two places, so it prints twice. **In other words, when there's an effect you cannot substitute `let logged = io.println(…)` with its definition** — this is where the premise of equational reasoning (referential transparency) breaks down (ties back to TU1).",
        [
          #(
            0,
            "You missed that `inlined` has two lines of `io.println('hi')`. Because evaluation is eager, both expressions run immediately at the point of the call (no laziness — to defer, use an `fn() -> a` thunk).",
          ),
          #(
            2,
            "The `let _ = logged` in `named` discards an *already-computed `Nil` value*; it does not call `io.println` again. The effect happens **once, at the moment the name is bound** (eager). So `named` only outputs 'hi' once.",
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
      title: "Equational Reasoning and the Substitution Model",
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
    "Reduction and Evaluation Order",
    [
      Theory("evaluation-order"),
      Theory("eager-vs-lazy"),
      Theory("normal-order-termination"),
    ],
    [
      tprose(
        "reduction-intro",
        "Running a program means **reducing** expressions to simpler ones. There are two ways to turn `square(2 + 3)` into a value.\n\n- **applicative order** (strict/eager): reduce the argument to a value *first* (`2 + 3` -> `5`), then apply the function (`square(5)` -> `25`).\n- **normal order** (lazy): apply the function *first* (`square(2+3)` -> `(2+3) * (2+3)`), and reduce arguments when they are actually needed.\n\nGleam is **applicative order = eager**. In other words, an argument is always a value by the time it enters a function.\n\n```gleam\nimport gleam/int\n\npub fn square(x: Int) -> Int {\n  x * x\n}\n\npub fn demo() -> Int {\n  // eager: 2 + 3 is reduced to 5 first, then passed into square\n  square(2 + 3)\n}\n// demo() == 25,  int.to_string(demo()) == \"25\"\n```",
      ),
      tpredict(
        "pick-first-eager",
        "Predict the stdout of the code below. `shout` prints its argument and returns it unchanged. `pick_first` does *not use* its second argument (`_b`).",
        "import gleam/io\nimport gleam/int\n\npub fn pick_first(a: Int, _b: Int) -> Int {\n  a\n}\n\npub fn shout(x: Int) -> Int {\n  io.println(\"evaluated \" <> int.to_string(x))\n  x\n}\n\npub fn main() -> Nil {\n  let _ = pick_first(1, shout(99))\n  Nil\n}",
        [
          "A single line: `evaluated 99`",
          "Nothing is printed",
          "Two lines: `evaluated 99`",
        ],
        0,
        "Even though it is ignored as `_b`, in an eager language *all arguments are evaluated before the function body is entered*. `shout(99)` runs exactly once, whether or not it is used.",
        [
          #(
            1,
            "That would be the answer for normal order (lazy). Under lazy evaluation, since `_b` is never used, `shout(99)` would never need to be reduced and would print nothing. But Gleam is eager, so it evaluates arguments up front regardless of whether they are used — this distinction is the heart of this unit.",
          ),
          #(
            2,
            "An argument is evaluated only once per call. Printing twice would happen under normal order when an argument is reduced *multiple times* inside the body, but Gleam turns the argument into a value once, up front, to begin with.",
          ),
        ],
      ),
      tprose(
        "termination-tradeoff",
        "The difference between the two orders is not a matter of performance taste — it is also a matter of **termination**: in theory, normal order terminates for more expressions (a result can appear even if an unused argument is an infinite loop). The price Gleam pays for choosing eager is that if you simply pass an \"expensive/dangerous argument that might not be used,\" it gets evaluated unconditionally.\n\nThe *only* language-level exception Gleam offers on top of this limitation is the short-circuit evaluation in the next lesson. Eager evaluation is one strand of the same \"predictability first\" design philosophy as Gleam's other absences — no automatic currying, no typeclasses, no exceptions.",
      ),
      tmcq(
        "lazy-not-always-faster",
        "What about the claim that \"normal order (lazy) is **always** more efficient than applicative order (eager)\"?",
        [
          "True — lazy skips unused arguments",
          "False — lazy incurs the cost and memory of creating and managing unevaluated expressions (thunks), and may re-evaluate an argument when it encounters a used one multiple times",
          "True — lazy has short-circuit evaluation built in",
        ],
        1,
        "Lazy's advantage is 'it guarantees more termination and doesn't do what isn't used,' not 'it's always fast.' Representing an unevaluated expression requires a runtime representation called a thunk, and if implemented without sharing, the same argument is re-evaluated. One reason Gleam chose eager is precisely this predictable cost.",
        [
          #(
            0,
            "It's true that lazy skips unused arguments, but that alone doesn't make it 'always' faster. There's an additional thunk cost to represent and manage unevaluated expressions.",
          ),
          #(
            2,
            "Short-circuit evaluation isn't exclusive to lazy languages. Gleam (eager) also has short-circuiting with `&&`/`||` — that's the topic of the next lesson.",
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
    "Faking Laziness — the Thunk",
    [Theory("thunk"), Theory("eager-eval-surprise")],
    [
      tprose(
        "thunk-intro",
        "Gleam doesn't give you laziness as a language feature, so to defer evaluation you wrap an expression in a zero-argument function `fn() -> a` (a **thunk**) and pass that. The expression inside is reduced only *when the receiver calls it* with `()`.\n\nThe function values from U7 reveal a second identity here — \"passing a function\" is the same as \"deferring evaluation.\" This is the fundamental technique for handling infinite sequences or expensive fallbacks with just the stdlib (true infinite streams are the domain of the `gleam_yielder` library).\n\n```gleam\nimport gleam/io\nimport gleam/int\n\n// Second argument unused. But now it's a thunk, so it isn't evaluated until called.\npub fn pick_first_lazy(a: Int, _thunk: fn() -> Int) -> Int {\n  a\n}\n\npub fn shout(x: Int) -> Int {\n  io.println(\"evaluated \" <> int.to_string(x))\n  x\n}\n\npub fn main() -> Nil {\n  // shout(99) is trapped inside the thunk and never called -> no output\n  let _ = pick_first_lazy(1, fn() { shout(99) })\n  io.println(\"done\")\n  Nil\n}\n// stdout: just a single line, \"done\"\n```",
      ),
      tpredict(
        "thunk-deferred",
        "Predict the stdout of the `main` above.",
        "import gleam/io\nimport gleam/int\n\npub fn pick_first_lazy(a: Int, _thunk: fn() -> Int) -> Int {\n  a\n}\n\npub fn shout(x: Int) -> Int {\n  io.println(\"evaluated \" <> int.to_string(x))\n  x\n}\n\npub fn main() -> Nil {\n  let _ = pick_first_lazy(1, fn() { shout(99) })\n  io.println(\"done\")\n  Nil\n}",
        [
          "`evaluated 99` followed by `done`",
          "A single line: `done`",
          "Nothing",
        ],
        1,
        "`fn() { shout(99) }` is just a *function value*, not a call. Eager evaluation builds the argument (= this function value itself), but the `shout(99)` inside it is reduced only when someone calls `thunk()`. `pick_first_lazy` ignores the thunk, so it is never called.",
        [
          #(
            0,
            "That's the output of the version *before* wrapping in a thunk. Passing `shout(99)` directly evaluates it immediately because of eager evaluation, but wrapping it as `fn() { shout(99) }` defers the call — this single layer of `fn()` is all it takes to fake laziness in an eager world.",
          ),
          #(
            2,
            "`io.println(\"done\")` runs as written. The only thing deferred is the expression inside the thunk.",
          ),
        ],
      ),
      tprose(
        "eager-surprise",
        "Without a thunk, eager evaluation surprises us — **an expensive or crash-prone argument gets evaluated before it is even used**. The trickiest spot is the stdlib's \"default value\" family of functions.\n\nIn `bool.guard(when:, return:, otherwise:)`, `return` is an **immediately evaluated value** while only `otherwise` is a thunk (`fn() -> a`). So if you write a heavy expression directly in `return`, it gets evaluated first as an argument even when that branch isn't chosen.\n\nIf you want an unevaluated default, use `bool.lazy_guard`, which takes both as thunks, or `option.lazy_unwrap`/`result.lazy_unwrap`. The reason these `lazy_*` variants exist *per function separately* is precisely that Gleam has no HKTs or typeclasses, so you can't write \"a single generic function that works for all lazy defaults.\"\n\n```gleam\nimport gleam/io\nimport gleam/int\nimport gleam/bool\n\npub fn heavy(tag: String) -> Int {\n  io.println(\"heavy \" <> tag)\n  100\n}\n\npub fn main() -> Nil {\n  // when: False, so 'otherwise' is chosen, but\n  // 'return: heavy(\"R\")' is an argument, so it's already evaluated before the call (eager trap!)\n  let r =\n    bool.guard(when: False, return: heavy(\"R\"), otherwise: fn() { heavy(\"O\") })\n  io.println(\"r=\" <> int.to_string(r))\n  Nil\n}\n// stdout: \"heavy R\" -> \"heavy O\" -> \"r=100\"\n```",
      ),
      tmcq(
        "spot-eager-default",
        "The three snippets below all intend to \"use the cached value if present, otherwise use the expensive `recompute()`.\" Pick the unidiomatic code that **needlessly runs `recompute()` every time**.\n\n```gleam\nimport gleam/option.{type Option}\n\n// (A)\npub fn get_a(cache: Option(Int)) -> Int {\n  option.lazy_unwrap(cache, or: fn() { recompute() })\n}\n\n// (B)\npub fn get_b(cache: Option(Int)) -> Int {\n  option.unwrap(cache, or: recompute())\n}\n\n// (C)\npub fn get_c(cache: Option(Int)) -> Int {\n  case cache {\n    option.Some(v) -> v\n    option.None -> recompute()\n  }\n}\n\npub fn recompute() -> Int {\n  // ...expensive computation...\n  0\n}\n```",
        ["(A)", "(B)", "(C)"],
        1,
        "The `or:` default of `option.unwrap` is an **eager value** argument, so even when the cache is filled with `Some(v)`, `recompute()` runs first as an argument. (A) has `lazy_unwrap` take the default as a thunk `fn() -> a` and call it only on `None`, and (C) calls it only in the `None` branch via `case`, so both are idiomatic.",
        [
          #(
            0,
            "(A)'s `fn() { recompute() }` is *a thunk, not a call*. `lazy_unwrap` calls that thunk only on `None`, so on a cache hit `recompute()` doesn't run — exactly the behavior we want.",
          ),
          #(
            2,
            "(C) is the most honest form. A `case` branch is evaluated only when chosen (branching is itself a kind of short-circuit), so `recompute()` runs only on `None`. `lazy_unwrap` is really just this `case` wrapped up in a single function.",
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
      title: "Evaluation Strategies: eager and lazy",
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
    "A type is a set of values — counting cardinality",
    [Theory("cardinality"), Theory("unit-void-types")],
    [
      tprose(
        "card-intro",
        "If you view a type as \"the *set* of values that type can hold,\" then every type has a **cardinality** (the number of elements, written |T|). `Bool` is `{True, False}` — two values — so |Bool|=2. A sum type made of variants with no constructors (an enum) has as many values as it has variants.\n\n```gleam\npub type Direction {\n  North\n  South\n  East\n  West\n}\n// |Direction| = 4  (North, South, East, West — no other value can exist)\n```",
      ),
      tpredict(
        "card-direction",
        "We gather *every* value of `Direction` into a single list and then print its length. What gets printed?",
        "import gleam/io\nimport gleam/list\nimport gleam/int\n\npub type Direction {\n  North\n  South\n  East\n  West\n}\n\npub fn main() -> Nil {\n  // List(Direction) itself can't be printed → print only the length to see the cardinality.\n  io.println(int.to_string(list.length([North, South, East, West])))\n}",
        ["`2`", "`4`", "`infinite`"],
        1,
        "The cardinality of an enum = the number of variants. `[North, South, East, West]` lists *all* the possible values, so its length of 4 is exactly |Direction|. This is the first muscle you build for reading a type as 'the set of its possible values'.",
        [
          #(
            2,
            "For Direction, any value other than North/South/East/West is impossible *by its very representation* — it isn't infinite like `Int`. The heart of an ADT is 'sealing the possible states into a finite set', and that count is precisely the cardinality. This finiteness is exactly what makes U4's exhaustiveness checking possible.",
          ),
        ],
      ),
      tprose(
        "card-unit-void",
        "Let's nail down the two extremes. **`Nil` has cardinality 1** — there is exactly one value (`Nil`), so it is a unit type meaning \"no information at all.\" Conversely, **`pub type Void` with no constructors at all has cardinality 0** — *you cannot construct any value*. Don't mistake `Nil` for 0: 0 means there is no value, while 1 means \"exactly one value\" so there is no choice to make.\n\n```gleam\npub type Void\n\npub fn impossible() -> Void {\n  Void\n}\n```\n\nActual compiler output (verified):\n\n```\nerror: Unknown variable\n  ┌─ src/main.gleam:5:3\n  │\n5 │   Void\n  │   ^^^^\n\n`Void` is a type, it cannot be used as a value.\n```",
      ),
      tmcq(
        "card-which-one",
        "Which of the following types has cardinality **1**?",
        ["`Bool`", "`Nil`", "`pub type Void` (no constructors)", "`Int`"],
        1,
        "`Nil` has exactly one value (`Nil`) — |Nil|=1. It is the slot that carries '0 bits of information'.",
        [
          #(0, "`Bool` is `{True, False}` — two values — so |Bool|=2. Not 1."),
          #(
            2,
            "That has cardinality **0** (void). With no constructors you cannot build *any* value at all — the `Void` compile error you just saw is the proof. 0 (no value) and 1 (exactly one value) are completely different. We revisit this confusion in TU5's discussion of the 0 and 1 identities.",
          ),
          #(
            3,
            "`Int` has infinitely many values — |Int| is not 1 but effectively infinite.",
          ),
        ],
      ),
    ],
  )
}

fn l_04_b() -> Lesson {
  tlesson(
    "tu04-adt-algebra-l02-sum-product-exp",
    "tu04-adt-algebra",
    "Product, sum, function — adding, multiplying, exponentiating",
    [
      Theory("sum-product-types"),
      Theory("cardinality-miscount"),
      Theory("adt-algebra"),
    ],
    [
      tprose(
        "spe-intro",
        "A single value of a product type (`#(a, b)`, or a record with all its fields) is \"one `a` **and** one `b`.\" The number of possible combinations is |a|×|b| — hence **product**. A value of a sum type (several variants) is \"this variant **or** that variant,\" so there are |a|+|b| of them — hence **sum**.\n\n```gleam\npub type Light {\n  Off\n  On(brightness: Bool)\n}\n// |Light| = |Off| + |On(Bool)| = 1 + 2 = 3\n// All values enumerated:  Off, On(False), On(True)\n\npub type Pair2 {\n  Pair2(a: Bool, b: Bool)\n}\n// |Pair2| = |Bool| × |Bool| = 2 × 2 = 4\n```",
      ),
      tpredict(
        "spe-option-bool",
        "We gather every value of `Option(Bool)` into a single list and then print its length. What gets printed?",
        "import gleam/io\nimport gleam/list\nimport gleam/option.{type Option, None, Some}\nimport gleam/int\n\npub fn all_option_bool() -> List(Option(Bool)) {\n  [None, Some(False), Some(True)]\n}\n\npub fn main() -> Nil {\n  io.println(int.to_string(list.length(all_option_bool())))\n}",
        ["`2`", "`3`", "`4`"],
        1,
        "`Option(a) = None | Some(a)` is a sum type, so |Option(a)| = 1 + |a|. `Option(Bool)` = 1 + 2 = 3 (`None`, `Some(False)`, `Some(True)`). By the same formula, `Result(a, e)` = |a| + |e|.",
        [
          #(
            0,
            "2 is the answer for `Bool` itself (|Bool|=2). `Option` adds one more `None` branch on top, so it is 1+2=3.",
          ),
          #(
            2,
            "4 is the answer for `Result(Bool, Bool)` (=2+2) or `#(Bool, Bool)` (=2×2). `Option` carries a value only on the `Some` side, while `None` adds 0 values, so it is 1+2=3. It is a sum, not a product — `None` is not 'one `Bool` *and*' but 'a branch with no value'.",
          ),
        ],
      ),
      tprose(
        "spe-exp",
        "A single value of a function type `fn(a) -> b` is \"a table that picks one output for *each* input in the domain.\" With |a| inputs, each having |b| possible outputs → the number of possible functions is **|b|^|a|** (the base is the output |b|, the exponent is the input |a|). So with sum, product, and now **exponent**, the \"algebra of types\" is complete.\n\n**Honesty note**: this counting assumes *total and pure* functions. Gleam's function-type signatures do **not** enforce totality or purity — code that aborts with `panic`/`todo`, diverges in infinite recursion, or performs side effects still type-checks just the same. So |b|^|a| is exactly right only for the *abstract set of total, pure functions*, and real Gleam code merely **promises by convention** to stay within that subset.\n\n```gleam\nimport gleam/io\nimport gleam/list\nimport gleam/int\n\n// There are exactly 2^2 = 4 total, pure fn(Bool) -> Bool. Enumerate all four.\npub fn all_bool_functions() -> List(fn(Bool) -> Bool) {\n  [\n    fn(_b) { False },\n    fn(b) { b },\n    fn(b) { !b },\n    fn(_b) { True },\n  ]\n}\n\npub fn main() -> Nil {\n  let fns = all_bool_functions()\n  assert list.length(fns) == 4\n  io.println(int.to_string(list.length(fns)))\n}\n```",
      ),
      tmcq(
        "spe-spot-bug",
        "Three students counted the number of values of `fn(Direction) -> Bool` (`|Direction|=4`, `|Bool|=2`). Pick the *wrong* derivation.",
        [
          "(A) \"|Bool|^|Direction| = 2^4 = **16**.\"",
          "(B) \"For each direction you independently choose True/False, so 2×2×2×2 = **16**.\"",
          "(C) \"The domain has 4 and the codomain has 2, so |Direction|^|Bool| = 4^2 = **16**.\"",
        ],
        2,
        "The formula is |b|^|a| = (outputs)^(inputs) = 2^4. (C) flipped the base and the exponent — here the answer happens to coincide, but for `fn(3-element) -> Bool` they diverge: 2^3=**8** (correct) vs 3^2=9 (wrong). (A) is the formula straight, and (B) is the same count with that exponent expanded into a product.",
        [
          #(
            0,
            "(A) and (B) are both correct. (A) is the |b|^|a| formula straight. The trap is (C), which flips the base and exponent. And note this count too holds only for total, pure functions.",
          ),
          #(
            1,
            "(A) and (B) are both correct. (B) just unfolds (A)'s 2^4 as '4 inputs, each with 2 possible outputs → a product' — a foreshadowing of TU5's idea that exponentiation is repeated multiplication. The trap is (C), which flips the base and exponent.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu04() -> Unit {
  tunit(
    UnitMeta(
      id: "tu04-adt-algebra",
      title: "The algebra of algebraic data types",
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
    "What Is an Isomorphism",
    [Theory("type-isomorphism")],
    [
      tprose(
        "iso-def",
        "Saying two types `A` and `B` are **isomorphic** (`A ≅ B`) means there exists a conversion pair `to : A -> B` and `from : B -> A` such that **a round trip in either direction lands you right back where you started** — `from(to(a)) = a` (for every `a`) and `to(from(b)) = b` (for every `b`). If only one of the two holds, it is not an isomorphism (that is the \"false isomorphism\" we will see later). `Option(a)` and `Result(a, Nil)`, which we learned separately back in U9, are the first example: they correspond 1:1 via `Some ↔ Ok` and `None ↔ Error(Nil)`, and their cardinalities match too — both are `(number of a) + 1`.\n\n```gleam\nimport gleam/io\nimport gleam/option.{type Option, None, Some}\n\npub fn result_to_option(r: Result(a, Nil)) -> Option(a) {\n  case r {\n    Ok(x) -> Some(x)\n    Error(Nil) -> None\n  }\n}\n\npub fn option_to_result(o: Option(a)) -> Result(a, Nil) {\n  case o {\n    Some(x) -> Ok(x)\n    None -> Error(Nil)\n  }\n}\n\npub fn main() -> Nil {\n  // assert, on samples, that  from ∘ to = id  and  to ∘ from = id\n  assert option_to_result(result_to_option(Ok(7))) == Ok(7)\n  assert option_to_result(result_to_option(Error(Nil))) == Error(Nil)\n  assert result_to_option(option_to_result(Some(7))) == Some(7)\n  assert result_to_option(option_to_result(None)) == None\n  io.println(\"iso ok\")\n}\n```",
      ),
      tpredict(
        "iso-roundtrip-predict",
        "What does running the `main` above print?",
        "assert option_to_result(result_to_option(Ok(7))) == Ok(7)\nassert option_to_result(result_to_option(Error(Nil))) == Error(Nil)\nassert result_to_option(option_to_result(Some(7))) == Some(7)\nassert result_to_option(option_to_result(None)) == None\nio.println(\"iso ok\")",
        ["`iso ok`", "Crash — an assert fails", "No output"],
        0,
        "It means all four `assert`s passed — that is, taking `Ok(7)` over to `Option` and back still gives `Ok(7)`, and the reverse direction holds too. This is the round-trip identity holding on samples, viewed as an *executable property* (laws can be checked in code — a recurring theme throughout the TU track).",
        [
          #(
            1,
            "`assert` only crashes when the expression is `False`. `option_to_result(result_to_option(Ok(7)))` goes `Ok(7) -> Some(7) -> Ok(7)`, landing right back where it started, so `== Ok(7)` is `True` — no crash. This 'landing back where you started' is exactly the definition of an isomorphism.",
          ),
        ],
      ),
      tprose(
        "iso-info",
        "The core intuition behind isomorphism is **\"different representation, same amount of information.\"** Whether you write it as `Option(Int)` or as `Result(Int, Nil)`, the *number* of distinct values you can hold is exactly the same (both are the infinite integers plus one slot for \"nothing\"). Changing the representation adds and discards no information — which is why the stdlib can freely favor `Result(a, Nil)` while we can just as freely transcribe to `Option`. **Honesty**: if Gleam had typeclasses, we would have built a \"generic `Iso(a, b)` interface that expresses every isomorphism in one line,\" but Gleam has neither typeclasses nor HKT, so an isomorphism is just a *pattern you recognize by writing `to`/`from` functions by hand for each concrete pair of types*.",
      ),
      tmcq(
        "iso-safe-head-type",
        "`safe_head` is supposed to return `Option(Int)`, but in the `[first, ..]` branch you wrote `Ok(first)` instead of `Some(first)`. What happens when you compile this?",
        [
          "It compiles fine — since they are isomorphic, `Ok` and `Some` are interchangeable",
          "Type mismatch — it should return `Option` but you gave it a `Result`",
          "An Inexhaustive patterns error",
        ],
        1,
        "The `safe_head` you just wrote is the isomorphic partner of `list.first` (which returns `Result(a, Nil)`) — the same information written as an `Option`. Being isomorphic does not make them the *same type*. They carry the same amount of information, but to the compiler they are genuinely distinct types, so you must go through `to`/`from` explicitly.",
        [
          #(
            0,
            "Being isomorphic does not make them the *same type*. They carry the same amount of information, but to the compiler `Option` and `Result` are genuinely distinct types, so you must go through `to`/`from` explicitly.",
          ),
          #(
            2,
            "The two branches of the case (`[]`, `[first, ..]`) cover lists exhaustively. The problem is not the number of branches but the return type — mixing a `Some` branch and an `Ok` branch makes `Option` and `Result` collide.",
          ),
        ],
      ),
    ],
  )
}

fn l_05_b() -> Lesson {
  tlesson(
    "tu05-isomorphism-l02-cardinality-modelling",
    "tu05-isomorphism",
    "Modelling with Cardinality",
    [Theory("cardinality-modelling"), Theory("false-isomorphism")],
    [
      tprose(
        "model-illegal",
        "The practical weaponization of isomorphism is **make-illegal-states-unrepresentable** (a revisit of U12-③). The procedure is simple — (1) count the *number of legitimate states* you want to represent, and (2) make the type's cardinality exactly that number. Example: if you model a network connection as `#(Bool, Bool)` (\"trying to connect?\", \"connected?\"), the cardinality is `2 × 2 = 4`, but there are only three legitimate states (disconnected / connecting / connected). The 4th, `#(True, True)` (\"connecting and connected at the same time\"), is meaningless yet *representable* — whenever cardinality exceeds the number of legitimate states, that excess opens a door for bugs to walk in. The compiler's exhaustiveness check honestly exposes that excess cardinality.\n\n```gleam\nimport gleam/io\n\n// Modelling a connection as #(Bool, Bool) forces you to handle\n// even the meaningless 4th state. The exhaustiveness check exposes the excess cardinality.\npub fn describe(state: #(Bool, Bool)) -> String {\n  case state {\n    #(False, False) -> \"off\"\n    #(True, False) -> \"...\"\n    #(False, True) -> \"on\"\n  }\n}\n\npub fn main() -> Nil {\n  io.println(describe(#(False, True)))\n}\n```",
      ),
      tmcq(
        "model-inexhaustive-predict",
        "Will the code above compile or not? If it compiles, what does it print?",
        [
          "Prints `on`",
          "Compile error (Inexhaustive patterns — missing pattern `#(True, True)`)",
          "Runtime crash",
        ],
        1,
        "The compiler points out precisely that you left out `#(True, True)`. This 'one missing slot' is exactly the 1 illegitimate value out of `#(Bool, Bool)`'s cardinality of 4 — the type is one slot *bigger* than reality.",
        [
          #(
            0,
            "Since the case handles only three of the four cases, Gleam *refuses to compile at all* (there is no early return, and no implicit 'handle the rest automatically' behavior). You either fill the empty slot with `_ -> ...` or — better — switch to a type whose cardinality is 3 from the start, so that slot cannot exist in the first place.",
          ),
          #(
            2,
            "Before execution even reaches runtime, the compiler refuses to compile, saying `#(True, True)` is missing. The exhaustiveness check happens at compile time.",
          ),
        ],
      ),
      tprose(
        "model-fix-and-false",
        "The fix is to move to a type with cardinality 3, i.e. a 3-variant sum type — from `#(Bool, Bool)` (4) to a `Connection` (3) that keeps only the three legitimate states. Now the state `#(True, True)` *does not exist in the type*, so there is no need — and no way — to handle it.\n\n```gleam\npub type Connection {\n  Disconnected\n  Connecting\n  Connected\n}\n```\n\n**False-isomorphism alert**: \"the cardinalities match\" is only a *necessary, not sufficient* condition for an isomorphism. The round-trip identity must hold as well for it to be a true isomorphism. A common trap: mistaking `Bool` (2) and \"an Int that is 0 or 1\" for an isomorphism — `bool_to_int` is fine, but the partner commonly used with it, `int_to_bool(n) = n != 0`, *accepts every Int*. So `bool_to_int(int_to_bool(7)) = 1 ≠ 7` — a round trip starting from the Int side does not land back where it started. This is a **lossy conversion**: not an isomorphism but a mere *injection* that is lossless in only one direction (`Bool -> Int`).\n\n```gleam\npub fn bool_to_int(b: Bool) -> Int {\n  case b {\n    True -> 1\n    False -> 0\n  }\n}\n\npub fn int_to_bool(n: Int) -> Bool {\n  n != 0\n}\n```",
      ),
      tmcq(
        "model-spot-false-iso",
        "Of these four claims that \"`A ≅ B` is an isomorphism,\" pick the **wrong one (the false isomorphism)**.",
        [
          "`Result(a, Nil) ≅ Option(a)` (`Ok↔Some`, `Error(Nil)↔None`)",
          "`#(a, Nil) ≅ a` (`#(x, Nil)↔x`)",
          "`Bool ≅ Int` (`bool_to_int` / `int_to_bool(n)=n != 0`)",
          "`fn(#(a, b)) -> c ≅ fn(a, b) -> c` (uncurry/curry)",
        ],
        2,
        "Only (c) breaks the round-trip identity: `int_to_bool` collapses `7`, `2`, `99` all into `True`, so `bool_to_int ∘ int_to_bool ≠ id`. The cardinalities differ to begin with — `Bool` is 2, `Int` is (effectively) infinite. If cardinalities differ, it cannot possibly be an isomorphism.",
        [
          #(
            0,
            "(a) is a true isomorphism. They correspond 1:1 via `Some ↔ Ok` and `None ↔ Error(Nil)`, the cardinalities match too — both `(number of a) + 1` — and the round trip in both directions lands back where it started. The false isomorphism is elsewhere.",
          ),
          #(
            1,
            "(b) is a true isomorphism. `Nil` is a type of cardinality 1, so `#(a, Nil)` has cardinality `(number of a) × 1 = number of a` — identical to `a`. `Nil` acts like the 1 of multiplication (the algebra rules from TU4) and adds no information at all. The `#(x, Nil) ↔ x` round trip lands perfectly in place.",
          ),
          #(
            3,
            "(d) is a true isomorphism too. Gleam has **no automatic currying** (U14② — `add(10)` is not partial application but a missing-argument error; partial application is made explicit via the capture `add(10, _)`), but you can write the lossless conversion pair (`uncurry`/`curry`) between the two function *shapes* by hand. 'An isomorphism exists' and 'the language converts automatically for you' are separate things — Gleam acknowledges the former while requiring the latter to be explicit.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu05() -> Unit {
  tunit(
    UnitMeta(
      id: "tu05-isomorphism",
      title: "Isomorphism and Data Modelling",
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
    "Types Are Propositions, Values Are Proofs",
    [Theory("curry-howard")],
    [
      tprose(
        "ch-prose-1",
        "The product and sum types you saw in TU5 have a second reading. We can read a type as a **proposition**, and a value of that type as a **proof** of that proposition — this is the Curry-Howard correspondence.\n\nHere is the dictionary: a product type `#(a, b)` (or `And(a, b)`) means \"a and b\" (∧), a sum type means \"a or b\" (∨), and a function type `fn(a) -> b` is the implication \"if a then b\". To say \"we can *build* a value of that type\" is to say \"we can *prove* that proposition\". For example, `proj_left`, which pulls the left side out of `And(a, b)`, is a proof of the logical formula `(a ∧ b) → a`.\n\n```gleam\nimport gleam/io\n\n// a×b ↔ ∧ (and): the product type is a proof of \"a and b\"\npub type And(a, b) {\n  And(left: a, right: b)\n}\n\n// a+b ↔ ∨ (or): the sum type is a proof of \"a or b\"\npub type Or(a, b) {\n  InL(a)\n  InR(b)\n}\n\n// ∧ → left side: if \"a and b\" is proven, then \"a\" is also proven\npub fn proj_left(p: And(a, b)) -> a {\n  p.left\n}\n\npub fn main() -> Nil {\n  let p = And(left: 1, right: \"two\")\n  assert proj_left(p) == 1\n  io.println(\"ok\")\n}\n```",
      ),
      tpredict(
        "ch-ex-1",
        "In the code above, if execution reaches `io.println(\"ok\")`, what is the output?",
        "import gleam/io\n\npub type And(a, b) {\n  And(left: a, right: b)\n}\n\npub fn proj_left(p: And(a, b)) -> a {\n  p.left\n}\n\npub fn main() -> Nil {\n  let p = And(left: 1, right: \"two\")\n  assert proj_left(p) == 1\n  io.println(\"ok\")\n}",
        ["`ok`", "`1`", "`runtime crash`"],
        0,
        "`proj_left(p) == 1` is true, so the `assert` passes and the final `io.println` runs. You just executed a proof of the proposition `(a ∧ b) → a`.",
        [
          #(
            2,
            "`assert` only crashes when the expression is **false**. The left of `And(1, \"two\")` is 1, and `1 == 1` is true, so it passes — a signal that the proof is closed.",
          ),
        ],
      ),
      tprose(
        "ch-prose-2",
        "Both extremes are in the dictionary too. **`Nil` (1 element) ↔ true (⊤)**: a trivial proof you can always build effortlessly, carrying zero information (which is why side-effecting functions so often return `Nil`). The opposite, **void (0 elements) ↔ false (⊥)**: a type with *no* inhabitants at all, which directly encodes \"no value can be built = no proof exists\". In Gleam you can mimic this with a type that has zero constructors, `pub type Void`.\n\n**An honest caveat**: in logic, `⊥ → a` (ex falso) is trivial, but Gleam 1.17 does *not* even recognize a `case` on an uninhabited type as automatically exhaustive — `case v {}` produces an `Inexhaustive patterns` error. So below we put a `panic` in a single `_` branch; this `panic` is \"safe because it is unreachable\", but the **compiler does not prove that safety for us**.\n\n```gleam\nimport gleam/io\n\n// Nil(1) ↔ true(⊤): a trivial proof you can always build. Zero information.\npub fn trivial() -> Nil {\n  Nil\n}\n\n// void(0) ↔ false(⊥): a type with no inhabitants. \"No value can be built\" means \"no proof\".\npub type Void\n\npub fn absurd(v: Void) -> a {\n  case v {\n    _ -> panic\n  }\n}\n\npub fn main() -> Nil {\n  let _ = trivial()\n  io.println(\"ok\")\n}\n```",
      ),
      tmcq(
        "ch-ex-2",
        "Which statement about `pub type Void` (zero constructors) is correct?",
        [
          "There is no normal way to build a value of type `Void` — it corresponds to the proposition ⊥ (false)",
          "`Void` is the same as `Nil`",
          "`absurd` produces any `a` from a `Void` value, so any proposition really is proven from ⊥",
        ],
        0,
        "Since there are no inhabitants, there is no way to call `absurd` normally either. This \"cannot be built\" is exactly the heart of ⊥↔void.",
        [
          #(
            1,
            "`Nil` has *1* element (↔ true), `Void` has *0* elements (↔ false). They are opposite extremes.",
          ),
          #(
            2,
            "It is a trap. `absurd` does compile, but that is thanks to `panic` (a runtime crash), not because the compiler proved ex falso. Besides, you cannot even build a `Void` value, so you cannot call `absurd` at all. Gleam is not a theorem prover.",
          ),
        ],
      ),
    ],
  )
}

fn l_06_b() -> Lesson {
  tlesson(
    "tu06-curry-howard-l02-parametricity",
    "tu06-curry-howard",
    "The Signature Pins Down the Implementation — Parametricity",
    [
      Theory("parametricity"),
      Theory("free-theorems"),
      Theory("parametricity-overclaim"),
    ],
    [
      tprose(
        "param-prose-1",
        "A generic signature *determines* far more than you might think. When a function takes a type variable `a`, there is no way inside that function to know whether `a` is an Int or a String — you can neither inspect it nor create a new `a`.\n\nSo **(assuming purity and totality)** the only inhabitant of `fn(a) -> a` is **the identity function**, and the only inhabitant of `fn(a, b) -> a` is **the one that returns the first argument**. Facts that \"follow for free just from looking at the signature\" like this are called *free theorems*, and their root is parametricity.\n\n```gleam\nimport gleam/io\nimport gleam/list\n\n// fn(a) -> a : you can never know the concrete identity of a, so you cannot touch it.\n// (if pure and total) the identity function is the unique inhabitant.\npub fn id(x: a) -> a {\n  x\n}\n\n// fn(a, b) -> a : the only a value you can place in the return slot is the first argument.\npub fn const_first(x: a, _y: b) -> a {\n  x\n}\n\n// fn(List(a)) -> List(a) : you cannot inspect the elements, so you can only cut/reverse/duplicate.\npub fn same_or_rev(xs: List(a)) -> List(a) {\n  list.reverse(xs)\n}\n\npub fn main() -> Nil {\n  assert id(42) == 42\n  assert const_first(1, \"ignored\") == 1\n  assert same_or_rev([1, 2, 3]) == [3, 2, 1]\n  io.println(\"ok\")\n}\n```",
      ),
      tpredict(
        "param-ex-1",
        "A function `mystery` of type `fn(a, b) -> a` has its body hidden, and we print `int.to_string(mystery(7, \"hello\"))`. What is the output?",
        "import gleam/io\nimport gleam/int\n\n// The signature is fn(a, b) -> a. The body is hidden. Predict the call result only.\npub fn mystery(x: a, _y: b) -> a {\n  x\n}\n\npub fn main() -> Nil {\n  io.println(int.to_string(mystery(7, \"hello\")))\n}",
        ["`7`", "`hello`", "`7hello`"],
        0,
        "The signature gives you the answer. The return type is `a` (= the type of the first argument), and the function body cannot *fabricate* a new `a`, so if it is pure and total, the only thing it can return is the first argument `7`. You can get it right without looking at the body.",
        [
          #(
            1,
            "`hello` is the second argument (type `b`). Since the return type is `a`, a `b` value could never go in that slot in the first place — if it did, it would be a type error.",
          ),
        ],
      ),
      tprose(
        "param-prose-2",
        "Free theorems also pinpoint \"things you cannot do\". But you have to state precisely *what* you cannot do. What `fn(List(a)) -> List(a)` guarantees is that **every element that appears in the output came from the input** — since you do not know what `a` is, you can neither *fabricate* a new `a` nor *insert* an external constant into an `a` slot. Try it and the compiler stops you: `[5, ..xs]` has `5: Int`, which clashes with `List(a)`, giving a `Type mismatch`.\n\n**Here we correct a common overclaim**: this theorem says nothing about *length*. *Duplicating and rearranging* elements is perfectly allowed, so a pure, total function that doubles the length like `list.append(xs, xs)` has the **same signature** (length 3 → 6). In other words, claims like \"the length can never grow\" or \"the result must be a subsequence or permutation\" are *false* (append is a counterexample). All a free theorem guarantees is that the *origin* of the output elements is the input.\n\n```gleam\nimport gleam/io\nimport gleam/list\n\n// Candidate A: signature fn(List(a)) -> List(a)\npub fn keep_all(xs: List(a)) -> List(a) {\n  xs\n}\n\n// Candidate B: same signature — drops the first element\npub fn drop_first(xs: List(a)) -> List(a) {\n  case xs {\n    [] -> []\n    [_, ..rest] -> rest\n  }\n}\n\n// Candidate C: same signature — concatenates the input twice to *grow* the length (duplication).\npub fn dup(xs: List(a)) -> List(a) {\n  list.append(xs, xs)\n}\n\npub fn main() -> Nil {\n  let sample = [10, 20, 30]\n  assert keep_all(sample) == [10, 20, 30]\n  assert drop_first(sample) == [20, 30]\n  assert dup(sample) == [10, 20, 30, 10, 20, 30]\n  assert list.length(dup(sample)) == 6\n  io.println(\"None of the three candidates can fabricate an element that was not in the input — but the length can change via duplication\")\n}\n```",
      ),
      tmcq(
        "param-ex-2",
        "All three definitions below *claim* the signature `fn(a) -> a`. Pick the **one piece of code that violates the free theorem (\"identity only\") — i.e., would have been impossible if it were pure and total**.",
        [
          "`pub fn f1(x: a) -> a { x }`",
          "`pub fn f2(x: a) -> a { let assert [_] = [x] x }`",
          "`pub fn f3(_x: a) -> a { io.println(\"side effect!\") panic as \"does not return a value\" }`",
        ],
        2,
        "(C) wears the same signature but performs a side effect and ultimately never returns a value (panic). Just from the signature, it is indistinguishable from (A) — and that is the point. So \"`fn(a) -> a` is identity only\" is not unconditionally true; it carries the caveat **\"if pure and total\"**. Gleam does not enforce totality or purity, so a signature like (C) compiles too.",
        [
          #(
            0,
            "(A) is literally the identity function. Far from violating the free theorem, it is exactly the unique inhabitant the theorem describes.",
          ),
          #(
            1,
            "(B) takes a messy detour, but once the `let assert` passes it returns `x` unchanged. Observationally it is the same as identity. The one that actually breaks the promise is (C).",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu06() -> Unit {
  tunit(
    UnitMeta(
      id: "tu06-curry-howard",
      title: "Curry-Howard and Parametricity",
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
    "Composition is FP's multiplication",
    [Theory("composition"), Theory("composition-order")],
    [
      tprose(
        "compose-intro",
        "Function composition is the basic operation that wires \"the output of one function into the input of the next.\" In mathematical notation, `(f ∘ g)(x) = f(g(x))` — **g runs first**. Gleam has **neither** a composition operator (like `>>`) **nor** a `compose` in its stdlib. So we build it ourselves. Once built, its true identity is revealed: the U2 pipe `x |> g |> f` is in fact the very same composition written *value-first*.\n\n```gleam\nimport gleam/io\nimport gleam/int\n\n// Gleam has no `>>` operator and no `compose` in stdlib — we write it.\npub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {\n  fn(x) { f(g(x)) }\n}\n\nfn inc(x: Int) -> Int { x + 1 }\nfn double(x: Int) -> Int { x * 2 }\n\npub fn main() -> Nil {\n  let inc_after_double = compose(inc, double)\n  assert inc_after_double(5) == 11\n  // compose(f, g) and x |> g |> f compute the same thing:\n  assert inc_after_double(5) == { 5 |> double |> inc }\n  io.println(int.to_string(inc_after_double(5)))\n}\n```\n\nLet's be honest about one caveat here. This `compose` is general **only over plain functions `fn(a) -> b`**. \"A single composition that wires together every Functor/Monad\" **cannot be written** in Gleam, because Gleam has neither type classes nor higher-kinded types (HKT). Composition and identity are not a *language feature* — they are a *pattern we recognize* across various concrete types.",
      ),
      tpredict(
        "compose-order-predict",
        "In the code above, if you use `compose(double, inc)(5)` instead of `compose(inc, double)`, what is its value?",
        "compose(double, inc)(5)",
        ["`11`", "`12`", "`7`"],
        1,
        "`compose(f, g)` runs g first. `compose(double, inc)` runs inc first → `5+1=6` → `6*2=12`. Even with the same two functions, swapping the order yields a different result — composition does **not** commute.",
        [
          #(
            0,
            "`11` is the value of `compose(inc, double)`. It runs double first (`5*2=10`) and then inc (`11`). You missed that the argument order of the two calls is swapped — watch out for the asymmetry: the first argument of `compose` is the function that runs *later*.",
          ),
        ],
      ),
      tprose(
        "pipe-vs-compose",
        "So what is the relationship between the pipe and `compose`? `x |> g |> f` runs g first, left-to-right, so **reading order = execution order**. By contrast, the mathematical form `f ∘ g` (our `compose(f, g)`) still runs g first, but its **reading order is reversed** (the left-hand f runs later). That is, `compose(f, g)(x)` ≡ `x |> g |> f`. They are just the same computation written in two directions. The tricky part is precisely this mismatch of \"reading direction ↔ execution direction.\"\n\n```gleam\nfn inc(x: Int) -> Int { x + 1 }\nfn double(x: Int) -> Int { x * 2 }\n\npub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {\n  fn(x) { f(g(x)) }\n}\n\npub fn main() -> Nil {\n  io.println(int.to_string(3 |> inc |> double))        // inc first: 4 -> 8\n  io.println(int.to_string(compose(double, inc)(3)))   // inc first: 4 -> 8\n  io.println(int.to_string(compose(inc, double)(3)))   // double first: 6 -> 7\n}\n```",
      ),
      tmcq(
        "pipe-to-compose-mcq",
        "Rewrite it while preserving the equation. What point-free composition produces the same value on all inputs as the piped expression `fn(x) { x |> double |> inc }`? (Blank: `let step2 = compose(???, ???)`)",
        [
          "`compose(inc, double)`",
          "`compose(double, inc)`",
          "`compose(double, inc)(x)`",
        ],
        0,
        "The pipe runs `double` first → then `inc`. To write that same execution order with `compose`, put *the function that runs later in front*: `compose(inc, double)`. The reflex this unit drills is that the reading order flips.",
        [
          #(
            1,
            "That is the same as `x |> inc |> double` — inc runs first. To carry the execution order of the pipe `|> double |> inc` (double→inc) over to `compose`, you must write it in *reverse*, so it becomes `compose(inc, double)`. It's the same non-commutativity trap you saw in the previous exercise.",
          ),
          #(
            2,
            "The rewrite target is a single *function value* (`fn(Int) -> Int`). Adding `(x)` turns it into a value, which is no longer point-free style — don't take the argument `x`; just return the composition.",
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
    "Two laws: identity and associativity",
    [Theory("identity-law"), Theory("composition-associativity")],
    [
      tprose(
        "identity-law-intro",
        "Composition has an **identity element** corresponding to `1` in multiplication — `function.identity` (`fn(x) { x }`). The identity law: `id ∘ f == f == f ∘ id`. Whether you attach it in front or behind, it does nothing. This is not merely a fact but a *law*, and we can sample-check laws as an **executable property** — using `assert` to see whether the equation holds across several inputs.\n\n```gleam\nimport gleam/io\nimport gleam/list\nimport gleam/function\n\npub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {\n  fn(x) { f(g(x)) }\n}\n\nfn double(x: Int) -> Int { x * 2 }\nfn inc(x: Int) -> Int { x + 1 }\n\n// Law as an executable property: identity law sampled over inputs.\nfn check_identity_law(f: fn(Int) -> Int, samples: List(Int)) -> Bool {\n  let id = function.identity\n  list.all(samples, fn(x) {\n    compose(id, f)(x) == f(x) && compose(f, id)(x) == f(x)\n  })\n}\n\npub fn main() -> Nil {\n  let samples = [-2, 0, 1, 5, 100]\n  assert check_identity_law(double, samples)\n  assert check_identity_law(inc, samples)\n  io.println(\"laws hold\")\n}\n```",
      ),
      tmcq(
        "identity-law-spot-bug",
        "Among the four \"identity law demonstrations\" below, pick the one that **states the law incorrectly**.",
        [
          "`compose(function.identity, f)(x) == f(x)`",
          "`compose(f, function.identity)(x) == f(x)`",
          "`function.identity(f(x)) == f(x)`",
          "`compose(f, g)(x) == compose(g, f)(x)`",
        ],
        3,
        "(d) is *commutativity*, which does not hold for composition (confirmed in the previous lesson, P1). (a) and (b) are the two sides of the identity law, and (c) is the very definition of `identity` — all of them are true.",
        [
          #(
            1,
            "(b) is true — `f ∘ id`. Even if you attach `id` on the right, the input passes straight into f, so it equals `f`. The point of the identity law is that it holds *on either the left or the right*.",
          ),
          #(
            2,
            "(c) is the definition of `identity` itself (since `identity(y) == y`, plugging in `y = f(x)` makes it true). It is not a law violation — the violation is only (d), which assumes commutativity.",
          ),
        ],
      ),
      tprose(
        "associativity-intro",
        "The second law is **associativity**: `(f ∘ g) ∘ h == f ∘ (g ∘ h)`. When chaining three, the result is the same no matter where you place the parentheses — which is why we usually *omit* the parentheses and write `f ∘ g ∘ h` (it's also why a pipe chain `|> h |> g |> f` reads flatly). The world where these two laws — identity + associativity — hold, with \"objects = types, morphisms = functions,\" is called a **category** in mathematics. You only need to know the name — we won't go deep into it. What matters is that *these two laws are the seed of the functor/monad laws to come* (the functor laws are, in their entirety, just that a functor preserves composition and identity).\n\n```gleam\npub fn compose(f: fn(b) -> c, g: fn(a) -> b) -> fn(a) -> c {\n  fn(x) { f(g(x)) }\n}\n\nfn inc(x: Int) -> Int { x + 1 }\nfn double(x: Int) -> Int { x * 2 }\nfn square(x: Int) -> Int { x * x }\n\n// Associativity sampled as an executable property.\nfn check_assoc(f, g, h, samples: List(Int)) -> Bool {\n  list.all(samples, fn(x) {\n    compose(compose(f, g), h)(x) == compose(f, compose(g, h))(x)\n  })\n}\n```",
      ),
      tpredict(
        "assoc-predict",
        "What is the value of `compose(compose(inc, double), inc)(3)`? (`inc(x)=x+1`, `double(x)=x*2`)",
        "compose(compose(inc, double), inc)(3)",
        ["`9`", "`10`", "`8`"],
        0,
        "Starting from the innermost argument: `inc(3)=4` → `double(4)=8` → `inc(8)=9`. Thanks to associativity, even if you move the parentheses to `compose(inc, compose(double, inc))(3)`, you still get `9` — that's the property demonstrated in this lesson.",
        [
          #(
            1,
            "`10` is the value you get when you imagine an order like `double(inc(inc(3)))`. Reconfirm the asymmetry that the first argument of `compose` is the *outer one (runs later)*: `compose(F, G)` runs G first, and here the innermost `inc` runs first of all.",
          ),
          #(
            2,
            "`8` is the value with the final `inc` dropped (`double(inc(3))`). With three functions composed, all three are applied once each.",
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
      title: "Composition and identity",
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
    "Combining two of the same shape into one — ⊕ and e",
    [Theory("monoid"), Theory("monoid-fold")],
    [
      tprose(
        "l01-s1",
        "A monoid isn't anything grand — it's just **three things bundled together**: some type `T`, a binary operation `⊕ : (T, T) -> T` that combines two values of the same type into one, and an **identity element** `e : T` that corresponds to \"adding nothing.\" You already know several of them: `(Int, +, 0)`, `(Int, *, 1)`, `(String, <>, \"\")`, `(List, append, [])`. The core intuition is \"combine two and get one of the same kind back + there's a default value for when there's nothing to combine.\"\n\n```gleam\nimport gleam/list\n\n// \"Summarize\" the fact that (List, append, []) is a monoid using fold\npub fn concat(xss: List(List(a))) -> List(a) {\n  list.fold(xss, [], fn(acc, xs) { list.append(acc, xs) })\n}\n// concat([[1, 2], [3], [4, 5]]) == [1, 2, 3, 4, 5]\n```",
      ),
      tpredict(
        "l01-p1",
        "What is the value of `concat([[1, 2], [3], [4, 5]])`?",
        "concat([[1, 2], [3], [4, 5]])",
        ["`[1, 2, 3, 4, 5]`", "`[[1, 2], [3], [4, 5]]`", "`[5, 4, 3, 2, 1]`"],
        0,
        "With `⊕ = list.append` and `e = []`, folding from the left flattens every piece into a single list in order — this is the most visual example of 'summarizing with a monoid.'",
        [
          #(
            2,
            "That reversal happens when you fold with `[x, ..acc]` (prepend) (U8-④, `acc-reverse`). Here `⊕` is `list.append`, not prepend, and append preserves order.",
          ),
        ],
      ),
      tprose(
        "l01-s2",
        "`Bool` is also a monoid in two different ways — `(Bool, &&, True)` and `(Bool, ||, False)`. The knack for choosing the identity: for `e ⊕ a == a` to hold, e must be the \"neutral value that doesn't change the result.\" For `&&`, since `True && a == a`, the identity is `True`; for `||`, since `False || a == a`, it's `False`. **Even for the same type, when the operation changes, so does the identity.**\n\n```gleam\nimport gleam/list\n\npub fn all_true(xs: List(Bool)) -> Bool {\n  list.fold(xs, True, fn(acc, b) { acc && b })\n}\n\npub fn any_true(xs: List(Bool)) -> Bool {\n  list.fold(xs, False, fn(acc, b) { acc || b })\n}\n// all_true([True, True, False]) == False\n// any_true([False, False, True]) == True\n```",
      ),
      tmcq(
        "l01-p2",
        "Which of the following identity pairs is **incorrectly** matched?",
        [
          "`(Int, +) → 0`",
          "`(Int, *) → 1`",
          "`(String, <>) → \"\"`",
          "`(Bool, &&) → False`",
        ],
        3,
        "`False && a` is always `False`, so it swallows a whole — that's not an identity but an *absorbing element* (zero). The correct identity is `True`.",
        [
          #(
            1,
            "`1 * a == a`, so the identity of multiplication really is 1. It plays exactly the same role as 0 does for addition, just in a different slot. In the next lesson you'll see the trap of 'what if you use 0 as the identity for multiplication?' firsthand.",
          ),
        ],
      ),
    ],
  )
}

fn l_08_b() -> Lesson {
  tlesson(
    "tu08-monoid-l02-laws-as-properties",
    "tu08-monoid",
    "Laws are runnable properties",
    [Theory("monoid-laws"), Theory("monoid-fold")],
    [
      tprose(
        "l02-s1",
        "Saying a monoid **obeys laws** isn't an abstract promise — they're **equations that must hold true**. There are only two: **associativity** `a ⊕ (b ⊕ c) == (a ⊕ b) ⊕ c`, and **left/right identity** `e ⊕ a == a == a ⊕ e`. Gleam has no property-testing framework in its stdlib, but thanks to the referential transparency we saw in TU1, we can **run the laws directly with `assert` over sample inputs** — the moment a law becomes \"visible.\" But let's be honest: **a sample `assert` does *not* prove a law.** It's closer to an *attempt at refutation* on specific inputs (a miniature property test).\n\n```gleam\nimport gleam/io\nimport gleam/list\nimport gleam/int\n\nfn op(a: Int, b: Int) -> Int {\n  a + b\n}\n\nfn empty() -> Int {\n  0\n}\n\npub fn main() -> Nil {\n  let a = 5\n  let b = 8\n  let c = 13\n  // Associativity: the result is the same even if you change the grouping order\n  assert op(a, op(b, c)) == op(op(a, b), c)\n  // Left identity / right identity\n  assert op(empty(), a) == a\n  assert op(a, empty()) == a\n  io.println(\"monoid sample checks passed for (Int, +, 0)\")\n  io.println(int.to_string(list.fold([1, 2, 3], empty(), op)))\n}\n// Output:\n// monoid sample checks passed for (Int, +, 0)\n// 6\n```",
      ),
      tpredict(
        "l02-p1",
        "What is the output of the `main` above?",
        "pub fn main() -> Nil {\n  let a = 5\n  let b = 8\n  let c = 13\n  assert op(a, op(b, c)) == op(op(a, b), c)\n  assert op(empty(), a) == a\n  assert op(a, empty()) == a\n  io.println(\"monoid sample checks passed for (Int, +, 0)\")\n  io.println(int.to_string(list.fold([1, 2, 3], empty(), op)))\n}",
        [
          "Two lines: `monoid sample checks passed for (Int, +, 0)` and `6`",
          "Crashes with Assertion failed",
          "Just one line: `6`",
        ],
        0,
        "All three `assert`s pass on this sample (they fail to refute the law), so without crashing we reach both `io.println`s. `op` has the signature `fn(Int, Int) -> Int`, so it slips *as-is* into the fold callback's `fn(acc, x)` slot.",
        [
          #(
            1,
            "`(Int, +, 0)` is a genuine monoid, so it passes this sample check. An `assert` blows up only when a law is *broken* (when it meets a counterexample), and we'll see that case in lesson ④ — honesty: Gleam has no exceptions, so a failed `assert` doesn't *return*, it **crashes** the program.",
          ),
        ],
      ),
      tprose(
        "l02-s2",
        "One paragraph of honesty — **Gleam has no Monoid typeclass.** The `op`/`empty` above are **not** declarations that \"register this type as a Monoid with the compiler.\" They're just ordinary functions we made by hand, and we pass `e` and `⊕` **directly** to fold. Gleam has neither typeclasses nor HKTs, so \"a single generic `mconcat` that works for every monoid\" **cannot be written** — the idiom is to pass `e` and `⊕` to fold on the spot for each type. The core pattern is just one: **swap only (e, ⊕) into the same fold skeleton.**\n\n```gleam\nimport gleam/list\nimport gleam/string\n\npub fn sum(xs: List(Int)) -> Int {\n  list.fold(xs, 0, fn(acc, x) { acc + x })\n}\n\npub fn product(xs: List(Int)) -> Int {\n  list.fold(xs, 1, fn(acc, x) { acc * x })\n}\n\npub fn join_all(xs: List(String)) -> String {\n  list.fold(xs, \"\", fn(acc, s) { acc <> s })\n}\n\n// If you need a separator, stdlib's string.join is another variation on the same 'monoid summary'\npub fn join_csv(xs: List(String)) -> String {\n  string.join(xs, \", \")\n}\n// sum([1, 2, 3, 4]) == 10\n// product([1, 2, 3, 4]) == 24\n// join_all([\"a\", \"b\", \"c\"]) == \"abc\"\n// join_csv([\"a\", \"b\", \"c\"]) == \"a, b, c\"\n```",
      ),
      tmcq(
        "l02-p2",
        "Suppose you want to move `sum` to the same skeleton \"while preserving the equations.\" What happens if you change `sum`'s initial value `e` from `0` to `1`?",
        [
          "`sum([]) == 1`, so the equation breaks",
          "The sum stays the same, so there's no problem at all",
          "It causes a compile error",
        ],
        0,
        "`e` is the *identity* determined by the combining function. The identity of `+` is `0`, so changing `e` to `1` makes `sum([]) == 1` and breaks the equation. A rewrite must *preserve values*, so when you move the skeleton you must move the `(e, ⊕)` pair together as a whole.",
        [
          #(
            1,
            "No — it shows up on the empty list. Changing `e` to `1` makes `sum([]) == 1`, which is no longer the identity of `+` (`0`), and the equation breaks. The only thing that changes is *where you pick (e, ⊕)*; the `(e, ⊕)` pair must move together as a whole.",
          ),
          #(
            2,
            "The type stays `Int`, so it compiles — the problem is the *value*. Changing `e` to `1` makes `sum([]) == 1` and breaks the equation.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu08() -> Unit {
  tunit(
    UnitMeta(
      id: "tu08-monoid",
      title: "Monoids",
      order: 8,
      level: 7,
      concepts: [Theory("monoid"), Theory("monoid-laws"), Theory("monoid-fold")],
      prerequisites: ["tu07-composition", "tu02-equational"],
      lesson_ids: [
        "tu08-monoid-l01-op-and-e",
        "tu08-monoid-l02-laws-as-properties",
      ],
    ),
    [l_08_a(), l_08_b()],
  )
}

// ── tu09-functor ─────────────────────────────────────────────
fn l_09_a() -> Lesson {
  tlesson(
    "tu09-functor-l01-shape",
    "tu09-functor",
    "One Shape Called map",
    [Theory("functor"), Theory("functor-instances"), Theory("no-hkt")],
    [
      tprose(
        "shape-intro",
        "In U8 you learned `list.map`, and in U9 you learned `option.map` and `result.map` separately. Now place all three side by side and the **same shape** appears — \"leave the wrapping structure (`List`/`Option`/`Result`) untouched, and apply the function *only to the contents inside*.\" A list's length doesn't change, `Some` stays `Some`, `Ok` stays `Ok` — only the value changes. This \"preserve the structure + transform the contents\" shape is called a **functor**. A functor is *not a typeclass or an interface*; it's a **pattern you recognize** over and over across many concrete types.\n\n```gleam\nimport gleam/int\nimport gleam/list\nimport gleam/option.{type Option, None, Some}\nimport gleam/result\n\npub fn shapes() -> #(List(Int), Option(Int), Result(Int, Nil)) {\n  let xs = list.map([1, 2, 3], fn(x) { x * 10 })\n  let o = option.map(Some(5), fn(x) { x * 10 })\n  let r = result.map(Ok(7), fn(x) { x * 10 })\n  #(xs, o, r)\n}\n// shapes() == #([10, 20, 30], Some(50), Ok(70))\n```",
      ),
      tpredict(
        "shape-predict",
        "What are the values of `option.map(Some(10), fn(x) { x + 5 })` and `option.map(None, fn(x: Int) { x + 5 })`?",
        "import gleam/option.{None, Some}\n\npub fn run() -> #(option.Option(Int), option.Option(Int)) {\n  let a = option.map(Some(10), fn(x) { x + 5 })\n  let b = option.map(None, fn(x: Int) { x + 5 })\n  #(a, b)\n}",
        ["`Some(15)` / `None`", "`Some(15)` / `Some(0)`", "`15` / `None`"],
        0,
        "Structure preservation is the key — `Some` stays `Some`, `None` stays `None`, and the function is applied *only when there is content*.",
        [
          #(
            1,
            "`None` has no content to apply the function to. map's function is *not called*, and `None` passes straight through — this short-circuit behavior is exactly what it means for a functor to respect the 'structure'.",
          ),
          #(
            2,
            "map never unwraps the wrapper. It returns `Some(15)`, not a bare `15` — the rule from U9, 'a Result/Option value never comes out bare', applies here too. To extract it you still need a separate `case` or `option.unwrap`.",
          ),
        ],
      ),
      tprose(
        "shape-nohkt",
        "The *function argument* (`fn(x) { x * 10 }`) is identical across all three calls. The only difference is which module's `map` you call. Here's the honest fact: **Gleam has neither a `Functor` typeclass nor higher-kinded types (HKT)**. So you can't write \"a single `map` that takes any functor\" — for each type you must call `list.map`/`option.map`/`result.map` *individually*. A functor isn't \"an interface you implement\"; it's \"a pattern you recognize\" in your head.\n\n```gleam\nimport gleam/list\n\n// If you try to write \"a single map that works on any functor\"…\n// you'd need to leave the container type itself as a type variable f and write f(a),\n// but Gleam has no HKT, so you can't apply a type variable to another type (f(a)).\npub fn generic_map(container: f(a), fun: fn(a) -> b) -> f(b) {\n  list.map(container, fun)\n}\n```",
      ),
      tmcq(
        "shape-generic-map",
        "What happens when you compile the `generic_map` above?",
        [
          "Compiles fine",
          "Syntax error — unexpected `(` in `f(a)`",
          "Type mismatch",
          "Runtime crash",
        ],
        1,
        "`f(a)` is the expression 'apply a type variable to a type', but that's a higher-kinded type (HKT), and Gleam has none. The parser hits the `(` where a type argument should be and stops right there.",
        [
          #(
            0,
            "In another language (Haskell's `Functor f => f a -> f b`) this would be possible. Gleam deliberately omits HKT to avoid 'confusing error messages, long compile times, and runtime cost'. The price is a little repetition — calling map per type — and the reward is simplicity.",
          ),
          #(
            2,
            "It's blocked not because the types don't match, but because *the statement itself isn't valid syntax* — it never even reaches the type-checking stage.",
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
    "The Two Functor Laws",
    [Theory("functor-laws"), Theory("functor-law-violation"), Theory("functor")],
    [
      tprose(
        "laws-intro",
        "For a `map` to be a 'real functor', it must obey two laws. ① **Identity**: `map(x, identity) == x` — mapping with the do-nothing function leaves the original unchanged. ② **Composition**: `map(map(x, g), f) == map(x, fn(a) { f(g(a)) })` — \"mapping twice = mapping once with the composed function\". These laws aren't abstract promises but **executable properties** — you can check them directly with `assert` on sample inputs inside `main`.\n\n```gleam\nimport gleam/io\nimport gleam/list\nimport gleam/option.{None, Some}\nimport gleam/function\n\npub fn main() -> Nil {\n  // identity law: map(x, identity) == x\n  assert list.map([1, 2, 3], function.identity) == [1, 2, 3]\n  assert option.map(Some(7), function.identity) == Some(7)\n  assert option.map(None, function.identity) == None\n\n  // composition law: map(map(x, g), f) == map(x, fn(a) { f(g(a)) })\n  let g = fn(n: Int) { n + 1 }\n  let f = fn(n: Int) { n * 10 }\n  assert list.map(list.map([1, 2], g), f) == list.map([1, 2], fn(a) { f(g(a)) })\n\n  io.println(\"all functor laws hold on the sample\")\n}\n// output: all functor laws hold on the sample\n```",
      ),
      tpredict(
        "laws-predict",
        "When you run the `main` above, what is printed to stdout?",
        "import gleam/io\nimport gleam/list\nimport gleam/option.{None, Some}\nimport gleam/function\n\npub fn main() -> Nil {\n  assert list.map([1, 2, 3], function.identity) == [1, 2, 3]\n  assert option.map(Some(7), function.identity) == Some(7)\n  assert option.map(None, function.identity) == None\n\n  let g = fn(n: Int) { n + 1 }\n  let f = fn(n: Int) { n * 10 }\n  assert list.map(list.map([1, 2], g), f) == list.map([1, 2], fn(a) { f(g(a)) })\n\n  io.println(\"all functor laws hold on the sample\")\n}",
        [
          "`all functor laws hold on the sample`",
          "Runtime error (assert fails)",
          "Nothing is printed",
        ],
        0,
        "Every `assert` is `True`, so nothing halts and execution reaches the final `println` — both `list.map` and `option.map` obey the functor laws. (For the composition law, the left side is `[(1+1)*10, (2+1)*10] = [20, 30]`, and the right side is also `[20, 30]`, so they match.)",
        [
          #(
            1,
            "The stdlib's `map` functions are implemented to satisfy the laws, so the sample check passes. An assert breaks only when you check a *fake map that violates the laws*, and we go hunting for those in the next lesson.",
          ),
          #(
            2,
            "When all asserts pass, the final `io.println` runs and prints one line — there's no reason to stop partway.",
          ),
        ],
      ),
      tprose(
        "laws-box",
        "These laws are demanded equally of functors you build yourself. `map_box` over `Box(a)` is also a functor — you can sample-check the same two laws for `Box`. (Honesty: this check too must be written *by hand* for `Box` — there's no general function that 'checks the laws of every functor at once', because there's no HKT.)\n\n```gleam\nimport gleam/function\n\npub type Box(a) {\n  Box(inner: a)\n}\n\npub fn map_box(box: Box(a), f: fn(a) -> b) -> Box(b) {\n  Box(f(box.inner))\n}\n\npub fn map_box_obeys_identity(b: Box(Int)) -> Bool {\n  map_box(b, function.identity) == b\n}\n// map_box_obeys_identity(Box(0)) == True\n```",
      ),
      tmcq(
        "laws-write-fn",
        "Write `pub fn map_box_obeys_identity(b: Box(Int)) -> Bool` — it returns whether the identity law (`map_box(b, identity) == b`) holds for an arbitrary `Box(Int)`. You expect `True` for `Box(0)`/`Box(-3)`/`Box(99)`. What's the correct body?",
        [
          "`map_box(b, b.inner)`",
          "`map_box(b, function.identity) == b`",
          "`map_box(b, function.identity) == b.inner`",
          "`identity(b) == b`",
        ],
        1,
        "The single line `map_box(b, function.identity) == b` is all you need — the law is the code. By writing the law as an executable property like this, even if someone later breaks `map_box` while 'optimizing' it, this check will catch it.",
        [
          #(
            0,
            "The second argument of `map_box` must be a *function*. `b.inner` is an `Int` value, not a `fn(a) -> b`, so the type doesn't match.",
          ),
          #(
            2,
            "Match the types on both sides. The result of `map_box` is a `Box(Int)`, not an `Int` — functor laws always compare *the whole structure*.",
          ),
          #(
            3,
            "For the law to mean anything, it must compare the result *passed through* `map_box` against the original. `identity(b)` never goes through map, so it doesn't check at all whether `map_box` preserves structure.",
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
      title: "The Functor Pattern",
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
    "Combining Two Independent Contexts (Applicative)",
    [Theory("applicative")],
    [
      tprose(
        "ap-intro",
        "In TU9, `result.map(r, f)` *preserved* one layer of context (`Result`) while transforming the single value inside (a functor). But what if there are **two** inputs and both are wrapped in a context? `parse_age(a)` and `parse_age(b)` are **two independent computations that don't see each other**. The pattern of \"gathering several independent contexts and assembling them into one\" is the applicative. Since Gleam has no `Applicative` typeclass, we express that pattern **by `case`-ing on both Results at once**, by hand.\n\n```gleam\nimport gleam/int\n\npub type AgeError {\n  NotANumber\n  Negative\n}\n\npub fn parse_age(input: String) -> Result(Int, AgeError) {\n  case int.parse(input) {\n    Error(Nil) -> Error(NotANumber)\n    Ok(n) ->\n      case n < 0 {\n        True -> Error(Negative)\n        False -> Ok(n)\n      }\n  }\n}\n\n// Applicative pattern: combine two independent contexts. Stops at the first Error.\npub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  case parse_age(a), parse_age(b) {\n    Ok(x), Ok(y) -> Ok(x + y)\n    Error(e), _ -> Error(e)\n    _, Error(e) -> Error(e)\n  }\n}\n// add_ages(\"3\", \"4\") == Ok(7)\n// add_ages(\"3\", \"x\") == Error(NotANumber)\n```",
      ),
      tpredict(
        "ap-predict-add",
        "What is the value of `add_ages(\"3\", \"x\")`?",
        "add_ages(\"3\", \"x\")",
        ["`Ok(3)`", "`Error(NotANumber)`", "`Error(Negative)`"],
        1,
        "The two arguments are *independent*, so both are evaluated, but the combining rule is 'only `Ok` when both are `Ok`'; otherwise it emits the first `Error` — exactly the second and third `case` branches you wrote by hand.",
        [
          #(
            0,
            "As long as the context is alive, the inner value never comes out bare. Once `b` fails, the whole function must return a failure context — the 'context preservation' you saw in TU9 is extended here to 'context combination'. The `+` happens *only when both succeed*.",
          ),
          #(
            2,
            "As long as the context is alive, the inner value never comes out bare. Once `b` fails, the whole function must return a failure context — the 'context preservation' you saw in TU9 is extended here to 'context combination'. The `+` happens *only when both succeed*.",
          ),
        ],
      ),
      tprose(
        "ap-use",
        "The same applicative pattern can also be written with `use`. Two lines of `use x <- result.try(parse_age(a))` followed by **assembling** with `Ok(x + y)`. But there is a trap here: `use`/`result.try` are actually monad tools (next lesson). If the two computations are *truly independent*, the result is the same either way, but the fact that the intent you want to express is \"independent combination\" is shown more honestly by `case a, b`. **An honest limitation**: Gleam has no `Applicative` and no HKT, so there is no *single notation over an arbitrary applicative* like Haskell's `(+) <$> pa <*> pb`. You assemble by hand each time, fitting it to that type.\n\n```gleam\nimport gleam/result\n\n// The same applicative intent as two use lines + Ok assembly\npub fn add_ages_use(a: String, b: String) -> Result(Int, AgeError) {\n  use x <- result.try(parse_age(a))\n  use y <- result.try(parse_age(b))\n  Ok(x + y)\n}\n// add_ages_use(\"3\", \"4\") == Ok(7)\n```",
      ),
      tmcq(
        "ap-order-use",
        "Reorder the following line fragments into the correct order to complete `add_ages_use` (`(\"3\",\"4\")->Ok(7)`, `(\"x\",\"4\")->Error(NotANumber)`). Which order is correct?",
        [
          "`use x <- result.try(parse_age(a))` → `use y <- result.try(parse_age(b))` → `Ok(x + y)`",
          "`use x <- result.try(parse_age(a))` → `use y <- result.try(parse_age(b))` → `x + y`",
          "`use a <- result.try(parse_age(a))` → `use a <- result.try(parse_age(b))` → `Ok(a + a)`",
        ],
        0,
        "After unwrapping the two independent contexts one by one, the `Ok(...)` that *re-wraps* the combined result back into a context is the applicative 'assembly' step. The names must differ (`x`, `y`) so that both can be used in the last line.",
        [
          #(
            1,
            "Even after unwrapping both contexts, the function's return type is still `Result(Int, AgeError)`. The `Ok(...)` that *re-wraps* the combined result into a context is the applicative 'assembly' step — the classic 'missing final Ok' from U10③ reappearing on the theory track.",
          ),
          #(
            2,
            "Even for two independent computations, the result names must differ so that both can be used in the last line.",
          ),
        ],
      ),
    ],
  )
}

fn l_10_b() -> Lesson {
  tlesson(
    "tu10-monad-l02-monad-laws",
    "tu10-monad",
    "The Three Monad Laws, and an Honest Limitation",
    [
      Theory("monad"),
      Theory("monad-laws"),
      Theory("bind-vs-map"),
      Theory("no-hkt"),
    ],
    [
      tprose(
        "ml-intro",
        "In the previous lesson we saw that `result.try(m, f)` (= `use`) is a **dependent sequence**: \"if the context is *alive*, proceed to the next computation; if it's dead, short-circuit\" — this is the monad's `bind`. **The reveal**: the moment you chained two `parse_age` calls with `use` in U10, you were already using the Result monad. For a monad to truly be a monad it must obey three laws, and since Gleam has no typeclass to enforce them, we check the laws as **runnable properties** — by sampling with `assert` inside `main`.\n\n```gleam\nimport gleam/io\nimport gleam/result\n\npub type AgeError {\n  NotANumber\n  Negative\n}\n\npub fn main() -> Nil {\n  let f = fn(x: Int) -> Result(Int, AgeError) { Ok(x + 1) }\n  let g = fn(x: Int) -> Result(Int, AgeError) { Ok(x * 10) }\n  let m: Result(Int, AgeError) = Ok(5)\n\n  // left identity:  try(Ok(a), f) == f(a)\n  assert result.try(Ok(5), f) == f(5)\n\n  // right identity: try(m, Ok) == m   (Ok is 'return/pure')\n  assert result.try(m, Ok) == m\n\n  // associativity:    try(try(m, f), g) == try(m, fn(x){ try(f(x), g) })\n  assert result.try(result.try(m, f), g)\n    == result.try(m, fn(x) { result.try(f(x), g) })\n\n  io.println(\"monad laws hold (sampled)\")\n}\n```",
      ),
      tmcq(
        "ml-spot-bug",
        "Among the four `assert`s, pick the one that states a monad law *incorrectly*.",
        [
          "`assert result.try(Ok(5), f) == f(5)`",
          "`assert result.try(m, Ok) == m`",
          "`assert result.try(m, fn(x) { Ok(x) }) == m`",
          "`assert result.try(Ok(5), f) == Ok(5)`",
        ],
        3,
        "Left identity is `try(Ok(a), f) == f(a)` — the value that has *passed through* `f`, not the original value `Ok(a)`. Since `f(5) == Ok(6) != Ok(5)`, this assert breaks at runtime (when an `assert` fails it crashes — the assert semantics from TU/U13).",
        [
          #(
            0,
            "This is the exact statement of left identity `try(Ok(a), f) == f(a)`. It compares against the value passed through `f`, so it is a correct law.",
          ),
          #(
            1,
            "`Ok` is this monad's 'pure (return)'. `try(m, Ok)` is a no-op that 'unwraps the context and immediately puts it back into the same context', so it always equals `m` — a correct law.",
          ),
          #(
            2,
            "`Ok` is this monad's 'pure (return)'. `fn(x) { Ok(x) }` is the same function as `Ok`, so it's just another way of writing `try(m, Ok) == m` — a correct law.",
          ),
        ],
      ),
      tprose(
        "ml-map-vs-try",
        "**`map` or `try`** (`bind-vs-map`). If the callback returns a **bare value**, the context stays at one layer, so use `map`. If the callback returns *another* **wrapped value** (`Result`), the context becomes *two layers* and you get `Result(Result(a, e), e)` — flattening this nesting is `try`'s job. Pick the wrong tool and the types won't line up, or even if they do, the meaning breaks.\n\n```gleam\nimport gleam/result\n\npub fn halve(n: Int) -> Result(Int, AgeError) {\n  case n % 2 == 0 {\n    True -> Ok(n / 2)\n    False -> Error(NotANumber)\n  }\n}\n\n// map: the callback returns another Result, so the context becomes two layers -> nesting\npub fn parse_then_halve_map(\n  s: String,\n) -> Result(Result(Int, AgeError), AgeError) {\n  result.map(parse_age(s), halve)\n}\n// parse_then_halve_map(\"8\") == Ok(Ok(4))   <- not flattened\n\n// try: flatten into a single layer\npub fn parse_then_halve_try(s: String) -> Result(Int, AgeError) {\n  result.try(parse_age(s), halve)\n}\n// parse_then_halve_try(\"8\") == Ok(4)\n// parse_then_halve_try(\"7\") == Error(NotANumber)\n```\n\n**Honest limitation (connecting to U14)**: Gleam has no `Monad` typeclass and no HKT. `use` is merely sugar where \"the entire rest of the lines become the final-argument callback\" — it is not typeclass dispatch. `result.try` works only on `Result`, `option.then` works only on `Option`. Mixing them like `result.try(option.Some(1), ...)` is rejected at compile time with `Expected type: Result(Int, a) / Found type: option.Option(Int)` — this is the concrete price of 'no HKT'. Gleam's way is not 'one abstract function' but 'an explicit `result.try` / `option.then` for each type' — the pattern is the same, but the dispatch is by hand.",
      ),
      tpredict(
        "ml-predict-map-try",
        "What are the values of `parse_then_halve_map(\"8\")` and `parse_then_halve_try(\"8\")` respectively?",
        "parse_then_halve_map(\"8\")\nparse_then_halve_try(\"8\")",
        [
          "`Ok(4)` and `Ok(Ok(4))`",
          "`Ok(Ok(4))` and `Ok(4)`",
          "`Ok(4)` and `Ok(4)`",
        ],
        1,
        "Since `halve` returns a `Result`, `map` *stacks* one more layer of context to make `Ok(Ok(4))`, while `try` absorbs (flattens) that layer to chain into `Ok(4)`. The selection rule is 'if one more layer of context appears, use `try`; otherwise `map`'.",
        [
          #(
            0,
            "The order is swapped. `map` never flattens, so it gives `Ok(Ok(4))`, and `try` flattens to give `Ok(4)`.",
          ),
          #(
            2,
            "`map` never flattens — it just puts the callback's result *as is* inside the context. If the callback is already a `Result`, the `Ok(Ok(...))` nesting is preserved as is. When you see this nested `Result(Result(a,e),e)`, it is almost always a signal that you should change `map` to `try`.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu10() -> Unit {
  tunit(
    UnitMeta(
      id: "tu10-monad",
      title: "Monad and Applicative Patterns",
      order: 10,
      level: 7,
      concepts: [
        Theory("monad"),
        Theory("applicative"),
        Theory("monad-laws"),
        Theory("bind-vs-map"),
      ],
      prerequisites: ["tu09-functor"],
      lesson_ids: ["tu10-monad-l01-applicative", "tu10-monad-l02-monad-laws"],
    ),
    [l_10_a(), l_10_b()],
  )
}

// ── tu11-lambda ─────────────────────────────────────────────
// TU11-① 「(λx.M)N → M[x:=N] — β-reduction and variable capture」
fn l_11_a() -> Lesson {
  tlesson(
    "tu11-lambda-l01-beta",
    "tu11-lambda",
    "(λx.M)N → M[x:=N] — β-reduction and variable capture",
    [
      Theory("lambda-calculus"),
      Theory("beta-reduction"),
      Theory("beta-reduction-capture"),
    ],
    [
      tprose(
        "beta-intro",
        "The lambda calculus is a model of computation with just three pieces of syntax — a **variable** `x`, an **abstraction** `λx.M` (\"a function that takes `x` and returns `M`\"), and an **application** `M N` (\"feed `N` to `M`\"). That's all. Computation has a single rule, **β-reduction**: when you apply a function to an argument, you replace the parameter in the body with that argument — `(λx.M)N → M[x:=N]`. In TU3 we said \"evaluation is reducing an expression to a simpler one\"; β-reduction is exactly that one step. In Gleam, `λx.M` is `fn(x) { m }`, application is `f(n)`, and β-reduction is what the Gleam runtime actually does when it calls a function.\n\n```gleam\nimport gleam/io\nimport gleam/int\n\n// (λx. x + x) 3  --β-->  3 + 3  -->  6\npub fn main() -> Nil {\n  let double = fn(x: Int) { x + x }\n  io.println(int.to_string(double(3)))\n  Nil\n}\n```",
      ),
      tpredict(
        "double-beta",
        "If you reduce `double(3)` above by hand using β-reduction you get `3 + 3` — and then? What gets printed?",
        "let double = fn(x: Int) { x + x }\ndouble(3)\n// (λx. x + x) 3  --β-->  3 + 3  -->  ?",
        ["`6`", "`33`", "`double(3)`"],
        0,
        "In `(λx. x+x) 3` you substitute the argument `3` for every `x` in the body `x+x` → `3+3` → `6`. β-reduction isn't 'splicing strings together', it's 'substituting values', so `Int +` does its job.",
        [
          #(
            1,
            "`33` looks like the result of string concatenation (`<>`). But here `+` is **Int addition** (Gleam strictly distinguishes Int `+`, Float `+.`, and string `<>` — U1③). β-reduction just substitutes the *value* 3 for the parameter `x`; it doesn't glue two tokens together.",
          ),
        ],
      ),
      tprose(
        "capture-intro",
        "Substitution has a pitfall — **variable capture**. When you do `M[x:=N]`, a free variable inside `N` must not get *trapped* by another λ inside `M`, flipping the meaning. Example: `(λx. λy. x)` is \"a function that returns the first of two arguments\". If you naïvely substitute `y` into it you get `λy. y` (\"returns the second\"), which breaks the meaning *backwards* — because the inner `λy` captured the `y` that came from outside. The correct reduction first renames the bound variable (α-conversion) to avoid the clash: `λy'. y`. For TU1's \"equational reasoning preserves substitution\" to hold, this capture-avoiding rule is essential. In Gleam the compiler tracks scope precisely, so you can't *directly* create a capture bug, but you can confirm in code that the compiler never makes the mistake we make when reducing by hand.\n\n```gleam\nimport gleam/io\n\n// Applying (λx. λy. x): fix the first argument to build a \"constant function\".\n// const_y ignores y and always returns the value it first received — no capture.\npub fn main() -> Nil {\n  let const_fn = fn(x: String) { fn(_y: String) { x } }\n  let always_a = const_fn(\"a\")\n  io.println(always_a(\"b\"))\n  // == \"a\"  (if y had been captured, this would have printed \"b\")\n  Nil\n}\n```",
      ),
      tmcq(
        "capture-spot",
        "Among the following three hand-computed \"`(λx. λy. x)` substitutions\", pick the **wrong one (where capture occurred)**.",
        [
          "(A) substituting `z` into `(λx. λy. x)` → `λy. z`",
          "(B) substituting `y` into `(λx. λy. x)` → `λy. y`",
          "(C) substituting `y` into `(λx. λy. x)`, first renaming `λy`→`λy'` then → `λy'. y`",
        ],
        1,
        "In (B) the free variable `y` coming from outside got *captured* by the inner `λy`, turning a 'constant function' into 'something identity-like' — the meaning changed, so it's a wrong reduction.",
        [
          #(
            2,
            "(C) is exactly the textbook capture-avoiding move — rename the clashing bound variable with α-conversion (`λy'`) first, then substitute, so the meaning is preserved. This is correct β-reduction, the same principle the Gleam compiler guarantees internally with its scoping.",
          ),
        ],
      ),
    ],
  )
}

// TU11-② 「Everything is a function — Church Bool, pair, and numbers in Gleam」
fn l_11_b() -> Lesson {
  tlesson(
    "tu11-lambda-l02-church",
    "tu11-lambda",
    "Everything is a function — Church Bool, pair, and numbers in Gleam",
    [Theory("church-encoding"), Theory("church-numerals")],
    [
      tprose(
        "church-bool-intro",
        "The lambda calculus has no `True`, no `42`, no `(a, b)`. There are only functions — so how do we represent data? **Church encoding**: define data by \"*what you do* with it\". A **Church Bool** is \"a function that picks one of two choices\" — `ctrue` picks the first, `cfalse` picks the second. Then `if` is just \"apply that boolean to the two alternatives\". Because Gleam is statically typed, unlike the untyped λ-calculus there's a type attached: the two choices must have the same type `a`, so a Church Bool has type **`fn(a, a) -> a`**.\n\n```gleam\nimport gleam/io\n\n// Church Bool : fn(a, a) -> a  — picks one of the two\npub fn ctrue(t: a, _f: a) -> a {\n  t\n}\n\npub fn cfalse(_t: a, f: a) -> a {\n  f\n}\n\n// cif b then else  ==  b(then, else) : apply the boolean to the two choices\npub fn cif(b: fn(a, a) -> a, then: a, els: a) -> a {\n  b(then, els)\n}\n\npub fn main() -> Nil {\n  assert cif(ctrue, \"yes\", \"no\") == \"yes\"\n  assert cif(cfalse, \"yes\", \"no\") == \"no\"\n  io.println(cif(ctrue, \"yes\", \"no\"))\n  // == \"yes\"\n  Nil\n}\n```\n\n> Honesty note: in `ctrue` we prefixed the unused second argument with `_f` (the \"unused argument\" idiom from U1). If you left it as plain `f` it would still compile, but you'd get an \"Unused function argument\" warning — in λ-calculus discarding an argument is normal, which is a spot where it slightly clashes with Gleam's warnings.",
      ),
      tpredict(
        "cfalse-call",
        "What does calling `cfalse(\"A\", \"B\")` directly (without `cif`) give?",
        "pub fn cfalse(_t: a, f: a) -> a {\n  f\n}\n\ncfalse(\"A\", \"B\")",
        ["`\"A\"`", "`\"B\"`", "compile error"],
        1,
        "Since `cfalse(t, f) = f`, it returns the second argument `\"B\"` as-is. A Church Bool *is* a 'choosing function', so branching is done by application alone.",
        [
          #(
            0,
            "That's what `ctrue` does. `cfalse` *discards* the first (`_t`) and picks the second `f` — look again at the function body `{ f }`.",
          ),
        ],
      ),
      tprose(
        "church-num-intro",
        "Numbers are functions too — a **Church numeral** is \"*how many times* a function `f` is applied to a value `x`\". `czero` applies it 0 times (just `x`), and `csucc(n)` applies it `n` times then once more. A natural number becomes \"a repeat count\". And `cadd m n` is \"apply `n` times first, then `m` times on top\" = `(m+n)` times. You can **decode** to a Gleam Int to check it's really right: feed `fn(k){k+1}` as `f` and `0` as `x`, and the application count drops straight out as an Int.\n\n```gleam\nimport gleam/io\nimport gleam/int\n\n// Church numeral : apply f to x n times\npub fn czero(_f: fn(a) -> a, x: a) -> a {\n  x\n}\n\npub fn csucc(n: fn(fn(a) -> a, a) -> a) -> fn(fn(a) -> a, a) -> a {\n  fn(f, x) { f(n(f, x)) }\n}\n\n// add m n : apply n times first, then m more times on top = (m+n) times\npub fn cadd(\n  m: fn(fn(a) -> a, a) -> a,\n  n: fn(fn(a) -> a, a) -> a,\n) -> fn(fn(a) -> a, a) -> a {\n  fn(f, x) { m(f, n(f, x)) }\n}\n\n// decode: apply +1 n times to convert into an Int\npub fn to_int(n: fn(fn(Int) -> Int, Int) -> Int) -> Int {\n  n(fn(k) { k + 1 }, 0)\n}\n\npub fn main() -> Nil {\n  let one = csucc(czero)\n  let two = csucc(one)\n  assert to_int(czero) == 0\n  assert to_int(two) == 2\n  assert to_int(cadd(two, two)) == 4\n  io.println(int.to_string(to_int(cadd(two, two))))\n  // == \"4\"\n  Nil\n}\n```",
      ),
      tmcq(
        "cmul-pick",
        "Pick the correct definition of `cmul(m, n)` (\"`m` times `n`\"). Hint: `m` is a tool for \"applying some function `m` times\" — so repeat 'applying `n` once' `m` times. (Hidden tests: `to_int(cmul(two, three)) == 6`, `to_int(cmul(czero, three)) == 0`)",
        [
          "`fn(f, x) { m(fn(y) { n(f, y) }, x) }`",
          "`fn(f, x) { m(f, n(f, x)) }`",
          "`fn(f, x) { m(f, x) + n(f, x) }`",
        ],
        0,
        "Just as multiplication is 'repeated addition', Church multiplication is 'repeated composition of applications' — `m` is the outer loop, `n` the inner loop. By passing `fn(y){ n(f, y) }` whole into `m`'s function-argument slot, you repeat the chunk 'apply-n-times' `m` times.",
        [
          #(
            1,
            "That's addition (`cadd`) — apply `n` times then `m` more *on top* gives `m+n`. Multiplication must *repeat* the chunk 'apply-n-times' `m` times, so you have to pass `fn(y){ n(f, y) }` whole into `m`'s function-argument slot.",
          ),
          #(
            2,
            "A Church numeral isn't an `Int`, it's 'a function expressing an application count' — it's not a value you can add with `+`. Multiplication is *composing and repeating* applications, not adding decoded numbers.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu11() -> Unit {
  tunit(
    UnitMeta(
      id: "tu11-lambda",
      title: "Lambda calculus and Church encoding",
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
    "The Consistency of Absence — Why You Can't Write a Single `map`",
    [Theory("no-hkt"), Theory("no-typeclass"), Theory("why-not-faq")],
    [
      tprose(
        "l01-seg1",
        "Throughout this track we've seen that `list.map`, `option.map`, and `result.map` all share the **same shape** (`map(container, fn(a)->b) -> container_of_b`). The natural question follows: \"So can't we just write one `map` that works over *any container*?\" Gleam's answer is **no, you can't**. A type variable can only stand for a *completed type* like `Int` or `String`; it cannot stand for a **type constructor** like `List` or `Option`, which needs more arguments before it becomes a complete type. That is precisely what \"there are no higher-kinded types (HKT)\" means. So all we can do is write a *separate* `map` for each type.\n\n```gleam\nimport gleam/list\nimport gleam/option.{type Option}\nimport gleam/result\n\n// Same pattern, but one per type — they can't be merged into one.\npub fn map_list(xs: List(a), f: fn(a) -> b) -> List(b) {\n  list.map(xs, f)\n}\n\npub fn map_option(o: Option(a), f: fn(a) -> b) -> Option(b) {\n  option.map(o, f)\n}\n\npub fn map_result(r: Result(a, e), f: fn(a) -> b) -> Result(b, e) {\n  result.map(r, f)\n}\n```",
      ),
      tmcq(
        "l01-ex1",
        "Of these four signatures, pick the one that is *literally impossible to even write* in Gleam.",
        [
          "`pub fn map_list(xs: List(a), f: fn(a) -> b) -> List(b)`",
          "`pub fn map_pair(p: #(a, a), f: fn(a) -> b) -> #(b, b)`",
          "`pub fn generic_map(c: f(a), f2: fn(a) -> b) -> f(b)`",
          "`pub fn map_result(r: Result(a, e), f: fn(a) -> b) -> Result(b, e)`",
        ],
        2,
        "Correct. `f(a)` tries to *apply the type variable `f` to a type*, but Gleam's type variables have no such power (no HKT). In fact the compiler stops you not at the type level but at the *syntax* level — the error title is `Syntax error`, the message is `I was not expecting this`, and the caret points at the opening parenthesis `(` after `f`. In other words, it never even reaches type checking.",
        [
          #(
            1,
            "This one is perfectly fine. `#(a, a)` only uses *completed types* as variables, and the container shape (`#(_, _)`) is hard-coded right into the signature — it doesn't take a type constructor as a variable, so no HKT is needed. This is exactly TU11's `pair_map`.",
          ),
          #(
            3,
            "`Result(a, e)` also has its container shape *fixed* in the signature. The only things that vary are the inner type variables `a` and `e`, so first-order is enough.",
          ),
        ],
      ),
      tprose(
        "l01-seg2",
        "This isn't because Gleam is \"unfinished\" — it's a **deliberate trade-off**. Haskell/PureScript/Scala use type classes + HKT to express a *single abstraction* like `class Functor f where fmap :: (a -> b) -> f a -> f b`. Gleam *intentionally* leaves type classes out, as stated in its official FAQ — the reasons are (1) **confusing error messages** when dispatch fails, (2) increased **compile time**, and (3) **runtime cost** from passing dictionaries. Instead, Gleam says \"*pass the behavior you need explicitly as a function argument*.\" This is the *theoretical root* of why, all across the TU track, we've honestly noted every time that \"there's no single generic Functor/Monad function you can use.\"",
      ),
      tpredict(
        "l01-ex2",
        "What happens when you compile the `generic_map` below?",
        "// If you actually try to write (c) — the syntax rejects it before the lack-of-HKT limit even matters.\npub fn generic_map(container: f(a), fun: fn(a) -> b) -> f(b) {\n  container\n}",
        [
          "Compiles fine",
          "`Syntax error` (rejects applying a type variable)",
          "`Type mismatch`",
          "Runtime crash",
        ],
        1,
        "The moment you put `(...)` on a type variable, the syntax parser rejects it. The actual output on pinned 1.17.0 is the title `Syntax error` and the body `I was not expecting this` (the caret points at the opening parenthesis of `f(`). The absence of HKT shows up not as a 'type check failure' but as *there being no syntax to express it in the first place* — the deepest kind of 'absence.'",
        [
          #(
            0,
            "For this to pass, `f` would have to be a *higher-kinded* variable that takes a type constructor. That's HKT, and Gleam doesn't have it.",
          ),
          #(
            2,
            "It never even reaches the type level. The parser stops first at `f(` — this is the purest form of 'the consistency of absence.'",
          ),
        ],
      ),
    ],
  )
}

fn l_12_b() -> Lesson {
  tlesson(
    "tu12-capstone-l02-recursion-scheme",
    "tu12-capstone",
    "Recursion Schemes — `fold` Is the One Structure-Respecting Collapse",
    [
      Theory("catamorphism"),
      Theory("recursion-scheme"),
      Theory("functor-laws"),
      Theory("patterns-as-eyes"),
    ],
    [
      tprose(
        "l02-seg1",
        "The hand-written `sum_loop` from U6 and the `list.fold` we met in U8 — those two actually share one name: **catamorphism**. For any ADT, if you give it *one function per constructor*, there is exactly one operation that \"collapses\" the structure in a single pass following its shape. Giving `initial` and `fn(acc, x)` to the list's two constructors (`[]`, `[_, ..]`) was `list.fold`. Trees work the same way — there are two constructors, `Leaf`/`Node`, so you give two functions. This \"number of constructors = number of arguments\" correspondence is the essence of a catamorphism (verified examples: sum=6, depth=3).\n\n```gleam\nimport gleam/int\n\npub type Tree(a) {\n  Leaf(a)\n  Node(Tree(a), Tree(a))\n}\n\n// catamorphism: one function for Leaf, one for Node. There is no other option.\npub fn fold_tree(tree: Tree(a), on_leaf: fn(a) -> b, on_node: fn(b, b) -> b) -> b {\n  case tree {\n    Leaf(value) -> on_leaf(value)\n    Node(left, right) ->\n      on_node(fold_tree(left, on_leaf, on_node), fold_tree(right, on_leaf, on_node))\n  }\n}\n\npub fn sum_tree(tree: Tree(Int)) -> Int {\n  fold_tree(tree, fn(x) { x }, fn(l, r) { l + r })\n}\n\npub fn depth(tree: Tree(a)) -> Int {\n  fold_tree(tree, fn(_) { 1 }, fn(l, r) { 1 + int.max(l, r) })\n}\n```",
      ),
      tpredict(
        "l02-ex1",
        "The catamorphism that counts the leaves (Leaf) of `Node(Node(Leaf(1), Leaf(2)), Leaf(3))` is shown below. What is the output?",
        "import gleam/io\nimport gleam/int\n\npub type Tree(a) {\n  Leaf(a)\n  Node(Tree(a), Tree(a))\n}\n\npub fn fold_tree(tree: Tree(a), on_leaf: fn(a) -> b, on_node: fn(b, b) -> b) -> b {\n  case tree {\n    Leaf(value) -> on_leaf(value)\n    Node(left, right) ->\n      on_node(fold_tree(left, on_leaf, on_node), fold_tree(right, on_leaf, on_node))\n  }\n}\n\npub fn main() -> Nil {\n  let t = Node(Node(Leaf(1), Leaf(2)), Leaf(3))\n  let count = fold_tree(t, fn(_) { 1 }, fn(l, r) { l + r })\n  io.println(int.to_string(count))\n  Nil\n}",
        [
          "`3`",
          "`6`",
          "`2`",
          "`1`",
        ],
        0,
        "`on_leaf` is the *seed value*, `on_node` is *how to combine*. There are 3 leaves, so 1+1+1=3. If instead `on_leaf = fn(x) { x }` and `on_node = fn(l, r) { l + r }`, that would be `sum_tree` and it would give 1+2+3=6 — same catamorphism, two different functions.",
        [
          #(
            1,
            "That's `sum_tree`, which adds the *values* of the leaves. Here `on_leaf = fn(_) { 1 }`, so it throws away the value and just counts 1. A catamorphism's behavior is determined solely by the two functions you pass in.",
          ),
          #(
            2,
            "There are two `Node`s, but what we're counting is *leaves*. Notice we're counting `Leaf` calls, not the number of internal nodes.",
          ),
          #(
            3,
            "There isn't one leaf, there are three. Since `on_node` adds the results of the two children, you get 1+1+1=3.",
          ),
        ],
      ),
      tprose(
        "l02-seg2",
        "A catamorphism *folds an ADT away* (bottom→up). The opposite direction — *unfolding* a structure from a single seed (top→down) — is an **anamorphism (ana)**, and combining the two gives a **paramorphism (para, a fold that also sees the children's originals)** — we'll just taste the names here. One subtle but important point: a catamorphism can be *anything* as long as you give *one function per constructor*. It can change the result type (sum, depth), or even rebuild the same `Tree` while *rearranging* its children (for example, list `reverse` can also be expressed as a fold). In other words, \"it's a catamorphism\" does *not* automatically mean \"it preserves structure.\" A functor map is just one *special* algebra among the many catamorphisms — the one that **preserves the structure exactly** (rebuilding each constructor in place, keeping the order of children). Another \"honest limit\": Gleam has no *generic fold that works automatically over every ADT* (that would require HKT). So you write each catamorphism **by hand**, per type. But once you develop the eye for it, U6's `sum_loop`, U8's `list.fold`, and the `fold_tree` above all reveal themselves as *different instances of the same pattern* — that is what \"theory is the eye that sees the pattern\" means.",
      ),
      tmcq(
        "l02-ex2",
        "All three `fold_tree` algebras below are **legitimate catamorphisms**. Pick the one that does *not* preserve structure like a functor map (i.e., it *rearranges* the order of children).",
        [
          "`fold_tree(tree, fn(x) { [x] }, fn(l, r) { list.append(l, r) })` — gathers the leaves into a list",
          "`fold_tree(tree, fn(x) { x }, fn(l, r) { l + r })` — sum",
          "`fold_tree(tree, fn(x) { Leaf(x) }, fn(l, r) { Node(r, l) })` — rebuilds a tree with left/right *swapped*",
        ],
        2,
        "(c) is also a **fully legitimate catamorphism** in form — it gives one function per constructor (an F-algebra), and on pinned 1.17.0 it compiles and runs, returning a `Tree` with left/right swapped. A catamorphism *can* rearrange children (just as list `reverse` can be expressed as a fold). However, (c) swaps **the order of children** with `Node(r, l)` in `on_node`, so it does *not* preserve structure, which disqualifies it as the skeleton for a functor map. Plugging this algebra in as the skeleton of `map_tree` would break the identity law `map(t, id) == t`.",
        [
          #(
            0,
            "(a) is also a legitimate catamorphism, and it preserves structure. `on_leaf`/`on_node` merely replace each leaf and node *in place* with a different type (a list); the left/right order is preserved by `list.append(l, r)`.",
          ),
          #(
            1,
            "(b) is the textbook `sum_tree`. With no swapping, it just adds the two children's results, so structure is respected perfectly — this is also a legitimate catamorphism.",
          ),
        ],
      ),
    ],
  )
}

fn unit_tu12() -> Unit {
  tunit(
    UnitMeta(
      id: "tu12-capstone",
      title: "Capstone — Limits, Recursion Schemes, and the Path Ahead",
      order: 12,
      level: 8,
      concepts: [
        Theory("no-hkt"),
        Theory("catamorphism"),
        Theory("recursion-scheme"),
        Theory("patterns-as-eyes"),
      ],
      prerequisites: [
        "tu08-monoid",
        "tu09-functor",
        "tu10-monad",
        "tu11-lambda",
      ],
      lesson_ids: [
        "tu12-capstone-l01-no-hkt",
        "tu12-capstone-l02-recursion-scheme",
      ],
    ),
    [l_12_a(), l_12_b()],
  )
}
