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
      title: "값, 불변성, 표현식",
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
    title: "값과 let",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "프로그램은 결국 **값**을 다루는 일입니다. `1`, `3.14`, `\"안녕\"`, `True` — 이 모두가 값이에요.\n\nGleam에서는 `let`으로 값에 **이름**을 붙입니다. `let pi = 3.14`라고 쓰면 그 시점부터 `pi`라는 이름이 `3.14`를 가리킵니다.",
      ),
      mcq(
        "bind-syntax",
        "Gleam에서 값을 이름에 묶는 올바른 문법은 무엇일까요?",
        ["`x = 5`", "`let x = 5`", "`var x = 5`", "`const x = 5`"],
        1,
        "맞아요! Gleam은 함수 안에서 `let`으로만 바인딩합니다. `var`도 없고, 재대입도 없어요.",
        [
          #(0, "`=`만으로는 안 됩니다. 바인딩엔 반드시 `let`이 필요해요."),
          #(2, "Gleam에는 `var`가 없습니다 — 재할당이라는 개념 자체가 없으니까요."),
          #(3, "`const`는 모듈 최상위 상수용입니다. 함수 안의 바인딩은 `let`이에요."),
        ],
      ),
      Prose(
        "use-name",
        "이름을 붙이면 뒤에서 그 이름으로 값을 다시 꺼내 쓸 수 있습니다. 표현식 안에서 이름은 곧 그 값으로 치환된다고 생각하면 됩니다.",
      ),
      predict(
        "let-use",
        "아래 코드가 끝났을 때 `total`의 값은?",
        "let price = 100\nlet count = 3\nlet total = price * count",
        ["`3`", "`100`", "`300`", "`103`"],
        2,
        "정확해요! `price`는 100, `count`는 3 — `total`은 100 * 3 = 300입니다.",
        [
          #(0, "`count`(3)만 본 거예요. `total`은 `price * count`로 계산됩니다."),
          #(1, "`price`(100)만 본 거예요. `count`를 곱해야 합니다."),
          #(3, "`*`는 곱셈입니다 — 더하기(100+3)가 아니라 100*3 = 300이에요."),
        ],
      ),
    ],
  )
}

fn lesson_immutability() -> Lesson {
  Lesson(
    id: "l02-immutability",
    unit_id: "u01-values",
    title: "불변성과 shadowing",
    emits_tags: [Concept("basics"), Tricky("shadowing")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam에는 변수 \"수정\"이 없습니다. 한번 `let`으로 묶인 값은 절대 바뀌지 않아요 — 모든 것이 **불변(immutable)**입니다.\n\n그렇다면 \"값을 바꾸고 싶을 때\"는? 바꾸는 대신, **같은 이름에 다시 `let`**을 씁니다. 이러면 그 시점부터 새 값을 가리키는 새 바인딩이 이전 것을 가립니다 — 이를 **shadowing**이라 합니다. 값이 변한 게 아니라 이름이 새것을 가리킬 뿐이에요.",
      ),
      predict(
        "shadowing-value",
        "아래 코드가 끝났을 때 `x`의 값은?",
        "let x = 1\nlet x = x + 1\nlet x = x * 10",
        ["`2`", "`11`", "`20`", "`1`"],
        2,
        "정확해요! 1 → (1+1)=2 → (2*10)=20. 각 줄의 `let`이 그 시점의 `x`로 계산해 새 바인딩을 만듭니다.",
        [
          #(0, "두 번째 줄까지만 계산했어요. 세 번째 줄 `x * 10`도 적용됩니다."),
          #(1, "`x + 1 * 10`이 아니에요. 줄 단위로 차례대로 새 `x`가 묶입니다 — 2가 된 뒤 10을 곱해요."),
          #(3, "`x`는 마지막 `let`의 결과를 가리킵니다 — 1이 아니라 20."),
        ],
      ),
      Prose(
        "no-mutation",
        "주의: shadowing은 **재대입**과 다릅니다. `let x = ...`처럼 매번 `let`을 새로 쓰는 건 합법이지만, `x = x + 1`처럼 `let` 없이 다시 대입하는 건 Gleam에 아예 없는 문법이라 컴파일되지 않습니다.",
      ),
      mcq(
        "reassign-illegal",
        "이미 `let total = 0`으로 묶은 뒤, 다음 줄에 `total = total + 100`이라고 쓰면?",
        [
          "`total`이 100으로 바뀐다",
          "컴파일 에러 — Gleam엔 `let` 없는 재대입이 없다",
          "새 `total` 바인딩이 생긴다",
          "런타임에 에러가 난다",
        ],
        1,
        "맞아요! Gleam에는 재대입 연산자가 없습니다. 값을 \"갱신\"하려면 `let total = total + 100`처럼 새 `let`으로 이전 이름을 가리세요.",
        [
          #(0, "값을 직접 바꾸는 일은 Gleam에 없습니다 — 그 줄은 아예 컴파일되지 않아요."),
          #(2, "새 바인딩을 만들려면 앞에 `let`이 있어야 합니다. `let` 없는 줄은 합법 문법이 아니에요."),
          #(3, "런타임이 아니라 **컴파일 타임**에 막힙니다 — 실행조차 되지 않아요."),
        ],
      ),
      Prose(
        "capture",
        "불변성의 진짜 힘은 여기서 드러납니다. 어떤 이름이 함수 안에 **캡처(capture)**되면, 나중에 같은 이름을 shadowing해도 이미 캡처된 값은 영향받지 않습니다 — 값은 절대 변하지 않으니까요.",
      ),
      predict(
        "shadow-capture",
        "아래 코드에서 두 줄의 출력은 차례로 무엇일까요? (`f`는 만들어질 때의 `x`를 기억합니다)",
        "let x = 1\nlet f = fn() { x }\nlet x = x + 10\necho x\necho f()",
        [
          "`11` 그리고 `11`",
          "`11` 그리고 `1`",
          "`1` 그리고 `1`",
          "컴파일 에러",
        ],
        1,
        "정확해요! `f`는 첫 번째 `x`(=1)를 캡처했습니다. 세 번째 줄의 `let x`는 **새 바인딩**일 뿐, `f`가 본 값을 바꾸지 못해요. 그래서 11과 1.",
        [
          #(
            0,
            "shadowing은 mutation이 아니에요. `f`는 여전히 처음 캡처한 1을 봅니다 — 두 번째 출력은 1.",
          ),
          #(2, "첫 출력 `x`는 마지막 `let`이 가리키는 11입니다 — 1이 아니에요."),
          #(3, "같은 이름의 재-`let`(shadowing)은 합법입니다. 금지된 건 `let` 없는 재대입이에요."),
        ],
      ),
    ],
  )
}

fn lesson_int_float() -> Lesson {
  Lesson(
    id: "l03-int-float",
    unit_id: "u01-values",
    title: "Int와 Float는 남남",
    emits_tags: [Concept("ints"), Concept("floats")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam은 정수(`Int`)와 실수(`Float`)를 엄격히 구분합니다. 둘 사이의 **암묵적 변환이 없어요**.\n\n그래서 Float 연산자에는 점이 붙습니다: `+.`  `-.`  `*.`  `/.`  정수는 `+ - * /`를 그대로 씁니다.",
      ),
      predict(
        "int-div",
        "정수 나눗셈의 결과는? (Gleam의 `/`는 정수끼리면 몫만 남깁니다)",
        "10 / 3",
        ["`3.333`", "`3`", "`4`", "`3.0`"],
        1,
        "맞아요! 정수 나눗셈은 몫만 남깁니다 — 10 / 3 = 3.",
        [
          #(0, "그건 실수 나눗셈의 결과예요. `/`는 정수끼리면 몫만 줍니다."),
          #(2, "내림이지 올림이 아니에요. 10 / 3의 몫은 3."),
          #(3, "결과는 `Int` 값 3이지 `Float` 3.0이 아니에요. 타입이 다릅니다."),
        ],
      ),
      predict(
        "float-div",
        "실수 나눗셈의 결과는?",
        "10.0 /. 4.0",
        ["`2`", "`2.5`", "`2.0`", "컴파일 에러"],
        1,
        "정확해요! `/.`는 Float 나눗셈이라 2.5를 줍니다.",
        [
          #(0, "결과는 `Float`예요 — `2`(Int)가 아니라 `2.5`."),
          #(2, "10.0 /. 4.0 = 2.5입니다. 2.0이 아니에요."),
          #(3, "`/.`는 올바른 Float 연산자라 정상 컴파일됩니다."),
        ],
      ),
      Prose(
        "no-mixing",
        "정수와 실수를 한 연산에 **섞으면 컴파일되지 않습니다**. Gleam은 조용히 변환하지 않아요 — 변환이 필요하면 `int.to_float` 같은 함수로 명시해야 합니다.",
      ),
      mcq(
        "mixed-arith",
        "표현식 `1 + 2.0`을 Gleam이 어떻게 다룰까요?",
        ["`3.0`", "`3`", "컴파일 에러 (타입 불일치)", "`2.0`으로 반올림"],
        2,
        "맞아요! `Int`와 `Float`는 섞을 수 없어요 — 컴파일러가 타입 불일치(Type mismatch) 에러로 막습니다 — `Int`와 `Float`는 섞일 수 없어요.",
        [
          #(0, "암묵적 변환이 없어서 3.0이 되지 않아요 — 아예 컴파일이 안 됩니다."),
          #(1, "Int로 변환되지도 않습니다. 타입이 어긋나면 컴파일 에러예요."),
          #(3, "Gleam은 조용히 변환하지 않습니다 — 직접 `int.to_float(1)`을 써야 해요."),
        ],
      ),
      mcq(
        "fix-float-op",
        "`Float`를 받아 0.5를 더하려는 함수 본문 `x + 0.5`가 컴파일 에러(\"Use +. instead\")를 냅니다. 올바른 수정은?",
        ["`x +. 0.5`", "`x + 0.5.0`", "`x .+ 0.5`", "`x + int.to_float(0.5)`"],
        0,
        "맞아요! Float 덧셈 연산자는 점이 붙은 `+.`입니다. `x +. 0.5`로 고치면 됩니다.",
        [
          #(1, "`0.5.0` 같은 숫자 표기는 없습니다 — 연산자를 `+.`로 바꿔야 해요."),
          #(2, "점은 연산자 **뒤**에 붙습니다: `+.` `-.` `*.` `/.` — `.+`는 없는 문법이에요."),
          #(3, "`0.5`는 이미 `Float`라 변환이 불필요하고, 문제는 연산자(`+` → `+.`)에 있습니다."),
        ],
      ),
    ],
  )
}

fn lesson_expressions() -> Lesson {
  Lesson(
    id: "l04-expressions",
    unit_id: "u01-values",
    title: "모든 것이 표현식",
    emits_tags: [Concept("basics"), Tricky("expressions-everywhere")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam에는 \"문장(statement)\"이 없습니다. `case`도, 중괄호 블록 `{ ... }`도, 조건 분기도 전부 **값을 내는 표현식**이에요.\n\n그래서 다른 언어처럼 \"if 안에서 변수에 대입\"하지 않습니다. 대신 **표현식의 결과를 통째로 `let`에 묶습니다**.",
      ),
      predict(
        "block-value",
        "중괄호 블록도 표현식입니다 — 마지막 줄의 값이 블록 전체의 값이 돼요. `y`의 값은?",
        "let y = {\n  let a = 2\n  a + 3\n}",
        ["`5`", "`2`", "`3`", "`Nil`"],
        0,
        "정확해요! 블록의 마지막 표현식 `a + 3`(=5)이 블록 전체의 값이고, 그게 `y`에 묶입니다.",
        [
          #(1, "`a`(2)는 블록 중간 값이에요. 블록의 값은 **마지막 표현식**입니다."),
          #(2, "`3`은 리터럴일 뿐, `a + 3`이 계산되어 5가 됩니다."),
          #(3, "블록은 마지막 표현식의 값을 돌려줍니다 — `Nil`이 아니라 5예요."),
        ],
      ),
      Prose(
        "case-is-expression",
        "`case`도 값을 내는 표현식이라 그 결과를 바로 `let`에 묶을 수 있습니다. 가드(`if ...`)가 붙은 가지는 **위에서 아래로** 검사되어, 처음으로 참이 되는 가지가 선택됩니다.",
      ),
      predict(
        "grade-85",
        "아래 `grade` 함수에서 `grade(85)`의 값은?",
        "fn grade(score: Int) -> String {\n  case score {\n    s if s >= 90 -> \"A\"\n    s if s >= 80 -> \"B\"\n    _ -> \"F\"\n  }\n}\n\ngrade(85)",
        ["`\"A\"`", "`\"B\"`", "`\"F\"`", "`85`"],
        1,
        "맞아요! 가드는 위에서부터 검사됩니다. `85 >= 90`은 거짓이라 건너뛰고, `85 >= 80`은 참이라 \"B\"가 선택돼요.",
        [
          #(0, "`85 >= 90`은 거짓이라 첫 가지는 건너뜁니다 — 다음 가지로 내려가요."),
          #(2, "`_` 가지까지 가지 않습니다. `85 >= 80`이 참이라 그 위에서 멈춰요."),
          #(3, "`case`는 매칭된 입력이 아니라 가지의 **결과**를 돌려줍니다 — 85가 아니라 \"B\"."),
        ],
      ),
      predict(
        "grade-95",
        "같은 `grade` 함수에서 `grade(95)`의 값은?",
        "fn grade(score: Int) -> String {\n  case score {\n    s if s >= 90 -> \"A\"\n    s if s >= 80 -> \"B\"\n    _ -> \"F\"\n  }\n}\n\ngrade(95)",
        ["`\"A\"`", "`\"B\"`", "`\"F\"`", "컴파일 에러"],
        0,
        "정확해요! `95 >= 90`이 참이라 첫 가지가 선택되어 \"A\"입니다.",
        [
          #(1, "첫 가지 `s if s >= 90`이 이미 참이라 거기서 멈춥니다 — \"B\"까지 가지 않아요."),
          #(2, "`_`는 맨 아래 가지예요. 위에서 이미 매칭됐으니 도달하지 않습니다."),
          #(3, "정상 컴파일됩니다 — `_` 가지가 나머지 모든 경우를 받아 빠짐없이 다뤄요."),
        ],
      ),
    ],
  )
}

fn lesson_string_bool() -> Lesson {
  Lesson(
    id: "l05-string-bool",
    unit_id: "u01-values",
    title: "String과 Bool, 그리고 echo/io.println",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "남은 기본 타입 두 가지입니다. **`String`**은 큰따옴표로 감싼 글자들(`\"안녕\"`)이고, 이어붙일 때는 `<>` 연산자를 씁니다. **`Bool`**은 `True` 또는 `False`이며, `&&`(그리고), `||`(또는), `!`(부정)로 조합합니다.",
      ),
      predict(
        "string-concat",
        "문자열 이어붙이기 `<>`의 결과는?",
        "\"ab\" <> \"cd\"",
        ["`\"abcd\"`", "`\"ab cd\"`", "`\"cdab\"`", "`\"ab+cd\"`"],
        0,
        "맞아요! `<>`는 왼쪽 문자열 뒤에 오른쪽을 그대로 붙입니다 — \"abcd\".",
        [
          #(1, "`<>`는 사이에 공백을 넣지 않아요 — 그대로 붙여 \"abcd\"."),
          #(2, "순서가 뒤집히지 않습니다 — 왼쪽이 앞, 오른쪽이 뒤예요."),
          #(3, "`<>`는 연산 기호를 글자로 끼워넣지 않습니다 — 순수하게 이어붙여요."),
        ],
      ),
      predict(
        "bool-and",
        "Bool 연산 `True && False`의 값은?",
        "True && False",
        ["`True`", "`False`", "`Nil`", "컴파일 에러"],
        1,
        "정확해요! `&&`(AND)는 양쪽이 모두 `True`일 때만 `True`입니다 — 하나라도 `False`면 `False`.",
        [
          #(0, "`&&`는 둘 다 참일 때만 참이에요. 하나가 `False`라 결과는 `False`."),
          #(2, "`&&`의 결과는 항상 `Bool`입니다 — `Nil`이 아니라 `False`."),
          #(3, "`&&`는 두 `Bool`에 쓰는 올바른 연산자라 정상 컴파일됩니다."),
        ],
      ),
      predict(
        "bool-or",
        "Bool 연산 `False || True`의 값은?",
        "False || True",
        ["`True`", "`False`", "`Nil`", "컴파일 에러"],
        0,
        "맞아요! `||`(OR)는 한쪽이라도 `True`면 `True`입니다.",
        [
          #(1, "`||`는 하나라도 참이면 참이에요 — 오른쪽이 `True`라 결과는 `True`."),
          #(2, "`||`의 결과는 항상 `Bool`입니다 — `Nil`이 아니라 `True`."),
          #(3, "`||`는 두 `Bool`에 쓰는 올바른 연산자라 정상 컴파일됩니다."),
        ],
      ),
      Prose(
        "echo-vs-println",
        "값을 화면에 찍는 두 가지 방법이 있습니다. **`io.println`**은 `String`만 받아 그 글자를 그대로 출력합니다(`import gleam/io` 필요). **`echo`**는 디버그용 키워드로, **어떤 타입의 값이든** 받아 사람이 읽기 좋은 모양으로 찍어줍니다(import 불필요) — 그래서 `Int`나 `Bool`을 빠르게 들여다볼 때 편합니다.",
      ),
      mcq(
        "echo-or-println",
        "정수 `total` 하나를 별다른 import 없이, 가장 빠르게 화면에 찍어 확인하려면?",
        [
          "`io.println(total)`",
          "`echo total`",
          "`io.println(\"total\")`",
          "`print(total)`",
        ],
        1,
        "맞아요! `echo`는 어떤 타입이든 받고 import도 필요 없어 디버그에 안성맞춤입니다 — `Int`도 알아서 보기 좋게 찍어줘요.",
        [
          #(
            0,
            "`io.println`은 `String`만 받습니다. `Int`인 `total`을 넘기면 타입 에러예요 — `int.to_string`이 필요합니다.",
          ),
          #(2, "그러면 변수 값이 아니라 글자 `total`이 그대로 찍힙니다 — 우리가 원한 건 숫자 값이에요."),
          #(3, "Gleam에는 `print`라는 함수가 없습니다 — `io.println` 또는 `echo`를 씁니다."),
        ],
      ),
    ],
  )
}

// ── Unit 2: 함수와 파이프 ─────────────────────────────────────────

fn unit_functions_pipes() -> Unit {
  let meta =
    UnitMeta(
      id: "u02-functions-pipes",
      title: "함수와 파이프",
      order: 2,
      level: 1,
      concepts: [Concept("basics"), Concept("pipe-operator"), Concept("strings")],
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
    title: "함수 정의와 타입 표기",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "함수는 `pub fn 이름(인자: 타입) -> 반환타입 { 본문 }` 모양으로 정의합니다.\n\n예: `pub fn double(x: Int) -> Int { x * 2 }`\n\n인자마다 타입을 적고, `->` 뒤에 반환 타입을 적습니다. 타입 표기는 컴파일러가 추론해줄 때도 많지만, 함수의 '계약서' 역할을 하므로 top-level 함수에는 늘 붙이는 것이 관용입니다.",
      ),
      mcq(
        "return-type",
        "`pub fn double(x: Int) -> ??? { x * 2 }` 에서 `???`에 올 반환 타입은?",
        ["`Int`", "`Float`", "`String`", "`Bool`"],
        0,
        "맞아요! `*`는 Int 연산자이고, Int * Int의 결과는 Int입니다.",
        [
          #(
            1,
            "`*`는 Int 연산자예요. Float였다면 `*.`와 `2.0`이 필요합니다.",
          ),
          #(2, "숫자 곱셈의 결과가 문자열이 될 수는 없어요."),
          #(3, "곱셈 결과는 참/거짓이 아니라 수입니다."),
        ],
      ),
      Prose(
        "no-return",
        "Gleam에는 `return` 키워드가 **없습니다**. 함수 본문의 **마지막 표현식**이 곧 반환값입니다.\n\n```gleam\npub fn double(x: Int) -> Int {\n  x * 2\n}\n```\n\n`x * 2`가 마지막 표현식이므로 그대로 반환됩니다. 중간에 빠져나가는 early return도 없습니다 — 이는 뒤 유닛의 case 분기 사고로 이어지는 복선입니다.",
      ),
      predict(
        "last-expr",
        "`double(21)`의 값은? (`fn double(x: Int) -> Int { x * 2 }`)",
        "pub fn double(x: Int) -> Int {\n  x * 2\n}\n\n// double(21) 은?",
        ["`42`", "`21`", "`23`", "`2`"],
        0,
        "정확해요! 마지막 표현식 `x * 2` = 21 * 2 = 42가 그대로 반환됩니다.",
        [
          #(1, "입력 그대로가 아니라 `x * 2`가 반환돼요 — 21 * 2 = 42."),
          #(2, "`x * 2`는 곱셈이지 덧셈이 아니에요. 21 * 2 = 42."),
          #(3, "`2`는 곱하는 수일 뿐, 반환값은 `x * 2` = 42입니다."),
        ],
      ),
      mcq(
        "return-keyword",
        "Gleam 함수에서 값을 돌려주는 방식으로 옳은 것은?",
        [
          "`return x` 처럼 return 키워드를 쓴다",
          "본문의 마지막 표현식이 자동으로 반환값이 된다",
          "`yield x` 로 반환한다",
          "함수 이름에 값을 대입한다",
        ],
        1,
        "맞아요! Gleam엔 return이 없고, 마지막 표현식이 곧 반환값입니다.",
        [
          #(0, "Gleam에는 `return` 키워드 자체가 없습니다."),
          #(2, "`yield`는 Gleam 문법이 아니에요."),
          #(3, "함수 이름에 대입하는 방식은 Gleam에 없습니다 — 마지막 표현식이 반환값."),
        ],
      ),
    ],
  )
}

fn lesson_pipe() -> Lesson {
  Lesson(
    id: "l06-pipe",
    unit_id: "u02-functions-pipes",
    title: "파이프 |>",
    emits_tags: [Concept("pipe-operator"), Concept("strings")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`|>`(파이프) 연산자는 왼쪽 값을 오른쪽 함수의 **첫 번째 인자**로 넣어줍니다.\n\n`x |> f`  는  `f(x)`  와 같고,\n`x |> f(y)`  는  `f(x, y)`  와 같습니다. (왼쪽 값이 맨 앞 자리에 들어갑니다!)\n\n데이터가 왼쪽에서 오른쪽으로, 변환되는 순서대로 흐르는 것이 핵심입니다.",
      ),
      predict(
        "trim-upper",
        "이 파이프 체인의 값은?",
        "\"  lucy \"\n|> string.trim\n|> string.uppercase",
        ["`\"LUCY\"`", "`\"  LUCY \"`", "`\"lucy\"`", "`\"  lucy \"`"],
        0,
        "맞아요! 먼저 trim으로 공백을 없애 \"lucy\", 그 다음 uppercase로 \"LUCY\".",
        [
          #(
            1,
            "trim이 양 끝 공백을 먼저 제거해요. 공백이 남지 않습니다.",
          ),
          #(2, "uppercase가 대문자로 바꿔요 — 소문자로 남지 않습니다."),
          #(3, "두 변환 모두 적용됩니다 — trim과 uppercase를 거칩니다."),
        ],
      ),
      Prose(
        "first-arg",
        "파이프가 값을 **첫 번째 인자**에 넣는다는 점이 가장 헷갈리는 부분입니다.\n\n`string.append(첫째, 둘째)`는 `첫째` 뒤에 `둘째`를 이어붙입니다.\n그래서 `\"LUCY\" |> string.append(\"!\")` 는 `string.append(\"LUCY\", \"!\")` 가 되어 `\"LUCY!\"`가 됩니다 — `\"LUCY\"`가 첫 인자, `\"!\"`가 둘째 인자입니다.",
      ),
      predict(
        "append-pipe",
        "이 표현식의 값은?",
        "\"LUCY\" |> string.append(\"!\")",
        ["`\"LUCY!\"`", "`\"!LUCY\"`", "`\"LUCY\"`", "컴파일 에러"],
        0,
        "정확해요! 파이프가 \"LUCY\"를 첫 인자에 넣어 string.append(\"LUCY\", \"!\") → \"LUCY!\".",
        [
          #(
            1,
            "파이프는 왼쪽 값을 **첫째** 인자에 넣어요. `append(\"LUCY\", \"!\")`라서 `!`가 뒤에 붙습니다.",
          ),
          #(2, "`\"!\"`가 인자로 더해지므로 그대로가 아니라 \"LUCY!\"가 됩니다."),
          #(3, "올바른 파이프 호출이라 컴파일됩니다."),
        ],
      ),
      mcq(
        "pipe-meaning",
        "`x |> f(y)` 는 무엇과 같은가요?",
        ["`f(y, x)`", "`f(x, y)`", "`f(x)(y)`", "`x(f, y)`"],
        1,
        "맞아요! 파이프는 왼쪽 값 x를 첫 인자로 넣어 `f(x, y)`가 됩니다.",
        [
          #(0, "x는 **첫째** 인자로 들어가요 — `f(x, y)`이지 `f(y, x)`가 아닙니다."),
          #(2, "Gleam엔 커링이 없어요 — `f(x)(y)` 형태가 아닙니다."),
          #(3, "f가 함수이고 x가 그 첫 인자입니다 — x가 f를 호출하지 않아요."),
        ],
      ),
    ],
  )
}

fn lesson_nested_to_pipe() -> Lesson {
  Lesson(
    id: "l07-nested-to-pipe",
    unit_id: "u02-functions-pipes",
    title: "중첩 호출을 파이프로",
    emits_tags: [Concept("pipe-operator"), Concept("strings")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`c(b(a(x)))` 같은 중첩 호출은 **안쪽부터** 읽어야 합니다 — a 먼저, 그다음 b, 그다음 c. 읽는 순서와 실행 순서가 거꾸로죠.\n\n파이프로 바꾸면 `x |> a |> b |> c` 가 되어 **데이터가 변환되는 순서 그대로** 읽힙니다. 두 표현식은 완전히 같은 값을 냅니다.",
      ),
      predict(
        "nested-value",
        "이 중첩 호출의 값은?",
        "string.uppercase(string.trim(\"  hi \"))",
        ["`\"HI\"`", "`\"  HI \"`", "`\"hi\"`", "`\"  hi \"`"],
        0,
        "맞아요! 안쪽 trim이 \"hi\"를 만들고, 바깥 uppercase가 \"HI\"로 바꿉니다.",
        [
          #(1, "안쪽 trim이 먼저 공백을 제거해요 — 공백이 남지 않습니다."),
          #(2, "바깥 uppercase가 대문자로 바꿔요."),
          #(3, "두 함수가 모두 적용돼 \"HI\"가 됩니다."),
        ],
      ),
      Prose(
        "equivalence",
        "위의 `string.uppercase(string.trim(\"  hi \"))` 는 파이프로 이렇게 씁니다:\n\n```gleam\n\"  hi \"\n|> string.trim\n|> string.uppercase\n```\n\n같은 값(\"HI\")을 내지만, 가장 먼저 일어나는 일(trim)이 가장 위에 옵니다.",
      ),
      mcq(
        "rewrite",
        "`c(b(a(x)))` 를 파이프로 올바르게 옮긴 것은?",
        [
          "`x |> a |> b |> c`",
          "`x |> c |> b |> a`",
          "`c |> b |> a |> x`",
          "`a |> b |> c |> x`",
        ],
        0,
        "정확해요! 안쪽(가장 먼저 실행되는) a가 가장 앞에 오고, 바깥 c가 마지막입니다.",
        [
          #(1, "순서가 뒤집혔어요 — 가장 안쪽 a가 가장 먼저 와야 합니다."),
          #(2, "x는 시작 데이터라 맨 앞에 와야 해요."),
          #(3, "x는 함수가 아니라 흘려보낼 값이라 맨 앞에 둡니다."),
        ],
      ),
      predict(
        "shout-chain",
        "함수 `shout`이 아래처럼 정의됐을 때 `shout(\"  lucy \")`의 값은?",
        "pub fn shout(name: String) -> String {\n  name\n  |> string.trim\n  |> string.uppercase\n  |> string.append(\"!\")\n}\n\n// shout(\"  lucy \") 은?",
        ["`\"LUCY!\"`", "`\"!LUCY\"`", "`\"  LUCY !\"`", "`\"lucy!\"`"],
        0,
        "맞아요! trim→\"lucy\", uppercase→\"LUCY\", append(\"!\")→\"LUCY!\".",
        [
          #(
            1,
            "append는 뒤에 붙여요 — \"LUCY\" 다음에 \"!\"라서 \"LUCY!\"입니다.",
          ),
          #(2, "trim이 공백을 먼저 없애므로 공백이 남지 않아요."),
          #(3, "uppercase 단계가 대문자로 바꿉니다 — 소문자로 남지 않아요."),
        ],
      ),
    ],
  )
}

fn lesson_pipe_first() -> Lesson {
  Lesson(
    id: "l08-pipe-first",
    unit_id: "u02-functions-pipes",
    title: "파이프 우선 스타일과 한계",
    emits_tags: [Concept("pipe-operator"), Concept("strings")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam stdlib는 '파이프하기 좋게' 설계되어, 변환할 **데이터를 첫 번째 인자**로 받는 경우가 많습니다. 그래서 `string.trim`, `string.uppercase`, `string.replace`, `string.append` 모두 자연스럽게 파이프됩니다.\n\n`string.replace(문자열, 찾을것, 바꿀것)` 도 문자열이 첫 인자라 파이프에 잘 맞습니다.",
      ),
      predict(
        "replace-pipe",
        "이 표현식의 값은? (`string.replace`는 첫 인자 문자열에서 둘째를 셋째로 바꿉니다)",
        "\"a-b-c\" |> string.replace(\"-\", \" \")",
        ["`\"a b c\"`", "`\"a-b-c\"`", "`\"abc\"`", "`\"- -\"`"],
        0,
        "맞아요! \"a-b-c\"에서 모든 \"-\"를 \" \"로 바꿔 \"a b c\".",
        [
          #(1, "replace가 적용되므로 그대로 남지 않아요 — \"-\"가 공백이 됩니다."),
          #(2, "\"-\"를 빈 문자열이 아니라 공백 \" \"으로 바꿔요."),
          #(3, "글자 a,b,c는 그대로 남고 구분자만 바뀝니다."),
        ],
      ),
      Prose(
        "limits",
        "파이프 우선 스타일에도 한계가 있습니다. 파이프는 왼쪽 값을 **첫 번째** 인자에만 넣을 수 있어요. 만약 흘려보내는 값이 둘째·셋째 인자 자리에 들어가야 한다면 파이프만으로는 안 됩니다.\n\n그럴 땐 함수 캡처(`f(고정값, _)`)나 익명 함수를 쓰는데, 이는 뒤 유닛에서 배웁니다. 지금은 '파이프는 첫 인자 전용'이라는 한계만 기억하세요.",
      ),
      mcq(
        "pipe-limit",
        "파이프 `|>`의 한계로 옳은 설명은?",
        [
          "왼쪽 값을 항상 첫 번째 인자에만 넣을 수 있다",
          "한 번에 두 개까지만 연결할 수 있다",
          "Int에는 쓸 수 없다",
          "함수가 인자를 하나만 받아야 쓸 수 있다",
        ],
        0,
        "맞아요! 파이프는 왼쪽 값을 첫 인자에만 넣습니다. 다른 자리면 캡처가 필요해요.",
        [
          #(1, "연결 개수에 제한은 없어요 — 얼마든지 이어 쓸 수 있습니다."),
          #(2, "타입과 무관해요 — 어떤 값이든 파이프할 수 있습니다."),
          #(3, "인자가 여러 개여도 됩니다 — 나머지를 호출에 적어주면 됩니다(`f(_)` 형태 등)."),
        ],
      ),
      mcq(
        "non-first-arg",
        "흘려보낼 값이 함수의 **두 번째** 인자 자리에 들어가야 한다면 어떻게 할까요?",
        [
          "파이프만으로 충분하다",
          "함수 캡처 `f(고정값, _)`나 익명 함수가 필요하다",
          "불가능하므로 그 함수는 쓸 수 없다",
          "인자 순서를 자동으로 바꿔준다",
        ],
        1,
        "정확해요! 파이프는 첫 인자 전용이라, 다른 자리는 캡처나 익명 함수로 처리합니다.",
        [
          #(0, "파이프는 첫 인자에만 넣어요 — 둘째 자리엔 부족합니다."),
          #(2, "쓸 수 있어요 — 캡처/익명 함수로 자리를 맞추면 됩니다."),
          #(3, "Gleam은 인자 순서를 자동으로 바꾸지 않습니다."),
        ],
      ),
    ],
  )
}

// ── Unit 3: case와 분기 (사고 전환 I) ───────────────────────────

fn unit_case_branching() -> Unit {
  let meta =
    UnitMeta(
      id: "u03-case-branching",
      title: "case와 분기",
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
    title: "case 표현식 해부",
    emits_tags: [Concept("case-expressions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam에서 분기의 중심은 `case`입니다. 모양은 이렇습니다:\n\n```\ncase 검사할_값 {\n  패턴1 -> 결과1\n  패턴2 -> 결과2\n  _ -> 나머지_결과\n}\n```\n\n위에서 아래로 패턴을 하나씩 맞춰 보고, **처음으로 맞는 가지**의 결과가 곧 `case` 전체의 값이 됩니다. `case`는 문장이 아니라 **표현식**이라, 그 자리에 값 하나를 남깁니다.",
      ),
      predict(
        "case-basic-3",
        "이 case 표현식의 값은?",
        "case 3 {\n  1 -> \"하나\"\n  2 -> \"둘\"\n  _ -> \"많음\"\n}",
        ["\"하나\"", "\"둘\"", "\"많음\"", "3"],
        2,
        "맞아요! 3은 1도 2도 아니라 마지막 `_` 가지에 걸려 \"많음\"이 됩니다.",
        [
          #(0, "3은 1이 아니에요. case는 위에서부터 맞는 첫 가지를 찾습니다."),
          #(1, "3은 2도 아니에요. 둘 다 비껴서 `_`로 떨어집니다."),
          #(
            3,
            "case는 검사한 값 3이 아니라 맞은 가지의 *결과*를 돌려줘요 — \"많음\".",
          ),
        ],
      ),
      Prose(
        "literal-patterns",
        "패턴 자리에는 리터럴(`1`, `\"red\"`, `True` 등)을 그대로 쓸 수 있습니다. 검사하는 값이 그 리터럴과 같으면 그 가지가 선택됩니다.\n\n`_`(언더스코어)는 **어떤 값과도 맞는** 와일드카드입니다. 보통 맨 아래에 두어 \"나머지 전부\"를 받습니다.",
      ),
      predict(
        "case-string-match",
        "`light(\"green\")`의 값은?",
        "fn light(color: String) -> String {\n  case color {\n    \"red\" -> \"멈춤\"\n    \"green\" -> \"출발\"\n    _ -> \"주의\"\n  }\n}",
        ["\"멈춤\"", "\"출발\"", "\"주의\"", "\"green\""],
        1,
        "맞아요! \"green\" 리터럴 패턴이 맞아떨어져 \"출발\"이 됩니다.",
        [
          #(0, "\"멈춤\"은 \"red\" 가지의 결과예요. 입력은 \"green\"입니다."),
          #(
            2,
            "\"green\"은 두 번째 가지에서 이미 잡히므로 `_`까지 내려가지 않아요.",
          ),
          #(3, "case는 맞은 가지의 결과를 돌려줘요 — 입력 \"green\" 자체가 아니라 \"출발\"."),
        ],
      ),
      Prose(
        "bind-name",
        "패턴 자리에 `_` 대신 **이름**을 쓰면, 맞은 값이 그 이름에 묶입니다(바인딩). 그러면 결과 식에서 그 값을 쓸 수 있어요. `_`는 \"받지만 안 쓴다\", 이름은 \"받아서 쓴다\"는 차이입니다.",
      ),
      predict(
        "case-bind-var",
        "`describe(7)`의 값은?",
        "fn describe(n: Int) -> String {\n  case n {\n    0 -> \"zero\"\n    other -> \"got \" <> int.to_string(other)\n  }\n}",
        ["\"zero\"", "\"got 0\"", "\"got 7\"", "\"other\""],
        2,
        "정확해요! 7은 0이 아니라 `other`에 묶이고, 결과 식에서 그 값을 씁니다.",
        [
          #(0, "\"zero\"는 0일 때의 결과예요. 입력은 7입니다."),
          #(1, "`other`에는 입력 7이 묶입니다 — 0이 아니라 7이 들어가요."),
          #(3, "`other`는 값을 담는 이름일 뿐, 그 글자가 결과로 나오지 않아요."),
        ],
      ),
    ],
  )
}

fn lesson_guards_alternates() -> Lesson {
  Lesson(
    id: "l06-guards-alternates",
    unit_id: "u03-case-branching",
    title: "guard와 _, 대안 패턴",
    emits_tags: [
      Concept("case-expressions"), Tricky("branch-order"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "guards",
        "패턴만으로는 \"90 이상\" 같은 조건을 표현할 수 없습니다. 이때 **guard**를 씁니다: 패턴 뒤에 `if 조건`을 붙이면, 패턴이 맞고 그 조건도 참일 때만 가지가 선택됩니다.\n\n```\ncase score {\n  s if s >= 90 -> \"A\"\n  s if s >= 80 -> \"B\"\n  _ -> \"F\"\n}\n```\n\n가지는 **위에서 아래로** 순서대로 검사되고, 처음으로 통과한 가지가 이깁니다.",
      ),
      predict(
        "grade-guard",
        "`grade(85)`의 값은?",
        "fn grade(score: Int) -> String {\n  case score {\n    s if s >= 90 -> \"A\"\n    s if s >= 80 -> \"B\"\n    _ -> \"F\"\n  }\n}",
        ["\"A\"", "\"B\"", "\"F\"", "85"],
        1,
        "맞아요! 85는 90 미만이라 첫 가지를 통과 못 하고, 80 이상이라 \"B\"에서 멈춥니다.",
        [
          #(0, "guard는 위에서부터 검사해요. `85 >= 90`은 거짓이라 다음 가지로 내려갑니다."),
          #(2, "\"F\"까지 가려면 두 guard를 모두 통과 못 해야 해요. 85는 80 이상입니다."),
          #(3, "case는 검사한 숫자가 아니라 가지의 결과(\"B\")를 돌려줍니다."),
        ],
      ),
      Prose(
        "alternates",
        "여러 리터럴이 같은 결과로 가야 한다면, `1 | 2 | 3 ->`처럼 **대안 패턴**으로 한 가지에 묶을 수 있습니다. `|`는 \"또는\"으로 읽으세요 — 셋 중 어느 것이든 맞으면 그 가지가 선택됩니다.",
      ),
      predict(
        "alternate-pattern",
        "`size(2)`의 값은?",
        "fn size(n: Int) -> String {\n  case n {\n    1 | 2 | 3 -> \"작음\"\n    _ -> \"큼\"\n  }\n}",
        ["\"작음\"", "\"큼\"", "2", "\"1 | 2 | 3\""],
        0,
        "맞아요! 2는 `1 | 2 | 3` 중 하나라 \"작음\" 가지에 묶입니다.",
        [
          #(1, "\"큼\"은 1·2·3 어디에도 안 맞을 때예요. 2는 거기 포함됩니다."),
          #(2, "case는 검사한 값이 아니라 맞은 가지의 결과를 돌려줘요 — \"작음\"."),
          #(3, "`1 | 2 | 3`은 패턴이지 출력 문자열이 아니에요."),
        ],
      ),
      Prose(
        "order-trap",
        "가지 순서는 **의미를 가집니다**. `_`는 모든 값과 맞으므로, 만약 `_`를 맨 위에 두면 그 아래 가지들은 절대 도달하지 못합니다(죽은 코드). 이런 경우 Gleam 컴파일러는 \"Unreachable pattern\" 경고를 냅니다 — 경고도 읽는 습관을 들이세요.",
      ),
      predict(
        "reversed-guard-order",
        "가지 순서를 뒤집어 `_ -> \"F\"`를 맨 위에 둔 코드입니다. `grade(95)`의 값은?",
        "fn grade(score: Int) -> String {\n  case score {\n    _ -> \"F\"\n    s if s >= 90 -> \"A\"\n    s if s >= 80 -> \"B\"\n  }\n}",
        ["\"A\"", "\"B\"", "\"F\"", "컴파일 에러"],
        2,
        "맞아요! `_`가 맨 위라 95를 포함한 모든 값이 첫 가지에서 \"F\"로 끝납니다. 아래 두 가지는 죽은 코드(경고 발생).",
        [
          #(0, "95가 90 이상이긴 하지만, 그 가지에 닿기 전에 `_`가 먼저 다 잡아요."),
          #(1, "\"B\" 가지에도 닿지 못해요 — `_`가 위에서 모든 값을 가져갑니다."),
          #(
            3,
            "도달 불가 가지는 *경고*일 뿐 에러가 아니에요 — 컴파일은 되고 항상 \"F\"가 나옵니다.",
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
    title: "early return은 없다",
    emits_tags: [
      Concept("case-expressions"), Tricky("no-early-return"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "다른 언어의 `if (조건) return ...;` 같은 **조기 반환**은 Gleam에 없습니다. `return` 키워드 자체가 없어요.\n\n함수는 **하나의 표현식**이고, 모든 경로가 값 하나로 수렴합니다. 그래서 \"일찍 빠져나가는\" 분기는 사라지는 게 아니라, `case`의 **가지 하나**가 됩니다. 의사코드의 각 `return`을 case 가지로 옮긴다고 생각하세요.",
      ),
      Prose(
        "translate",
        "예를 들어 이런 명령형 의사코드를:\n\n```\nif n < 0: return \"negative\"\nif n == 0: return \"zero\"\nreturn \"positive\"\n```\n\nGleam에서는 case 하나로 모읍니다:\n\n```\nfn sign_label(n: Int) -> String {\n  case n {\n    _ if n < 0 -> \"negative\"\n    0 -> \"zero\"\n    _ -> \"positive\"\n  }\n}\n```\n\n각 `return`이 곧 하나의 가지입니다.",
      ),
      predict(
        "sign-negative",
        "`sign_label(-5)`의 값은?",
        "fn sign_label(n: Int) -> String {\n  case n {\n    _ if n < 0 -> \"negative\"\n    0 -> \"zero\"\n    _ -> \"positive\"\n  }\n}",
        ["\"negative\"", "\"zero\"", "\"positive\"", "-5"],
        0,
        "맞아요! -5는 첫 guard `n < 0`을 통과해 \"negative\"가 됩니다 — 명령형의 첫 return과 같습니다.",
        [
          #(1, "\"zero\"는 `0` 패턴 가지예요. -5는 0이 아닙니다."),
          #(2, "\"positive\"는 위 두 가지를 다 비껴야 나와요. -5는 첫 가지에서 잡힙니다."),
          #(3, "case는 검사한 숫자가 아니라 맞은 가지의 결과를 돌려줍니다."),
        ],
      ),
      predict(
        "sign-zero",
        "같은 `sign_label`에서 `sign_label(0)`의 값은?",
        "fn sign_label(n: Int) -> String {\n  case n {\n    _ if n < 0 -> \"negative\"\n    0 -> \"zero\"\n    _ -> \"positive\"\n  }\n}",
        ["\"negative\"", "\"zero\"", "\"positive\"", "0"],
        1,
        "정확해요! 0은 `n < 0`이 거짓이라 첫 가지를 비껴가고, `0` 패턴에 정확히 맞아 \"zero\"가 됩니다.",
        [
          #(0, "0은 음수가 아니에요 — `0 < 0`은 거짓이라 첫 가지를 통과 못 합니다."),
          #(2, "0은 마지막 `_`까지 가기 전에 `0` 패턴에서 먼저 잡힙니다."),
          #(3, "case는 검사한 값이 아니라 가지의 결과 \"zero\"를 돌려줍니다."),
        ],
      ),
      Prose(
        "redundant-bool",
        "조기 반환을 없애다 보면 또 다른 함정이 보입니다: **이미 Bool인 값을 다시 case로 풀어 `True -> True`, `False -> False`로 돌려주는** 코드입니다. 조건식 자체가 이미 우리가 원하는 Bool 값이므로, 그대로 돌려주면 됩니다.",
      ),
      mcq(
        "redundant-bool-spot",
        "다음 중 가장 비관용적(불필요하게 장황한) 코드는?",
        [
          "case n > 0 { True -> True False -> False }",
          "n > 0",
          "case n { _ if n > 0 -> True _ -> False }",
          "n >= 1",
        ],
        0,
        "맞아요! `n > 0`은 이미 Bool입니다. case로 풀어 `True -> True`로 되돌려주는 건 같은 값을 빙 둘러 만드는 군더더기예요.",
        [
          #(1, "`n > 0`은 가장 간결한 정답 형태예요 — 이미 Bool이라 그대로 돌려주면 됩니다."),
          #(2, "이건 조금 장황해도 (1)만큼 군더더기는 아니에요 — 진짜 군더더기는 Bool을 다시 case로 푸는 것."),
          #(3, "정수 입력에선 `n >= 1`도 `n > 0`과 같은 결과라 간결한 편이에요."),
        ],
      ),
    ],
  )
}

fn lesson_imperative_to_expr() -> Lesson {
  Lesson(
    id: "l08-imperative-to-expr",
    unit_id: "u03-case-branching",
    title: "명령형을 표현식으로",
    emits_tags: [
      Concept("case-expressions"), Tricky("no-early-return"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "이번 레슨은 사고를 한 번 더 전환합니다: **변수에 값을 대입했다가 if로 덮어쓰는** 명령형 습관을, **case 표현식의 결과를 곧장 쓰는** 표현식 사고로 바꿉니다.\n\n명령형에서는 \"빈 변수 → 조건마다 채우기\"였다면, Gleam에서는 \"모든 분기가 값을 내는 case 하나\"입니다. 변수에 담고 싶으면 `let x = case ... { ... }`처럼 case의 결과를 묶으면 됩니다.",
      ),
      predict(
        "fee-translate",
        "나이별 요금: 13세 미만 0, 65세 미만 1000, 그 외 500. `fee(70)`의 값은?",
        "fn fee(age: Int) -> Int {\n  case age {\n    a if a < 13 -> 0\n    a if a < 65 -> 1000\n    _ -> 500\n  }\n}",
        ["`0`", "`1000`", "`500`", "`70`"],
        2,
        "맞아요! 70은 `< 13`도 `< 65`도 거짓이라 마지막 `_` 가지의 500이 됩니다.",
        [
          #(0, "0은 13세 미만일 때예요. 70은 거기 해당하지 않습니다."),
          #(1, "1000은 65세 미만일 때예요. 70은 65 이상이라 다음 가지로 내려갑니다."),
          #(3, "case는 검사한 나이가 아니라 맞은 가지의 결과(500)를 돌려줍니다."),
        ],
      ),
      Prose(
        "multi-subject",
        "case는 **여러 값을 동시에** 검사할 수도 있습니다: `case a, b { ... }`처럼 쉼표로 묶고, 각 가지도 쉼표로 패턴을 나열합니다. 중첩 if 사다리를 평평한 한 case로 펴는 강력한 도구입니다.",
      ),
      predict(
        "fizzbuzz-translate",
        "`fizz(15)`의 값은?",
        "fn fizz(n: Int) -> String {\n  case n % 3, n % 5 {\n    0, 0 -> \"FizzBuzz\"\n    0, _ -> \"Fizz\"\n    _, 0 -> \"Buzz\"\n    _, _ -> \"기타\"\n  }\n}",
        ["\"FizzBuzz\"", "\"Fizz\"", "\"Buzz\"", "\"기타\""],
        0,
        "맞아요! 15는 3으로도 5로도 나누어떨어져 `0, 0`이 되고, 첫 가지 \"FizzBuzz\"에 맞습니다.",
        [
          #(1, "\"Fizz\"는 3으로만 나누어떨어질 때(`0, _`)예요. 15는 5로도 떨어집니다."),
          #(2, "\"Buzz\"는 5로만 떨어질 때(`_, 0`)예요. 15는 3으로도 떨어집니다."),
          #(3, "\"기타\"는 둘 다 안 떨어질 때예요. 15는 둘 다 떨어집니다 — 첫 가지가 이깁니다."),
        ],
      ),
      mcq(
        "let-case-bind",
        "\"점수에 따라 등급 문자열을 변수 `label`에 담고 싶다\"를 Gleam답게 쓴 것은?",
        [
          "let label = case score { s if s >= 90 -> \"A\" _ -> \"F\" }",
          "var label; if score >= 90 { label = \"A\" }",
          "label = case score { ... }",
          "case score { s if s >= 90 -> let label = \"A\" }",
        ],
        0,
        "맞아요! case는 표현식이라 그 결과를 곧장 `let label =`로 묶을 수 있습니다 — 이것이 표현식 사고입니다.",
        [
          #(1, "Gleam에는 `var`도 빈 변수 후 대입도 없어요. case의 결과를 한 번에 묶습니다."),
          #(2, "바인딩에는 반드시 `let`이 필요해요 — `label = ...`만으로는 안 됩니다."),
          #(3, "가지 안에서 `let`만 하면 case가 값을 못 내요. 결과 자리에 값(\"A\")을 둬야 합니다."),
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
      title: "커스텀 타입과 레코드",
      order: 4,
      level: 2,
      concepts: [
        Concept("custom-types"), Concept("labelled-fields"),
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
    title: "variant로 상태 표현하기",
    emits_tags: [Concept("custom-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "지금까지는 Gleam이 준 타입(`Int`, `String`, `Bool` …)만 썼습니다. 이제 **나만의 타입**을 만듭니다.\n\n`pub type 이름 { ... }` 안에 가능한 **경우(variant)**를 하나씩 나열합니다. 예를 들어 신호등은 셋 중 하나죠:\n\n```gleam\npub type TrafficLight {\n  Red\n  Yellow\n  Green\n}\n```\n\n이제 `TrafficLight` 타입의 값은 오직 `Red`, `Yellow`, `Green` 셋뿐입니다 — \"불가능한 상태\"를 타입으로 아예 막는 것이 커스텀 타입의 핵심입니다.",
      ),
      mcq(
        "variant-meaning",
        "위 `TrafficLight` 정의에서 `Red`, `Yellow`, `Green`은 무엇일까요?",
        [
          "세 개의 서로 다른 타입",
          "`TrafficLight` 타입이 가질 수 있는 세 가지 값(variant)",
          "세 개의 변수",
          "세 개의 함수",
        ],
        1,
        "맞아요! 셋은 `TrafficLight`라는 **한 타입**이 가질 수 있는 값(variant)입니다 — 신호등은 이 셋 중 하나죠.",
        [
          #(0, "타입은 `TrafficLight` 하나뿐이에요. `Red`·`Yellow`·`Green`은 그 타입의 값들입니다."),
          #(2, "`let`으로 묶은 변수가 아니라, 타입 정의가 나열한 가능한 값들이에요."),
          #(3, "인자 없이 쓰는 이름이라 함수처럼 보이지만, 호출하지 않고 값 그 자체로 씁니다."),
        ],
      ),
      Prose(
        "match-variant",
        "커스텀 타입은 `case`와 단짝입니다. 값이 어떤 variant인지에 따라 분기하면 되죠. variant 이름을 패턴 자리에 그대로 적습니다.\n\n```gleam\npub fn next(light: TrafficLight) -> TrafficLight {\n  case light {\n    Red -> Green\n    Green -> Yellow\n    Yellow -> Red\n  }\n}\n```\n\n결과로 또 다른 `TrafficLight` 값을 돌려줄 수도 있다는 점에 주목하세요.",
      ),
      predict(
        "next-red",
        "위 `next` 함수에서 `next(Red)`의 값은?",
        "pub type TrafficLight {\n  Red\n  Yellow\n  Green\n}\n\npub fn next(light: TrafficLight) -> TrafficLight {\n  case light {\n    Red -> Green\n    Green -> Yellow\n    Yellow -> Red\n  }\n}\n\n// next(Red) 은?",
        ["`Red`", "`Yellow`", "`Green`", "`\"Green\"`"],
        2,
        "맞아요! `Red` 패턴에 맞아 결과로 `Green` variant를 돌려줍니다 — 빨강 다음은 초록.",
        [
          #(0, "입력 그대로가 아니에요. `Red` 가지의 **결과**인 `Green`이 나옵니다."),
          #(1, "`Yellow`는 `Green` 입력일 때의 결과예요. 입력은 `Red`입니다."),
          #(3, "`Green`은 문자열이 아니라 `TrafficLight`의 variant 값이에요 — 따옴표가 없습니다."),
        ],
      ),
      predict(
        "label-yellow",
        "신호를 한국어로 옮기는 `label`입니다. `label(Yellow)`의 값은?",
        "pub fn label(light: TrafficLight) -> String {\n  case light {\n    Red -> \"멈춤\"\n    Yellow -> \"주의\"\n    Green -> \"출발\"\n  }\n}\n\n// label(Yellow) 은?",
        ["`\"멈춤\"`", "`\"주의\"`", "`\"출발\"`", "`Yellow`"],
        1,
        "정확해요! `Yellow` 가지에 맞아 \"주의\"가 됩니다.",
        [
          #(0, "\"멈춤\"은 `Red` 가지의 결과예요. 입력은 `Yellow`입니다."),
          #(2, "\"출발\"은 `Green` 가지의 결과예요 — `Yellow`가 아니에요."),
          #(3, "`case`는 입력 variant가 아니라 맞은 가지의 결과(문자열)를 돌려줍니다."),
        ],
      ),
      predict(
        "coin-payout",
        "동전 던지기 보상입니다. `payout(Heads)`의 값은?",
        "pub type Coin {\n  Heads\n  Tails\n}\n\npub fn payout(c: Coin) -> Int {\n  case c {\n    Heads -> 100\n    Tails -> 0\n  }\n}\n\n// payout(Heads) 은?",
        ["`100`", "`0`", "`Heads`", "`200`"],
        0,
        "맞아요! `Heads` 가지에 맞아 100이 나옵니다.",
        [
          #(1, "0은 `Tails`일 때의 결과예요. 입력은 `Heads`입니다."),
          #(2, "`case`는 입력 variant가 아니라 가지의 결과(`Int`)를 돌려줍니다."),
          #(3, "두 보상을 더하지 않아요 — 맞은 한 가지의 값만 나옵니다."),
        ],
      ),
    ],
  )
}

fn lesson_records_labelled() -> Lesson {
  Lesson(
    id: "l10-records-labelled",
    unit_id: "u04-custom-types",
    title: "record와 labelled fields",
    emits_tags: [Concept("custom-types"), Concept("labelled-fields")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "variant가 데이터를 **담을** 수도 있습니다. 괄호 안에 `이름: 타입` 꼴의 **필드**를 적으면, 여러 값을 하나로 묶은 **record**가 됩니다.\n\n```gleam\npub type Player {\n  Player(name: String, score: Int, level: Int)\n}\n```\n\n타입 이름과 같은 `Player`가 값을 만드는 생성자예요. 만들 때는 `Player(name: \"lucy\", score: 10, level: 1)`처럼 **라벨**과 함께 적습니다. 만든 뒤 한 필드만 꺼낼 땐 `p.score`처럼 점으로 접근합니다.",
      ),
      predict(
        "field-access",
        "아래 코드에서 `p.score`의 값은?",
        "pub type Player {\n  Player(name: String, score: Int, level: Int)\n}\n\nlet p = Player(name: \"lucy\", score: 10, level: 1)\n// p.score 은?",
        ["`10`", "`1`", "`\"lucy\"`", "`Player`"],
        0,
        "맞아요! `p.score`는 `score` 필드 값인 10을 그대로 꺼냅니다.",
        [
          #(1, "`1`은 `level` 필드예요. `.score`는 score 자리를 봅니다."),
          #(2, "\"lucy\"는 `name` 필드예요. `.score`가 가리키는 건 10입니다."),
          #(3, "`p.score`는 record 전체가 아니라 한 필드(10)만 꺼냅니다."),
        ],
      ),
      Prose(
        "labelled-order",
        "필드에 **라벨**이 붙어 있으면 생성할 때 순서를 바꿔 적어도 됩니다 — 라벨이 어느 필드인지 말해주니까요. `Player(level: 1, name: \"lucy\", score: 10)`도 정의 순서대로 쓴 것과 똑같은 값을 만듭니다. 라벨은 \"세 번째 인자가 대체 뭐였지?\" 하는 혼란을 없애줍니다.",
      ),
      predict(
        "labelled-reorder",
        "라벨 순서를 바꿔 적은 코드입니다. `p.name`의 값은?",
        "pub type Player {\n  Player(name: String, score: Int, level: Int)\n}\n\nlet p = Player(level: 1, name: \"lucy\", score: 10)\n// p.name 은?",
        ["`\"lucy\"`", "`1`", "`10`", "컴파일 에러"],
        0,
        "정확해요! 라벨로 적었으니 순서는 상관없습니다 — `name`은 여전히 \"lucy\".",
        [
          #(1, "`1`은 `level` 값이에요. 라벨 `name:`이 가리키는 건 \"lucy\"입니다."),
          #(2, "`10`은 `score` 값이에요. `.name`은 \"lucy\"를 봅니다."),
          #(3, "라벨을 붙이면 순서를 바꿔도 정상 컴파일됩니다 — 라벨이 자리를 알려줘요."),
        ],
      ),
      Prose(
        "destructure",
        "record는 `case`나 `let`에서 **분해(destructure)**할 수도 있습니다. 패턴 자리에 `Point(x: x, y: y)`처럼 적으면 각 필드를 이름에 한 번에 묶습니다. 필요 없는 필드는 `_`로 버리면 돼요.",
      ),
      predict(
        "destructure-x",
        "record를 분해하는 코드입니다. 출력은?",
        "pub type Point {\n  Point(x: Int, y: Int)\n}\n\nlet p = Point(x: 3, y: 7)\ncase p {\n  Point(x: x, y: _) -> echo x\n}",
        ["`3`", "`7`", "`10`", "`Point(3, 7)`"],
        0,
        "맞아요! `Point(x: x, y: _)`가 `x` 필드(3)를 이름 `x`에 묶고, `y`는 `_`로 버립니다.",
        [
          #(1, "`7`은 `y` 필드예요 — 하지만 `_`로 버려서 쓰지 않았어요. 묶은 건 `x`(3)."),
          #(2, "두 필드를 더하지 않아요 — 분해는 각 필드를 따로 이름에 묶을 뿐입니다."),
          #(3, "분해 패턴은 record 전체가 아니라 꺼낸 필드 값(3)을 이름에 묶습니다."),
        ],
      ),
      mcq(
        "labelled-why",
        "record에 labelled fields(필드 라벨)를 쓰면 좋은 점으로 가장 옳은 것은?",
        [
          "성능이 빨라진다",
          "생성·분해 시 각 값이 어떤 필드인지 이름으로 분명해진다",
          "필드 개수를 무제한으로 만들 수 있다",
          "타입 표기를 생략할 수 있다",
        ],
        1,
        "맞아요! 라벨은 `Player(\"lucy\", 10, 1)`의 \"세 번째 1이 대체 뭐였지?\"를 없애줍니다 — 이름으로 의미가 분명해져요.",
        [
          #(0, "라벨은 가독성을 위한 것이지 성능과는 무관해요 — 같은 값을 만듭니다."),
          #(2, "필드 개수는 라벨과 무관해요. 라벨이 하는 일은 각 자리에 이름을 붙이는 것입니다."),
          #(3, "필드 타입 표기는 그대로 필요해요 — 라벨은 타입을 대신하지 않습니다."),
        ],
      ),
    ],
  )
}

fn lesson_exhaustiveness() -> Lesson {
  Lesson(
    id: "l11-exhaustiveness",
    unit_id: "u04-custom-types",
    title: "빠짐없이 다루기 — exhaustiveness",
    emits_tags: [Concept("case-expressions"), Tricky("exhaustiveness")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "커스텀 타입에 `case`를 쓸 때 Gleam의 진짜 안전망이 켜집니다: **모든 variant를 다뤄야 컴파일됩니다**. 하나라도 빠뜨리면 컴파일 자체가 안 돼요.\n\n```gleam\npub type Shape {\n  Circle(radius: Float)\n  Rectangle(width: Float, height: Float)\n}\n\npub fn area(shape: Shape) -> Float {\n  case shape {\n    Circle(radius: r) -> 3.14159 *. r *. r\n    Rectangle(width: w, height: h) -> w *. h\n  }\n}\n```\n\n넓이는 Float 연산이라 `*.`을 씁니다. 패턴 안에서 `radius: r`은 그 필드를 이름 `r`에 묶어 결과 식에서 쓰게 해줘요.",
      ),
      predict(
        "area-circle",
        "위 `area`에서 `area(Circle(radius: 2.0))`의 값은?",
        "pub type Shape {\n  Circle(radius: Float)\n  Rectangle(width: Float, height: Float)\n}\n\npub fn area(shape: Shape) -> Float {\n  case shape {\n    Circle(radius: r) -> 3.14159 *. r *. r\n    Rectangle(width: w, height: h) -> w *. h\n  }\n}\n\n// area(Circle(radius: 2.0)) 은?",
        ["`12.56636`", "`6.28318`", "`4.0`", "`12`"],
        0,
        "맞아요! 3.14159 *. 2.0 *. 2.0 = 12.56636. `r`에 2.0이 묶여 반지름의 제곱에 파이를 곱합니다.",
        [
          #(1, "그건 3.14159 *. 2.0(지름 곱)이에요. 넓이는 반지름을 **두 번** 곱합니다 — r *. r."),
          #(2, "4.0은 2.0 *. 2.0(r 제곱)일 뿐, 파이(3.14159)를 아직 안 곱했어요."),
          #(3, "결과는 `Float`라 `12`(Int)가 아니라 `12.56636`입니다 — 타입이 달라요."),
        ],
      ),
      Prose(
        "inexhaustive",
        "만약 `Rectangle` 가지를 지우면 어떻게 될까요? Gleam은 다음과 같은 컴파일 에러를 냅니다:\n\n```\nerror: Inexhaustive patterns\n\nThis case expression does not have a pattern for all possible values.\nThe missing patterns are:\n\n    Rectangle(width:, height:)\n```\n\n컴파일러가 **정확히 빠진 variant를 짚어줍니다**. 이것이 안전망입니다: 나중에 `Triangle`을 추가하면, 이 `case`를 포함해 고쳐야 할 모든 곳을 컴파일러가 알려줘요.",
      ),
      mcq(
        "missing-pattern",
        "`Rectangle` 가지를 지운 `area`를 컴파일하면 \"Inexhaustive patterns\" 에러가 납니다. 이 에러를 가장 올바르게 고치는 방법은?",
        [
          "`Rectangle(width: w, height: h) -> w *. h` 가지를 추가한다",
          "`_ -> 0.0` 가지를 추가한다",
          "`case`를 `if`로 바꾼다",
          "`Rectangle` variant를 타입 정의에서 지운다",
        ],
        0,
        "맞아요! 빠진 variant를 명시적으로 다루는 게 정답입니다 — 컴파일러가 짚어준 `Rectangle`을 그대로 추가하세요.",
        [
          #(1, "컴파일은 되지만 함정이에요. `_`는 exhaustiveness 검사를 꺼버려서, 나중에 `Triangle`을 추가해도 컴파일러가 침묵합니다 — variant를 명시하세요."),
          #(2, "Gleam엔 `if` 문이 따로 없고, 문제는 분기 도구가 아니라 빠진 가지예요 — `Rectangle` 가지를 추가하면 됩니다."),
          #(3, "그러면 사각형을 표현할 수 없게 됩니다 — 다루는 게 목적이지 타입에서 지우는 게 아니에요."),
        ],
      ),
      mcq(
        "wildcard-trap",
        "exhaustiveness를 만족시키려고 모든 case 끝에 `_ -> ...`를 습관처럼 붙이는 것이 위험한 이유는?",
        [
          "컴파일이 느려져서",
          "`_`가 미래의 새 variant까지 조용히 삼켜, 컴파일러의 \"고칠 곳\" 경고를 꺼버려서",
          "`_`는 문법 오류라서",
          "런타임이 느려져서",
        ],
        1,
        "정확해요! variant를 추가했을 때 컴파일러가 알려주는 안전망이 `_` 때문에 작동하지 않습니다 — 새 variant가 말없이 `_`로 떨어져요.",
        [
          #(0, "컴파일 속도와는 무관해요. 문제는 미래의 안전망을 잃는다는 점입니다."),
          #(2, "`_`는 정상 문법이에요 — 위험한 건 문법이 아니라 '모든 미래 변경을 삼킨다'는 점입니다."),
          #(3, "런타임 성능 문제가 아니라, 컴파일 타임 검사를 무력화한다는 점이 문제예요."),
        ],
      ),
      predict(
        "area-rectangle",
        "같은 `area`에서 `area(Rectangle(width: 3.0, height: 4.0))`의 값은?",
        "pub fn area(shape: Shape) -> Float {\n  case shape {\n    Circle(radius: r) -> 3.14159 *. r *. r\n    Rectangle(width: w, height: h) -> w *. h\n  }\n}\n\n// area(Rectangle(width: 3.0, height: 4.0)) 은?",
        ["`12.0`", "`7.0`", "`12`", "`14.0`"],
        0,
        "맞아요! `Rectangle` 가지가 `w *. h` = 3.0 *. 4.0 = 12.0을 돌려줍니다.",
        [
          #(1, "7.0은 3.0 +. 4.0(더하기)이에요. 넓이는 곱(`*.`)이라 12.0입니다."),
          #(2, "결과는 `Float`라 `12`(Int)가 아니라 `12.0`이에요 — 타입이 달라요."),
          #(3, "14.0은 둘레의 절반 같은 값이에요. 넓이는 w *. h = 12.0입니다."),
        ],
      ),
    ],
  )
}

fn lesson_record_update() -> Lesson {
  Lesson(
    id: "l12-record-update",
    unit_id: "u04-custom-types",
    title: "record update — '수정'의 정체",
    emits_tags: [Concept("custom-types"), Tricky("record-update-copy")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "record의 한 필드만 바꾸고 싶을 때, Gleam은 `Player(..p, level: p.level + 1)`이라는 **record update** 문법을 줍니다. \"`p`의 나머지 필드는 그대로 두고 `level`만 새 값으로\"라는 뜻이에요.\n\n```gleam\npub type Player {\n  Player(name: String, score: Int, level: Int)\n}\n\npub fn level_up(p: Player) -> Player {\n  Player(..p, level: p.level + 1)\n}\n```\n\n그런데 여기서 U1의 불변성이 다시 등장합니다: 이 문법은 `p`를 **바꾸지 않습니다**. 바뀐 값을 가진 **새 record**를 만들 뿐이에요(나머지는 구조를 공유해 저렴합니다).",
      ),
      predict(
        "level-up-both",
        "아래 코드에서 `p1.level`과 `p2.level`은 각각 무엇일까요?",
        "pub fn level_up(p: Player) -> Player {\n  Player(..p, level: p.level + 1)\n}\n\nlet p1 = Player(name: \"lucy\", score: 10, level: 1)\nlet p2 = level_up(p1)\n// p1.level 과 p2.level 은?",
        ["`1` 그리고 `2`", "`2` 그리고 `2`", "`1` 그리고 `1`", "`2` 그리고 `1`"],
        0,
        "정확해요! `level_up`은 새 record를 만들어 돌려줄 뿐, `p1`은 영원히 level 1입니다 — `p2`만 2예요.",
        [
          #(1, "record update는 원본을 건드리지 않습니다. `p1`은 그대로 level 1 — '바꾼다'가 아니라 '바뀐 복사본을 만든다'로 읽으세요."),
          #(2, "`p2`는 `level + 1`을 적용한 새 record라 2예요 — 둘 다 1은 아닙니다."),
          #(3, "순서가 뒤바뀌었어요. 원본 `p1`이 1, 새로 만든 `p2`가 2입니다."),
        ],
      ),
      mcq(
        "update-semantics",
        "`Player(..p, level: p.level + 1)` 표현식이 실제로 하는 일은?",
        [
          "`p`의 `level` 필드를 제자리에서 1 증가시킨다",
          "`p`는 그대로 두고, `level`만 바뀐 새 `Player` record를 만든다",
          "`p`를 삭제하고 다시 만든다",
          "`level`을 0으로 초기화한다",
        ],
        1,
        "맞아요! record update는 원본을 복사하듯 새 값을 만듭니다 — U1의 불변성이 데이터 구조로 확장된 거예요.",
        [
          #(0, "Gleam엔 제자리 수정(mutation)이 없습니다 — `p`는 절대 안 바뀌고 새 record가 생겨요."),
          #(2, "삭제·재생성이 아니라, `p`는 그대로 살아 있고 그 위에 새 복사본을 얹습니다."),
          #(3, "`..p`는 나머지 필드를 `p`에서 그대로 가져와요 — 초기화가 아니라 보존입니다."),
        ],
      ),
      predict(
        "update-name-untouched",
        "record update 후에도 원본의 다른 필드는 안전합니다. 출력은?",
        "let p1 = Player(name: \"lucy\", score: 10, level: 1)\nlet p2 = level_up(p1)\necho p1.name",
        ["`\"lucy\"`", "`\"\"`", "`Nil`", "컴파일 에러"],
        0,
        "맞아요! `level_up`은 `p1`을 전혀 건드리지 않으므로 `p1.name`은 여전히 \"lucy\"입니다.",
        [
          #(1, "필드가 지워지지 않아요 — 원본 `p1`은 만들어진 그대로 보존됩니다."),
          #(2, "`p1.name`은 `String` 값(\"lucy\")이에요 — `Nil`이 아닙니다."),
          #(3, "정상 컴파일·실행됩니다 — 원본 필드 접근은 아무 문제 없어요."),
        ],
      ),
      Prose(
        "any-type",
        "record update는 어떤 record에도 쓸 수 있고, 한 번에 여러 필드를 바꿀 수도 있습니다. `Config(..base, width: 1920, height: 1080)`처럼요. 여기서도 규칙은 같습니다: `base`는 그대로, 명시한 필드만 새 값을 가진 **새 record**가 나옵니다.",
      ),
      predict(
        "config-update",
        "여러 필드를 한 번에 바꾸는 코드입니다. 출력은?",
        "pub type Config {\n  Config(width: Int, height: Int, fullscreen: Bool)\n}\n\nlet base = Config(width: 800, height: 600, fullscreen: False)\nlet big = Config(..base, width: 1920, height: 1080)\necho int.to_string(big.width) <> \" \" <> int.to_string(base.width)",
        ["`\"1920 800\"`", "`\"1920 1920\"`", "`\"800 1920\"`", "`\"800 800\"`"],
        0,
        "정확해요! `big.width`는 새 값 1920, `base.width`는 건드리지 않아 그대로 800 — 원본은 안전합니다.",
        [
          #(1, "`base`는 record update의 영향을 받지 않아요 — `base.width`는 여전히 800입니다."),
          #(2, "순서가 뒤바뀌었어요. 식은 `big.width`(1920)를 먼저, `base.width`(800)를 뒤에 출력합니다."),
          #(3, "`big`은 `width: 1920`으로 바꾼 새 record예요 — `big.width`는 800이 아니라 1920입니다."),
        ],
      ),
    ],
  )
}

fn lesson_bool_vs_custom() -> Lesson {
  Lesson(
    id: "l13-bool-vs-custom",
    unit_id: "u04-custom-types",
    title: "Bool 대신 커스텀 타입",
    emits_tags: [Concept("custom-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "상태가 둘뿐일 땐 `Bool`을 쓰고 싶어집니다 — `is_admin: Bool`처럼요. 하지만 상태가 셋 이상으로 늘어나면 `Bool`로는 표현이 안 됩니다. 게다가 `True`/`False`는 \"무엇이 참인지\"를 코드에서 읽을 수 없어요(이른바 *boolean blindness*).\n\n그래서 Gleam에서는 **의미 있는 이름의 variant**를 즐겨 만듭니다.\n\n```gleam\npub type Access {\n  Guest\n  Member\n  Admin\n}\n```\n\n`Admin`은 그 자체로 의미가 분명하고, 나중에 `Moderator`를 끼워 넣어도 컴파일러가 고칠 곳을 다 짚어줍니다.",
      ),
      mcq(
        "why-custom",
        "권한을 `is_admin: Bool` 대신 커스텀 타입 `Access { Guest Member Admin }`로 표현하면 좋은 이유로 옳은 것은?",
        [
          "Bool보다 항상 빠르다",
          "상태가 셋 이상이어도 표현되고, 각 상태의 의미가 이름으로 드러난다",
          "`case`를 쓸 필요가 없어진다",
          "메모리를 덜 쓴다",
        ],
        1,
        "맞아요! `Bool` 두 값으로는 셋 이상을 못 담고, `True`/`False`는 의미를 숨깁니다. variant는 의미와 확장성을 모두 줍니다.",
        [
          #(0, "속도가 목적이 아니에요 — 표현력과 의미의 명확함이 핵심입니다."),
          #(2, "오히려 `case`로 각 variant를 다루게 되고, exhaustiveness 안전망까지 얻습니다."),
          #(3, "메모리 절약이 목적이 아니라, '불가능한 상태를 막고 의미를 드러내는' 것이 목적입니다."),
        ],
      ),
      predict(
        "can-delete-member",
        "권한별 삭제 가능 여부입니다. `can_delete(Member)`의 값은?",
        "pub type Access {\n  Guest\n  Member\n  Admin\n}\n\npub fn can_delete(a: Access) -> Bool {\n  case a {\n    Admin -> True\n    Member -> False\n    Guest -> False\n  }\n}\n\n// can_delete(Member) 은?",
        ["`True`", "`False`", "`Member`", "컴파일 에러"],
        1,
        "맞아요! `Member` 가지는 `False`를 돌려줍니다 — 회원은 삭제 권한이 없네요.",
        [
          #(0, "`True`는 `Admin`일 때예요. 입력은 `Member`라 `False`입니다."),
          #(2, "`case`는 입력 variant가 아니라 가지의 결과(`Bool`)를 돌려줍니다."),
          #(3, "세 variant를 모두 다뤄 exhaustive하니 정상 컴파일됩니다."),
        ],
      ),
      Prose(
        "states-as-type",
        "boolean blindness가 특히 아픈 곳은 \"진행 중\" 같은 중간 상태입니다. 연결 상태를 `is_connected: Bool`로 두면 \"연결 중\"을 표현할 자리가 없어요. variant면 깔끔합니다:\n\n```gleam\npub type Connection {\n  Connecting\n  Connected\n  Disconnected\n}\n```",
      ),
      predict(
        "connection-message",
        "연결 상태별 메시지입니다. `message(Connected)`의 값은?",
        "pub type Connection {\n  Connecting\n  Connected\n  Disconnected\n}\n\npub fn message(c: Connection) -> String {\n  case c {\n    Connecting -> \"연결 중...\"\n    Connected -> \"연결됨\"\n    Disconnected -> \"끊김\"\n  }\n}\n\n// message(Connected) 은?",
        ["`\"연결 중...\"`", "`\"연결됨\"`", "`\"끊김\"`", "`Connected`"],
        1,
        "정확해요! `Connected` 가지에 맞아 \"연결됨\"이 됩니다 — `Bool`이었다면 이 세 상태를 못 담았을 거예요.",
        [
          #(0, "\"연결 중...\"은 `Connecting` 가지예요 — 입력은 `Connected`입니다."),
          #(2, "\"끊김\"은 `Disconnected` 가지예요 — `Connected`가 아니에요."),
          #(3, "`case`는 입력 variant가 아니라 맞은 가지의 결과(문자열)를 돌려줍니다."),
        ],
      ),
      mcq(
        "boolean-blindness",
        "함수 시그니처 `fn render(loading: Bool, error: Bool) -> ...`의 문제로 가장 옳은 것은?",
        [
          "Bool은 함수 인자로 쓸 수 없다",
          "`(True, True)`처럼 모순된 '불가능한 상태'가 타입상 허용되고, 의미가 이름에 드러나지 않는다",
          "인자가 두 개라서 느리다",
          "Bool은 `case`에 못 쓴다",
        ],
        1,
        "맞아요! 로딩이면서 동시에 에러인 `(True, True)`는 말이 안 되는데도 타입이 막지 못합니다 — 상태 하나를 variant 타입으로 묶으면 불가능한 조합을 아예 없앨 수 있어요.",
        [
          #(0, "`Bool`은 인자로 잘 쓰입니다 — 문제는 여러 `Bool`이 모순 상태를 허용한다는 점이에요."),
          #(2, "인자 개수와 속도는 무관해요 — 핵심은 불가능한 상태를 타입이 못 막는다는 점입니다."),
          #(3, "`Bool`도 `case True/False`로 잘 다룰 수 있어요 — 그게 문제가 아닙니다."),
        ],
      ),
    ],
  )
}

fn unit_lists_recursion() -> Unit {
  let meta =
    UnitMeta(
      id: "u05-lists-recursion",
      title: "리스트와 재귀",
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
    title: "List(a)와 prepend",
    emits_tags: [Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "리스트는 같은 타입의 값을 **순서대로** 담는 자료구조입니다. `[1, 2, 3]`은 `List(Int)`, `[\"a\", \"b\"]`는 `List(String)`이에요. 한 리스트 안의 원소는 **모두 같은 타입**이어야 합니다.\n\n빈 리스트는 `[]`입니다. 이 작은 빈 리스트가 나중에 재귀의 **출발점**이 되니 눈여겨봐 두세요.",
      ),
      mcq(
        "list-homogeneous",
        "다음 중 Gleam에서 올바른 리스트는?",
        [
          "`[1, \"a\", True]`",
          "`[1, 2, 3]`",
          "`{1, 2, 3}`",
          "`(1, 2, 3)`",
        ],
        1,
        "맞아요! 리스트의 모든 원소는 같은 타입이어야 합니다 — `[1, 2, 3]`은 전부 `Int`라 `List(Int)`예요.",
        [
          #(0, "타입이 섞였어요 — `Int`, `String`, `Bool`을 한 리스트에 담을 수 없습니다. 모두 같은 타입이어야 해요."),
          #(2, "`{...}`는 리스트 문법이 아니에요 — 리스트는 대괄호 `[...]`를 씁니다."),
          #(3, "`(...)`는 튜플 문법이에요. 리스트는 `[...]`입니다."),
        ],
      ),
      Prose(
        "prepend",
        "리스트 **앞**에 원소 하나를 붙이는 것을 prepend라고 합니다. `[head, ..tail]` 문법으로, 기존 리스트(tail) 앞에 새 원소(head)를 얹어 **새 리스트**를 만들어요.\n\n`let xs = [1, 2, 3]` 일 때 `[0, ..xs]` 는 `[0, 1, 2, 3]` 입니다. 중요한 점: `xs`는 바뀌지 않습니다 — 앞 유닛에서 배운 불변성 그대로, 새 리스트가 만들어질 뿐이에요. prepend는 기존 리스트를 그대로 재사용하므로 매우 빠릅니다(O(1)).",
      ),
      predict(
        "prepend-front",
        "`xs`가 `[1, 2, 3]`일 때, `[0, ..xs]`의 값은?",
        "let xs = [1, 2, 3]\nlet ys = [0, ..xs]\n// ys 는?",
        ["`[0, 1, 2, 3]`", "`[1, 2, 3, 0]`", "`[0, [1, 2, 3]]`", "`[1, 2, 3]`"],
        0,
        "정확해요! `..`는 새 원소를 **앞(head)**에 붙입니다 — `[0, 1, 2, 3]`.",
        [
          #(1, "prepend는 **앞**에 붙여요 — 뒤가 아니라 0이 맨 앞에 옵니다."),
          #(2, "중첩되지 않아요 — `..`는 tail을 펼쳐 평평한 `[0, 1, 2, 3]`을 만듭니다."),
          #(3, "`ys`는 새 리스트예요 — 0이 붙어 `[0, 1, 2, 3]`이 됩니다(`xs` 자체는 그대로지만)."),
        ],
      ),
      predict(
        "prepend-two",
        "`xs`가 `[3]`일 때, `[1, 2, ..xs]`의 값은?",
        "let xs = [3]\nlet ys = [1, 2, ..xs]\n// ys 는?",
        ["`[1, 2, 3]`", "`[3, 1, 2]`", "`[1, 2, [3]]`", "`[1, 2]`"],
        0,
        "맞아요! 앞쪽에 1, 2를 차례로 얹어 `[1, 2, 3]`이 됩니다 — `..` 뒤의 tail이 그대로 이어져요.",
        [
          #(1, "앞에 적은 `1, 2`가 먼저 오고, tail `[3]`이 뒤에 붙어 `[1, 2, 3]`이에요."),
          #(2, "tail은 통째로 한 원소가 되지 않아요 — 펼쳐져서 평평한 `[1, 2, 3]`이 됩니다."),
          #(3, "tail `[3]`의 원소도 포함돼요 — `[1, 2]`가 아니라 `[1, 2, 3]`입니다."),
        ],
      ),
    ],
  )
}

fn lesson_head_tail_pattern() -> Lesson {
  Lesson(
    id: "l05-head-tail-pattern",
    unit_id: "u05-lists-recursion",
    title: "[first, ..rest] — 리스트를 분해하는 패턴",
    emits_tags: [Concept("lists"), Tricky("empty-list-base-case")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "리스트를 **만드는** `[head, ..tail]` 문법은, `case`의 **패턴 자리**에서는 리스트를 **분해**하는 데 쓰입니다. 같은 모양이 방향만 반대로 동작해요.\n\n리스트가 가질 수 있는 모양은 단 두 가지입니다:\n- `[]` — 비어 있다\n- `[first, ..rest]` — 머리 `first` 하나와 나머지 `rest`(리스트)로 나뉜다\n\n이 두 패턴이 리스트의 모든 경우를 빠짐없이 덮습니다.",
      ),
      predict(
        "head-bind",
        "`[first, ..rest]` 패턴에서 `first`에는 머리 원소가 묶입니다. `first_or_zero([10, 20, 30])`의 값은?",
        "fn first_or_zero(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [first, ..rest] -> first\n  }\n}\n\n// first_or_zero([10, 20, 30]) 은?",
        ["`10`", "`30`", "`0`", "`[20, 30]`"],
        0,
        "맞아요! `first`에는 리스트의 **머리**(맨 앞 원소)인 10이 묶입니다.",
        [
          #(1, "`first`는 **맨 앞** 원소예요 — 마지막 30이 아니라 10입니다."),
          #(2, "0은 빈 리스트(`[]`)일 때의 결과예요 — 입력은 비어 있지 않습니다."),
          #(3, "`[20, 30]`은 `rest`(꼬리)예요 — 이 함수는 `first`를 돌려줍니다."),
        ],
      ),
      predict(
        "rest-bind",
        "같은 패턴에서 `rest`에는 머리를 뺀 나머지 리스트가 묶입니다. `drop_first([10, 20, 30])`의 값은?",
        "fn drop_first(xs: List(Int)) -> List(Int) {\n  case xs {\n    [] -> []\n    [first, ..rest] -> rest\n  }\n}\n\n// drop_first([10, 20, 30]) 은?",
        ["`[20, 30]`", "`[10, 20, 30]`", "`10`", "`[10]`"],
        0,
        "정확해요! `rest`는 머리 10을 뺀 나머지 — `[20, 30]`입니다.",
        [
          #(1, "`rest`는 머리를 **뺀** 부분이에요 — 10이 빠져 `[20, 30]`이 됩니다."),
          #(2, "`10`은 `first`(머리)예요 — 이 함수는 `rest`(꼬리 리스트)를 돌려줍니다."),
          #(3, "`rest`엔 20과 30이 모두 들어가요 — `[10]`이 아니라 `[20, 30]`입니다."),
        ],
      ),
      Prose(
        "two-cases",
        "두 패턴 `[]` 와 `[first, ..rest]` 는 리스트의 **모든 경우**를 덮습니다. 그래서 `case`로 리스트를 다룰 때 이 둘만 있으면 exhaustiveness(빠짐없음) 검사를 통과해요.\n\n핵심은 `[first, ..rest]` 가 리스트를 **한 겹 벗긴다**는 점입니다 — 머리 하나를 떼어내고, 더 짧은 `rest`를 남깁니다. 이 \"한 겹씩 줄어드는\" 성질이 다음 레슨의 재귀를 가능하게 합니다.",
      ),
      mcq(
        "list-shapes",
        "Gleam에서 리스트가 가질 수 있는 모양(패턴)을 모두 고른다면?",
        [
          "`[]` 와 `[first, ..rest]` 두 가지",
          "`[]` 한 가지뿐",
          "`[first, ..rest]` 한 가지뿐",
          "원소 개수마다 따로따로 — `[a]`, `[a, b]`, `[a, b, c]` ...",
        ],
        0,
        "맞아요! 리스트는 \"비었다(`[]`)\" 또는 \"머리 하나 + 나머지(`[first, ..rest]`)\" 두 모양뿐이라, 이 둘이 모든 경우를 덮습니다.",
        [
          #(1, "비어 있지 않은 리스트(`[1, 2]` 등)도 있어요 — `[first, ..rest]` 패턴이 더 필요합니다."),
          #(2, "빈 리스트 `[]`도 가능해요 — 그 경우를 빠뜨리면 exhaustiveness 검사를 통과 못 합니다."),
          #(3, "길이별로 나눌 필요가 없어요 — `[first, ..rest]` 하나가 길이 1 이상을 **모두** 덮습니다."),
        ],
      ),
      predict(
        "rebuild",
        "분해한 머리와 꼬리를 다시 붙이면 원래대로 돌아옵니다. `[1, ..[2, 3]]`의 값은?",
        "[1, ..[2, 3]]",
        ["`[1, 2, 3]`", "`[[1], 2, 3]`", "`[1, [2, 3]]`", "`[2, 3, 1]`"],
        0,
        "맞아요! 머리 1과 꼬리 `[2, 3]`을 합쳐 `[1, 2, 3]` — 분해의 반대 방향입니다.",
        [
          #(1, "머리는 중첩되지 않아요 — 1이 그냥 맨 앞 원소로 들어가 `[1, 2, 3]`이 됩니다."),
          #(2, "꼬리 `[2, 3]`은 통째로 한 원소가 되지 않아요 — 펼쳐져 `[1, 2, 3]`이 됩니다."),
          #(3, "`..`는 **앞**에 붙입니다 — 1이 맨 앞이라 `[1, 2, 3]`이에요."),
        ],
      ),
    ],
  )
}

fn lesson_first_recursion() -> Lesson {
  Lesson(
    id: "l05-first-recursion",
    unit_id: "u05-lists-recursion",
    title: "첫 재귀: 길이 세기와 합",
    emits_tags: [Concept("recursion"), Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam에는 `for`도 `while`도 **없습니다**. 그럼 리스트를 어떻게 훑을까요? 답은 **재귀**입니다: 머리 하나를 처리하고, **꼬리에 대해 자기 자신을 다시 부릅니다**.\n\n모든 재귀는 두 가지 질문으로 설계합니다:\n1. 가장 작은 입력(빈 리스트)이면 답이 뭔가? — **종료 조건(base case)**\n2. 머리 하나를 처리하고 나면, 남은 문제는 뭔가? — **재귀 단계**",
      ),
      Prose(
        "length-example",
        "리스트의 길이를 세는 함수를 봅시다:\n\n```gleam\npub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n```\n\n빈 리스트의 길이는 0(종료 조건). 비어 있지 않으면 머리 하나(`+1`)에 **나머지의 길이**를 더합니다. 머리 값 자체는 안 쓰니 `_`로 받았어요.",
      ),
      predict(
        "length-3",
        "위 `length` 함수에서 `length([10, 20, 30])`의 값은?",
        "pub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n\n// length([10, 20, 30]) 은?",
        ["`3`", "`60`", "`0`", "`30`"],
        0,
        "맞아요! 1 + (1 + (1 + 0)) = 3. 머리를 하나씩 떼며 +1을 쌓고, 빈 리스트에서 0으로 마무리됩니다.",
        [
          #(1, "이 함수는 원소를 **세는** 거예요 — 더하는(10+20+30) 게 아니라 개수 3을 셉니다."),
          #(2, "0은 빈 리스트일 때예요 — 원소가 3개라 결과는 3입니다."),
          #(3, "마지막 원소(30)가 아니라 **개수**를 돌려줘요 — 3입니다."),
        ],
      ),
      predict(
        "length-empty",
        "같은 `length` 함수에서 `length([])`의 값은? (종료 조건이 곧 답의 씨앗입니다)",
        "pub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n\n// length([]) 은?",
        ["`0`", "`1`", "`Nil`", "컴파일 에러"],
        0,
        "정확해요! 빈 리스트는 첫 가지 `[] -> 0`에 바로 걸립니다 — 종료 조건이 0을 돌려줘요.",
        [
          #(1, "빈 리스트엔 원소가 없어요 — 길이는 1이 아니라 0입니다."),
          #(2, "`[] -> 0` 가지가 `Int` 0을 돌려줍니다 — `Nil`이 아니에요."),
          #(3, "정상 컴파일됩니다 — `[]`와 `[_, ..rest]`가 모든 경우를 덮어요."),
        ],
      ),
      Prose(
        "total-example",
        "같은 뼈대로 **합**도 구합니다. 이번엔 머리 값을 써야 하니 이름(`first`)으로 받습니다:\n\n```gleam\npub fn total(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [first, ..rest] -> first + total(rest)\n  }\n}\n```\n\n빈 리스트의 합은 0(종료 조건). 비어 있지 않으면 **머리 값** + **나머지의 합**입니다. `length`와 거의 같고, `1` 자리에 `first`만 들어갔어요.",
      ),
      predict(
        "total-sum",
        "위 `total` 함수에서 `total([2, 3, 5])`의 값은?",
        "pub fn total(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [first, ..rest] -> first + total(rest)\n  }\n}\n\n// total([2, 3, 5]) 은?",
        ["`10`", "`3`", "`0`", "`5`"],
        0,
        "맞아요! 2 + (3 + (5 + 0)) = 10. 머리 값을 차례로 더하고 빈 리스트에서 0으로 닫힙니다.",
        [
          #(1, "이건 합을 구하는 함수예요 — 개수(3)가 아니라 합 2+3+5 = 10입니다."),
          #(2, "0은 빈 리스트일 때의 종료값이에요 — 원소들의 합은 10입니다."),
          #(3, "마지막 원소(5)만이 아니라 **전부** 더해요 — 10입니다."),
        ],
      ),
    ],
  )
}

fn lesson_termination() -> Lesson {
  Lesson(
    id: "l05-termination",
    unit_id: "u05-lists-recursion",
    title: "종료 조건 — 재귀의 생명줄",
    emits_tags: [Concept("recursion"), Tricky("empty-list-base-case")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "재귀가 끝나려면 **매 호출마다 문제가 작아져서** 결국 종료 조건에 닿아야 합니다. 무한 재귀의 3대 원인은:\n1. **빈 리스트 케이스 누락** — `[]` 가지가 없다\n2. **같은 인자로 재호출** — `f(xs)`가 또 `f(xs)`를 부른다(작아지지 않음)\n3. **줄어들지 않는 인자** — `n` 대신 `n`을 넘긴다(`n - 1`이어야)\n\n다행히 (1)은 컴파일러가 막아줍니다 — `[]` 패턴이 없으면 Inexhaustive 에러가 나서, 컴파일러가 종료 조건을 **강제로 생각하게** 만들어요.",
      ),
      Prose(
        "countdown-example",
        "리스트가 아니라 숫자로도 재귀할 수 있습니다. `countdown`은 n부터 1까지 담은 리스트를 만들어요:\n\n```gleam\npub fn countdown(n: Int) -> List(Int) {\n  case n {\n    0 -> []\n    _ -> [n, ..countdown(n - 1)]\n  }\n}\n```\n\n종료 조건은 `0 -> []`. 재귀 단계는 `n`을 앞에 붙이고 **`n - 1`**(작아진 값)으로 자신을 부릅니다. 매 호출마다 n이 1씩 줄어 결국 0에 닿아 멈춰요.",
      ),
      predict(
        "countdown-3",
        "위 `countdown` 함수에서 `countdown(3)`의 값은?",
        "pub fn countdown(n: Int) -> List(Int) {\n  case n {\n    0 -> []\n    _ -> [n, ..countdown(n - 1)]\n  }\n}\n\n// countdown(3) 은?",
        ["`[3, 2, 1]`", "`[1, 2, 3]`", "`[3, 2, 1, 0]`", "`[]`"],
        0,
        "맞아요! 3을 앞에 붙이고 `countdown(2)`, 거기에 2를 붙이고... `0 -> []`에서 멈춰 `[3, 2, 1]`이 됩니다.",
        [
          #(1, "prepend라 큰 수가 **앞**에 붙어요 — `[3, 2, 1]` 순서입니다."),
          #(2, "종료 조건 `0 -> []`은 0을 **담지 않고** 빈 리스트를 돌려줘요 — 0은 포함되지 않습니다."),
          #(3, "`[]`는 `countdown(0)`일 때예요 — `countdown(3)`은 원소 3개를 담습니다."),
        ],
      ),
      mcq(
        "same-arg-infinite",
        "리스트 합 함수에서 재귀 가지를 `first + total(rest)` 대신 `first + total(xs)`로 썼습니다. 무슨 일이 벌어질까요?",
        [
          "`total(xs)`가 **같은** 리스트로 자신을 계속 불러 끝나지 않는다(무한 재귀)",
          "정상 동작하며 같은 합을 돌려준다",
          "컴파일 에러가 난다",
          "합이 2배로 계산된다",
        ],
        0,
        "맞아요! `xs`는 줄어들지 않아 종료 조건(`[]`)에 영영 닿지 못합니다. 브라우저에서는 watchdog이 멈춘 워커를 종료하고 \"시간 초과 — 재귀가 끝나지 않았습니다. `rest`를 넘겨 문제를 작게 만드세요\"라고 알려줘요.",
        [
          #(1, "정상 동작하지 않아요 — `xs`가 안 줄어들어 `[]`에 닿지 못하고 무한히 반복됩니다."),
          #(2, "문법은 맞아서 **컴파일은 됩니다** — 문제는 실행 중에 끝나지 않는 것(런타임 무한 루프)이에요."),
          #(3, "값이 나오기 전에 멈추질 않아요 — 2배가 아니라 결과 자체가 안 나옵니다."),
        ],
      ),
      mcq(
        "missing-base-case",
        "재귀 함수에서 `[] -> ...` 종료 조건 가지를 빠뜨리면 Gleam은 어떻게 반응할까요?",
        [
          "컴파일 에러 (Inexhaustive patterns) — `[]` 경우가 빠졌다고 알려준다",
          "조용히 컴파일되고 실행 시 무한 재귀에 빠진다",
          "빈 리스트를 만나면 자동으로 0을 돌려준다",
          "경고만 내고 정상 컴파일된다",
        ],
        0,
        "정확해요! `case`는 모든 경우를 덮어야 하므로, `[]` 가지가 없으면 컴파일러가 Inexhaustive patterns 에러로 막습니다 — 종료 조건을 강제로 생각하게 만들어요.",
        [
          #(1, "조용히 넘어가지 않아요 — `[]`가 빠지면 **컴파일 단계**에서 바로 걸립니다."),
          #(2, "Gleam은 기본값을 끼워주지 않아요 — 빠진 패턴은 컴파일 에러입니다."),
          #(3, "단순 경고가 아니라 **에러**예요 — 빠진 패턴이 있으면 컴파일 자체가 실패합니다."),
        ],
      ),
      predict(
        "sum-to-good",
        "인자가 매 호출마다 줄어드는 올바른 재귀입니다. `sum_to(4)`의 값은?",
        "pub fn sum_to(n: Int) -> Int {\n  case n {\n    0 -> 0\n    _ -> n + sum_to(n - 1)\n  }\n}\n\n// sum_to(4) 은?",
        ["`10`", "`4`", "`0`", "끝나지 않음 (무한 재귀)"],
        0,
        "맞아요! 4 + 3 + 2 + 1 + 0 = 10. 매 호출마다 `n - 1`로 줄어 0에 닿아 안전하게 멈춥니다.",
        [
          #(1, "입력 그대로(4)가 아니라 4부터 1까지의 합이에요 — 10입니다."),
          #(2, "0은 종료값일 뿐이고, 내려가며 더한 합이 결과예요 — 10입니다."),
          #(3, "`n - 1`로 매번 줄어드니 끝납니다 — 무한 재귀는 `sum_to(n)`처럼 안 줄일 때예요."),
        ],
      ),
    ],
  )
}

fn lesson_no_loops() -> Lesson {
  Lesson(
    id: "l05-no-loops",
    unit_id: "u05-lists-recursion",
    title: "인덱스 없는 세계 — no loops",
    emits_tags: [Concept("lists"), Concept("recursion")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "다른 언어의 `for (i = 0; i < n; i++)`나 `xs[i]` 같은 **인덱스 접근**이 Gleam에는 없습니다. 리스트는 \"머리 + 꼬리\" 구조라, i번째 원소를 바로 집는 대신 **앞에서부터 한 겹씩** 벗겨 나갑니다.\n\n그래서 \"모든 원소에 무언가 하기\"도 재귀로 표현합니다: 머리를 변환해 결과 앞에 붙이고, 꼬리에 대해 재귀하는 식이에요.",
      ),
      Prose(
        "map-example",
        "각 원소를 2배로 만드는 함수를 봅시다 — 루프 없이 재귀로:\n\n```gleam\npub fn double_all(xs: List(Int)) -> List(Int) {\n  case xs {\n    [] -> []\n    [first, ..rest] -> [first * 2, ..double_all(rest)]\n  }\n}\n```\n\n빈 리스트는 빈 리스트(종료 조건). 비어 있지 않으면 머리를 `* 2` 변환해 **나머지를 변환한 결과 앞에 prepend**합니다. `length`/`total`과 똑같은 뼈대예요.",
      ),
      predict(
        "double-all",
        "위 `double_all` 함수에서 `double_all([1, 2, 3])`의 값은?",
        "pub fn double_all(xs: List(Int)) -> List(Int) {\n  case xs {\n    [] -> []\n    [first, ..rest] -> [first * 2, ..double_all(rest)]\n  }\n}\n\n// double_all([1, 2, 3]) 은?",
        ["`[2, 4, 6]`", "`[1, 2, 3]`", "`[6, 4, 2]`", "`12`"],
        0,
        "맞아요! 각 머리를 2배로 변환해 앞에 붙이며 내려가 `[2, 4, 6]`이 됩니다 — 순서는 그대로 유지돼요.",
        [
          #(1, "변환이 적용돼요 — 그대로가 아니라 각 원소가 2배가 된 `[2, 4, 6]`입니다."),
          #(2, "순서는 뒤집히지 않아요 — 머리를 변환한 결과를 **앞에** 붙여 원래 순서 `[2, 4, 6]`이 유지됩니다."),
          #(3, "이 함수는 합(2+4+6)이 아니라 변환된 **리스트**를 돌려줘요 — `[2, 4, 6]`입니다."),
        ],
      ),
      mcq(
        "no-for-while",
        "Gleam에서 리스트의 모든 원소를 훑으려면 무엇을 쓸까요?",
        [
          "재귀 — 머리를 처리하고 꼬리에 대해 자기 자신을 부른다",
          "`for` 루프",
          "`while` 루프",
          "`xs[i]`로 인덱스를 0부터 증가시키며 접근",
        ],
        0,
        "맞아요! Gleam엔 `for`/`while`이 없어 반복은 재귀로 표현합니다 — 머리를 처리하고 더 짧은 꼬리에 대해 자신을 부르는 패턴이에요.",
        [
          #(1, "Gleam에는 `for` 루프가 없습니다 — 반복은 재귀(또는 다음 유닛의 `list` 함수)로 합니다."),
          #(2, "Gleam에는 `while` 루프도 없어요 — 종료 조건이 있는 재귀로 대신합니다."),
          #(3, "`xs[i]` 같은 인덱스 접근이 없어요 — 리스트는 머리/꼬리로 한 겹씩 벗겨 다룹니다."),
        ],
      ),
      mcq(
        "prepend-vs-append",
        "리스트 앞에 붙이기(prepend, `[x, ..xs]`)와 뒤에 붙이기(append)의 비용에 대해 옳은 것은?",
        [
          "prepend는 O(1)로 빠르고, 뒤에 붙이려면 리스트 끝까지 가야 해 더 비싸다",
          "둘 다 똑같이 O(1)이다",
          "prepend가 더 비싸다 — 모든 원소를 옮겨야 한다",
          "리스트는 인덱스로 어디든 O(1)에 끼워넣을 수 있다",
        ],
        0,
        "정확해요! 머리에 붙이는 prepend는 기존 리스트를 그대로 꼬리로 재사용하니 O(1)입니다. 그래서 재귀로 결과를 만들 때 보통 **앞에서부터 prepend**하는 패턴을 씁니다.",
        [
          #(1, "뒤에 붙이기는 끝까지 훑어가야 해 prepend보다 비싸요 — 둘이 같지 않습니다."),
          #(2, "거꾸로예요 — prepend가 O(1)로 가장 쌉니다(꼬리 재사용)."),
          #(3, "인덱스 임의 삽입은 리스트에 없어요 — 머리/꼬리 구조라 앞쪽 작업이 쌉니다."),
        ],
      ),
    ],
  )
}

// ── Unit 6: 꼬리 재귀와 누산기 (사고 전환 — 재귀를 점프로) ──────────

fn unit_tail_recursion() -> Unit {
  let meta =
    UnitMeta(
      id: "u06-tail-recursion",
      title: "꼬리 재귀와 누산기",
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
    title: "스택이 자라는 재귀, 자라지 않는 재귀",
    emits_tags: [Concept("tail-call-optimisation")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "U5에서 쓴 재귀를 다시 봅시다. `1 + length(rest)`는 `length(rest)`가 **돌아온 뒤에** 할 일(`1 +`)이 남아 있습니다. 그 \"나중에 할 일\"을 어딘가 적어둬야 하므로, 호출 한 겹마다 **스택 프레임**이 하나씩 쌓입니다.\n\n```gleam\npub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n```\n\n리스트가 길어지면 프레임도 그만큼 깊이 쌓여, 아주 긴 입력에서는 스택이 넘칠 수 있습니다.",
      ),
      predict(
        "length-still-works",
        "값 자체는 올바릅니다. `length([10, 20, 30, 40])`의 값은?",
        "pub fn length(xs: List(Int)) -> Int {\n  case xs {\n    [] -> 0\n    [_, ..rest] -> 1 + length(rest)\n  }\n}\n\n// length([10, 20, 30, 40]) 은?",
        ["`3`", "`4`", "`100`", "`0`"],
        1,
        "맞아요! 원소가 넷이라 `1 +`이 네 번 쌓여 4입니다. 결과는 맞지만, 그 과정에서 스택이 네 겹 자랐습니다.",
        [
          #(0, "원소 개수만큼 셉니다 — 넷이라 4예요. 3은 하나를 빠뜨린 거예요."),
          #(2, "값을 더하는 게 아니라 *개수*를 셉니다 — 합 100이 아니라 길이 4."),
          #(3, "0은 빈 리스트일 때의 종료값이에요. 여기엔 원소가 넷 있습니다."),
        ],
      ),
      Prose(
        "what-is-tail",
        "핵심 구분은 \"재귀 호출이 그 가지의 **마지막 동작**인가\"입니다.\n\n- `1 + length(rest)` — 호출이 끝나고 `1 +`이 더 남음 → **꼬리 호출 아님** (스택이 자람)\n- `count_loop(rest, acc + 1)` — 호출 그 자체가 마지막 → **꼬리 호출** (스택이 안 자람)\n\n재귀 호출이 마지막 동작이면 Gleam은 그것을 **점프**로 컴파일합니다(꼬리 호출 최적화, TCO). 새 프레임을 쌓는 대신 같은 프레임을 재활용하는 거예요.",
      ),
      mcq(
        "which-is-tail",
        "다음 가지 중 **꼬리 호출**(재귀 호출이 마지막 동작)인 것은?",
        [
          "`[first, ..rest] -> first + sum(rest)`",
          "`[_, ..rest] -> 1 + length(rest)`",
          "`[first, ..rest] -> sum_loop(rest, acc + first)`",
          "`[first, ..rest] -> { let n = go(rest) n * 2 }`",
        ],
        2,
        "맞아요! `sum_loop(rest, acc + first)`는 호출이 곧 그 가지의 결과예요 — 호출 *뒤에* 할 일이 없으니 꼬리 호출이고, 점프로 최적화됩니다.",
        [
          #(0, "재귀 결과에 `first +`이 더 남아요 — 호출 뒤에 덧셈이 남으면 꼬리 호출이 아닙니다."),
          #(1, "재귀 결과에 `1 +`이 더 남아요 — 마지막 동작이 덧셈이라 꼬리 호출이 아닙니다."),
          #(3, "재귀 결과를 `n`에 담아 `n * 2`를 더 합니다 — 호출 뒤에 곱셈이 남아 꼬리 호출이 아니에요."),
        ],
      ),
      mcq(
        "why-tco",
        "재귀 호출을 \"마지막 동작\"으로 만들면 좋은 점은?",
        [
          "결과 값이 달라진다",
          "스택 프레임을 쌓지 않고 점프로 도는 꼴이 되어 긴 입력에도 스택이 넘치지 않는다",
          "컴파일이 빨라진다",
          "재귀를 for 루프로 자동 변환해 준다",
        ],
        1,
        "맞아요! 호출 뒤에 할 일이 없으면 Gleam이 점프로 컴파일합니다 — 프레임이 안 쌓이니 입력이 아무리 길어도 안전해요.",
        [
          #(0, "값은 그대로예요 — 같은 답을 *어떻게* 계산하느냐(스택 vs 점프)가 다를 뿐입니다."),
          #(2, "컴파일 속도와는 무관해요 — 핵심은 실행 시 스택이 자라지 않는다는 점입니다."),
          #(3, "Gleam에는 for 루프가 없어요 — 꼬리 호출 자체가 점프로 도는 반복이 됩니다."),
        ],
      ),
    ],
  )
}

fn lesson_accumulator() -> Lesson {
  Lesson(
    id: "l16-accumulator",
    unit_id: "u06-tail-recursion",
    title: "accumulator 패턴",
    emits_tags: [
      Concept("tail-call-optimisation"), Tricky("tail-call-accumulator"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "비-꼬리 재귀를 꼬리 재귀로 바꾸는 열쇠는 **누산기(accumulator)**입니다. \"지금까지의 답\"을 인자로 들고 내려가는 거예요.\n\n`1 + total(rest)`처럼 *돌아온 뒤에* 더하는 대신, 내려가면서 `acc + first`로 미리 더해 다음 호출에 넘깁니다. 그러면 재귀 호출이 그 가지의 **마지막 동작**이 됩니다.\n\n```gleam\nfn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n```\n\n`acc`에 0부터 시작해 원소를 하나씩 더해 나갑니다.",
      ),
      predict(
        "sumloop-from-zero",
        "`sum_loop([4, 5, 6], 0)`의 값은?",
        "fn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n\n// sum_loop([4, 5, 6], 0) 은?",
        ["`15`", "`0`", "`4`", "`456`"],
        0,
        "맞아요! acc가 0→4→9→15로 자라고, 빈 리스트에서 15를 돌려줍니다.",
        [
          #(1, "0은 *시작* 누산기예요 — 원소들을 더하면 15가 됩니다."),
          #(2, "첫 원소 4만 더한 게 아니에요 — 5와 6도 누적됩니다."),
          #(3, "숫자를 이어붙이는 게 아니라 *더합니다* — 4+5+6 = 15."),
        ],
      ),
      Prose(
        "empty-returns-acc",
        "여기서 가장 헷갈리는 지점: 종료 가지 `[] -> ???`에 무엇을 둘까요?\n\n비-꼬리 버전(`total`)에서는 `[] -> 0`이었습니다. 거기서 0은 \"빈 리스트의 합은 0\"이라는 *씨앗*이었어요. 하지만 누산기 버전에서는 합을 이미 `acc`에 다 모아 왔습니다. **종료 시점의 `acc`가 바로 답**입니다.",
      ),
      predict(
        "empty-branch-hole",
        "`[] -> ???` 자리에 `acc`를 넣었습니다. `sum_loop([1, 2, 3], 10)`의 값은? (시작 acc가 10)",
        "fn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n\n// sum_loop([1, 2, 3], 10) 은?",
        ["`6`", "`16`", "`10`", "`0`"],
        1,
        "정확해요! 시작 acc 10에 1+2+3을 더해 16. 종료 가지가 모아 온 acc를 그대로 돌려줍니다.",
        [
          #(0, "시작값 10을 빠뜨렸어요 — acc는 10에서 출발해 16이 됩니다."),
          #(2, "10은 시작 누산기예요 — 거기에 원소들을 더해야 16."),
          #(3, "`[] -> acc`라서 모아 온 값을 돌려줍니다 — `[] -> 0`이었다면 모은 걸 버려 버그였을 거예요."),
        ],
      ),
      mcq(
        "empty-zero-bug",
        "만약 종료 가지를 `[] -> 0`으로 바꾸면 `sum_loop([1, 2, 3], 0)`은 어떻게 될까요?",
        [
          "여전히 `6`을 준다",
          "`0`을 준다 — 마지막에 모아 온 acc를 버리기 때문",
          "컴파일 에러가 난다",
          "무한 재귀에 빠진다",
        ],
        1,
        "맞아요! 끝까지 내려가 acc를 6으로 만들어 놓고도, 종료 가지가 그걸 무시하고 0을 돌려줍니다 — 모은 걸 통째로 버리는 버그예요.",
        [
          #(0, "종료 가지가 acc 대신 0을 돌려주므로 6이 나오지 않아요 — 모은 값을 버립니다."),
          #(2, "타입은 맞아 컴파일은 됩니다 — *논리* 버그라 조용히 0이 나옵니다."),
          #(3, "리스트가 매번 짧아지므로 종료는 합니다 — 다만 잘못된 0을 돌려줘요."),
        ],
      ),
      predict(
        "count-with-acc",
        "개수도 같은 패턴으로 셉니다. `count_loop([7, 8, 9], 0)`의 값은?",
        "fn count_loop(xs: List(Int), acc: Int) -> Int {\n  case xs {\n    [] -> acc\n    [_, ..rest] -> count_loop(rest, acc + 1)\n  }\n}\n\n// count_loop([7, 8, 9], 0) 은?",
        ["`3`", "`24`", "`0`", "`9`"],
        0,
        "맞아요! 원소마다 acc에 1을 더해 0→1→2→3. 종료 시 acc(=3)가 길이입니다.",
        [
          #(1, "원소 값을 더하는 게 아니라 *1씩* 셉니다 — 합 24가 아니라 개수 3."),
          #(2, "0은 시작 누산기예요 — 원소 셋을 세면 3이 됩니다."),
          #(3, "마지막 원소 값(9)이 아니라 *개수*(3)를 돌려줍니다."),
        ],
      ),
    ],
  )
}

fn lesson_wrapper_loop() -> Lesson {
  Lesson(
    id: "l17-wrapper-loop",
    unit_id: "u06-tail-recursion",
    title: "wrapper + private loop 관용구",
    emits_tags: [Concept("tail-call-optimisation")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "누산기 버전에는 작은 불편이 있습니다. 부르는 쪽이 매번 시작값 `0`을 넘겨야 해요 — `sum_loop(numbers, 0)`. 시작값을 잊으면 곤란하고, 애초에 \"내부 사정\"인 acc를 바깥에 노출하는 것도 어색합니다.\n\n그래서 Gleam의 관용구는 **얇은 public wrapper + private `_loop`**입니다. public 함수는 시작값을 채워 넣어 한 번 호출하고, 진짜 재귀는 숨겨진 private 함수가 담당합니다.\n\n```gleam\npub fn sum(numbers: List(Int)) -> Int {\n  sum_loop(numbers, 0)\n}\n\nfn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n```",
      ),
      predict(
        "wrapper-value",
        "`sum([2, 3, 5])`의 값은? (wrapper가 시작 acc 0을 채워 줍니다)",
        "pub fn sum(numbers: List(Int)) -> Int {\n  sum_loop(numbers, 0)\n}\n\nfn sum_loop(numbers: List(Int), acc: Int) -> Int {\n  case numbers {\n    [] -> acc\n    [first, ..rest] -> sum_loop(rest, acc + first)\n  }\n}\n\n// sum([2, 3, 5]) 은?",
        ["`10`", "`0`", "`2`", "`235`"],
        0,
        "맞아요! wrapper가 `sum_loop([2, 3, 5], 0)`을 불러 acc가 0→2→5→10이 됩니다.",
        [
          #(1, "0은 wrapper가 넣어 주는 시작 acc예요 — 원소를 더하면 10."),
          #(2, "첫 원소 2만이 아니라 3과 5도 누적됩니다 — 합은 10."),
          #(3, "숫자를 이어붙이는 게 아니라 더합니다 — 2+3+5 = 10."),
        ],
      ),
      Prose(
        "why-wrapper",
        "이 관용구의 좋은 점:\n\n- 부르는 쪽은 `sum(xs)`만 알면 됩니다 — 시작값 0은 wrapper가 알아서 채웁니다.\n- acc는 구현 세부사항이라 `pub`을 붙이지 않아 **모듈 밖에서 보이지 않습니다**.\n- public 함수의 타입은 깔끔하게 `List(Int) -> Int` — 누산기 인자가 새어 나가지 않아요.\n\n관례상 private 재귀 함수에는 `_loop`(또는 `do_`, `go`) 같은 이름을 붙입니다.",
      ),
      mcq(
        "wrapper-purpose",
        "wrapper(public `sum`)가 하는 일은 무엇인가요?",
        [
          "실제 재귀를 직접 수행한다",
          "시작 누산기(0)를 채워 private `_loop`을 한 번 호출한다",
          "결과를 한 번 더 뒤집는다",
          "리스트를 정렬한다",
        ],
        1,
        "맞아요! wrapper는 시작값을 채워 넣어 private loop을 시동하는 얇은 한 줄이에요 — 재귀 자체는 `_loop`이 합니다.",
        [
          #(0, "재귀는 private `_loop`이 담당해요 — wrapper는 시작값만 채워 한 번 부릅니다."),
          #(2, "여기엔 뒤집기가 없어요 — 그건 리스트를 prepend로 쌓을 때 나오는 다른 패턴입니다."),
          #(3, "정렬과는 무관해요 — wrapper의 역할은 시작 acc를 채워 주는 것뿐입니다."),
        ],
      ),
      mcq(
        "why-private",
        "private `sum_loop`을 `pub`으로 노출하지 않는 이유로 가장 알맞은 것은?",
        [
          "private 함수가 더 빠르게 실행되므로",
          "acc는 내부 구현 세부사항이라 바깥 API를 `List(Int) -> Int`로 깔끔하게 유지하려고",
          "private 함수만 재귀할 수 있으므로",
          "`pub`을 붙이면 컴파일 에러가 나므로",
        ],
        1,
        "맞아요! 부르는 쪽엔 누산기가 필요 없어요. 감춰 두면 API가 깔끔하고, 시작값을 잘못 넘길 일도 없습니다.",
        [
          #(0, "`pub` 여부는 실행 속도와 무관해요 — 차이는 *외부 노출* 여부입니다."),
          #(2, "재귀에 `pub`/private은 상관없어요 — public 함수도 재귀할 수 있습니다."),
          #(3, "`pub`을 붙여도 컴파일은 됩니다 — 다만 acc가 새어 나가 API가 지저분해질 뿐이에요."),
        ],
      ),
    ],
  )
}

fn lesson_acc_reverse() -> Lesson {
  Lesson(
    id: "l18-acc-reverse",
    unit_id: "u06-tail-recursion",
    title: "누산의 부작용: 뒤집힌 결과",
    emits_tags: [Tricky("accumulator-reverse")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "누산기로 *리스트*를 만들 땐 한 가지 부작용이 생깁니다. 새 원소를 누산기 **앞에 prepend**(`[x, ..acc]`)로 쌓는데, prepend가 O(1)이라 이렇게 쌓는 게 옳습니다. 그런데 그 대가로 **결과가 뒤집힙니다**.\n\n```gleam\nfn double_loop(xs: List(Int), acc: List(Int)) -> List(Int) {\n  case xs {\n    [] -> acc\n    [first, ..rest] -> double_loop(rest, [first * 2, ..acc])\n  }\n}\n```\n\n첫 원소가 *가장 먼저* 들어가 *가장 깊이* 깔리고, 마지막 원소가 맨 앞에 옵니다.",
      ),
      predict(
        "double-loop-reversed",
        "`double_loop([1, 2, 3], [])`의 값은?",
        "fn double_loop(xs: List(Int), acc: List(Int)) -> List(Int) {\n  case xs {\n    [] -> acc\n    [first, ..rest] -> double_loop(rest, [first * 2, ..acc])\n  }\n}\n\n// double_loop([1, 2, 3], []) 은?",
        ["`[2, 4, 6]`", "`[6, 4, 2]`", "`[1, 2, 3]`", "`[6]`"],
        1,
        "맞아요! 2를 []앞에→[2], 4를 앞에→[4, 2], 6을 앞에→[6, 4, 2]. prepend 누산은 순서를 뒤집습니다.",
        [
          #(0, "각 값을 두 배 한 건 맞지만 *순서가 뒤집힙니다* — 1이 먼저 들어가 가장 깊이 깔려 [6, 4, 2]예요."),
          #(2, "값이 두 배가 됩니다 — 1,2,3이 아니라 2,4,6이고, 게다가 순서도 뒤집혀 [6, 4, 2]."),
          #(3, "모든 원소가 쌓입니다 — 마지막 [6]만 남지 않고 [6, 4, 2]예요."),
        ],
      ),
      Prose(
        "accumulate-then-reverse",
        "이 뒤집힘은 **버그가 아니라 패턴**입니다. 순서를 보존하고 싶으면 wrapper에서 마지막에 `list.reverse`를 한 번 거치면 됩니다. 이것을 **accumulate-then-reverse**(쌓고 마지막에 뒤집기) 관용구라고 합니다.\n\n```gleam\npub fn double_all(xs: List(Int)) -> List(Int) {\n  list.reverse(double_loop(xs, []))\n}\n```\n\nprepend로 빠르게(O(1)) 쌓아 두고, 끝에 딱 한 번 뒤집어 원래 순서로 되돌립니다.",
      ),
      predict(
        "double-all-restored",
        "`double_all([1, 2, 3])`의 값은? (wrapper가 마지막에 `list.reverse`를 적용)",
        "fn double_loop(xs: List(Int), acc: List(Int)) -> List(Int) {\n  case xs {\n    [] -> acc\n    [first, ..rest] -> double_loop(rest, [first * 2, ..acc])\n  }\n}\n\npub fn double_all(xs: List(Int)) -> List(Int) {\n  list.reverse(double_loop(xs, []))\n}\n\n// double_all([1, 2, 3]) 은?",
        ["`[6, 4, 2]`", "`[2, 4, 6]`", "`[1, 2, 3]`", "`[3, 2, 1]`"],
        1,
        "정확해요! loop이 [6, 4, 2]를 만들고, `list.reverse`가 그걸 [2, 4, 6]으로 되돌려 원래 순서를 회복합니다.",
        [
          #(0, "그건 reverse *전*의 값이에요 — wrapper가 한 번 뒤집어 [2, 4, 6]으로 만듭니다."),
          #(2, "값이 두 배가 됩니다 — 원소가 그대로가 아니라 2,4,6이에요."),
          #(3, "값을 두 배 해야 합니다 — 1,2,3이 아니라 2,4,6입니다."),
        ],
      ),
      mcq(
        "why-prepend",
        "리스트 누산에서 append(`acc <> [x]`) 대신 prepend(`[x, ..acc]`)를 쓰고 끝에 reverse하는 이유는?",
        [
          "append가 불가능하므로",
          "prepend는 O(1)이라 빠르고, 뒤집힘은 끝에 reverse 한 번으로 해결되므로",
          "reverse가 결과 값을 바꿔 주므로",
          "prepend는 순서를 보존하므로",
        ],
        1,
        "맞아요! prepend는 항상 O(1)이라 매 단계가 빠릅니다. 뒤집히는 건 마지막에 reverse 한 번(O(n))으로 깔끔히 되돌리면 돼요.",
        [
          #(0, "append도 가능은 해요 — 다만 매번 리스트 끝까지 훑어 O(n)이라 느립니다."),
          #(2, "reverse는 *순서*만 바꿉니다 — 값 자체(두 배 한 결과)는 그대로예요."),
          #(3, "prepend는 순서를 *뒤집습니다* — 그래서 끝에 reverse가 필요한 거예요."),
        ],
      ),
      mcq(
        "reverse-is-pattern",
        "누산기로 만든 리스트가 뒤집혀 나온 것을 보고 가장 알맞은 판단은?",
        [
          "버그다 — 재귀를 잘못 짰다",
          "정상이다 — prepend 누산의 자연스러운 결과이고, 필요하면 끝에 `list.reverse`로 되돌린다",
          "종료 조건이 틀렸다",
          "acc 시작값을 `[]`가 아니라 `[0]`으로 줘야 한다",
        ],
        1,
        "맞아요! prepend로 쌓으면 뒤집히는 게 정상입니다 — 버그가 아니라 패턴이에요. 순서가 중요하면 wrapper에서 reverse 한 번 하면 됩니다.",
        [
          #(0, "버그가 아니에요 — prepend 누산은 원래 뒤집힌 결과를 냅니다. reverse로 마무리할 뿐이죠."),
          #(2, "종료 조건 `[] -> acc`는 맞아요 — 뒤집힘은 종료가 아니라 prepend 때문입니다."),
          #(3, "시작값은 빈 리스트 `[]`가 맞아요 — `[0]`을 주면 없던 0이 결과에 섞입니다."),
        ],
      ),
    ],
  )
}

// ── Unit 7: 함수를 값으로 ─────────────────────────────────────────

fn unit_functions_as_values() -> Unit {
  let meta =
    UnitMeta(
      id: "u07-functions-as-values",
      title: "함수를 값으로",
      order: 7,
      level: 2,
      concepts: [
        Concept("anonymous-functions"), Concept("labelled-arguments"),
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
    title: "익명 함수와 함수 값",
    emits_tags: [Concept("anonymous-functions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "지금까지 함수는 `pub fn 이름(...) { ... }`처럼 **이름을 붙여** 정의했습니다. 하지만 Gleam에서 함수는 그 자체로 하나의 **값**이에요 — 정수나 문자열처럼 변수에 담고, 다른 함수에 건네줄 수 있습니다.\n\n이름 없이 즉석에서 만드는 함수를 **익명 함수**라고 하며 `fn(인자) { 본문 }`으로 씁니다. `fn`만 있고 이름이 없다는 점만 다를 뿐, 똑같은 함수예요.\n\n```gleam\nlet double = fn(x) { x * 2 }\ndouble(21)  // 42\n```\n\n`fn(x) { x * 2 }`라는 값을 만들어 `double`이라는 이름에 `let`으로 묶었습니다. 그다음부터는 `double(21)`처럼 보통 함수처럼 호출합니다.",
      ),
      predict(
        "anon-bind-call",
        "아래 코드에서 `double(21)`의 값은?",
        "let double = fn(x) { x * 2 }\n\n// double(21) 은?",
        ["`42`", "`21`", "`2`", "컴파일 에러"],
        0,
        "정확해요! `fn(x) { x * 2 }`는 입력을 두 배로 만드는 함수예요. `double(21)`은 21 * 2 = 42입니다.",
        [
          #(1, "입력 그대로가 아니라 `x * 2`가 적용돼요 — 21 * 2 = 42."),
          #(2, "`2`는 곱하는 수일 뿐, 반환값은 `x * 2` = 42입니다."),
          #(
            3,
            "익명 함수를 `let`으로 묶어 호출하는 건 합법이에요 — 함수도 값이라 변수에 담깁니다.",
          ),
        ],
      ),
      Prose(
        "anon-vs-named",
        "이름 붙은 함수와 익명 함수는 사실상 같은 것입니다. `pub fn double(x: Int) -> Int { x * 2 }`는 `double`이라는 이름에 `fn(x) { x * 2 }`를 묶어 둔 것과 본질적으로 같아요.\n\n익명 함수에도 인자 타입과 반환 타입을 적을 수 있지만(`fn(x: Int) -> Int { x * 2 }`), 짧게 쓸 때는 컴파일러의 추론에 맡겨 생략하는 경우가 많습니다.",
      ),
      predict(
        "anon-immediate",
        "익명 함수를 만들자마자 바로 호출할 수도 있습니다. 이 표현식의 값은?",
        "fn(a, b) { a + b }(3, 4)",
        ["`7`", "`12`", "`34`", "컴파일 에러"],
        0,
        "맞아요! `fn(a, b) { a + b }`를 만들고 곧장 `(3, 4)`로 호출하면 3 + 4 = 7입니다.",
        [
          #(1, "`+`는 덧셈이지 곱셈이 아니에요 — 3 + 4 = 7입니다."),
          #(2, "두 인자를 글자로 잇는 게 아니라 더해요 — 3 + 4 = 7."),
          #(3, "만든 즉시 `(3, 4)`로 호출하는 건 합법이에요 — 함수 값을 바로 적용한 것."),
        ],
      ),
      mcq(
        "anon-syntax",
        "이름 없는 익명 함수를 만드는 올바른 문법은?",
        [
          "`fn(x) { x * 2 }`",
          "`fn double(x) { x * 2 }`",
          "`lambda x: x * 2`",
          "`(x) => x * 2`",
        ],
        0,
        "맞아요! 익명 함수는 `fn(인자) { 본문 }`이에요 — `fn` 뒤에 이름 없이 바로 괄호가 옵니다.",
        [
          #(1, "`fn double(...)`은 이름이 붙은 정의예요 — 익명 함수에는 이름이 없습니다."),
          #(2, "`lambda`는 Gleam 문법이 아니에요. 익명 함수도 키워드는 `fn`입니다."),
          #(3, "`=>` 화살표 문법은 Gleam에 없어요 — 본문은 `{ }`로 감쌉니다."),
        ],
      ),
    ],
  )
}

fn lesson_higher_order() -> Lesson {
  Lesson(
    id: "u07-l02-higher-order",
    unit_id: "u07-functions-as-values",
    title: "고차 함수 — 함수를 받는 함수",
    emits_tags: [Concept("anonymous-functions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "함수가 값이라면, 함수를 **인자로 받는** 함수도 만들 수 있겠죠. 함수를 받거나 함수를 돌려주는 함수를 **고차 함수(higher-order function)**라고 합니다.\n\n함수 타입은 `fn(입력타입) -> 출력타입`으로 적습니다. 예를 들어 \"Int를 받아 Int를 돌려주는 함수\"는 `fn(Int) -> Int`예요.\n\n```gleam\nfn apply(f: fn(Int) -> Int, x: Int) -> Int {\n  f(x)\n}\n\napply(fn(n) { n * 2 }, 5)  // 10\n```\n\n`apply`는 첫 인자로 *함수*를, 둘째 인자로 값을 받아, 그 함수를 값에 적용합니다.",
      ),
      predict(
        "apply-fn",
        "위 `apply`에 두 배 함수와 5를 넘기면? `apply(fn(n) { n * 2 }, 5)`의 값은?",
        "fn apply(f: fn(Int) -> Int, x: Int) -> Int {\n  f(x)\n}\n\n// apply(fn(n) { n * 2 }, 5) 은?",
        ["`10`", "`5`", "`7`", "`25`"],
        0,
        "정확해요! `apply`는 받은 함수 `fn(n) { n * 2 }`를 5에 적용해요 — 5 * 2 = 10.",
        [
          #(1, "`apply`는 받은 함수를 적용해요 — 5를 그대로 두지 않고 두 배로 만듭니다."),
          #(2, "`n * 2`는 곱셈이라 5 * 2 = 10이에요 — 5 + 2가 아닙니다."),
          #(3, "`n * 2`는 5 * 2 = 10이지 5 * 5 = 25가 아니에요."),
        ],
      ),
      Prose(
        "list-map",
        "고차 함수의 진짜 위력은 리스트에서 드러납니다. `list.map(리스트, 함수)`는 리스트의 **각 원소에 함수를 적용**해 새 리스트를 만듭니다 — U5의 직접 재귀를 추상화한 도구예요.\n\n```gleam\nimport gleam/list\n\nlist.map([1, 2, 3], fn(x) { x * 2 })  // [2, 4, 6]\n```\n\n각 원소에 익명 함수 `fn(x) { x * 2 }`가 적용되어 두 배가 됩니다.",
      ),
      predict(
        "map-double",
        "이 `list.map`의 결과는?",
        "list.map([1, 2, 3], fn(x) { x * 2 })",
        ["`[2, 4, 6]`", "`[1, 2, 3]`", "`6`", "`[1, 4, 9]`"],
        0,
        "맞아요! 각 원소에 `x * 2`를 적용해 [2, 4, 6]이 됩니다.",
        [
          #(1, "함수가 각 원소에 적용돼요 — 원본 그대로가 아니라 두 배가 됩니다."),
          #(2, "`map`은 합치는 게 아니라 각 원소를 1:1 변환해 *리스트*를 돌려줘요 — 6이 아니라 [2, 4, 6]."),
          #(3, "`x * 2`는 두 배예요(제곱 `x * x`가 아니라) — [2, 4, 6]입니다."),
        ],
      ),
      predict(
        "filter-even",
        "`list.filter(리스트, 조건함수)`는 조건이 `True`인 원소만 남깁니다. 이 결과는?",
        "list.filter([1, 2, 3, 4], fn(x) { x % 2 == 0 })",
        ["`[2, 4]`", "`[1, 3]`", "`[1, 2, 3, 4]`", "`[True, False, True, False]`"],
        0,
        "정확해요! `x % 2 == 0`(짝수)이 참인 2와 4만 남습니다.",
        [
          #(1, "조건이 *참*인 원소를 남겨요 — 짝수(2, 4)가 남고 홀수가 걸러집니다."),
          #(2, "`filter`는 조건에 맞는 것만 골라내요 — 전부 남기지 않습니다."),
          #(
            3,
            "`filter`는 Bool 리스트가 아니라 *원소 자체*를 골라 돌려줘요 — [2, 4].",
          ),
        ],
      ),
      mcq(
        "fn-type",
        "\"Int를 받아 Bool을 돌려주는 함수\"의 타입 표기로 옳은 것은?",
        [
          "`fn(Int) -> Bool`",
          "`fn(Bool) -> Int`",
          "`Int -> Bool`",
          "`fn Int Bool`",
        ],
        0,
        "맞아요! 함수 타입은 `fn(입력) -> 출력`이에요 — 입력 `Int`, 출력 `Bool`.",
        [
          #(1, "입력과 출력이 뒤바뀌었어요 — Int가 입력, Bool이 출력입니다."),
          #(2, "함수 타입에도 `fn(...)`과 괄호가 필요해요 — `Int -> Bool`만으로는 안 됩니다."),
          #(3, "`->`로 입력과 출력을 잇고 입력은 괄호로 감쌉니다 — `fn(Int) -> Bool`."),
        ],
      ),
    ],
  )
}

fn lesson_captures() -> Lesson {
  Lesson(
    id: "u07-l03-captures",
    unit_id: "u07-functions-as-values",
    title: "함수 캡처 f(_, x)",
    emits_tags: [
      Concept("anonymous-functions"), Tricky("capture-vs-currying"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`list.map([1, 2, 3], fn(x) { add(10, x) })`처럼, \"인자 하나만 비워 둔 함수\"가 자주 필요합니다. Gleam은 이걸 짧게 쓰는 **함수 캡처** 문법을 줍니다: 호출에서 채울 자리에 `_`(언더스코어)를 하나 두면 돼요.\n\n```gleam\nadd(10, _)\n// 는 fn(b) { add(10, b) } 의 단축\n```\n\n빈칸 `_`는 정확히 **한 개**입니다. `add(10, _)`은 \"첫 인자는 10으로 고정, 둘째 인자만 받는 새 함수\"가 됩니다.",
      ),
      predict(
        "capture-map-add",
        "캡처를 `list.map`에 넘긴 결과는?",
        "list.map([1, 2, 3], add(10, _))\n// add(a, b) -> a + b",
        ["`[11, 12, 13]`", "`[10, 20, 30]`", "`[11, 22, 33]`", "`[1, 2, 3]`"],
        0,
        "정확해요! `add(10, _)`는 \"10을 더하는 함수\"라, 각 원소에 10을 더해 [11, 12, 13]이 됩니다.",
        [
          #(1, "10을 *곱하는* 게 아니라 *더해요* — 1+10, 2+10, 3+10 = [11, 12, 13]."),
          #(2, "`_`는 각 원소 하나를 받을 뿐이에요 — 원소를 10배 하지 않고 10을 더합니다."),
          #(3, "`add(10, _)`가 각 원소에 적용돼요 — 원본 그대로가 아니라 10씩 더해집니다."),
        ],
      ),
      Prose(
        "blank-position",
        "빈칸의 **위치**가 어느 인자를 비울지를 정합니다. 이게 캡처의 핵심이에요.\n\n`string.append(첫째, 둘째)`는 첫째 뒤에 둘째를 붙입니다.\n- `string.append(_, \"!\")`는 각 값 *뒤에* `!`를 붙입니다 (값이 첫째 자리).\n- `string.append(\"!\", _)`는 각 값 *앞에* `!`를 붙입니다 (값이 둘째 자리).\n\nU2에서 본 \"파이프는 첫 인자 전용\"이라는 한계를, 캡처가 풀어 줍니다 — 빈칸을 둘째·셋째 자리에도 둘 수 있으니까요.",
      ),
      predict(
        "capture-append-suffix",
        "이 캡처를 `list.map`에 넘긴 결과는?",
        "list.map([\"a\", \"b\"], string.append(_, \"!\"))",
        ["`[\"a!\", \"b!\"]`", "`[\"!a\", \"!b\"]`", "`[\"a\", \"b\"]`", "`[\"ab!\"]`"],
        0,
        "맞아요! `append(_, \"!\")`는 빈칸이 첫째 자리라 각 원소 *뒤에* `!`를 붙입니다 — [\"a!\", \"b!\"].",
        [
          #(
            1,
            "빈칸의 위치가 중요해요. `append(_, \"!\")`는 값이 *앞*이라 `!`가 뒤에 붙습니다 — 앞에 붙이려면 `append(\"!\", _)`.",
          ),
          #(2, "캡처한 함수가 각 원소에 적용돼요 — 원본 그대로 남지 않습니다."),
          #(3, "`map`은 각 원소를 1:1 변환해요 — 하나로 합치지 않습니다."),
        ],
      ),
      Prose(
        "vs-currying",
        "다른 언어를 안다면 캡처를 \"커링(currying)\"과 헷갈리기 쉽습니다. **Gleam에는 자동 커링이 없습니다.** Haskell처럼 `add 10`만 써서 부분 적용되는 일은 일어나지 않아요.\n\nGleam에서 부분 적용은 *명시적으로* 빈칸 `_`를 둘 때만 일어납니다. `add(10, _)`라고 빈칸을 적어 줘야 비로소 `fn(b) { add(10, b) }`가 됩니다. 그래서 `add(10, _)`의 타입은 \"아직 인자 하나가 비었다\"는 뜻의 `fn(Int) -> Int`예요.",
      ),
      mcq(
        "capture-type",
        "`add(a: Int, b: Int) -> Int`가 있을 때, 캡처 `add(10, _)`의 타입은?",
        [
          "`fn(Int) -> Int`",
          "`Int`",
          "`fn(Int, Int) -> Int`",
          "`fn() -> Int`",
        ],
        0,
        "맞아요! 빈칸이 하나 남았으니, 인자 하나(Int)를 더 받아 Int를 돌려주는 함수 — `fn(Int) -> Int`입니다.",
        [
          #(1, "캡처는 아직 호출이 끝나지 않은 *함수 값*이에요 — 결과 Int가 아니라 함수입니다."),
          #(
            2,
            "이미 첫 인자를 10으로 채웠어요 — 남은 빈칸은 하나라 `fn(Int) -> Int`입니다.",
          ),
          #(3, "빈칸 `_`가 하나 있으니 인자 하나를 받아요 — `fn() -> Int`가 아닙니다."),
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
        "함수 인자가 여럿이면 호출부에서 \"이 값이 어느 자리였더라?\" 하고 헷갈립니다. Gleam은 인자에 **라벨**을 붙여 호출을 문장처럼 읽히게 합니다.\n\n정의할 때 인자 앞에 `라벨 이름: 타입` 형태로 라벨을 붙입니다:\n\n```gleam\npub fn replace(\n  in string: String,\n  each pattern: String,\n  with replacement: String,\n) -> String {\n  string.replace(string, pattern, replacement)\n}\n\nreplace(in: \"a,b,c\", each: \",\", with: \" \")  // \"a b c\"\n```\n\n`in`, `each`, `with`가 라벨이고, `string`, `pattern`, `replacement`는 본문에서 쓰는 내부 이름입니다.",
      ),
      predict(
        "labelled-call",
        "위 `replace`를 라벨로 호출한 결과는?",
        "replace(in: \"a,b,c\", each: \",\", with: \" \")",
        ["`\"a b c\"`", "`\"a,b,c\"`", "`\"abc\"`", "`\" \"`"],
        0,
        "정확해요! \"a,b,c\"에서 모든 `,`를 공백으로 바꿔 \"a b c\"가 됩니다.",
        [
          #(1, "replace가 적용되므로 그대로 남지 않아요 — `,`가 공백이 됩니다."),
          #(2, "`,`를 빈 문자열이 아니라 *공백*으로 바꿔요 — 글자 사이에 공백이 남습니다."),
          #(3, "글자 a, b, c는 그대로 남고 구분자만 바뀝니다 — \"a b c\"."),
        ],
      ),
      Prose(
        "order-free",
        "라벨의 진짜 장점은 **순서에서 자유로워진다**는 점입니다. 라벨을 붙여 호출하면 인자를 어떤 순서로 적어도 이름으로 맞춰집니다 — 정의된 순서를 외울 필요가 없어요.\n\n```gleam\nreplace(each: \",\", with: \" \", in: \"a,b,c\")\n// 위와 똑같이 \"a b c\"\n```\n\n라벨 호출은 *위치*가 아니라 *이름*으로 매칭되니까요.",
      ),
      predict(
        "labelled-reorder",
        "라벨 순서를 바꿔 호출했습니다. 이 결과는?",
        "replace(each: \",\", with: \" \", in: \"a,b,c\")",
        ["`\"a b c\"`", "`\",a,b,c \"`", "컴파일 에러", "`\"a,b,c\"`"],
        0,
        "맞아요! 라벨은 이름으로 매칭되므로 순서를 바꿔도 결과가 같습니다 — \"a b c\".",
        [
          #(
            1,
            "라벨은 위치가 아니라 이름으로 짝지어요 — `in`은 여전히 대상 문자열, `each`는 찾을 것입니다.",
          ),
          #(
            2,
            "라벨이 붙은 호출은 순서가 달라도 합법이에요 — 컴파일되고 \"a b c\"가 됩니다.",
          ),
          #(3, "replace가 정상 적용돼요 — `,`가 공백으로 바뀐 \"a b c\"입니다."),
        ],
      ),
      Prose(
        "shorthand",
        "변수 이름이 라벨과 똑같을 때는 **단축 문법(label shorthand)**을 쓸 수 있습니다. `greet(name: name, greeting: greeting)`처럼 이름이 겹치면, `greet(name:, greeting:)`로 줄여 쓸 수 있어요 — 라벨 뒤를 비우면 \"같은 이름의 변수를 넣는다\"는 뜻입니다.",
      ),
      mcq(
        "shorthand-meaning",
        "`name`과 `greeting`이라는 변수가 있을 때, `greet(name:, greeting:)`은 무엇과 같은가요?",
        [
          "`greet(name: name, greeting: greeting)`",
          "`greet(name, greeting)`",
          "`greet()` — 빈 호출",
          "컴파일 에러",
        ],
        0,
        "맞아요! 라벨 뒤를 비우면 *같은 이름의 변수*를 그 라벨에 넣는다는 단축 문법이에요.",
        [
          #(
            1,
            "단축 문법은 *라벨이 붙은* 호출이에요 — 라벨 `name:`/`greeting:`이 그대로 살아 있습니다.",
          ),
          #(2, "인자를 비우는 게 아니라, 같은 이름의 변수를 채워 넣는 단축이에요."),
          #(
            3,
            "같은 이름의 변수가 있으면 합법인 단축 문법이라 정상 컴파일됩니다.",
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
      title: "list 모듈 — 재귀의 추상화",
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
    title: "당신이 쓴 재귀에는 이름이 있다 — map",
    emits_tags: [Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "U5~U6에서 손으로 쓴 재귀를 떠올려 보세요. 리스트의 머리를 처리하고 꼬리에 대해 자신을 다시 부르는 그 패턴 — 사실 **이미 이름이 붙어 있습니다**.\n\n각 원소를 **1:1로 변환**해 같은 길이의 새 리스트를 만드는 재귀, 그게 바로 `list.map`입니다.\n\n```gleam\nimport gleam/list\n\nlist.map([1, 2, 3], fn(x) { x * 2 })\n// == [2, 4, 6]\n```\n\n`list.map(리스트, 변환함수)` — 변환함수는 원소 하나를 받아 새 원소 하나를 돌려줍니다. 원소 개수는 그대로예요.",
      ),
      predict(
        "map-double",
        "이 `list.map`의 결과는?",
        "list.map([1, 2, 3], fn(x) { x * 2 })",
        ["`[2, 4, 6]`", "`[1, 2, 3]`", "`12`", "`[1, 4, 9]`"],
        0,
        "맞아요! 각 원소에 변환함수 `x * 2`가 1:1로 적용돼 `[2, 4, 6]`이 됩니다.",
        [
          #(1, "변환함수가 모든 원소에 적용됩니다 — 원본 그대로가 아니라 두 배가 돼요."),
          #(2, "map은 리스트를 합치지 않아요. 길이가 같은 **리스트**를 돌려줍니다 — 값 하나가 아니에요."),
          #(3, "`x * 2`는 제곱이 아니라 두 배예요. `[1, 4, 9]`는 `x * x`의 결과입니다."),
        ],
      ),
      Prose(
        "shape-changes",
        "map은 원소의 **타입을 바꿀 수도** 있습니다. 변환함수의 반환 타입이 곧 새 리스트의 원소 타입이 돼요. `List(Int)`에 `int.to_string`을 map하면 `List(String)`이 됩니다 — 길이는 그대로, 모양만 바뀝니다.\n\n```gleam\nimport gleam/int\nimport gleam/list\n\nlist.map([1, 2, 3], int.to_string)\n// == [\"1\", \"2\", \"3\"]\n```\n\nU7에서 배운 함수 값을 그대로 넘길 수 있다는 점에 주목하세요 — `int.to_string`은 익명 함수로 감싸지 않아도 됩니다.",
      ),
      predict(
        "map-to-string",
        "이 `list.map`의 결과는?",
        "list.map([1, 2, 3], int.to_string)",
        ["`[\"1\", \"2\", \"3\"]`", "`[1, 2, 3]`", "`\"123\"`", "`[\"123\"]`"],
        0,
        "정확해요! 각 `Int`가 `int.to_string`으로 변환돼 `List(String)`인 `[\"1\", \"2\", \"3\"]`이 됩니다.",
        [
          #(1, "타입이 바뀝니다 — `Int`가 아니라 `String`이 됩니다. 보기의 따옴표 유무를 보세요."),
          #(2, "map은 원소를 이어붙이지 않아요 — 각 원소를 따로 변환한 **리스트**를 돌려줍니다."),
          #(3, "원소가 하나로 합쳐지지 않아요 — 원소 3개가 각각 변환돼 3개로 남습니다."),
        ],
      ),
      predict(
        "map-uppercase",
        "함수 값을 그대로 넘기는 `list.map`입니다. 결과는?",
        "list.map([\"a\", \"b\", \"c\"], string.uppercase)",
        [
          "`[\"A\", \"B\", \"C\"]`", "`[\"a\", \"b\", \"c\"]`", "`\"ABC\"`",
          "`[\"abc\"]`",
        ],
        0,
        "맞아요! 각 문자열에 `string.uppercase`가 적용돼 `[\"A\", \"B\", \"C\"]`가 됩니다 — 익명 함수로 감쌀 필요 없이 함수 값을 바로 넘겼어요.",
        [
          #(1, "변환이 적용됩니다 — 소문자 그대로가 아니라 대문자가 돼요."),
          #(2, "map은 원소를 합치지 않아요. 같은 길이의 리스트를 돌려줍니다."),
          #(3, "원소 3개가 각각 변환돼 3개로 남습니다 — 하나로 합쳐지지 않아요."),
        ],
      ),
      mcq(
        "map-meaning",
        "`list.map`을 한 문장으로 가장 잘 설명한 것은?",
        [
          "각 원소를 1:1로 변환해 **같은 길이**의 새 리스트를 만든다",
          "조건에 맞는 원소만 골라 **더 짧은** 리스트를 만든다",
          "리스트를 접어 **값 하나**로 만든다",
          "리스트의 원소 순서를 뒤집는다",
        ],
        0,
        "맞아요! map의 핵심은 '1:1 변환, 길이 보존'입니다. 거르기(filter)나 접기(fold)와는 역할이 다릅니다.",
        [
          #(1, "그건 `filter`예요. map은 원소를 거르지 않고 모두 변환합니다 — 길이가 그대로예요."),
          #(2, "그건 `fold`예요. map의 결과는 값 하나가 아니라 **리스트**입니다."),
          #(3, "순서 뒤집기는 `list.reverse`입니다 — map은 순서를 유지해요."),
        ],
      ),
    ],
  )
}

fn lesson_list_filter() -> Lesson {
  Lesson(
    id: "l08-list-filter",
    unit_id: "u08-list-module",
    title: "filter — 골라내기",
    emits_tags: [Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "map이 \"모든 원소를 변환\"이라면, `list.filter`는 \"**조건에 맞는 원소만 남기기**\"입니다.\n\n넘기는 함수는 원소 하나를 받아 `Bool`을 돌려주는 **술어(predicate)**입니다. `True`면 남기고, `False`면 버립니다. 원소 자체는 바뀌지 않고, **개수만 줄어들 수 있어요**.\n\n```gleam\nimport gleam/list\n\nlist.filter([1, 2, 3, 4, 5], fn(x) { x > 2 })\n// == [3, 4, 5]\n```",
      ),
      predict(
        "filter-gt2",
        "이 `list.filter`의 결과는? (술어가 `True`인 원소만 남김)",
        "list.filter([1, 2, 3, 4, 5], fn(x) { x > 2 })",
        ["`[3, 4, 5]`", "`[1, 2]`", "`[True, True, True]`", "`3`"],
        0,
        "맞아요! `x > 2`가 참인 원소(3, 4, 5)만 남고 나머지는 버려집니다.",
        [
          #(1, "술어가 `True`인 원소를 **남깁니다** — `False`인 것을 남기는 게 아니에요. `x > 2`가 참인 건 3, 4, 5입니다."),
          #(2, "filter는 술어의 결과(`Bool`)가 아니라 **원래 원소**를 남깁니다 — `[3, 4, 5]`."),
          #(3, "filter는 값 하나가 아니라 걸러진 **리스트**를 돌려줍니다."),
        ],
      ),
      Prose(
        "predicate",
        "술어는 반드시 `Bool`을 돌려줘야 합니다. 짝수만 거르고 싶다면 `int.is_even`처럼 `Bool`을 주는 함수를 쓰거나, `fn(x) { x % 2 == 0 }`처럼 직접 비교식을 씁니다. (`%`는 나머지 연산자라 `x % 2 == 0`이면 짝수예요.)\n\n```gleam\nimport gleam/int\nimport gleam/list\n\nlist.filter([1, 2, 3, 4, 5], int.is_even)\n// == [2, 4]\n```",
      ),
      predict(
        "filter-even",
        "함수 값을 그대로 넘긴 `list.filter`입니다. 결과는?",
        "list.filter([1, 2, 3, 4, 5], int.is_even)",
        ["`[2, 4]`", "`[1, 3, 5]`", "`[2, 4, 6]`", "`2`"],
        0,
        "정확해요! `int.is_even`이 `True`인 원소, 즉 짝수 2와 4만 남습니다.",
        [
          #(1, "`is_even`이 참인 것(짝수)을 남깁니다 — 홀수가 아니라 `[2, 4]`예요."),
          #(2, "리스트에 없던 6이 생길 수는 없어요. filter는 원소를 추가하지 않습니다."),
          #(3, "filter는 개수(값 하나)가 아니라 걸러진 **리스트**를 돌려줍니다."),
        ],
      ),
      predict(
        "filter-then-length",
        "filter 결과를 length로 센 값은?",
        "[1, 2, 3, 4, 5, 6]\n|> list.filter(fn(x) { x % 2 == 0 })\n|> list.length",
        ["`3`", "`2`", "`6`", "`[2, 4, 6]`"],
        0,
        "맞아요! 짝수는 2, 4, 6 — 세 개라 `list.length`가 `3`을 줍니다.",
        [
          #(1, "1~6 사이 짝수는 2, 4, 6으로 셋이에요 — 둘이 아닙니다."),
          #(2, "6은 원본 길이예요. filter가 짝수만 남긴 뒤 길이를 셉니다."),
          #(3, "마지막 `list.length`가 리스트를 **개수**로 바꿔요 — 리스트가 아니라 `3`입니다."),
        ],
      ),
      mcq(
        "filter-vs-map",
        "map과 filter의 가장 큰 차이는?",
        [
          "filter는 결과 길이가 줄 수 있고, map은 길이가 항상 같다",
          "filter는 길이가 같고, map은 길이가 줄 수 있다",
          "둘 다 항상 값 하나를 돌려준다",
          "둘 다 술어(`Bool` 반환 함수)를 받는다",
        ],
        0,
        "맞아요! filter는 거르므로 길이가 줄 수 있고(또는 같고), map은 1:1 변환이라 길이가 보존됩니다.",
        [
          #(1, "반대로 설명했어요 — 길이가 변할 수 있는 건 filter, 보존하는 건 map입니다."),
          #(2, "둘 다 **리스트**를 돌려줍니다. 값 하나로 접는 건 fold예요."),
          #(3, "술어(`Bool` 반환)를 받는 건 filter뿐이에요. map의 함수는 어떤 타입이든 돌려줄 수 있습니다."),
        ],
      ),
    ],
  )
}

fn lesson_fold() -> Lesson {
  Lesson(
    id: "l08-fold",
    unit_id: "u08-list-module",
    title: "fold — 만능 접기",
    emits_tags: [Concept("lists")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "map과 filter는 리스트를 받아 리스트를 돌려줍니다. 그런데 리스트를 **값 하나로 접고** 싶을 때는요? 합계, 곱, 개수, 이어붙인 문자열처럼요. 그게 `list.fold`입니다.\n\n`list.fold(리스트, 초기값, fn(acc, item) { ... })` — **초기 누산기(acc)**에서 시작해, 원소를 하나씩 누산기에 합쳐 나갑니다. U6에서 손으로 쓴 `sum_loop`가 정확히 fold예요.\n\n```gleam\nimport gleam/list\n\nlist.fold([1, 2, 3, 4], 0, fn(acc, x) { acc + x })\n// == 10\n```\n\n중요: 콜백의 **첫 번째 인자가 누산기(acc)**, 두 번째가 현재 원소입니다.",
      ),
      predict(
        "fold-sum",
        "이 `list.fold`의 결과는?",
        "list.fold([1, 2, 3, 4], 0, fn(acc, x) { acc + x })",
        ["`10`", "`0`", "`[1, 2, 3, 4]`", "`4`"],
        0,
        "맞아요! 0에서 시작해 1, 2, 3, 4를 차례로 더해 `10`이 됩니다.",
        [
          #(1, "0은 **초기 누산기**예요. 거기에 원소들을 더해 나갑니다."),
          #(2, "fold는 리스트를 값 하나로 **접습니다** — 리스트가 아니라 `10`이에요."),
          #(3, "4는 마지막 원소(또는 개수)일 뿐, 결과는 합 `10`입니다."),
        ],
      ),
      Prose(
        "any-shape",
        "fold의 초기값과 누산기 타입은 **원소 타입과 달라도** 됩니다. 그래서 fold는 \"만능\"이에요 — 곱(초기값 1), 개수(초기값 0, 콜백에서 `acc + 1`), 문자열 이어붙이기(초기값 `\"\"`)까지 전부 fold로 표현됩니다.\n\n```gleam\nimport gleam/list\n\n// 곱: 초기값 1\nlist.fold([1, 2, 3, 4], 1, fn(acc, x) { acc * x })\n// == 24\n```",
      ),
      predict(
        "fold-product",
        "곱을 구하는 `list.fold`입니다. 결과는?",
        "list.fold([1, 2, 3, 4], 1, fn(acc, x) { acc * x })",
        ["`24`", "`10`", "`1`", "`0`"],
        0,
        "정확해요! 초기값 1에서 1*1*2*3*4 = 24를 누적합니다.",
        [
          #(1, "10은 **덧셈** fold의 결과예요. 여기선 `acc * x`로 곱합니다."),
          #(2, "1은 초기 누산기예요 — 원소들을 곱해 나가면 24가 됩니다."),
          #(3, "곱셈의 초기값을 0으로 두면 전부 0이 되겠지만, 여기선 1로 시작합니다 — 결과는 24."),
        ],
      ),
      predict(
        "fold-count",
        "원소 개수를 세는 fold입니다. 콜백이 원소 값을 안 쓰고 `acc + 1`만 합니다. 결과는?",
        "list.fold([10, 20, 30], 0, fn(acc, _x) { acc + 1 })",
        ["`3`", "`60`", "`30`", "`0`"],
        0,
        "맞아요! 원소 값을 무시하고 매번 1씩 더하므로, 원소 개수인 `3`이 됩니다.",
        [
          #(1, "60은 원소들의 **합**이에요. 이 콜백은 값을 더하지 않고 `acc + 1`만 합니다."),
          #(2, "30은 마지막 원소예요. 콜백은 원소 값을 쓰지 않습니다 — 개수만 셉니다."),
          #(3, "0은 초기값이에요 — 원소마다 1을 더해 3이 됩니다."),
        ],
      ),
      mcq(
        "fold-callback-shape",
        "`list.fold(xs, init, f)`에서 콜백 `f`의 올바른 인자 순서는?",
        [
          "`fn(acc, item)` — 누산기가 먼저",
          "`fn(item, acc)` — 원소가 먼저",
          "`fn(acc)` — 인자 하나",
          "`fn(item)` — 인자 하나",
        ],
        0,
        "맞아요! Gleam stdlib의 fold 콜백은 `fn(acc, item)`입니다 — 누산기가 첫 번째예요. 다음 레슨에서 이 순서가 왜 함정이 되는지 봅니다.",
        [
          #(1, "순서가 반대예요. Gleam은 누산기를 **첫 번째** 인자로 받습니다 — 다른 언어와 다를 수 있어요."),
          #(2, "콜백은 누산기와 원소 **둘 다** 받아야 합니다 — 인자가 둘이에요."),
          #(3, "원소만 받으면 누산을 이어갈 수 없어요 — 누산기도 함께 받습니다."),
        ],
      ),
    ],
  )
}

fn lesson_fold_direction() -> Lesson {
  Lesson(
    id: "l08-fold-direction",
    unit_id: "u08-list-module",
    title: "fold 방향과 누산기",
    emits_tags: [Concept("lists"), Tricky("fold-arg-order")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`list.fold`는 **왼쪽부터** 접습니다. 그리고 콜백은 `fn(acc, item)` — **누산기가 첫 번째**입니다. 이 두 사실이 합쳐지면 초보자가 가장 자주 미끄러지는 지점이 만들어져요.\n\n각 원소를 누산기 **앞에 붙이며**(prepend) 접으면 어떻게 될까요?\n\n```gleam\nimport gleam/list\n\nlist.fold([1, 2, 3], [], fn(acc, x) { [x, ..acc] })\n// 1을 []앞에 → [1], 2를 앞에 → [2, 1], 3을 앞에 → [3, 2, 1]\n```",
      ),
      predict(
        "fold-prepend",
        "각 원소를 누산기 앞에 붙이는 fold입니다. 결과는?",
        "list.fold([1, 2, 3], [], fn(acc, x) { [x, ..acc] })",
        ["`[3, 2, 1]`", "`[1, 2, 3]`", "`[3]`", "`6`"],
        0,
        "맞아요! 왼쪽부터: 1이 먼저 깔리고 그 앞에 2, 3이 쌓여 `[3, 2, 1]`로 뒤집힙니다 — U6의 accumulate 패턴과 똑같은 현상이에요.",
        [
          #(1, "fold는 왼쪽부터라 1이 가장 깊이 깔립니다. 순서를 보존하려면 `list.fold_right`나 fold 후 `list.reverse`가 필요해요."),
          #(2, "원소가 하나만 남지 않아요 — 셋 다 누산기에 쌓입니다."),
          #(3, "여기 콜백은 더하지 않고 리스트에 prepend해요 — 결과는 합 6이 아니라 리스트 `[3, 2, 1]`입니다."),
        ],
      ),
      Prose(
        "fold-right",
        "순서를 보존하고 싶다면 **오른쪽부터** 접는 `list.fold_right`를 씁니다. 콜백 모양은 똑같이 `fn(acc, item)`이지만, 원소를 **뒤에서부터** 누산기에 합칩니다.\n\n```gleam\nimport gleam/list\n\nlist.fold_right([1, 2, 3], [], fn(acc, x) { [x, ..acc] })\n// 3을 []앞에 → [3], 2를 앞에 → [2, 3], 1을 앞에 → [1, 2, 3]\n```\n\n즉 prepend로 쌓되 뒤에서부터 처리하니 원래 순서가 그대로 복원됩니다.",
      ),
      predict(
        "fold-right-prepend",
        "같은 prepend 콜백을 `list.fold_right`로 쓰면? ",
        "list.fold_right([1, 2, 3], [], fn(acc, x) { [x, ..acc] })",
        ["`[1, 2, 3]`", "`[3, 2, 1]`", "`[3]`", "`6`"],
        0,
        "정확해요! 오른쪽부터 접으니 3이 먼저 깔리고 그 앞에 2, 1이 붙어 원래 순서 `[1, 2, 3]`이 복원됩니다.",
        [
          #(1, "그건 왼쪽부터 접는 `list.fold`의 결과예요. `fold_right`는 순서를 보존합니다."),
          #(2, "원소가 하나만 남지 않아요 — 셋 다 쌓입니다."),
          #(3, "이 콜백은 더하지 않고 prepend해요 — 결과는 리스트 `[1, 2, 3]`입니다."),
        ],
      ),
      Prose(
        "arg-order-trap",
        "더 미묘한 함정: 콜백 인자 순서를 **거꾸로** 써 버리는 것입니다. Gleam의 fold 콜백은 `fn(acc, item)`이지만, 다른 언어(예: Haskell의 `foldr`)에 익숙하면 무심코 `fn(item, acc)`로 씁니다.\n\n문자열을 누산기에 이어붙이는 fold를 봅시다 — `acc <> x`는 \"지금까지 모은 것 뒤에 현재 원소\"라는 뜻입니다. 왼쪽부터 접으니 순서가 그대로 보존돼요.\n\n```gleam\nimport gleam/list\n\nlist.fold([\"1\", \"2\", \"3\"], \"\", fn(acc, x) { acc <> x })\n// == \"123\"\n```",
      ),
      predict(
        "fold-string-concat",
        "문자열을 이어붙이는 fold입니다. 콜백은 `acc <> x` (누산기 뒤에 원소). 결과는?",
        "list.fold([\"1\", \"2\", \"3\"], \"\", fn(acc, x) { acc <> x })",
        ["`\"123\"`", "`\"321\"`", "`\"\"`", "`6`"],
        0,
        "맞아요! 왼쪽부터 `\"\" <> \"1\" <> \"2\" <> \"3\"` 순으로 이어붙여 `\"123\"`이 됩니다 — `acc`가 앞, 원소가 뒤라 순서가 보존돼요.",
        [
          #(1, "`\"321\"`은 콜백을 `x <> acc`로 거꾸로 썼을 때 나오는 결과예요. 여기선 `acc <> x`라 순서가 보존됩니다."),
          #(2, "`\"\"`는 초기값일 뿐, 원소들이 차례로 이어붙습니다."),
          #(3, "여기 콜백은 더하지 않고 문자열을 `<>`로 이어붙여요 — 결과는 숫자가 아니라 `\"123\"`입니다."),
        ],
      ),
      mcq(
        "fold-arg-order-mcq",
        "`list.fold([\"1\", \"2\", \"3\"], \"\", f)`로 `\"321\"`을 만들려면 콜백 `f`를 어떻게 써야 할까요?",
        [
          "`fn(acc, x) { x <> acc }` — 원소를 누산기 앞에 붙인다",
          "`fn(acc, x) { acc <> x }` — 누산기 뒤에 원소",
          "`fn(acc, x) { acc <> \"-\" <> x }` — 사이에 -를 끼운다",
          "`list.fold_right`를 쓰면 자동으로 뒤집힌다",
        ],
        0,
        "맞아요! 콜백 인자 순서는 그대로 `fn(acc, x)`로 두고, 본문에서 `x <> acc`로 원소를 앞에 붙이면 왼쪽 fold가 `\"321\"`을 만듭니다.",
        [
          #(1, "`acc <> x`는 순서를 보존해 `\"123\"`을 만들어요 — 뒤집으려면 본문을 `x <> acc`로 바꿔야 합니다."),
          #(2, "이건 원소 사이에 -를 넣어 `\"-1-2-3\"`을 만들어요 — `\"321\"`이 아닙니다."),
          #(3, "`fold_right`에 `acc <> x`를 쓰면 `\"321\"`이 되긴 하지만 \"자동으로\"가 아니에요 — 방향이 바뀌어 그런 거고, 같은 `list.fold`로도 본문만 바꿔 만들 수 있습니다."),
        ],
      ),
    ],
  )
}

fn lesson_tool_choice() -> Lesson {
  Lesson(
    id: "l08-tool-choice",
    unit_id: "u08-list-module",
    title: "도구 선택 — map인가 filter인가 fold인가",
    emits_tags: [Concept("lists"), Tricky("tool-choice")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "이제 셋을 한자리에 놓고 **언제 무엇을 쓸지** 정리합니다. 판단 기준은 딱 하나, **결과의 모양**이에요.\n\n- 각 원소가 **1:1로 변환**되고 길이가 그대로 → `list.map`\n- **조건으로 골라내** 길이가 줄 수 있음 → `list.filter`\n- 리스트가 **값 하나로(또는 다른 모양으로) 접힘** → `list.fold`\n\n셋을 파이프로 이으면 작은 데이터 파이프라인이 됩니다.\n\n```gleam\nimport gleam/list\n\npub fn process(xs: List(Int)) -> Int {\n  xs\n  |> list.filter(fn(x) { x % 2 == 0 })\n  |> list.map(fn(x) { x * x })\n  |> list.fold(0, fn(acc, x) { acc + x })\n}\n// process([1, 2, 3, 4]) == 20\n```",
      ),
      predict(
        "pipeline-process",
        "위 `process` 파이프라인에서 `process([1, 2, 3, 4])`의 값은? (짝수만 → 제곱 → 합)",
        "xs\n|> list.filter(fn(x) { x % 2 == 0 })  // [2, 4]\n|> list.map(fn(x) { x * x })           // [4, 16]\n|> list.fold(0, fn(acc, x) { acc + x }) // 20",
        ["`20`", "`30`", "`[4, 16]`", "`6`"],
        0,
        "맞아요! 짝수 [2, 4] → 제곱 [4, 16] → 합 20. filter·map·fold가 차례로 모양을 바꿔 갑니다.",
        [
          #(1, "30은 1~4 전체를 제곱해 더한 값(1+4+9+16)이에요. 먼저 **짝수만** 걸러야 합니다."),
          #(2, "마지막 fold가 리스트를 값 하나로 접어요 — `[4, 16]`은 fold 직전 상태입니다."),
          #(3, "6은 원본 [1,2,3,4]의 짝수 합(2+4)이에요. 그 사이 **제곱** 단계가 있습니다."),
        ],
      ),
      Prose(
        "by-return-type",
        "막힐 때는 **결과 타입**을 먼저 떠올리세요. 결과가 `List`면 map이나 filter, 결과가 값 하나(`Int`, `String`, `Bool`)면 fold로 끝나야 합니다. \"개수를 센다\", \"최댓값을 찾는다\", \"합을 구한다\"는 모두 리스트를 **값 하나로** 접는 일 — fold(또는 그 특수형)예요.",
      ),
      mcq(
        "choose-count-evens",
        "\"리스트에서 짝수의 **개수**를 센다\"에 가장 알맞은 접근은?",
        [
          "`filter`로 짝수만 남긴 뒤 `length`로 센다 (또는 fold로 누적)",
          "`map`만으로 끝낼 수 있다",
          "`filter`만으로 개수가 나온다",
          "도구 없이 `<>`로 이어붙인다",
        ],
        0,
        "맞아요! 결과가 `Int` 하나이므로 마지막엔 접어야 합니다 — 짝수를 filter한 뒤 length로 세거나, fold로 직접 셀 수 있어요.",
        [
          #(1, "map은 길이를 보존해 **리스트**를 돌려줘요. 개수라는 값 하나를 얻으려면 접는 단계가 필요합니다."),
          #(2, "filter는 걸러진 **리스트**를 줍니다 — 개수(`Int`)를 얻으려면 length나 fold가 한 단계 더 필요해요."),
          #(3, "`<>`는 문자열 이어붙이기예요 — 개수 세기와는 무관합니다."),
        ],
      ),
      predict(
        "choose-uppercase",
        "\"각 단어를 대문자화한다\"에 알맞은 도구로 만든 결과입니다. 값은?",
        "list.map([\"hi\", \"bye\"], string.uppercase)",
        [
          "`[\"HI\", \"BYE\"]`", "`\"HIBYE\"`", "`[\"hi\", \"bye\"]`", "`2`",
        ],
        0,
        "맞아요! 각 원소를 1:1로 변환하고 길이를 보존하니 map이 정답입니다 — 결과는 `[\"HI\", \"BYE\"]`.",
        [
          #(1, "map은 원소를 합치지 않아요 — 각각 변환한 **리스트**를 돌려줍니다. 합치려면 fold가 필요해요."),
          #(2, "변환이 적용됩니다 — 소문자 그대로가 아니라 대문자가 돼요."),
          #(3, "개수(값 하나)는 fold/length의 결과예요. \"대문자화\"는 1:1 변환이라 map → **리스트**가 나옵니다."),
        ],
      ),
      predict(
        "choose-max",
        "\"리스트의 **최댓값**을 찾는다\"를 fold로 구현했습니다. 결과는?",
        "list.fold([3, 7, 2, 9, 4], 0, fn(acc, x) { int.max(acc, x) })",
        ["`9`", "`[3, 7, 2, 9, 4]`", "`25`", "`3`"],
        0,
        "맞아요! 최댓값은 리스트를 값 하나로 접는 일이라 fold가 어울립니다 — 누산기에 더 큰 값을 계속 남겨 `9`가 됩니다.",
        [
          #(1, "fold는 리스트를 값 하나로 접어요 — 리스트가 아니라 최댓값 `9`입니다."),
          #(2, "25는 모든 원소를 더한 합(3+7+2+9+4)이에요. 하지만 콜백이 `int.max`라 더하지 않고 더 큰 쪽만 남겨 결과는 최댓값 `9`입니다."),
          #(3, "3은 첫 원소예요. fold가 모든 원소를 훑어 가장 큰 9를 남깁니다."),
        ],
      ),
    ],
  )
}

fn unit_option_result() -> Unit {
  let meta =
    UnitMeta(
      id: "u09-option-result",
      title: "Option과 Result",
      order: 9,
      level: 3,
      concepts: [
        Concept("options"), Concept("results"),
        Concept("custom-error-types"),
      ],
      prerequisites: ["u04-custom-types"],
      lesson_ids: [
        "l01-option", "l02-result", "l03-custom-error",
        "l04-option-vs-result", "l05-stdlib-results",
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
    title: "없을 수도 있는 값 — Option",
    emits_tags: [Concept("options")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "다른 언어의 `null`은 \"값이 없음\"을 어디에나 몰래 끼워 넣어, 결국 NPE(null 참조 오류)로 폭발하곤 합니다. Gleam에는 `null`이 **없습니다**. 대신 \"있을 수도, 없을 수도\"를 타입에 적어두는 **`Option(a)`**를 씁니다.\n\n`Option(a)`는 두 가지 모양뿐인 커스텀 타입입니다(U4에서 본 variant 그대로예요):\n\n- `Some(값)` — 값이 **있다**\n- `None` — 값이 **없다**\n\n`import gleam/option.{type Option, None, Some}`로 가져와 씁니다.",
      ),
      predict(
        "some-shape",
        "`find_nickname(\"lucy\")`가 별명을 찾아 돌려줍니다. 그 값은 어떤 모양일까요?",
        "import gleam/option.{type Option, Some}\n\nfn find_nickname(name: String) -> Option(String) {\n  case name {\n    \"lucy\" -> Some(\"루시\")\n    _ -> Some(\"?\")\n  }\n}\n\n// find_nickname(\"lucy\") 은?",
        ["`Some(\"루시\")`", "`\"루시\"`", "`None`", "`Ok(\"루시\")`"],
        0,
        "맞아요! `Option`에서 값은 맨몸으로 나오지 않고 `Some(...)`으로 포장됩니다 — `Some(\"루시\")`.",
        [
          #(1, "값이 \"루시\"이긴 하지만, `Option` 타입이라 `Some`으로 감싸여 나옵니다. 꺼내려면 패턴 매칭이 필요해요."),
          #(2, "`None`은 별명이 *없을* 때의 모양이에요. 여기선 \"lucy\" 가지가 값을 찾았습니다."),
          #(3, "`Ok`는 `Result`의 생성자예요. `Option`은 `Some`/`None`을 씁니다."),
        ],
      ),
      predict(
        "none-shape",
        "같은 함수가 별명을 못 찾으면(`_` 가지) `None`을 돌려주도록 바꿨습니다. `find_nickname(\"bob\")`의 값은?",
        "import gleam/option.{type Option, None, Some}\n\nfn find_nickname(name: String) -> Option(String) {\n  case name {\n    \"lucy\" -> Some(\"루시\")\n    _ -> None\n  }\n}\n\n// find_nickname(\"bob\") 은?",
        ["`None`", "`Some(\"bob\")`", "`\"\"`", "`Nil`"],
        0,
        "정확해요! \"bob\"은 `_` 가지로 떨어져 `None` — \"값이 없음\"을 명시적으로 표현합니다.",
        [
          #(1, "`bob`에 해당하는 별명이 없어 `_` 가지가 선택돼요 — `Some`이 아니라 `None`."),
          #(2, "빈 문자열 `\"\"`도 엄연히 *있는* 값이에요. \"없음\"은 `None`으로 표현합니다."),
          #(3, "`Nil`은 다른 타입(빈 값)이에요. `Option`의 \"없음\"은 `None`입니다."),
        ],
      ),
      Prose(
        "pattern-match",
        "`Some`인지 `None`인지는 **`case`로 분기**해 꺼냅니다. `Some(x)` 가지에서 이름 `x`에 안쪽 값이 묶여요. `Option`도 variant가 둘뿐이라, U4의 exhaustiveness 그대로 — `Some`과 `None`을 **둘 다** 다뤄야 컴파일됩니다.\n\n```gleam\ncase nickname {\n  Some(nick) -> \"안녕, \" <> nick <> \"!\"\n  None -> \"안녕, 손님!\"\n}\n```",
      ),
      predict(
        "case-none",
        "위 패턴으로 만든 `greet` 함수에서 `greet(None)`의 값은?",
        "import gleam/option.{type Option, None, Some}\n\nfn greet(nickname: Option(String)) -> String {\n  case nickname {\n    Some(nick) -> \"안녕, \" <> nick <> \"!\"\n    None -> \"안녕, 손님!\"\n  }\n}\n\n// greet(None) 은?",
        ["`\"안녕, 손님!\"`", "`\"안녕, !\"`", "`None`", "컴파일 에러"],
        0,
        "맞아요! 입력이 `None`이라 `None` 가지가 선택되어 \"안녕, 손님!\"이 됩니다.",
        [
          #(1, "`None`엔 안쪽 값이 없어요 — `Some(nick)` 가지로 가지 않으니 `nick`을 쓰는 결과가 나오지 않습니다."),
          #(2, "`case`는 매칭된 입력이 아니라 가지의 *결과*를 돌려줘요 — `None`이 아니라 \"안녕, 손님!\"."),
          #(3, "`Some`과 `None`을 모두 다뤘으니 빠짐없이 처리되어 정상 컴파일됩니다."),
        ],
      ),
      Prose(
        "unwrap",
        "\"값이 있으면 그 값, 없으면 기본값\"이 필요할 때마다 `case`를 쓰긴 번거롭습니다. `option.unwrap(opt, 기본값)`이 그 패턴을 한 줄로 해줘요: `Some(x)`면 `x`, `None`이면 기본값을 돌려줍니다.",
      ),
      predict(
        "unwrap-none",
        "`option.unwrap`의 결과는?",
        "import gleam/option.{None}\n\noption.unwrap(None, \"익명\")",
        ["`\"익명\"`", "`None`", "`Some(\"익명\")`", "`\"\"`"],
        0,
        "정확해요! `None`이라 기본값 \"익명\"이 그대로 나옵니다 — `unwrap`은 포장을 벗겨 맨 값을 줍니다.",
        [
          #(1, "`unwrap`은 포장(`Option`)을 벗긴 맨 값을 돌려줘요 — `None`이 아니라 기본값 \"익명\"."),
          #(2, "`unwrap`의 결과는 더 이상 `Option`이 아니에요 — `Some`으로 다시 감싸지 않습니다."),
          #(3, "기본값으로 \"익명\"을 줬으니 빈 문자열이 아니라 \"익명\"이 나옵니다."),
        ],
      ),
    ],
  )
}

fn lesson_result() -> Lesson {
  Lesson(
    id: "l02-result",
    unit_id: "u09-option-result",
    title: "실패할 수 있는 연산 — Result",
    emits_tags: [Concept("results"), Tricky("exhaustiveness")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Gleam에는 예외(exception)가 **없습니다**. `try/catch`로 어딘가에서 날아오는 에러를 잡는 일이 없어요. 대신 실패 가능성을 **반환 타입에 적습니다**: `Result(성공타입, 실패타입)`.\n\n`Result(a, e)`도 모양이 둘뿐인 커스텀 타입입니다:\n\n- `Ok(값)` — **성공**, 안에 성공값\n- `Error(이유)` — **실패**, 안에 실패 이유\n\n호출자는 `case`로 **두 경우 모두** 다뤄야 컴파일됩니다(U4 exhaustiveness의 재등장). \"에러를 깜빡하고 안 다루는\" 선택지가 타입 시스템에 아예 없어요.",
      ),
      predict(
        "result-ok",
        "`safe_div`는 0으로 나누기를 막습니다. `safe_div(20, 4)`의 값은?",
        "fn safe_div(a: Int, b: Int) -> Result(Int, Nil) {\n  case b {\n    0 -> Error(Nil)\n    _ -> Ok(a / b)\n  }\n}\n\n// safe_div(20, 4) 은?",
        ["`Ok(5)`", "`5`", "`Error(Nil)`", "`Ok(20)`"],
        0,
        "맞아요! 나누기가 성공해 몫 5가 `Ok`로 포장됩니다 — `Ok(5)`. 성공값도 맨몸으로는 안 나와요.",
        [
          #(1, "값은 5가 맞지만, `Result` 타입이라 `Ok(5)`로 포장돼요 — 꺼내려면 패턴 매칭이 필요합니다."),
          #(2, "`Error(Nil)`은 `b`가 0일 때예요. 여기선 4로 나누어 성공합니다."),
          #(3, "결과는 몫 `20 / 4 = 5`예요 — `Ok(20)`이 아니라 `Ok(5)`."),
        ],
      ),
      predict(
        "result-error",
        "같은 함수에서 `safe_div(20, 0)`의 값은?",
        "fn safe_div(a: Int, b: Int) -> Result(Int, Nil) {\n  case b {\n    0 -> Error(Nil)\n    _ -> Ok(a / b)\n  }\n}\n\n// safe_div(20, 0) 은?",
        ["`Error(Nil)`", "`Ok(0)`", "프로그램이 크래시한다", "`0`"],
        0,
        "정확해요! `b`가 0이라 `Error(Nil)` 가지가 선택됩니다 — 실패가 *값*으로 표현되니 크래시하지 않아요.",
        [
          #(1, "0으로 나누기는 성공이 아니에요 — `Ok`가 아니라 `Error(Nil)`로 막습니다."),
          #(2, "예외가 없으니 크래시하지 않아요. 실패는 `Error` 값으로 안전하게 돌아옵니다."),
          #(3, "실패는 맨 `0`이 아니라 `Error(Nil)`로 표현됩니다 — 호출자가 `case`로 구분할 수 있게요."),
        ],
      ),
      Prose(
        "handle-both",
        "`Result`에서 값을 쓰려면 `Ok`와 `Error`를 **둘 다** `case`로 풀어야 합니다.\n\n```gleam\ncase result {\n  Ok(n) -> \"값은 \" <> int.to_string(n)\n  Error(Nil) -> \"값이 없음\"\n}\n```\n\n만약 `Ok(n)` 가지만 쓰고 `Error`를 빼먹으면, U4에서 본 것과 **똑같은** \"Inexhaustive patterns\" 컴파일 에러가 납니다. 에러를 안 다루는 건 선택이 아니라 컴파일 실패예요.",
      ),
      predict(
        "result-case-ok",
        "위 패턴으로 만든 `describe` 함수에서 `describe(Ok(20))`의 값은?",
        "import gleam/int\n\nfn describe(r: Result(Int, Nil)) -> String {\n  case r {\n    Ok(n) -> \"값은 \" <> int.to_string(n)\n    Error(Nil) -> \"값이 없음\"\n  }\n}\n\n// describe(Ok(20)) 은?",
        ["`\"값은 20\"`", "`\"값이 없음\"`", "`Ok(20)`", "`20`"],
        0,
        "맞아요! `Ok(20)`이 `Ok(n)` 가지에 맞아 `n`에 20이 묶이고, \"값은 20\"이 만들어집니다.",
        [
          #(1, "\"값이 없음\"은 `Error` 가지의 결과예요 — 입력은 `Ok(20)`이라 성공 가지로 갑니다."),
          #(2, "`case`는 입력 그대로가 아니라 가지의 *결과 문자열*을 돌려줘요 — `Ok(20)`이 아니라 \"값은 20\"."),
          #(3, "`Ok(n)` 가지에서 `n`(=20)을 꺼내 문자열에 끼워 넣은 \"값은 20\"이 결과입니다."),
        ],
      ),
      mcq(
        "inexhaustive",
        "`Result(Int, Nil)`을 받는 `case`에서 `Ok(n) -> ...` 가지만 쓰고 `Error`를 안 썼습니다. 어떻게 될까요?",
        [
          "런타임에 `Error`가 들어오면 그때 크래시한다",
          "컴파일 에러 — `Error` 경우가 빠져 \"Inexhaustive patterns\"",
          "`Error`는 자동으로 무시된다",
          "`Error`일 땐 `Nil`을 알아서 돌려준다",
        ],
        1,
        "맞아요! `Ok`/`Error` 둘 다 다뤄야 컴파일됩니다. 에러를 \"안 다루는\" 선택지가 타입 시스템에 없는 것 — 이게 예외 대신 `Result`를 쓰는 대가이자 보상이에요.",
        [
          #(0, "런타임까지 가지 않아요 — *컴파일 타임*에 빠진 케이스를 잡아 실행조차 막습니다."),
          #(2, "Gleam은 빠진 가지를 조용히 무시하지 않아요 — 컴파일 에러로 분명히 알려줍니다."),
          #(3, "자동 기본값 같은 건 없어요. 모든 경우를 직접 명시해야 합니다."),
        ],
      ),
    ],
  )
}

fn lesson_custom_error() -> Lesson {
  Lesson(
    id: "l03-custom-error",
    unit_id: "u09-option-result",
    title: "나만의 에러 타입",
    emits_tags: [Concept("custom-error-types"), Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`Result(Int, Nil)`의 `Nil`은 \"실패했다\"만 말할 뿐, *왜* 실패했는지는 못 담습니다. 실패 이유가 여러 가지라면, 그 이유들을 **나만의 커스텀 타입**으로 만들어 `Error`의 자리에 넣습니다(U4의 variant 그대로).\n\n```gleam\npub type AgeError {\n  NotANumber\n  Negative\n}\n```\n\n이제 `Result(Int, AgeError)`는 \"성공하면 `Int`, 실패하면 *이 두 이유 중 하나*\"를 타입만 보고 알 수 있어요.",
      ),
      Prose(
        "parse-age",
        "`int.parse(input)`은 문자열을 정수로 바꿔 시도하고 `Result(Int, Nil)`을 돌려줍니다(숫자가 아니면 `Error(Nil)`). 이걸 받아 우리 에러 타입으로 옮기고, 음수까지 거르는 `parse_age`를 만들어 봅시다:\n\n```gleam\nimport gleam/int\n\npub fn parse_age(input: String) -> Result(Int, AgeError) {\n  case int.parse(input) {\n    Error(Nil) -> Error(NotANumber)\n    Ok(n) ->\n      case n < 0 {\n        True -> Error(Negative)\n        False -> Ok(n)\n      }\n  }\n}\n```\n\n바깥 `case`는 파싱 성공/실패를, 안쪽 `case`는 음수 여부를 가립니다.",
      ),
      predict(
        "parse-neg",
        "위 `parse_age`에서 `parse_age(\"-3\")`의 값은?",
        "// parse_age(\"-3\") 은?\n// (int.parse(\"-3\") == Ok(-3), 그리고 -3 < 0)",
        ["`Error(Negative)`", "`-3`", "`Error(NotANumber)`", "`Ok(-3)`"],
        0,
        "맞아요! \"-3\"은 숫자로 파싱돼 `Ok(-3)`이 되지만, 안쪽 `case`에서 `-3 < 0`이 참이라 `Error(Negative)`로 걸러집니다.",
        [
          #(1, "`Result`에서 값은 절대 맨몸으로 나오지 않아요 — 실패는 `Error(...)`로 포장됩니다. 게다가 음수라 성공도 아니에요."),
          #(2, "`NotANumber`는 *파싱 자체가* 실패할 때예요. \"-3\"은 숫자로 잘 파싱되지만 음수라서 막힙니다."),
          #(3, "\"-3\"은 파싱은 되지만 음수라 `Ok`가 아니에요 — `Error(Negative)`로 걸러집니다."),
        ],
      ),
      predict(
        "parse-abc",
        "같은 함수에서 `parse_age(\"abc\")`의 값은?",
        "// parse_age(\"abc\") 은?\n// (int.parse(\"abc\") == Error(Nil))",
        ["`Error(NotANumber)`", "`Error(Negative)`", "`Error(Nil)`", "`Ok(0)`"],
        0,
        "정확해요! \"abc\"는 정수로 파싱되지 않아 `int.parse`가 `Error(Nil)`을 주고, 바깥 `case`가 이를 `Error(NotANumber)`로 옮깁니다.",
        [
          #(1, "`Negative`는 *파싱은 됐지만 음수*일 때예요. \"abc\"는 애초에 숫자로 파싱되지 않습니다."),
          #(2, "`int.parse`의 원래 `Error(Nil)`을 우리 함수가 의미 있는 `Error(NotANumber)`로 바꿔 돌려줘요."),
          #(3, "파싱 실패는 성공값 0이 아니에요 — `Ok`가 아니라 `Error(NotANumber)`입니다."),
        ],
      ),
      predict(
        "parse-8",
        "같은 함수에서 `parse_age(\"8\")`의 값은?",
        "// parse_age(\"8\") 은?\n// (int.parse(\"8\") == Ok(8), 그리고 8 >= 0)",
        ["`Ok(8)`", "`8`", "`Error(NotANumber)`", "`Some(8)`"],
        0,
        "맞아요! \"8\"은 숫자로 파싱되고 음수도 아니라 `Ok(8)` — 성공값도 `Ok`로 포장되어 나옵니다.",
        [
          #(1, "값은 8이 맞지만 `Result`라 `Ok(8)`로 포장돼요 — 꺼내려면 패턴 매칭이 필요합니다."),
          #(2, "\"8\"은 멀쩡한 숫자라 파싱에 성공해요 — `NotANumber`가 아니라 `Ok(8)`."),
          #(3, "`Some`은 `Option`의 생성자예요. `Result`의 성공은 `Ok`로 감쌉니다."),
        ],
      ),
      Prose(
        "use-error-type",
        "커스텀 에러 타입의 진짜 이득은 **호출자 쪽**에서 드러납니다. `case`로 풀 때 각 실패 이유마다 다른 메시지를 줄 수 있고, 이유를 빠뜨리면 컴파일러가 잡아줍니다.\n\n```gleam\npub fn age_message(input: String) -> String {\n  case parse_age(input) {\n    Ok(n) -> \"나이: \" <> int.to_string(n)\n    Error(NotANumber) -> \"숫자가 아니에요\"\n    Error(Negative) -> \"음수는 안 돼요\"\n  }\n}\n```",
      ),
      mcq(
        "message-negative",
        "위 `age_message` 코드로 `age_message(\"-3\")`를 부르면 어떤 문자열이 나올까요?",
        ["`\"음수는 안 돼요\"`", "`\"숫자가 아니에요\"`", "`\"나이: -3\"`", "`\"나이: 0\"`"],
        0,
        "맞아요! `parse_age(\"-3\")`이 `Error(Negative)`라, `Error(Negative)` 가지의 \"음수는 안 돼요\"가 선택됩니다 — 이유별로 다른 메시지를 줄 수 있는 게 커스텀 에러의 힘이에요.",
        [
          #(1, "\"숫자가 아니에요\"는 `Error(NotANumber)` 가지예요. \"-3\"은 숫자로 파싱은 되지만 음수라 `Negative`로 갑니다."),
          #(2, "음수는 `Ok` 가지로 가지 않아요 — \"나이: -3\"은 나오지 않고 에러 메시지가 나옵니다."),
          #(3, "값을 0으로 보정하지 않아요 — 음수는 그대로 `Error(Negative)`로 거부됩니다."),
        ],
      ),
    ],
  )
}

fn lesson_option_vs_result() -> Lesson {
  Lesson(
    id: "l04-option-vs-result",
    unit_id: "u09-option-result",
    title: "Option vs Result 선택 기준",
    emits_tags: [Tricky("option-vs-result"), Concept("options"), Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`Option`과 `Result`는 둘 다 \"값이 없을 수도\"를 다루지만, 쓰임이 다릅니다. 한 줄 기준:\n\n- **\"없음이 정상적인 상태\"면 `Option`** — 부재(없음) 자체가 데이터인 자리. 예: 레코드의 선택적 필드(별명이 없을 수 있다).\n- **\"실패이고 이유가 있으면\" `Result`** — 무언가 잘못됐고 *왜* 잘못됐는지 전할 게 있을 때.\n\n핵심 질문: \"이 없음은 *정상*인가, *실패*인가?\"",
      ),
      mcq(
        "optional-field",
        "사용자 프로필에서 `nickname`(별명)은 \"설정 안 했을 수도 있는\" 선택적 필드입니다. 별명이 없는 건 오류가 아니라 흔하고 정상적인 상태예요. 이 필드의 타입으로 가장 알맞은 것은?",
        [
          "`Option(String)` — 부재가 정상 데이터라서",
          "`Result(String, Nil)` — 별명은 실패할 수 있어서",
          "`String` — 없으면 빈 문자열로",
          "`Result(String, String)` — 이유를 담으려고",
        ],
        0,
        "맞아요! 별명 없음은 *실패*가 아니라 *정상적인 부재*예요 — 그래서 `Option(String)`이 딱 맞습니다. `None`이 \"별명 미설정\"을 자연스럽게 표현하죠.",
        [
          #(1, "별명이 없는 건 실패가 아니라 정상이에요 — 전할 \"실패 이유\"가 없으니 `Result`는 과합니다."),
          #(2, "빈 문자열은 \"있는데 빈 값\"과 \"아예 없음\"을 구분 못 해요 — `Option`이 그 둘을 분명히 나눕니다."),
          #(3, "담을 실패 이유가 없는데 에러 타입을 두는 건 군더더기예요 — 정상적 부재엔 `Option`."),
        ],
      ),
      Prose(
        "result-default",
        "그런데 Gleam stdlib를 보면, 실패 이유가 *하나뿐*일 때조차 `Option`이 아니라 **`Result(a, Nil)`**을 쓰는 경우가 많습니다 — `int.parse`, `list.first`가 그래요. 관용적으로 **`Result`가 기본값**이고, `Option`은 \"부재가 데이터인\" 특별한 자리에 아껴 씁니다. \"파싱 실패\"나 \"빈 리스트의 첫 원소\"는 *정상적 부재*라기보다 *그 연산의 실패*이기 때문이에요.",
      ),
      mcq(
        "stdlib-idiom",
        "`int.parse(\"abc\")`가 `Option`이 아니라 `Result(Int, Nil)`로 `Error(Nil)`을 돌려주는 이유로 가장 적절한 것은?",
        [
          "\"abc를 정수로\"는 정상적 부재가 아니라 연산의 *실패*라서 — stdlib는 이런 경우 Result가 기본",
          "Gleam에는 Option이 없어서",
          "Result가 Option보다 항상 빠르기 때문에",
          "`int.parse`만의 특수 규칙이라 다른 함수는 Option을 쓴다",
        ],
        0,
        "맞아요! 파싱이 안 되는 건 \"없음이 정상\"이 아니라 \"이 연산이 실패\"라는 신호예요 — 그래서 관용적으로 `Result`(`list.first`도 동일)를 씁니다.",
        [
          #(1, "Gleam에는 `Option`이 분명히 있어요(`gleam/option`). 다만 *실패*엔 `Result`가 관용입니다."),
          #(2, "속도 때문이 아니라 *의미* 때문이에요 — 부재(데이터)냐 실패냐의 구분입니다."),
          #(3, "`list.first`도 같은 이유로 `Result`를 써요 — `int.parse`만의 예외가 아닙니다."),
        ],
      ),
      mcq(
        "spot-awkward",
        "다음 네 함수 시그니처 중, 타입 선택이 **어색한** 것 하나는?",
        [
          "`fn divide(a: Int, b: Int) -> Option(Int)`",
          "`fn find_user(id: Int) -> Result(User, Nil)`",
          "`fn middle_name(p: Person) -> Option(String)`",
          "`fn parse_age(s: String) -> Result(Int, AgeError)`",
        ],
        0,
        "맞아요! 0으로 나누기는 *정상적 부재*가 아니라 연산의 *실패*예요 — `Option`보다 `Result(Int, ...)`가 적절합니다. 기준: \"없음이 정상이면 Option, 실패이면 Result\".",
        [
          #(1, "사용자 조회 실패에 `Result`는 자연스러워요 — stdlib 관용대로 이유가 하나면 `Result(_, Nil)`도 OK."),
          #(2, "중간 이름(middle name)은 \"없는 게 정상\"인 선택적 필드라 `Option`이 딱 맞아요 — 어색하지 않습니다."),
          #(3, "나이 파싱은 실패에 이유(`AgeError`)가 있으니 `Result(Int, AgeError)`가 정석이에요 — 어색하지 않습니다."),
        ],
      ),
    ],
  )
}

fn lesson_stdlib_results() -> Lesson {
  Lesson(
    id: "l05-stdlib-results",
    unit_id: "u09-option-result",
    title: "stdlib의 Result들",
    emits_tags: [Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "이제 표준 라이브러리가 곳곳에서 `Result`를 돌려주는 게 보일 거예요. 대표 두 가지:\n\n- **`int.parse(String) -> Result(Int, Nil)`** — 문자열을 정수로. 정수가 아니면 `Error(Nil)`.\n- **`list.first(List(a)) -> Result(a, Nil)`** — 리스트의 첫 원소. 빈 리스트면 `Error(Nil)`.\n\n둘 다 실패 이유가 하나뿐이라 에러 타입이 `Nil`입니다(U9-④의 관용 그대로). 그래도 \"꺼내려면 패턴 매칭\"은 똑같이 적용돼요.",
      ),
      predict(
        "parse-int-ok",
        "`int.parse`의 결과는?",
        "import gleam/int\n\nint.parse(\"42\")",
        ["`Ok(42)`", "`42`", "`Error(Nil)`", "`Some(42)`"],
        0,
        "맞아요! \"42\"는 정수로 잘 파싱돼 `Ok(42)` — 성공값도 `Ok`로 포장됩니다.",
        [
          #(1, "값은 42지만 `Result`라 `Ok(42)`로 포장돼요 — 맨몸 `42`로는 안 나옵니다."),
          #(2, "\"42\"는 멀쩡한 정수라 성공이에요 — `Error(Nil)`은 파싱이 *안 될* 때입니다."),
          #(3, "`int.parse`는 `Result`를 돌려줘요 — `Some`이 아니라 `Ok`로 감쌉니다."),
        ],
      ),
      predict(
        "parse-float",
        "`int.parse`는 *정수* 전용입니다. `int.parse(\"4.2\")`의 값은?",
        "import gleam/int\n\nint.parse(\"4.2\")",
        ["`Error(Nil)`", "`Ok(4)`", "`Ok(4.2)`", "`4.2`"],
        0,
        "정확해요! \"4.2\"는 *정수*가 아니라 `int.parse`가 실패해 `Error(Nil)`을 줍니다. 소수점이 있으면 정수 파싱은 안 돼요.",
        [
          #(1, "버림(4로 절삭)을 하지 않아요 — \"4.2\"는 정수 형식이 아니라 통째로 파싱 실패입니다."),
          #(2, "`int.parse`는 `Int`만 만들어요 — `Float` `4.2`를 돌려주지 않습니다(애초에 실패예요)."),
          #(3, "값이 맨몸으로 나오지도, 파싱되지도 않아요 — `Error(Nil)`입니다."),
        ],
      ),
      Prose(
        "list-first",
        "`list.first`도 같은 모양입니다. 원소가 하나라도 있으면 첫 원소를 `Ok`로, 비어 있으면 `Error(Nil)`로 돌려줘요. \"비었을 수도 있는 리스트의 첫 원소\"를 안전하게 다루는 방법입니다 — 빈 리스트에서 크래시하지 않아요.",
      ),
      predict(
        "first-ok",
        "`list.first`의 결과는?",
        "import gleam/list\n\nlist.first([10, 20, 30])",
        ["`Ok(10)`", "`10`", "`Ok([10, 20, 30])`", "`Ok(30)`"],
        0,
        "맞아요! 첫 원소 10이 `Ok`로 포장되어 `Ok(10)`입니다.",
        [
          #(1, "값은 10이지만 `Result`라 `Ok(10)`으로 포장돼요 — 맨몸으로는 안 나옵니다."),
          #(2, "`first`는 리스트 전체가 아니라 *첫 원소 하나*를 줘요 — `Ok(10)`."),
          #(3, "`first`는 맨 *앞* 원소예요 — 마지막 30이 아니라 첫 10입니다(`list.last`가 마지막)."),
        ],
      ),
      predict(
        "first-empty",
        "빈 리스트에 `list.first`를 쓰면? `list.first([])`의 값은?",
        "import gleam/list\n\nlist.first([])",
        ["`Error(Nil)`", "`Ok(Nil)`", "프로그램이 크래시한다", "`[]`"],
        0,
        "정확해요! 빈 리스트엔 첫 원소가 없어 `Error(Nil)` — 실패가 값으로 돌아오니 크래시하지 않아요.",
        [
          #(1, "빈 리스트는 성공이 아니에요 — `Ok`가 아니라 `Error(Nil)`로 \"첫 원소 없음\"을 알립니다."),
          #(2, "예외가 없으니 크래시하지 않아요 — `Result`가 실패를 안전하게 표현합니다."),
          #(3, "빈 리스트 그대로가 아니라 `Result` 값(`Error(Nil)`)이 나옵니다."),
        ],
      ),
      mcq(
        "why-result",
        "`int.parse`와 `list.first`가 굳이 맨 값 대신 `Result`를 돌려주는 이유로 가장 적절한 것은?",
        [
          "실패(파싱 불가·빈 리스트)를 *값*으로 표현해, 호출자가 case로 두 경우를 안전하게 다루게 하려고",
          "Result가 Int보다 메모리를 적게 써서",
          "Gleam 함수는 항상 Result만 반환할 수 있어서",
          "디버깅 출력을 예쁘게 하려고",
        ],
        0,
        "맞아요! 실패를 예외로 던지는 대신 `Result` 값으로 돌려주면, 컴파일러가 \"실패도 다뤘니?\"를 강제해 빠진 처리를 막아줍니다 — 이 유닛의 핵심이에요.",
        [
          #(1, "메모리 절약과는 무관해요 — 이유는 *실패를 안전하게 표현*하기 위함입니다."),
          #(2, "함수는 어떤 타입이든 반환할 수 있어요 — `Result`는 실패 가능성이 있을 때의 선택입니다."),
          #(3, "디버깅 표시 때문이 아니라, 실패를 타입으로 드러내 호출자가 처리하도록 만들기 위함이에요."),
        ],
      ),
    ],
  )
}

fn unit_result_use() -> Unit {
  let meta =
    UnitMeta(
      id: "u10-result-use",
      title: "Result 체이닝과 use",
      order: 10,
      level: 3,
      concepts: [
        Concept("results"), Concept("use-expressions"),
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
    title: "case 계단의 고통",
    emits_tags: [Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "U9에서 만든 `parse_age`를 기억하나요? 실패할 수 있는 연산은 `Result(성공, 실패)`를 돌려주고, 호출자는 `case`로 `Ok`와 `Error` **두 경우 모두**를 다뤄야 했습니다.\n\n```gleam\npub fn parse_age(input: String) -> Result(Int, AgeError) {\n  case int.parse(input) {\n    Error(Nil) -> Error(NotANumber)\n    Ok(n) -> case n < 0 {\n      True -> Error(Negative)\n      False -> Ok(n)\n    }\n  }\n}\n```\n\n그런데 **두 개**의 Result를 이어 써야 한다면 어떻게 될까요? 예를 들어 두 나이를 각각 파싱해서 더하려면요.",
      ),
      Prose(
        "stairs",
        "각 `parse_age`가 Result라서, 안쪽 값을 꺼내려면 `case`로 풀어야 합니다. 그런데 두 번 풀다 보면 case가 **계단처럼 중첩**됩니다:\n\n```gleam\npub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  case parse_age(a) {\n    Error(e) -> Error(e)\n    Ok(age_a) -> case parse_age(b) {\n      Error(e) -> Error(e)\n      Ok(age_b) -> Ok(age_a + age_b)\n    }\n  }\n}\n```\n\n`Error(e) -> Error(e)` 줄이 계단마다 똑같이 반복되는 게 보이나요? 이 군더더기가 바로 이번 유닛에서 펴낼 대상입니다.",
      ),
      predict(
        "stairs-both-ok",
        "위 계단형 `add_ages`에서 `add_ages(\"5\", \"7\")`의 값은?",
        "// 위 정의에서\nadd_ages(\"5\", \"7\")",
        ["`Ok(12)`", "`12`", "`Ok(5)`", "`Error(NotANumber)`"],
        0,
        "맞아요! 둘 다 `Ok`라 바깥 case가 `age_a`(5), 안쪽이 `age_b`(7)를 꺼내 `Ok(5 + 7)` = `Ok(12)`를 냅니다.",
        [
          #(
            1,
            "Result에서 값은 맨몸으로 나오지 않아요. 함수 반환 타입이 `Result`라 마지막도 `Ok(...)`로 포장됩니다 — `12`가 아니라 `Ok(12)`.",
          ),
          #(
            2,
            "바깥 case만 본 거예요. 안쪽 `parse_age(\"7\")`까지 풀어 둘을 더한 `Ok(12)`가 결과입니다.",
          ),
          #(
            3,
            "두 입력 모두 정상 숫자라 어느 가지도 Error로 빠지지 않아요 — `Ok(12)`입니다.",
          ),
        ],
      ),
      predict(
        "stairs-second-fail",
        "같은 계단형 `add_ages`에서 `add_ages(\"3\", \"x\")`의 값은? (`\"x\"`는 숫자가 아님)",
        "// 위 정의에서\nadd_ages(\"3\", \"x\")",
        ["`Ok(3)`", "`Error(NotANumber)`", "`Error(Negative)`", "`Ok(0)`"],
        1,
        "정확해요! 바깥 `parse_age(\"3\")`은 `Ok(3)`라 안쪽으로 들어가지만, `parse_age(\"x\")`가 `Error(NotANumber)`라 그 가지가 그대로 함수의 결과가 됩니다.",
        [
          #(
            0,
            "첫 파싱이 성공해도 두 번째가 실패하면 전체가 실패예요. 안쪽 case의 `Error` 가지가 결과가 됩니다 — `Ok(3)`이 아니라 `Error(NotANumber)`.",
          ),
          #(
            2,
            "`Negative`는 음수일 때의 에러예요. `\"x\"`는 음수가 아니라 아예 숫자가 아니므로 `NotANumber`입니다.",
          ),
          #(
            3,
            "실패는 `Ok(0)` 같은 기본값으로 슬쩍 넘어가지 않아요 — 에러가 타입에 남아 `Error(NotANumber)`로 드러납니다.",
          ),
        ],
      ),
      Prose(
        "pain",
        "이 계단의 고통은 분명합니다. Result를 이을 때마다 case가 한 단씩 깊어지고, `Error(e) -> Error(e)`라는 **\"실패면 그대로 흘려보낸다\"** 코드가 똑같이 반복됩니다. 다음 레슨에서 stdlib의 `result.map`과 `result.try`로 이 반복을 걷어냅니다.",
      ),
      mcq(
        "stairs-why-nested",
        "두 Result를 이어 쓸 때 case가 중첩 계단이 되는 근본 이유는?",
        [
          "Gleam의 case는 한 번에 한 값만 검사할 수 있어서",
          "각 Result의 안쪽 값(`Ok`의 내용물)을 꺼내려면 `case`로 풀어야 하고, 두 번 풀면 한 풀이가 다른 풀이 안에 들어가기 때문",
          "`Result` 타입끼리는 직접 더할 수 없어서 컴파일 에러가 나기 때문",
          "`parse_age`가 재귀 함수라서",
        ],
        1,
        "맞아요! `Ok(n)`의 `n`을 쓰려면 매번 case로 포장을 풀어야 하고, 두 값을 모두 풀려면 한 case가 다른 case 안에 들어가 계단이 됩니다.",
        [
          #(
            0,
            "case는 `case a, b { ... }`로 여러 값을 동시에 검사할 수 있어요. 계단의 원인은 그게 아니라 Result 포장을 차례로 푸는 데 있습니다.",
          ),
          #(
            2,
            "컴파일 에러 때문이 아니에요. 안쪽 값을 꺼낸 뒤 더하는 건 정상이고, 문제는 꺼내는 과정이 중첩된다는 점입니다.",
          ),
          #(
            3,
            "`parse_age`는 재귀가 아니에요. 계단은 재귀가 아니라 Result를 두 번 푸는 데서 생깁니다.",
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
    title: "result.map과 result.try",
    emits_tags: [Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "계단을 펴기 전에, 두 가지 도구를 익힙니다. 둘 다 **\"Error면 그대로 흘려보내고, Ok면 안쪽 값에 함수를 적용\"**한다는 점은 같지만, 적용하는 함수의 반환 타입이 다릅니다.\n\n- `result.map(결과, fn(x) { ... })` — 콜백이 **평범한 값**을 돌려줍니다. map이 그 값을 다시 `Ok(...)`로 포장해 줍니다.\n- `result.try(결과, fn(x) { ... })` — 콜백이 **또 다른 Result**를 돌려줍니다. try는 그것을 그대로 결과로 씁니다(이중 포장 없음).",
      ),
      predict(
        "map-ok",
        "`result.map`은 Ok면 안쪽 값에 함수를 적용하고 다시 Ok로 포장합니다. 이 값은?",
        "result.map(Ok(5), fn(x) { x * 2 })",
        ["`Ok(10)`", "`10`", "`Ok(5)`", "`Ok(Ok(10))`"],
        0,
        "정확해요! `Ok(5)`의 안쪽 5에 `* 2`를 적용해 10, 그걸 다시 `Ok`로 포장해 `Ok(10)`.",
        [
          #(
            1,
            "map은 결과를 다시 `Ok`로 포장합니다 — 맨몸 `10`이 아니라 `Ok(10)`이에요.",
          ),
          #(
            2,
            "함수 `x * 2`가 적용되므로 안쪽 값이 바뀝니다 — `Ok(5)`가 아니라 `Ok(10)`.",
          ),
          #(
            3,
            "콜백이 평범한 값(`10`)을 돌려주므로 포장은 한 겹뿐이에요 — `Ok(10)`이지 `Ok(Ok(10))`이 아닙니다.",
          ),
        ],
      ),
      predict(
        "map-error",
        "`result.map`에 `Error`가 들어오면 콜백은 호출되지 않고 Error가 그대로 통과합니다. 이 값은?",
        "let r: Result(Int, String) = Error(\"nope\")\nresult.map(r, fn(x) { x * 2 })",
        ["`Error(\"nope\")`", "`Ok(\"nope\")`", "`Error(0)`", "`\"nope\"`"],
        0,
        "맞아요! Error면 콜백 `x * 2`는 아예 실행되지 않고, `Error(\"nope\")`가 손대지 않은 채 그대로 나옵니다.",
        [
          #(
            1,
            "에러가 `Ok`로 바뀌지 않아요 — map은 Error를 만나면 손대지 않고 그대로 흘려보냅니다.",
          ),
          #(
            2,
            "에러 안의 값도 바뀌지 않습니다. `x * 2`는 Ok의 안쪽에만 적용돼요 — Error는 통과만 합니다.",
          ),
          #(
            3,
            "Result에서 값은 맨몸으로 나오지 않아요. 포장이 벗겨지지 않고 `Error(\"nope\")` 그대로입니다.",
          ),
        ],
      ),
      Prose(
        "try-chains",
        "이제 핵심인 `result.try`입니다. 콜백이 **Result를 돌려줄 때** 씁니다 — 그래서 Result를 내는 연산을 줄줄이 이을 수 있어요. \"Ok면 콜백으로 계속, Error면 즉시 단락(short-circuit)\"이 정확히 계단의 `Error(e) -> Error(e)`를 대신합니다.\n\n```gleam\nresult.try(int.parse(\"4\"), fn(n) {\n  result.try(int.parse(\"6\"), fn(m) {\n    Ok(n + m)\n  })\n})\n```",
      ),
      predict(
        "try-chain-ok",
        "위 `result.try` 중첩 호출의 값은? (`int.parse`는 `Result(Int, Nil)`)",
        "result.try(int.parse(\"4\"), fn(n) {\n  result.try(int.parse(\"6\"), fn(m) {\n    Ok(n + m)\n  })\n})",
        ["`Ok(10)`", "`10`", "`Ok(Ok(10))`", "`Error(Nil)`"],
        0,
        "정확해요! `int.parse(\"4\")`=`Ok(4)`라 `n`=4로 진행, `int.parse(\"6\")`=`Ok(6)`라 `m`=6, 마지막 `Ok(4 + 6)` = `Ok(10)`.",
        [
          #(
            1,
            "마지막 줄이 `Ok(n + m)`이라 결과는 `Ok`로 포장돼요 — `10`이 아니라 `Ok(10)`.",
          ),
          #(
            2,
            "`try`는 콜백이 돌려준 Result를 그대로 씁니다(이중 포장 없음). 마지막이 `Ok(10)`이라 전체도 `Ok(10)`이에요.",
          ),
          #(
            3,
            "두 파싱 모두 성공하므로 단락되지 않아요 — `Error(Nil)`이 아니라 `Ok(10)`입니다.",
          ),
        ],
      ),
      predict(
        "try-chain-shortcircuit",
        "같은 모양에서 첫 파싱이 실패하면? `int.parse(\"x\")`는 `Error(Nil)`입니다. 이 값은?",
        "result.try(int.parse(\"x\"), fn(n) {\n  result.try(int.parse(\"6\"), fn(m) {\n    Ok(n + m)\n  })\n})",
        ["`Ok(6)`", "`Error(Nil)`", "`Ok(Error(Nil))`", "`Ok(0)`"],
        1,
        "맞아요! 첫 `int.parse(\"x\")`가 `Error(Nil)`라 `try`가 즉시 단락합니다 — 콜백은 실행되지 않고 `Error(Nil)`이 그대로 결과예요.",
        [
          #(
            0,
            "첫 단계가 실패하면 안쪽 콜백은 아예 실행되지 않아요. `int.parse(\"6\")`에는 도달조차 못 합니다 — `Error(Nil)`입니다.",
          ),
          #(
            2,
            "단락된 Error는 `Ok`로 감싸이지 않아요. try는 Error를 그대로 흘려보내 `Error(Nil)`을 냅니다.",
          ),
          #(
            3,
            "실패가 기본값으로 무마되지 않습니다 — 에러가 타입에 그대로 남아 `Error(Nil)`로 나와요.",
          ),
        ],
      ),
      mcq(
        "map-vs-try",
        "콜백이 **그 자체로 또 다른 Result를 돌려줄 때** `result.map`을 쓰면 어떤 일이 생기나요? 예: `result.map(int.parse(\"4\"), fn(n) { Ok(n + 1) })`",
        [
          "`Ok(5)` — map이 알아서 한 겹으로 평탄화한다",
          "`Ok(Ok(5))` — map은 콜백 결과를 무조건 한 번 더 Ok로 감싸 이중 포장이 된다",
          "컴파일 에러 — map은 Result를 돌려주는 콜백을 받을 수 없다",
          "`Error(Nil)` — Result가 섞이면 실패로 본다",
        ],
        1,
        "맞아요! map은 콜백이 무엇을 돌려주든 한 번 더 `Ok`로 감쌉니다. 콜백이 이미 `Ok(5)`를 돌려주면 `Ok(Ok(5))`라는 이중 포장이 돼요 — 이럴 땐 `try`를 써야 합니다.",
        [
          #(
            0,
            "평탄화는 `try`의 일이에요. map은 무조건 한 겹을 더 씌우므로 여기선 `Ok(Ok(5))`가 됩니다.",
          ),
          #(
            2,
            "컴파일은 됩니다 — 다만 의도와 달리 `Ok(Ok(5))`처럼 이중 포장된 타입이 나와 버려요.",
          ),
          #(
            3,
            "Result가 섞였다고 실패로 보지 않아요. 두 겹으로 포장된 성공값 `Ok(Ok(5))`가 나옵니다.",
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
    title: "use — 계단을 펴는 설탕",
    emits_tags: [Concept("use-expressions"), Concept("results")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`result.try`로 단락은 해결했지만, 콜백이 또 다른 `try`를 품으면서 여전히 오른쪽으로 들여쓰기가 깊어집니다. Gleam의 `use` 표현식은 이 연쇄를 **위에서 아래로 평평하게** 펴 줍니다.\n\n```gleam\nimport gleam/result\n\npub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  use age_a <- result.try(parse_age(a))\n  use age_b <- result.try(parse_age(b))\n  Ok(age_a + age_b)\n}\n```\n\n계단이 사라지고, `Error(e) -> Error(e)` 반복도 없습니다. `use age_a <- ...`는 \"이 Result가 Ok면 그 값을 `age_a`로 받아 아래를 계속하고, Error면 그대로 단락\"이라고 읽습니다.",
      ),
      predict(
        "addages-ok",
        "위 `use` 버전 `add_ages`에서 `add_ages(\"8\", \"9\")`의 값은?",
        "pub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  use age_a <- result.try(parse_age(a))\n  use age_b <- result.try(parse_age(b))\n  Ok(age_a + age_b)\n}\n\nadd_ages(\"8\", \"9\")",
        ["`Ok(17)`", "`17`", "`Ok(8)`", "`Error(NotANumber)`"],
        0,
        "정확해요! 두 파싱 모두 Ok라 `age_a`=8, `age_b`=9로 내려가고, 마지막 `Ok(8 + 9)` = `Ok(17)`.",
        [
          #(
            1,
            "함수 반환 타입이 `Result`라 마지막 줄도 `Ok(...)`예요 — 맨몸 `17`이 아니라 `Ok(17)`.",
          ),
          #(
            2,
            "두 `use` 줄을 모두 통과한 뒤 둘을 더합니다 — `age_a`만 본 `Ok(8)`이 아니라 `Ok(17)`.",
          ),
          #(
            3,
            "두 입력 모두 정상 숫자라 단락되지 않아요 — `Error`가 아니라 `Ok(17)`입니다.",
          ),
        ],
      ),
      Prose(
        "shortcircuit",
        "이번 유닛의 핵심 직관입니다. `use` 줄에서 `result.try`가 `Error`를 받으면, **그 아래 줄들은 아예 실행되지 않고** Error가 그대로 함수의 반환값이 됩니다.\n\nU3에서 \"Gleam엔 early return이 없다\"고 배웠죠. `use` + `result.try`의 단락이 바로 그 early return의 역할을, **타입 안전하게**(Result 타입으로) 수행하는 셈입니다.",
      ),
      predict(
        "addages-shortcircuit",
        "`add_ages(\"3\", \"x\")`의 값은? (`use` 버전, `\"x\"`는 숫자가 아님)",
        "pub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  use age_a <- result.try(parse_age(a))\n  use age_b <- result.try(parse_age(b))\n  Ok(age_a + age_b)\n}\n\nadd_ages(\"3\", \"x\")",
        ["`Ok(3)`", "`Error(NotANumber)`", "`Ok(0)`", "`Error(Negative)`"],
        1,
        "맞아요! 첫 줄은 `Ok(3)`라 `age_a`=3로 내려가지만, 둘째 `use` 줄의 `parse_age(\"x\")`가 `Error(NotANumber)`라 거기서 단락 — 아래 `Ok(...)`는 실행되지 않고 그 Error가 반환됩니다.",
        [
          #(
            0,
            "use 줄에서 Error가 나오면 그 아래는 실행되지 않고 Error가 그대로 함수의 반환값이 됩니다. early return이 없다더니, Result 체이닝이 그 역할을 타입 안전하게 수행하는 셈입니다 — `Ok(3)`이 아니라 `Error(NotANumber)`.",
          ),
          #(
            2,
            "단락은 `Ok(0)` 같은 기본값을 만들지 않아요. 실패한 Error를 그대로 반환합니다 — `Error(NotANumber)`.",
          ),
          #(
            3,
            "`\"x\"`는 음수가 아니라 숫자 자체가 아니므로 `NotANumber`예요 — `Negative`가 아닙니다.",
          ),
        ],
      ),
      predict(
        "addages-negative",
        "`add_ages(\"-3\", \"4\")`의 값은? (`parse_age`는 음수면 `Error(Negative)`)",
        "pub fn add_ages(a: String, b: String) -> Result(Int, AgeError) {\n  use age_a <- result.try(parse_age(a))\n  use age_b <- result.try(parse_age(b))\n  Ok(age_a + age_b)\n}\n\nadd_ages(\"-3\", \"4\")",
        ["`Error(Negative)`", "`Error(NotANumber)`", "`Ok(1)`", "`Ok(-3)`"],
        0,
        "정확해요! 첫 `parse_age(\"-3\")`이 숫자 파싱엔 성공하지만 음수라 `Error(Negative)`를 냅니다 — 첫 `use` 줄에서 바로 단락됩니다.",
        [
          #(
            1,
            "`\"-3\"`은 정수 파싱 자체는 성공해요(부호 포함). 다만 음수라서 `Negative`로 걸립니다 — `NotANumber`가 아니에요.",
          ),
          #(
            2,
            "첫 줄에서 이미 단락되므로 덧셈에 도달하지 못해요 — `Ok(1)`이 아니라 `Error(Negative)`.",
          ),
          #(
            3,
            "단락된 결과는 `Error`예요. 게다가 음수 입력은 `parse_age`가 거부하므로 `Ok(-3)`이 될 수 없습니다.",
          ),
        ],
      ),
      mcq(
        "forgot-ok",
        "`use`로 다 펴고 마지막 줄을 `Ok(age_a + age_b)`가 아니라 그냥 `age_a + age_b`로 쓰면 어떻게 될까요?",
        [
          "잘 동작한다 — Gleam이 알아서 Ok로 감싼다",
          "타입 불일치(Type mismatch) 컴파일 에러 — 함수 반환 타입은 `Result`인데 마지막 식이 `Int`라서",
          "런타임에 에러가 난다",
          "항상 `Error`를 반환한다",
        ],
        1,
        "맞아요! use를 다 펴도 함수의 반환 타입은 여전히 `Result`입니다. 마지막 성공값을 `Ok`로 포장하는 것을 잊는 실수는 `use-expr` 테마의 1번 단골이라, 컴파일러가 Type mismatch로 잡아줍니다.",
        [
          #(
            0,
            "Gleam은 자동으로 `Ok`를 씌워주지 않아요. 반환 타입이 `Result(Int, _)`인데 마지막이 `Int`면 타입이 어긋나 컴파일 에러입니다.",
          ),
          #(
            2,
            "런타임이 아니라 컴파일 타임에 막혀요 — 타입이 맞지 않으면 실행조차 되지 않습니다.",
          ),
          #(
            3,
            "`Error`를 반환하는 게 아니라 아예 컴파일되지 않아요 — 타입 불일치입니다.",
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
    title: "use의 정체 — 디슈가링과 한계",
    emits_tags: [
      Concept("use-expressions"), Tricky("use-desugaring"),
    ],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`use`는 마법이 아니라 **문법 설탕(syntactic sugar)**입니다. 정체를 알면 헷갈릴 일이 없어요.\n\n```gleam\nuse x <- f(arg)\n나머지_코드\n```\n\n이 한 줄은 정확히 다음과 같이 풀립니다(디슈가링):\n\n```gleam\nf(arg, fn(x) { 나머지_코드 })\n```\n\n핵심: **`use` 줄 아래의 \"나머지 코드 전체\"가 마지막 인자인 콜백 `fn(x) { ... }`의 본문으로 통째로 들어갑니다.** 일부만 들어가는 게 아니라 전부입니다.",
      ),
      predict(
        "desugar-equiv",
        "다음 두 코드는 같은 함수입니다(하나는 use, 하나는 디슈가링된 형태). `add(\"10\", \"5\")`의 값은?",
        "// use 버전\n//   use x <- result.try(int.parse(a))\n//   use y <- result.try(int.parse(b))\n//   Ok(x + y)\n// 디슈가링 버전:\nresult.try(int.parse(\"10\"), fn(x) {\n  result.try(int.parse(\"5\"), fn(y) {\n    Ok(x + y)\n  })\n})",
        ["`Ok(15)`", "`15`", "`Ok(Ok(15))`", "`Error(Nil)`"],
        0,
        "정확해요! 두 형태는 완전히 같은 코드예요. `x`=10, `y`=5로 내려가 마지막 `Ok(10 + 5)` = `Ok(15)`입니다.",
        [
          #(
            1,
            "마지막이 `Ok(x + y)`라 결과는 포장돼요 — 맨몸 `15`가 아니라 `Ok(15)`.",
          ),
          #(
            2,
            "`try`는 콜백이 돌려준 Result를 그대로 써요(이중 포장 없음) — `Ok(15)`이지 `Ok(Ok(15))`가 아닙니다.",
          ),
          #(
            3,
            "두 파싱 모두 성공하므로 단락되지 않아요 — `Ok(15)`입니다.",
          ),
        ],
      ),
      Prose(
        "general-sugar",
        "여기서 중요한 통찰: `use`는 `result.try` 전용이 **아닙니다**. 디슈가링이 \"마지막 인자로 콜백을 넘긴다\"이므로, **마지막 인자가 함수인 어떤 함수와도** 쓸 수 있어요(예: `list.map`도 문법적으로는 가능). 다만 단락 흐름이 아닌 곳에 쓰면 오히려 읽기 어려워져서, 관용적으로는 `result.try`/`option`처럼 \"이어가기/단락\" 맥락에 씁니다.\n\n남용 주의: `use`는 들여쓰기를 없애 줄 뿐, 의미를 바꾸지 않습니다.",
      ),
      mcq(
        "desugar-wrong-pairing",
        "다음 중 `use`와 디슈가링이 **잘못** 짝지어진 것은?",
        [
          "`use x <- f(a)` ⟶ `f(a, fn(x) { 나머지 })`",
          "`use x <- f(a)` ⟶ `f(fn(x) { 나머지 }, a)`  (콜백이 첫 인자)",
          "`use a, b <- f(x)` ⟶ `f(x, fn(a, b) { 나머지 })`",
          "`use <- f(x)` ⟶ `f(x, fn() { 나머지 })`  (받는 값 없음)",
        ],
        1,
        "맞아요! 콜백은 항상 **마지막** 인자로 들어갑니다. 첫 인자로 넣는 (2)가 잘못된 짝이에요 — 디슈가링 규칙은 \"나머지 코드를 마지막 인자 콜백으로\"입니다.",
        [
          #(
            0,
            "이건 올바른 짝이에요. `use x <- f(a)`는 정확히 `f(a, fn(x) { 나머지 })`로 풀립니다.",
          ),
          #(
            2,
            "이것도 올바릅니다. 화살표 왼쪽에 여러 이름을 쓰면 콜백 인자도 그만큼(`fn(a, b)`) 됩니다.",
          ),
          #(
            3,
            "이것도 올바른 짝이에요. 화살표 왼쪽이 비면 인자 없는 콜백 `fn() { ... }`이 됩니다.",
          ),
        ],
      ),
      mcq(
        "callback-scope",
        "`use` 줄 아래에 코드가 세 줄 더 있습니다. 그중 콜백 `fn(x) { ... }`의 본문에 들어가는 것은?",
        [
          "바로 다음 한 줄만",
          "`use` 줄 아래의 세 줄 전부",
          "마지막 `Ok(...)` 줄만",
          "아무 줄도 안 들어간다 — use는 그 줄에서 끝난다",
        ],
        1,
        "맞아요! 디슈가링의 핵심은 \"나머지 코드 전체\"가 콜백 본문이 된다는 것입니다 — 아래 세 줄 모두 `fn(x) { ... }` 안으로 들어갑니다.",
        [
          #(
            0,
            "한 줄만 들어가는 게 아니에요. use 아래의 모든 줄이 통째로 콜백 본문이 됩니다.",
          ),
          #(
            2,
            "마지막 줄만이 아니라 use 아래 전부가 콜백 본문이에요 — 중간 줄들도 함께 들어갑니다.",
          ),
          #(
            3,
            "use는 그 줄에서 끝나지 않아요 — 오히려 아래 코드 전체를 콜백으로 감싸 이어 줍니다.",
          ),
        ],
      ),
      predict(
        "use-single-line",
        "한 단계짜리 `use`도 같은 규칙입니다. `inc(\"41\")`의 값은?",
        "pub fn inc(s: String) -> Result(Int, Nil) {\n  use n <- result.try(int.parse(s))\n  Ok(n + 1)\n}\n\ninc(\"41\")",
        ["`Ok(42)`", "`42`", "`Ok(Ok(42))`", "`Error(Nil)`"],
        0,
        "정확해요! `int.parse(\"41\")`=`Ok(41)`라 `n`=41, 콜백 본문 `Ok(41 + 1)` = `Ok(42)`. 디슈가링하면 `result.try(int.parse(\"41\"), fn(n) { Ok(n + 1) })`와 같아요.",
        [
          #(
            1,
            "함수 반환 타입이 `Result`라 마지막도 `Ok(...)`예요 — `42`가 아니라 `Ok(42)`.",
          ),
          #(
            2,
            "`try`는 평탄화하므로 포장이 한 겹뿐이에요 — `Ok(42)`이지 `Ok(Ok(42))`가 아닙니다.",
          ),
          #(
            3,
            "`\"41\"`은 정상 숫자라 파싱이 성공해요 — 단락되지 않고 `Ok(42)`입니다.",
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
      title: "제네릭과 타입 설계 기초",
      order: 11,
      level: 3,
      concepts: [
        Concept("generics"), Concept("type-aliases"), Concept("dicts"),
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
  Unit(meta: meta, lessons: lessons, checkpoint: checkpoint("u11-generics", lessons))
}

fn lesson_type_variables() -> Lesson {
  Lesson(
    id: "l40-type-variables",
    unit_id: "u11-generics",
    title: "타입 변수 — 아무거나 한 가지",
    emits_tags: [Concept("generics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "지금까지 타입은 `Int`, `String`처럼 늘 **대문자**로 시작했습니다. 그런데 함수 시그니처에 `a`, `b`처럼 **소문자** 이름이 보이면 그건 **타입 변수(type variable)**입니다.\n\n타입 변수는 \"아무 타입이나 될 수 있지만, 같은 글자끼리는 반드시 같은 타입\"이라는 약속이에요. 어떤 구체 타입이 들어갈지는 **호출하는 순간** 컴파일러가 추론으로 정합니다.",
      ),
      Prose(
        "pair-map",
        "아래 `pair_map`을 보세요. 두 원소가 같은 타입(`a`)인 튜플을 받아, 각 원소에 `f`를 적용해 새 튜플을 만듭니다.\n\n```gleam\npub fn pair_map(pair: #(a, a), f: fn(a) -> b) -> #(b, b) {\n  let #(x, y) = pair\n  #(f(x), f(y))\n}\n```\n\n`a`는 입력 원소의 타입, `b`는 `f`가 돌려주는 타입입니다. 둘이 달라도 됩니다 — 단지 *같은 글자끼리만* 같으면 돼요.",
      ),
      predict(
        "pair-map-to-string",
        "`int.to_string`은 `Int`를 받아 `String`을 돌려줍니다. 이 호출의 값은?",
        "pair_map(#(1, 2), int.to_string)",
        ["`#(\"1\", \"2\")`", "`#(1, 2)`", "`#(\"1, 2\")`", "컴파일 에러"],
        0,
        "정확해요! `a = Int`, `b = String`으로 채워집니다. 각 원소에 `int.to_string`이 적용돼 `#(\"1\", \"2\")`.",
        [
          #(1, "`f`가 각 원소를 변환합니다 — 원본 그대로(`#(1, 2)`)가 나오지 않아요."),
          #(2, "결과는 문자열 하나가 아니라 **튜플**입니다 — 원소가 각각 변환돼 두 칸으로 남아요."),
          #(3, "`Int`와 `Int`라 `#(a, a)` 약속을 지키므로 정상 컴파일됩니다."),
        ],
      ),
      predict(
        "pair-map-double",
        "이번엔 익명 함수로 각 원소를 2배 합니다. 이 호출의 값은?",
        "pair_map(#(3, 4), fn(n) { n * 2 })",
        ["`#(6, 8)`", "`#(3, 4)`", "`#(7)`", "`#(3, 4, 6, 8)`"],
        0,
        "맞아요! 여기선 `a = Int`, `b = Int`입니다. 3*2=6, 4*2=8이라 `#(6, 8)`.",
        [
          #(1, "`f`가 각 원소에 적용돼 값이 바뀝니다 — 원본이 그대로 남지 않아요."),
          #(2, "두 원소를 더하는 게 아니라, 각각 따로 변환해 **튜플 두 칸**을 유지합니다."),
          #(3, "원소가 늘어나지 않아요 — 입력과 같은 모양 `#(b, b)`, 즉 두 칸입니다."),
        ],
      ),
      mcq(
        "same-letter-rule",
        "`pair: #(a, a)`라는 타입 표기가 **약속하는** 것은 무엇일까요?",
        [
          "튜플의 두 원소는 서로 같은 타입이어야 한다",
          "튜플의 두 원소는 반드시 `Int`여야 한다",
          "튜플의 두 원소는 서로 달라도 된다",
          "튜플은 원소가 정확히 `a`개여야 한다",
        ],
        0,
        "맞아요! 같은 글자 `a`가 두 번 쓰였으니, 두 원소는 *같은* 타입으로 묶입니다. `#(1, \"x\")`처럼 섞으면 컴파일 에러예요.",
        [
          #(1, "`a`는 *아무* 타입이나 될 수 있어요 — `Int`로 고정된 게 아닙니다. 단지 둘이 같기만 하면 돼요."),
          #(2, "다른 타입을 허용하려면 `#(a, b)`처럼 글자를 달리 써야 해요. `#(a, a)`는 같음을 강제합니다."),
          #(3, "`a`는 개수가 아니라 *타입*을 가리키는 이름입니다 — 튜플 칸 수와는 무관해요."),
        ],
      ),
    ],
  )
}

fn lesson_generic_types() -> Lesson {
  Lesson(
    id: "l41-generic-types",
    unit_id: "u11-generics",
    title: "제네릭 커스텀 타입",
    emits_tags: [Concept("generics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "타입 변수는 함수뿐 아니라 **커스텀 타입**에도 붙일 수 있습니다. 사실 이미 써온 `List(a)`, `Option(a)`, `Result(a, e)`가 전부 그런 **제네릭 커스텀 타입**이에요 — 당신도 직접 만들 수 있습니다.\n\n```gleam\npub type Box(a) {\n  Box(inner: a)\n}\n```\n\n`Box(a)`는 \"무언가 하나를 담는 상자\"입니다. `Box(42)`는 `Box(Int)`, `Box(\"hi\")`는 `Box(String)`이 되죠. 담긴 값의 타입이 곧 `a`입니다.",
      ),
      Prose(
        "unbox",
        "상자에서 값을 꺼내는 함수도 제네릭으로 씁니다. `Box(a)`를 받아 그 안의 `a`를 그대로 돌려줘요.\n\n```gleam\npub fn unbox(box: Box(a)) -> a {\n  box.inner\n}\n```\n\n레코드 필드 접근(`box.inner`)은 U4에서 본 그대로입니다 — 제네릭이라고 달라지지 않아요.",
      ),
      predict(
        "unbox-int",
        "`Box(42)`를 풀면? (`unbox(box) -> a`는 `box.inner`를 돌려줍니다)",
        "unbox(Box(42))",
        ["`42`", "`Box(42)`", "`Box(inner: 42)`", "`a`"],
        0,
        "정확해요! `unbox`는 상자 안의 값을 그대로 꺼냅니다 — 포장을 벗긴 `42`.",
        [
          #(1, "`unbox`는 포장을 **벗깁니다** — 상자째로 돌려주지 않아요."),
          #(2, "그건 상자 *자체*를 들여다본 모양이에요. `unbox`는 `inner` 값만 꺼냅니다."),
          #(3, "`a`는 타입 변수(자리표시자)일 뿐, 실제 값이 아니에요 — 여기선 `42`로 채워집니다."),
        ],
      ),
      Prose(
        "map-box",
        "이제 \"상자를 열지 않고 안의 값만 변환\"하는 함수를 봅시다. 입력 타입 `a`와 출력 타입 `b`가 다를 수 있으니 두 타입 변수를 씁니다.\n\n```gleam\npub fn map_box(box: Box(a), f: fn(a) -> b) -> Box(b) {\n  Box(f(box.inner))\n}\n```\n\n낯익지 않나요? 이건 `result.map`, `option.map`과 **똑같은 모양**입니다 — 당신은 방금 그들의 사촌을 만들었어요.",
      ),
      predict(
        "map-box-incr",
        "안의 값에 1을 더하면? `string.inspect`로 찍은 모양을 고르세요.",
        "map_box(Box(5), fn(n) { n + 1 })",
        ["`Box(inner: 6)`", "`6`", "`Box(inner: 5)`", "`Box(5, 6)`"],
        0,
        "맞아요! `f`가 안의 5를 6으로 바꾸고, 결과는 **다시 상자에 담겨** `Box(inner: 6)`.",
        [
          #(1, "`map_box`는 상자째 돌려줍니다 — 벗긴 값(`6`)이 아니라 `Box(inner: 6)`이에요. (벗기려면 `unbox`)"),
          #(2, "`f`가 적용돼 5가 6이 됩니다 — 원래 값이 그대로 남지 않아요."),
          #(3, "상자엔 변환된 값 하나만 들어갑니다 — 옛 값과 새 값이 둘 다 남지 않아요."),
        ],
      ),
      predict(
        "map-box-upper",
        "이번엔 문자열을 대문자화합니다. 결과의 모양은?",
        "map_box(Box(\"gleam\"), string.uppercase)",
        ["`Box(inner: \"GLEAM\")`", "`\"GLEAM\"`", "`Box(inner: \"gleam\")`", "컴파일 에러"],
        0,
        "정확해요! 여기선 `a = String`, `b = String`. 안의 \"gleam\"이 \"GLEAM\"이 되어 다시 상자에 담깁니다.",
        [
          #(1, "결과는 상자입니다 — 벗긴 문자열이 아니라 `Box(inner: \"GLEAM\")`이에요."),
          #(2, "`string.uppercase`가 적용돼 대문자가 됩니다 — 원래대로 남지 않아요."),
          #(3, "`String -> String` 함수라 `fn(a) -> b`에 잘 맞습니다 — 정상 컴파일돼요."),
        ],
      ),
    ],
  )
}

fn lesson_alias_tuple_custom() -> Lesson {
  Lesson(
    id: "l42-alias-tuple-custom",
    unit_id: "u11-generics",
    title: "type alias, 그리고 tuple vs 커스텀 타입",
    emits_tags: [Concept("type-aliases")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "긴 타입을 매번 쓰기 번거로울 때 **type alias**로 짧은 별명을 붙입니다.\n\n```gleam\npub type Pair =\n  #(String, Int)\n```\n\n주의: alias는 *새 타입을 만들지 않습니다*. `Pair`는 그저 `#(String, Int)`의 **다른 이름**일 뿐이라, 둘은 완전히 호환됩니다. 커스텀 타입(`pub type Box(a) { Box(...) }`)이 새 타입을 *만드는* 것과는 다릅니다.",
      ),
      predict(
        "alias-use",
        "`make`는 `Pair`(즉 `#(String, Int)`)를 돌려줍니다. 아래 출력은?\n\n```gleam\npub type Pair = #(String, Int)\npub fn make() -> Pair { #(\"score\", 100) }\n```",
        "let p = make()\np.0 <> \"=\" <> int.to_string(p.1)",
        ["`\"score=100\"`", "`\"score\"`", "`\"100\"`", "컴파일 에러"],
        0,
        "맞아요! `Pair`는 그냥 `#(String, Int)`라 튜플처럼 `.0`/`.1`로 접근합니다 — \"score\" <> \"=\" <> \"100\".",
        [
          #(1, "`.0`만 쓴 게 아니라 `.1`도 이어붙였어요 — 결과는 \"score=100\"."),
          #(2, "`.0`(\"score\")도 함께 이어붙입니다 — \"100\"만 나오지 않아요."),
          #(3, "alias는 새 타입이 아니라 튜플 그 자체라, `.0`/`.1` 접근이 정상 동작합니다."),
        ],
      ),
      Prose(
        "tuple-access",
        "튜플의 원소는 위치로 꺼냅니다: 첫째는 `.0`, 둘째는 `.1`. 이름이 아니라 **순서**로 구분하죠. 그래서 튜플은 \"가볍지만 각 칸이 무슨 뜻인지 코드에 안 적힌다\"는 단점이 있습니다.",
      ),
      predict(
        "tuple-index",
        "튜플의 둘째 원소를 꺼내면?",
        "let user = #(\"lucy\", 30)\nuser.1",
        ["`30`", "`\"lucy\"`", "`#(\"lucy\", 30)`", "`1`"],
        0,
        "정확해요! `.1`은 **둘째** 원소(0부터 셉니다)라 30입니다.",
        [
          #(1, "`.1`이 아니라 `.0`이 첫째(\"lucy\")예요 — 인덱스는 0부터 셉니다."),
          #(2, "`.1`은 튜플 전체가 아니라 *한 칸*만 꺼냅니다 — 30이에요."),
          #(3, "`.1`은 인덱스 표기지 그 숫자 자체를 돌려주는 게 아니에요 — 둘째 원소 30입니다."),
        ],
      ),
      Prose(
        "custom-access",
        "반대로 커스텀 레코드는 칸마다 **이름**이 있습니다. `User(name: \"lucy\", age: 30)`의 둘째 칸은 `.1`이 아니라 `.age`로 꺼내죠.\n\n```gleam\npub type User {\n  User(name: String, age: Int)\n}\n```\n\n원소가 두세 개뿐이고 의미가 자명하면 튜플로 충분하지만, 칸이 늘거나 \"이 칸이 무슨 뜻이지?\" 싶어지면 **이름 있는 커스텀 타입**으로 올리는 게 관용입니다.",
      ),
      predict(
        "record-field",
        "이름 있는 필드로 접근하면?",
        "let u = User(name: \"lucy\", age: 30)\nu.name",
        ["`\"lucy\"`", "`30`", "`\"name\"`", "`User(...)`"],
        0,
        "맞아요! `.name` 필드는 \"lucy\"를 가리킵니다 — 위치(`.0`)가 아니라 *이름*으로 꺼냈어요.",
        [
          #(1, "`.name`이 아니라 `.age`가 30이에요 — 필드 이름을 따라가야 합니다."),
          #(2, "`.name`은 필드 *이름*이 아니라 그 필드의 *값*(\"lucy\")을 돌려줍니다."),
          #(3, "레코드 *값 전체*가 아니라 `name` 한 칸만 꺼냅니다 — \"lucy\"."),
        ],
      ),
      mcq(
        "tuple-vs-custom",
        "다음 중 **커스텀 타입**(튜플 대신)이 더 적절한 상황은?",
        [
          "필드가 5개이고 각각의 의미를 코드에서 분명히 하고 싶을 때",
          "두 값을 잠깐 함께 묶어 곧바로 분해할 때",
          "좌표 `#(x, y)`처럼 의미가 자명한 두 값일 때",
          "함수가 값 두 개를 한꺼번에 돌려줄 임시 묶음이 필요할 때",
        ],
        0,
        "맞아요! 칸이 많고 의미가 중요해질수록, 이름 있는 필드(커스텀 타입)가 코드를 자기 설명적으로 만듭니다.",
        [
          #(1, "잠깐 묶었다 바로 푸는 가벼운 묶음엔 튜플이 더 간편합니다."),
          #(2, "`x, y`처럼 자명한 두 값은 튜플로도 충분히 읽힙니다."),
          #(3, "임시 반환 묶음은 튜플의 전형적인 쓰임새예요 — 굳이 새 타입을 만들 필요는 적습니다."),
        ],
      ),
    ],
  )
}

fn lesson_dicts_sets() -> Lesson {
  Lesson(
    id: "l43-dicts-sets",
    unit_id: "u11-generics",
    title: "Dict와 Set 한 바퀴",
    emits_tags: [Concept("dicts")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "마지막으로 제네릭 컬렉션 둘을 둘러봅니다. **`Dict(k, v)`**는 키(`k`)로 값(`v`)을 찾는 사전입니다(`import gleam/dict`). 타입 변수가 *둘*이라 \"무슨 키든, 무슨 값이든\" 담을 수 있어요.\n\n```gleam\nlet scores = dict.from_list([#(\"lucy\", 10), #(\"max\", 7)])\n```\n\n중요한 점: `dict.get`은 키가 없을 수도 있으니 **`Result`를 돌려줍니다**(U9의 재등장!). 있으면 `Ok(값)`, 없으면 `Error(Nil)`.",
      ),
      predict(
        "dict-get-hit",
        "키가 있을 때 `dict.get`의 값은?",
        "let scores = dict.from_list([#(\"lucy\", 10), #(\"max\", 7)])\ndict.get(scores, \"lucy\")",
        ["`Ok(10)`", "`10`", "`Some(10)`", "`Error(Nil)`"],
        0,
        "맞아요! 값이 있어도 맨몸으로 나오지 않습니다 — `Ok(10)`으로 포장돼 옵니다. 꺼내려면 패턴 매칭.",
        [
          #(1, "Dict 조회는 실패할 수 있어서 결과가 `Result`로 포장됩니다 — `10`이 아니라 `Ok(10)`."),
          #(2, "`dict.get`은 `Option`이 아니라 `Result`를 돌려줍니다 — `Some`이 아니라 `Ok`예요."),
          #(3, "`Error(Nil)`은 키가 *없을* 때예요. \"lucy\"는 사전에 있습니다."),
        ],
      ),
      predict(
        "dict-get-miss",
        "없는 키를 찾으면?",
        "let scores = dict.from_list([#(\"lucy\", 10), #(\"max\", 7)])\ndict.get(scores, \"nobody\")",
        ["`Error(Nil)`", "`Nil`", "`None`", "런타임 크래시"],
        0,
        "정확해요! 키가 없으면 `Error(Nil)`입니다 — 크래시가 아니라 *타입에 적힌 실패*예요. 호출자가 case로 다뤄야 합니다.",
        [
          #(1, "맨 `Nil`이 아니라 `Error(Nil)`로 포장됩니다 — `dict.get`은 `Result`를 돌려줘요."),
          #(2, "`None`은 `Option`의 부재예요. `dict.get`은 `Result`라 `Error(Nil)`을 씁니다."),
          #(3, "없는 키는 크래시가 아니라 `Error(Nil)`로 안전하게 표현됩니다 — 예외가 없으니까요."),
        ],
      ),
      Prose(
        "dict-insert",
        "Dict도 불변입니다. `dict.insert(d, 키, 값)`은 원본을 바꾸지 않고 *새 Dict*를 돌려줘요. 그리고 **같은 키에 다시 넣으면 덮어씁니다** — 키는 중복되지 않습니다.",
      ),
      predict(
        "dict-insert-overwrite",
        "같은 키 `\"a\"`에 두 번 넣은 뒤의 크기(`dict.size`)는?",
        "let d =\n  dict.new()\n  |> dict.insert(\"a\", 1)\n  |> dict.insert(\"a\", 99)\ndict.size(d)",
        ["`1`", "`2`", "`99`", "`0`"],
        0,
        "맞아요! 같은 키는 덮어쓰여 하나로 합쳐집니다 — 크기는 1(값은 99로 갱신).",
        [
          #(1, "키 `\"a\"`가 같아서 두 칸이 되지 않아요 — 둘째 insert가 첫째를 덮습니다."),
          #(2, "`99`는 저장된 *값*이지 *크기*가 아니에요 — 항목은 하나뿐입니다."),
          #(3, "항목을 넣었으니 비어 있지 않아요 — 크기는 1입니다."),
        ],
      ),
      Prose(
        "set",
        "**`Set(a)`**는 \"중복 없는 모음\"입니다(`import gleam/set`). 같은 값을 여러 번 넣어도 하나로 합쳐지고, `set.contains`로 들어있는지만 묻습니다 — 순서나 개수는 신경 쓰지 않아요.",
      ),
      predict(
        "set-dedup",
        "1을 두 번, 2를 한 번 넣은 Set의 크기(`set.size`)는?",
        "let s =\n  set.new()\n  |> set.insert(1)\n  |> set.insert(2)\n  |> set.insert(1)\nset.size(s)",
        ["`2`", "`3`", "`1`", "`0`"],
        0,
        "정확해요! Set은 중복을 합칩니다 — 1이 두 번 들어가도 하나로 세어, 서로 다른 값은 1과 2뿐이라 크기는 2.",
        [
          #(1, "넣은 *횟수*가 아니라 *서로 다른 값*의 수예요 — 1의 중복이 합쳐져 2입니다."),
          #(2, "값이 두 종류(1, 2)라 크기는 1이 아니에요. 중복만 합쳐집니다."),
          #(3, "원소를 넣었으니 비어 있지 않아요 — 크기는 2입니다."),
        ],
      ),
    ],
  )
}

fn unit_opaque_types() -> Unit {
  let meta =
    UnitMeta(
      id: "u12-opaque-types",
      title: "Opaque Type과 API 설계",
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
    title: "잘못된 값을 만들 수 없게 — opaque + smart constructor",
    emits_tags: [Concept("opaque-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "보통 `pub type`은 타입 이름과 **생성자**를 함께 공개합니다. 그래서 누구든 `Amount(-999)`처럼 값을 직접 만들 수 있죠 — 음수 금액 같은 잘못된 값까지요.\n\n`pub opaque type`은 타입 **이름만** 공개하고, 생성자는 모듈 안에 가둡니다. 바깥에서는 값을 직접 만들 수 없고, 모듈이 제공하는 함수로만 만들 수 있어요.\n\n```\npub opaque type Amount {\n  Amount(cents: Int)\n}\n\npub fn new(cents: Int) -> Result(Amount, String) {\n  case cents >= 0 {\n    True -> Ok(Amount(cents))\n    False -> Error(\"amount must not be negative\")\n  }\n}\n\npub fn cents(amount: Amount) -> Int {\n  amount.cents\n}\n```\n\n이렇게 \"검증을 통과한 값만 존재할 수 있게\" 만드는 `new`를 **smart constructor**라고 부릅니다.",
      ),
      mcq(
        "opaque-outside",
        "다른 모듈에서 `bank.Amount(-999)`라고 직접 생성자를 호출하면 어떻게 될까요? (`Amount`는 위처럼 `opaque`)",
        [
          "`-999`센트짜리 `Amount`가 만들어진다",
          "런타임에 에러가 던져진다",
          "컴파일 에러 — `opaque` 타입의 생성자는 모듈 밖에서 쓸 수 없다",
          "`new`가 자동으로 호출되어 `Error`가 반환된다",
        ],
        2,
        "맞아요! `opaque`의 핵심입니다. 생성자가 모듈에 봉인돼 음수 `Amount`는 *표현조차 불가능*합니다 — 런타임 검증이 아니라 컴파일 타임 봉인이에요.",
        [
          #(0, "그게 가능하면 `opaque`가 아니죠. 생성자는 모듈 밖으로 공개되지 않습니다."),
          #(1, "런타임까지 가지도 않아요 — 애초에 컴파일이 거부됩니다."),
          #(3, "`new`가 자동 호출되는 마법은 없어요. 그냥 컴파일 에러로 막힙니다."),
        ],
      ),
      Prose(
        "smart-ctor",
        "그럼 바깥에서는 어떻게 `Amount`를 만들까요? 모듈이 공개한 `new`를 통해서만 만듭니다. `new`는 검증에 성공하면 `Ok(amount)`, 실패하면 `Error(...)`를 돌려주죠.\n\n검증을 통과하지 못한 입력은 절대 `Amount`가 되지 못합니다.",
      ),
      predict(
        "new-negative",
        "이 호출의 결과는?",
        "new(-5)\n// pub fn new(cents) {\n//   case cents >= 0 {\n//     True -> Ok(Amount(cents))\n//     False -> Error(\"amount must not be negative\")\n//   }\n// }",
        [
          "`Ok(Amount(-5))`",
          "`Error(\"amount must not be negative\")`",
          "`-5`",
          "컴파일 에러",
        ],
        1,
        "정확해요! `-5 >= 0`은 거짓이라 `False` 가지를 타고 `Error(...)`가 나옵니다.",
        [
          #(0, "음수는 검증을 통과 못 해요 — `Ok`가 아니라 `Error`입니다."),
          #(2, "`new`는 날값이 아니라 `Result`를 돌려줘요."),
          #(3, "문법은 멀쩡합니다 — 컴파일은 되고, 값으로 `Error`가 나옵니다."),
        ],
      ),
      predict(
        "new-then-cents",
        "이 코드가 끝났을 때 `total`의 값은?",
        "let total = case new(150) {\n  Ok(a) -> cents(a)\n  Error(_) -> -1\n}\n// new는 검증 통과 시 Ok(Amount(150))",
        ["`150`", "`-1`", "`Ok(150)`", "`Amount(150)`"],
        0,
        "맞아요! `150 >= 0`이라 `Ok(a)` 가지를 타고, 접근자 `cents`가 안에 든 150을 꺼냅니다.",
        [
          #(1, "`-1`은 `Error` 가지의 값이에요. 150은 검증을 통과합니다."),
          #(2, "`cents`는 `Result`가 아니라 `Int`를 돌려줘요 — 그냥 150."),
          #(3, "`Amount`는 `opaque`라 그 내부가 그대로 노출되지 않아요. `cents`로 꺼낸 `Int` 150이 들어갑니다."),
        ],
      ),
      mcq(
        "opaque-vs-type",
        "`pub type`과 `pub opaque type`의 차이로 옳은 것은?",
        [
          "`opaque`는 타입을 아예 비공개로 만들어 다른 모듈에서 타입 이름조차 쓸 수 없다",
          "`opaque`는 타입 이름은 공개하되 생성자/필드 접근은 모듈 안으로 가둔다",
          "`opaque`는 런타임 성능을 위한 최적화일 뿐 의미 차이는 없다",
          "`opaque`는 필드를 자동으로 검증해 준다",
        ],
        1,
        "맞아요! 타입 이름은 공개되어 함수 시그니처에 쓸 수 있지만, 만들고 뜯어보는 일은 모듈만 할 수 있습니다.",
        [
          #(0, "타입 이름은 여전히 공개돼요 — `bank.Amount`를 시그니처에 쓸 수 있습니다. 가려지는 건 생성자/필드예요."),
          #(2, "성능 얘기가 아니라 **캡슐화**가 핵심입니다."),
          #(3, "검증은 `opaque`가 아니라 당신이 짠 smart constructor(`new`)가 합니다."),
        ],
      ),
    ],
  )
}

fn lesson_invariant_boundary() -> Lesson {
  Lesson(
    id: "l37-invariant-boundary",
    unit_id: "u12-opaque-types",
    title: "불변식은 모듈 경계에서 지킨다",
    emits_tags: [Concept("opaque-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "**불변식(invariant)**이란 \"이 타입의 값이라면 *항상* 참인 성질\"입니다. 예: \"`Amount`의 센트는 절대 음수가 아니다.\"\n\n`opaque` + smart constructor를 쓰면 이 불변식을 **단 한 곳 — 모듈 경계 — 에서만** 지키면 됩니다. 값을 만드는 통로가 모듈 안의 함수뿐이니까요. 한 번 `Amount`가 되었다면, 그 안의 센트가 음수일 리 없다고 *나머지 코드 전부가 믿어도* 됩니다.",
      ),
      predict(
        "subtract-ok",
        "이 코드의 결과는? (`subtract`는 모듈 안에서 `new(cents(a) - cents(b))`를 호출)",
        "let out = case new(100), new(30) {\n  Ok(a), Ok(b) ->\n    case subtract(a, b) {\n      Ok(r) -> cents(r)\n      Error(_) -> -1\n    }\n  _, _ -> -1\n}",
        ["`70`", "`130`", "`-1`", "`Ok(70)`"],
        0,
        "맞아요! 100 - 30 = 70이고 70 >= 0이라 `new`가 `Ok`를 돌려줍니다. `cents`로 꺼내면 70.",
        [
          #(1, "차감입니다 — 더하기(130)가 아니라 100 - 30 = 70이에요."),
          #(2, "`-1`은 `Error` 가지의 값이에요. 70은 음수가 아니라 검증을 통과합니다."),
          #(3, "`cents`로 한 번 꺼냈으니 `Result`가 아니라 `Int` 70이 들어갑니다."),
        ],
      ),
      predict(
        "subtract-underflow",
        "이번엔? (같은 `subtract`)",
        "case new(30), new(100) {\n  Ok(a), Ok(b) -> subtract(a, b)\n  _, _ -> Error(\"setup\")\n}",
        [
          "`Ok(Amount(-70))`",
          "`Error(\"amount must not be negative\")`",
          "`-70`",
          "`Error(\"setup\")`",
        ],
        1,
        "정확해요! 30 - 100 = -70이고, `subtract`가 `new(-70)`을 호출하니 불변식 검증이 막아 `Error`가 됩니다.",
        [
          #(0, "음수 `Amount`는 만들어질 수 없어요 — 그게 불변식의 요점입니다."),
          #(2, "`subtract`는 날값이 아니라 `Result`를 돌려줘요."),
          #(3, "`new(30)`/`new(100)` 둘 다 성공하니 `\"setup\"` 가지엔 가지 않아요. 검증은 `new(-70)`에서 걸립니다."),
        ],
      ),
      Prose(
        "where",
        "여기서 핵심은 \"음수 검사를 호출하는 쪽 모든 곳에 흩뿌리지 않는다\"는 점입니다. 불변식은 모듈 안 `new`/`subtract`에서 한 번 지켜지고, 바깥 코드는 `Amount`를 받으면 \"이미 올바른 값\"이라 믿고 씁니다.\n\n다른 도메인도 똑같습니다. `Email`이라면 \"`@`를 포함한다\"가 불변식이죠.",
      ),
      predict(
        "email-invalid",
        "`Email`의 smart constructor가 `string.contains(raw, \"@\")`로 검증할 때, `new(\"ab\")`의 결과는?",
        "pub fn new(raw: String) -> Result(Email, String) {\n  case string.contains(raw, \"@\") {\n    True -> Ok(Email(raw))\n    False -> Error(\"invalid email\")\n  }\n}\n\nnew(\"ab\")",
        [
          "`Ok(Email(\"ab\"))`",
          "`Error(\"invalid email\")`",
          "`\"ab\"`",
          "`True`",
        ],
        1,
        "맞아요! `\"ab\"`에는 `@`가 없어 `string.contains`가 `False` — `Error` 가지를 탑니다.",
        [
          #(0, "`@`가 없으면 `Ok`가 되지 않아요 — 불변식이 막습니다."),
          #(2, "`new`는 날 문자열이 아니라 `Result`를 돌려줘요."),
          #(3, "`string.contains`는 `case`의 검사값일 뿐, `new`의 결과는 `Result`입니다."),
        ],
      ),
      mcq(
        "boundary-benefit",
        "불변식을 \"모듈 경계에서만\" 지키는 설계의 가장 큰 이점은?",
        [
          "검증 코드를 값을 쓰는 모든 호출부에 복붙해야 한다",
          "한 번 만들어진 값은 어디서든 올바르다고 믿을 수 있어 방어 코드가 사라진다",
          "런타임 검증이 더 자주 일어나 안전해진다",
          "타입을 `opaque`로 만들면 검증이 자동 생성된다",
        ],
        1,
        "맞아요! 만드는 통로가 봉인돼 있으니, 받은 `Amount`는 이미 올바릅니다. 곳곳의 `if cents < 0` 방어 코드가 필요 없어져요.",
        [
          #(0, "그건 정반대예요 — 경계에서 한 번만 지키면 복붙이 사라집니다."),
          #(2, "검증은 만들 때 한 번이면 충분합니다. 자주 하는 게 목적이 아니에요."),
          #(3, "`opaque`는 통로를 봉인할 뿐, 검증 로직은 당신이 `new`에 직접 씁니다."),
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
        "한 발 더 나아가는 원칙: **\"불가능한 상태를 표현조차 불가능하게(make invalid states unrepresentable)\"**.\n\n검증으로 잘못된 값을 *막는* 것도 좋지만, 더 나은 건 타입 자체를 \"잘못된 조합이 애초에 만들어질 수 없게\" 짜는 것입니다.\n\n흔한 안티패턴: `User(is_member: Bool, name: String, points: Int)` — 손님인데 `name`이 채워지거나, 회원인데 `points`가 비는 모순된 조합이 가능합니다. 대신 합 타입(sum type)으로 쪼개면 각 상태가 *자기에게 필요한 데이터만* 동반합니다.",
      ),
      predict(
        "member-greeting",
        "다음 타입과 함수에서 `greeting(Member(\"수민\", 50))`의 값은?",
        "pub type User {\n  Guest\n  Member(name: String, points: Int)\n}\n\nfn greeting(u: User) -> String {\n  case u {\n    Guest -> \"환영합니다, 손님\"\n    Member(name, points) -> name <> \": \" <> int.to_string(points) <> \"p\"\n  }\n}",
        [
          "`\"환영합니다, 손님\"`",
          "`\"수민: 50p\"`",
          "`\"수민\"`",
          "`\"Member\"`",
        ],
        1,
        "맞아요! `Member` 가지가 맞아 `name`과 `points`를 꺼내 `\"수민: 50p\"`를 만듭니다.",
        [
          #(0, "그건 `Guest` 가지의 결과예요. 입력은 `Member`입니다."),
          #(2, "`points`도 함께 문자열에 붙어요 — 이름만 나오지 않습니다."),
          #(3, "case는 생성자 이름이 아니라 가지의 *결과 식*을 돌려줘요."),
        ],
      ),
      Prose(
        "data-per-state",
        "핵심은 `Guest`에는 `name`/`points` 필드가 *아예 없다*는 점입니다. \"손님인데 포인트가 있는\" 상태는 만들 방법이 없죠. 각 상태가 자기 데이터만 가지니, 모순된 조합이 타입 수준에서 사라집니다.\n\n또 하나의 이득: `case`로 다룰 때 컴파일러가 \"모든 상태를 처리했는지\"(exhaustiveness)를 검사해 줍니다.",
      ),
      predict(
        "connection-state",
        "`describe(Connected(\"abc\"))`의 값은?",
        "pub type Connection {\n  Disconnected\n  Connected(session: String)\n}\n\nfn describe(c: Connection) -> String {\n  case c {\n    Disconnected -> \"offline\"\n    Connected(session) -> \"online:\" <> session\n  }\n}",
        [
          "`\"offline\"`",
          "`\"online:abc\"`",
          "`\"online:\"`",
          "`\"abc\"`",
        ],
        1,
        "정확해요! `Connected` 가지가 `session`(\"abc\")을 꺼내 `\"online:\" <> \"abc\"`를 만듭니다.",
        [
          #(0, "그건 `Disconnected` 가지예요. 입력은 `Connected`입니다."),
          #(2, "`session`이 비어 있지 않아요 — \"abc\"가 뒤에 붙습니다."),
          #(3, "case는 가지의 결과 식 전체를 돌려줘요 — 접두사 \"online:\"까지 포함됩니다."),
        ],
      ),
      mcq(
        "design-choice",
        "\"연결됨일 때만 세션 ID가 있고, 끊김일 때는 없다\"를 가장 잘 표현하는 설계는?",
        [
          "`Connection(connected: Bool, session: String)` — 끊김일 땐 빈 문자열로",
          "`Connection(connected: Bool, session: Result(String, Nil))`",
          "`Disconnected` / `Connected(session: String)` 두 변형의 합 타입",
          "`session: String`만 두고 끊김은 `\"NONE\"` 같은 약속된 값으로",
        ],
        2,
        "맞아요! 합 타입으로 쪼개면 \"끊겼는데 세션이 있는\" 모순이 표현 불가능해집니다 — 정확히 make-invalid-states-unrepresentable.",
        [
          #(0, "빈 문자열도 엄연한 값이라 \"끊겼는데 세션이 있는\" 상태가 여전히 표현 가능해요."),
          #(1, "조금 낫지만 `connected:False`인데 `session:Ok(..)`인 모순 조합이 아직 가능합니다."),
          #(3, "약속된 마법값(`\"NONE\"`)은 깨지기 쉽고, 타입이 막아 주지 못해요."),
        ],
      ),
      mcq(
        "exhaustiveness-benefit",
        "잘못된 상태를 타입으로 제거했을 때, `case`에서 추가로 얻는 안전망은?",
        [
          "런타임이 더 빨라진다",
          "컴파일러가 모든 변형을 처리했는지(exhaustiveness) 검사해 누락을 막는다",
          "필드 값이 자동으로 검증된다",
          "패턴 매칭을 생략할 수 있게 된다",
        ],
        1,
        "맞아요! 변형이 명시돼 있으니 컴파일러가 빠뜨린 가지를 잡아 줍니다 — 새 상태를 추가하면 그걸 처리 안 한 case가 전부 컴파일 에러로 드러나죠.",
        [
          #(0, "exhaustiveness는 속도가 아니라 *누락 방지*에 관한 이야기입니다."),
          #(2, "값 검증은 별개예요 — 그건 smart constructor의 몫입니다."),
          #(3, "오히려 모든 변형을 다뤄야 합니다 — 생략이 아니라 빠짐없음이 핵심이에요."),
        ],
      ),
    ],
  )
}

fn lesson_phantom_types() -> Lesson {
  Lesson(
    id: "l39-phantom-types",
    unit_id: "u12-opaque-types",
    title: "phantom types 맛보기",
    emits_tags: [Concept("phantom-types")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "마지막은 **고급 맛보기**입니다(부담 없이 구경만 하세요). \n\n타입 파라미터가 *값에는 전혀 등장하지 않고* 타입 단계에서 **구분자**로만 쓰일 수 있습니다. 이를 **phantom type**(유령 타입)이라 합니다.\n\n```\npub type Meters\n\npub type Feet\n\npub type Length(unit) {\n  Length(amount: Float)\n}\n\npub fn add_lengths(a: Length(unit), b: Length(unit)) -> Length(unit) {\n  Length(a.amount +. b.amount)\n}\n```\n\n`unit` 파라미터는 `Length`의 필드 어디에도 안 쓰입니다 — 오로지 \"이건 미터, 저건 피트\"를 *타입으로* 구분하기 위한 표식이에요.",
      ),
      predict(
        "add-meters",
        "같은 단위끼리 더할 때, 이 코드의 출력은?",
        "let a: Length(Meters) = Length(3.0)\nlet b: Length(Meters) = Length(2.0)\nlet total = add_lengths(a, b)\nio.println(float.to_string(total.amount))",
        ["`5.0`", "`6.0`", "`5`", "`Length(5.0)`"],
        0,
        "맞아요! 둘 다 `Meters`라 타입이 맞고, `3.0 +. 2.0 = 5.0`이 출력됩니다.",
        [
          #(1, "더하기예요 — 곱(3.0 *. 2.0 = 6.0)이 아니라 3.0 +. 2.0 = 5.0입니다."),
          #(2, "`Float`라 `5`가 아니라 `5.0`으로 출력됩니다."),
          #(3, "`total.amount`로 안의 `Float`만 꺼내 출력해요 — 레코드 전체가 아니라 5.0."),
        ],
      ),
      Prose(
        "type-guard",
        "그럼 `unit`이 왜 유용할까요? `add_lengths`의 시그니처는 `a`와 `b`가 **같은 `unit`**이어야 한다고 못 박습니다. 그래서 미터와 피트를 섞으면 컴파일러가 막아 줍니다 — 단위 혼동을 *컴파일 에러*로 잡는 거죠. 값에는 전혀 비용이 없고요(런타임엔 `unit`이 사라집니다).",
      ),
      mcq(
        "mix-units",
        "`Length(Meters)` 하나와 `Length(Feet)` 하나를 `add_lengths`에 넘기면?",
        [
          "둘을 더한 `Length`가 나온다",
          "런타임에 단위 변환이 일어난다",
          "타입 불일치(type mismatch) 컴파일 에러 — `unit`이 서로 달라서",
          "첫 인자의 단위로 자동 통일된다",
        ],
        2,
        "맞아요! 시그니처가 `a`와 `b`의 `unit`을 같게 요구하므로, `Meters`와 `Feet`를 섞으면 컴파일 단계에서 거부됩니다.",
        [
          #(0, "서로 다른 `unit`이라 애초에 컴파일이 안 돼요 — 결과 `Length`도 안 생깁니다."),
          #(1, "phantom type엔 런타임 동작이 없어요. 변환 로직은 어디에도 없습니다."),
          #(3, "자동 통일 같은 마법은 없어요 — 그냥 컴파일 에러로 막습니다."),
        ],
      ),
      mcq(
        "phantom-runtime",
        "phantom type의 파라미터(`Meters`, `Feet`)에 대해 옳은 설명은?",
        [
          "런타임에 값으로 저장돼 메모리를 차지한다",
          "값에는 등장하지 않고 컴파일 타임 구분에만 쓰여 런타임 비용이 없다",
          "반드시 어떤 필드의 타입으로 사용되어야 한다",
          "`opaque` 타입에서만 쓸 수 있다",
        ],
        1,
        "정확해요! 그래서 \"유령(phantom)\"입니다 — 타입 검사에만 존재하고 런타임엔 흔적이 없죠.",
        [
          #(0, "값에 안 들어가니 런타임 비용이 없습니다 — 그게 유령인 이유예요."),
          #(2, "오히려 필드에 *안 쓰여서* phantom입니다 — 필드에 쓰이면 평범한 제네릭이죠."),
          #(3, "`opaque`와 독립적인 기법입니다 — 어떤 타입에서도 phantom 파라미터를 둘 수 있어요."),
        ],
      ),
    ],
  )
}

fn unit_intentional_crash() -> Unit {
  let meta =
    UnitMeta(
      id: "u13-intentional-crash",
      title: "의도적 크래시",
      order: 13,
      level: 4,
      concepts: [Concept("let-assertions"), Tricky("crash-vs-result")],
      prerequisites: ["u09-option-result"],
      lesson_ids: [
        "l13a-todo-panic", "l13b-let-assert", "l13c-assert-test",
      ],
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
    title: "todo와 panic — 아직 vs 절대",
    emits_tags: [Concept("let-assertions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "지금까지는 실패를 **데이터**로 다뤘습니다 — `Option`, `Result`. 하지만 가끔은 \"여기 도달하면 안 된다\"가 정답일 때가 있어요. 그때 쓰는 도구가 `todo`와 `panic`입니다.\n\n`todo`는 \"아직 안 만들었음\"의 표시입니다. 컴파일은 통과시키되, **실행해서 그 자리에 닿으면** 크래시합니다. `panic`은 \"여기는 절대 닿으면 안 되는 곳\"이라는 단언이에요.",
      ),
      Prose(
        "todo-fills",
        "`todo`의 장점은 **타입은 맞춰주면서 구현은 미룬다**는 점입니다. 함수 골격을 먼저 짜고 본문을 `todo`로 채워도 전체 프로그램은 컴파일됩니다. 나중에 그 자리를 진짜 코드로 바꾸면 되죠.\n\n아래 `area`는 `todo`로 시작했다가 이제 본문을 채운 모습입니다. 실제로 호출해 봅시다.",
      ),
      predict(
        "area-filled",
        "본문을 채운 `area`를 호출했습니다. `area(4, 5)`의 값은?",
        "pub fn area(w: Int, h: Int) -> Int {\n  w * h\n}\n\npub fn main() {\n  io.println(int.to_string(area(4, 5)))\n}",
        ["`9`", "`20`", "`45`", "런타임 크래시(todo)"],
        1,
        "맞아요! `todo`는 사라졌고 본문이 `w * h`이니 4 * 5 = 20을 출력합니다.",
        [
          #(0, "`+`가 아니라 `*`입니다 — 4 + 5가 아니라 4 * 5예요."),
          #(2, "`4`와 `5`를 이어 붙인 게 아니라 곱한 값입니다. 20이에요."),
          #(3, "`todo`는 이미 진짜 코드로 교체됐습니다. 그 자리에 닿을 일이 없어요."),
        ],
      ),
      Prose(
        "panic-here",
        "`panic`은 다릅니다 — \"미완성\"이 아니라 **\"불가능\"** 을 뜻해요. `case`의 모든 의미 있는 가지를 처리한 뒤, 논리상 절대 오지 않을 가지에 `panic as \"...\"`을 두면, 만에 하나 닿았을 때 그 메시지와 함께 즉시 멈춥니다.\n\n핵심은 **닿지 않으면 아무 일도 없다**는 것. 정상 경로를 타면 평범하게 값을 돌려줍니다.",
      ),
      predict(
        "panic-not-reached",
        "`b`가 0이 아니면 `panic` 가지는 닿지 않습니다. `safe_div(20, 4)`의 값은?",
        "pub fn safe_div(a: Int, b: Int) -> Int {\n  case b {\n    0 -> panic as \"0으로 나눌 수 없습니다\"\n    _ -> a / b\n  }\n}\n\npub fn main() {\n  io.println(int.to_string(safe_div(20, 4)))\n}",
        ["`5`", "`0`", "런타임 크래시(panic)", "`24`"],
        0,
        "정확해요! 4는 0이 아니므로 `_` 가지를 타고 20 / 4 = 5. `panic`은 닿지 않았습니다.",
        [
          #(1, "`b`가 0일 때만 멈춥니다. 여기선 4이므로 정상적으로 나눗셈을 해요."),
          #(2, "정상 경로(`b`가 0이 아님)를 탔으니 크래시하지 않습니다. 5를 돌려줘요."),
          #(3, "`/`는 나눗셈입니다 — 20 + 4가 아니라 20 / 4 = 5예요."),
        ],
      ),
      mcq(
        "todo-vs-panic",
        "`todo`와 `panic`의 차이로 가장 정확한 설명은?",
        [
          "둘 다 컴파일 에러를 낸다",
          "`todo`는 \"아직 구현 안 함\", `panic`은 \"여기 절대 닿으면 안 됨\"을 뜻한다",
          "`todo`는 크래시하지 않고, `panic`만 크래시한다",
          "`panic`은 메시지를 붙일 수 없다",
        ],
        1,
        "맞아요! `todo`=미완성 표시, `panic`=불가능 단언. 의도가 다릅니다.",
        [
          #(0, "둘 다 컴파일은 통과합니다 — 실행해서 그 자리에 닿을 때 크래시해요."),
          #(2, "`todo`도 실행 중 그 자리에 닿으면 크래시합니다. 차이는 의도예요."),
          #(3, "둘 다 `as \"메시지\"`로 설명을 붙일 수 있습니다."),
        ],
      ),
    ],
  )
}

fn lesson_let_assert() -> Lesson {
  Lesson(
    id: "l13b-let-assert",
    unit_id: "u13-intentional-crash",
    title: "let assert — \"이건 반드시 맞는다\"",
    emits_tags: [Concept("let-assertions")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`let`은 패턴이 **반드시 전체를 덮어야** 합니다. 그래서 `let [first, ..] = xs`는 컴파일 에러예요 — 빈 리스트일 가능성을 처리하지 않았으니까요.\n\n`let assert`는 그 규칙을 깨고 **부분 패턴**을 허용합니다. 대신 약속을 합니다: \"이 시점에 이 모양이 아니면 그건 내 코드의 버그다.\" 모양이 맞으면 값을 꺼내고, 틀리면 **즉시 크래시**합니다.",
      ),
      predict(
        "let-assert-head",
        "리스트가 비어있지 않으니 패턴이 맞습니다. `first_or_crash([10, 20, 30])`의 값은?",
        "pub fn first_or_crash(xs: List(Int)) -> Int {\n  let assert [first, ..] = xs\n  first\n}\n\npub fn main() {\n  io.println(int.to_string(first_or_crash([10, 20, 30])))\n}",
        ["`10`", "`30`", "`[10, 20, 30]`", "런타임 크래시"],
        0,
        "맞아요! `[first, ..]`에서 `first`는 머리(첫 원소)인 10에 묶입니다.",
        [
          #(1, "`first`는 마지막이 아니라 **첫** 원소입니다 — 10이에요."),
          #(2, "`first`는 리스트 전체가 아니라 첫 원소 하나입니다."),
          #(3, "리스트가 비어있지 않으므로 패턴이 맞습니다 — 크래시하지 않아요."),
        ],
      ),
      predict(
        "let-assert-ok",
        "`let assert Ok(n)`은 `Ok`라고 단언합니다. `double_ok(Ok(21))`의 값은?",
        "pub fn double_ok(r: Result(Int, String)) -> Int {\n  let assert Ok(n) = r\n  n * 2\n}\n\npub fn main() {\n  io.println(int.to_string(double_ok(Ok(21))))\n}",
        ["`21`", "`42`", "`Ok(42)`", "런타임 크래시"],
        1,
        "정확해요! `Ok(21)`에서 `n`은 21로 풀리고, 21 * 2 = 42를 돌려줍니다.",
        [
          #(0, "`n`을 꺼낸 뒤 `n * 2`를 합니다 — 21이 아니라 42예요."),
          #(2, "`let assert Ok(n)`은 껍데기를 벗겨 `n`만 꺼냅니다. 결과는 `Int`인 42예요."),
          #(3, "값이 `Ok`이므로 단언이 맞습니다 — 크래시하지 않아요."),
        ],
      ),
      Prose(
        "fails-crash",
        "그렇다면 모양이 틀리면? `first_or_crash([])`처럼 빈 리스트가 들어오면 `[first, ..]`와 맞지 않아 **즉시 크래시**합니다. 플랫폼은 캡처된 예외 메시지(\"Pattern match failed...\")를 그대로 보여줘요.\n\n이게 바로 `let assert`의 거래입니다: 편하게 값을 꺼내는 대가로, 약속이 깨지면 프로그램을 멈춥니다.",
      ),
      mcq(
        "empty-list-crash",
        "`first_or_crash([])`를 실행하면 어떻게 될까요?",
        [
          "`0`을 돌려준다",
          "`Error(Nil)`을 돌려준다",
          "패턴 불일치로 런타임 크래시한다",
          "컴파일 에러가 난다",
        ],
        2,
        "맞아요! 빈 리스트는 `[first, ..]`와 맞지 않아, 단언이 깨지며 즉시 크래시합니다.",
        [
          #(0, "`let assert`는 기본값을 만들지 않습니다 — 맞으면 꺼내고, 틀리면 멈춰요."),
          #(1, "`let assert`는 `Result`를 돌려주지 않습니다. 실패는 데이터가 아니라 크래시예요."),
          #(3, "컴파일은 통과합니다 — 실패는 실행 시점(런타임)에 일어나요."),
        ],
      ),
      mcq(
        "when-justified",
        "다음 중 `let assert`가 **정당한** 상황은? (외부 입력의 실패는 데이터, 내 불변식 위반은 버그)",
        [
          "사용자가 입력한 문자열을 숫자로 파싱하기",
          "방금 내 코드에서 만든 3원소 리스트의 머리를 꺼내기",
          "설정 파일을 읽어 들이기",
          "네트워크 응답을 해석하기",
        ],
        1,
        "맞아요! 방금 내가 만든 3원소 리스트는 절대 비어있지 않습니다 — 비어있다면 그건 데이터가 아니라 내 코드의 버그예요.",
        [
          #(0, "사용자 입력은 언제든 틀릴 수 있는 **데이터**입니다 — `Result`로 다뤄야 해요."),
          #(2, "설정 파일은 없거나 망가질 수 있는 외부 값입니다 — 다룰 수 있는 실패예요."),
          #(3, "네트워크 응답은 외부에서 온 값이라 실패가 정상 범주입니다 — `Result`로 처리하세요."),
        ],
      ),
    ],
  )
}

fn lesson_assert_test() -> Lesson {
  Lesson(
    id: "l13c-assert-test",
    unit_id: "u13-intentional-crash",
    title: "assert와 테스트 — 크래시가 옳은 순간",
    emits_tags: [Concept("let-assertions"), Tricky("crash-vs-result")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "`assert`(v1.11+)는 **Bool 표현식**을 단언합니다. 참이면 조용히 지나가고, 거짓이면 *양변의 값까지 담긴* 풍부한 메시지와 함께 크래시해요.\n\n사실 한 가지 비밀을 알려드릴게요: 여러분이 이 플랫폼에서 푸는 모든 `write` 문제의 숨김 채점기가 정확히 이 `assert`로 만들어져 있습니다.",
      ),
      predict(
        "assert-passes",
        "두 `assert`가 모두 참이라 통과합니다. 마지막 줄까지 실행되면 무엇이 출력될까요?",
        "pub fn total(xs: List(Int)) -> Int {\n  list.fold(xs, 0, fn(acc, x) { acc + x })\n}\n\npub fn main() {\n  assert total([1, 2, 3]) == 6\n  assert total([]) == 0\n  io.println(int.to_string(total([1, 2, 3])))\n}",
        ["`6`", "`0`", "아무것도 출력 안 됨(크래시)", "`True`"],
        0,
        "맞아요! 두 단언이 모두 참이라 막힘없이 지나가고, 마지막 줄이 `total([1, 2, 3])`=6을 출력합니다.",
        [
          #(1, "마지막 줄은 `total([])`이 아니라 `total([1, 2, 3])`을 출력합니다 — 6이에요."),
          #(2, "두 단언이 모두 참이므로 크래시하지 않습니다 — 끝까지 실행돼요."),
          #(3, "출력하는 건 비교 결과가 아니라 `total(...)`의 값입니다 — 6이에요."),
        ],
      ),
      Prose(
        "assert-fails",
        "만약 `assert total([]) == 0`에서 `total([])`이 0이 아니었다면? `assert`는 **거짓**임을 발견하고, \"좌변은 이 값, 우변은 저 값\"이라는 메시지와 함께 크래시합니다. 그래서 테스트로 쓰기에 완벽해요 — 무엇이 틀렸는지 바로 보여주니까요.",
      ),
      mcq(
        "assert-on-false",
        "`assert`의 표현식이 **거짓**으로 평가되면 어떻게 될까요?",
        [
          "`False`를 돌려준다",
          "양변의 값이 담긴 메시지와 함께 크래시한다",
          "다음 줄로 그냥 넘어간다",
          "컴파일 에러가 난다",
        ],
        1,
        "맞아요! 거짓이면 좌변/우변 값이 담긴 풍부한 메시지로 즉시 크래시합니다.",
        [
          #(0, "`assert`는 값을 돌려주는 게 아니라, 거짓일 때 크래시하는 도구예요."),
          #(2, "참일 때만 넘어갑니다 — 거짓이면 멈춰요."),
          #(3, "컴파일은 통과합니다 — 거짓 판정은 실행 중에 일어나요."),
        ],
      ),
      mcq(
        "tool-choice",
        "함수가 받은 값이 \"실패할 수 있는 외부 입력\"일 때, 올바른 도구는?",
        [
          "`let assert`로 강제로 꺼낸다",
          "`panic`으로 막는다",
          "`Result`로 실패를 데이터로 다룬다",
          "`todo`로 남겨 둔다",
        ],
        2,
        "맞아요! 외부에서 온 값의 실패는 정상 범주의 **데이터**입니다 — `Result`로 다뤄야 해요. 이 구분이 이 유닛의 전부입니다.",
        [
          #(0, "다룰 수 있는 실패에 `let assert`를 쓰면, 정상적인 실패에도 프로그램이 죽습니다."),
          #(1, "`panic`은 \"불가능한 일\"에 씁니다 — 외부 입력의 실패는 충분히 가능한 일이에요."),
          #(3, "`todo`는 미완성 표시일 뿐, 실패를 처리하는 도구가 아닙니다."),
        ],
      ),
    ],
  )
}

fn unit_gleam_omits() -> Unit {
  let meta =
    UnitMeta(
      id: "u14-gleam-omits",
      title: "Gleam에 없는 것들 — 사고 전환 II",
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
    title: "타입 클래스가 없는 이유",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Haskell에서 왔다면 가장 먼저 허전한 것이 **타입 클래스**입니다. `Ord`, `Eq`, `Show` 같은 \"이 타입은 비교할 수 있다\"는 약속이 Gleam엔 없어요.\n\n공식 FAQ는 그 이유를 셋으로 듭니다 — **혼란스러운 에러 메시지**, **느려지는 컴파일 시간**, 그리고 디스패치에 따르는 **런타임 비용**. Gleam은 이 셋을 피하려고 타입 클래스를 아예 넣지 않았습니다.",
      ),
      Prose(
        "instead",
        "그 대신 Gleam이 주는 것은 단순합니다: **필요한 동작을 함수로 명시해서 넘긴다**.\n\n예를 들어 정렬에는 \"숨은 `Ord` 인스턴스\"가 없습니다. `list.sort`는 비교 함수를 **인자로 직접** 받아요:\n\n```gleam\nlist.sort([3, 1, 2], by: int.compare)\n```\n\n무엇으로 비교할지가 코드에 그대로 드러나죠 — 마법도, 암묵적 디스패치도 없습니다.",
      ),
      predict(
        "sort-explicit",
        "비교 함수를 직접 넘기는 이 정렬의 결과는?",
        "list.sort([3, 1, 2], by: int.compare)",
        ["`[1, 2, 3]`", "`[3, 2, 1]`", "`[3, 1, 2]`", "컴파일 에러"],
        0,
        "맞아요! `int.compare`를 오름차순 비교자로 넘겼으니 [1, 2, 3]입니다. 숨은 `Ord`가 아니라 명시한 함수가 순서를 정해요.",
        [
          #(1, "`int.compare`는 오름차순입니다. 내림차순은 `fn(a, b) { int.compare(b, a) }` 같이 직접 뒤집어 넘겨야 해요."),
          #(2, "`sort`는 정렬된 새 리스트를 돌려줍니다 — 원본 순서가 그대로 나오지 않아요."),
          #(3, "`by:`로 비교 함수를 넘겼으니 정상 컴파일됩니다 — 타입 클래스가 없어도 정렬은 함수 전달로 됩니다."),
        ],
      ),
      Prose(
        "describe",
        "\"이 타입을 글로 표현하는 법\"(Haskell의 `Show`)도 마찬가지예요. 타입마다 알아서 호출되는 인스턴스 대신, **변환 함수를 직접 건네줍니다**. 아래 `describe_all`은 어떤 타입이든 `to_text` 함수만 받으면 동작하는, 타입 클래스의 명시적 대체물입니다.",
      ),
      predict(
        "describe-pass",
        "함수를 직접 넘겨 각 원소를 글로 바꾸는 코드입니다. 결과는?",
        "fn describe_all(xs, to_text) {\n  list.map(xs, to_text)\n}\nfn coin_text(heads) {\n  case heads { True -> \"앞\"  False -> \"뒤\" }\n}\n\ndescribe_all([True, False, True], coin_text)",
        [
          "`[\"앞\", \"뒤\", \"앞\"]`",
          "`[\"뒤\", \"앞\", \"뒤\"]`",
          "`[True, False, True]`",
          "컴파일 에러 (Show 인스턴스 없음)",
        ],
        0,
        "정확해요! `coin_text`를 명시적으로 넘겨 각 Bool을 글자로 바꿨습니다 — [\"앞\", \"뒤\", \"앞\"]. 이것이 타입 클래스 없이 동작을 주입하는 방식이에요.",
        [
          #(1, "`True`가 \"앞\", `False`가 \"뒤\"입니다 — 첫 원소 `True`는 \"앞\"으로 시작해요."),
          #(2, "`to_text`가 각 원소를 String으로 바꾸므로 결과는 Bool 리스트가 아니라 문자열 리스트예요."),
          #(3, "Gleam엔 `Show` 자체가 없지만, 변환 함수를 **인자로** 넘겼으니 전혀 문제없이 컴파일됩니다."),
        ],
      ),
      mcq(
        "why-no-typeclass",
        "공식 FAQ가 드는, Gleam에 타입 클래스가 없는 이유로 거리가 먼 것은?",
        [
          "혼란스러운 컴파일 에러 메시지를 피하려고",
          "컴파일 시간을 짧게 유지하려고",
          "디스패치의 런타임 비용을 피하려고",
          "타입 추론을 아예 포기했기 때문에",
        ],
        3,
        "맞아요! Gleam은 타입 추론을 잘 합니다 — 타입 클래스를 뺀 이유는 에러 메시지·컴파일 시간·런타임 비용 세 가지예요.",
        [
          #(0, "이건 실제 이유 중 하나예요. 타입 클래스는 종종 난해한 에러를 낳습니다."),
          #(1, "이것도 실제 이유입니다 — 인스턴스 해석은 컴파일을 느리게 만들 수 있어요."),
          #(2, "이것도 맞는 이유예요 — 동적 디스패치엔 런타임 비용이 따릅니다."),
        ],
      ),
    ],
  )
}

fn lesson_no_currying() -> Lesson {
  Lesson(
    id: "l14-no-currying",
    unit_id: "u14-gleam-omits",
    title: "커링이 없는 이유와 캡처",
    emits_tags: [Concept("basics"), Tricky("capture-vs-currying")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Haskell이라면 `add 10`이 \"한 인자를 받는 함수\"가 됩니다 — 자동 **커링**이죠. Gleam엔 그게 없습니다.\n\nGleam에서 `add(10)`은 함수가 아니라 **인자 부족 컴파일 에러**예요. 두 자리짜리 함수를 한 자리만 채워 부른 셈이니까요.",
      ),
      predict(
        "map-missing-arg",
        "두 인자 함수 `add`를 한 자리만 채워 `list.map`에 넘기면?",
        "fn add(a, b) { a + b }\n\nlist.map([1, 2], add(10))",
        [
          "`[11, 12]`",
          "컴파일 에러 (인자 개수 불일치)",
          "`[10, 10]`",
          "`[1, 2]`",
        ],
        1,
        "맞아요! `add(10)`은 인자가 하나 모자란 호출이라 컴파일되지 않습니다. Gleam엔 자동 커링이 없어요.",
        [
          #(0, "Haskell이라면 맞습니다. Gleam은 자동 커링이 없으니 `add(10, _)`로 빈자리를 명시하세요."),
          #(2, "`add(10)`은 값을 만들지 못하고 컴파일 단계에서 막힙니다 — 실행 자체가 안 돼요."),
          #(3, "`add`가 적용되지 못한 게 아니라 호출이 컴파일 에러라, [1, 2]가 그대로 나오지도 않아요."),
        ],
      ),
      Prose(
        "capture",
        "부분 적용이 *정말* 하고 싶다면? **캡처**로 의도를 명시합니다.\n\n`add(10, _)`는 \"한 자리만 비워둔 호출\"로, `fn(b) { add(10, b) }`의 단축이에요. 빈칸 `_`는 정확히 한 개.\n\n핵심 설계 의도: 실수(인자 빠뜨림)와 의도(부분 적용)가 **문법으로 구분**됩니다. `add(10)`은 실수, `add(10, _)`는 의도.",
      ),
      predict(
        "capture-map",
        "캡처로 빈자리를 명시한 이 코드의 결과는?",
        "fn add(a, b) { a + b }\n\nlist.map([1, 2], add(10, _))",
        ["`[11, 12]`", "컴파일 에러", "`[10, 20]`", "`[1, 2]`"],
        0,
        "정확해요! `add(10, _)`는 `fn(b) { add(10, b) }`라, 각 원소에 10을 더해 [11, 12]가 됩니다.",
        [
          #(1, "이번엔 `_`로 빈자리를 채웠으니 정상입니다 — 인자 부족이 아니에요."),
          #(2, "10을 *더합니다*. 곱하는 게 아니라 1+10=11, 2+10=12예요."),
          #(3, "캡처가 각 원소에 적용되므로 원본 그대로 나오지 않아요 — [11, 12]입니다."),
        ],
      ),
      Prose(
        "hole-position",
        "빈칸의 **위치**가 어느 인자를 비울지 정합니다. 같은 함수라도 `_`를 어디 두느냐로 결과가 달라져요.",
      ),
      predict(
        "hole-position",
        "각 문자열 *뒤에* `!`를 붙이려 합니다. 이 캡처의 결과는?",
        "list.map([\"a\", \"b\"], string.append(_, \"!\"))",
        [
          "`[\"a!\", \"b!\"]`",
          "`[\"!a\", \"!b\"]`",
          "`[\"a\", \"b\"]`",
          "컴파일 에러",
        ],
        0,
        "맞아요! `append(_, \"!\")`는 첫 인자(원소)를 비워, 각 원소 *뒤에* \"!\"를 붙입니다 — [\"a!\", \"b!\"].",
        [
          #(1, "그건 `string.append(\"!\", _)`의 결과예요. 빈칸 위치가 어느 인자가 비는지를 정합니다."),
          #(2, "`append`가 \"!\"를 실제로 붙이므로 원본 그대로 나오지 않아요."),
          #(3, "`_` 한 개로 첫 인자를 비운 올바른 캡처라 정상 컴파일됩니다."),
        ],
      ),
      mcq(
        "capture-type",
        "`add`가 `fn(Int, Int) -> Int`일 때, 캡처 `add(10, _)`의 타입은?",
        ["`fn(Int) -> Int`", "`Int`", "`fn(Int, Int) -> Int`", "`fn() -> Int`"],
        0,
        "맞아요! 한 자리를 비웠으니 남은 인자 하나를 받는 함수, `fn(Int) -> Int`입니다.",
        [
          #(1, "캡처는 값이 아니라 *함수*를 만듭니다 — 아직 빈자리를 채워야 결과가 나와요."),
          #(2, "두 자리를 다 받는 건 `add` 자신이에요. 캡처는 한 자리를 이미 채웠으니 하나만 남습니다."),
          #(3, "빈칸이 하나 있으니 인자 하나를 받습니다 — `fn() -> Int`가 아니에요."),
        ],
      ),
    ],
  )
}

fn lesson_eager() -> Lesson {
  Lesson(
    id: "l14-eager",
    unit_id: "u14-gleam-omits",
    title: "게으름이 없다 — eager 평가",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "Haskell은 게으릅니다(lazy) — 값은 *필요할 때* 계산되죠. Gleam은 반대로 **eager**입니다: 함수에 넘긴 인자는 호출이 *시작되기 전에* 모두 계산됩니다.\n\n그래서 무한 시퀀스 같은 게으른 구조는 언어가 아니라 라이브러리(`gleam_yielder`, stdlib 아님)의 몫이에요.",
      ),
      Prose(
        "eager-arg",
        "이게 왜 중요할까요? \"조건이 거짓이면 비싼 계산을 건너뛰겠지\"라는 lazy식 기대가 Gleam에선 통하지 않기 때문입니다.\n\n`bool.guard(when:, return:, otherwise:)`를 봅시다. `when`이 `False`라 `return` 값이 *버려질* 상황이어도, `return:` 자리에 직접 쓴 식은 **호출 전에 이미 계산**됩니다.",
      ),
      predict(
        "eager-side-effect",
        "`when: False`라 `return` 값은 버려집니다. 그런데 `계산됨`이 출력될까요? (`expensive()`는 `계산됨`을 출력하고 값을 돌려줍니다)",
        "fn expensive() {\n  io.println(\"계산됨\")\n  \"결과\"\n}\n\nbool.guard(when: False, return: expensive(), otherwise: fn() { \"기본\" })",
        [
          "`계산됨`이 출력된다 (eager)",
          "아무것도 출력되지 않는다 (lazy)",
          "`기본`이 출력된다",
          "컴파일 에러",
        ],
        0,
        "맞아요! Gleam은 eager라, `return:` 자리의 `expensive()`가 호출 전에 이미 실행됩니다 — 값이 버려져도 부수효과(`계산됨` 출력)는 일어나요.",
        [
          #(1, "그건 lazy 언어의 동작입니다. Gleam은 인자를 호출 전에 모두 계산해요 — `계산됨`이 찍힙니다."),
          #(2, "`expensive()`는 `계산됨`을 출력하지 `기본`을 출력하지 않습니다. `\"기본\"`은 `otherwise` 쪽 값이에요."),
          #(3, "`bool.guard`에 올바른 인자를 넘겼으니 정상 컴파일됩니다 — 문제는 평가 시점이에요."),
        ],
      ),
      Prose(
        "thunk",
        "그럼 지연이 정말 필요할 땐? **익명 함수로 감싸 넘깁니다**(U7의 `fn() { ... }`). 함수 *값*은 만들어질 뿐 호출되기 전엔 실행되지 않으니까요 — 이게 게으름의 수동 대체재입니다.\n\n`bool.lazy_guard`는 양쪽을 `fn() -> a` 썽크(thunk)로 받아, 실제로 고른 쪽만 호출합니다.",
      ),
      predict(
        "thunk-defers",
        "이번엔 `expensive`를 `fn() { ... }`로 감싸 `lazy_guard`에 넘깁니다. `when: False`일 때 출력은?",
        "fn expensive() {\n  io.println(\"계산됨\")\n  \"결과\"\n}\n\nbool.lazy_guard(\n  when: False,\n  return: fn() { expensive() },\n  otherwise: fn() { \"기본\" },\n)",
        [
          "`기본` (expensive 썽크는 호출 안 됨)",
          "`계산됨` 그리고 `기본`",
          "`계산됨`",
          "아무것도 출력되지 않음",
        ],
        0,
        "정확해요! 썽크로 감쌌으니 `return` 쪽은 호출되지 않고, `when: False`라 `otherwise`가 골라져 `기본`만 나옵니다.",
        [
          #(1, "`return` 썽크는 호출조차 안 되므로 `계산됨`은 찍히지 않아요 — `기본`만 출력됩니다."),
          #(2, "`fn()`으로 감쌌으니 `expensive`는 실행되지 않습니다 — 이게 지연의 핵심이에요."),
          #(3, "`lazy_guard`는 고른 쪽 썽크를 호출하므로 `기본`이 반드시 출력됩니다."),
        ],
      ),
      mcq(
        "lazy-where",
        "Gleam에서 무한 시퀀스 같은 \"게으른 구조\"는 어디에 있나요?",
        [
          "언어에 내장돼 있다",
          "stdlib의 `gleam/lazy` 모듈",
          "별도 라이브러리 `gleam_yielder` (stdlib 아님)",
          "`Int`처럼 기본 타입이다",
        ],
        2,
        "맞아요! 게으른 시퀀스는 언어가 아니라 별도 라이브러리 `gleam_yielder`의 영역입니다 — 표준 라이브러리에도 들어있지 않아요.",
        [
          #(0, "Gleam 언어 자체는 eager뿐입니다 — 게으름은 내장돼 있지 않아요."),
          #(1, "`gleam/lazy` 같은 stdlib 모듈은 없습니다. 게으름은 외부 라이브러리예요."),
          #(3, "게으른 시퀀스는 기본 타입이 아니라 라이브러리가 제공하는 자료구조입니다."),
        ],
      ),
    ],
  )
}

fn lesson_no_exceptions() -> Lesson {
  Lesson(
    id: "l14-no-exceptions",
    unit_id: "u14-gleam-omits",
    title: "예외·뮤테이션·매크로 — 결핍의 일관성",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "마지막으로 한꺼번에 정리합니다. Gleam이 빼버린 나머지 셋 — **예외**, **뮤테이션**, **매크로** — 도 같은 철학에서 나옵니다: \"숨은 제어 흐름과 숨은 상태를 없애 코드를 읽는 그대로 믿게 한다.\"",
      ),
      Prose(
        "no-exceptions",
        "**예외가 없습니다.** 실패할 수 있는 연산은 던지는 대신 **Result로 돌려줍니다**. 0으로 나누기조차 크래시가 아니라 `Error`예요:\n\n```gleam\nint.divide(10, 0)  // Error(Nil)\nint.divide(10, 2)  // Ok(5)\n```\n\n실패가 타입에 드러나니, 호출부는 `case`나 `use`로 *반드시* 다뤄야 합니다 — 잊고 지나칠 수가 없죠.",
      ),
      predict(
        "div-zero-result",
        "0으로 나누면 예외가 던져질까요? 이 식의 값은?",
        "int.divide(10, 0)",
        ["`Error(Nil)`", "런타임 예외(크래시)", "`0`", "`Ok(0)`"],
        0,
        "맞아요! Gleam엔 예외가 없어 0으로 나누기도 `Error(Nil)`을 돌려줍니다 — 던지지 않아요.",
        [
          #(1, "예외 자체가 없습니다 — 실패는 던지는 게 아니라 `Error` 값으로 *반환*돼요."),
          #(2, "그냥 `0`이 아니라 `Result`로 감싼 `Error(Nil)`입니다 — 실패가 타입에 드러나요."),
          #(3, "0 나누기는 성공이 아니라 실패라 `Ok`가 아니라 `Error(Nil)`이에요."),
        ],
      ),
      Prose(
        "no-mutation",
        "**뮤테이션이 없습니다.** 값은 결코 제자리에서 바뀌지 않아요. 리스트에 원소를 \"추가\"해도 원본은 그대로고 *새* 리스트가 생깁니다 — 내부적으로는 **구조 공유(structural sharing)** 불변 데이터라 비싸지 않아요.",
      ),
      predict(
        "append-no-mutate",
        "`ys`를 만든 뒤 원본 `xs`를 출력하면?",
        "let xs = [1, 2, 3]\nlet ys = list.append(xs, [4])\nxs",
        ["`[1, 2, 3]`", "`[1, 2, 3, 4]`", "`[4, 1, 2, 3]`", "`[4]`"],
        0,
        "정확해요! `append`는 *새* 리스트(`ys`)를 만들 뿐, 원본 `xs`는 절대 바뀌지 않습니다 — 여전히 [1, 2, 3].",
        [
          #(1, "그건 새로 만들어진 `ys`예요. 원본 `xs`는 뮤테이션이 없어 그대로 [1, 2, 3]입니다."),
          #(2, "`append`는 뒤에 붙이고, 게다가 원본을 바꾸지도 않아요 — `xs`는 [1, 2, 3]."),
          #(3, "`xs`에서 사라지는 원소는 없습니다 — 불변이라 처음 모습 그대로예요."),
        ],
      ),
      Prose(
        "no-macros",
        "**매크로도 (아직) 없습니다.** FAQ는 매크로에 단호히 닫혀 있진 않지만 — **가독성과 컴파일 속도를 해치지 않을 때에만** 열려 있다고 말합니다. 코드가 \"보이는 그대로\"이길 바라는 같은 원칙이죠.\n\n결국 없는 것들의 목록 — 타입 클래스, 커링, 게으름, 예외, 뮤테이션, 매크로 — 은 제각각이 아니라 **하나의 일관된 선택**입니다.",
      ),
      mcq(
        "consistency",
        "이 유닛이 다룬 \"없는 것들\"을 관통하는 한 가지 일관된 동기는?",
        [
          "숨은 제어 흐름·상태·디스패치를 없애 코드를 읽는 그대로 믿게 한다",
          "다른 언어와 문법을 똑같이 맞추려고",
          "컴파일러 구현이 어려워서 미뤄둔 것뿐",
          "함수형이 아니라 객체지향을 지향하기 때문",
        ],
        0,
        "맞아요! 타입 클래스(숨은 디스패치)·예외(숨은 제어 흐름)·뮤테이션(숨은 상태)을 모두 빼서, 코드가 보이는 그대로 동작하게 만든 일관된 선택입니다.",
        [
          #(1, "오히려 다른 언어의 관습을 의도적으로 *덜어낸* 쪽입니다 — 똑같이 맞추려는 게 아니에요."),
          #(2, "구현 난이도가 아니라 설계 철학에 따른 선택이에요 — FAQ가 그 이유를 분명히 밝힙니다."),
          #(3, "Gleam은 함수형 언어입니다 — 이 선택들은 함수형 철학을 *강화*하는 쪽이에요."),
        ],
      ),
    ],
  )
}

fn unit_capstone() -> Unit {
  let meta =
    UnitMeta(
      id: "u15-capstone",
      title: "캡스톤",
      order: 15,
      level: 4,
      concepts: [Concept("basics")],
      prerequisites: [
        "u12-opaque-types", "u13-intentional-crash", "u14-gleam-omits",
      ],
      lesson_ids: [
        "l15-csv-parser", "l15-state-machine", "l15-otp-actor",
        "l15-next-steps",
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
    title: "종합 1 — CSV 한 줄 파서",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "드디어 캡스톤입니다. 지금까지 배운 도구를 **하나의 작은 프로그램**으로 엮어 봅시다.\n\n목표: `\"lucy,8\"` 같은 CSV 한 줄을 받아 `Player(name, age)`로 파싱하고, 실패하면 **이유를 담은 에러**를 돌려주는 함수입니다. 동원하는 것 — 커스텀 타입(U4), `Result`와 에러 타입(U9), `string.split`/`case` 패턴(U3·U5), 그리고 조립을 위한 `use`(U10).\n\n```gleam\nimport gleam/int\nimport gleam/string\n\npub type ParseError {\n  WrongFieldCount\n  BadAge\n}\n\npub type Player {\n  Player(name: String, age: Int)\n}\n\nfn parse_age(s: String) -> Result(Int, ParseError) {\n  case int.parse(s) {\n    Ok(n) -> Ok(n)\n    Error(_) -> Error(BadAge)\n  }\n}\n\nfn parse_line(line: String) -> Result(Player, ParseError) {\n  case string.split(line, \",\") {\n    [name, age_str] ->\n      case parse_age(age_str) {\n        Ok(age) -> Ok(Player(name: name, age: age))\n        Error(e) -> Error(e)\n      }\n    _ -> Error(WrongFieldCount)\n  }\n}\n```\n\n핵심은 두 가지 실패 경로(필드 개수가 틀림, 나이가 숫자가 아님)를 **타입으로** 구분해 둔 것입니다.",
      ),
      predict(
        "parse-happy",
        "정상 입력입니다. `parse_line(\"lucy,8\")`의 값은?",
        "parse_line(\"lucy,8\")",
        [
          "`Ok(Player(name: \"lucy\", age: 8))`", "`Player(\"lucy\", 8)`",
          "`Ok(#(\"lucy\", 8))`", "`Error(BadAge)`",
        ],
        0,
        "정확해요! `split`이 `[\"lucy\", \"8\"]`로 두 필드가 되고, `parse_age(\"8\")`가 `Ok(8)`이라 `Ok(Player(...))`로 감싸집니다.",
        [
          #(1, "성공 경로는 항상 `Ok(...)`로 **감싸** 돌려줍니다 — 함수 반환 타입이 `Result`예요."),
          #(2, "튜플이 아니라 우리가 정의한 `Player` 레코드를 만듭니다."),
          #(3, "`\"8\"`은 숫자로 잘 파싱되니 `BadAge`가 아니라 성공입니다."),
        ],
      ),
      Prose(
        "split-shape",
        "왜 `case string.split(line, \",\")`의 가지가 `[name, age_str]`일까요? `string.split`은 **리스트**를 돌려주기 때문입니다. `\"lucy,8\"`은 `[\"lucy\", \"8\"]` — 정확히 원소 2개. 그래서 `[name, age_str]` 패턴이 맞아떨어지고, 그 외 모든 모양은 `_`로 떨어져 `WrongFieldCount`가 됩니다.",
      ),
      predict(
        "split-result",
        "이 `string.split`의 결과는?",
        "string.split(\"lucy,8\", \",\")",
        [
          "`[\"lucy\", \"8\"]`", "`#(\"lucy\", \"8\")`", "`\"lucy 8\"`",
          "`[\"lucy,8\"]`",
        ],
        0,
        "맞아요! `split`은 구분자로 잘라 **문자열 리스트**를 줍니다 — 원소 2개라 `[name, age_str]` 패턴과 일치합니다.",
        [
          #(1, "튜플이 아니라 리스트예요 — 그래서 `[...]` 패턴으로 매칭합니다."),
          #(2, "split은 자르는 함수예요 — 합치지 않습니다."),
          #(3, "구분자 `,`로 **나뉘므로** 원소가 둘이 됩니다 — 통째로 한 개가 아니에요."),
        ],
      ),
      predict(
        "parse-fewfields",
        "필드가 부족합니다. `parse_line(\"lucy\")`의 값은?",
        "parse_line(\"lucy\")",
        [
          "`Error(WrongFieldCount)`", "`Error(BadAge)`",
          "`Ok(Player(\"lucy\", 0))`", "`Error(Nil)`",
        ],
        0,
        "정확해요! `split(\"lucy\", \",\")`는 `[\"lucy\"]` — 원소 1개라 `[name, age_str]`에 안 맞고 `_` 가지로 떨어집니다.",
        [
          #(1, "나이를 파싱하는 단계까지 가지도 못해요 — 필드 개수에서 먼저 걸립니다."),
          #(2, "빠진 값을 0으로 채우지 않습니다 — 실패는 실패로 보고해요."),
          #(3, "에러를 막연한 `Nil`이 아니라 **이유가 있는** `WrongFieldCount`로 구분해 둔 게 핵심입니다."),
        ],
      ),
      predict(
        "parse-badage",
        "나이가 숫자가 아닙니다. `parse_line(\"lucy,eight\")`의 값은?",
        "parse_line(\"lucy,eight\")",
        [
          "`Error(BadAge)`", "`Error(WrongFieldCount)`",
          "`Ok(Player(\"lucy\", 0))`", "`Ok(Player(\"lucy\", 8))`",
        ],
        0,
        "맞아요! 필드는 2개라 통과하지만 `int.parse(\"eight\")`가 `Error(_)` → `parse_age`가 `BadAge`를 돌려줍니다.",
        [
          #(1, "필드 개수는 2개로 맞아요 — 막히는 곳은 나이 파싱 단계입니다."),
          #(2, "`\"eight\"`를 숫자로 추측해 채우지 않아요 — 파싱 실패를 그대로 보고합니다."),
          #(3, "`\"eight\"`는 정수로 파싱되지 않습니다 — `8`이라는 값은 나오지 않아요."),
        ],
      ),
      Prose(
        "use-assembly",
        "중첩된 `case`가 거슬리죠? 두 단계를 각각 `Result`를 돌려주는 작은 함수로 쪼개면 `use`(U10)로 평평하게 조립됩니다. 단계 중 하나라도 `Error`면 **즉시 단락(short-circuit)**되어 그 에러가 그대로 반환됩니다.\n\n```gleam\nimport gleam/result\n\nfn parse_line(line: String) -> Result(Player, ParseError) {\n  use pair <- result.try(fields(line))\n  let #(name, age_str) = pair\n  use age <- result.try(parse_age(age_str))\n  Ok(Player(name: name, age: age))\n}\n```\n\n동작은 중첩 `case` 버전과 **완전히 같습니다** — 읽기만 쉬워졌어요.",
      ),
      mcq(
        "use-shortcircuit",
        "위 `use` 버전에서 `fields(line)`이 `Error(WrongFieldCount)`를 돌려주면 그 다음 줄들은 어떻게 될까요?",
        [
          "실행되지 않고 `Error(WrongFieldCount)`가 즉시 반환된다",
          "`age`가 `0`으로 채워진 채 계속 실행된다", "런타임 크래시가 난다",
          "마지막 `Ok(Player(...))`가 그대로 반환된다",
        ],
        0,
        "맞아요! `result.try`는 첫 `Error`에서 단락합니다 — 뒤 단계는 건너뛰고 그 에러가 함수 결과가 됩니다.",
        [
          #(1, "빈자리를 기본값으로 메우지 않아요 — `use`는 실패를 만나면 멈춥니다."),
          #(2, "이건 정상적인 `Result` 흐름이라 크래시가 아니에요 — 에러를 **값으로** 돌려줍니다."),
          #(3, "마지막 `Ok`까지 도달하려면 모든 단계가 `Ok`여야 합니다 — 하나라도 `Error`면 못 가요."),
        ],
      ),
    ],
  )
}

fn lesson_state_machine() -> Lesson {
  Lesson(
    id: "l15-state-machine",
    unit_id: "u15-capstone",
    title: "종합 2 — 상태 기계",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "intro",
        "두 번째 종합 과제는 **상태 기계(state machine)**입니다. 상태와 이벤트를 각각 variant로 정의하고, `(상태, 이벤트) -> 다음 상태` 전이 함수를 `case`로 적습니다.\n\n예: 동전을 넣어야 열리는 개찰구.\n\n```gleam\npub type State {\n  Locked\n  Unlocked\n}\n\npub type Event {\n  Coin\n  Push\n}\n\nfn next(state: State, event: Event) -> State {\n  case state, event {\n    Locked, Coin -> Unlocked\n    Locked, Push -> Locked\n    Unlocked, Coin -> Unlocked\n    Unlocked, Push -> Locked\n  }\n}\n```\n\n`case state, event`로 **두 값을 동시에** 매칭합니다. 상태 2종 × 이벤트 2종 = 가지 4개 — 컴파일러가 빠진 조합이 없는지 검사해 줍니다(exhaustiveness, U4).",
      ),
      predict(
        "next-coin",
        "잠긴 개찰구에 동전을 넣습니다. `next(Locked, Coin)`의 값은?",
        "next(Locked, Coin)",
        ["`Unlocked`", "`Locked`", "`Coin`", "`Ok(Unlocked)`"],
        0,
        "맞아요! `Locked, Coin -> Unlocked` 가지에 매칭됩니다 — 동전이 빗장을 풉니다.",
        [
          #(1, "동전을 넣으면 상태가 바뀝니다 — `Locked`에 머물지 않아요."),
          #(2, "`next`는 **다음 상태**를 돌려줍니다 — 이벤트(`Coin`)가 아니에요."),
          #(3, "이 전이 함수는 그냥 `State`를 돌려줍니다 — `Result`로 감싸지 않아요."),
        ],
      ),
      predict(
        "next-push-locked",
        "잠긴 개찰구를 그냥 밉니다. `next(Locked, Push)`의 값은?",
        "next(Locked, Push)",
        ["`Locked`", "`Unlocked`", "`Push`", "`Error(Locked)`"],
        0,
        "정확해요! `Locked, Push -> Locked` — 동전 없이 밀면 그대로 잠긴 상태입니다.",
        [
          #(1, "밀기만으로는 안 열려요 — 동전을 넣어야 `Unlocked`가 됩니다."),
          #(2, "결과는 다음 **상태**예요 — 이벤트가 아닙니다."),
          #(3, "막힌 것은 정상 전이일 뿐 에러가 아니에요 — 그냥 `Locked`로 남습니다."),
        ],
      ),
      Prose(
        "run-fold",
        "이벤트가 **여러 개**라면? `list.fold`(U8)로 초기 상태에서 시작해 이벤트를 하나씩 먹이면 됩니다 — 누산기가 곧 상태예요.\n\n```gleam\nimport gleam/list\n\nfn run(state: State, events: List(Event)) -> State {\n  list.fold(events, state, fn(s, e) { next(s, e) })\n}\n```\n\nfold의 누산기 타입이 원소 타입과 달라도 된다(U8)는 점이 여기서 빛납니다 — 누산기는 `State`, 원소는 `Event`예요.",
      ),
      predict(
        "run-sequence",
        "잠긴 상태에서 이벤트 4개를 순서대로 처리합니다. `run(Locked, [Coin, Push, Push, Coin])`의 값은?",
        "run(Locked, [Coin, Push, Push, Coin])",
        [
          "`Unlocked`", "`Locked`",
          "`[Unlocked, Locked, Locked, Unlocked]`", "`Coin`",
        ],
        0,
        "맞아요! Locked →(Coin) Unlocked →(Push) Locked →(Push) Locked →(Coin) Unlocked. 마지막 상태는 `Unlocked`입니다.",
        [
          #(1, "마지막 이벤트가 `Coin`이라 잠금이 풀려요 — 끝 상태는 `Unlocked`입니다."),
          #(2, "fold는 **마지막 누산기 하나**만 돌려줍니다 — 중간 상태 리스트가 아니에요."),
          #(3, "`run`은 최종 **상태**를 돌려줍니다 — 이벤트가 아닙니다."),
        ],
      ),
      predict(
        "run-push-first",
        "이번엔 밀고 나서 동전. `run(Locked, [Push, Coin])`의 값은?",
        "run(Locked, [Push, Coin])",
        ["`Unlocked`", "`Locked`", "`Error(Push)`", "`[Locked, Unlocked]`"],
        0,
        "정확해요! Locked →(Push) Locked →(Coin) Unlocked. 먼저 민 것은 효과 없이 잠긴 채였다가, 동전으로 풀립니다.",
        [
          #(1, "마지막에 동전을 넣었으니 풀립니다 — `Locked`로 끝나지 않아요."),
          #(2, "잘못된 순서의 이벤트도 그냥 \"상태 유지\"로 흡수돼요 — 에러가 아닙니다."),
          #(3, "fold는 중간 과정을 모으지 않고 **최종 상태**만 줍니다."),
        ],
      ),
      mcq(
        "exhaustiveness",
        "전이 함수에서 `Unlocked, Push -> Locked` 가지를 **삭제하면** 어떻게 될까요?",
        [
          "컴파일 에러 — 매칭되지 않는 조합(Unlocked, Push)이 있다고 컴파일러가 막는다",
          "잘 컴파일되고, 그 조합이 오면 런타임에 무시된다",
          "잘 컴파일되고, 그 조합이 오면 자동으로 `Unlocked`가 된다",
          "경고만 뜨고 컴파일은 통과한다",
        ],
        0,
        "맞아요! `case`는 모든 조합을 빠짐없이 다뤄야 합니다(exhaustiveness). 한 조합을 빼면 컴파일 자체가 거부돼요 — 상태 기계의 구멍을 컴파일 타임에 잡아 줍니다.",
        [
          #(1, "Gleam은 \"런타임에 무시\" 같은 건 없어요 — 빠진 케이스는 컴파일을 막습니다."),
          #(2, "빠진 가지를 어떤 값으로도 자동 채우지 않습니다 — 직접 다 적어야 해요."),
          #(3, "누락된 case는 경고가 아니라 **에러**입니다 — 컴파일이 통과하지 않아요."),
        ],
      ),
    ],
  )
}

fn lesson_otp_actor() -> Lesson {
  Lesson(
    id: "l15-otp-actor",
    unit_id: "u15-capstone",
    title: "OTP와 actor — 다음 세계 (읽기 전용)",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "banner",
        "⚠️ **이 레슨의 코드는 실행되지 않습니다.** gleam_otp의 actor는 Erlang VM 전용이라 브라우저(JS 타깃)에서 돌릴 수 없어요. Gleam 컴파일러는 타깃별 지원을 표현식 단위로 추적하기 때문에, 이런 코드는 JS로 컴파일하면 거부됩니다.\n\n그래서 이 레슨은 **읽고 이해하는** 레슨입니다 — 출력 예측 대신 개념 문제만 풀어요. \"다음 세계\"가 어떤 모습인지 미리 엿보는 시간입니다.",
      ),
      Prose(
        "what-is-actor",
        "지금까지 배운 상태 기계를 떠올려 보세요. `run`은 이벤트 리스트를 **한 번에** 접었습니다. 그런데 실제 서버는 이벤트가 시간에 걸쳐, 여러 곳에서 동시에 들어옵니다.\n\n**actor**는 그 상태 기계를 \"살아 있는 프로세스\"로 만든 것입니다. 자기만의 상태를 들고, 메시지를 하나씩 받아 처리하며, 다음 상태를 들고 다음 메시지를 기다립니다. 메시지를 보낼 수는 있어도 그 상태를 **직접 만질 수는 없어요** — 동시성 버그(공유 메모리 경쟁)가 원천 차단됩니다. 우리가 배운 불변성·전이 함수가 그대로 확장된 모습입니다.",
      ),
      mcq(
        "actor-why-no-run",
        "왜 이 레슨의 actor 코드는 브라우저에서 실행할 수 없을까요?",
        [
          "gleam_otp는 Erlang VM 전용이고, 컴파일러가 JS 타깃 미지원을 표현식 단위로 추적하기 때문",
          "actor 코드에 문법 오류가 있어서",
          "코드가 너무 길어서 브라우저가 멈추기 때문",
          "Gleam은 원래 브라우저에서 전혀 실행되지 않기 때문",
        ],
        0,
        "맞아요! Gleam은 Erlang과 JavaScript 두 타깃으로 컴파일되는데, OTP/actor는 Erlang VM의 기능이라 JS 타깃에선 지원되지 않습니다. 컴파일러가 이를 타깃별로 추적해요.",
        [
          #(1, "문법 문제가 아니라 **타깃(런타임) 차이** 때문입니다 — 코드 자체는 올바릅니다."),
          #(2, "길이의 문제가 아니에요 — Erlang 전용 기능이라 JS로는 컴파일되지 않습니다."),
          #(3, "Gleam은 JS 타깃으로 브라우저에서 잘 돕니다 — 이 강의의 다른 레슨이 그 증거예요. 단지 OTP만 Erlang 전용입니다."),
        ],
      ),
      mcq(
        "actor-vs-statemachine",
        "우리가 U15-②에서 만든 `next`/`run` 상태 기계와 비교할 때, actor의 핵심 차이는?",
        [
          "actor는 상태를 들고 살아서 메시지를 하나씩 비동기로 받지만, `run`은 이벤트 리스트를 한 번에 접는다",
          "actor는 가변(mutable) 변수를 자유롭게 재할당할 수 있다",
          "actor에는 상태 개념이 없다", "actor는 `case`를 쓸 수 없다",
        ],
        0,
        "맞아요! actor는 상태 기계를 \"살아 있는 프로세스\"로 만든 것 — 메시지를 시간에 걸쳐 하나씩 받아 다음 상태로 넘어갑니다. 전이 함수 사고는 그대로예요.",
        [
          #(1, "actor도 여전히 불변입니다 — 상태를 재할당하는 게 아니라 다음 상태를 **돌려줍니다**."),
          #(2, "actor의 본질이 바로 상태를 들고 다니는 것입니다 — 상태가 없는 게 아니에요."),
          #(3, "actor 내부의 메시지 처리도 보통 `case`로 분기합니다 — 우리가 배운 그대로예요."),
        ],
      ),
      mcq(
        "actor-shared-state",
        "actor 모델이 동시성 버그를 줄여 주는 이유로 가장 알맞은 것은?",
        [
          "다른 프로세스가 actor의 상태를 직접 만지지 못하고 메시지로만 소통해서, 공유 메모리 경쟁이 사라지기 때문",
          "actor는 한 번에 하나의 프로그램만 실행되도록 강제하기 때문",
          "actor를 쓰면 모든 함수가 자동으로 빨라지기 때문",
          "actor는 에러를 절대 일으키지 않기 때문",
        ],
        0,
        "맞아요! 상태는 actor 안에 갇혀 있고 바깥은 메시지만 보냅니다 — 여러 프로세스가 같은 메모리를 동시에 건드리는 고전적 경쟁 조건이 구조적으로 사라져요. 불변성 + 메시지 패싱의 힘입니다.",
        [
          #(1, "오히려 반대예요 — 여러 actor가 **동시에** 돌면서도 안전한 게 장점입니다."),
          #(2, "actor는 동시성 모델이지 속도 보장 도구가 아니에요 — 빨라진다는 보장은 없습니다."),
          #(3, "actor도 실패할 수 있어요 — OTP는 오히려 \"실패하면 감독자가 재시작\"하는 철학(U13의 크래시 사고와 연결)입니다."),
        ],
      ),
    ],
  )
}

fn lesson_next_steps() -> Lesson {
  Lesson(
    id: "l15-next-steps",
    unit_id: "u15-capstone",
    title: "수료와 다음 경로",
    emits_tags: [Concept("basics")],
    srs_items: [],
    blocks: [
      Prose(
        "congrats",
        "여기까지 왔습니다. 값과 불변성에서 시작해 함수·case·커스텀 타입·리스트·고차 함수·`Result`·`use`·opaque 타입·의도적 크래시까지 — Gleam으로 **생각하는 법**을 익혔어요.\n\n이 마지막 레슨은 코드가 없습니다. 배운 것을 어디로 가져갈지, 다음 경로를 정리합니다.",
      ),
      Prose(
        "paths",
        "추천 경로 세 가지:\n\n- **Exercism Gleam 트랙** — 작은 연습 문제를 멘토 피드백과 함께 풉니다. 손으로 더 많이 써 볼 곳.\n- **CodeCrafters** — \"직접 Redis/Git을 만들어 보기\" 같은 큰 프로젝트로 실전 감각을 키웁니다.\n- **본 플랫폼 트레이닝 모드** — 레이팅 퍼즐·SRS 복습·타임드(Code Storm)가 상시 운영됩니다. 레슨에서 틀린 테마는 개인 재훈련 큐로 들어가 다시 만나게 됩니다.\n\n무엇을 고르든, 작은 것을 자주 만드는 것이 핵심입니다.",
      ),
      mcq(
        "next-handson",
        "\"멘토 피드백을 받으며 작은 연습 문제를 더 풀고 싶다\"면 어디가 가장 알맞을까요?",
        [
          "Exercism Gleam 트랙", "CodeCrafters", "더 이상 연습할 곳은 없다",
          "Erlang 공식 문서만 읽기",
        ],
        0,
        "맞아요! Exercism은 작은 연습 문제 + 멘토 리뷰 모델이라 \"손으로 더 써 보기\"에 가장 잘 맞습니다.",
        [
          #(1, "CodeCrafters는 작은 연습보다 **큰 프로젝트**를 직접 만드는 쪽에 가깝습니다."),
          #(2, "오히려 갈 곳이 많아요 — 이 레슨이 그 목록입니다."),
          #(3, "문서 읽기도 좋지만, \"멘토 피드백 + 연습 문제\"라는 조건엔 Exercism이 더 맞습니다."),
        ],
      ),
      mcq(
        "next-bigproject",
        "\"Redis나 Git 같은 걸 처음부터 직접 만들어 보며 실전 감각을 키우고 싶다\"면?",
        [
          "CodeCrafters", "Exercism Gleam 트랙", "본 플랫폼의 타임드 모드만 반복",
          "아무 경로도 추천되지 않는다",
        ],
        0,
        "맞아요! CodeCrafters는 유명 소프트웨어를 단계적으로 직접 구현하는 큰 프로젝트형 학습에 특화돼 있습니다.",
        [
          #(1, "Exercism은 작은 연습 문제 중심이라 \"큰 프로젝트 직접 만들기\"와는 결이 다릅니다."),
          #(2, "타임드 모드는 빠른 반사 훈련용이에요 — 큰 프로젝트 구현과는 목적이 다릅니다."),
          #(3, "이 레슨이 바로 다음 경로를 추천하는 곳입니다 — 갈 곳이 있어요."),
        ],
      ),
      mcq(
        "next-training",
        "레슨에서 자주 틀린 테마(예: fold 방향)를 꾸준히 복습하고 싶다면, 본 플랫폼에서 무엇이 도와줄까요?",
        [
          "트레이닝 모드 — 틀린 테마가 개인 재훈련 큐와 SRS 복습으로 다시 서빙된다",
          "레슨을 처음부터 전부 다시 듣는 것만이 방법이다",
          "한 번 틀린 문제는 다시 볼 수 없다",
          "트레이닝 모드는 새 사용자만 쓸 수 있다",
        ],
        0,
        "맞아요! 틀린 마이크로 연습은 테마 태그와 함께 실패 로그로 쌓여 개인화 재훈련 큐(SRS 포함)로 돌아옵니다 — 약한 곳을 집중적으로 다시 만나게 됩니다.",
        [
          #(1, "전체를 다시 들을 필요 없어요 — 약한 테마만 골라 복습하도록 설계돼 있습니다."),
          #(2, "오히려 틀린 문제를 **다시 만나도록** 큐에 넣는 게 핵심 기능입니다."),
          #(3, "트레이닝 모드는 수료 후에도 상시 운영됩니다 — 누구나 계속 쓸 수 있어요."),
        ],
      ),
    ],
  )
}

// ── 생성 헬퍼 ─────────────────────────────────────────────────────

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
