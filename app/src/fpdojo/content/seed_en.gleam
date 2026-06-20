//// 부트스트랩 임베드 콘텐츠 — M1 컴파일러-free 학습 루프용 (PLAN §5.3 대안).
////
//// 정식 콘텐츠 파이프라인(TOML 저작 → build-content.mjs → JSON 청크 →
//// content/loader fetch)은 설계대로 유지하되, "실제로 실행해 학습 가능한"
//// 슬라이스를 위해 여기서는 콘텐츠를 Gleam 값으로 직접 임베드한다.
//// 무컴파일 퍼즐 타입(predict 선택지형·mcq)만 써서 WASM 컴파일러 없이도
//// 동작한다. 커버리지: L1~L4 전체(U1~U15, 고급 개념 포함). 예제는 전수
//// 로컬 gleam(JS 타깃=브라우저 런타임)으로 실행 검증됨(122+).
////
//// 의존 방향: content/schema · core/types 만 import (콘텐츠는 도메인 데이터).

import fpdojo/content/schema.{
  type Lesson, type LessonBlock, type Unit, Checkpoint, CheckpointItem, Exercise,
  FeedbackMap, Lesson, Prose, Step, Unit, UnitMeta,
}
import fpdojo/core/types.{type Tag, Choice, Concept, Mcq, Predict, Tricky}
import gleam/dict
import gleam/int
import gleam/list
import gleam/option

/// 임베드된 전체 유닛 — 앱 부트 시 ui/app이 이 목록을 로드한다.
pub fn units() -> List(Unit) {
  [
    unit_values(),
    unit_functions_pipes(),
    unit_case_branching(),
    unit_custom_types(),
    unit_lists_recursion(),
    unit_tail_recursion(),
    unit_functions_as_values(),
    unit_list_module(),
    unit_option_result(),
    unit_result_use(),
    unit_generics(),
    unit_opaque_types(),
    unit_intentional_crash(),
    unit_gleam_omits(),
    unit_capstone(),
  ]
}

/// 편의: id로 유닛 1개 조회.
pub fn unit(id: String) -> Result(Unit, Nil) {
  list.find(units(), fn(u) { u.meta.id == id })
}

/// 편의: id로 레슨 1개 조회 (어느 유닛에 있든).
pub fn lesson(id: String) -> Result(Lesson, Nil) {
  units()
  |> list.flat_map(fn(u) { u.lessons })
  |> list.find(fn(l) { l.id == id })
}

fn unit_values() -> Unit {
  let meta =
    UnitMeta(
      id: "u01-values",
      title: "Values, Immutability, Expressions",
      order: 1,
      level: 1,
      concepts: [Concept("basics"), Concept("ints"), Concept("floats")],
      prerequisites: [],
      lesson_ids: [
        "l01-values-let", "l02-immutability", "l03-int-float", "l04-expressions",
        "l05-string-bool",
      ],
    )
  let lessons = [
    lesson_values_let(),
    lesson_immutability(),
    lesson_int_float(),
    lesson_expressions(),
    lesson_string_bool(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u01-values", lessons),
  )
}

fn lesson_values_let() -> Lesson {
  Lesson(
    id: "l01-values-let",
    unit_id: "u01-values",
    title: "Values and let",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Programming is, in the end, all about working with **values**. `1`, `3.14`, `\"hello\"`, `True` — these are all values.\n\nIn Gleam you give a value a **name** with `let`. When you write `let pi = 3.14`, from that point on the name `pi` refers to `3.14`.",
      ),
      mcq(
        "bind-syntax",
        "What is the correct syntax for binding a value to a name in Gleam?",
        ["`x = 5`", "`let x = 5`", "`var x = 5`", "`const x = 5`"],
        1,
        "Correct! In Gleam you bind inside a function only with `let`. There is no `var`, and no reassignment either.",
        [
          #(0, "`=` on its own won't do it. A binding always needs `let`."),
          #(
            2,
            "Gleam has no `var` — there's no such thing as reassignment in the first place.",
          ),
          #(
            3,
            "`const` is for module-level top-level constants. Bindings inside a function use `let`.",
          ),
        ],
      ),
      Prose(
        "use-name",
        "Once you've named a value, you can pull it back out later by that name. Think of a name inside an expression as being substituted by its value.",
      ),
      predict(
        "let-use",
        "What is the value of `total` when the code below finishes?",
        "let price = 100\nlet count = 3\nlet total = price * count",
        ["`3`", "`100`", "`300`", "`103`"],
        2,
        "Exactly! `price` is 100 and `count` is 3 — so `total` is 100 * 3 = 300.",
        [
          #(
            0,
            "You only looked at `count` (3). `total` is computed as `price * count`.",
          ),
          #(
            1,
            "You only looked at `price` (100). You still need to multiply by `count`.",
          ),
          #(3, "`*` is multiplication — not addition (100+3) but 100*3 = 300."),
        ],
      ),
    ],
  )
}

fn lesson_immutability() -> Lesson {
  Lesson(
    id: "l02-immutability",
    unit_id: "u01-values",
    title: "Immutability and shadowing",
    emits_tags: [Concept("basics"), Tricky("shadowing")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam has no way to \"modify\" a variable. Once a value is bound with `let`, it never changes — everything is **immutable**.\n\nSo what about \"when you want to change a value\"? Instead of changing it, you write **`let` again with the same name**. From that point on, a new binding pointing at the new value shadows the previous one — this is called **shadowing**. The value didn't change; the name simply points at something new.",
      ),
      predict(
        "shadowing-value",
        "What is the value of `x` when the code below finishes?",
        "let x = 1\nlet x = x + 1\nlet x = x * 10",
        ["`2`", "`11`", "`20`", "`1`"],
        2,
        "Exactly! 1 → (1+1)=2 → (2*10)=20. Each line's `let` computes using the `x` of that moment and creates a new binding.",
        [
          #(
            0,
            "You only went as far as the second line. The third line `x * 10` applies too.",
          ),
          #(
            1,
            "It's not `x + 1 * 10`. A new `x` is bound line by line in order — it becomes 2, then is multiplied by 10.",
          ),
          #(3, "`x` refers to the result of the last `let` — 20, not 1."),
        ],
      ),
      Prose(
        "no-mutation",
        "Note: shadowing is different from **reassignment**. Writing a fresh `let` each time, like `let x = ...`, is legal, but reassigning without `let`, like `x = x + 1`, is syntax that simply doesn't exist in Gleam, so it won't compile.",
      ),
      mcq(
        "reassign-illegal",
        "After binding `let total = 0`, what happens if the next line is `total = total + 100`?",
        [
          "`total` becomes 100",
          "Compile error — Gleam has no reassignment without `let`",
          "A new `total` binding is created",
          "It errors at runtime",
        ],
        1,
        "Correct! Gleam has no reassignment operator. To \"update\" a value, shadow the old name with a new `let`, like `let total = total + 100`.",
        [
          #(
            0,
            "Changing a value in place doesn't exist in Gleam — that line won't even compile.",
          ),
          #(
            2,
            "To create a new binding you need `let` in front. A line without `let` isn't valid syntax.",
          ),
          #(
            3,
            "It's stopped at **compile time**, not at runtime — it never even runs.",
          ),
        ],
      ),
      Prose(
        "capture",
        "The real power of immutability shows up here. When a name is **captured** inside a function, later shadowing of that same name has no effect on the already-captured value — because values never change.",
      ),
      predict(
        "shadow-capture",
        "In the code below, what do the two lines print, in order? (`f` remembers the `x` from when it was created)",
        "let x = 1\nlet f = fn() { x }\nlet x = x + 10\necho x\necho f()",
        [
          "`11` and `11`",
          "`11` and `1`",
          "`1` and `1`",
          "Compile error",
        ],
        1,
        "Exactly! `f` captured the first `x` (=1). The `let x` on the third line is just a **new binding** and can't change the value `f` saw. So it's 11 and 1.",
        [
          #(
            0,
            "Shadowing is not mutation. `f` still sees the 1 it captured first — the second output is 1.",
          ),
          #(
            2,
            "The first output `x` is the 11 that the last `let` points to — not 1.",
          ),
          #(
            3,
            "Re-`let`ting the same name (shadowing) is legal. What's forbidden is reassignment without `let`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_int_float() -> Lesson {
  Lesson(
    id: "l03-int-float",
    unit_id: "u01-values",
    title: "Int and Float are strangers",
    emits_tags: [Concept("ints"), Concept("floats")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam strictly distinguishes integers (`Int`) from floats (`Float`). There is **no implicit conversion** between them.\n\nThat's why the Float operators carry a dot: `+.`  `-.`  `*.`  `/.`  Integers use plain `+ - * /`.",
      ),
      predict(
        "int-div",
        "What is the result of this integer division? (Gleam's `/` between two integers keeps only the quotient)",
        "10 / 3",
        ["`3.333`", "`3`", "`4`", "`3.0`"],
        1,
        "Correct! Integer division keeps only the quotient — 10 / 3 = 3.",
        [
          #(
            0,
            "That's the result of float division. `/` between integers gives only the quotient.",
          ),
          #(2, "It rounds down, not up. The quotient of 10 / 3 is 3."),
          #(
            3,
            "The result is the `Int` value 3, not the `Float` 3.0. They're different types.",
          ),
        ],
      ),
      predict(
        "float-div",
        "What is the result of this float division?",
        "10.0 /. 4.0",
        ["`2`", "`2.5`", "`2.0`", "Compile error"],
        1,
        "Exactly! `/.` is Float division, so it gives 2.5.",
        [
          #(0, "The result is a `Float` — `2.5`, not `2` (an Int)."),
          #(2, "10.0 /. 4.0 = 2.5. It's not 2.0."),
          #(3, "`/.` is the correct Float operator, so it compiles fine."),
        ],
      ),
      Prose(
        "no-mixing",
        "**Mixing** an integer and a float in one operation **won't compile**. Gleam doesn't convert silently — if you need a conversion you must make it explicit with a function like `int.to_float`.",
      ),
      mcq(
        "mixed-arith",
        "How does Gleam handle the expression `1 + 2.0`?",
        ["`3.0`", "`3`", "Compile error (type mismatch)", "Rounds to `2.0`"],
        2,
        "Correct! `Int` and `Float` can't be mixed — the compiler stops it with a Type mismatch error — `Int` and `Float` cannot mix.",
        [
          #(
            0,
            "There's no implicit conversion, so it doesn't become 3.0 — it doesn't compile at all.",
          ),
          #(
            1,
            "It isn't converted to an Int either. A type mismatch is a compile error.",
          ),
          #(
            3,
            "Gleam doesn't convert silently — you must write `int.to_float(1)` yourself.",
          ),
        ],
      ),
      mcq(
        "fix-float-op",
        "A function body `x + 0.5` (taking a `Float` and adding 0.5) gives a compile error (\"Use +. instead\"). What's the correct fix?",
        ["`x +. 0.5`", "`x + 0.5.0`", "`x .+ 0.5`", "`x + int.to_float(0.5)`"],
        0,
        "Correct! The Float addition operator is the dotted `+.`. Fixing it to `x +. 0.5` works.",
        [
          #(
            1,
            "There's no number notation like `0.5.0` — you need to change the operator to `+.`.",
          ),
          #(
            2,
            "The dot goes **after** the operator: `+.` `-.` `*.` `/.` — `.+` isn't valid syntax.",
          ),
          #(
            3,
            "`0.5` is already a `Float`, so no conversion is needed; the problem is the operator (`+` → `+.`).",
          ),
        ],
      ),
    ],
  )
}

fn lesson_expressions() -> Lesson {
  Lesson(
    id: "l04-expressions",
    unit_id: "u01-values",
    title: "Everything is an expression",
    emits_tags: [Concept("basics"), Tricky("expressions-everywhere")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam has no \"statements.\" `case`, brace blocks `{ ... }`, conditional branches — they're all **expressions that produce a value**.\n\nSo, unlike other languages, you don't \"assign to a variable inside an if.\" Instead, you **bind the whole result of an expression with `let`**.",
      ),
      predict(
        "block-value",
        "A brace block is an expression too — the value of its last line is the value of the whole block. What is `y`?",
        "let y = {\n  let a = 2\n  a + 3\n}",
        ["`5`", "`2`", "`3`", "`Nil`"],
        0,
        "Exactly! The block's last expression `a + 3` (=5) is the value of the whole block, and that's bound to `y`.",
        [
          #(
            1,
            "`a` (2) is an intermediate value in the block. The block's value is its **last expression**.",
          ),
          #(2, "`3` is just a literal; `a + 3` is computed and becomes 5."),
          #(
            3,
            "A block returns the value of its last expression — 5, not `Nil`.",
          ),
        ],
      ),
      Prose(
        "case-is-expression",
        "`case` is also an expression that yields a value, so you can bind its result directly with `let`. Branches with a guard (`if ...`) are checked **top to bottom**, and the first one that is true is chosen.",
      ),
      predict(
        "grade-85",
        "In the `grade` function below, what is the value of `grade(85)`?",
        "fn grade(score: Int) -> String {\n  case score {\n    s if s >= 90 -> \"A\"\n    s if s >= 80 -> \"B\"\n    _ -> \"F\"\n  }\n}\n\ngrade(85)",
        ["`\"A\"`", "`\"B\"`", "`\"F\"`", "`85`"],
        1,
        "Correct! Guards are checked from the top. `85 >= 90` is false so it's skipped, and `85 >= 80` is true, so \"B\" is chosen.",
        [
          #(
            0,
            "`85 >= 90` is false, so the first branch is skipped — it falls through to the next one.",
          ),
          #(
            2,
            "It never reaches the `_` branch. `85 >= 80` is true, so it stops above that.",
          ),
          #(
            3,
            "`case` returns the **result** of the chosen branch, not the matched input — \"B\", not 85.",
          ),
        ],
      ),
      predict(
        "grade-95",
        "In the same `grade` function, what is the value of `grade(95)`?",
        "fn grade(score: Int) -> String {\n  case score {\n    s if s >= 90 -> \"A\"\n    s if s >= 80 -> \"B\"\n    _ -> \"F\"\n  }\n}\n\ngrade(95)",
        ["`\"A\"`", "`\"B\"`", "`\"F\"`", "Compile error"],
        0,
        "Exactly! `95 >= 90` is true, so the first branch is chosen and the result is \"A\".",
        [
          #(
            1,
            "The first branch `s if s >= 90` is already true, so it stops there — it never reaches \"B\".",
          ),
          #(
            2,
            "`_` is the bottom branch. Since something already matched above, it's never reached.",
          ),
          #(
            3,
            "It compiles fine — the `_` branch catches all remaining cases, covering everything exhaustively.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_string_bool() -> Lesson {
  Lesson(
    id: "l05-string-bool",
    unit_id: "u01-values",
    title: "String and Bool, plus echo/io.println",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Here are the last two basic types. A **`String`** is characters wrapped in double quotes (`\"hello\"`), and you join them with the `<>` operator. A **`Bool`** is `True` or `False`, and you combine them with `&&` (and), `||` (or), and `!` (not).",
      ),
      predict(
        "string-concat",
        "What is the result of the string concatenation `<>`?",
        "\"ab\" <> \"cd\"",
        ["`\"abcd\"`", "`\"ab cd\"`", "`\"cdab\"`", "`\"ab+cd\"`"],
        0,
        "Correct! `<>` sticks the right string directly onto the end of the left one — \"abcd\".",
        [
          #(
            1,
            "`<>` doesn't insert a space in between — it joins them directly to get \"abcd\".",
          ),
          #(
            2,
            "The order isn't reversed — the left side comes first, the right side after.",
          ),
          #(
            3,
            "`<>` doesn't slip the operator symbol in as a character — it concatenates purely.",
          ),
        ],
      ),
      predict(
        "bool-and",
        "What is the value of the Bool operation `True && False`?",
        "True && False",
        ["`True`", "`False`", "`Nil`", "Compile error"],
        1,
        "Exactly! `&&` (AND) is `True` only when both sides are `True` — if even one is `False`, it's `False`.",
        [
          #(
            0,
            "`&&` is true only when both are true. One side is `False`, so the result is `False`.",
          ),
          #(2, "The result of `&&` is always a `Bool` — `False`, not `Nil`."),
          #(
            3,
            "`&&` is the correct operator for two `Bool`s, so it compiles fine.",
          ),
        ],
      ),
      predict(
        "bool-or",
        "What is the value of the Bool operation `False || True`?",
        "False || True",
        ["`True`", "`False`", "`Nil`", "Compile error"],
        0,
        "Correct! `||` (OR) is `True` if even one side is `True`.",
        [
          #(
            1,
            "`||` is true if even one side is true — the right side is `True`, so the result is `True`.",
          ),
          #(2, "The result of `||` is always a `Bool` — `True`, not `Nil`."),
          #(
            3,
            "`||` is the correct operator for two `Bool`s, so it compiles fine.",
          ),
        ],
      ),
      Prose(
        "echo-vs-println",
        "There are two ways to print a value to the screen. **`io.println`** takes only a `String` and prints those characters as-is (requires `import gleam/io`). **`echo`** is a debug keyword that takes **a value of any type** and prints it in a human-readable form (no import needed) — so it's handy for quickly peeking at an `Int` or a `Bool`.",
      ),
      mcq(
        "echo-or-println",
        "What's the fastest way to print a single integer `total` to the screen to check it, with no extra imports?",
        [
          "`io.println(total)`",
          "`echo total`",
          "`io.println(\"total\")`",
          "`print(total)`",
        ],
        1,
        "Correct! `echo` takes any type and needs no import, so it's perfect for debugging — it'll print an `Int` nicely on its own.",
        [
          #(
            0,
            "`io.println` takes only a `String`. Passing the `Int` `total` is a type error — you'd need `int.to_string`.",
          ),
          #(
            2,
            "That prints the literal text `total`, not the variable's value — what we wanted was the number.",
          ),
          #(3, "Gleam has no `print` function — use `io.println` or `echo`."),
        ],
      ),
    ],
  )
}

// ── Unit 2: Functions and pipes ─────────────────────────────────────────
fn unit_functions_pipes() -> Unit {
  let meta =
    UnitMeta(
      id: "u02-functions-pipes",
      title: "Functions and Pipes",
      order: 2,
      level: 1,
      concepts: [
        Concept("basics"),
        Concept("pipe-operator"),
        Concept("strings"),
      ],
      prerequisites: ["u01-values"],
      lesson_ids: [
        "l05-fn-def", "l06-pipe", "l07-nested-to-pipe", "l08-pipe-first",
      ],
    )
  let lessons = [
    lesson_fn_def(),
    lesson_pipe(),
    lesson_nested_to_pipe(),
    lesson_pipe_first(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u02-functions-pipes", lessons),
  )
}

fn lesson_fn_def() -> Lesson {
  Lesson(
    id: "l05-fn-def",
    unit_id: "u02-functions-pipes",
    title: "Function Definitions and Type Annotations",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "A function is defined in the shape `pub fn name(arg: Type) -> ReturnType { body }`.\n\nExample: `pub fn double(x: Int) -> Int { x * 2 }`\n\nYou write a type for each argument, and the return type after `->`. The compiler can often infer types for you, but since annotations act as the function's 'contract', the convention is to always add them to top-level functions.",
      ),
      mcq(
        "return-type",
        "In `pub fn double(x: Int) -> ??? { x * 2 }`, what return type belongs in place of `???`?",
        ["`Int`", "`Float`", "`String`", "`Bool`"],
        0,
        "Correct! `*` is the Int operator, and Int * Int yields an Int.",
        [
          #(1, "`*` is the Int operator. For Floats you'd need `*.` and `2.0`."),
          #(2, "A numeric multiplication can't produce a string."),
          #(3, "The result of multiplication is a number, not true/false."),
        ],
      ),
      Prose(
        "no-return",
        "Gleam has **no** `return` keyword. The **last expression** in a function body is its return value.\n\n```gleam\npub fn double(x: Int) -> Int {\n  x * 2\n}\n```\n\nSince `x * 2` is the last expression, it is returned as-is. There's also no early return that bails out partway through — this foreshadows the case-branch mindset you'll meet in a later unit.",
      ),
      predict(
        "last-expr",
        "What is the value of `double(21)`? (`fn double(x: Int) -> Int { x * 2 }`)",
        "pub fn double(x: Int) -> Int {\n  x * 2\n}\n\n// double(21) is?",
        ["`42`", "`21`", "`23`", "`2`"],
        0,
        "Exactly! The last expression `x * 2` = 21 * 2 = 42 is returned as-is.",
        [
          #(1, "It returns `x * 2`, not the input unchanged — 21 * 2 = 42."),
          #(2, "`x * 2` is multiplication, not addition. 21 * 2 = 42."),
          #(3, "`2` is just the multiplier; the return value is `x * 2` = 42."),
        ],
      ),
      mcq(
        "return-keyword",
        "Which is the correct way a Gleam function returns a value?",
        [
          "You use a return keyword, like `return x`",
          "The last expression in the body automatically becomes the return value",
          "You return with `yield x`",
          "You assign the value to the function's name",
        ],
        1,
        "Correct! Gleam has no return; the last expression is the return value.",
        [
          #(0, "Gleam has no `return` keyword at all."),
          #(2, "`yield` is not Gleam syntax."),
          #(
            3,
            "Assigning to the function name doesn't exist in Gleam — the last expression is the return value.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_pipe() -> Lesson {
  Lesson(
    id: "l06-pipe",
    unit_id: "u02-functions-pipes",
    title: "The Pipe |>",
    emits_tags: [Concept("pipe-operator"), Concept("strings")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "The `|>` (pipe) operator feeds the value on the left into the **first argument** of the function on the right.\n\n`x |> f`  is the same as  `f(x)`,\nand `x |> f(y)`  is the same as  `f(x, y)`. (The left-hand value goes into the very first slot!)\n\nThe key idea is that data flows left to right, in the order it's transformed.",
      ),
      predict(
        "trim-upper",
        "What is the value of this pipe chain?",
        "\"  lucy \"\n|> string.trim\n|> string.uppercase",
        ["`\"LUCY\"`", "`\"  LUCY \"`", "`\"lucy\"`", "`\"  lucy \"`"],
        0,
        "Correct! First trim removes the whitespace to give \"lucy\", then uppercase makes it \"LUCY\".",
        [
          #(
            1,
            "trim strips the whitespace at both ends first. None is left over.",
          ),
          #(2, "uppercase converts to capitals — it doesn't stay lowercase."),
          #(
            3,
            "Both transformations apply — it goes through trim and uppercase.",
          ),
        ],
      ),
      Prose(
        "first-arg",
        "The most confusing part is that the pipe places the value into the **first argument**.\n\n`string.append(first, second)` appends `second` after `first`.\nSo `\"LUCY\" |> string.append(\"!\")` becomes `string.append(\"LUCY\", \"!\")`, producing `\"LUCY!\"` — `\"LUCY\"` is the first argument and `\"!\"` is the second.",
      ),
      predict(
        "append-pipe",
        "What is the value of this expression?",
        "\"LUCY\" |> string.append(\"!\")",
        ["`\"LUCY!\"`", "`\"!LUCY\"`", "`\"LUCY\"`", "Compile error"],
        0,
        "Exactly! The pipe puts \"LUCY\" into the first argument: string.append(\"LUCY\", \"!\") → \"LUCY!\".",
        [
          #(
            1,
            "The pipe puts the left value into the **first** argument. It's `append(\"LUCY\", \"!\")`, so `!` is appended at the end.",
          ),
          #(
            2,
            "`\"!\"` is added as an argument, so it doesn't stay unchanged — it becomes \"LUCY!\".",
          ),
          #(3, "It's a valid pipe call, so it compiles."),
        ],
      ),
      mcq(
        "pipe-meaning",
        "What is `x |> f(y)` the same as?",
        ["`f(y, x)`", "`f(x, y)`", "`f(x)(y)`", "`x(f, y)`"],
        1,
        "Correct! The pipe puts the left value x into the first argument, giving `f(x, y)`.",
        [
          #(
            0,
            "x goes into the **first** argument — it's `f(x, y)`, not `f(y, x)`.",
          ),
          #(2, "Gleam has no currying — there's no `f(x)(y)` form."),
          #(
            3,
            "f is the function and x is its first argument — x doesn't call f.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_nested_to_pipe() -> Lesson {
  Lesson(
    id: "l07-nested-to-pipe",
    unit_id: "u02-functions-pipes",
    title: "Turning Nested Calls into Pipes",
    emits_tags: [Concept("pipe-operator"), Concept("strings")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "A nested call like `c(b(a(x)))` must be read **from the inside out** — a first, then b, then c. The reading order is the reverse of the execution order.\n\nRewriting it as a pipe gives `x |> a |> b |> c`, which reads **in the exact order the data is transformed**. The two expressions produce exactly the same value.",
      ),
      predict(
        "nested-value",
        "What is the value of this nested call?",
        "string.uppercase(string.trim(\"  hi \"))",
        ["`\"HI\"`", "`\"  HI \"`", "`\"hi\"`", "`\"  hi \"`"],
        0,
        "Correct! The inner trim produces \"hi\", and the outer uppercase turns it into \"HI\".",
        [
          #(
            1,
            "The inner trim removes the whitespace first — none is left over.",
          ),
          #(2, "The outer uppercase converts to capitals."),
          #(3, "Both functions apply, producing \"HI\"."),
        ],
      ),
      Prose(
        "equivalence",
        "The `string.uppercase(string.trim(\"  hi \"))` above is written with pipes like this:\n\n```gleam\n\"  hi \"\n|> string.trim\n|> string.uppercase\n```\n\nIt yields the same value (\"HI\"), but the thing that happens first (trim) comes at the top.",
      ),
      mcq(
        "rewrite",
        "Which correctly rewrites `c(b(a(x)))` as a pipe?",
        [
          "`x |> a |> b |> c`",
          "`x |> c |> b |> a`",
          "`c |> b |> a |> x`",
          "`a |> b |> c |> x`",
        ],
        0,
        "Exactly! The innermost (first-executed) a comes first, and the outer c comes last.",
        [
          #(1, "The order is reversed — the innermost a should come first."),
          #(2, "x is the starting data, so it must come at the front."),
          #(
            3,
            "x is not a function but the value to flow through, so it goes at the front.",
          ),
        ],
      ),
      predict(
        "shout-chain",
        "Given the function `shout` defined below, what is the value of `shout(\"  lucy \")`?",
        "pub fn shout(name: String) -> String {\n  name\n  |> string.trim\n  |> string.uppercase\n  |> string.append(\"!\")\n}\n\n// shout(\"  lucy \") is?",
        ["`\"LUCY!\"`", "`\"!LUCY\"`", "`\"  LUCY !\"`", "`\"lucy!\"`"],
        0,
        "Correct! trim→\"lucy\", uppercase→\"LUCY\", append(\"!\")→\"LUCY!\".",
        [
          #(
            1,
            "append adds to the end — \"!\" comes after \"LUCY\", so it's \"LUCY!\".",
          ),
          #(2, "trim removes the whitespace first, so none is left over."),
          #(
            3,
            "The uppercase step converts to capitals — it doesn't stay lowercase.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_pipe_first() -> Lesson {
  Lesson(
    id: "l08-pipe-first",
    unit_id: "u02-functions-pipes",
    title: "Pipe-First Style and Its Limits",
    emits_tags: [Concept("pipe-operator"), Concept("strings")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "The Gleam stdlib is designed to be 'pipe-friendly', so it often takes the **data to be transformed as the first argument**. That's why `string.trim`, `string.uppercase`, `string.replace`, and `string.append` all pipe naturally.\n\n`string.replace(string, what_to_find, what_to_replace_with)` also takes the string first, so it fits pipes well.",
      ),
      predict(
        "replace-pipe",
        "What is the value of this expression? (`string.replace` replaces the second argument with the third within the first-argument string)",
        "\"a-b-c\" |> string.replace(\"-\", \" \")",
        ["`\"a b c\"`", "`\"a-b-c\"`", "`\"abc\"`", "`\"- -\"`"],
        0,
        "Correct! In \"a-b-c\", every \"-\" is replaced with \" \", giving \"a b c\".",
        [
          #(
            1,
            "replace is applied, so it doesn't stay unchanged — each \"-\" becomes a space.",
          ),
          #(
            2,
            "It replaces \"-\" with a space \" \", not with an empty string.",
          ),
          #(3, "The letters a, b, c stay; only the separators change."),
        ],
      ),
      Prose(
        "limits",
        "Pipe-first style has its limits too. The pipe can only place the left value into the **first** argument. If the value being flowed through needs to go into the second or third argument slot, the pipe alone won't do.\n\nIn those cases you use a function capture (`f(fixed_value, _)`) or an anonymous function, which you'll learn in a later unit. For now, just remember the limit: 'the pipe is first-argument-only'.",
      ),
      mcq(
        "pipe-limit",
        "Which correctly describes a limit of the pipe `|>`?",
        [
          "It can only ever put the left value into the first argument",
          "It can chain at most two things at a time",
          "It can't be used with Int",
          "It can only be used when the function takes exactly one argument",
        ],
        0,
        "Correct! The pipe only puts the left value into the first argument. For other slots you need a capture.",
        [
          #(
            1,
            "There's no limit on how many you can chain — you can keep linking as many as you like.",
          ),
          #(2, "It's independent of type — you can pipe any value."),
          #(
            3,
            "Multiple arguments are fine — you just write the rest in the call (e.g. the `f(_)` form).",
          ),
        ],
      ),
      mcq(
        "non-first-arg",
        "What do you do if the value to flow through needs to go into the function's **second** argument slot?",
        [
          "The pipe alone is enough",
          "You need a function capture `f(fixed_value, _)` or an anonymous function",
          "It's impossible, so you can't use that function",
          "It automatically reorders the arguments for you",
        ],
        1,
        "Exactly! The pipe is first-argument-only, so other slots are handled with a capture or an anonymous function.",
        [
          #(
            0,
            "The pipe only puts it into the first argument — that's not enough for the second slot.",
          ),
          #(
            2,
            "You can use it — line up the slot with a capture or an anonymous function.",
          ),
          #(3, "Gleam does not automatically reorder arguments."),
        ],
      ),
    ],
  )
}

// ── Unit 3: case and Branching (Mindset Shift I) ───────────────────────────
fn unit_case_branching() -> Unit {
  let meta =
    UnitMeta(
      id: "u03-case-branching",
      title: "case and Branching",
      order: 3,
      level: 1,
      concepts: [Concept("case-expressions")],
      prerequisites: ["u02-functions-pipes"],
      lesson_ids: [
        "l05-case-anatomy", "l06-guards-alternates", "l07-no-early-return",
        "l08-imperative-to-expr",
      ],
    )
  let lessons = [
    lesson_case_anatomy(),
    lesson_guards_alternates(),
    lesson_no_early_return(),
    lesson_imperative_to_expr(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u03-case-branching", lessons),
  )
}

fn lesson_case_anatomy() -> Lesson {
  Lesson(
    id: "l05-case-anatomy",
    unit_id: "u03-case-branching",
    title: "Anatomy of a case Expression",
    emits_tags: [Concept("case-expressions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "In Gleam, the heart of branching is `case`. Here is what it looks like:\n\n```\ncase value_to_check {\n  pattern1 -> result1\n  pattern2 -> result2\n  _ -> remaining_result\n}\n```\n\nThe patterns are tried one at a time from top to bottom, and the result of the **first branch that matches** becomes the value of the whole `case`. A `case` is not a statement but an **expression**, so it leaves a single value in its place.",
      ),
      predict(
        "case-basic-3",
        "What is the value of this case expression?",
        "case 3 {\n  1 -> \"one\"\n  2 -> \"two\"\n  _ -> \"many\"\n}",
        ["\"one\"", "\"two\"", "\"many\"", "3"],
        2,
        "Correct! 3 is neither 1 nor 2, so it falls to the final `_` branch and becomes \"many\".",
        [
          #(
            0,
            "3 is not 1. A case finds the first matching branch starting from the top.",
          ),
          #(1, "3 is not 2 either. It misses both and drops into `_`."),
          #(
            3,
            "A case returns the *result* of the matching branch, not the value 3 that was inspected — \"many\".",
          ),
        ],
      ),
      Prose(
        "literal-patterns",
        "In a pattern position you can write a literal directly (`1`, `\"red\"`, `True`, and so on). If the inspected value equals that literal, that branch is chosen.\n\n`_` (the underscore) is a wildcard that **matches any value**. It is usually placed at the bottom to catch \"everything else\".",
      ),
      predict(
        "case-string-match",
        "What is the value of `light(\"green\")`?",
        "fn light(color: String) -> String {\n  case color {\n    \"red\" -> \"stop\"\n    \"green\" -> \"go\"\n    _ -> \"caution\"\n  }\n}",
        ["\"stop\"", "\"go\"", "\"caution\"", "\"green\""],
        1,
        "Correct! The \"green\" literal pattern matches, so the result is \"go\".",
        [
          #(
            0,
            "\"stop\" is the result of the \"red\" branch. The input is \"green\".",
          ),
          #(
            2,
            "\"green\" is already caught by the second branch, so it never reaches `_`.",
          ),
          #(
            3,
            "A case returns the result of the matching branch — \"go\", not the input \"green\" itself.",
          ),
        ],
      ),
      Prose(
        "bind-name",
        "If you write a **name** instead of `_` in a pattern position, the matched value is bound to that name. You can then use that value in the result expression. `_` means \"take it but don't use it\", whereas a name means \"take it and use it\".",
      ),
      predict(
        "case-bind-var",
        "What is the value of `describe(7)`?",
        "fn describe(n: Int) -> String {\n  case n {\n    0 -> \"zero\"\n    other -> \"got \" <> int.to_string(other)\n  }\n}",
        ["\"zero\"", "\"got 0\"", "\"got 7\"", "\"other\""],
        2,
        "Exactly! 7 is not 0, so it binds to `other`, and the result expression uses that value.",
        [
          #(0, "\"zero\" is the result when the input is 0. The input is 7."),
          #(1, "`other` is bound to the input 7 — it holds 7, not 0."),
          #(
            3,
            "`other` is just a name holding the value; the literal text does not appear in the result.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_guards_alternates() -> Lesson {
  Lesson(
    id: "l06-guards-alternates",
    unit_id: "u03-case-branching",
    title: "Guards, _, and Alternate Patterns",
    emits_tags: [
      Concept("case-expressions"),
      Tricky("branch-order"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "guards",
        "Patterns alone cannot express a condition like \"90 or higher\". For that we use a **guard**: by adding `if condition` after a pattern, the branch is chosen only when the pattern matches *and* that condition is true.\n\n```\ncase score {\n  s if s >= 90 -> \"A\"\n  s if s >= 80 -> \"B\"\n  _ -> \"F\"\n}\n```\n\nBranches are checked in order, **top to bottom**, and the first one to pass wins.",
      ),
      predict(
        "grade-guard",
        "What is the value of `grade(85)`?",
        "fn grade(score: Int) -> String {\n  case score {\n    s if s >= 90 -> \"A\"\n    s if s >= 80 -> \"B\"\n    _ -> \"F\"\n  }\n}",
        ["\"A\"", "\"B\"", "\"F\"", "85"],
        1,
        "Correct! 85 is below 90, so it fails the first branch, and being 80 or above it stops at \"B\".",
        [
          #(
            0,
            "Guards are checked from the top. `85 >= 90` is false, so it drops to the next branch.",
          ),
          #(2, "To reach \"F\" both guards must fail. 85 is 80 or above."),
          #(
            3,
            "A case returns the branch's result (\"B\"), not the number that was inspected.",
          ),
        ],
      ),
      Prose(
        "alternates",
        "When several literals should lead to the same result, you can group them into one branch with an **alternate pattern**, like `1 | 2 | 3 ->`. Read `|` as \"or\" — if any one of the three matches, that branch is chosen.",
      ),
      predict(
        "alternate-pattern",
        "What is the value of `size(2)`?",
        "fn size(n: Int) -> String {\n  case n {\n    1 | 2 | 3 -> \"small\"\n    _ -> \"big\"\n  }\n}",
        ["\"small\"", "\"big\"", "2", "\"1 | 2 | 3\""],
        0,
        "Correct! 2 is one of `1 | 2 | 3`, so it binds to the \"small\" branch.",
        [
          #(
            1,
            "\"big\" is for when none of 1, 2, or 3 match. 2 is included in that set.",
          ),
          #(
            2,
            "A case returns the result of the matching branch, not the inspected value — \"small\".",
          ),
          #(3, "`1 | 2 | 3` is a pattern, not an output string."),
        ],
      ),
      Prose(
        "order-trap",
        "Branch order **matters**. Since `_` matches every value, if you put `_` at the top, the branches below it can never be reached (dead code). In that case the Gleam compiler emits an \"Unreachable pattern\" warning — get into the habit of reading warnings too.",
      ),
      predict(
        "reversed-guard-order",
        "Here the branch order is reversed so that `_ -> \"F\"` is at the top. What is the value of `grade(95)`?",
        "fn grade(score: Int) -> String {\n  case score {\n    _ -> \"F\"\n    s if s >= 90 -> \"A\"\n    s if s >= 80 -> \"B\"\n  }\n}",
        ["\"A\"", "\"B\"", "\"F\"", "compile error"],
        2,
        "Correct! Since `_` is at the top, every value including 95 ends at the first branch with \"F\". The two branches below are dead code (a warning is emitted).",
        [
          #(
            0,
            "95 is indeed 90 or above, but `_` catches everything first, before that branch is reached.",
          ),
          #(
            1,
            "The \"B\" branch is also unreachable — `_` at the top takes every value.",
          ),
          #(
            3,
            "An unreachable branch is only a *warning*, not an error — it compiles and always yields \"F\".",
          ),
        ],
      ),
    ],
  )
}

fn lesson_no_early_return() -> Lesson {
  Lesson(
    id: "l07-no-early-return",
    unit_id: "u03-case-branching",
    title: "There Is No early return",
    emits_tags: [
      Concept("case-expressions"),
      Tricky("no-early-return"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam has no **early return** like `if (condition) return ...;` from other languages. There is no `return` keyword at all.\n\nA function is **a single expression**, and every path converges to one value. So a branch that \"bails out early\" does not disappear — it becomes **one branch** of a `case`. Think of each `return` in pseudocode as moving into a case branch.",
      ),
      Prose(
        "translate",
        "For example, take this imperative pseudocode:\n\n```\nif n < 0: return \"negative\"\nif n == 0: return \"zero\"\nreturn \"positive\"\n```\n\nIn Gleam it gathers into a single case:\n\n```\nfn sign_label(n: Int) -> String {\n  case n {\n    _ if n < 0 -> \"negative\"\n    0 -> \"zero\"\n    _ -> \"positive\"\n  }\n}\n```\n\nEach `return` becomes one branch.",
      ),
      predict(
        "sign-negative",
        "What is the value of `sign_label(-5)`?",
        "fn sign_label(n: Int) -> String {\n  case n {\n    _ if n < 0 -> \"negative\"\n    0 -> \"zero\"\n    _ -> \"positive\"\n  }\n}",
        ["\"negative\"", "\"zero\"", "\"positive\"", "-5"],
        0,
        "Correct! -5 passes the first guard `n < 0`, so it becomes \"negative\" — just like the first return in the imperative version.",
        [
          #(1, "\"zero\" is the `0` pattern branch. -5 is not 0."),
          #(
            2,
            "\"positive\" only appears if both branches above are missed. -5 is caught by the first branch.",
          ),
          #(
            3,
            "A case returns the result of the matching branch, not the number that was inspected.",
          ),
        ],
      ),
      predict(
        "sign-zero",
        "In the same `sign_label`, what is the value of `sign_label(0)`?",
        "fn sign_label(n: Int) -> String {\n  case n {\n    _ if n < 0 -> \"negative\"\n    0 -> \"zero\"\n    _ -> \"positive\"\n  }\n}",
        ["\"negative\"", "\"zero\"", "\"positive\"", "0"],
        1,
        "Exactly! For 0, `n < 0` is false so it skips the first branch, and it matches the `0` pattern precisely, yielding \"zero\".",
        [
          #(
            0,
            "0 is not negative — `0 < 0` is false, so it does not pass the first branch.",
          ),
          #(2, "0 is caught by the `0` pattern before reaching the final `_`."),
          #(
            3,
            "A case returns the branch's result \"zero\", not the value that was inspected.",
          ),
        ],
      ),
      Prose(
        "redundant-bool",
        "As you eliminate early returns, another pitfall comes into view: code that **takes a value that is already a Bool and unpacks it again with a case to return `True -> True`, `False -> False`**. The condition expression is already the Bool value we want, so we can simply return it directly.",
      ),
      mcq(
        "redundant-bool-spot",
        "Which of the following is the most unidiomatic (needlessly verbose) code?",
        [
          "case n > 0 { True -> True False -> False }",
          "n > 0",
          "case n { _ if n > 0 -> True _ -> False }",
          "n >= 1",
        ],
        0,
        "Correct! `n > 0` is already a Bool. Unpacking it with a case to return `True -> True` is just cruft that rebuilds the same value the long way around.",
        [
          #(
            1,
            "`n > 0` is the most concise correct form — it is already a Bool, so just return it directly.",
          ),
          #(
            2,
            "This is a little verbose, but not as much cruft as (1) — the real cruft is unpacking a Bool with a case again.",
          ),
          #(
            3,
            "For an integer input, `n >= 1` gives the same result as `n > 0`, so it is fairly concise.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_imperative_to_expr() -> Lesson {
  Lesson(
    id: "l08-imperative-to-expr",
    unit_id: "u03-case-branching",
    title: "From Imperative to Expression",
    emits_tags: [
      Concept("case-expressions"),
      Tricky("no-early-return"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "This lesson shifts your thinking one more notch: it turns the imperative habit of **assigning a value to a variable and then overwriting it with an if** into expression thinking that **uses the result of a case expression directly**.\n\nWhere imperative code goes \"empty variable → fill it per condition\", Gleam goes \"a single case where every branch yields a value\". If you want to store it in a variable, just bind the case's result like `let x = case ... { ... }`.",
      ),
      predict(
        "fee-translate",
        "Fees by age: under 13 is 0, under 65 is 1000, otherwise 500. What is the value of `fee(70)`?",
        "fn fee(age: Int) -> Int {\n  case age {\n    a if a < 13 -> 0\n    a if a < 65 -> 1000\n    _ -> 500\n  }\n}",
        ["`0`", "`1000`", "`500`", "`70`"],
        2,
        "Correct! 70 is neither `< 13` nor `< 65`, so it becomes 500 from the final `_` branch.",
        [
          #(0, "0 is for under 13. 70 does not fall there."),
          #(
            1,
            "1000 is for under 65. 70 is 65 or above, so it drops to the next branch.",
          ),
          #(
            3,
            "A case returns the result of the matching branch (500), not the age that was inspected.",
          ),
        ],
      ),
      Prose(
        "multi-subject",
        "A case can also inspect **several values at once**: group them with commas like `case a, b { ... }`, and list the patterns in each branch with commas too. It is a powerful tool for flattening a nested if-ladder into one flat case.",
      ),
      predict(
        "fizzbuzz-translate",
        "What is the value of `fizz(15)`?",
        "fn fizz(n: Int) -> String {\n  case n % 3, n % 5 {\n    0, 0 -> \"FizzBuzz\"\n    0, _ -> \"Fizz\"\n    _, 0 -> \"Buzz\"\n    _, _ -> \"other\"\n  }\n}",
        ["\"FizzBuzz\"", "\"Fizz\"", "\"Buzz\"", "\"other\""],
        0,
        "Correct! 15 is divisible by both 3 and 5, so it becomes `0, 0` and matches the first branch \"FizzBuzz\".",
        [
          #(
            1,
            "\"Fizz\" is when divisible only by 3 (`0, _`). 15 is also divisible by 5.",
          ),
          #(
            2,
            "\"Buzz\" is when divisible only by 5 (`_, 0`). 15 is also divisible by 3.",
          ),
          #(
            3,
            "\"other\" is when neither divides. 15 is divisible by both — the first branch wins.",
          ),
        ],
      ),
      mcq(
        "let-case-bind",
        "Which is the idiomatic Gleam way to write \"I want to store a grade string in a variable `label` depending on the score\"?",
        [
          "let label = case score { s if s >= 90 -> \"A\" _ -> \"F\" }",
          "var label; if score >= 90 { label = \"A\" }",
          "label = case score { ... }",
          "case score { s if s >= 90 -> let label = \"A\" }",
        ],
        0,
        "Correct! A case is an expression, so you can bind its result directly with `let label =` — this is expression thinking.",
        [
          #(
            1,
            "Gleam has no `var`, nor empty-variable-then-assign. You bind the case's result all at once.",
          ),
          #(
            2,
            "A binding always needs `let` — `label = ...` alone is not enough.",
          ),
          #(
            3,
            "Doing only `let` inside a branch means the case yields no value. You must put a value (\"A\") in the result position.",
          ),
        ],
      ),
    ],
  )
}

// ── Unit 4: 커스텀 타입과 레코드 (사고 전환 II) ──────────────────
fn unit_custom_types() -> Unit {
  let meta =
    UnitMeta(
      id: "u04-custom-types",
      title: "Custom Types and Records",
      order: 4,
      level: 2,
      concepts: [
        Concept("custom-types"),
        Concept("labelled-fields"),
        Concept("case-expressions"),
      ],
      prerequisites: ["u03-case-branching"],
      lesson_ids: [
        "l09-variants", "l10-records-labelled", "l11-exhaustiveness",
        "l12-record-update", "l13-bool-vs-custom",
      ],
    )
  let lessons = [
    lesson_variants(),
    lesson_records_labelled(),
    lesson_exhaustiveness(),
    lesson_record_update(),
    lesson_bool_vs_custom(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u04-custom-types", lessons),
  )
}

fn lesson_variants() -> Lesson {
  Lesson(
    id: "l09-variants",
    unit_id: "u04-custom-types",
    title: "Modeling state with variants",
    emits_tags: [Concept("custom-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "So far we've only used the types Gleam gave us (`Int`, `String`, `Bool` …). Now we'll make **our own type**.\n\nInside `pub type Name { ... }` you list the possible **cases (variants)** one by one. A traffic light, for example, is one of three:\n\n```gleam\npub type TrafficLight {\n  Red\n  Yellow\n  Green\n}\n```\n\nNow a value of type `TrafficLight` can only ever be `Red`, `Yellow`, or `Green` — using a type to flat-out rule out \"impossible states\" is the heart of custom types.",
      ),
      mcq(
        "variant-meaning",
        "In the `TrafficLight` definition above, what are `Red`, `Yellow`, and `Green`?",
        [
          "Three distinct types",
          "Three possible values (variants) the `TrafficLight` type can hold",
          "Three variables",
          "Three functions",
        ],
        1,
        "Right! The three are the values (variants) that the **single type** `TrafficLight` can hold — a traffic light is one of these three.",
        [
          #(
            0,
            "There's only one type, `TrafficLight`. `Red`, `Yellow`, and `Green` are values of that type.",
          ),
          #(
            2,
            "They're not variables bound with `let`; they're the possible values listed by the type definition.",
          ),
          #(
            3,
            "Since they're names used without arguments they look like functions, but you don't call them — you use them as values themselves.",
          ),
        ],
      ),
      Prose(
        "match-variant",
        "Custom types are best friends with `case`. You just branch on which variant a value is. Write the variant name right in the pattern position.\n\n```gleam\npub fn next(light: TrafficLight) -> TrafficLight {\n  case light {\n    Red -> Green\n    Green -> Yellow\n    Yellow -> Red\n  }\n}\n```\n\nNotice that you can also return another `TrafficLight` value as the result.",
      ),
      predict(
        "next-red",
        "In the `next` function above, what is the value of `next(Red)`?",
        "pub type TrafficLight {\n  Red\n  Yellow\n  Green\n}\n\npub fn next(light: TrafficLight) -> TrafficLight {\n  case light {\n    Red -> Green\n    Green -> Yellow\n    Yellow -> Red\n  }\n}\n\n// next(Red) is?",
        ["`Red`", "`Yellow`", "`Green`", "`\"Green\"`"],
        2,
        "Right! It matches the `Red` pattern and returns the `Green` variant — after red comes green.",
        [
          #(
            0,
            "It's not the input as-is. The **result** of the `Red` branch, `Green`, comes out.",
          ),
          #(
            1,
            "`Yellow` is the result when the input is `Green`. The input here is `Red`.",
          ),
          #(
            3,
            "`Green` isn't a string but a variant value of `TrafficLight` — no quotes.",
          ),
        ],
      ),
      predict(
        "label-yellow",
        "Here's `label`, which translates a signal into Korean. What is the value of `label(Yellow)`?",
        "pub fn label(light: TrafficLight) -> String {\n  case light {\n    Red -> \"멈춤\"\n    Yellow -> \"주의\"\n    Green -> \"출발\"\n  }\n}\n\n// label(Yellow) is?",
        ["`\"멈춤\"`", "`\"주의\"`", "`\"출발\"`", "`Yellow`"],
        1,
        "Exactly! It matches the `Yellow` branch and becomes \"주의\".",
        [
          #(
            0,
            "\"멈춤\" is the result of the `Red` branch. The input is `Yellow`.",
          ),
          #(2, "\"출발\" is the result of the `Green` branch — not `Yellow`."),
          #(
            3,
            "`case` returns the result (a string) of the matched branch, not the input variant.",
          ),
        ],
      ),
      predict(
        "coin-payout",
        "Here's a coin-toss payout. What is the value of `payout(Heads)`?",
        "pub type Coin {\n  Heads\n  Tails\n}\n\npub fn payout(c: Coin) -> Int {\n  case c {\n    Heads -> 100\n    Tails -> 0\n  }\n}\n\n// payout(Heads) is?",
        ["`100`", "`0`", "`Heads`", "`200`"],
        0,
        "Right! It matches the `Heads` branch and gives 100.",
        [
          #(1, "0 is the result when it's `Tails`. The input is `Heads`."),
          #(
            2,
            "`case` returns the result of the branch (an `Int`), not the input variant.",
          ),
          #(
            3,
            "You don't add the two payouts — only the value of the single matched branch comes out.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_records_labelled() -> Lesson {
  Lesson(
    id: "l10-records-labelled",
    unit_id: "u04-custom-types",
    title: "Records and labelled fields",
    emits_tags: [Concept("custom-types"), Concept("labelled-fields")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "A variant can also **hold** data. If you write **fields** of the form `name: type` inside parentheses, you get a **record** that bundles several values into one.\n\n```gleam\npub type Player {\n  Player(name: String, score: Int, level: Int)\n}\n```\n\n`Player`, which has the same name as the type, is the constructor that makes values. To make one you write it with **labels**, like `Player(name: \"lucy\", score: 10, level: 1)`. To pull out a single field afterward, access it with a dot, like `p.score`.",
      ),
      predict(
        "field-access",
        "In the code below, what is the value of `p.score`?",
        "pub type Player {\n  Player(name: String, score: Int, level: Int)\n}\n\nlet p = Player(name: \"lucy\", score: 10, level: 1)\n// p.score is?",
        ["`10`", "`1`", "`\"lucy\"`", "`Player`"],
        0,
        "Right! `p.score` pulls out the value of the `score` field, 10, directly.",
        [
          #(
            1,
            "`1` is the `level` field. `.score` looks at the score position.",
          ),
          #(2, "\"lucy\" is the `name` field. What `.score` points to is 10."),
          #(3, "`p.score` pulls out a single field (10), not the whole record."),
        ],
      ),
      Prose(
        "labelled-order",
        "When fields have **labels**, you can write them in a different order when constructing — because the label says which field it is. `Player(level: 1, name: \"lucy\", score: 10)` makes exactly the same value as writing them in definition order. Labels banish the confusion of \"wait, what was the third argument again?\"",
      ),
      predict(
        "labelled-reorder",
        "Here's code that writes the labels in a different order. What is the value of `p.name`?",
        "pub type Player {\n  Player(name: String, score: Int, level: Int)\n}\n\nlet p = Player(level: 1, name: \"lucy\", score: 10)\n// p.name is?",
        ["`\"lucy\"`", "`1`", "`10`", "Compile error"],
        0,
        "Exactly! Since they're written with labels the order doesn't matter — `name` is still \"lucy\".",
        [
          #(
            1,
            "`1` is the `level` value. What the label `name:` points to is \"lucy\".",
          ),
          #(2, "`10` is the `score` value. `.name` looks at \"lucy\"."),
          #(
            3,
            "When you attach labels, reordering still compiles fine — the label tells it the position.",
          ),
        ],
      ),
      Prose(
        "destructure",
        "A record can also be **destructured** in a `case` or `let`. Writing something like `Point(x: x, y: y)` in the pattern position binds each field to a name all at once. Drop fields you don't need with `_`.",
      ),
      predict(
        "destructure-x",
        "Here's code that destructures a record. What's the output?",
        "pub type Point {\n  Point(x: Int, y: Int)\n}\n\nlet p = Point(x: 3, y: 7)\ncase p {\n  Point(x: x, y: _) -> echo x\n}",
        ["`3`", "`7`", "`10`", "`Point(3, 7)`"],
        0,
        "Right! `Point(x: x, y: _)` binds the `x` field (3) to the name `x`, and discards `y` with `_`.",
        [
          #(
            1,
            "`7` is the `y` field — but it was discarded with `_` and not used. What was bound is `x` (3).",
          ),
          #(
            2,
            "You don't add the two fields — destructuring just binds each field separately to a name.",
          ),
          #(
            3,
            "A destructuring pattern binds the extracted field value (3) to a name, not the whole record.",
          ),
        ],
      ),
      mcq(
        "labelled-why",
        "Which is the best benefit of using labelled fields (field labels) on a record?",
        [
          "It makes performance faster",
          "When constructing or destructuring, each value's field becomes clear by name",
          "You can make an unlimited number of fields",
          "You can omit the type annotation",
        ],
        1,
        "Right! Labels banish the \"wait, what was that third 1 again?\" of `Player(\"lucy\", 10, 1)` — the meaning becomes clear from the names.",
        [
          #(
            0,
            "Labels are for readability and have nothing to do with performance — they make the same value.",
          ),
          #(
            2,
            "The number of fields has nothing to do with labels. What labels do is attach a name to each position.",
          ),
          #(
            3,
            "Field type annotations are still required — labels don't stand in for types.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_exhaustiveness() -> Lesson {
  Lesson(
    id: "l11-exhaustiveness",
    unit_id: "u04-custom-types",
    title: "Handling everything — exhaustiveness",
    emits_tags: [Concept("case-expressions"), Tricky("exhaustiveness")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "When you use `case` on a custom type, Gleam's real safety net switches on: **it only compiles if you handle every variant**. Miss even one and it won't compile at all.\n\n```gleam\npub type Shape {\n  Circle(radius: Float)\n  Rectangle(width: Float, height: Float)\n}\n\npub fn area(shape: Shape) -> Float {\n  case shape {\n    Circle(radius: r) -> 3.14159 *. r *. r\n    Rectangle(width: w, height: h) -> w *. h\n  }\n}\n```\n\nArea is a Float computation, so we use `*.`. Inside the pattern, `radius: r` binds that field to the name `r` so you can use it in the result expression.",
      ),
      predict(
        "area-circle",
        "In the `area` above, what is the value of `area(Circle(radius: 2.0))`?",
        "pub type Shape {\n  Circle(radius: Float)\n  Rectangle(width: Float, height: Float)\n}\n\npub fn area(shape: Shape) -> Float {\n  case shape {\n    Circle(radius: r) -> 3.14159 *. r *. r\n    Rectangle(width: w, height: h) -> w *. h\n  }\n}\n\n// area(Circle(radius: 2.0)) is?",
        ["`12.56636`", "`6.28318`", "`4.0`", "`12`"],
        0,
        "Right! 3.14159 *. 2.0 *. 2.0 = 12.56636. `r` is bound to 2.0, so you multiply pi by the radius squared.",
        [
          #(
            1,
            "That's 3.14159 *. 2.0 (multiplied by the diameter). Area multiplies the radius **twice** — r *. r.",
          ),
          #(
            2,
            "4.0 is just 2.0 *. 2.0 (r squared); you haven't multiplied by pi (3.14159) yet.",
          ),
          #(
            3,
            "The result is a `Float`, so it's `12.56636`, not `12` (an Int) — the type is different.",
          ),
        ],
      ),
      Prose(
        "inexhaustive",
        "What happens if you delete the `Rectangle` branch? Gleam gives the following compile error:\n\n```\nerror: Inexhaustive patterns\n\nThis case expression does not have a pattern for all possible values.\nThe missing patterns are:\n\n    Rectangle(width:, height:)\n```\n\nThe compiler **points out exactly the missing variant**. This is the safety net: if you add `Triangle` later, the compiler tells you every place you need to fix, including this `case`.",
      ),
      mcq(
        "missing-pattern",
        "Compiling an `area` with the `Rectangle` branch deleted gives an \"Inexhaustive patterns\" error. What's the most correct way to fix it?",
        [
          "Add the `Rectangle(width: w, height: h) -> w *. h` branch",
          "Add a `_ -> 0.0` branch",
          "Change the `case` into an `if`",
          "Delete the `Rectangle` variant from the type definition",
        ],
        0,
        "Right! Explicitly handling the missing variant is the answer — just add the `Rectangle` the compiler pointed out.",
        [
          #(
            1,
            "It compiles, but it's a trap. `_` switches off the exhaustiveness check, so even if you add `Triangle` later the compiler stays silent — spell out the variant.",
          ),
          #(
            2,
            "Gleam has no separate `if` statement, and the problem isn't the branching tool but the missing branch — just add the `Rectangle` branch.",
          ),
          #(
            3,
            "Then you couldn't represent a rectangle anymore — the goal is to handle it, not to delete it from the type.",
          ),
        ],
      ),
      mcq(
        "wildcard-trap",
        "Why is it dangerous to habitually tack a `_ -> ...` onto the end of every case just to satisfy exhaustiveness?",
        [
          "Compilation gets slower",
          "`_` quietly swallows even future new variants, switching off the compiler's \"places to fix\" warning",
          "`_` is a syntax error",
          "Runtime gets slower",
        ],
        1,
        "Exactly! The safety net where the compiler warns you when you add a variant stops working because of `_` — the new variant silently falls into `_`.",
        [
          #(
            0,
            "It has nothing to do with compile speed. The problem is that you lose the future safety net.",
          ),
          #(
            2,
            "`_` is valid syntax — what's dangerous isn't the syntax but that it 'swallows every future change'.",
          ),
          #(
            3,
            "It's not a runtime performance problem; the problem is that it disables the compile-time check.",
          ),
        ],
      ),
      predict(
        "area-rectangle",
        "In the same `area`, what is the value of `area(Rectangle(width: 3.0, height: 4.0))`?",
        "pub fn area(shape: Shape) -> Float {\n  case shape {\n    Circle(radius: r) -> 3.14159 *. r *. r\n    Rectangle(width: w, height: h) -> w *. h\n  }\n}\n\n// area(Rectangle(width: 3.0, height: 4.0)) is?",
        ["`12.0`", "`7.0`", "`12`", "`14.0`"],
        0,
        "Right! The `Rectangle` branch returns `w *. h` = 3.0 *. 4.0 = 12.0.",
        [
          #(
            1,
            "7.0 is 3.0 +. 4.0 (addition). Area is the product (`*.`), so it's 12.0.",
          ),
          #(
            2,
            "The result is a `Float`, so it's `12.0`, not `12` (an Int) — the type is different.",
          ),
          #(
            3,
            "14.0 is something like half the perimeter. Area is w *. h = 12.0.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_record_update() -> Lesson {
  Lesson(
    id: "l12-record-update",
    unit_id: "u04-custom-types",
    title: "Record update — what 'modifying' really is",
    emits_tags: [Concept("custom-types"), Tricky("record-update-copy")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "When you want to change just one field of a record, Gleam gives you the **record update** syntax `Player(..p, level: p.level + 1)`. It means \"leave the rest of `p`'s fields as they are, and set only `level` to a new value.\"\n\n```gleam\npub type Player {\n  Player(name: String, score: Int, level: Int)\n}\n\npub fn level_up(p: Player) -> Player {\n  Player(..p, level: p.level + 1)\n}\n```\n\nBut here U1's immutability shows up again: this syntax does **not change** `p`. It just makes a **new record** with the changed value (the rest shares structure, so it's cheap).",
      ),
      predict(
        "level-up-both",
        "In the code below, what are `p1.level` and `p2.level` respectively?",
        "pub fn level_up(p: Player) -> Player {\n  Player(..p, level: p.level + 1)\n}\n\nlet p1 = Player(name: \"lucy\", score: 10, level: 1)\nlet p2 = level_up(p1)\n// p1.level and p2.level are?",
        ["`1` and `2`", "`2` and `2`", "`1` and `1`", "`2` and `1`"],
        0,
        "Exactly! `level_up` just makes and returns a new record; `p1` stays level 1 forever — only `p2` is 2.",
        [
          #(
            1,
            "Record update doesn't touch the original. `p1` stays level 1 — read it as 'makes a changed copy', not 'changes it'.",
          ),
          #(
            2,
            "`p2` is a new record with `level + 1` applied, so it's 2 — they aren't both 1.",
          ),
          #(
            3,
            "The order is swapped. The original `p1` is 1, and the newly made `p2` is 2.",
          ),
        ],
      ),
      mcq(
        "update-semantics",
        "What does the expression `Player(..p, level: p.level + 1)` actually do?",
        [
          "Increments `p`'s `level` field by 1 in place",
          "Leaves `p` as it is and makes a new `Player` record with only `level` changed",
          "Deletes `p` and makes it again",
          "Resets `level` to 0",
        ],
        1,
        "Right! Record update makes a new value as if copying the original — it's U1's immutability extended to data structures.",
        [
          #(
            0,
            "Gleam has no in-place mutation — `p` never changes and a new record is created.",
          ),
          #(
            2,
            "It's not delete-and-recreate; `p` stays alive and a new copy is laid on top of it.",
          ),
          #(
            3,
            "`..p` brings the rest of the fields over from `p` as they are — it's preservation, not resetting.",
          ),
        ],
      ),
      predict(
        "update-name-untouched",
        "After a record update the original's other fields are still safe. What's the output?",
        "let p1 = Player(name: \"lucy\", score: 10, level: 1)\nlet p2 = level_up(p1)\necho p1.name",
        ["`\"lucy\"`", "`\"\"`", "`Nil`", "Compile error"],
        0,
        "Right! `level_up` doesn't touch `p1` at all, so `p1.name` is still \"lucy\".",
        [
          #(
            1,
            "The field isn't erased — the original `p1` is preserved exactly as made.",
          ),
          #(2, "`p1.name` is a `String` value (\"lucy\") — not `Nil`."),
          #(
            3,
            "It compiles and runs fine — accessing the original's field is no problem at all.",
          ),
        ],
      ),
      Prose(
        "any-type",
        "Record update works on any record, and you can change several fields at once, like `Config(..base, width: 1920, height: 1080)`. The rule is the same here: `base` stays as it is, and out comes a **new record** with new values only for the fields you specified.",
      ),
      predict(
        "config-update",
        "Here's code that changes several fields at once. What's the output?",
        "pub type Config {\n  Config(width: Int, height: Int, fullscreen: Bool)\n}\n\nlet base = Config(width: 800, height: 600, fullscreen: False)\nlet big = Config(..base, width: 1920, height: 1080)\necho int.to_string(big.width) <> \" \" <> int.to_string(base.width)",
        ["`\"1920 800\"`", "`\"1920 1920\"`", "`\"800 1920\"`", "`\"800 800\"`"],
        0,
        "Exactly! `big.width` is the new value 1920, and `base.width` isn't touched so it stays 800 — the original is safe.",
        [
          #(
            1,
            "`base` isn't affected by the record update — `base.width` is still 800.",
          ),
          #(
            2,
            "The order is swapped. The expression outputs `big.width` (1920) first, then `base.width` (800).",
          ),
          #(
            3,
            "`big` is a new record with `width: 1920` changed — `big.width` is 1920, not 800.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_bool_vs_custom() -> Lesson {
  Lesson(
    id: "l13-bool-vs-custom",
    unit_id: "u04-custom-types",
    title: "Custom types instead of Bool",
    emits_tags: [Concept("custom-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "When there are only two states, you're tempted to use `Bool` — like `is_admin: Bool`. But once the states grow to three or more, `Bool` can't express it. On top of that, `True`/`False` doesn't let you read \"what is true\" from the code (so-called *boolean blindness*).\n\nThat's why in Gleam we love to make **variants with meaningful names**.\n\n```gleam\npub type Access {\n  Guest\n  Member\n  Admin\n}\n```\n\n`Admin` is clear in meaning by itself, and even if you slot in `Moderator` later, the compiler points out all the places to fix.",
      ),
      mcq(
        "why-custom",
        "Which is a correct reason it's good to represent permissions with the custom type `Access { Guest Member Admin }` instead of `is_admin: Bool`?",
        [
          "It's always faster than Bool",
          "It can be expressed even with three or more states, and each state's meaning shows up in its name",
          "You no longer need to use `case`",
          "It uses less memory",
        ],
        1,
        "Right! Two `Bool` values can't hold three or more, and `True`/`False` hides the meaning. Variants give you both meaning and extensibility.",
        [
          #(
            0,
            "Speed isn't the goal — expressiveness and clarity of meaning are the point.",
          ),
          #(
            2,
            "On the contrary, you handle each variant with `case`, and you even gain the exhaustiveness safety net.",
          ),
          #(
            3,
            "Saving memory isn't the goal; the goal is to 'rule out impossible states and reveal meaning'.",
          ),
        ],
      ),
      predict(
        "can-delete-member",
        "Here's whether each permission can delete. What is the value of `can_delete(Member)`?",
        "pub type Access {\n  Guest\n  Member\n  Admin\n}\n\npub fn can_delete(a: Access) -> Bool {\n  case a {\n    Admin -> True\n    Member -> False\n    Guest -> False\n  }\n}\n\n// can_delete(Member) is?",
        ["`True`", "`False`", "`Member`", "Compile error"],
        1,
        "Right! The `Member` branch returns `False` — a member has no delete permission.",
        [
          #(
            0,
            "`True` is when it's `Admin`. The input is `Member`, so it's `False`.",
          ),
          #(
            2,
            "`case` returns the result of the branch (a `Bool`), not the input variant.",
          ),
          #(
            3,
            "All three variants are handled so it's exhaustive — it compiles fine.",
          ),
        ],
      ),
      Prose(
        "states-as-type",
        "Where boolean blindness especially hurts is intermediate states like \"in progress.\" If you make the connection state `is_connected: Bool`, there's no place to express \"connecting.\" With a variant it's clean:\n\n```gleam\npub type Connection {\n  Connecting\n  Connected\n  Disconnected\n}\n```",
      ),
      predict(
        "connection-message",
        "Here's a message per connection state. What is the value of `message(Connected)`?",
        "pub type Connection {\n  Connecting\n  Connected\n  Disconnected\n}\n\npub fn message(c: Connection) -> String {\n  case c {\n    Connecting -> \"연결 중...\"\n    Connected -> \"연결됨\"\n    Disconnected -> \"끊김\"\n  }\n}\n\n// message(Connected) is?",
        ["`\"연결 중...\"`", "`\"연결됨\"`", "`\"끊김\"`", "`Connected`"],
        1,
        "Exactly! It matches the `Connected` branch and becomes \"연결됨\" — if it were a `Bool` you couldn't have held these three states.",
        [
          #(
            0,
            "\"연결 중...\" is the `Connecting` branch — the input is `Connected`.",
          ),
          #(2, "\"끊김\" is the `Disconnected` branch — not `Connected`."),
          #(
            3,
            "`case` returns the result (a string) of the matched branch, not the input variant.",
          ),
        ],
      ),
      mcq(
        "boolean-blindness",
        "Which is the most correct problem with the function signature `fn render(loading: Bool, error: Bool) -> ...`?",
        [
          "Bool can't be used as a function argument",
          "A contradictory 'impossible state' like `(True, True)` is allowed by the type, and the meaning isn't revealed in names",
          "It's slow because there are two arguments",
          "Bool can't be used in `case`",
        ],
        1,
        "Right! `(True, True)` — loading and erroring at the same time — makes no sense, yet the type can't prevent it. If you bundle the one state into a variant type, you can eliminate the impossible combination entirely.",
        [
          #(
            0,
            "`Bool` works perfectly well as an argument — the problem is that several `Bool`s allow a contradictory state.",
          ),
          #(
            2,
            "The number of arguments and speed are unrelated — the key is that the type can't prevent impossible states.",
          ),
          #(
            3,
            "`Bool` can be handled fine with `case True/False` — that's not the problem.",
          ),
        ],
      ),
    ],
  )
}

fn unit_lists_recursion() -> Unit {
  let meta =
    UnitMeta(
      id: "u05-lists-recursion",
      title: "Lists and Recursion",
      order: 5,
      level: 2,
      concepts: [Concept("lists"), Concept("recursion")],
      prerequisites: ["u04-custom-types"],
      lesson_ids: [
        "l05-list-prepend", "l05-head-tail-pattern", "l05-first-recursion",
        "l05-termination", "l05-no-loops",
      ],
    )
  let lessons = [
    lesson_list_prepend(),
    lesson_head_tail_pattern(),
    lesson_first_recursion(),
    lesson_termination(),
    lesson_no_loops(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u05-lists-recursion", lessons),
  )
}

fn lesson_list_prepend() -> Lesson {
  Lesson(
    id: "l05-list-prepend",
    unit_id: "u05-lists-recursion",
    title: "List(a) and prepend",
    emits_tags: [Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "A list is a data structure that holds values of the same type **in order**. `[1, 2, 3]` is a `List(Int)`, and `[\"a\", \"b\"]` is a `List(String)`. Every element in a single list must be **of the same type**.\n\nThe empty list is `[]`. Keep an eye on this tiny empty list — it later becomes the **starting point** of recursion.",
      ),
      mcq(
        "list-homogeneous",
        "Which of the following is a valid list in Gleam?",
        [
          "`[1, \"a\", True]`",
          "`[1, 2, 3]`",
          "`{1, 2, 3}`",
          "`(1, 2, 3)`",
        ],
        1,
        "Correct! Every element of a list must be the same type — `[1, 2, 3]` is all `Int`, so it's a `List(Int)`.",
        [
          #(
            0,
            "The types are mixed — you can't put `Int`, `String`, and `Bool` in one list. They must all be the same type.",
          ),
          #(2, "`{...}` isn't list syntax — lists use square brackets `[...]`."),
          #(3, "`(...)` is tuple syntax. Lists use `[...]`."),
        ],
      ),
      Prose(
        "prepend",
        "Adding a single element to the **front** of a list is called prepend. With the `[head, ..tail]` syntax, you place a new element (head) on top of an existing list (tail) to make a **new list**.\n\nWhen `let xs = [1, 2, 3]`, then `[0, ..xs]` is `[0, 1, 2, 3]`. The important point: `xs` doesn't change — exactly the immutability you learned in the previous unit, a new list is simply created. Prepend reuses the existing list as-is, so it's very fast (O(1)).",
      ),
      predict(
        "prepend-front",
        "When `xs` is `[1, 2, 3]`, what is the value of `[0, ..xs]`?",
        "let xs = [1, 2, 3]\nlet ys = [0, ..xs]\n// what is ys?",
        ["`[0, 1, 2, 3]`", "`[1, 2, 3, 0]`", "`[0, [1, 2, 3]]`", "`[1, 2, 3]`"],
        0,
        "Exactly! `..` adds the new element to the **front (head)** — `[0, 1, 2, 3]`.",
        [
          #(
            1,
            "prepend adds to the **front** — 0 comes at the very front, not the back.",
          ),
          #(
            2,
            "It doesn't nest — `..` spreads the tail out to make a flat `[0, 1, 2, 3]`.",
          ),
          #(
            3,
            "`ys` is a new list — with 0 prepended it becomes `[0, 1, 2, 3]` (though `xs` itself stays the same).",
          ),
        ],
      ),
      predict(
        "prepend-two",
        "When `xs` is `[3]`, what is the value of `[1, 2, ..xs]`?",
        "let xs = [3]\nlet ys = [1, 2, ..xs]\n// what is ys?",
        ["`[1, 2, 3]`", "`[3, 1, 2]`", "`[1, 2, [3]]`", "`[1, 2]`"],
        0,
        "Correct! 1 and 2 are placed on the front in order, making `[1, 2, 3]` — the tail after `..` follows on unchanged.",
        [
          #(
            1,
            "The `1, 2` written in front come first, and the tail `[3]` follows, giving `[1, 2, 3]`.",
          ),
          #(
            2,
            "The tail doesn't become a single element — it spreads out into a flat `[1, 2, 3]`.",
          ),
          #(
            3,
            "The element of the tail `[3]` is included too — it's `[1, 2, 3]`, not `[1, 2]`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_head_tail_pattern() -> Lesson {
  Lesson(
    id: "l05-head-tail-pattern",
    unit_id: "u05-lists-recursion",
    title: "[first, ..rest] — the pattern that takes a list apart",
    emits_tags: [Concept("lists"), Tricky("empty-list-base-case")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "The `[head, ..tail]` syntax that **builds** a list is used, in the **pattern position** of a `case`, to **take a list apart**. The same shape works in the opposite direction.\n\nA list can only have two shapes:\n- `[]` — it's empty\n- `[first, ..rest]` — it splits into one head `first` and the remainder `rest` (a list)\n\nThese two patterns cover every possible case of a list, with none missed.",
      ),
      predict(
        "head-bind",
        "In the `[first, ..rest]` pattern, `first` is bound to the head element. What is the value of `first_or_zero([10, 20, 30])`?",
        "fn first_or_zero(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [first, ..rest] -> first\n  }\n}\n\n// what is first_or_zero([10, 20, 30])?",
        ["`10`", "`30`", "`0`", "`[20, 30]`"],
        0,
        "Correct! `first` is bound to the **head** of the list (the very first element), which is 10.",
        [
          #(
            1,
            "`first` is the **frontmost** element — 10, not the last one, 30.",
          ),
          #(
            2,
            "0 is the result for an empty list (`[]`) — the input isn't empty.",
          ),
          #(
            3,
            "`[20, 30]` is the `rest` (tail) — this function returns `first`.",
          ),
        ],
      ),
      predict(
        "rest-bind",
        "In the same pattern, `rest` is bound to the remaining list with the head removed. What is the value of `drop_first([10, 20, 30])`?",
        "fn drop_first(xs: List(Int)) -> List(Int) {\n  case xs {\n    [] -> []\n    [first, ..rest] -> rest\n  }\n}\n\n// what is drop_first([10, 20, 30])?",
        ["`[20, 30]`", "`[10, 20, 30]`", "`10`", "`[10]`"],
        0,
        "Exactly! `rest` is the remainder with the head 10 removed — `[20, 30]`.",
        [
          #(
            1,
            "`rest` is the part with the head **removed** — 10 is gone, giving `[20, 30]`.",
          ),
          #(
            2,
            "`10` is `first` (the head) — this function returns `rest` (the tail list).",
          ),
          #(3, "`rest` contains both 20 and 30 — it's `[20, 30]`, not `[10]`."),
        ],
      ),
      Prose(
        "two-cases",
        "The two patterns `[]` and `[first, ..rest]` cover **every case** of a list. So when you handle a list with `case`, having just these two passes the exhaustiveness check.\n\nThe key is that `[first, ..rest]` **peels off one layer** of the list — it removes one head and leaves a shorter `rest`. This \"shrinks by one layer each time\" property is what makes the recursion in the next lesson possible.",
      ),
      mcq(
        "list-shapes",
        "If you were to list all the shapes (patterns) a list can have in Gleam, which is correct?",
        [
          "Two of them: `[]` and `[first, ..rest]`",
          "Just one: `[]`",
          "Just one: `[first, ..rest]`",
          "A separate one for each element count — `[a]`, `[a, b]`, `[a, b, c]` ...",
        ],
        0,
        "Correct! A list has only two shapes — \"empty (`[]`)\" or \"one head + the rest (`[first, ..rest]`)\" — so these two cover every case.",
        [
          #(
            1,
            "There are also non-empty lists (`[1, 2]`, etc.) — you also need the `[first, ..rest]` pattern.",
          ),
          #(
            2,
            "The empty list `[]` is possible too — if you omit that case, you won't pass the exhaustiveness check.",
          ),
          #(
            3,
            "There's no need to split by length — a single `[first, ..rest]` covers **all** lengths of 1 or more.",
          ),
        ],
      ),
      predict(
        "rebuild",
        "Reattaching the head and tail you took apart gives you back the original. What is the value of `[1, ..[2, 3]]`?",
        "[1, ..[2, 3]]",
        ["`[1, 2, 3]`", "`[[1], 2, 3]`", "`[1, [2, 3]]`", "`[2, 3, 1]`"],
        0,
        "Correct! Combining the head 1 with the tail `[2, 3]` gives `[1, 2, 3]` — the reverse direction of taking it apart.",
        [
          #(
            1,
            "The head doesn't nest — 1 just goes in as the frontmost element, giving `[1, 2, 3]`.",
          ),
          #(
            2,
            "The tail `[2, 3]` doesn't become a single element — it spreads out into `[1, 2, 3]`.",
          ),
          #(
            3,
            "`..` adds to the **front** — 1 is at the very front, so it's `[1, 2, 3]`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_first_recursion() -> Lesson {
  Lesson(
    id: "l05-first-recursion",
    unit_id: "u05-lists-recursion",
    title: "First recursion: counting length and summing",
    emits_tags: [Concept("recursion"), Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam has **neither** `for` nor `while`. So how do you traverse a list? The answer is **recursion**: process one head, then **call yourself again on the tail**.\n\nEvery recursion is designed around two questions:\n1. If the input is the smallest possible (an empty list), what's the answer? — the **base case (termination condition)**\n2. After processing one head, what problem remains? — the **recursive step**",
      ),
      Prose(
        "length-example",
        "Let's look at a function that counts the length of a list:\n\n```gleam\npub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n```\n\nThe length of an empty list is 0 (base case). If it's not empty, add one head (`+1`) to **the length of the rest**. We don't use the head value itself, so we caught it with `_`.",
      ),
      predict(
        "length-3",
        "With the `length` function above, what is the value of `length([10, 20, 30])`?",
        "pub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n\n// what is length([10, 20, 30])?",
        ["`3`", "`60`", "`0`", "`30`"],
        0,
        "Correct! 1 + (1 + (1 + 0)) = 3. It peels off one head at a time, stacking up +1, and finishes with 0 at the empty list.",
        [
          #(
            1,
            "This function **counts** elements — it counts the quantity 3, it doesn't add them up (10+20+30).",
          ),
          #(
            2,
            "0 is for an empty list — there are 3 elements, so the result is 3.",
          ),
          #(
            3,
            "It returns the **count**, not the last element (30) — that's 3.",
          ),
        ],
      ),
      predict(
        "length-empty",
        "With the same `length` function, what is the value of `length([])`? (The base case is the very seed of the answer.)",
        "pub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n\n// what is length([])?",
        ["`0`", "`1`", "`Nil`", "compile error"],
        0,
        "Exactly! An empty list matches the first branch `[] -> 0` right away — the base case returns 0.",
        [
          #(1, "An empty list has no elements — its length is 0, not 1."),
          #(2, "The `[] -> 0` branch returns the `Int` 0 — it's not `Nil`."),
          #(3, "It compiles fine — `[]` and `[_, ..rest]` cover every case."),
        ],
      ),
      Prose(
        "total-example",
        "Using the same skeleton, we can also compute a **sum**. This time we need the head value, so we catch it with a name (`first`):\n\n```gleam\npub fn total(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [first, ..rest] -> first + total(rest)\n  }\n}\n```\n\nThe sum of an empty list is 0 (base case). If it's not empty, it's the **head value** + **the sum of the rest**. It's nearly identical to `length`, with just `first` in place of `1`.",
      ),
      predict(
        "total-sum",
        "With the `total` function above, what is the value of `total([2, 3, 5])`?",
        "pub fn total(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [first, ..rest] -> first + total(rest)\n  }\n}\n\n// what is total([2, 3, 5])?",
        ["`10`", "`3`", "`0`", "`5`"],
        0,
        "Correct! 2 + (3 + (5 + 0)) = 10. It adds the head values one by one and closes out with 0 at the empty list.",
        [
          #(
            1,
            "This function computes a sum — that's 2+3+5 = 10, not the count (3).",
          ),
          #(
            2,
            "0 is the base-case value for an empty list — the sum of the elements is 10.",
          ),
          #(
            3,
            "It adds up **all** of them, not just the last element (5) — that's 10.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_termination() -> Lesson {
  Lesson(
    id: "l05-termination",
    unit_id: "u05-lists-recursion",
    title: "The base case — recursion's lifeline",
    emits_tags: [Concept("recursion"), Tricky("empty-list-base-case")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "For recursion to terminate, **the problem must shrink with every call** until it eventually reaches the base case. The three main causes of infinite recursion are:\n1. **Missing empty-list case** — there's no `[]` branch\n2. **Recalling with the same argument** — `f(xs)` calls `f(xs)` again (it doesn't shrink)\n3. **An argument that doesn't decrease** — passing `n` instead of `n` (it should be `n - 1`)\n\nFortunately, the compiler blocks (1) for you — if there's no `[]` pattern, you get an Inexhaustive error, which **forces** you to think about the base case.",
      ),
      Prose(
        "countdown-example",
        "You can also recurse over numbers, not just lists. `countdown` builds a list holding n down to 1:\n\n```gleam\npub fn countdown(n: Int) -> List(Int) {\n  case n {\n    0 -> []\n    _ -> [n, ..countdown(n - 1)]\n  }\n}\n```\n\nThe base case is `0 -> []`. The recursive step prepends `n` and calls itself with **`n - 1`** (the smaller value). With every call n decreases by 1, eventually reaching 0 and stopping.",
      ),
      predict(
        "countdown-3",
        "With the `countdown` function above, what is the value of `countdown(3)`?",
        "pub fn countdown(n: Int) -> List(Int) {\n  case n {\n    0 -> []\n    _ -> [n, ..countdown(n - 1)]\n  }\n}\n\n// what is countdown(3)?",
        ["`[3, 2, 1]`", "`[1, 2, 3]`", "`[3, 2, 1, 0]`", "`[]`"],
        0,
        "Correct! It prepends 3 then `countdown(2)`, prepends 2 onto that... and stops at `0 -> []`, giving `[3, 2, 1]`.",
        [
          #(
            1,
            "Because it's prepend, larger numbers attach at the **front** — the order is `[3, 2, 1]`.",
          ),
          #(
            2,
            "The base case `0 -> []` returns an empty list **without holding** 0 — 0 isn't included.",
          ),
          #(3, "`[]` is for `countdown(0)` — `countdown(3)` holds 3 elements."),
        ],
      ),
      mcq(
        "same-arg-infinite",
        "In a list-sum function, suppose the recursive branch is written `first + total(xs)` instead of `first + total(rest)`. What happens?",
        [
          "`total(xs)` keeps calling itself with the **same** list, so it never finishes (infinite recursion)",
          "It works fine and returns the same sum",
          "It causes a compile error",
          "The sum is computed twice as large",
        ],
        0,
        "Correct! `xs` never shrinks, so it can never reach the base case (`[]`). In the browser, a watchdog terminates the stalled worker and tells you \"Timeout — the recursion didn't finish. Pass `rest` to make the problem smaller.\"",
        [
          #(
            1,
            "It doesn't work fine — `xs` never shrinks, so it never reaches `[]` and repeats forever.",
          ),
          #(
            2,
            "The syntax is valid, so it **does compile** — the problem is that it never finishes at runtime (a runtime infinite loop).",
          ),
          #(
            3,
            "It never stops to produce a value — it's not doubled; no result comes out at all.",
          ),
        ],
      ),
      mcq(
        "missing-base-case",
        "If you omit the `[] -> ...` base-case branch from a recursive function, how does Gleam react?",
        [
          "Compile error (Inexhaustive patterns) — it tells you the `[]` case is missing",
          "It compiles silently and falls into infinite recursion at runtime",
          "It automatically returns 0 when it meets an empty list",
          "It only emits a warning and compiles fine",
        ],
        0,
        "Exactly! Since a `case` must cover every case, if the `[]` branch is missing the compiler blocks it with an Inexhaustive patterns error — forcing you to think about the base case.",
        [
          #(
            1,
            "It doesn't let it slide silently — if `[]` is missing, it's caught right at the **compile step**.",
          ),
          #(
            2,
            "Gleam doesn't slot in a default value — a missing pattern is a compile error.",
          ),
          #(
            3,
            "It's an **error**, not a mere warning — if there's a missing pattern, compilation itself fails.",
          ),
        ],
      ),
      predict(
        "sum-to-good",
        "Here's a correct recursion where the argument shrinks with every call. What is the value of `sum_to(4)`?",
        "pub fn sum_to(n: Int) -> Int {\n  case n {\n    0 -> 0\n    _ -> n + sum_to(n - 1)\n  }\n}\n\n// what is sum_to(4)?",
        ["`10`", "`4`", "`0`", "never finishes (infinite recursion)"],
        0,
        "Correct! 4 + 3 + 2 + 1 + 0 = 10. With every call it shrinks by `n - 1`, reaches 0, and stops safely.",
        [
          #(
            1,
            "It's not the input itself (4) but the sum from 4 down to 1 — that's 10.",
          ),
          #(
            2,
            "0 is just the base-case value; the result is the sum accumulated on the way down — that's 10.",
          ),
          #(
            3,
            "It shrinks by `n - 1` each time, so it terminates — infinite recursion is when you don't shrink, like `sum_to(n)`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_no_loops() -> Lesson {
  Lesson(
    id: "l05-no-loops",
    unit_id: "u05-lists-recursion",
    title: "A world without indices — no loops",
    emits_tags: [Concept("lists"), Concept("recursion")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam has no **index access** like other languages' `for (i = 0; i < n; i++)` or `xs[i]`. Because a list is a \"head + tail\" structure, instead of grabbing the i-th element directly you **peel it off one layer at a time from the front**.\n\nSo \"do something to every element\" is also expressed with recursion: transform the head, prepend it to the result, and recurse on the tail.",
      ),
      Prose(
        "map-example",
        "Let's look at a function that doubles each element — no loop, just recursion:\n\n```gleam\npub fn double_all(xs: List(Int)) -> List(Int) {\n  case xs {\n    [] -> []\n    [first, ..rest] -> [first * 2, ..double_all(rest)]\n  }\n}\n```\n\nAn empty list gives an empty list (base case). If it's not empty, transform the head with `* 2` and **prepend it to the result of transforming the rest**. It's the exact same skeleton as `length`/`total`.",
      ),
      predict(
        "double-all",
        "With the `double_all` function above, what is the value of `double_all([1, 2, 3])`?",
        "pub fn double_all(xs: List(Int)) -> List(Int) {\n  case xs {\n    [] -> []\n    [first, ..rest] -> [first * 2, ..double_all(rest)]\n  }\n}\n\n// what is double_all([1, 2, 3])?",
        ["`[2, 4, 6]`", "`[1, 2, 3]`", "`[6, 4, 2]`", "`12`"],
        0,
        "Correct! It transforms each head by doubling and prepends as it goes down, giving `[2, 4, 6]` — the order is preserved.",
        [
          #(
            1,
            "The transformation is applied — it's not unchanged; each element is doubled, giving `[2, 4, 6]`.",
          ),
          #(
            2,
            "The order isn't reversed — the transformed head is prepended to the **front**, so the original order `[2, 4, 6]` is preserved.",
          ),
          #(
            3,
            "This function returns the transformed **list**, not the sum (2+4+6) — that's `[2, 4, 6]`.",
          ),
        ],
      ),
      mcq(
        "no-for-while",
        "What do you use to traverse every element of a list in Gleam?",
        [
          "Recursion — process the head and call yourself on the tail",
          "A `for` loop",
          "A `while` loop",
          "Access by index from 0 upward with `xs[i]`",
        ],
        0,
        "Correct! Gleam has no `for`/`while`, so iteration is expressed with recursion — the pattern of processing the head and calling yourself on the shorter tail.",
        [
          #(
            1,
            "Gleam has no `for` loop — iteration is done with recursion (or the `list` functions in the next unit).",
          ),
          #(
            2,
            "Gleam has no `while` loop either — you use recursion with a base case instead.",
          ),
          #(
            3,
            "There's no index access like `xs[i]` — lists are handled by peeling off head/tail one layer at a time.",
          ),
        ],
      ),
      mcq(
        "prepend-vs-append",
        "Which is correct about the cost of prepending (`[x, ..xs]`) versus appending to the back of a list?",
        [
          "prepend is fast at O(1), while appending to the back has to walk to the end of the list, so it's more expensive",
          "Both are equally O(1)",
          "prepend is more expensive — it has to move every element",
          "A list can insert anywhere in O(1) by index",
        ],
        0,
        "Exactly! Prepending at the head reuses the existing list as the tail unchanged, so it's O(1). That's why, when building results with recursion, you usually use the pattern of **prepending from the front**.",
        [
          #(
            1,
            "Appending to the back has to walk to the end, so it's more expensive than prepend — they aren't the same.",
          ),
          #(
            2,
            "It's the opposite — prepend is the cheapest at O(1) (it reuses the tail).",
          ),
          #(
            3,
            "Arbitrary insertion by index doesn't exist for lists — because of the head/tail structure, work at the front is cheap.",
          ),
        ],
      ),
    ],
  )
}

// ── Unit 6: Tail recursion and accumulators (a mindset shift — recursion as a jump) ──────────
fn unit_tail_recursion() -> Unit {
  let meta =
    UnitMeta(
      id: "u06-tail-recursion",
      title: "Tail Recursion and Accumulators",
      order: 6,
      level: 2,
      concepts: [Concept("tail-call-optimisation")],
      prerequisites: ["u05-lists-recursion"],
      lesson_ids: [
        "l15-stack-growth", "l16-accumulator", "l17-wrapper-loop",
        "l18-acc-reverse",
      ],
    )
  let lessons = [
    lesson_stack_growth(),
    lesson_accumulator(),
    lesson_wrapper_loop(),
    lesson_acc_reverse(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u06-tail-recursion", lessons),
  )
}

fn lesson_stack_growth() -> Lesson {
  Lesson(
    id: "l15-stack-growth",
    unit_id: "u06-tail-recursion",
    title: "Recursion That Grows the Stack, and Recursion That Doesn't",
    emits_tags: [Concept("tail-call-optimisation")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Let's look again at the recursion we wrote in U5. With `1 + length(rest)`, there's still work to do (`1 +`) **after** `length(rest)` comes back. That \"work to do later\" has to be recorded somewhere, so each layer of calls pushes one more **stack frame**.\n\n```gleam\npub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n```\n\nAs the list grows longer, the frames pile up just as deep, and with a very long input the stack can overflow.",
      ),
      predict(
        "length-still-works",
        "The value itself is correct. What is `length([10, 20, 30, 40])`?",
        "pub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n\n// length([10, 20, 30, 40]) is?",
        ["`3`", "`4`", "`100`", "`0`"],
        1,
        "Right! With four elements, `1 +` stacks up four times, giving 4. The result is correct, but along the way the stack grew four layers deep.",
        [
          #(
            0,
            "It counts as many as there are elements — four, so 4. 3 misses one.",
          ),
          #(
            2,
            "It doesn't add the values, it counts the *number* of them — length 4, not sum 100.",
          ),
          #(
            3,
            "0 is the terminating value for an empty list. Here there are four elements.",
          ),
        ],
      ),
      Prose(
        "what-is-tail",
        "The key distinction is \"is the recursive call the **last action** of that branch?\"\n\n- `1 + length(rest)` — there's still `1 +` left after the call returns → **not a tail call** (stack grows)\n- `count_loop(rest, acc + 1)` — the call itself is the last thing → **tail call** (stack doesn't grow)\n\nWhen the recursive call is the last action, Gleam compiles it into a **jump** (tail-call optimisation, TCO). Instead of pushing a new frame, it reuses the same frame.",
      ),
      mcq(
        "which-is-tail",
        "Which of the following branches is a **tail call** (the recursive call is the last action)?",
        [
          "`[first, ..rest] -> first + sum(rest)`",
          "`[_, ..rest] -> 1 + length(rest)`",
          "`[first, ..rest] -> sum_loop(rest, acc + first)`",
          "`[first, ..rest] -> { let n = go(rest) n * 2 }`",
        ],
        2,
        "Right! `sum_loop(rest, acc + first)` is itself the result of that branch — there's no work *after* the call, so it's a tail call and gets optimised into a jump.",
        [
          #(
            0,
            "There's still `first +` left on the recursive result — if an addition remains after the call, it's not a tail call.",
          ),
          #(
            1,
            "There's still `1 +` left on the recursive result — the last action is an addition, so it's not a tail call.",
          ),
          #(
            3,
            "It binds the recursive result to `n` and then does `n * 2` — a multiplication remains after the call, so it's not a tail call.",
          ),
        ],
      ),
      mcq(
        "why-tco",
        "What's the benefit of making the recursive call the \"last action\"?",
        [
          "The result value changes",
          "It loops by jumping instead of pushing stack frames, so the stack won't overflow even on long inputs",
          "Compilation gets faster",
          "It automatically converts recursion into a for loop",
        ],
        1,
        "Right! When there's no work after the call, Gleam compiles it into a jump — no frames pile up, so it's safe no matter how long the input is.",
        [
          #(
            0,
            "The value stays the same — only *how* you compute the same answer (stack vs jump) differs.",
          ),
          #(
            2,
            "It has nothing to do with compile speed — the point is that the stack doesn't grow at run time.",
          ),
          #(
            3,
            "Gleam has no for loops — the tail call itself becomes a loop that runs as a jump.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_accumulator() -> Lesson {
  Lesson(
    id: "l16-accumulator",
    unit_id: "u06-tail-recursion",
    title: "The Accumulator Pattern",
    emits_tags: [
      Concept("tail-call-optimisation"),
      Tricky("tail-call-accumulator"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "The key to turning non-tail recursion into tail recursion is an **accumulator**. You carry \"the answer so far\" down as an argument.\n\nInstead of adding *after* the call returns, like `1 + total(rest)`, you add ahead of time on the way down with `acc + first` and pass it to the next call. That makes the recursive call the **last action** of the branch.\n\n```gleam\nfn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n```\n\nStarting `acc` at 0, you add the elements one by one.",
      ),
      predict(
        "sumloop-from-zero",
        "What is `sum_loop([4, 5, 6], 0)`?",
        "fn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n\n// sum_loop([4, 5, 6], 0) is?",
        ["`15`", "`0`", "`4`", "`456`"],
        0,
        "Right! acc grows 0→4→9→15, and the empty list returns 15.",
        [
          #(
            1,
            "0 is the *starting* accumulator — once you add the elements it becomes 15.",
          ),
          #(
            2,
            "It's not just the first element 4 — 5 and 6 get accumulated too.",
          ),
          #(
            3,
            "It doesn't concatenate the digits, it *adds* them — 4+5+6 = 15.",
          ),
        ],
      ),
      Prose(
        "empty-returns-acc",
        "Here's the most confusing point: what should go in the terminating branch `[] -> ???`?\n\nIn the non-tail version (`total`), it was `[] -> 0`. There, 0 was the *seed* meaning \"the sum of an empty list is 0.\" But in the accumulator version, the sum has already been gathered up in `acc`. **The `acc` at the moment of termination is exactly the answer.**",
      ),
      predict(
        "empty-branch-hole",
        "We put `acc` in the `[] -> ???` slot. What is `sum_loop([1, 2, 3], 10)`? (starting acc is 10)",
        "fn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n\n// sum_loop([1, 2, 3], 10) is?",
        ["`6`", "`16`", "`10`", "`0`"],
        1,
        "Exactly! Adding 1+2+3 to the starting acc of 10 gives 16. The terminating branch returns the acc it gathered, just as it is.",
        [
          #(
            0,
            "You left out the starting value 10 — acc starts at 10 and becomes 16.",
          ),
          #(
            2,
            "10 is the starting accumulator — you have to add the elements to it to get 16.",
          ),
          #(
            3,
            "Because it's `[] -> acc`, it returns the gathered value — if it were `[] -> 0`, it would throw away what it gathered, which would be a bug.",
          ),
        ],
      ),
      mcq(
        "empty-zero-bug",
        "If you changed the terminating branch to `[] -> 0`, what would `sum_loop([1, 2, 3], 0)` do?",
        [
          "Still gives `6`",
          "Gives `0` — because it discards the acc it gathered at the end",
          "A compile error occurs",
          "It falls into infinite recursion",
        ],
        1,
        "Right! It goes all the way down building acc up to 6, and then the terminating branch ignores it and returns 0 — a bug that throws away everything you gathered.",
        [
          #(
            0,
            "The terminating branch returns 0 instead of acc, so 6 doesn't come out — it discards the gathered value.",
          ),
          #(
            2,
            "The types match, so it compiles — it's a *logic* bug, so it silently returns 0.",
          ),
          #(
            3,
            "The list gets shorter each time, so it does terminate — it just returns a wrong 0.",
          ),
        ],
      ),
      predict(
        "count-with-acc",
        "Counting works with the same pattern. What is `count_loop([7, 8, 9], 0)`?",
        "fn count_loop(xs: List(Int), acc: Int) -> Int {\n  case xs {\n    [] -> acc\n    [_, ..rest] -> count_loop(rest, acc + 1)\n  }\n}\n\n// count_loop([7, 8, 9], 0) is?",
        ["`3`", "`24`", "`0`", "`9`"],
        0,
        "Right! For each element you add 1 to acc, 0→1→2→3. At termination acc(=3) is the length.",
        [
          #(
            1,
            "It doesn't add the element values, it counts *by 1* each time — count 3, not sum 24.",
          ),
          #(
            2,
            "0 is the starting accumulator — counting three elements gives 3.",
          ),
          #(
            3,
            "It returns the *count* (3), not the value of the last element (9).",
          ),
        ],
      ),
    ],
  )
}

fn lesson_wrapper_loop() -> Lesson {
  Lesson(
    id: "l17-wrapper-loop",
    unit_id: "u06-tail-recursion",
    title: "The Wrapper + Private Loop Idiom",
    emits_tags: [Concept("tail-call-optimisation")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "The accumulator version has a small inconvenience. The caller has to pass the starting value `0` every time — `sum_loop(numbers, 0)`. Forgetting the starting value is troublesome, and exposing acc — an \"internal detail\" in the first place — to the outside is awkward too.\n\nSo the Gleam idiom is a **thin public wrapper + a private `_loop`**. The public function fills in the starting value and calls once, while the real recursion is handled by the hidden private function.\n\n```gleam\npub fn sum(numbers: List(Int)) -> Int {\n  sum_loop(numbers, 0)\n}\n\nfn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n```",
      ),
      predict(
        "wrapper-value",
        "What is `sum([2, 3, 5])`? (the wrapper fills in the starting acc 0 for you)",
        "pub fn sum(numbers: List(Int)) -> Int {\n  sum_loop(numbers, 0)\n}\n\nfn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n\n// sum([2, 3, 5]) is?",
        ["`10`", "`0`", "`2`", "`235`"],
        0,
        "Right! The wrapper calls `sum_loop([2, 3, 5], 0)` and acc becomes 0→2→5→10.",
        [
          #(
            1,
            "0 is the starting acc that the wrapper puts in — add the elements and you get 10.",
          ),
          #(
            2,
            "It's not just the first element 2 — 3 and 5 are accumulated too, so the sum is 10.",
          ),
          #(3, "It doesn't concatenate the digits, it adds them — 2+3+5 = 10."),
        ],
      ),
      Prose(
        "why-wrapper",
        "The nice things about this idiom:\n\n- The caller only needs to know `sum(xs)` — the wrapper fills in the starting value 0 on its own.\n- acc is an implementation detail, so it's not marked `pub` and is **invisible outside the module**.\n- The public function's type is cleanly `List(Int) -> Int` — the accumulator argument doesn't leak out.\n\nBy convention, the private recursive function is given a name like `_loop` (or `do_`, `go`).",
      ),
      mcq(
        "wrapper-purpose",
        "What does the wrapper (the public `sum`) do?",
        [
          "It performs the actual recursion directly",
          "It fills in the starting accumulator (0) and calls the private `_loop` once",
          "It reverses the result one more time",
          "It sorts the list",
        ],
        1,
        "Right! The wrapper is a thin one-liner that fills in the starting value and kicks off the private loop — the recursion itself is done by `_loop`.",
        [
          #(
            0,
            "The recursion is handled by the private `_loop` — the wrapper just fills in the starting value and calls it once.",
          ),
          #(
            2,
            "There's no reversing here — that's a different pattern that shows up when you build a list with prepend.",
          ),
          #(
            3,
            "It has nothing to do with sorting — the wrapper's only job is to fill in the starting acc.",
          ),
        ],
      ),
      mcq(
        "why-private",
        "What's the best reason for not exposing the private `sum_loop` as `pub`?",
        [
          "Because private functions run faster",
          "Because acc is an internal implementation detail, and you want to keep the outward API cleanly as `List(Int) -> Int`",
          "Because only private functions can recurse",
          "Because adding `pub` causes a compile error",
        ],
        1,
        "Right! The caller doesn't need the accumulator. Hiding it keeps the API clean and avoids passing a wrong starting value.",
        [
          #(
            0,
            "Whether something is `pub` has nothing to do with run speed — the difference is *outward exposure*.",
          ),
          #(
            2,
            "`pub`/private doesn't matter for recursion — public functions can recurse too.",
          ),
          #(
            3,
            "It compiles fine even with `pub` — it just leaks acc and makes the API messy.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_acc_reverse() -> Lesson {
  Lesson(
    id: "l18-acc-reverse",
    unit_id: "u06-tail-recursion",
    title: "A Side Effect of Accumulation: the Reversed Result",
    emits_tags: [Tricky("accumulator-reverse")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "When you build a *list* with an accumulator, one side effect appears. You stack each new element by **prepending it to the front** of the accumulator (`[x, ..acc]`), and since prepend is O(1), stacking this way is the right choice. But the price is that **the result comes out reversed**.\n\n```gleam\nfn double_loop(xs: List(Int), acc: List(Int)) -> List(Int) {\n  case xs {\n    [] -> acc\n    [first, ..rest] -> double_loop(rest, [first * 2, ..acc])\n  }\n}\n```\n\nThe first element goes in *first* and ends up buried *deepest*, while the last element comes to the front.",
      ),
      predict(
        "double-loop-reversed",
        "What is `double_loop([1, 2, 3], [])`?",
        "fn double_loop(xs: List(Int), acc: List(Int)) -> List(Int) {\n  case xs {\n    [] -> acc\n    [first, ..rest] -> double_loop(rest, [first * 2, ..acc])\n  }\n}\n\n// double_loop([1, 2, 3], []) is?",
        ["`[2, 4, 6]`", "`[6, 4, 2]`", "`[1, 2, 3]`", "`[6]`"],
        1,
        "Right! 2 goes in front of []→[2], 4 in front→[4, 2], 6 in front→[6, 4, 2]. Prepend accumulation reverses the order.",
        [
          #(
            0,
            "Each value is doubled, true, but *the order is reversed* — 1 goes in first and ends up buried deepest, giving [6, 4, 2].",
          ),
          #(
            2,
            "The values get doubled — it's 2,4,6 not 1,2,3, and on top of that the order is reversed to [6, 4, 2].",
          ),
          #(
            3,
            "Every element gets stacked — it's not just the last [6] that remains, it's [6, 4, 2].",
          ),
        ],
      ),
      Prose(
        "accumulate-then-reverse",
        "This reversal is **a pattern, not a bug**. If you want to preserve the order, you just pass through `list.reverse` once at the end in the wrapper. This is called the **accumulate-then-reverse** idiom (stack up, then reverse at the end).\n\n```gleam\npub fn double_all(xs: List(Int)) -> List(Int) {\n  list.reverse(double_loop(xs, []))\n}\n```\n\nYou stack quickly (O(1)) with prepend, then reverse exactly once at the end to restore the original order.",
      ),
      predict(
        "double-all-restored",
        "What is `double_all([1, 2, 3])`? (the wrapper applies `list.reverse` at the end)",
        "fn double_loop(xs: List(Int), acc: List(Int)) -> List(Int) {\n  case xs {\n    [] -> acc\n    [first, ..rest] -> double_loop(rest, [first * 2, ..acc])\n  }\n}\n\npub fn double_all(xs: List(Int)) -> List(Int) {\n  list.reverse(double_loop(xs, []))\n}\n\n// double_all([1, 2, 3]) is?",
        ["`[6, 4, 2]`", "`[2, 4, 6]`", "`[1, 2, 3]`", "`[3, 2, 1]`"],
        1,
        "Exactly! The loop builds [6, 4, 2], and `list.reverse` turns it back into [2, 4, 6], restoring the original order.",
        [
          #(
            0,
            "That's the value *before* reverse — the wrapper reverses it once into [2, 4, 6].",
          ),
          #(
            2,
            "The values get doubled — the elements aren't left as is, they become 2,4,6.",
          ),
          #(3, "You have to double the values — it's 2,4,6 not 1,2,3."),
        ],
      ),
      mcq(
        "why-prepend",
        "Why use prepend (`[x, ..acc]`) instead of append (`acc <> [x]`) in list accumulation and reverse at the end?",
        [
          "Because append is impossible",
          "Because prepend is O(1) and fast, and the reversal is solved by a single reverse at the end",
          "Because reverse changes the result value",
          "Because prepend preserves the order",
        ],
        1,
        "Right! Prepend is always O(1), so every step is fast. The reversal is cleanly fixed with a single reverse (O(n)) at the end.",
        [
          #(
            0,
            "Append is possible too — it's just slow because each time it scans to the end of the list, making it O(n).",
          ),
          #(
            2,
            "Reverse only changes the *order* — the values themselves (the doubled results) stay the same.",
          ),
          #(
            3,
            "Prepend *reverses* the order — that's exactly why you need reverse at the end.",
          ),
        ],
      ),
      mcq(
        "reverse-is-pattern",
        "When you see that a list built with an accumulator comes out reversed, what's the best conclusion?",
        [
          "It's a bug — the recursion was written wrong",
          "It's normal — it's the natural result of prepend accumulation, and if needed you restore it with `list.reverse` at the end",
          "The terminating condition is wrong",
          "The starting acc should be `[0]` instead of `[]`",
        ],
        1,
        "Right! When you stack with prepend, coming out reversed is normal — it's a pattern, not a bug. If order matters, just reverse once in the wrapper.",
        [
          #(
            0,
            "It's not a bug — prepend accumulation inherently produces a reversed result. You just finish off with reverse.",
          ),
          #(
            2,
            "The terminating condition `[] -> acc` is correct — the reversal is due to prepend, not termination.",
          ),
          #(
            3,
            "The starting value is correctly the empty list `[]` — giving `[0]` would mix a stray 0 into the result.",
          ),
        ],
      ),
    ],
  )
}

// ── Unit 7: Functions as Values ─────────────────────────────────────────
fn unit_functions_as_values() -> Unit {
  let meta =
    UnitMeta(
      id: "u07-functions-as-values",
      title: "Functions as Values",
      order: 7,
      level: 2,
      concepts: [
        Concept("anonymous-functions"),
        Concept("labelled-arguments"),
      ],
      prerequisites: ["u05-lists-recursion"],
      lesson_ids: [
        "u07-l01-anonymous-functions", "u07-l02-higher-order",
        "u07-l03-captures", "u07-l04-labelled-args",
      ],
    )
  let lessons = [
    lesson_anonymous_functions(),
    lesson_higher_order(),
    lesson_captures(),
    lesson_labelled_args(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u07-functions-as-values", lessons),
  )
}

fn lesson_anonymous_functions() -> Lesson {
  Lesson(
    id: "u07-l01-anonymous-functions",
    unit_id: "u07-functions-as-values",
    title: "Anonymous Functions and Function Values",
    emits_tags: [Concept("anonymous-functions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "So far we've defined functions by **giving them a name**, like `pub fn name(...) { ... }`. But in Gleam a function is itself a **value** — just like an integer or a string, you can store it in a variable and hand it off to other functions.\n\nA function created on the spot without a name is called an **anonymous function**, written `fn(args) { body }`. It's exactly the same kind of function — the only difference is that there's just `fn` with no name.\n\n```gleam\nlet double = fn(x) { x * 2 }\ndouble(21)  // 42\n```\n\nWe created the value `fn(x) { x * 2 }` and bound it to the name `double` with `let`. From then on we call it like any ordinary function, e.g. `double(21)`.",
      ),
      predict(
        "anon-bind-call",
        "In the code below, what is the value of `double(21)`?",
        "let double = fn(x) { x * 2 }\n\n// double(21) 은?",
        ["`42`", "`21`", "`2`", "Compile error"],
        0,
        "Exactly! `fn(x) { x * 2 }` is a function that doubles its input. `double(21)` is 21 * 2 = 42.",
        [
          #(
            1,
            "It doesn't return the input unchanged — `x * 2` is applied, so 21 * 2 = 42.",
          ),
          #(2, "`2` is just the multiplier; the return value is `x * 2` = 42."),
          #(
            3,
            "Binding an anonymous function with `let` and calling it is perfectly legal — functions are values, so they fit in variables.",
          ),
        ],
      ),
      Prose(
        "anon-vs-named",
        "A named function and an anonymous function are essentially the same thing. `pub fn double(x: Int) -> Int { x * 2 }` is fundamentally the same as binding `fn(x) { x * 2 }` to the name `double`.\n\nYou can also write argument and return types on an anonymous function (`fn(x: Int) -> Int { x * 2 }`), but for short cases people often leave them out and let the compiler's inference handle it.",
      ),
      predict(
        "anon-immediate",
        "You can also call an anonymous function the moment you create it. What is the value of this expression?",
        "fn(a, b) { a + b }(3, 4)",
        ["`7`", "`12`", "`34`", "Compile error"],
        0,
        "Right! Create `fn(a, b) { a + b }` and immediately call it with `(3, 4)`, giving 3 + 4 = 7.",
        [
          #(1, "`+` is addition, not multiplication — 3 + 4 = 7."),
          #(
            2,
            "The two arguments are added, not concatenated as text — 3 + 4 = 7.",
          ),
          #(
            3,
            "Calling it immediately with `(3, 4)` is legal — it's just applying a function value right away.",
          ),
        ],
      ),
      mcq(
        "anon-syntax",
        "What is the correct syntax for creating a nameless anonymous function?",
        [
          "`fn(x) { x * 2 }`",
          "`fn double(x) { x * 2 }`",
          "`lambda x: x * 2`",
          "`(x) => x * 2`",
        ],
        0,
        "Right! An anonymous function is `fn(args) { body }` — after `fn` come the parentheses directly, with no name.",
        [
          #(
            1,
            "`fn double(...)` is a named definition — an anonymous function has no name.",
          ),
          #(
            2,
            "`lambda` isn't Gleam syntax. Anonymous functions also use the keyword `fn`.",
          ),
          #(3, "Gleam has no `=>` arrow syntax — the body is wrapped in `{ }`."),
        ],
      ),
    ],
  )
}

fn lesson_higher_order() -> Lesson {
  Lesson(
    id: "u07-l02-higher-order",
    unit_id: "u07-functions-as-values",
    title: "Higher-Order Functions — Functions That Take Functions",
    emits_tags: [Concept("anonymous-functions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "If a function is a value, then you can also make functions that **take a function as an argument**. A function that takes or returns a function is called a **higher-order function**.\n\nA function type is written `fn(input_type) -> output_type`. For example, \"a function that takes an Int and returns an Int\" is `fn(Int) -> Int`.\n\n```gleam\nfn apply(f: fn(Int) -> Int, x: Int) -> Int {\n  f(x)\n}\n\napply(fn(n) { n * 2 }, 5)  // 10\n```\n\n`apply` takes a *function* as its first argument and a value as its second, then applies that function to the value.",
      ),
      predict(
        "apply-fn",
        "If you pass the doubling function and 5 to `apply` above, what is the value of `apply(fn(n) { n * 2 }, 5)`?",
        "fn apply(f: fn(Int) -> Int, x: Int) -> Int {\n  f(x)\n}\n\n// apply(fn(n) { n * 2 }, 5) 은?",
        ["`10`", "`5`", "`7`", "`25`"],
        0,
        "Exactly! `apply` applies the function it received, `fn(n) { n * 2 }`, to 5 — 5 * 2 = 10.",
        [
          #(
            1,
            "`apply` applies the function it was given — it doesn't leave 5 untouched, it doubles it.",
          ),
          #(2, "`n * 2` is multiplication, so 5 * 2 = 10 — not 5 + 2."),
          #(3, "`n * 2` is 5 * 2 = 10, not 5 * 5 = 25."),
        ],
      ),
      Prose(
        "list-map",
        "The real power of higher-order functions shows up with lists. `list.map(list, fn)` **applies a function to each element** of the list to build a new list — it's a tool that abstracts the manual recursion from U5.\n\n```gleam\nimport gleam/list\n\nlist.map([1, 2, 3], fn(x) { x * 2 })  // [2, 4, 6]\n```\n\nThe anonymous function `fn(x) { x * 2 }` is applied to each element, doubling it.",
      ),
      predict(
        "map-double",
        "What is the result of this `list.map`?",
        "list.map([1, 2, 3], fn(x) { x * 2 })",
        ["`[2, 4, 6]`", "`[1, 2, 3]`", "`6`", "`[1, 4, 9]`"],
        0,
        "Right! `x * 2` is applied to each element, giving [2, 4, 6].",
        [
          #(
            1,
            "The function is applied to each element — they get doubled, not left as the original.",
          ),
          #(
            2,
            "`map` doesn't combine; it transforms each element 1-to-1 and returns a *list* — not 6 but [2, 4, 6].",
          ),
          #(3, "`x * 2` is doubling (not squaring `x * x`) — so [2, 4, 6]."),
        ],
      ),
      predict(
        "filter-even",
        "`list.filter(list, predicate)` keeps only the elements for which the predicate is `True`. What is this result?",
        "list.filter([1, 2, 3, 4], fn(x) { x % 2 == 0 })",
        [
          "`[2, 4]`",
          "`[1, 3]`",
          "`[1, 2, 3, 4]`",
          "`[True, False, True, False]`",
        ],
        0,
        "Exactly! Only 2 and 4, for which `x % 2 == 0` (even) is true, remain.",
        [
          #(
            1,
            "It keeps the elements where the predicate is *true* — the evens (2, 4) stay and the odds are filtered out.",
          ),
          #(
            2,
            "`filter` selects only the ones that match the condition — it doesn't keep them all.",
          ),
          #(
            3,
            "`filter` returns the *elements themselves*, not a list of Bools — [2, 4].",
          ),
        ],
      ),
      mcq(
        "fn-type",
        "Which is the correct type notation for \"a function that takes an Int and returns a Bool\"?",
        [
          "`fn(Int) -> Bool`",
          "`fn(Bool) -> Int`",
          "`Int -> Bool`",
          "`fn Int Bool`",
        ],
        0,
        "Right! A function type is `fn(input) -> output` — input `Int`, output `Bool`.",
        [
          #(
            1,
            "The input and output are swapped — Int is the input, Bool is the output.",
          ),
          #(
            2,
            "A function type also needs `fn(...)` with parentheses — `Int -> Bool` alone won't do.",
          ),
          #(
            3,
            "`->` joins input and output, and the input is wrapped in parentheses — `fn(Int) -> Bool`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_captures() -> Lesson {
  Lesson(
    id: "u07-l03-captures",
    unit_id: "u07-functions-as-values",
    title: "Function Captures f(_, x)",
    emits_tags: [
      Concept("anonymous-functions"),
      Tricky("capture-vs-currying"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Like `list.map([1, 2, 3], fn(x) { add(10, x) })`, you often need \"a function with just one argument left blank.\" Gleam gives you a short **function capture** syntax for this: put a single `_` (underscore) where the call should be filled in.\n\n```gleam\nadd(10, _)\n// is shorthand for fn(b) { add(10, b) }\n```\n\nThere is exactly **one** blank `_`. `add(10, _)` becomes \"a new function with the first argument fixed at 10, taking only the second argument.\"",
      ),
      predict(
        "capture-map-add",
        "What is the result of passing a capture to `list.map`?",
        "list.map([1, 2, 3], add(10, _))\n// add(a, b) -> a + b",
        ["`[11, 12, 13]`", "`[10, 20, 30]`", "`[11, 22, 33]`", "`[1, 2, 3]`"],
        0,
        "Exactly! `add(10, _)` is \"a function that adds 10,\" so each element gains 10, giving [11, 12, 13].",
        [
          #(
            1,
            "It *adds* 10, not *multiplies* by 10 — 1+10, 2+10, 3+10 = [11, 12, 13].",
          ),
          #(
            2,
            "`_` just receives one element at a time — it doesn't multiply by 10, it adds 10.",
          ),
          #(
            3,
            "`add(10, _)` is applied to each element — they each gain 10, not left as the original.",
          ),
        ],
      ),
      Prose(
        "blank-position",
        "The **position** of the blank determines which argument is left empty. This is the heart of captures.\n\n`string.append(first, second)` appends `second` after `first`.\n- `string.append(_, \"!\")` appends `!` *after* each value (the value goes in the first slot).\n- `string.append(\"!\", _)` puts `!` *before* each value (the value goes in the second slot).\n\nThe \"pipes are for the first argument only\" limitation we saw in U2 is solved by captures — because you can place the blank in the second, third, etc. slot too.",
      ),
      predict(
        "capture-append-suffix",
        "What is the result of passing this capture to `list.map`?",
        "list.map([\"a\", \"b\"], string.append(_, \"!\"))",
        [
          "`[\"a!\", \"b!\"]`",
          "`[\"!a\", \"!b\"]`",
          "`[\"a\", \"b\"]`",
          "`[\"ab!\"]`",
        ],
        0,
        "Right! In `append(_, \"!\")` the blank is in the first slot, so `!` is appended *after* each element — [\"a!\", \"b!\"].",
        [
          #(
            1,
            "The blank's position matters. In `append(_, \"!\")` the value goes *first*, so `!` is appended after it — to put it before, use `append(\"!\", _)`.",
          ),
          #(
            2,
            "The captured function is applied to each element — they don't stay as the originals.",
          ),
          #(
            3,
            "`map` transforms each element 1-to-1 — it doesn't combine them into one.",
          ),
        ],
      ),
      Prose(
        "vs-currying",
        "If you know other languages, it's easy to confuse captures with \"currying.\" **Gleam has no automatic currying.** Unlike Haskell, writing just `add 10` will never partially apply.\n\nIn Gleam, partial application happens *only* when you explicitly place a blank `_`. You have to write the blank, `add(10, _)`, for it to become `fn(b) { add(10, b) }`. That's why the type of `add(10, _)` is `fn(Int) -> Int`, meaning \"one argument is still left blank.\"",
      ),
      mcq(
        "capture-type",
        "Given `add(a: Int, b: Int) -> Int`, what is the type of the capture `add(10, _)`?",
        [
          "`fn(Int) -> Int`",
          "`Int`",
          "`fn(Int, Int) -> Int`",
          "`fn() -> Int`",
        ],
        0,
        "Right! One blank remains, so it's a function that takes one more argument (Int) and returns an Int — `fn(Int) -> Int`.",
        [
          #(
            1,
            "A capture is a *function value* whose call isn't finished yet — it's a function, not a resulting Int.",
          ),
          #(
            2,
            "The first argument is already filled with 10 — only one blank remains, so it's `fn(Int) -> Int`.",
          ),
          #(
            3,
            "There's one blank `_`, so it takes one argument — not `fn() -> Int`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_labelled_args() -> Lesson {
  Lesson(
    id: "u07-l04-labelled-args",
    unit_id: "u07-functions-as-values",
    title: "labelled arguments",
    emits_tags: [Concept("labelled-arguments")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "When a function has several arguments, the call site can leave you wondering \"which slot was this value again?\" Gleam lets you attach **labels** to arguments so calls read like a sentence.\n\nWhen defining, put a label in front of the argument as `label name: type`:\n\n```gleam\npub fn replace(\n  in string: String,\n  each pattern: String,\n  with replacement: String,\n) -> String {\n  string.replace(string, pattern, replacement)\n}\n\nreplace(in: \"a,b,c\", each: \",\", with: \" \")  // \"a b c\"\n```\n\n`in`, `each`, and `with` are the labels, while `string`, `pattern`, and `replacement` are the internal names used in the body.",
      ),
      predict(
        "labelled-call",
        "What is the result of calling `replace` above with labels?",
        "replace(in: \"a,b,c\", each: \",\", with: \" \")",
        ["`\"a b c\"`", "`\"a,b,c\"`", "`\"abc\"`", "`\" \"`"],
        0,
        "Exactly! Every `,` in \"a,b,c\" is replaced with a space, giving \"a b c\".",
        [
          #(
            1,
            "replace is applied, so it doesn't stay unchanged — the `,` characters become spaces.",
          ),
          #(
            2,
            "The `,` is replaced with a *space*, not an empty string — spaces remain between the letters.",
          ),
          #(
            3,
            "The letters a, b, c stay; only the separators change — \"a b c\".",
          ),
        ],
      ),
      Prose(
        "order-free",
        "The real benefit of labels is that you become **free from order**. When you call with labels, you can list the arguments in any order and they're matched by name — you don't have to memorize the defined order.\n\n```gleam\nreplace(each: \",\", with: \" \", in: \"a,b,c\")\n// the same \"a b c\" as above\n```\n\nThat's because a labelled call matches by *name*, not *position*.",
      ),
      predict(
        "labelled-reorder",
        "Here the labels are reordered in the call. What is this result?",
        "replace(each: \",\", with: \" \", in: \"a,b,c\")",
        ["`\"a b c\"`", "`\",a,b,c \"`", "Compile error", "`\"a,b,c\"`"],
        0,
        "Right! Labels are matched by name, so reordering them gives the same result — \"a b c\".",
        [
          #(
            1,
            "Labels are paired by name, not position — `in` is still the target string and `each` is still what to find.",
          ),
          #(
            2,
            "A labelled call is legal even with a different order — it compiles and gives \"a b c\".",
          ),
          #(
            3,
            "replace is applied normally — the `,` becomes a space, giving \"a b c\".",
          ),
        ],
      ),
      Prose(
        "shorthand",
        "When a variable's name is the same as the label, you can use **label shorthand**. When the names overlap, like `greet(name: name, greeting: greeting)`, you can shorten it to `greet(name:, greeting:)` — leaving the part after the label blank means \"use the variable of the same name.\"",
      ),
      mcq(
        "shorthand-meaning",
        "Given variables called `name` and `greeting`, what is `greet(name:, greeting:)` equivalent to?",
        [
          "`greet(name: name, greeting: greeting)`",
          "`greet(name, greeting)`",
          "`greet()` — an empty call",
          "Compile error",
        ],
        0,
        "Right! Leaving the part after the label blank is the shorthand for putting the *variable of the same name* into that label.",
        [
          #(
            1,
            "The shorthand is still a *labelled* call — the labels `name:`/`greeting:` are still there.",
          ),
          #(
            2,
            "It doesn't leave the argument empty; it's a shorthand that fills in the variable of the same name.",
          ),
          #(
            3,
            "It's legal shorthand when a variable of the same name exists, so it compiles fine.",
          ),
        ],
      ),
    ],
  )
}

// ── Unit 8: list 모듈 — 재귀의 추상화 ─────────────────────────────
fn unit_list_module() -> Unit {
  let meta =
    UnitMeta(
      id: "u08-list-module",
      title: "The list Module — Abstracting Recursion",
      order: 8,
      level: 3,
      concepts: [Concept("lists")],
      prerequisites: ["u06-tail-recursion", "u07-functions-as-values"],
      lesson_ids: [
        "l08-list-map", "l08-list-filter", "l08-fold", "l08-fold-direction",
        "l08-tool-choice",
      ],
    )
  let lessons = [
    lesson_list_map(),
    lesson_list_filter(),
    lesson_fold(),
    lesson_fold_direction(),
    lesson_tool_choice(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u08-list-module", lessons),
  )
}

fn lesson_list_map() -> Lesson {
  Lesson(
    id: "l08-list-map",
    unit_id: "u08-list-module",
    title: "The Recursion You Wrote Has a Name — map",
    emits_tags: [Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Think back to the recursion you wrote by hand in U5~U6. That pattern — process the head of the list, then call yourself again on the tail — actually **already has a name**.\n\nRecursion that **transforms each element 1:1** to build a new list of the same length is exactly `list.map`.\n\n```gleam\nimport gleam/list\n\nlist.map([1, 2, 3], fn(x) { x * 2 })\n// == [2, 4, 6]\n```\n\n`list.map(list, transform_fn)` — the transform function takes one element and returns one new element. The number of elements stays the same.",
      ),
      predict(
        "map-double",
        "What does this `list.map` produce?",
        "list.map([1, 2, 3], fn(x) { x * 2 })",
        ["`[2, 4, 6]`", "`[1, 2, 3]`", "`12`", "`[1, 4, 9]`"],
        0,
        "Right! The transform function `x * 2` is applied 1:1 to each element, giving `[2, 4, 6]`.",
        [
          #(
            1,
            "The transform function is applied to every element — they're doubled, not left as-is.",
          ),
          #(
            2,
            "map doesn't combine the list. It returns a **list** of the same length — not a single value.",
          ),
          #(
            3,
            "`x * 2` doubles, it doesn't square. `[1, 4, 9]` is the result of `x * x`.",
          ),
        ],
      ),
      Prose(
        "shape-changes",
        "map can also **change the element type**. The return type of the transform function becomes the element type of the new list. Mapping `int.to_string` over a `List(Int)` gives a `List(String)` — same length, just a different shape.\n\n```gleam\nimport gleam/int\nimport gleam/list\n\nlist.map([1, 2, 3], int.to_string)\n// == [\"1\", \"2\", \"3\"]\n```\n\nNotice that you can pass the function values you learned about in U7 directly — `int.to_string` doesn't need to be wrapped in an anonymous function.",
      ),
      predict(
        "map-to-string",
        "What does this `list.map` produce?",
        "list.map([1, 2, 3], int.to_string)",
        ["`[\"1\", \"2\", \"3\"]`", "`[1, 2, 3]`", "`\"123\"`", "`[\"123\"]`"],
        0,
        "Exactly! Each `Int` is converted by `int.to_string`, giving the `List(String)` `[\"1\", \"2\", \"3\"]`.",
        [
          #(
            1,
            "The type changes — they become `String`, not `Int`. Look at whether the choices have quotes.",
          ),
          #(
            2,
            "map doesn't concatenate the elements — it returns a **list** with each element transformed separately.",
          ),
          #(
            3,
            "The elements aren't merged into one — three elements are each transformed, leaving three.",
          ),
        ],
      ),
      predict(
        "map-uppercase",
        "This `list.map` passes a function value directly. What's the result?",
        "list.map([\"a\", \"b\", \"c\"], string.uppercase)",
        [
          "`[\"A\", \"B\", \"C\"]`", "`[\"a\", \"b\", \"c\"]`", "`\"ABC\"`",
          "`[\"abc\"]`",
        ],
        0,
        "Right! `string.uppercase` is applied to each string, giving `[\"A\", \"B\", \"C\"]` — and we passed the function value directly, with no need to wrap it in an anonymous function.",
        [
          #(
            1,
            "The transformation is applied — they become uppercase, not left lowercase.",
          ),
          #(
            2,
            "map doesn't combine the elements. It returns a list of the same length.",
          ),
          #(
            3,
            "Three elements are each transformed, leaving three — they aren't merged into one.",
          ),
        ],
      ),
      mcq(
        "map-meaning",
        "Which single sentence best describes `list.map`?",
        [
          "It transforms each element 1:1 to build a new list of the **same length**",
          "It picks only the elements that match a condition to build a **shorter** list",
          "It folds the list into a **single value**",
          "It reverses the order of the list's elements",
        ],
        0,
        "Right! The essence of map is '1:1 transformation, length preserved.' Its role differs from filtering (filter) and folding (fold).",
        [
          #(
            1,
            "That's `filter`. map doesn't filter elements — it transforms them all, keeping the length the same.",
          ),
          #(
            2,
            "That's `fold`. The result of map is a **list**, not a single value.",
          ),
          #(3, "Reversing order is `list.reverse` — map preserves order."),
        ],
      ),
    ],
  )
}

fn lesson_list_filter() -> Lesson {
  Lesson(
    id: "l08-list-filter",
    unit_id: "u08-list-module",
    title: "filter — Picking Things Out",
    emits_tags: [Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "If map is \"transform every element,\" then `list.filter` is \"**keep only the elements that match a condition**.\"\n\nThe function you pass is a **predicate** that takes one element and returns a `Bool`. If it's `True`, the element is kept; if `False`, it's discarded. The elements themselves aren't changed, but **the count can shrink**.\n\n```gleam\nimport gleam/list\n\nlist.filter([1, 2, 3, 4, 5], fn(x) { x > 2 })\n// == [3, 4, 5]\n```",
      ),
      predict(
        "filter-gt2",
        "What does this `list.filter` produce? (only elements where the predicate is `True` are kept)",
        "list.filter([1, 2, 3, 4, 5], fn(x) { x > 2 })",
        ["`[3, 4, 5]`", "`[1, 2]`", "`[True, True, True]`", "`3`"],
        0,
        "Right! Only the elements where `x > 2` is true (3, 4, 5) are kept; the rest are discarded.",
        [
          #(
            1,
            "Elements where the predicate is `True` are **kept** — not the `False` ones. The elements where `x > 2` is true are 3, 4, 5.",
          ),
          #(
            2,
            "filter keeps the **original elements**, not the predicate's result (`Bool`) — `[3, 4, 5]`.",
          ),
          #(3, "filter returns the filtered **list**, not a single value."),
        ],
      ),
      Prose(
        "predicate",
        "The predicate must return a `Bool`. If you want to filter for even numbers, use a function that gives a `Bool`, like `int.is_even`, or write a comparison directly, like `fn(x) { x % 2 == 0 }`. (`%` is the remainder operator, so `x % 2 == 0` means even.)\n\n```gleam\nimport gleam/int\nimport gleam/list\n\nlist.filter([1, 2, 3, 4, 5], int.is_even)\n// == [2, 4]\n```",
      ),
      predict(
        "filter-even",
        "This `list.filter` passes a function value directly. What's the result?",
        "list.filter([1, 2, 3, 4, 5], int.is_even)",
        ["`[2, 4]`", "`[1, 3, 5]`", "`[2, 4, 6]`", "`2`"],
        0,
        "Exactly! The elements where `int.is_even` is `True` — the even numbers 2 and 4 — are kept.",
        [
          #(
            1,
            "It keeps the ones where `is_even` is true (the evens) — `[2, 4]`, not the odd numbers.",
          ),
          #(
            2,
            "A 6 that wasn't in the list can't appear. filter doesn't add elements.",
          ),
          #(
            3,
            "filter returns the filtered **list**, not a count (a single value).",
          ),
        ],
      ),
      predict(
        "filter-then-length",
        "What's the value of the filter result counted by length?",
        "[1, 2, 3, 4, 5, 6]\n|> list.filter(fn(x) { x % 2 == 0 })\n|> list.length",
        ["`3`", "`2`", "`6`", "`[2, 4, 6]`"],
        0,
        "Right! The even numbers are 2, 4, 6 — three of them, so `list.length` gives `3`.",
        [
          #(
            1,
            "The even numbers between 1 and 6 are 2, 4, 6 — three of them, not two.",
          ),
          #(
            2,
            "6 is the original length. filter keeps only the evens first, then the length is counted.",
          ),
          #(
            3,
            "The final `list.length` turns the list into a **count** — `3`, not a list.",
          ),
        ],
      ),
      mcq(
        "filter-vs-map",
        "What's the biggest difference between map and filter?",
        [
          "filter's result length can shrink, while map's length is always the same",
          "filter keeps the same length, while map's length can shrink",
          "Both always return a single value",
          "Both take a predicate (a function returning `Bool`)",
        ],
        0,
        "Right! filter discards elements, so its length can shrink (or stay the same), while map is a 1:1 transformation, so length is preserved.",
        [
          #(
            1,
            "You've got it backwards — the length that can change is filter's, and the one preserved is map's.",
          ),
          #(
            2,
            "Both return a **list**. Folding down to a single value is fold.",
          ),
          #(
            3,
            "Only filter takes a predicate (returning `Bool`). map's function can return any type.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_fold() -> Lesson {
  Lesson(
    id: "l08-fold",
    unit_id: "u08-list-module",
    title: "fold — The All-Purpose Fold",
    emits_tags: [Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "map and filter take a list and return a list. But what about when you want to **fold a list down to a single value**? Like a sum, a product, a count, or a concatenated string. That's `list.fold`.\n\n`list.fold(list, initial_value, fn(acc, item) { ... })` — starting from an **initial accumulator (acc)**, it merges each element into the accumulator one at a time. The `sum_loop` you wrote by hand in U6 is exactly a fold.\n\n```gleam\nimport gleam/list\n\nlist.fold([1, 2, 3, 4], 0, fn(acc, x) { acc + x })\n// == 10\n```\n\nImportant: the callback's **first argument is the accumulator (acc)**, and the second is the current element.",
      ),
      predict(
        "fold-sum",
        "What does this `list.fold` produce?",
        "list.fold([1, 2, 3, 4], 0, fn(acc, x) { acc + x })",
        ["`10`", "`0`", "`[1, 2, 3, 4]`", "`4`"],
        0,
        "Right! Starting from 0 and adding 1, 2, 3, 4 in turn gives `10`.",
        [
          #(
            1,
            "0 is the **initial accumulator**. The elements get added onto it from there.",
          ),
          #(
            2,
            "fold **folds** the list down to a single value — `10`, not a list.",
          ),
          #(
            3,
            "4 is just the last element (or the count); the result is the sum, `10`.",
          ),
        ],
      ),
      Prose(
        "any-shape",
        "fold's initial value and accumulator type **can differ from the element type**. That's why fold is \"all-purpose\" — products (initial value 1), counts (initial value 0, `acc + 1` in the callback), and string concatenation (initial value `\"\"`) can all be expressed with fold.\n\n```gleam\nimport gleam/list\n\n// product: initial value 1\nlist.fold([1, 2, 3, 4], 1, fn(acc, x) { acc * x })\n// == 24\n```",
      ),
      predict(
        "fold-product",
        "This `list.fold` computes a product. What's the result?",
        "list.fold([1, 2, 3, 4], 1, fn(acc, x) { acc * x })",
        ["`24`", "`10`", "`1`", "`0`"],
        0,
        "Exactly! Starting from the initial value 1, it accumulates 1*1*2*3*4 = 24.",
        [
          #(
            1,
            "10 is the result of an **addition** fold. Here we multiply with `acc * x`.",
          ),
          #(
            2,
            "1 is the initial accumulator — multiplying the elements onto it gives 24.",
          ),
          #(
            3,
            "Using 0 as the initial value for multiplication would make everything 0, but here we start from 1 — the result is 24.",
          ),
        ],
      ),
      predict(
        "fold-count",
        "This fold counts the elements. The callback ignores the element value and just does `acc + 1`. What's the result?",
        "list.fold([10, 20, 30], 0, fn(acc, _x) { acc + 1 })",
        ["`3`", "`60`", "`30`", "`0`"],
        0,
        "Right! It ignores the element value and adds 1 each time, so it gives the element count, `3`.",
        [
          #(
            1,
            "60 is the **sum** of the elements. This callback doesn't add the values — it only does `acc + 1`.",
          ),
          #(
            2,
            "30 is the last element. The callback doesn't use the element value — it just counts.",
          ),
          #(3, "0 is the initial value — adding 1 per element gives 3."),
        ],
      ),
      mcq(
        "fold-callback-shape",
        "In `list.fold(xs, init, f)`, what's the correct argument order for the callback `f`?",
        [
          "`fn(acc, item)` — accumulator first",
          "`fn(item, acc)` — element first",
          "`fn(acc)` — one argument",
          "`fn(item)` — one argument",
        ],
        0,
        "Right! Gleam stdlib's fold callback is `fn(acc, item)` — the accumulator is first. In the next lesson we'll see why this order becomes a trap.",
        [
          #(
            1,
            "The order is reversed. Gleam takes the accumulator as the **first** argument — this may differ from other languages.",
          ),
          #(
            2,
            "The callback must take **both** the accumulator and the element — that's two arguments.",
          ),
          #(
            3,
            "Taking only the element means you can't carry the accumulation forward — you take the accumulator too.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_fold_direction() -> Lesson {
  Lesson(
    id: "l08-fold-direction",
    unit_id: "u08-list-module",
    title: "Fold Direction and the Accumulator",
    emits_tags: [Concept("lists"), Tricky("fold-arg-order")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`list.fold` folds **from the left**. And its callback is `fn(acc, item)` — **accumulator first**. When these two facts combine, you get the spot where beginners slip up most often.\n\nWhat happens if you fold by **prepending** each element to the accumulator?\n\n```gleam\nimport gleam/list\n\nlist.fold([1, 2, 3], [], fn(acc, x) { [x, ..acc] })\n// 1 in front of [] -> [1], 2 in front -> [2, 1], 3 in front -> [3, 2, 1]\n```",
      ),
      predict(
        "fold-prepend",
        "This fold prepends each element to the accumulator. What's the result?",
        "list.fold([1, 2, 3], [], fn(acc, x) { [x, ..acc] })",
        ["`[3, 2, 1]`", "`[1, 2, 3]`", "`[3]`", "`6`"],
        0,
        "Right! From the left: 1 is laid down first, then 2 and 3 pile up in front of it, flipping it to `[3, 2, 1]` — the same phenomenon as the accumulate pattern from U6.",
        [
          #(
            1,
            "fold goes from the left, so 1 ends up buried deepest. To preserve order you'd need `list.fold_right` or `list.reverse` after the fold.",
          ),
          #(
            2,
            "Not just one element remains — all three pile up in the accumulator.",
          ),
          #(
            3,
            "This callback doesn't add; it prepends to a list — the result is the list `[3, 2, 1]`, not the sum 6.",
          ),
        ],
      ),
      Prose(
        "fold-right",
        "If you want to preserve order, use `list.fold_right`, which folds **from the right**. The callback shape is the same, `fn(acc, item)`, but it merges elements into the accumulator **starting from the back**.\n\n```gleam\nimport gleam/list\n\nlist.fold_right([1, 2, 3], [], fn(acc, x) { [x, ..acc] })\n// 3 in front of [] -> [3], 2 in front -> [2, 3], 1 in front -> [1, 2, 3]\n```\n\nIn other words, you stack with prepend but process from the back, so the original order is restored exactly.",
      ),
      predict(
        "fold-right-prepend",
        "What happens if you use the same prepend callback with `list.fold_right`? ",
        "list.fold_right([1, 2, 3], [], fn(acc, x) { [x, ..acc] })",
        ["`[1, 2, 3]`", "`[3, 2, 1]`", "`[3]`", "`6`"],
        0,
        "Exactly! Folding from the right, 3 is laid down first and 2, 1 are added in front of it, restoring the original order `[1, 2, 3]`.",
        [
          #(
            1,
            "That's the result of `list.fold`, which folds from the left. `fold_right` preserves order.",
          ),
          #(2, "Not just one element remains — all three pile up."),
          #(
            3,
            "This callback doesn't add; it prepends — the result is the list `[1, 2, 3]`.",
          ),
        ],
      ),
      Prose(
        "arg-order-trap",
        "A subtler trap: writing the callback's argument order **backwards**. Gleam's fold callback is `fn(acc, item)`, but if you're used to other languages (e.g. Haskell's `foldr`) you might absent-mindedly write `fn(item, acc)`.\n\nLet's look at a fold that concatenates strings onto the accumulator — `acc <> x` means \"the current element after what we've collected so far.\" Folding from the left preserves the order exactly.\n\n```gleam\nimport gleam/list\n\nlist.fold([\"1\", \"2\", \"3\"], \"\", fn(acc, x) { acc <> x })\n// == \"123\"\n```",
      ),
      predict(
        "fold-string-concat",
        "This fold concatenates strings. The callback is `acc <> x` (the element after the accumulator). What's the result?",
        "list.fold([\"1\", \"2\", \"3\"], \"\", fn(acc, x) { acc <> x })",
        ["`\"123\"`", "`\"321\"`", "`\"\"`", "`6`"],
        0,
        "Right! From the left it concatenates in the order `\"\" <> \"1\" <> \"2\" <> \"3\"`, giving `\"123\"` — with `acc` first and the element after, order is preserved.",
        [
          #(
            1,
            "`\"321\"` is what you'd get if you wrote the callback backwards as `x <> acc`. Here it's `acc <> x`, so order is preserved.",
          ),
          #(
            2,
            "`\"\"` is just the initial value; the elements get concatenated on in turn.",
          ),
          #(
            3,
            "This callback doesn't add; it concatenates strings with `<>` — the result is `\"123\"`, not a number.",
          ),
        ],
      ),
      mcq(
        "fold-arg-order-mcq",
        "To make `\"321\"` with `list.fold([\"1\", \"2\", \"3\"], \"\", f)`, how should you write the callback `f`?",
        [
          "`fn(acc, x) { x <> acc }` — prepend the element in front of the accumulator",
          "`fn(acc, x) { acc <> x }` — the element after the accumulator",
          "`fn(acc, x) { acc <> \"-\" <> x }` — insert a - between them",
          "Using `list.fold_right` reverses it automatically",
        ],
        0,
        "Right! Keep the callback argument order as `fn(acc, x)` and, in the body, put the element in front with `x <> acc`, and a left fold produces `\"321\"`.",
        [
          #(
            1,
            "`acc <> x` preserves order and produces `\"123\"` — to reverse it you have to change the body to `x <> acc`.",
          ),
          #(
            2,
            "This puts a - between elements, producing `\"-1-2-3\"` — not `\"321\"`.",
          ),
          #(
            3,
            "Using `acc <> x` with `fold_right` does give `\"321\"`, but not \"automatically\" — it's because the direction changed, and you can also make it with the same `list.fold` by just changing the body.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_tool_choice() -> Lesson {
  Lesson(
    id: "l08-tool-choice",
    unit_id: "u08-list-module",
    title: "Choosing the Tool — map, filter, or fold",
    emits_tags: [Concept("lists"), Tricky("tool-choice")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Now let's put all three side by side and sort out **when to use which**. There's just one deciding factor: **the shape of the result**.\n\n- Each element is **transformed 1:1** and the length stays the same -> `list.map`\n- You **pick by a condition** and the length can shrink -> `list.filter`\n- The list is **folded into a single value (or another shape)** -> `list.fold`\n\nChaining all three with pipes makes a little data pipeline.\n\n```gleam\nimport gleam/list\n\npub fn process(xs: List(Int)) -> Int {\n  xs\n  |> list.filter(fn(x) { x % 2 == 0 })\n  |> list.map(fn(x) { x * x })\n  |> list.fold(0, fn(acc, x) { acc + x })\n}\n// process([1, 2, 3, 4]) == 20\n```",
      ),
      predict(
        "pipeline-process",
        "In the `process` pipeline above, what's the value of `process([1, 2, 3, 4])`? (evens only -> square -> sum)",
        "xs\n|> list.filter(fn(x) { x % 2 == 0 })  // [2, 4]\n|> list.map(fn(x) { x * x })           // [4, 16]\n|> list.fold(0, fn(acc, x) { acc + x }) // 20",
        ["`20`", "`30`", "`[4, 16]`", "`6`"],
        0,
        "Right! Evens [2, 4] -> squares [4, 16] -> sum 20. filter, map, and fold change the shape one after another.",
        [
          #(
            1,
            "30 is the sum of squaring all of 1~4 (1+4+9+16). You have to filter for **evens only** first.",
          ),
          #(
            2,
            "The final fold folds the list down to a single value — `[4, 16]` is the state just before the fold.",
          ),
          #(
            3,
            "6 is the sum of the evens (2+4) from the original [1,2,3,4]. There's a **squaring** step in between.",
          ),
        ],
      ),
      Prose(
        "by-return-type",
        "When you're stuck, think of the **result type** first. If the result is a `List`, it's map or filter; if the result is a single value (`Int`, `String`, `Bool`), it should end with a fold. \"Count them,\" \"find the maximum,\" \"compute the sum\" are all about folding a list into **a single value** — fold (or a specialized form of it).",
      ),
      mcq(
        "choose-count-evens",
        "Which approach best fits \"count the **number** of even values in a list\"?",
        [
          "Keep only the evens with `filter`, then count with `length` (or accumulate with fold)",
          "It can be done with `map` alone",
          "`filter` alone gives the count",
          "Concatenate with `<>`, no tools needed",
        ],
        0,
        "Right! Since the result is a single `Int`, you must fold at the end — filter for evens then count with length, or count directly with fold.",
        [
          #(
            1,
            "map preserves length and returns a **list**. To get a single count value, you need a folding step.",
          ),
          #(
            2,
            "filter gives a filtered **list** — to get the count (`Int`), you need one more step with length or fold.",
          ),
          #(
            3,
            "`<>` is string concatenation — it has nothing to do with counting.",
          ),
        ],
      ),
      predict(
        "choose-uppercase",
        "This is the result made with the right tool for \"uppercase each word.\" What's the value?",
        "list.map([\"hi\", \"bye\"], string.uppercase)",
        ["`[\"HI\", \"BYE\"]`", "`\"HIBYE\"`", "`[\"hi\", \"bye\"]`", "`2`"],
        0,
        "Right! It transforms each element 1:1 and preserves the length, so map is the answer — the result is `[\"HI\", \"BYE\"]`.",
        [
          #(
            1,
            "map doesn't combine the elements — it returns a **list** with each transformed. To combine them you'd need fold.",
          ),
          #(
            2,
            "The transformation is applied — they become uppercase, not left lowercase.",
          ),
          #(
            3,
            "A count (a single value) is the result of fold/length. \"Uppercasing\" is a 1:1 transformation, so map gives a **list**.",
          ),
        ],
      ),
      predict(
        "choose-max",
        "Here's \"find the **maximum** of a list\" implemented with fold. What's the result?",
        "list.fold([3, 7, 2, 9, 4], 0, fn(acc, x) { int.max(acc, x) })",
        ["`9`", "`[3, 7, 2, 9, 4]`", "`25`", "`3`"],
        0,
        "Right! Finding the maximum is folding a list into a single value, so fold fits — it keeps leaving the larger value in the accumulator, giving `9`.",
        [
          #(
            1,
            "fold folds the list into a single value — the maximum `9`, not a list.",
          ),
          #(
            2,
            "25 is the sum of all the elements (3+7+2+9+4). But the callback is `int.max`, so it doesn't add — it keeps only the larger side, giving the maximum `9`.",
          ),
          #(
            3,
            "3 is the first element. fold scans all the elements and leaves the largest, 9.",
          ),
        ],
      ),
    ],
  )
}

fn unit_option_result() -> Unit {
  let meta =
    UnitMeta(
      id: "u09-option-result",
      title: "Option and Result",
      order: 9,
      level: 3,
      concepts: [
        Concept("options"),
        Concept("results"),
        Concept("custom-error-types"),
      ],
      prerequisites: ["u04-custom-types"],
      lesson_ids: [
        "l01-option", "l02-result", "l03-custom-error", "l04-option-vs-result",
        "l05-stdlib-results",
      ],
    )
  let lessons = [
    lesson_option(),
    lesson_result(),
    lesson_custom_error(),
    lesson_option_vs_result(),
    lesson_stdlib_results(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u09-option-result", lessons),
  )
}

fn lesson_option() -> Lesson {
  Lesson(
    id: "l01-option",
    unit_id: "u09-option-result",
    title: "Values That Might Not Exist — Option",
    emits_tags: [Concept("options")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "In other languages `null` sneaks \"no value here\" in everywhere, and eventually blows up as an NPE (null reference error). Gleam has **no** `null`. Instead it uses **`Option(a)`**, which records \"might be there, might not\" right in the type.\n\n`Option(a)` is a custom type with just two shapes (the very same variants you saw in U4):\n\n- `Some(value)` — a value **is** present\n- `None` — there is **no** value\n\nYou bring it in with `import gleam/option.{type Option, None, Some}`.",
      ),
      predict(
        "some-shape",
        "`find_nickname(\"lucy\")` looks up a nickname and returns it. What shape does that value have?",
        "import gleam/option.{type Option, Some}\n\nfn find_nickname(name: String) -> Option(String) {\n  case name {\n    \"lucy\" -> Some(\"Lucy\")\n    _ -> Some(\"?\")\n  }\n}\n\n// find_nickname(\"lucy\") is?",
        ["`Some(\"Lucy\")`", "`\"Lucy\"`", "`None`", "`Ok(\"Lucy\")`"],
        0,
        "Right! In an `Option` a value never comes out bare — it's wrapped in `Some(...)`: `Some(\"Lucy\")`.",
        [
          #(
            1,
            "The value is indeed \"Lucy\", but it's an `Option` type, so it comes out wrapped in `Some`. You need pattern matching to take it out.",
          ),
          #(
            2,
            "`None` is the shape when there's *no* nickname. Here the \"lucy\" branch found a value.",
          ),
          #(
            3,
            "`Ok` is a constructor of `Result`. `Option` uses `Some`/`None`.",
          ),
        ],
      ),
      predict(
        "none-shape",
        "The same function is changed so that when no nickname is found (the `_` branch) it returns `None`. What is the value of `find_nickname(\"bob\")`?",
        "import gleam/option.{type Option, None, Some}\n\nfn find_nickname(name: String) -> Option(String) {\n  case name {\n    \"lucy\" -> Some(\"Lucy\")\n    _ -> None\n  }\n}\n\n// find_nickname(\"bob\") is?",
        ["`None`", "`Some(\"bob\")`", "`\"\"`", "`Nil`"],
        0,
        "Exactly! \"bob\" falls into the `_` branch and gives `None` — an explicit way of saying \"no value\".",
        [
          #(
            1,
            "There's no nickname for `bob`, so the `_` branch is chosen — `None`, not `Some`.",
          ),
          #(
            2,
            "An empty string `\"\"` is still a value that *is* present. \"Absence\" is expressed with `None`.",
          ),
          #(
            3,
            "`Nil` is a different type (the empty value). The \"absence\" in `Option` is `None`.",
          ),
        ],
      ),
      Prose(
        "pattern-match",
        "Whether it's `Some` or `None`, you pull the value out by **branching with `case`**. In the `Some(x)` branch the inner value is bound to the name `x`. `Option` also has just two variants, so the same U4 exhaustiveness applies — your code only compiles if you handle **both** `Some` and `None`.\n\n```gleam\ncase nickname {\n  Some(nick) -> \"Hi, \" <> nick <> \"!\"\n  None -> \"Hi, guest!\"\n}\n```",
      ),
      predict(
        "case-none",
        "For a `greet` function built with the pattern above, what is the value of `greet(None)`?",
        "import gleam/option.{type Option, None, Some}\n\nfn greet(nickname: Option(String)) -> String {\n  case nickname {\n    Some(nick) -> \"Hi, \" <> nick <> \"!\"\n    None -> \"Hi, guest!\"\n  }\n}\n\n// greet(None) is?",
        ["`\"Hi, guest!\"`", "`\"Hi, !\"`", "`None`", "compile error"],
        0,
        "Right! The input is `None`, so the `None` branch is chosen and the result is \"Hi, guest!\".",
        [
          #(
            1,
            "`None` has no inner value — it doesn't go to the `Some(nick)` branch, so no result that uses `nick` is produced.",
          ),
          #(
            2,
            "`case` returns the *result* of the matched branch, not the input — \"Hi, guest!\", not `None`.",
          ),
          #(
            3,
            "Both `Some` and `None` are handled, so everything is covered and it compiles fine.",
          ),
        ],
      ),
      Prose(
        "unwrap",
        "Writing a `case` every time you want \"the value if it's there, a default otherwise\" gets tedious. `option.unwrap(opt, default)` does that pattern in one line: if it's `Some(x)` it returns `x`, and if it's `None` it returns the default.",
      ),
      predict(
        "unwrap-none",
        "What is the result of `option.unwrap`?",
        "import gleam/option.{None}\n\noption.unwrap(None, \"anonymous\")",
        ["`\"anonymous\"`", "`None`", "`Some(\"anonymous\")`", "`\"\"`"],
        0,
        "Exactly! It's `None`, so the default \"anonymous\" comes straight out — `unwrap` strips off the wrapper and gives you the bare value.",
        [
          #(
            1,
            "`unwrap` returns the bare value with the `Option` wrapper removed — the default \"anonymous\", not `None`.",
          ),
          #(
            2,
            "The result of `unwrap` is no longer an `Option` — it isn't wrapped back up in `Some`.",
          ),
          #(
            3,
            "You gave \"anonymous\" as the default, so you get \"anonymous\", not an empty string.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_result() -> Lesson {
  Lesson(
    id: "l02-result",
    unit_id: "u09-option-result",
    title: "Operations That Can Fail — Result",
    emits_tags: [Concept("results"), Tricky("exhaustiveness")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam has **no** exceptions. There's no catching an error that flies in from somewhere with `try/catch`. Instead, you write the possibility of failure **into the return type**: `Result(success_type, failure_type)`.\n\n`Result(a, e)` is also a custom type with just two shapes:\n\n- `Ok(value)` — **success**, with the success value inside\n- `Error(reason)` — **failure**, with the reason for failure inside\n\nThe caller only compiles if they handle **both cases** with `case` (U4 exhaustiveness returns). The option of \"forgetting to handle the error\" simply doesn't exist in the type system.",
      ),
      predict(
        "result-ok",
        "`safe_div` guards against division by zero. What is the value of `safe_div(20, 4)`?",
        "fn safe_div(a: Int, b: Int) -> Result(Int, Nil) {\n  case b {\n    0 -> Error(Nil)\n    _ -> Ok(a / b)\n  }\n}\n\n// safe_div(20, 4) is?",
        ["`Ok(5)`", "`5`", "`Error(Nil)`", "`Ok(20)`"],
        0,
        "Right! The division succeeds, so the quotient 5 is wrapped in `Ok` — `Ok(5)`. Success values don't come out bare either.",
        [
          #(
            1,
            "The value is indeed 5, but it's a `Result` type so it's wrapped as `Ok(5)` — you need pattern matching to take it out.",
          ),
          #(
            2,
            "`Error(Nil)` is when `b` is 0. Here we divide by 4 and succeed.",
          ),
          #(
            3,
            "The result is the quotient `20 / 4 = 5` — `Ok(5)`, not `Ok(20)`.",
          ),
        ],
      ),
      predict(
        "result-error",
        "For the same function, what is the value of `safe_div(20, 0)`?",
        "fn safe_div(a: Int, b: Int) -> Result(Int, Nil) {\n  case b {\n    0 -> Error(Nil)\n    _ -> Ok(a / b)\n  }\n}\n\n// safe_div(20, 0) is?",
        ["`Error(Nil)`", "`Ok(0)`", "the program crashes", "`0`"],
        0,
        "Exactly! `b` is 0, so the `Error(Nil)` branch is chosen — failure is expressed as a *value*, so it doesn't crash.",
        [
          #(
            1,
            "Dividing by zero isn't success — it's blocked with `Error(Nil)`, not `Ok`.",
          ),
          #(
            2,
            "There are no exceptions, so it doesn't crash. The failure comes back safely as an `Error` value.",
          ),
          #(
            3,
            "Failure is expressed as `Error(Nil)`, not a bare `0` — so the caller can tell them apart with `case`.",
          ),
        ],
      ),
      Prose(
        "handle-both",
        "To use the value in a `Result`, you have to unpack **both** `Ok` and `Error` with `case`.\n\n```gleam\ncase result {\n  Ok(n) -> \"The value is \" <> int.to_string(n)\n  Error(Nil) -> \"No value\"\n}\n```\n\nIf you only write the `Ok(n)` branch and leave out `Error`, you get the **exact same** \"Inexhaustive patterns\" compile error you saw in U4. Not handling the error isn't an option — it's a compile failure.",
      ),
      predict(
        "result-case-ok",
        "For a `describe` function built with the pattern above, what is the value of `describe(Ok(20))`?",
        "import gleam/int\n\nfn describe(r: Result(Int, Nil)) -> String {\n  case r {\n    Ok(n) -> \"The value is \" <> int.to_string(n)\n    Error(Nil) -> \"No value\"\n  }\n}\n\n// describe(Ok(20)) is?",
        ["`\"The value is 20\"`", "`\"No value\"`", "`Ok(20)`", "`20`"],
        0,
        "Right! `Ok(20)` matches the `Ok(n)` branch, `n` is bound to 20, and \"The value is 20\" is produced.",
        [
          #(
            1,
            "\"No value\" is the result of the `Error` branch — the input is `Ok(20)`, so it goes to the success branch.",
          ),
          #(
            2,
            "`case` returns the branch's *result string*, not the input as-is — \"The value is 20\", not `Ok(20)`.",
          ),
          #(
            3,
            "The result is \"The value is 20\", with `n` (= 20) pulled from the `Ok(n)` branch and spliced into the string.",
          ),
        ],
      ),
      mcq(
        "inexhaustive",
        "In a `case` over `Result(Int, Nil)`, you only wrote the `Ok(n) -> ...` branch and didn't write `Error`. What happens?",
        [
          "It crashes at runtime, but only once an `Error` actually arrives",
          "A compile error — the `Error` case is missing: \"Inexhaustive patterns\"",
          "`Error` is automatically ignored",
          "When it's `Error` it returns `Nil` on its own",
        ],
        1,
        "Right! You must handle both `Ok` and `Error` for it to compile. The option of \"not handling\" the error doesn't exist in the type system — that's both the price and the payoff of using `Result` instead of exceptions.",
        [
          #(
            0,
            "It never reaches runtime — the missing case is caught at *compile time*, blocking it from even running.",
          ),
          #(
            2,
            "Gleam doesn't silently ignore a missing branch — it tells you clearly with a compile error.",
          ),
          #(
            3,
            "There's no automatic default. You have to spell out every case yourself.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_custom_error() -> Lesson {
  Lesson(
    id: "l03-custom-error",
    unit_id: "u09-option-result",
    title: "Your Own Error Types",
    emits_tags: [Concept("custom-error-types"), Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "The `Nil` in `Result(Int, Nil)` only says \"it failed\" — it can't carry *why* it failed. If there are several reasons for failure, you turn those reasons into **your own custom type** and put it in the `Error` slot (the same variants from U4).\n\n```gleam\npub type AgeError {\n  NotANumber\n  Negative\n}\n```\n\nNow `Result(Int, AgeError)` tells you, just from the type, \"on success an `Int`, on failure *one of these two reasons*\".",
      ),
      Prose(
        "parse-age",
        "`int.parse(input)` tries to convert a string to an integer and returns `Result(Int, Nil)` (if it isn't a number, `Error(Nil)`). Let's take that and map it into our own error type, building a `parse_age` that also filters out negatives:\n\n```gleam\nimport gleam/int\n\npub fn parse_age(input: String) -> Result(Int, AgeError) {\n  case int.parse(input) {\n    Error(Nil) -> Error(NotANumber)\n    Ok(n) ->\n      case n < 0 {\n        True -> Error(Negative)\n        False -> Ok(n)\n      }\n  }\n}\n```\n\nThe outer `case` handles parse success/failure, and the inner `case` checks whether it's negative.",
      ),
      predict(
        "parse-neg",
        "For the `parse_age` above, what is the value of `parse_age(\"-3\")`?",
        "// parse_age(\"-3\") is?\n// (int.parse(\"-3\") == Ok(-3), and -3 < 0)",
        ["`Error(Negative)`", "`-3`", "`Error(NotANumber)`", "`Ok(-3)`"],
        0,
        "Right! \"-3\" parses as a number, giving `Ok(-3)`, but in the inner `case` `-3 < 0` is true, so it's filtered out as `Error(Negative)`.",
        [
          #(
            1,
            "In a `Result`, a value never comes out bare — failure is wrapped in `Error(...)`. And besides, it's negative, so it isn't a success either.",
          ),
          #(
            2,
            "`NotANumber` is for when *parsing itself* fails. \"-3\" parses fine as a number, but it's blocked for being negative.",
          ),
          #(
            3,
            "\"-3\" does parse, but it's negative so it isn't `Ok` — it's filtered out as `Error(Negative)`.",
          ),
        ],
      ),
      predict(
        "parse-abc",
        "For the same function, what is the value of `parse_age(\"abc\")`?",
        "// parse_age(\"abc\") is?\n// (int.parse(\"abc\") == Error(Nil))",
        ["`Error(NotANumber)`", "`Error(Negative)`", "`Error(Nil)`", "`Ok(0)`"],
        0,
        "Exactly! \"abc\" doesn't parse as an integer, so `int.parse` gives `Error(Nil)`, and the outer `case` maps that to `Error(NotANumber)`.",
        [
          #(
            1,
            "`Negative` is for when it *parsed but is negative*. \"abc\" doesn't parse as a number to begin with.",
          ),
          #(
            2,
            "Our function turns `int.parse`'s raw `Error(Nil)` into a meaningful `Error(NotANumber)` and returns that.",
          ),
          #(
            3,
            "A parse failure isn't the success value 0 — it's `Error(NotANumber)`, not `Ok`.",
          ),
        ],
      ),
      predict(
        "parse-8",
        "For the same function, what is the value of `parse_age(\"8\")`?",
        "// parse_age(\"8\") is?\n// (int.parse(\"8\") == Ok(8), and 8 >= 0)",
        ["`Ok(8)`", "`8`", "`Error(NotANumber)`", "`Some(8)`"],
        0,
        "Right! \"8\" parses as a number and isn't negative, so it's `Ok(8)` — success values come out wrapped in `Ok` too.",
        [
          #(
            1,
            "The value is indeed 8, but it's a `Result` so it's wrapped as `Ok(8)` — you need pattern matching to take it out.",
          ),
          #(
            2,
            "\"8\" is a perfectly good number, so parsing succeeds — `Ok(8)`, not `NotANumber`.",
          ),
          #(
            3,
            "`Some` is a constructor of `Option`. A `Result`'s success is wrapped in `Ok`.",
          ),
        ],
      ),
      Prose(
        "use-error-type",
        "The real benefit of a custom error type shows up **on the caller's side**. When you unpack with `case`, you can give a different message for each reason for failure, and if you leave a reason out, the compiler catches it.\n\n```gleam\npub fn age_message(input: String) -> String {\n  case parse_age(input) {\n    Ok(n) -> \"Age: \" <> int.to_string(n)\n    Error(NotANumber) -> \"That's not a number\"\n    Error(Negative) -> \"Negatives aren't allowed\"\n  }\n}\n```",
      ),
      mcq(
        "message-negative",
        "With the `age_message` code above, what string comes out if you call `age_message(\"-3\")`?",
        [
          "`\"Negatives aren't allowed\"`",
          "`\"That's not a number\"`",
          "`\"Age: -3\"`",
          "`\"Age: 0\"`",
        ],
        0,
        "Right! `parse_age(\"-3\")` is `Error(Negative)`, so the `Error(Negative)` branch's \"Negatives aren't allowed\" is chosen — being able to give a different message per reason is the power of custom errors.",
        [
          #(
            1,
            "\"That's not a number\" is the `Error(NotANumber)` branch. \"-3\" does parse as a number but is negative, so it goes to `Negative`.",
          ),
          #(
            2,
            "A negative doesn't go to the `Ok` branch — \"Age: -3\" doesn't appear; an error message does.",
          ),
          #(
            3,
            "The value isn't corrected to 0 — a negative is rejected as-is with `Error(Negative)`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_option_vs_result() -> Lesson {
  Lesson(
    id: "l04-option-vs-result",
    unit_id: "u09-option-result",
    title: "How to Choose Between Option and Result",
    emits_tags: [
      Tricky("option-vs-result"),
      Concept("options"),
      Concept("results"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`Option` and `Result` both deal with \"a value might not be there\", but they're used differently. A one-line rule:\n\n- **If \"absence is a normal state\", use `Option`** — where the absence itself is data. Example: an optional field on a record (someone might not have a nickname).\n- **If it's a \"failure with a reason\", use `Result`** — when something went wrong and you have something to say about *why*.\n\nThe key question: \"Is this absence *normal*, or is it a *failure*?\"",
      ),
      mcq(
        "optional-field",
        "On a user profile, `nickname` is an optional field that \"someone may not have set\". Having no nickname isn't an error — it's a common, normal state. What is the most fitting type for this field?",
        [
          "`Option(String)` — because absence is normal data",
          "`Result(String, Nil)` — because a nickname can fail",
          "`String` — empty string when absent",
          "`Result(String, String)` — to carry a reason",
        ],
        0,
        "Right! Having no nickname is *normal absence*, not a *failure* — so `Option(String)` fits perfectly. `None` naturally expresses \"nickname not set\".",
        [
          #(
            1,
            "Having no nickname isn't a failure, it's normal — there's no \"failure reason\" to convey, so `Result` is overkill.",
          ),
          #(
            2,
            "An empty string can't distinguish \"present but empty\" from \"not there at all\" — `Option` clearly separates those two.",
          ),
          #(
            3,
            "Putting an error type there when there's no failure reason to carry is just clutter — for normal absence, use `Option`.",
          ),
        ],
      ),
      Prose(
        "result-default",
        "But if you look at Gleam's stdlib, even when there's *only one* reason for failure it often uses **`Result(a, Nil)`** rather than `Option` — `int.parse` and `list.first` do exactly this. Idiomatically, **`Result` is the default**, and `Option` is saved for the special spots where \"absence is the data\". A \"parse failure\" or \"the first element of an empty list\" is less *normal absence* than *a failure of that operation*.",
      ),
      mcq(
        "stdlib-idiom",
        "What is the best reason that `int.parse(\"abc\")` returns `Error(Nil)` as `Result(Int, Nil)` rather than as an `Option`?",
        [
          "\"abc as an integer\" isn't normal absence but a *failure* of the operation — and for these cases stdlib defaults to Result",
          "Because Gleam doesn't have Option",
          "Because Result is always faster than Option",
          "Because it's a special rule just for `int.parse`; other functions use Option",
        ],
        0,
        "Right! Failing to parse signals not \"absence is normal\" but \"this operation failed\" — so idiomatically it uses `Result` (`list.first` is the same).",
        [
          #(
            1,
            "Gleam clearly does have `Option` (`gleam/option`). It's just that for *failure*, `Result` is idiomatic.",
          ),
          #(
            2,
            "It's not about speed but about *meaning* — the distinction between absence (data) and failure.",
          ),
          #(
            3,
            "`list.first` uses `Result` for the same reason — it isn't an exception unique to `int.parse`.",
          ),
        ],
      ),
      mcq(
        "spot-awkward",
        "Among the following four function signatures, which one has an **awkward** type choice?",
        [
          "`fn divide(a: Int, b: Int) -> Option(Int)`",
          "`fn find_user(id: Int) -> Result(User, Nil)`",
          "`fn middle_name(p: Person) -> Option(String)`",
          "`fn parse_age(s: String) -> Result(Int, AgeError)`",
        ],
        0,
        "Right! Dividing by zero isn't *normal absence* but a *failure* of the operation — `Result(Int, ...)` is more appropriate than `Option`. The rule: \"if absence is normal, Option; if it's a failure, Result.\"",
        [
          #(
            1,
            "`Result` is natural for a failed user lookup — per stdlib idiom, if there's one reason, `Result(_, Nil)` is fine too.",
          ),
          #(
            2,
            "A middle name is an optional field where \"absence is normal\", so `Option` fits perfectly — not awkward.",
          ),
          #(
            3,
            "Age parsing has a reason on failure (`AgeError`), so `Result(Int, AgeError)` is the textbook choice — not awkward.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_stdlib_results() -> Lesson {
  Lesson(
    id: "l05-stdlib-results",
    unit_id: "u09-option-result",
    title: "Results in the stdlib",
    emits_tags: [Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Now you'll start to see the standard library return `Result` all over the place. Two representative ones:\n\n- **`int.parse(String) -> Result(Int, Nil)`** — a string to an integer. If it isn't an integer, `Error(Nil)`.\n- **`list.first(List(a)) -> Result(a, Nil)`** — the first element of a list. If the list is empty, `Error(Nil)`.\n\nBoth have only one reason for failure, so the error type is `Nil` (the same idiom as U9-④). Still, \"pattern match to take it out\" applies just the same.",
      ),
      predict(
        "parse-int-ok",
        "What is the result of `int.parse`?",
        "import gleam/int\n\nint.parse(\"42\")",
        ["`Ok(42)`", "`42`", "`Error(Nil)`", "`Some(42)`"],
        0,
        "Right! \"42\" parses fine as an integer, giving `Ok(42)` — success values come out wrapped in `Ok` too.",
        [
          #(
            1,
            "The value is 42, but it's a `Result` so it's wrapped as `Ok(42)` — it doesn't come out as a bare `42`.",
          ),
          #(
            2,
            "\"42\" is a perfectly good integer, so it's a success — `Error(Nil)` is for when parsing *fails*.",
          ),
          #(3, "`int.parse` returns a `Result` — it wraps in `Ok`, not `Some`."),
        ],
      ),
      predict(
        "parse-float",
        "`int.parse` is for *integers* only. What is the value of `int.parse(\"4.2\")`?",
        "import gleam/int\n\nint.parse(\"4.2\")",
        ["`Error(Nil)`", "`Ok(4)`", "`Ok(4.2)`", "`4.2`"],
        0,
        "Exactly! \"4.2\" is not an *integer*, so `int.parse` fails and gives `Error(Nil)`. If there's a decimal point, integer parsing won't work.",
        [
          #(
            1,
            "It doesn't truncate (round down to 4) — \"4.2\" isn't an integer format, so the whole thing fails to parse.",
          ),
          #(
            2,
            "`int.parse` only produces an `Int` — it doesn't return the `Float` `4.2` (it fails to begin with).",
          ),
          #(
            3,
            "The value neither comes out bare nor parses — it's `Error(Nil)`.",
          ),
        ],
      ),
      Prose(
        "list-first",
        "`list.first` has the same shape. If there's at least one element it returns the first as `Ok`, and if it's empty it returns `Error(Nil)`. It's the way to safely handle \"the first element of a list that might be empty\" — it doesn't crash on an empty list.",
      ),
      predict(
        "first-ok",
        "What is the result of `list.first`?",
        "import gleam/list\n\nlist.first([10, 20, 30])",
        ["`Ok(10)`", "`10`", "`Ok([10, 20, 30])`", "`Ok(30)`"],
        0,
        "Right! The first element, 10, is wrapped in `Ok`, giving `Ok(10)`.",
        [
          #(
            1,
            "The value is 10, but it's a `Result` so it's wrapped as `Ok(10)` — it doesn't come out bare.",
          ),
          #(
            2,
            "`first` gives just the *first single element*, not the whole list — `Ok(10)`.",
          ),
          #(
            3,
            "`first` is the very *front* element — the first 10, not the last 30 (`list.last` is the last).",
          ),
        ],
      ),
      predict(
        "first-empty",
        "What if you use `list.first` on an empty list? What is the value of `list.first([])`?",
        "import gleam/list\n\nlist.first([])",
        ["`Error(Nil)`", "`Ok(Nil)`", "the program crashes", "`[]`"],
        0,
        "Exactly! An empty list has no first element, so it's `Error(Nil)` — the failure comes back as a value, so it doesn't crash.",
        [
          #(
            1,
            "An empty list isn't a success — it reports \"no first element\" with `Error(Nil)`, not `Ok`.",
          ),
          #(
            2,
            "There are no exceptions, so it doesn't crash — `Result` safely expresses the failure.",
          ),
          #(
            3,
            "It's not the empty list as-is but a `Result` value (`Error(Nil)`) that comes out.",
          ),
        ],
      ),
      mcq(
        "why-result",
        "What is the best reason that `int.parse` and `list.first` go to the trouble of returning a `Result` instead of a bare value?",
        [
          "To express failure (can't parse, empty list) as a *value*, so the caller can safely handle both cases with case",
          "Because Result uses less memory than Int",
          "Because Gleam functions can only ever return Result",
          "To make debugging output prettier",
        ],
        0,
        "Right! Returning failure as a `Result` value instead of throwing an exception lets the compiler force \"did you handle the failure too?\" and prevent missed handling — that's the heart of this unit.",
        [
          #(
            1,
            "It has nothing to do with saving memory — the reason is to *express failure safely*.",
          ),
          #(
            2,
            "A function can return any type — `Result` is the choice when there's a possibility of failure.",
          ),
          #(
            3,
            "It's not about debug display, but about surfacing failure in the type so the caller handles it.",
          ),
        ],
      ),
    ],
  )
}

fn unit_result_use() -> Unit {
  let meta =
    UnitMeta(
      id: "u10-result-use",
      title: "Result Chaining and use",
      order: 10,
      level: 3,
      concepts: [
        Concept("results"),
        Concept("use-expressions"),
        Tricky("use-desugaring"),
      ],
      prerequisites: ["u08-list-module", "u09-option-result"],
      lesson_ids: [
        "l30-case-stairs", "l31-map-try", "l32-use-sugar", "l33-use-desugar",
      ],
    )
  let lessons = [
    lesson_case_stairs(),
    lesson_map_try(),
    lesson_use_sugar(),
    lesson_use_desugar(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u10-result-use", lessons),
  )
}

fn lesson_case_stairs() -> Lesson {
  Lesson(
    id: "l30-case-stairs",
    unit_id: "u10-result-use",
    title: "The Pain of the case Staircase",
    emits_tags: [Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Remember the `parse_age` we built in U9? An operation that can fail returns a `Result(success, failure)`, and the caller had to handle **both** the `Ok` and `Error` cases with a `case`.\n\n```gleam\npub fn parse_age(input: String) -> Result(Int, AgeError) {\n  case int.parse(input) {\n    Error(Nil) -> Error(NotANumber)\n    Ok(n) -> case n < 0 {\n      True -> Error(Negative)\n      False -> Ok(n)\n    }\n  }\n}\n```\n\nBut what happens when you need to chain **two** Results together? For example, parsing two ages separately and adding them.",
      ),
      Prose(
        "stairs",
        "Since each `parse_age` is a Result, you have to unwrap it with a `case` to get at the inner value. And when you unwrap twice, the cases end up **nested like a staircase**:\n\n```gleam\npub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  case parse_age(a) {\n    Error(e) -> Error(e)\n    Ok(age_a) -> case parse_age(b) {\n      Error(e) -> Error(e)\n      Ok(age_b) -> Ok(age_a + age_b)\n    }\n  }\n}\n```\n\nSee how the `Error(e) -> Error(e)` line repeats identically on every step of the staircase? That redundancy is exactly what we'll flatten out in this unit.",
      ),
      predict(
        "stairs-both-ok",
        "In the staircase-style `add_ages` above, what is the value of `add_ages(\"5\", \"7\")`?",
        "// From the definition above\nadd_ages(\"5\", \"7\")",
        ["`Ok(12)`", "`12`", "`Ok(5)`", "`Error(NotANumber)`"],
        0,
        "Correct! Both are `Ok`, so the outer case extracts `age_a` (5) and the inner one extracts `age_b` (7), producing `Ok(5 + 7)` = `Ok(12)`.",
        [
          #(
            1,
            "In a Result, the value never comes out bare. Since the function's return type is `Result`, the final result is wrapped in `Ok(...)` too — `Ok(12)`, not `12`.",
          ),
          #(
            2,
            "You only looked at the outer case. After unwrapping the inner `parse_age(\"7\")` as well and adding the two, the result is `Ok(12)`.",
          ),
          #(
            3,
            "Both inputs are valid numbers, so neither branch falls into Error — it's `Ok(12)`.",
          ),
        ],
      ),
      predict(
        "stairs-second-fail",
        "In the same staircase-style `add_ages`, what is the value of `add_ages(\"3\", \"x\")`? (`\"x\"` is not a number)",
        "// From the definition above\nadd_ages(\"3\", \"x\")",
        ["`Ok(3)`", "`Error(NotANumber)`", "`Error(Negative)`", "`Ok(0)`"],
        1,
        "Exactly! The outer `parse_age(\"3\")` is `Ok(3)`, so we step inside, but `parse_age(\"x\")` is `Error(NotANumber)`, and that branch becomes the function's result directly.",
        [
          #(
            0,
            "Even if the first parse succeeds, the whole thing fails when the second one fails. The `Error` branch of the inner case becomes the result — `Error(NotANumber)`, not `Ok(3)`.",
          ),
          #(
            2,
            "`Negative` is the error for a negative number. `\"x\"` isn't negative — it isn't a number at all, so it's `NotANumber`.",
          ),
          #(
            3,
            "A failure doesn't quietly fall back to a default like `Ok(0)` — the error stays in the type and surfaces as `Error(NotANumber)`.",
          ),
        ],
      ),
      Prose(
        "pain",
        "The pain of this staircase is clear. Every time you chain another Result, the case nests one level deeper, and the **\"if it failed, just pass it through\"** code — `Error(e) -> Error(e)` — repeats identically. In the next lesson we'll strip away this repetition with stdlib's `result.map` and `result.try`.",
      ),
      mcq(
        "stairs-why-nested",
        "What is the fundamental reason the cases turn into a nested staircase when chaining two Results?",
        [
          "Because Gleam's case can only inspect one value at a time",
          "Because extracting the inner value of each Result (the contents of `Ok`) requires unwrapping it with a `case`, and unwrapping twice puts one unwrap inside the other",
          "Because `Result` types can't be added directly, which causes a compile error",
          "Because `parse_age` is a recursive function",
        ],
        1,
        "Correct! To use the `n` inside `Ok(n)`, you have to unwrap the packaging with a case every time, and to unwrap both values, one case goes inside the other, forming a staircase.",
        [
          #(
            0,
            "case can inspect multiple values at once with `case a, b { ... }`. The cause of the staircase isn't that — it's unwrapping the Result packaging one after another.",
          ),
          #(
            2,
            "It's not because of a compile error. Adding the values after extracting them is fine; the problem is that the extraction process gets nested.",
          ),
          #(
            3,
            "`parse_age` isn't recursive. The staircase comes from unwrapping the Result twice, not from recursion.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_map_try() -> Lesson {
  Lesson(
    id: "l31-map-try",
    unit_id: "u10-result-use",
    title: "result.map and result.try",
    emits_tags: [Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Before flattening the staircase, let's learn two tools. Both do the same thing — **\"if it's Error, pass it through; if it's Ok, apply a function to the inner value\"** — but they differ in the return type of the function being applied.\n\n- `result.map(result, fn(x) { ... })` — the callback returns a **plain value**. map re-wraps that value back into `Ok(...)` for you.\n- `result.try(result, fn(x) { ... })` — the callback returns **another Result**. try uses it as-is for the result (no double wrapping).",
      ),
      predict(
        "map-ok",
        "`result.map` applies the function to the inner value when it's Ok and re-wraps in Ok. What is this value?",
        "result.map(Ok(5), fn(x) { x * 2 })",
        ["`Ok(10)`", "`10`", "`Ok(5)`", "`Ok(Ok(10))`"],
        0,
        "Exactly! It applies `* 2` to the 5 inside `Ok(5)` to get 10, then re-wraps that in `Ok` to give `Ok(10)`.",
        [
          #(
            1,
            "map re-wraps the result in `Ok` — it's `Ok(10)`, not a bare `10`.",
          ),
          #(
            2,
            "The function `x * 2` is applied, so the inner value changes — `Ok(10)`, not `Ok(5)`.",
          ),
          #(
            3,
            "The callback returns a plain value (`10`), so there's only one layer of wrapping — `Ok(10)`, not `Ok(Ok(10))`.",
          ),
        ],
      ),
      predict(
        "map-error",
        "When an `Error` comes into `result.map`, the callback isn't called and the Error passes straight through. What is this value?",
        "let r: Result(Int, String) = Error(\"nope\")\nresult.map(r, fn(x) { x * 2 })",
        ["`Error(\"nope\")`", "`Ok(\"nope\")`", "`Error(0)`", "`\"nope\"`"],
        0,
        "Correct! On Error, the callback `x * 2` doesn't run at all, and `Error(\"nope\")` comes out untouched.",
        [
          #(
            1,
            "The error doesn't turn into `Ok` — when map encounters an Error, it leaves it untouched and passes it straight through.",
          ),
          #(
            2,
            "The value inside the error doesn't change either. `x * 2` is applied only to the inside of an Ok — an Error just passes through.",
          ),
          #(
            3,
            "In a Result, the value never comes out bare. The packaging isn't stripped — it stays `Error(\"nope\")`.",
          ),
        ],
      ),
      Prose(
        "try-chains",
        "Now for the key one: `result.try`. You use it when **the callback returns a Result** — which lets you chain Result-producing operations one after another. \"Continue with the callback if Ok, short-circuit immediately if Error\" is exactly what replaces the staircase's `Error(e) -> Error(e)`.\n\n```gleam\nresult.try(int.parse(\"4\"), fn(n) {\n  result.try(int.parse(\"6\"), fn(m) {\n    Ok(n + m)\n  })\n})\n```",
      ),
      predict(
        "try-chain-ok",
        "What is the value of the nested `result.try` call above? (`int.parse` is `Result(Int, Nil)`)",
        "result.try(int.parse(\"4\"), fn(n) {\n  result.try(int.parse(\"6\"), fn(m) {\n    Ok(n + m)\n  })\n})",
        ["`Ok(10)`", "`10`", "`Ok(Ok(10))`", "`Error(Nil)`"],
        0,
        "Exactly! `int.parse(\"4\")` = `Ok(4)`, so we proceed with `n` = 4; `int.parse(\"6\")` = `Ok(6)`, so `m` = 6; the final `Ok(4 + 6)` = `Ok(10)`.",
        [
          #(
            1,
            "The last line is `Ok(n + m)`, so the result is wrapped in `Ok` — `Ok(10)`, not `10`.",
          ),
          #(
            2,
            "`try` uses the Result the callback returns as-is (no double wrapping). The last one is `Ok(10)`, so the whole thing is `Ok(10)` too.",
          ),
          #(
            3,
            "Both parses succeed, so there's no short-circuit — it's `Ok(10)`, not `Error(Nil)`.",
          ),
        ],
      ),
      predict(
        "try-chain-shortcircuit",
        "In the same shape, what if the first parse fails? `int.parse(\"x\")` is `Error(Nil)`. What is this value?",
        "result.try(int.parse(\"x\"), fn(n) {\n  result.try(int.parse(\"6\"), fn(m) {\n    Ok(n + m)\n  })\n})",
        ["`Ok(6)`", "`Error(Nil)`", "`Ok(Error(Nil))`", "`Ok(0)`"],
        1,
        "Correct! The first `int.parse(\"x\")` is `Error(Nil)`, so `try` short-circuits immediately — the callback doesn't run and `Error(Nil)` is the result as-is.",
        [
          #(
            0,
            "When the first step fails, the inner callback never runs at all. It doesn't even reach `int.parse(\"6\")` — it's `Error(Nil)`.",
          ),
          #(
            2,
            "A short-circuited Error doesn't get wrapped in `Ok`. try passes the Error straight through, giving `Error(Nil)`.",
          ),
          #(
            3,
            "A failure isn't smoothed over with a default — the error stays in the type and comes out as `Error(Nil)`.",
          ),
        ],
      ),
      mcq(
        "map-vs-try",
        "What happens if you use `result.map` when the callback **itself returns another Result**? Example: `result.map(int.parse(\"4\"), fn(n) { Ok(n + 1) })`",
        [
          "`Ok(5)` — map automatically flattens it into a single layer",
          "`Ok(Ok(5))` — map always wraps the callback's result in one more Ok, producing double wrapping",
          "Compile error — map can't take a callback that returns a Result",
          "`Error(Nil)` — a mixed-in Result is treated as a failure",
        ],
        1,
        "Correct! map wraps whatever the callback returns in one more `Ok`. If the callback already returns `Ok(5)`, you get the double wrapping `Ok(Ok(5))` — this is when you should use `try` instead.",
        [
          #(
            0,
            "Flattening is `try`'s job. map always adds one more layer, so here you get `Ok(Ok(5))`.",
          ),
          #(
            2,
            "It does compile — but contrary to your intent, you end up with a double-wrapped type like `Ok(Ok(5))`.",
          ),
          #(
            3,
            "A mixed-in Result isn't treated as a failure. You get the double-wrapped success value `Ok(Ok(5))`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_use_sugar() -> Lesson {
  Lesson(
    id: "l32-use-sugar",
    unit_id: "u10-result-use",
    title: "use — Sugar that Flattens the Staircase",
    emits_tags: [Concept("use-expressions"), Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`result.try` solved the short-circuiting, but because each callback nests another `try`, the indentation still keeps creeping rightward. Gleam's `use` expression flattens this chain out **top-to-bottom**.\n\n```gleam\nimport gleam/result\n\npub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  use age_a <- result.try(parse_age(a))\n  use age_b <- result.try(parse_age(b))\n  Ok(age_a + age_b)\n}\n```\n\nThe staircase is gone, and there's no more `Error(e) -> Error(e)` repetition. `use age_a <- ...` reads as \"if this Result is Ok, bind its value to `age_a` and continue below; if Error, short-circuit straight away.\"",
      ),
      predict(
        "addages-ok",
        "In the `use` version of `add_ages` above, what is the value of `add_ages(\"8\", \"9\")`?",
        "pub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  use age_a <- result.try(parse_age(a))\n  use age_b <- result.try(parse_age(b))\n  Ok(age_a + age_b)\n}\n\nadd_ages(\"8\", \"9\")",
        ["`Ok(17)`", "`17`", "`Ok(8)`", "`Error(NotANumber)`"],
        0,
        "Exactly! Both parses are Ok, so we descend with `age_a` = 8 and `age_b` = 9, and the final `Ok(8 + 9)` = `Ok(17)`.",
        [
          #(
            1,
            "The function's return type is `Result`, so the last line is `Ok(...)` too — `Ok(17)`, not a bare `17`.",
          ),
          #(
            2,
            "After passing through both `use` lines, the two are added — `Ok(17)`, not `Ok(8)` which only considers `age_a`.",
          ),
          #(
            3,
            "Both inputs are valid numbers, so there's no short-circuit — it's `Ok(17)`, not `Error`.",
          ),
        ],
      ),
      Prose(
        "shortcircuit",
        "Here's the key intuition of this unit. When `result.try` on a `use` line receives an `Error`, **the lines below it don't run at all**, and the Error becomes the function's return value directly.\n\nIn U3 you learned that \"Gleam has no early return.\" The short-circuiting of `use` + `result.try` performs exactly that early-return role — but **type-safely** (via the Result type).",
      ),
      predict(
        "addages-shortcircuit",
        "What is the value of `add_ages(\"3\", \"x\")`? (the `use` version, `\"x\"` is not a number)",
        "pub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  use age_a <- result.try(parse_age(a))\n  use age_b <- result.try(parse_age(b))\n  Ok(age_a + age_b)\n}\n\nadd_ages(\"3\", \"x\")",
        ["`Ok(3)`", "`Error(NotANumber)`", "`Ok(0)`", "`Error(Negative)`"],
        1,
        "Correct! The first line is `Ok(3)`, so we descend with `age_a` = 3, but `parse_age(\"x\")` on the second `use` line is `Error(NotANumber)`, so it short-circuits there — the `Ok(...)` below doesn't run and that Error is returned.",
        [
          #(
            0,
            "When an Error comes out of a use line, the lines below don't run and the Error becomes the function's return value directly. So much for no early return — Result chaining performs that role type-safely — `Error(NotANumber)`, not `Ok(3)`.",
          ),
          #(
            2,
            "Short-circuiting doesn't create a default like `Ok(0)`. It returns the failing Error as-is — `Error(NotANumber)`.",
          ),
          #(
            3,
            "`\"x\"` isn't negative — it isn't a number at all, so it's `NotANumber`, not `Negative`.",
          ),
        ],
      ),
      predict(
        "addages-negative",
        "What is the value of `add_ages(\"-3\", \"4\")`? (`parse_age` returns `Error(Negative)` for negatives)",
        "pub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  use age_a <- result.try(parse_age(a))\n  use age_b <- result.try(parse_age(b))\n  Ok(age_a + age_b)\n}\n\nadd_ages(\"-3\", \"4\")",
        ["`Error(Negative)`", "`Error(NotANumber)`", "`Ok(1)`", "`Ok(-3)`"],
        0,
        "Exactly! The first `parse_age(\"-3\")` succeeds at number parsing but is negative, so it yields `Error(Negative)` — it short-circuits right on the first `use` line.",
        [
          #(
            1,
            "`\"-3\"` does succeed at integer parsing (sign included). It's just negative, so it's caught as `Negative` — not `NotANumber`.",
          ),
          #(
            2,
            "It already short-circuits on the first line, so it never reaches the addition — `Error(Negative)`, not `Ok(1)`.",
          ),
          #(
            3,
            "The short-circuited result is `Error`. On top of that, `parse_age` rejects negative input, so it can't be `Ok(-3)`.",
          ),
        ],
      ),
      mcq(
        "forgot-ok",
        "After flattening everything with `use`, what happens if you write the last line as just `age_a + age_b` instead of `Ok(age_a + age_b)`?",
        [
          "It works fine — Gleam automatically wraps it in Ok",
          "Type mismatch compile error — the function's return type is `Result` but the last expression is `Int`",
          "It errors at runtime",
          "It always returns `Error`",
        ],
        1,
        "Correct! Even after flattening with use, the function's return type is still `Result`. Forgetting to wrap the final success value in `Ok` is the number-one classic mistake of the `use-expr` theme, and the compiler catches it as a Type mismatch.",
        [
          #(
            0,
            "Gleam doesn't put `Ok` on automatically. If the return type is `Result(Int, _)` but the last expression is `Int`, the types don't line up and it's a compile error.",
          ),
          #(
            2,
            "It's blocked at compile time, not runtime — if the types don't match, it won't even run.",
          ),
          #(
            3,
            "It doesn't return `Error` — it simply won't compile, because of the type mismatch.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_use_desugar() -> Lesson {
  Lesson(
    id: "l33-use-desugar",
    unit_id: "u10-result-use",
    title: "What use Really Is — Desugaring and Its Limits",
    emits_tags: [
      Concept("use-expressions"),
      Tricky("use-desugaring"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`use` isn't magic — it's **syntactic sugar**. Once you know what it really is, there's nothing to be confused about.\n\n```gleam\nuse x <- f(arg)\nrest_of_the_code\n```\n\nThis single line expands to exactly the following (desugaring):\n\n```gleam\nf(arg, fn(x) { rest_of_the_code })\n```\n\nThe key: **\"the entire rest of the code\" below the `use` line goes wholesale into the body of the final-argument callback `fn(x) { ... }`.** Not just part of it — all of it.",
      ),
      predict(
        "desugar-equiv",
        "The two snippets below are the same function (one uses use, the other is the desugared form). What is the value of `add(\"10\", \"5\")`?",
        "// use version\n//   use x <- result.try(int.parse(a))\n//   use y <- result.try(int.parse(b))\n//   Ok(x + y)\n// desugared version:\nresult.try(int.parse(\"10\"), fn(x) {\n  result.try(int.parse(\"5\"), fn(y) {\n    Ok(x + y)\n  })\n})",
        ["`Ok(15)`", "`15`", "`Ok(Ok(15))`", "`Error(Nil)`"],
        0,
        "Exactly! The two forms are completely identical code. We descend with `x` = 10 and `y` = 5, and the final `Ok(10 + 5)` = `Ok(15)`.",
        [
          #(
            1,
            "The last one is `Ok(x + y)`, so the result is wrapped — `Ok(15)`, not a bare `15`.",
          ),
          #(
            2,
            "`try` uses the Result the callback returns as-is (no double wrapping) — `Ok(15)`, not `Ok(Ok(15))`.",
          ),
          #(
            3,
            "Both parses succeed, so there's no short-circuit — it's `Ok(15)`.",
          ),
        ],
      ),
      Prose(
        "general-sugar",
        "An important insight here: `use` is **not** exclusive to `result.try`. Since desugaring is \"pass a callback as the last argument,\" it works with **any function whose last argument is a function** (e.g., `list.map` is syntactically possible too). That said, using it outside a short-circuiting flow tends to make things harder to read, so idiomatically it's used in \"continue/short-circuit\" contexts like `result.try`/`option`.\n\nA word of caution against overuse: `use` only removes indentation — it doesn't change the meaning.",
      ),
      mcq(
        "desugar-wrong-pairing",
        "Which of the following pairs `use` with its desugaring **incorrectly**?",
        [
          "`use x <- f(a)` ⟶ `f(a, fn(x) { rest })`",
          "`use x <- f(a)` ⟶ `f(fn(x) { rest }, a)`  (callback as first argument)",
          "`use a, b <- f(x)` ⟶ `f(x, fn(a, b) { rest })`",
          "`use <- f(x)` ⟶ `f(x, fn() { rest })`  (no value received)",
        ],
        1,
        "Correct! The callback always goes in as the **last** argument. (2), which puts it first, is the wrong pairing — the desugaring rule is \"the rest of the code as the last-argument callback.\"",
        [
          #(
            0,
            "This is a correct pairing. `use x <- f(a)` expands to exactly `f(a, fn(x) { rest })`.",
          ),
          #(
            2,
            "This is correct too. If you write multiple names to the left of the arrow, the callback takes that many arguments (`fn(a, b)`).",
          ),
          #(
            3,
            "This is a correct pairing as well. If the left of the arrow is empty, you get an argument-less callback `fn() { ... }`.",
          ),
        ],
      ),
      mcq(
        "callback-scope",
        "There are three more lines of code below a `use` line. Which of them go into the body of the callback `fn(x) { ... }`?",
        [
          "Only the very next line",
          "All three lines below the `use` line",
          "Only the last `Ok(...)` line",
          "No lines at all — use ends on that line",
        ],
        1,
        "Correct! The crux of desugaring is that \"the entire rest of the code\" becomes the callback body — all three lines below go inside `fn(x) { ... }`.",
        [
          #(
            0,
            "It's not just one line. Every line below use goes wholesale into the callback body.",
          ),
          #(
            2,
            "It's not just the last line — everything below use is the callback body, so the middle lines go in too.",
          ),
          #(
            3,
            "use doesn't end on that line — on the contrary, it wraps the entire code below into the callback to continue it.",
          ),
        ],
      ),
      predict(
        "use-single-line",
        "A single-step `use` follows the same rule. What is the value of `inc(\"41\")`?",
        "pub fn inc(s: String) -> Result(Int, Nil) {\n  use n <- result.try(int.parse(s))\n  Ok(n + 1)\n}\n\ninc(\"41\")",
        ["`Ok(42)`", "`42`", "`Ok(Ok(42))`", "`Error(Nil)`"],
        0,
        "Exactly! `int.parse(\"41\")` = `Ok(41)`, so `n` = 41, and the callback body `Ok(41 + 1)` = `Ok(42)`. Desugared, it's the same as `result.try(int.parse(\"41\"), fn(n) { Ok(n + 1) })`.",
        [
          #(
            1,
            "The function's return type is `Result`, so the last one is `Ok(...)` too — `Ok(42)`, not `42`.",
          ),
          #(
            2,
            "`try` flattens, so there's only one layer of wrapping — `Ok(42)`, not `Ok(Ok(42))`.",
          ),
          #(
            3,
            "`\"41\"` is a valid number, so the parse succeeds — no short-circuit, it's `Ok(42)`.",
          ),
        ],
      ),
    ],
  )
}

fn unit_generics() -> Unit {
  let meta =
    UnitMeta(
      id: "u11-generics",
      title: "Generics and Type Design Basics",
      order: 11,
      level: 3,
      concepts: [
        Concept("generics"),
        Concept("type-aliases"),
        Concept("dicts"),
      ],
      prerequisites: ["u08-list-module", "u09-option-result"],
      lesson_ids: [
        "l40-type-variables", "l41-generic-types", "l42-alias-tuple-custom",
        "l43-dicts-sets",
      ],
    )
  let lessons = [
    lesson_type_variables(),
    lesson_generic_types(),
    lesson_alias_tuple_custom(),
    lesson_dicts_sets(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u11-generics", lessons),
  )
}

fn lesson_type_variables() -> Lesson {
  Lesson(
    id: "l40-type-variables",
    unit_id: "u11-generics",
    title: "Type Variables — Any One Thing",
    emits_tags: [Concept("generics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "So far, types have always started with an **uppercase** letter, like `Int` or `String`. But when you see **lowercase** names like `a` or `b` in a function signature, those are **type variables**.\n\nA type variable is a promise that says \"this can be any type at all, but the same letter must always be the same type.\" Which concrete type actually fills in is decided by the compiler through inference **at the moment of the call**.",
      ),
      Prose(
        "pair-map",
        "Look at `pair_map` below. It takes a tuple whose two elements share the same type (`a`), applies `f` to each element, and builds a new tuple.\n\n```gleam\npub fn pair_map(pair: #(a, a), f: fn(a) -> b) -> #(b, b) {\n  let #(x, y) = pair\n  #(f(x), f(y))\n}\n```\n\n`a` is the type of the input elements, and `b` is the type `f` returns. They're allowed to differ — only *matching letters* have to match.",
      ),
      predict(
        "pair-map-to-string",
        "`int.to_string` takes an `Int` and returns a `String`. What is the value of this call?",
        "pair_map(#(1, 2), int.to_string)",
        ["`#(\"1\", \"2\")`", "`#(1, 2)`", "`#(\"1, 2\")`", "compile error"],
        0,
        "Exactly! Here `a = Int` and `b = String`. `int.to_string` is applied to each element, giving `#(\"1\", \"2\")`.",
        [
          #(
            1,
            "`f` transforms each element — you don't get the original back (`#(1, 2)`).",
          ),
          #(
            2,
            "The result is a **tuple**, not a single string — each element is transformed and stays in its own slot.",
          ),
          #(
            3,
            "Since both are `Int`, the `#(a, a)` promise is kept, so it compiles fine.",
          ),
        ],
      ),
      predict(
        "pair-map-double",
        "This time an anonymous function doubles each element. What is the value of this call?",
        "pair_map(#(3, 4), fn(n) { n * 2 })",
        ["`#(6, 8)`", "`#(3, 4)`", "`#(7)`", "`#(3, 4, 6, 8)`"],
        0,
        "Right! Here `a = Int` and `b = Int`. 3*2=6 and 4*2=8, so the result is `#(6, 8)`.",
        [
          #(
            1,
            "`f` is applied to each element, so the values change — the original doesn't stay as-is.",
          ),
          #(
            2,
            "It doesn't add the two elements together — each is transformed separately, keeping **two tuple slots**.",
          ),
          #(
            3,
            "The number of elements doesn't grow — the output has the same shape `#(b, b)`, i.e. two slots.",
          ),
        ],
      ),
      mcq(
        "same-letter-rule",
        "What does the type annotation `pair: #(a, a)` actually **promise**?",
        [
          "The tuple's two elements must be the same type",
          "The tuple's two elements must both be `Int`",
          "The tuple's two elements are allowed to differ",
          "The tuple must have exactly `a` elements",
        ],
        0,
        "Right! The same letter `a` is used twice, so both elements are tied to the *same* type. Mixing them like `#(1, \"x\")` is a compile error.",
        [
          #(
            1,
            "`a` can be *any* type — it isn't fixed to `Int`. The two just have to match each other.",
          ),
          #(
            2,
            "To allow different types you'd write different letters, like `#(a, b)`. `#(a, a)` forces sameness.",
          ),
          #(
            3,
            "`a` is a name for a *type*, not a count — it has nothing to do with the number of tuple slots.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_generic_types() -> Lesson {
  Lesson(
    id: "l41-generic-types",
    unit_id: "u11-generics",
    title: "Generic Custom Types",
    emits_tags: [Concept("generics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Type variables can be attached not only to functions but also to **custom types**. In fact, the `List(a)`, `Option(a)`, and `Result(a, e)` you've already been using are all such **generic custom types** — and you can build your own too.\n\n```gleam\npub type Box(a) {\n  Box(inner: a)\n}\n```\n\n`Box(a)` is \"a box that holds one thing.\" `Box(42)` becomes `Box(Int)`, and `Box(\"hi\")` becomes `Box(String)`. The type of the held value is exactly `a`.",
      ),
      Prose(
        "unbox",
        "The function that takes a value out of the box is generic too. It takes a `Box(a)` and returns the `a` inside, unchanged.\n\n```gleam\npub fn unbox(box: Box(a)) -> a {\n  box.inner\n}\n```\n\nRecord field access (`box.inner`) works just as you saw in U4 — being generic changes nothing.",
      ),
      predict(
        "unbox-int",
        "What do you get when you unbox `Box(42)`? (`unbox(box) -> a` returns `box.inner`)",
        "unbox(Box(42))",
        ["`42`", "`Box(42)`", "`Box(inner: 42)`", "`a`"],
        0,
        "Exactly! `unbox` takes the value out of the box as-is — the unwrapped `42`.",
        [
          #(
            1,
            "`unbox` **unwraps** the box — it doesn't hand the whole box back.",
          ),
          #(
            2,
            "That's the shape of looking at the box *itself*. `unbox` extracts only the `inner` value.",
          ),
          #(
            3,
            "`a` is just a type variable (a placeholder), not an actual value — here it's filled in with `42`.",
          ),
        ],
      ),
      Prose(
        "map-box",
        "Now let's look at a function that \"transforms only the value inside without opening the box.\" Since the input type `a` and output type `b` may differ, we use two type variables.\n\n```gleam\npub fn map_box(box: Box(a), f: fn(a) -> b) -> Box(b) {\n  Box(f(box.inner))\n}\n```\n\nLook familiar? This is the **exact same shape** as `result.map` and `option.map` — you've just built their cousin.",
      ),
      predict(
        "map-box-incr",
        "What if you add 1 to the value inside? Pick the shape as printed by `string.inspect`.",
        "map_box(Box(5), fn(n) { n + 1 })",
        ["`Box(inner: 6)`", "`6`", "`Box(inner: 5)`", "`Box(5, 6)`"],
        0,
        "Right! `f` turns the inner 5 into 6, and the result is **wrapped back into a box** as `Box(inner: 6)`.",
        [
          #(
            1,
            "`map_box` hands back a box — not the unwrapped value (`6`) but `Box(inner: 6)`. (Use `unbox` to unwrap.)",
          ),
          #(
            2,
            "`f` is applied, turning 5 into 6 — the original value doesn't stay.",
          ),
          #(
            3,
            "The box holds only the single transformed value — the old and new values don't both remain.",
          ),
        ],
      ),
      predict(
        "map-box-upper",
        "This time it uppercases a string. What shape is the result?",
        "map_box(Box(\"gleam\"), string.uppercase)",
        [
          "`Box(inner: \"GLEAM\")`",
          "`\"GLEAM\"`",
          "`Box(inner: \"gleam\")`",
          "compile error",
        ],
        0,
        "Exactly! Here `a = String` and `b = String`. The inner \"gleam\" becomes \"GLEAM\" and is wrapped back into the box.",
        [
          #(
            1,
            "The result is a box — not the unwrapped string but `Box(inner: \"GLEAM\")`.",
          ),
          #(
            2,
            "`string.uppercase` is applied, making it uppercase — it doesn't stay as the original.",
          ),
          #(
            3,
            "It's a `String -> String` function, so it fits `fn(a) -> b` perfectly — it compiles fine.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_alias_tuple_custom() -> Lesson {
  Lesson(
    id: "l42-alias-tuple-custom",
    unit_id: "u11-generics",
    title: "type alias, and tuple vs custom type",
    emits_tags: [Concept("type-aliases")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "When writing out a long type every time is tedious, you can give it a short nickname with a **type alias**.\n\n```gleam\npub type Pair =\n  #(String, Int)\n```\n\nNote: an alias *does not create a new type*. `Pair` is merely **another name** for `#(String, Int)`, so the two are fully interchangeable. This is different from a custom type (`pub type Box(a) { Box(...) }`), which *creates* a new type.",
      ),
      predict(
        "alias-use",
        "`make` returns a `Pair` (i.e. `#(String, Int)`). What's the output below?\n\n```gleam\npub type Pair = #(String, Int)\npub fn make() -> Pair { #(\"score\", 100) }\n```",
        "let p = make()\np.0 <> \"=\" <> int.to_string(p.1)",
        ["`\"score=100\"`", "`\"score\"`", "`\"100\"`", "compile error"],
        0,
        "Right! `Pair` is just `#(String, Int)`, so you access it like a tuple with `.0`/`.1` — \"score\" <> \"=\" <> \"100\".",
        [
          #(
            1,
            "It doesn't use only `.0` — `.1` is concatenated too, so the result is \"score=100\".",
          ),
          #(
            2,
            "`.0` (\"score\") is concatenated as well — you don't get just \"100\".",
          ),
          #(
            3,
            "An alias isn't a new type but the tuple itself, so `.0`/`.1` access works normally.",
          ),
        ],
      ),
      Prose(
        "tuple-access",
        "You pull tuple elements out by position: the first is `.0`, the second is `.1`. They're distinguished by **order**, not by name. So tuples have a downside: \"they're lightweight, but the code doesn't say what each slot means.\"",
      ),
      predict(
        "tuple-index",
        "What do you get when you pull out a tuple's second element?",
        "let user = #(\"lucy\", 30)\nuser.1",
        ["`30`", "`\"lucy\"`", "`#(\"lucy\", 30)`", "`1`"],
        0,
        "Exactly! `.1` is the **second** element (counting from 0), so it's 30.",
        [
          #(
            1,
            "`.0`, not `.1`, is the first (\"lucy\") — indices count from 0.",
          ),
          #(2, "`.1` pulls out *one slot*, not the whole tuple — it's 30."),
          #(
            3,
            "`.1` is an index notation, not a return of that number itself — it gives the second element, 30.",
          ),
        ],
      ),
      Prose(
        "custom-access",
        "By contrast, a custom record gives each slot a **name**. The second slot of `User(name: \"lucy\", age: 30)` is pulled out with `.age`, not `.1`.\n\n```gleam\npub type User {\n  User(name: String, age: Int)\n}\n```\n\nIf there are only two or three elements and their meaning is obvious, a tuple is enough; but once the slots grow or you start wondering \"what does this slot mean?\", the idiomatic move is to promote it to a **named custom type**.",
      ),
      predict(
        "record-field",
        "What do you get when you access by named field?",
        "let u = User(name: \"lucy\", age: 30)\nu.name",
        ["`\"lucy\"`", "`30`", "`\"name\"`", "`User(...)`"],
        0,
        "Right! The `.name` field points to \"lucy\" — you pulled it out by *name*, not by position (`.0`).",
        [
          #(
            1,
            "`.age`, not `.name`, is 30 — you have to follow the field name.",
          ),
          #(
            2,
            "`.name` returns the *value* of that field (\"lucy\"), not the field *name*.",
          ),
          #(
            3,
            "It pulls out just the `name` slot, not the *whole record value* — \"lucy\".",
          ),
        ],
      ),
      mcq(
        "tuple-vs-custom",
        "In which situation is a **custom type** (instead of a tuple) more appropriate?",
        [
          "When there are 5 fields and you want to make each one's meaning clear in the code",
          "When you briefly bundle two values together and immediately destructure them",
          "When the two values are self-evident, like coordinates `#(x, y)`",
          "When a function needs a temporary bundle to return two values at once",
        ],
        0,
        "Right! The more slots there are and the more their meaning matters, named fields (a custom type) make the code self-documenting.",
        [
          #(
            1,
            "For a light bundle you tie together and untie right away, a tuple is handier.",
          ),
          #(2, "Self-evident pairs like `x, y` read perfectly fine as a tuple."),
          #(
            3,
            "A temporary return bundle is a textbook use of a tuple — there's little need to make a new type.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_dicts_sets() -> Lesson {
  Lesson(
    id: "l43-dicts-sets",
    unit_id: "u11-generics",
    title: "A Tour of Dict and Set",
    emits_tags: [Concept("dicts")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Finally, let's tour two generic collections. **`Dict(k, v)`** is a dictionary that looks up a value (`v`) by a key (`k`) (`import gleam/dict`). It has *two* type variables, so it can hold \"any key, any value.\"\n\n```gleam\nlet scores = dict.from_list([#(\"lucy\", 10), #(\"max\", 7)])\n```\n\nImportant point: since the key may not exist, `dict.get` **returns a `Result`** (U9 makes a comeback!). If present, `Ok(value)`; if not, `Error(Nil)`.",
      ),
      predict(
        "dict-get-hit",
        "When the key exists, what is the value of `dict.get`?",
        "let scores = dict.from_list([#(\"lucy\", 10), #(\"max\", 7)])\ndict.get(scores, \"lucy\")",
        ["`Ok(10)`", "`10`", "`Some(10)`", "`Error(Nil)`"],
        0,
        "Right! Even when the value exists, it doesn't come out bare — it arrives wrapped as `Ok(10)`. To extract it, use pattern matching.",
        [
          #(
            1,
            "A Dict lookup can fail, so the result is wrapped in a `Result` — `Ok(10)`, not `10`.",
          ),
          #(
            2,
            "`dict.get` returns a `Result`, not an `Option` — so it's `Ok`, not `Some`.",
          ),
          #(
            3,
            "`Error(Nil)` is for when the key is *absent*. \"lucy\" is in the dictionary.",
          ),
        ],
      ),
      predict(
        "dict-get-miss",
        "What if you look up a key that doesn't exist?",
        "let scores = dict.from_list([#(\"lucy\", 10), #(\"max\", 7)])\ndict.get(scores, \"nobody\")",
        ["`Error(Nil)`", "`Nil`", "`None`", "runtime crash"],
        0,
        "Exactly! When the key is absent it's `Error(Nil)` — not a crash, but a *failure written into the type*. The caller has to handle it with case.",
        [
          #(
            1,
            "It's wrapped as `Error(Nil)`, not bare `Nil` — `dict.get` returns a `Result`.",
          ),
          #(
            2,
            "`None` is the absence of an `Option`. `dict.get` is a `Result`, so it uses `Error(Nil)`.",
          ),
          #(
            3,
            "A missing key isn't a crash but is safely expressed as `Error(Nil)` — there are no exceptions.",
          ),
        ],
      ),
      Prose(
        "dict-insert",
        "Dict is immutable too. `dict.insert(d, key, value)` doesn't modify the original; it returns a *new Dict*. And **inserting again at the same key overwrites it** — keys are never duplicated.",
      ),
      predict(
        "dict-insert-overwrite",
        "After inserting twice at the same key `\"a\"`, what's the size (`dict.size`)?",
        "let d =\n  dict.new()\n  |> dict.insert(\"a\", 1)\n  |> dict.insert(\"a\", 99)\ndict.size(d)",
        ["`1`", "`2`", "`99`", "`0`"],
        0,
        "Right! The same key gets overwritten and collapses into one — the size is 1 (with the value updated to 99).",
        [
          #(
            1,
            "The key `\"a\"` is the same, so you don't get two slots — the second insert overwrites the first.",
          ),
          #(
            2,
            "`99` is the stored *value*, not the *size* — there's only one entry.",
          ),
          #(3, "You inserted an entry, so it isn't empty — the size is 1."),
        ],
      ),
      Prose(
        "set",
        "**`Set(a)`** is a \"collection without duplicates\" (`import gleam/set`). Inserting the same value multiple times collapses it into one, and `set.contains` only asks whether something is in it — it doesn't care about order or count.",
      ),
      predict(
        "set-dedup",
        "If you insert 1 twice and 2 once, what's the Set's size (`set.size`)?",
        "let s =\n  set.new()\n  |> set.insert(1)\n  |> set.insert(2)\n  |> set.insert(1)\nset.size(s)",
        ["`2`", "`3`", "`1`", "`0`"],
        0,
        "Exactly! A Set merges duplicates — even though 1 is inserted twice it's counted once, and the only distinct values are 1 and 2, so the size is 2.",
        [
          #(
            1,
            "It's the count of *distinct values*, not the number of *insertions* — the duplicate 1 collapses, giving 2.",
          ),
          #(
            2,
            "There are two kinds of values (1, 2), so the size isn't 1. Only duplicates collapse.",
          ),
          #(3, "You inserted elements, so it isn't empty — the size is 2."),
        ],
      ),
    ],
  )
}

fn unit_opaque_types() -> Unit {
  let meta =
    UnitMeta(
      id: "u12-opaque-types",
      title: "Opaque Types and API Design",
      order: 12,
      level: 4,
      concepts: [Concept("opaque-types"), Concept("phantom-types")],
      prerequisites: ["u10-result-use", "u11-generics"],
      lesson_ids: [
        "l36-opaque-smart-ctor", "l37-invariant-boundary",
        "l38-make-invalid-unrep", "l39-phantom-types",
      ],
    )
  let lessons = [
    lesson_opaque_smart_ctor(),
    lesson_invariant_boundary(),
    lesson_make_invalid_unrep(),
    lesson_phantom_types(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u12-opaque-types", lessons),
  )
}

fn lesson_opaque_smart_ctor() -> Lesson {
  Lesson(
    id: "l36-opaque-smart-ctor",
    unit_id: "u12-opaque-types",
    title: "Make invalid values impossible to build — opaque + smart constructor",
    emits_tags: [Concept("opaque-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Normally `pub type` exposes both the type name and its **constructor**. So anyone can build a value directly, like `Amount(-999)` — even invalid values such as a negative amount.\n\n`pub opaque type` exposes **only** the type name and locks the constructor inside the module. From the outside you can't build a value directly; you can only build one through the functions the module provides.\n\n```\npub opaque type Amount {\n  Amount(cents: Int)\n}\n\npub fn new(cents: Int) -> Result(Amount, String) {\n  case cents >= 0 {\n    True -> Ok(Amount(cents))\n    False -> Error(\"amount must not be negative\")\n  }\n}\n\npub fn cents(amount: Amount) -> Int {\n  amount.cents\n}\n```\n\nA `new` like this — which ensures that \"only values that pass validation can exist\" — is called a **smart constructor**.",
      ),
      mcq(
        "opaque-outside",
        "What happens if you call the constructor directly from another module, like `bank.Amount(-999)`? (`Amount` is `opaque`, as above.)",
        [
          "An `Amount` worth `-999` cents is created",
          "An error is thrown at runtime",
          "Compile error — the constructor of an `opaque` type can't be used outside its module",
          "`new` is called automatically and an `Error` is returned",
        ],
        2,
        "Correct! This is the heart of `opaque`. The constructor is sealed inside the module, so a negative `Amount` is *not even representable* — it's a compile-time seal, not a runtime check.",
        [
          #(
            0,
            "If that were possible, it wouldn't be `opaque`. The constructor is never exposed outside the module.",
          ),
          #(
            1,
            "It never even reaches runtime — the compile is rejected up front.",
          ),
          #(
            3,
            "There's no magic that calls `new` automatically. It's simply blocked with a compile error.",
          ),
        ],
      ),
      Prose(
        "smart-ctor",
        "So how do you build an `Amount` from the outside? Only through the `new` the module exposes. `new` returns `Ok(amount)` if validation succeeds and `Error(...)` if it fails.\n\nInput that doesn't pass validation can never become an `Amount`.",
      ),
      predict(
        "new-negative",
        "What is the result of this call?",
        "new(-5)\n// pub fn new(cents) {\n//   case cents >= 0 {\n//     True -> Ok(Amount(cents))\n//     False -> Error(\"amount must not be negative\")\n//   }\n// }",
        [
          "`Ok(Amount(-5))`",
          "`Error(\"amount must not be negative\")`",
          "`-5`",
          "Compile error",
        ],
        1,
        "Exactly! `-5 >= 0` is false, so it takes the `False` branch and `Error(...)` comes out.",
        [
          #(
            0,
            "A negative value can't pass validation — it's `Error`, not `Ok`.",
          ),
          #(2, "`new` returns a `Result`, not a raw value."),
          #(
            3,
            "The syntax is fine — it compiles, and the value that comes out is `Error`.",
          ),
        ],
      ),
      predict(
        "new-then-cents",
        "When this code finishes, what is the value of `total`?",
        "let total = case new(150) {\n  Ok(a) -> cents(a)\n  Error(_) -> -1\n}\n// new returns Ok(Amount(150)) when validation passes",
        ["`150`", "`-1`", "`Ok(150)`", "`Amount(150)`"],
        0,
        "Correct! `150 >= 0`, so it takes the `Ok(a)` branch, and the accessor `cents` pulls out the 150 inside.",
        [
          #(
            1,
            "`-1` is the value of the `Error` branch. 150 passes validation.",
          ),
          #(2, "`cents` returns an `Int`, not a `Result` — just 150."),
          #(
            3,
            "`Amount` is `opaque`, so its internals aren't exposed as-is. The `Int` 150 pulled out by `cents` goes in.",
          ),
        ],
      ),
      mcq(
        "opaque-vs-type",
        "Which is a correct statement about the difference between `pub type` and `pub opaque type`?",
        [
          "`opaque` makes the type entirely private, so other modules can't even use the type name",
          "`opaque` exposes the type name but locks constructor/field access inside the module",
          "`opaque` is just a runtime performance optimization with no difference in meaning",
          "`opaque` automatically validates the fields for you",
        ],
        1,
        "Correct! The type name is exposed so it can be used in function signatures, but only the module can build and dissect values.",
        [
          #(
            0,
            "The type name is still exposed — you can use `bank.Amount` in a signature. What's hidden is the constructor/fields.",
          ),
          #(2, "It's not about performance — **encapsulation** is the point."),
          #(
            3,
            "The validation isn't done by `opaque` but by the smart constructor (`new`) you write.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_invariant_boundary() -> Lesson {
  Lesson(
    id: "l37-invariant-boundary",
    unit_id: "u12-opaque-types",
    title: "Enforce invariants at the module boundary",
    emits_tags: [Concept("opaque-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "An **invariant** is \"a property that is *always* true of any value of this type.\" For example: \"the cents of an `Amount` are never negative.\"\n\nWith `opaque` + a smart constructor, you only need to enforce this invariant **in a single place — the module boundary**. That's because the only way to create a value is through functions inside the module. Once something has become an `Amount`, *all the rest of your code can trust* that its cents can't be negative.",
      ),
      predict(
        "subtract-ok",
        "What is the result of this code? (`subtract` calls `new(cents(a) - cents(b))` inside the module.)",
        "let out = case new(100), new(30) {\n  Ok(a), Ok(b) ->\n    case subtract(a, b) {\n      Ok(r) -> cents(r)\n      Error(_) -> -1\n    }\n  _, _ -> -1\n}",
        ["`70`", "`130`", "`-1`", "`Ok(70)`"],
        0,
        "Correct! 100 - 30 = 70, and 70 >= 0, so `new` returns `Ok`. Pulling it out with `cents` gives 70.",
        [
          #(1, "It's a subtraction — not addition (130) but 100 - 30 = 70."),
          #(
            2,
            "`-1` is the value of the `Error` branch. 70 isn't negative, so it passes validation.",
          ),
          #(
            3,
            "Since you've pulled it out once with `cents`, it's the `Int` 70 that goes in, not a `Result`.",
          ),
        ],
      ),
      predict(
        "subtract-underflow",
        "Now this one? (same `subtract`)",
        "case new(30), new(100) {\n  Ok(a), Ok(b) -> subtract(a, b)\n  _, _ -> Error(\"setup\")\n}",
        [
          "`Ok(Amount(-70))`",
          "`Error(\"amount must not be negative\")`",
          "`-70`",
          "`Error(\"setup\")`",
        ],
        1,
        "Exactly! 30 - 100 = -70, and `subtract` calls `new(-70)`, so the invariant check blocks it and the result is `Error`.",
        [
          #(
            0,
            "A negative `Amount` can't be created — that's the whole point of the invariant.",
          ),
          #(2, "`subtract` returns a `Result`, not a raw value."),
          #(
            3,
            "Both `new(30)` and `new(100)` succeed, so it never reaches the `\"setup\"` branch. The validation catches it at `new(-70)`.",
          ),
        ],
      ),
      Prose(
        "where",
        "The key here is that you \"don't scatter the negative check across every place that calls.\" The invariant is enforced once, inside the module's `new`/`subtract`, and outside code that receives an `Amount` trusts it to be \"already valid\" and uses it.\n\nThe same goes for other domains. For `Email`, the invariant would be \"contains an `@`.\"",
      ),
      predict(
        "email-invalid",
        "When `Email`'s smart constructor validates with `string.contains(raw, \"@\")`, what is the result of `new(\"ab\")`?",
        "pub fn new(raw: String) -> Result(Email, String) {\n  case string.contains(raw, \"@\") {\n    True -> Ok(Email(raw))\n    False -> Error(\"invalid email\")\n  }\n}\n\nnew(\"ab\")",
        [
          "`Ok(Email(\"ab\"))`",
          "`Error(\"invalid email\")`",
          "`\"ab\"`",
          "`True`",
        ],
        1,
        "Correct! `\"ab\"` has no `@`, so `string.contains` is `False` — it takes the `Error` branch.",
        [
          #(
            0,
            "Without an `@` it doesn't become `Ok` — the invariant blocks it.",
          ),
          #(2, "`new` returns a `Result`, not a raw string."),
          #(
            3,
            "`string.contains` is just the value tested by the `case`; the result of `new` is a `Result`.",
          ),
        ],
      ),
      mcq(
        "boundary-benefit",
        "What is the biggest benefit of a design that enforces invariants \"only at the module boundary\"?",
        [
          "You have to copy-paste the validation code into every call site that uses the value",
          "Once a value is created you can trust it's valid everywhere, so defensive code disappears",
          "Runtime validation happens more often, making it safer",
          "Making the type `opaque` auto-generates the validation",
        ],
        1,
        "Correct! Since the path to creating values is sealed, any `Amount` you receive is already valid. The scattered `if cents < 0` defensive code is no longer needed.",
        [
          #(
            0,
            "That's the exact opposite — enforcing it once at the boundary eliminates the copy-paste.",
          ),
          #(
            2,
            "Validating once at creation is enough. Doing it often isn't the goal.",
          ),
          #(
            3,
            "`opaque` only seals the path; you write the validation logic in `new` yourself.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_make_invalid_unrep() -> Lesson {
  Lesson(
    id: "l38-make-invalid-unrep",
    unit_id: "u12-opaque-types",
    title: "make invalid states unrepresentable",
    emits_tags: [Concept("opaque-types"), Tricky("invalid-states")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "A principle that takes things one step further: **\"make invalid states unrepresentable.\"**\n\nIt's good to *block* invalid values with validation, but it's even better to design the type itself so that \"invalid combinations can't be built in the first place.\"\n\nA common anti-pattern: `User(is_member: Bool, name: String, points: Int)` — it allows contradictory combinations, like a guest who has a `name` filled in, or a member whose `points` are empty. Instead, if you split it into a sum type, each state carries *only the data it actually needs*.",
      ),
      predict(
        "member-greeting",
        "Given the following type and function, what is the value of `greeting(Member(\"Sumin\", 50))`?",
        "pub type User {\n  Guest\n  Member(name: String, points: Int)\n}\n\nfn greeting(u: User) -> String {\n  case u {\n    Guest -> \"Welcome, guest\"\n    Member(name, points) -> name <> \": \" <> int.to_string(points) <> \"p\"\n  }\n}",
        [
          "`\"Welcome, guest\"`",
          "`\"Sumin: 50p\"`",
          "`\"Sumin\"`",
          "`\"Member\"`",
        ],
        1,
        "Correct! The `Member` branch matches, so it pulls out `name` and `points` to produce `\"Sumin: 50p\"`.",
        [
          #(
            0,
            "That's the result of the `Guest` branch. The input is `Member`.",
          ),
          #(
            2,
            "`points` is appended to the string too — it's not just the name.",
          ),
          #(
            3,
            "`case` returns the *result expression* of a branch, not the constructor name.",
          ),
        ],
      ),
      Prose(
        "data-per-state",
        "The key is that `Guest` has *no* `name`/`points` fields at all. There's no way to build a \"guest who has points\" state. Since each state carries only its own data, contradictory combinations vanish at the type level.\n\nAnother benefit: when you handle it with `case`, the compiler checks whether you've \"handled every state\" (exhaustiveness).",
      ),
      predict(
        "connection-state",
        "What is the value of `describe(Connected(\"abc\"))`?",
        "pub type Connection {\n  Disconnected\n  Connected(session: String)\n}\n\nfn describe(c: Connection) -> String {\n  case c {\n    Disconnected -> \"offline\"\n    Connected(session) -> \"online:\" <> session\n  }\n}",
        [
          "`\"offline\"`",
          "`\"online:abc\"`",
          "`\"online:\"`",
          "`\"abc\"`",
        ],
        1,
        "Exactly! The `Connected` branch pulls out `session` (\"abc\") to produce `\"online:\" <> \"abc\"`.",
        [
          #(0, "That's the `Disconnected` branch. The input is `Connected`."),
          #(2, "`session` isn't empty — \"abc\" is appended after it."),
          #(
            3,
            "`case` returns the whole result expression of the branch — including the prefix \"online:\".",
          ),
        ],
      ),
      mcq(
        "design-choice",
        "Which design best expresses \"there's a session ID only when connected, and none when disconnected\"?",
        [
          "`Connection(connected: Bool, session: String)` — use an empty string when disconnected",
          "`Connection(connected: Bool, session: Result(String, Nil))`",
          "A sum type with two variants: `Disconnected` / `Connected(session: String)`",
          "Keep only `session: String` and use an agreed-upon value like `\"NONE\"` for disconnected",
        ],
        2,
        "Correct! Splitting it into a sum type makes the contradiction of \"disconnected but has a session\" unrepresentable — exactly make-invalid-states-unrepresentable.",
        [
          #(
            0,
            "An empty string is still a value, so the \"disconnected but has a session\" state is still representable.",
          ),
          #(
            1,
            "A little better, but the contradictory combination of `connected:False` with `session:Ok(..)` is still possible.",
          ),
          #(
            3,
            "An agreed-upon magic value (`\"NONE\"`) is fragile, and the type can't block it for you.",
          ),
        ],
      ),
      mcq(
        "exhaustiveness-benefit",
        "When you've eliminated invalid states via the type, what additional safety net do you get in `case`?",
        [
          "The runtime gets faster",
          "The compiler checks whether all variants are handled (exhaustiveness), preventing omissions",
          "Field values are validated automatically",
          "You can skip pattern matching",
        ],
        1,
        "Correct! Since the variants are stated explicitly, the compiler catches any branch you missed — and if you add a new state, every case that doesn't handle it surfaces as a compile error.",
        [
          #(
            0,
            "Exhaustiveness is about *preventing omissions*, not about speed.",
          ),
          #(
            2,
            "Value validation is separate — that's the smart constructor's job.",
          ),
          #(
            3,
            "On the contrary, you must handle every variant — completeness is the point, not omission.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_phantom_types() -> Lesson {
  Lesson(
    id: "l39-phantom-types",
    unit_id: "u12-opaque-types",
    title: "a taste of phantom types",
    emits_tags: [Concept("phantom-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "The last one is an **advanced taste** (feel free to just browse, no pressure). \n\nA type parameter can be used purely as a **discriminator** at the type level *without ever appearing in the value at all*. This is called a **phantom type**.\n\n```\npub type Meters\n\npub type Feet\n\npub type Length(unit) {\n  Length(amount: Float)\n}\n\npub fn add_lengths(a: Length(unit), b: Length(unit)) -> Length(unit) {\n  Length(a.amount +. b.amount)\n}\n```\n\nThe `unit` parameter is used in none of `Length`'s fields — it's purely a marker to distinguish \"this is meters, that is feet\" *by type*.",
      ),
      predict(
        "add-meters",
        "When adding values of the same unit, what does this code output?",
        "let a: Length(Meters) = Length(3.0)\nlet b: Length(Meters) = Length(2.0)\nlet total = add_lengths(a, b)\nio.println(float.to_string(total.amount))",
        ["`5.0`", "`6.0`", "`5`", "`Length(5.0)`"],
        0,
        "Correct! Both are `Meters` so the types match, and `3.0 +. 2.0 = 5.0` is printed.",
        [
          #(
            1,
            "It's addition — not the product (3.0 *. 2.0 = 6.0) but 3.0 +. 2.0 = 5.0.",
          ),
          #(2, "It's a `Float`, so it prints as `5.0`, not `5`."),
          #(
            3,
            "`total.amount` pulls out only the inner `Float` and prints it — 5.0, not the whole record.",
          ),
        ],
      ),
      Prose(
        "type-guard",
        "So why is `unit` useful? The signature of `add_lengths` pins down that `a` and `b` must have the **same `unit`**. So if you mix meters and feet, the compiler blocks it — it catches the unit confusion as a *compile error*. And there's no cost at all on the value (at runtime, `unit` disappears).",
      ),
      mcq(
        "mix-units",
        "What happens if you pass one `Length(Meters)` and one `Length(Feet)` to `add_lengths`?",
        [
          "You get a `Length` that adds the two",
          "A unit conversion happens at runtime",
          "A type mismatch compile error — because the `unit`s differ",
          "They're automatically unified to the first argument's unit",
        ],
        2,
        "Correct! The signature requires `a` and `b` to share the same `unit`, so mixing `Meters` and `Feet` is rejected at compile time.",
        [
          #(
            0,
            "Because the `unit`s differ, it won't compile in the first place — no resulting `Length` is produced either.",
          ),
          #(
            1,
            "A phantom type has no runtime behavior. There's no conversion logic anywhere.",
          ),
          #(
            3,
            "There's no magic auto-unification — it's simply blocked with a compile error.",
          ),
        ],
      ),
      mcq(
        "phantom-runtime",
        "Which is a correct description of a phantom type's parameters (`Meters`, `Feet`)?",
        [
          "They're stored as values at runtime and take up memory",
          "They don't appear in the value and are used only for compile-time distinction, so they have no runtime cost",
          "They must be used as the type of some field",
          "They can only be used with `opaque` types",
        ],
        1,
        "Exactly! That's why it's a \"phantom\" — it exists only in type checking and leaves no trace at runtime.",
        [
          #(
            0,
            "Since it doesn't go into the value, there's no runtime cost — that's exactly why it's a phantom.",
          ),
          #(
            2,
            "On the contrary, it's a phantom precisely *because* it's not used in a field — if it were used in a field, it would be an ordinary generic.",
          ),
          #(
            3,
            "It's a technique independent of `opaque` — you can put a phantom parameter on any type.",
          ),
        ],
      ),
    ],
  )
}

fn unit_intentional_crash() -> Unit {
  let meta =
    UnitMeta(
      id: "u13-intentional-crash",
      title: "Intentional Crashes",
      order: 13,
      level: 4,
      concepts: [Concept("let-assertions"), Tricky("crash-vs-result")],
      prerequisites: ["u09-option-result"],
      lesson_ids: ["l13a-todo-panic", "l13b-let-assert", "l13c-assert-test"],
    )
  let lessons = [
    lesson_todo_panic(),
    lesson_let_assert(),
    lesson_assert_test(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u13-intentional-crash", lessons),
  )
}

fn lesson_todo_panic() -> Lesson {
  Lesson(
    id: "l13a-todo-panic",
    unit_id: "u13-intentional-crash",
    title: "todo and panic — not yet vs never",
    emits_tags: [Concept("let-assertions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "So far we've treated failure as **data** — `Option`, `Result`. But sometimes the right answer is \"we should never get here.\" The tools for that are `todo` and `panic`.\n\n`todo` is a marker for \"not built yet.\" It lets compilation succeed, but if you **run the program and reach that spot**, it crashes. `panic` is an assertion that says \"this place must never be reached.\"",
      ),
      Prose(
        "todo-fills",
        "The nice thing about `todo` is that it **satisfies the types while deferring the implementation**. You can sketch a function's skeleton first and fill the body with `todo`, and the whole program still compiles. Later you just replace that spot with real code.\n\nThe `area` below started out as `todo` and now has its body filled in. Let's actually call it.",
      ),
      predict(
        "area-filled",
        "We called `area` now that its body is filled in. What is the value of `area(4, 5)`?",
        "pub fn area(w: Int, h: Int) -> Int {\n  w * h\n}\n\npub fn main() {\n  io.println(int.to_string(area(4, 5)))\n}",
        ["`9`", "`20`", "`45`", "runtime crash (todo)"],
        1,
        "Right! The `todo` is gone and the body is `w * h`, so it prints 4 * 5 = 20.",
        [
          #(0, "It's `*`, not `+` — 4 * 5, not 4 + 5."),
          #(2, "That's `4` and `5` multiplied, not concatenated. It's 20."),
          #(
            3,
            "The `todo` has already been replaced with real code. You'll never land on that spot.",
          ),
        ],
      ),
      Prose(
        "panic-here",
        "`panic` is different — it means **\"impossible\"**, not \"unfinished.\" Once you've handled every meaningful branch of a `case`, you can put `panic as \"...\"` on a branch that logically can never occur; if it somehow is reached, the program stops immediately with that message.\n\nThe key point: **if it's never reached, nothing happens**. On the normal path it just returns a value as usual.",
      ),
      predict(
        "panic-not-reached",
        "If `b` isn't 0, the `panic` branch isn't reached. What is the value of `safe_div(20, 4)`?",
        "pub fn safe_div(a: Int, b: Int) -> Int {\n  case b {\n    0 -> panic as \"cannot divide by zero\"\n    _ -> a / b\n  }\n}\n\npub fn main() {\n  io.println(int.to_string(safe_div(20, 4)))\n}",
        ["`5`", "`0`", "runtime crash (panic)", "`24`"],
        0,
        "Exactly! 4 isn't 0, so it takes the `_` branch and computes 20 / 4 = 5. The `panic` wasn't reached.",
        [
          #(
            1,
            "It only stops when `b` is 0. Here it's 4, so it divides normally.",
          ),
          #(
            2,
            "It took the normal path (`b` isn't 0), so it doesn't crash. It returns 5.",
          ),
          #(3, "`/` is division — 20 / 4 = 5, not 20 + 4."),
        ],
      ),
      mcq(
        "todo-vs-panic",
        "Which statement most accurately describes the difference between `todo` and `panic`?",
        [
          "Both produce a compile error",
          "`todo` means \"not implemented yet\", `panic` means \"this must never be reached\"",
          "`todo` doesn't crash, only `panic` does",
          "`panic` can't take a message",
        ],
        1,
        "Right! `todo` = a marker for unfinished work, `panic` = an assertion of impossibility. The intent differs.",
        [
          #(
            0,
            "Both compile fine — they crash when you run the program and reach that spot.",
          ),
          #(
            2,
            "`todo` also crashes if you reach that spot at runtime. The difference is the intent.",
          ),
          #(3, "Both can attach an explanation with `as \"message\"`."),
        ],
      ),
    ],
  )
}

fn lesson_let_assert() -> Lesson {
  Lesson(
    id: "l13b-let-assert",
    unit_id: "u13-intentional-crash",
    title: "let assert — \"this is guaranteed to match\"",
    emits_tags: [Concept("let-assertions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "A `let` pattern **must cover the whole value**. That's why `let [first, ..] = xs` is a compile error — it doesn't handle the possibility of an empty list.\n\n`let assert` breaks that rule and allows a **partial pattern**. In exchange, you make a promise: \"if it isn't this shape at this point, that's a bug in my code.\" If the shape matches, it extracts the value; if it doesn't, it **crashes immediately**.",
      ),
      predict(
        "let-assert-head",
        "The list isn't empty, so the pattern matches. What is the value of `first_or_crash([10, 20, 30])`?",
        "pub fn first_or_crash(xs: List(Int)) -> Int {\n  let assert [first, ..] = xs\n  first\n}\n\npub fn main() {\n  io.println(int.to_string(first_or_crash([10, 20, 30])))\n}",
        ["`10`", "`30`", "`[10, 20, 30]`", "runtime crash"],
        0,
        "Right! In `[first, ..]`, `first` is bound to the head (the first element), which is 10.",
        [
          #(1, "`first` is the **first** element, not the last — it's 10."),
          #(2, "`first` is a single first element, not the whole list."),
          #(
            3,
            "The list isn't empty, so the pattern matches — it doesn't crash.",
          ),
        ],
      ),
      predict(
        "let-assert-ok",
        "`let assert Ok(n)` asserts that it's `Ok`. What is the value of `double_ok(Ok(21))`?",
        "pub fn double_ok(r: Result(Int, String)) -> Int {\n  let assert Ok(n) = r\n  n * 2\n}\n\npub fn main() {\n  io.println(int.to_string(double_ok(Ok(21))))\n}",
        ["`21`", "`42`", "`Ok(42)`", "runtime crash"],
        1,
        "Exactly! In `Ok(21)`, `n` unwraps to 21, and it returns 21 * 2 = 42.",
        [
          #(0, "After extracting `n` it computes `n * 2` — that's 42, not 21."),
          #(
            2,
            "`let assert Ok(n)` peels off the wrapper and extracts just `n`. The result is the `Int` 42.",
          ),
          #(3, "The value is `Ok`, so the assertion holds — it doesn't crash."),
        ],
      ),
      Prose(
        "fails-crash",
        "So what if the shape doesn't match? If an empty list comes in, like `first_or_crash([])`, it doesn't match `[first, ..]`, so it **crashes immediately**. The platform shows you the captured exception message (\"Pattern match failed...\") as-is.\n\nThat's the `let assert` bargain: in exchange for conveniently extracting the value, it stops the program when the promise is broken.",
      ),
      mcq(
        "empty-list-crash",
        "What happens when you run `first_or_crash([])`?",
        [
          "Returns `0`",
          "Returns `Error(Nil)`",
          "Crashes at runtime due to a pattern mismatch",
          "Produces a compile error",
        ],
        2,
        "Right! An empty list doesn't match `[first, ..]`, so the assertion breaks and it crashes immediately.",
        [
          #(
            0,
            "`let assert` doesn't produce a default value — it extracts when it matches and stops when it doesn't.",
          ),
          #(
            1,
            "`let assert` doesn't return a `Result`. Failure here is a crash, not data.",
          ),
          #(3, "It compiles fine — the failure happens at runtime."),
        ],
      ),
      mcq(
        "when-justified",
        "Which of the following is a **justified** use of `let assert`? (External-input failures are data; violations of your own invariants are bugs.)",
        [
          "Parsing a user-entered string into a number",
          "Taking the head of a 3-element list you just built in your own code",
          "Reading in a config file",
          "Interpreting a network response",
        ],
        1,
        "Right! A 3-element list you just built yourself is never empty — if it were, that's a bug in your code, not data.",
        [
          #(
            0,
            "User input is **data** that can be wrong at any time — handle it with `Result`.",
          ),
          #(
            2,
            "A config file can be missing or corrupted — it's external, a failure you can handle.",
          ),
          #(
            3,
            "A network response comes from outside, so failure is a normal possibility — handle it with `Result`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_assert_test() -> Lesson {
  Lesson(
    id: "l13c-assert-test",
    unit_id: "u13-intentional-crash",
    title: "assert and testing — when crashing is the right call",
    emits_tags: [Concept("let-assertions"), Tricky("crash-vs-result")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`assert` (v1.11+) asserts a **Bool expression**. If it's true, it passes silently; if it's false, it crashes with a rich message *that even includes the values on both sides*.\n\nLet me let you in on a secret: the hidden grader for every `write` exercise you solve on this platform is built from exactly this `assert`.",
      ),
      predict(
        "assert-passes",
        "Both `assert`s are true, so they pass. If execution reaches the last line, what gets printed?",
        "pub fn total(xs: List(Int)) -> Int {\n  list.fold(xs, 0, fn(acc, x) { acc + x })\n}\n\npub fn main() {\n  assert total([1, 2, 3]) == 6\n  assert total([]) == 0\n  io.println(int.to_string(total([1, 2, 3])))\n}",
        ["`6`", "`0`", "nothing is printed (crash)", "`True`"],
        0,
        "Right! Both assertions are true so they pass without obstruction, and the last line prints `total([1, 2, 3])` = 6.",
        [
          #(
            1,
            "The last line prints `total([1, 2, 3])`, not `total([])` — that's 6.",
          ),
          #(
            2,
            "Both assertions are true, so it doesn't crash — it runs to the end.",
          ),
          #(
            3,
            "It prints the value of `total(...)`, not a comparison result — that's 6.",
          ),
        ],
      ),
      Prose(
        "assert-fails",
        "What if `total([])` weren't 0 in `assert total([]) == 0`? `assert` would discover it's **false** and crash with a message saying \"the left side is this value, the right side is that value.\" That's why it's perfect for tests — it shows you exactly what went wrong.",
      ),
      mcq(
        "assert-on-false",
        "What happens when an `assert` expression evaluates to **false**?",
        [
          "Returns `False`",
          "Crashes with a message containing the values from both sides",
          "Just moves on to the next line",
          "Produces a compile error",
        ],
        1,
        "Right! When it's false, it crashes immediately with a rich message containing the left- and right-side values.",
        [
          #(
            0,
            "`assert` doesn't return a value — it's a tool that crashes when the expression is false.",
          ),
          #(2, "It only moves on when true — when false, it stops."),
          #(3, "It compiles fine — the false verdict happens at runtime."),
        ],
      ),
      mcq(
        "tool-choice",
        "When the value a function receives is \"external input that can fail,\" which is the right tool?",
        [
          "Force it open with `let assert`",
          "Block it with `panic`",
          "Treat the failure as data with `Result`",
          "Leave it as `todo`",
        ],
        2,
        "Right! Failure of a value from outside is a normal-case **data** — handle it with `Result`. This distinction is what this whole unit is about.",
        [
          #(
            0,
            "Using `let assert` on a handleable failure kills the program even on a normal failure.",
          ),
          #(
            1,
            "`panic` is for \"impossible\" things — failure of external input is entirely possible.",
          ),
          #(
            3,
            "`todo` is just a marker for unfinished work, not a tool for handling failure.",
          ),
        ],
      ),
    ],
  )
}

fn unit_gleam_omits() -> Unit {
  let meta =
    UnitMeta(
      id: "u14-gleam-omits",
      title: "What Gleam Leaves Out — Mindset Shift II",
      order: 14,
      level: 4,
      concepts: [Concept("basics"), Tricky("capture-vs-currying")],
      prerequisites: ["u10-result-use", "u11-generics"],
      lesson_ids: [
        "l14-no-typeclass", "l14-no-currying", "l14-eager", "l14-no-exceptions",
      ],
    )
  let lessons = [
    lesson_no_typeclass(),
    lesson_no_currying(),
    lesson_eager(),
    lesson_no_exceptions(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u14-gleam-omits", lessons),
  )
}

fn lesson_no_typeclass() -> Lesson {
  Lesson(
    id: "l14-no-typeclass",
    unit_id: "u14-gleam-omits",
    title: "Why There Are No Type Classes",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "If you came from Haskell, the first thing you'll miss is **type classes**. Promises like `Ord`, `Eq`, and `Show` — \"this type can be compared\" — simply don't exist in Gleam.\n\nThe official FAQ gives three reasons — **confusing error messages**, **slower compile times**, and the **runtime cost** that comes with dispatch. Gleam left type classes out entirely to avoid all three.",
      ),
      Prose(
        "instead",
        "What Gleam gives you instead is simple: **state the behavior you need as a function and pass it in**.\n\nFor sorting, for example, there's no \"hidden `Ord` instance.\" `list.sort` takes the comparison function **directly as an argument**:\n\n```gleam\nlist.sort([3, 1, 2], by: int.compare)\n```\n\nWhat you compare by is right there in the code — no magic, no implicit dispatch.",
      ),
      predict(
        "sort-explicit",
        "What does this sort produce when you pass the comparison function directly?",
        "list.sort([3, 1, 2], by: int.compare)",
        ["`[1, 2, 3]`", "`[3, 2, 1]`", "`[3, 1, 2]`", "compile error"],
        0,
        "Right! You passed `int.compare` as an ascending comparator, so it's [1, 2, 3]. There's no hidden `Ord` — the function you name decides the order.",
        [
          #(
            1,
            "`int.compare` is ascending. For descending you have to flip it yourself, like `fn(a, b) { int.compare(b, a) }`.",
          ),
          #(
            2,
            "`sort` returns a new sorted list — the original order doesn't come back out.",
          ),
          #(
            3,
            "You passed a comparison function via `by:`, so it compiles fine — even without type classes, sorting works by passing a function.",
          ),
        ],
      ),
      Prose(
        "describe",
        "\"How to render this type as text\" (Haskell's `Show`) works the same way. Instead of an instance that gets called automatically per type, you **hand over the conversion function directly**. The `describe_all` below works for any type as long as it receives a `to_text` function — an explicit substitute for type classes.",
      ),
      predict(
        "describe-pass",
        "This code passes a function directly to turn each element into text. What's the result?",
        "fn describe_all(xs, to_text) {\n  list.map(xs, to_text)\n}\nfn coin_text(heads) {\n  case heads { True -> \"heads\"  False -> \"tails\" }\n}\n\ndescribe_all([True, False, True], coin_text)",
        [
          "`[\"heads\", \"tails\", \"heads\"]`",
          "`[\"tails\", \"heads\", \"tails\"]`",
          "`[True, False, True]`",
          "compile error (no Show instance)",
        ],
        0,
        "Exactly! You passed `coin_text` explicitly to turn each Bool into text — [\"heads\", \"tails\", \"heads\"]. This is how you inject behavior without type classes.",
        [
          #(
            1,
            "`True` is \"heads\" and `False` is \"tails\" — the first element `True` starts with \"heads\".",
          ),
          #(
            2,
            "`to_text` turns each element into a String, so the result is a list of strings, not a list of Bools.",
          ),
          #(
            3,
            "Gleam has no `Show` at all, but since you passed the conversion function **as an argument**, it compiles with no trouble.",
          ),
        ],
      ),
      mcq(
        "why-no-typeclass",
        "Which of these is NOT one of the reasons the official FAQ gives for Gleam having no type classes?",
        [
          "To avoid confusing compile error messages",
          "To keep compile times short",
          "To avoid the runtime cost of dispatch",
          "Because it gave up on type inference entirely",
        ],
        3,
        "Right! Gleam does type inference well — the reasons it left type classes out are error messages, compile times, and runtime cost.",
        [
          #(
            0,
            "This is one of the real reasons. Type classes often produce cryptic errors.",
          ),
          #(
            1,
            "This is a real reason too — instance resolution can slow down compilation.",
          ),
          #(
            2,
            "This is a valid reason as well — dynamic dispatch carries a runtime cost.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_no_currying() -> Lesson {
  Lesson(
    id: "l14-no-currying",
    unit_id: "u14-gleam-omits",
    title: "Why There's No Currying, and Capture",
    emits_tags: [Concept("basics"), Tricky("capture-vs-currying")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "In Haskell, `add 10` becomes \"a function that takes one argument\" — automatic **currying**. Gleam doesn't have that.\n\nIn Gleam, `add(10)` is not a function but a **\"too few arguments\" compile error**. You called a two-place function and filled only one slot.",
      ),
      predict(
        "map-missing-arg",
        "What happens if you fill only one slot of the two-argument function `add` and pass it to `list.map`?",
        "fn add(a, b) { a + b }\n\nlist.map([1, 2], add(10))",
        [
          "`[11, 12]`",
          "compile error (argument count mismatch)",
          "`[10, 10]`",
          "`[1, 2]`",
        ],
        1,
        "Right! `add(10)` is a call missing an argument, so it won't compile. Gleam has no automatic currying.",
        [
          #(
            0,
            "In Haskell, yes. Gleam has no automatic currying, so spell out the empty slot with `add(10, _)`.",
          ),
          #(
            2,
            "`add(10)` can't produce a value and is blocked at compile time — it never even runs.",
          ),
          #(
            3,
            "`add` isn't merely left unapplied; the call is a compile error, so [1, 2] doesn't come out unchanged either.",
          ),
        ],
      ),
      Prose(
        "capture",
        "What if you *really* want partial application? You make the intent explicit with **capture**.\n\n`add(10, _)` is a \"call with one slot left empty,\" shorthand for `fn(b) { add(10, b) }`. Exactly one hole `_`.\n\nThe key design intent: a mistake (forgetting an argument) and an intention (partial application) are **distinguished by syntax**. `add(10)` is a mistake; `add(10, _)` is intentional.",
      ),
      predict(
        "capture-map",
        "What's the result of this code, where capture makes the empty slot explicit?",
        "fn add(a, b) { a + b }\n\nlist.map([1, 2], add(10, _))",
        ["`[11, 12]`", "compile error", "`[10, 20]`", "`[1, 2]`"],
        0,
        "Exactly! `add(10, _)` is `fn(b) { add(10, b) }`, so it adds 10 to each element, giving [11, 12].",
        [
          #(
            1,
            "This time you filled the empty slot with `_`, so it's fine — no missing argument.",
          ),
          #(2, "It *adds* 10, it doesn't multiply: 1+10=11, 2+10=12."),
          #(
            3,
            "The capture is applied to each element, so the original doesn't come out unchanged — it's [11, 12].",
          ),
        ],
      ),
      Prose(
        "hole-position",
        "The **position** of the hole determines which argument gets left empty. Even for the same function, where you put `_` changes the result.",
      ),
      predict(
        "hole-position",
        "You want to append `!` *after* each string. What's the result of this capture?",
        "list.map([\"a\", \"b\"], string.append(_, \"!\"))",
        [
          "`[\"a!\", \"b!\"]`",
          "`[\"!a\", \"!b\"]`",
          "`[\"a\", \"b\"]`",
          "compile error",
        ],
        0,
        "Right! `append(_, \"!\")` leaves the first argument (the element) empty, so \"!\" is appended *after* each element — [\"a!\", \"b!\"].",
        [
          #(
            1,
            "That's the result of `string.append(\"!\", _)`. The hole's position decides which argument is left empty.",
          ),
          #(
            2,
            "`append` actually attaches \"!\", so the original doesn't come out unchanged.",
          ),
          #(
            3,
            "With a single `_` leaving the first argument empty, it's a valid capture and compiles fine.",
          ),
        ],
      ),
      mcq(
        "capture-type",
        "When `add` is `fn(Int, Int) -> Int`, what is the type of the capture `add(10, _)`?",
        ["`fn(Int) -> Int`", "`Int`", "`fn(Int, Int) -> Int`", "`fn() -> Int`"],
        0,
        "Right! You left one slot empty, so it's a function taking the one remaining argument: `fn(Int) -> Int`.",
        [
          #(
            1,
            "A capture produces a *function*, not a value — you still have to fill the empty slot to get a result.",
          ),
          #(
            2,
            "The thing that takes both slots is `add` itself. The capture already filled one slot, so just one remains.",
          ),
          #(
            3,
            "There's one hole, so it takes one argument — it's not `fn() -> Int`.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_eager() -> Lesson {
  Lesson(
    id: "l14-eager",
    unit_id: "u14-gleam-omits",
    title: "No Laziness — Eager Evaluation",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Haskell is lazy — values are computed *when they're needed*. Gleam is the opposite: **eager**. Arguments passed to a function are all computed *before* the call begins.\n\nSo lazy structures like infinite sequences are the job of a library (`gleam_yielder`, not stdlib), not the language.",
      ),
      Prose(
        "eager-arg",
        "Why does this matter? Because the lazy-style expectation that \"if the condition is false, the expensive computation will be skipped\" doesn't hold in Gleam.\n\nLook at `bool.guard(when:, return:, otherwise:)`. Even when `when` is `False` and the `return` value will be *discarded*, an expression written directly in the `return:` slot is **already computed before the call**.",
      ),
      predict(
        "eager-side-effect",
        "Since `when: False`, the `return` value is discarded. But will `computed` be printed? (`expensive()` prints `computed` and returns a value.)",
        "fn expensive() {\n  io.println(\"computed\")\n  \"result\"\n}\n\nbool.guard(when: False, return: expensive(), otherwise: fn() { \"default\" })",
        [
          "`computed` is printed (eager)",
          "nothing is printed (lazy)",
          "`default` is printed",
          "compile error",
        ],
        0,
        "Right! Gleam is eager, so the `expensive()` in the `return:` slot already runs before the call — even though its value is discarded, the side effect (printing `computed`) still happens.",
        [
          #(
            1,
            "That's the behavior of a lazy language. Gleam computes all arguments before the call — `computed` gets printed.",
          ),
          #(
            2,
            "`expensive()` prints `computed`, not `default`. `\"default\"` is the value on the `otherwise` side.",
          ),
          #(
            3,
            "You passed valid arguments to `bool.guard`, so it compiles fine — the issue is the timing of evaluation.",
          ),
        ],
      ),
      Prose(
        "thunk",
        "So when you really do need deferral? **Wrap it in an anonymous function and pass that** (the `fn() { ... }` from U7). A function *value* is merely created; it doesn't run until it's called — this is the manual substitute for laziness.\n\n`bool.lazy_guard` takes both sides as `fn() -> a` thunks and only calls the one it actually selects.",
      ),
      predict(
        "thunk-defers",
        "This time you wrap `expensive` in `fn() { ... }` and pass it to `lazy_guard`. With `when: False`, what's the output?",
        "fn expensive() {\n  io.println(\"computed\")\n  \"result\"\n}\n\nbool.lazy_guard(\n  when: False,\n  return: fn() { expensive() },\n  otherwise: fn() { \"default\" },\n)",
        [
          "`default` (the expensive thunk is never called)",
          "`computed` and then `default`",
          "`computed`",
          "nothing is printed",
        ],
        0,
        "Exactly! Wrapped in a thunk, the `return` side isn't called, and since `when: False`, `otherwise` is selected, so only `default` comes out.",
        [
          #(
            1,
            "The `return` thunk is never even called, so `computed` isn't printed — only `default` comes out.",
          ),
          #(
            2,
            "Wrapped in `fn()`, `expensive` doesn't run — that's the whole point of deferral.",
          ),
          #(
            3,
            "`lazy_guard` calls the selected thunk, so `default` is definitely printed.",
          ),
        ],
      ),
      mcq(
        "lazy-where",
        "Where do \"lazy structures\" like infinite sequences live in Gleam?",
        [
          "built into the language",
          "the `gleam/lazy` module in stdlib",
          "a separate library `gleam_yielder` (not stdlib)",
          "a primitive type like `Int`",
        ],
        2,
        "Right! Lazy sequences are the domain of the separate library `gleam_yielder`, not the language — they're not even in the standard library.",
        [
          #(
            0,
            "The Gleam language itself is eager-only — laziness isn't built in.",
          ),
          #(
            1,
            "There's no stdlib module like `gleam/lazy`. Laziness comes from an external library.",
          ),
          #(
            3,
            "Lazy sequences aren't a primitive type but a data structure provided by a library.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_no_exceptions() -> Lesson {
  Lesson(
    id: "l14-no-exceptions",
    unit_id: "u14-gleam-omits",
    title: "Exceptions, Mutation, Macros — The Consistency of Absence",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Finally, let's wrap it all up together. The remaining three things Gleam left out — **exceptions**, **mutation**, and **macros** — come from the same philosophy: \"remove hidden control flow and hidden state so you can trust the code exactly as you read it.\"",
      ),
      Prose(
        "no-exceptions",
        "**There are no exceptions.** Operations that can fail **return a Result** instead of throwing. Even dividing by zero is not a crash but an `Error`:\n\n```gleam\nint.divide(10, 0)  // Error(Nil)\nint.divide(10, 2)  // Ok(5)\n```\n\nSince failure shows up in the type, the call site *must* handle it with `case` or `use` — you can't forget and skip past it.",
      ),
      predict(
        "div-zero-result",
        "Does dividing by zero throw an exception? What's the value of this expression?",
        "int.divide(10, 0)",
        ["`Error(Nil)`", "runtime exception (crash)", "`0`", "`Ok(0)`"],
        0,
        "Right! Gleam has no exceptions, so dividing by zero returns `Error(Nil)` — it doesn't throw.",
        [
          #(
            1,
            "There are no exceptions at all — failure is *returned* as an `Error` value, not thrown.",
          ),
          #(
            2,
            "It's not just `0` but `Error(Nil)` wrapped in a `Result` — failure shows up in the type.",
          ),
          #(
            3,
            "Dividing by zero is a failure, not a success, so it's `Error(Nil)`, not `Ok`.",
          ),
        ],
      ),
      Prose(
        "no-mutation",
        "**There's no mutation.** Values are never changed in place. Even when you \"add\" an element to a list, the original stays as-is and a *new* list is created — internally it's immutable data with **structural sharing**, so it isn't expensive.",
      ),
      predict(
        "append-no-mutate",
        "After creating `ys`, what do you get if you print the original `xs`?",
        "let xs = [1, 2, 3]\nlet ys = list.append(xs, [4])\nxs",
        ["`[1, 2, 3]`", "`[1, 2, 3, 4]`", "`[4, 1, 2, 3]`", "`[4]`"],
        0,
        "Exactly! `append` only creates a *new* list (`ys`); the original `xs` is never changed — it's still [1, 2, 3].",
        [
          #(
            1,
            "That's the newly created `ys`. With no mutation, the original `xs` stays as [1, 2, 3].",
          ),
          #(
            2,
            "`append` attaches at the end, and on top of that it doesn't change the original — `xs` is [1, 2, 3].",
          ),
          #(
            3,
            "No element disappears from `xs` — it's immutable, so it stays exactly as it started.",
          ),
        ],
      ),
      Prose(
        "no-macros",
        "**There are no macros (yet) either.** The FAQ isn't firmly closed to macros — but it says it's only open to them **when they don't hurt readability and compile speed**. It's the same principle of wanting code to be \"exactly what it looks like.\"\n\nIn the end, the list of things left out — type classes, currying, laziness, exceptions, mutation, macros — isn't a grab-bag but **one consistent choice**.",
      ),
      mcq(
        "consistency",
        "What is the one consistent motivation running through all the \"omitted things\" this unit covered?",
        [
          "Remove hidden control flow, state, and dispatch so you can trust the code as you read it",
          "To match other languages' syntax exactly",
          "It was just deferred because the compiler is hard to implement",
          "Because it aims to be object-oriented rather than functional",
        ],
        0,
        "Right! Type classes (hidden dispatch), exceptions (hidden control flow), and mutation (hidden state) were all left out to make the code behave exactly as it looks — a consistent choice.",
        [
          #(
            1,
            "If anything, it deliberately *strips away* other languages' conventions — it's not trying to match them.",
          ),
          #(
            2,
            "It's a choice driven by design philosophy, not implementation difficulty — the FAQ states the reasons clearly.",
          ),
          #(
            3,
            "Gleam is a functional language — these choices *reinforce* the functional philosophy.",
          ),
        ],
      ),
    ],
  )
}

fn unit_capstone() -> Unit {
  let meta =
    UnitMeta(
      id: "u15-capstone",
      title: "Capstone",
      order: 15,
      level: 4,
      concepts: [Concept("basics")],
      prerequisites: [
        "u12-opaque-types", "u13-intentional-crash", "u14-gleam-omits",
      ],
      lesson_ids: [
        "l15-csv-parser", "l15-state-machine", "l15-otp-actor", "l15-next-steps",
      ],
    )
  let lessons = [
    lesson_csv_parser(),
    lesson_state_machine(),
    lesson_otp_actor(),
    lesson_next_steps(),
  ]
  Unit(
    meta: meta,
    lessons: lessons,
    checkpoint: checkpoint("u15-capstone", lessons),
  )
}

fn lesson_csv_parser() -> Lesson {
  Lesson(
    id: "l15-csv-parser",
    unit_id: "u15-capstone",
    title: "Capstone 1 — A One-Line CSV Parser",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "At last, the capstone. Let's weave together the tools you've learned so far into **one small program**.\n\nGoal: a function that takes a single CSV line like `\"lucy,8\"`, parses it into `Player(name, age)`, and on failure returns **an error that carries the reason**. What we'll bring to bear — custom types (U4), `Result` and error types (U9), `string.split`/`case` patterns (U3·U5), and `use` for assembly (U10).\n\n```gleam\nimport gleam/int\nimport gleam/string\n\npub type ParseError {\n  WrongFieldCount\n  BadAge\n}\n\npub type Player {\n  Player(name: String, age: Int)\n}\n\nfn parse_age(s: String) -> Result(Int, ParseError) {\n  case int.parse(s) {\n    Ok(n) -> Ok(n)\n    Error(_) -> Error(BadAge)\n  }\n}\n\nfn parse_line(line: String) -> Result(Player, ParseError) {\n  case string.split(line, \",\") {\n    [name, age_str] ->\n      case parse_age(age_str) {\n        Ok(age) -> Ok(Player(name: name, age: age))\n        Error(e) -> Error(e)\n      }\n    _ -> Error(WrongFieldCount)\n  }\n}\n```\n\nThe key is that we distinguish the two failure paths (wrong field count, age isn't a number) **by type**.",
      ),
      predict(
        "parse-happy",
        "A valid input. What is the value of `parse_line(\"lucy,8\")`?",
        "parse_line(\"lucy,8\")",
        [
          "`Ok(Player(name: \"lucy\", age: 8))`", "`Player(\"lucy\", 8)`",
          "`Ok(#(\"lucy\", 8))`", "`Error(BadAge)`",
        ],
        0,
        "Exactly! `split` produces two fields `[\"lucy\", \"8\"]`, and `parse_age(\"8\")` is `Ok(8)`, so it gets wrapped as `Ok(Player(...))`.",
        [
          #(
            1,
            "The success path always **wraps** its return in `Ok(...)` — the function's return type is `Result`.",
          ),
          #(2, "It builds the `Player` record we defined, not a tuple."),
          #(
            3,
            "`\"8\"` parses fine as a number, so it's a success, not `BadAge`.",
          ),
        ],
      ),
      Prose(
        "split-shape",
        "Why is the branch for `case string.split(line, \",\")` written as `[name, age_str]`? Because `string.split` returns a **list**. `\"lucy,8\"` becomes `[\"lucy\", \"8\"]` — exactly two elements. So the `[name, age_str]` pattern fits, and every other shape falls through to `_` and becomes `WrongFieldCount`.",
      ),
      predict(
        "split-result",
        "What is the result of this `string.split`?",
        "string.split(\"lucy,8\", \",\")",
        [
          "`[\"lucy\", \"8\"]`", "`#(\"lucy\", \"8\")`", "`\"lucy 8\"`",
          "`[\"lucy,8\"]`",
        ],
        0,
        "Right! `split` cuts on the separator and gives a **list of strings** — two elements, so it matches the `[name, age_str]` pattern.",
        [
          #(
            1,
            "It's a list, not a tuple — that's why we match it with the `[...]` pattern.",
          ),
          #(2, "`split` is a cutting function — it doesn't join."),
          #(
            3,
            "It's **split** on the separator `,`, so you get two elements — not one big piece.",
          ),
        ],
      ),
      predict(
        "parse-fewfields",
        "Not enough fields. What is the value of `parse_line(\"lucy\")`?",
        "parse_line(\"lucy\")",
        [
          "`Error(WrongFieldCount)`", "`Error(BadAge)`",
          "`Ok(Player(\"lucy\", 0))`", "`Error(Nil)`",
        ],
        0,
        "Exactly! `split(\"lucy\", \",\")` is `[\"lucy\"]` — one element, so it doesn't match `[name, age_str]` and falls into the `_` branch.",
        [
          #(
            1,
            "It never even reaches the age-parsing step — it's caught at the field count first.",
          ),
          #(
            2,
            "We don't fill in the missing value with 0 — a failure is reported as a failure.",
          ),
          #(
            3,
            "The key is that we distinguish the error as a **reasoned** `WrongFieldCount` rather than a vague `Nil`.",
          ),
        ],
      ),
      predict(
        "parse-badage",
        "The age isn't a number. What is the value of `parse_line(\"lucy,eight\")`?",
        "parse_line(\"lucy,eight\")",
        [
          "`Error(BadAge)`", "`Error(WrongFieldCount)`",
          "`Ok(Player(\"lucy\", 0))`", "`Ok(Player(\"lucy\", 8))`",
        ],
        0,
        "Right! There are 2 fields so that passes, but `int.parse(\"eight\")` is `Error(_)` → `parse_age` returns `BadAge`.",
        [
          #(
            1,
            "The field count is correct at 2 — where it gets stuck is the age-parsing step.",
          ),
          #(
            2,
            "We don't guess a number for `\"eight\"` and fill it in — we report the parse failure as is.",
          ),
          #(
            3,
            "`\"eight\"` doesn't parse as an integer — there's no `8` value coming out.",
          ),
        ],
      ),
      Prose(
        "use-assembly",
        "The nested `case` bothering you? If you split the two steps into small functions that each return a `Result`, you can assemble them flatly with `use` (U10). If any step is an `Error`, it **short-circuits immediately** and that error is returned as is.\n\n```gleam\nimport gleam/result\n\nfn parse_line(line: String) -> Result(Player, ParseError) {\n  use pair <- result.try(fields(line))\n  let #(name, age_str) = pair\n  use age <- result.try(parse_age(age_str))\n  Ok(Player(name: name, age: age))\n}\n```\n\nThe behavior is **exactly the same** as the nested-`case` version — it just got easier to read.",
      ),
      mcq(
        "use-shortcircuit",
        "In the `use` version above, if `fields(line)` returns `Error(WrongFieldCount)`, what happens to the following lines?",
        [
          "They don't run, and `Error(WrongFieldCount)` is returned immediately",
          "Execution continues with `age` filled in as `0`",
          "A runtime crash occurs",
          "The final `Ok(Player(...))` is returned as is",
        ],
        0,
        "Right! `result.try` short-circuits on the first `Error` — the later steps are skipped and that error becomes the function's result.",
        [
          #(
            1,
            "It doesn't fill the gap with a default — `use` stops when it meets a failure.",
          ),
          #(
            2,
            "This is normal `Result` flow, so it's not a crash — it returns the error **as a value**.",
          ),
          #(
            3,
            "To reach the final `Ok`, every step must be `Ok` — if any one is `Error`, you can't get there.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_state_machine() -> Lesson {
  Lesson(
    id: "l15-state-machine",
    unit_id: "u15-capstone",
    title: "Capstone 2 — A State Machine",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "The second capstone exercise is a **state machine**. You define states and events each as variants, and write a `(state, event) -> next state` transition function with `case`.\n\nExample: a turnstile that only opens when you insert a coin.\n\n```gleam\npub type State {\n  Locked\n  Unlocked\n}\n\npub type Event {\n  Coin\n  Push\n}\n\nfn next(state: State, event: Event) -> State {\n  case state, event {\n    Locked, Coin -> Unlocked\n    Locked, Push -> Locked\n    Unlocked, Coin -> Unlocked\n    Unlocked, Push -> Locked\n  }\n}\n```\n\n`case state, event` matches **two values at once**. 2 states × 2 events = 4 branches — the compiler checks that no combination is missing (exhaustiveness, U4).",
      ),
      predict(
        "next-coin",
        "You insert a coin into a locked turnstile. What is the value of `next(Locked, Coin)`?",
        "next(Locked, Coin)",
        ["`Unlocked`", "`Locked`", "`Coin`", "`Ok(Unlocked)`"],
        0,
        "Right! It matches the `Locked, Coin -> Unlocked` branch — the coin releases the latch.",
        [
          #(1, "Inserting a coin changes the state — it doesn't stay `Locked`."),
          #(2, "`next` returns the **next state** — not the event (`Coin`)."),
          #(
            3,
            "This transition function just returns a `State` — it doesn't wrap it in `Result`.",
          ),
        ],
      ),
      predict(
        "next-push-locked",
        "You just push a locked turnstile. What is the value of `next(Locked, Push)`?",
        "next(Locked, Push)",
        ["`Locked`", "`Unlocked`", "`Push`", "`Error(Locked)`"],
        0,
        "Exactly! `Locked, Push -> Locked` — pushing without a coin leaves it locked as is.",
        [
          #(
            1,
            "Pushing alone doesn't open it — you have to insert a coin to become `Unlocked`.",
          ),
          #(2, "The result is the next **state** — not the event."),
          #(
            3,
            "Being blocked is just a normal transition, not an error — it simply stays `Locked`.",
          ),
        ],
      ),
      Prose(
        "run-fold",
        "What if there are **multiple** events? Use `list.fold` (U8): start from an initial state and feed it the events one by one — the accumulator is the state itself.\n\n```gleam\nimport gleam/list\n\nfn run(state: State, events: List(Event)) -> State {\n  list.fold(events, state, fn(s, e) { next(s, e) })\n}\n```\n\nThe fact that fold's accumulator type can differ from the element type (U8) shines here — the accumulator is `State`, the elements are `Event`.",
      ),
      predict(
        "run-sequence",
        "Starting from locked, process 4 events in order. What is the value of `run(Locked, [Coin, Push, Push, Coin])`?",
        "run(Locked, [Coin, Push, Push, Coin])",
        [
          "`Unlocked`", "`Locked`", "`[Unlocked, Locked, Locked, Unlocked]`",
          "`Coin`",
        ],
        0,
        "Right! Locked →(Coin) Unlocked →(Push) Locked →(Push) Locked →(Coin) Unlocked. The final state is `Unlocked`.",
        [
          #(
            1,
            "The last event is `Coin`, so the lock is released — the end state is `Unlocked`.",
          ),
          #(
            2,
            "fold returns **only the final accumulator** — not a list of intermediate states.",
          ),
          #(3, "`run` returns the final **state** — not the event."),
        ],
      ),
      predict(
        "run-push-first",
        "This time, push and then coin. What is the value of `run(Locked, [Push, Coin])`?",
        "run(Locked, [Push, Coin])",
        ["`Unlocked`", "`Locked`", "`Error(Push)`", "`[Locked, Unlocked]`"],
        0,
        "Exactly! Locked →(Push) Locked →(Coin) Unlocked. The push first had no effect and stayed locked, then the coin releases it.",
        [
          #(
            1,
            "The coin was inserted last, so it gets released — it doesn't end at `Locked`.",
          ),
          #(
            2,
            "An out-of-order event is simply absorbed as \"stay in state\" — it's not an error.",
          ),
          #(
            3,
            "fold doesn't collect the intermediate steps — it gives only the **final state**.",
          ),
        ],
      ),
      mcq(
        "exhaustiveness",
        "What happens if you **delete** the `Unlocked, Push -> Locked` branch from the transition function?",
        [
          "Compile error — the compiler blocks it because there's an unmatched combination (Unlocked, Push)",
          "It compiles fine, and that combination is ignored at runtime when it arrives",
          "It compiles fine, and that combination automatically becomes `Unlocked` when it arrives",
          "Only a warning appears and compilation passes",
        ],
        0,
        "Right! A `case` must handle every combination exhaustively (exhaustiveness). Leave one out and the compile itself is rejected — it catches holes in your state machine at compile time.",
        [
          #(
            1,
            "Gleam has no \"ignore at runtime\" thing — a missing case blocks compilation.",
          ),
          #(
            2,
            "It doesn't auto-fill a missing branch with any value — you have to write them all out yourself.",
          ),
          #(
            3,
            "A missing case is an **error**, not a warning — compilation does not pass.",
          ),
        ],
      ),
    ],
  )
}

fn lesson_otp_actor() -> Lesson {
  Lesson(
    id: "l15-otp-actor",
    unit_id: "u15-capstone",
    title: "OTP and Actors — The Next World (Read-Only)",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "banner",
        "⚠️ **The code in this lesson does not run.** gleam_otp's actor is Erlang VM-only, so it can't run in the browser (the JS target). Because the Gleam compiler tracks per-target support at the expression level, code like this is rejected when compiled to JS.\n\nSo this lesson is a **read-and-understand** lesson — instead of predicting output, you solve concept questions only. It's a chance to take an early peek at what \"the next world\" looks like.",
      ),
      Prose(
        "what-is-actor",
        "Recall the state machine we just learned. `run` folded a list of events **all at once**. But a real server receives events spread over time, from many places at once.\n\nAn **actor** turns that state machine into a \"living process.\" It holds its own state, receives messages one at a time and processes them, then holds the next state and waits for the next message. You can send it messages, but you **cannot touch its state directly** — concurrency bugs (shared-memory races) are blocked at the source. It's the immutability and transition functions we learned, scaled up unchanged.",
      ),
      mcq(
        "actor-why-no-run",
        "Why can't the actor code in this lesson run in the browser?",
        [
          "gleam_otp is Erlang VM-only, and the compiler tracks the JS target's lack of support at the expression level",
          "Because there's a syntax error in the actor code",
          "Because the code is too long and freezes the browser",
          "Because Gleam doesn't run in the browser at all",
        ],
        0,
        "Right! Gleam compiles to two targets, Erlang and JavaScript, but OTP/actors are a feature of the Erlang VM, so they aren't supported on the JS target. The compiler tracks this per target.",
        [
          #(
            1,
            "It's not a syntax issue — it's because of a **target (runtime) difference**. The code itself is correct.",
          ),
          #(
            2,
            "It's not a length issue — it's an Erlang-only feature, so it doesn't compile to JS.",
          ),
          #(
            3,
            "Gleam runs fine in the browser via the JS target — the other lessons in this course are proof. It's just OTP that's Erlang-only.",
          ),
        ],
      ),
      mcq(
        "actor-vs-statemachine",
        "Compared to the `next`/`run` state machine we built in U15-②, what is the key difference of an actor?",
        [
          "An actor lives holding state and receives messages one at a time asynchronously, whereas `run` folds a list of events all at once",
          "An actor can freely reassign mutable variables",
          "An actor has no concept of state", "An actor can't use `case`",
        ],
        0,
        "Right! An actor turns a state machine into a \"living process\" — it receives messages one at a time over time and moves to the next state. The transition-function mindset is unchanged.",
        [
          #(
            1,
            "An actor is still immutable — it doesn't reassign state, it **returns** the next state.",
          ),
          #(
            2,
            "Holding state is the very essence of an actor — it's not that it has no state.",
          ),
          #(
            3,
            "Message handling inside an actor usually branches with `case` too — exactly what we learned.",
          ),
        ],
      ),
      mcq(
        "actor-shared-state",
        "Which is the best reason the actor model reduces concurrency bugs?",
        [
          "Other processes can't touch an actor's state directly and communicate only via messages, so shared-memory races disappear",
          "Because an actor forces only one program to run at a time",
          "Because using actors automatically makes all functions faster",
          "Because actors never raise errors",
        ],
        0,
        "Right! State is locked inside the actor and the outside only sends messages — the classic race condition of many processes touching the same memory at once structurally disappears. It's the power of immutability + message passing.",
        [
          #(
            1,
            "It's actually the opposite — the advantage is that many actors run **concurrently** and yet stay safe.",
          ),
          #(
            2,
            "An actor is a concurrency model, not a speed-guarantee tool — there's no guarantee it gets faster.",
          ),
          #(
            3,
            "Actors can fail too — OTP's philosophy is rather \"if it fails, a supervisor restarts it\" (connected to the crash mindset of U13).",
          ),
        ],
      ),
    ],
  )
}

fn lesson_next_steps() -> Lesson {
  Lesson(
    id: "l15-next-steps",
    unit_id: "u15-capstone",
    title: "Completion and Next Paths",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "congrats",
        "You've made it here. From values and immutability through functions, case, custom types, lists, higher-order functions, `Result`, `use`, opaque types, and intentional crashes — you've learned **how to think** in Gleam.\n\nThis final lesson has no code. It wraps up where to take what you've learned, and what your next paths are.",
      ),
      Prose(
        "paths",
        "Three recommended paths:\n\n- **The Exercism Gleam track** — solve small practice problems with mentor feedback. A place to write more by hand.\n- **CodeCrafters** — build your practical instincts with large projects like \"build your own Redis/Git.\"\n- **This platform's training mode** — rated puzzles, SRS review, and timed (Code Storm) run continuously. Themes you got wrong in lessons enter your personal retraining queue, so you'll meet them again.\n\nWhatever you choose, the key is to build small things often.",
      ),
      mcq(
        "next-handson",
        "If you want to \"solve more small practice problems while getting mentor feedback,\" which fits best?",
        [
          "The Exercism Gleam track", "CodeCrafters",
          "There's nowhere left to practice",
          "Just reading the official Erlang docs",
        ],
        0,
        "Right! Exercism's model is small practice problems + mentor review, so it fits \"writing more by hand\" best.",
        [
          #(
            1,
            "CodeCrafters leans toward building **large projects** yourself rather than small exercises.",
          ),
          #(
            2,
            "There are actually plenty of places to go — this lesson is that list.",
          ),
          #(
            3,
            "Reading docs is good too, but for the \"mentor feedback + practice problems\" condition, Exercism fits better.",
          ),
        ],
      ),
      mcq(
        "next-bigproject",
        "If you want to \"build something like Redis or Git from scratch yourself to grow practical instincts,\" then?",
        [
          "CodeCrafters", "The Exercism Gleam track",
          "Just repeating this platform's timed mode", "No path is recommended",
        ],
        0,
        "Right! CodeCrafters specializes in large project-style learning where you implement famous software step by step yourself.",
        [
          #(
            1,
            "Exercism centers on small practice problems, so it has a different feel from \"building large projects yourself.\"",
          ),
          #(
            2,
            "Timed mode is for fast reflex training — its purpose differs from implementing large projects.",
          ),
          #(
            3,
            "This very lesson is where the next paths are recommended — there are places to go.",
          ),
        ],
      ),
      mcq(
        "next-training",
        "If you want to steadily review themes you often got wrong in lessons (e.g., fold direction), what on this platform helps?",
        [
          "Training mode — themes you got wrong are served again via your personal retraining queue and SRS review",
          "The only way is to listen to every lesson again from the start",
          "Once you get a problem wrong, you can't see it again",
          "Training mode is only for new users",
        ],
        0,
        "Right! Wrong micro-exercises pile up in a failure log along with theme tags and come back through a personalized retraining queue (including SRS) — you'll meet your weak spots again, focused.",
        [
          #(
            1,
            "You don't need to listen to everything again — it's designed to let you pick out and review only weak themes.",
          ),
          #(
            2,
            "On the contrary, the core feature is putting wrong problems in a queue so you **meet them again**.",
          ),
          #(
            3,
            "Training mode runs continuously even after completion — anyone can keep using it.",
          ),
        ],
      ),
    ],
  )
}

// ── Generation helpers ─────────────────────────────────────────────────────
/// 객관식 개념 문제 (코드 없음). answer_idx는 0-기반 정답 인덱스.
fn mcq(
  id: String,
  prompt: String,
  choices: List(String),
  answer_idx: Int,
  correct_fb: String,
  wrong_fbs: List(#(Int, String)),
) -> LessonBlock {
  exercise(id, Mcq, prompt, "", choices, answer_idx, correct_fb, wrong_fbs, [])
}

/// 출력/값 예측 문제. starter에 보여줄 코드를 담는다.
fn predict(
  id: String,
  prompt: String,
  code: String,
  choices: List(String),
  answer_idx: Int,
  correct_fb: String,
  wrong_fbs: List(#(Int, String)),
) -> LessonBlock {
  exercise(
    id,
    Predict,
    prompt,
    code,
    choices,
    answer_idx,
    correct_fb,
    wrong_fbs,
    [],
  )
}

fn exercise(
  id: String,
  ptype: types.PuzzleType,
  prompt: String,
  code: String,
  choices: List(String),
  answer_idx: Int,
  correct_fb: String,
  wrong_fbs: List(#(Int, String)),
  tags: List(Tag),
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
    answer: option_some_int(answer_idx),
    test_code: option_none(),
    feedback: FeedbackMap(entries: entries),
    tags: tags,
  ))
}

/// 유닛 체크포인트 — 각 레슨의 첫 연습을 모아 임시 구성 (M1 UI 미연동, 데이터 유효성용).
fn checkpoint(unit_id: String, lessons: List(Lesson)) -> schema.Checkpoint {
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

fn option_some_int(i: Int) -> option.Option(String) {
  option.Some(int.to_string(i))
}

fn option_none() -> option.Option(String) {
  option.None
}
