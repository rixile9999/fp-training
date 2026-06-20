//// 경량 마크다운 → Lustre 렌더러 — 레슨 prose·prompt·choices·feedback 공용.
////
//// 지원하는 부분집합(학습 콘텐츠가 실제로 쓰는 것): 펜스 코드블록(```lang),
//// 인라인 코드(`code`), 굵게(**bold**), 문단(빈 줄 분리), 불릿 리스트(- / *),
//// 헤딩(#/##/###). 전체 CommonMark 가 아니라, 콘텐츠가 쓰는 만큼만 안전하게
//// 렌더한다. 코드 구문 하이라이팅은 후속(현재는 monospace 보존).
////
//// 순수 모듈 — gleam/stdlib + lustre 만 import. msg 제네릭(이벤트 없음).

import gleam/list
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// 블록 레벨 렌더 — prose 세그먼트용. 코드블록/문단/리스트/헤딩을 조립한다.
pub fn render(markdown: String) -> Element(msg) {
  html.div([attribute.class("md")], list.flat_map(split_blocks(markdown), render_block))
}

/// 인라인 전용 렌더 — 한 줄 텍스트(prompt·choice·feedback)의 `code`·**bold** 처리.
/// 결과는 부모가 적절한 컨테이너(p/span/button 등)에 넣는다.
pub fn inline(text: String) -> List(Element(msg)) {
  // 백틱으로 split: 홀수 인덱스 = 코드 스팬, 짝수 = 일반 텍스트(그 안에서 bold 처리).
  text
  |> string.split("`")
  |> list.index_map(fn(part, i) {
    case i % 2 == 1 {
      True -> [html.code([attribute.class("md-icode")], [html.text(part)])]
      False -> bold(part)
    }
  })
  |> list.flatten
}

fn bold(text: String) -> List(Element(msg)) {
  // "**" 로 split: 홀수 인덱스 = 굵게.
  text
  |> string.split("**")
  |> list.index_map(fn(part, i) {
    case i % 2 == 1 {
      True -> html.strong([], [html.text(part)])
      False -> html.text(part)
    }
  })
}

// ── 블록 파싱 ───────────────────────────────────────────────────────

type Block {
  Code(text: String)
  Prose(text: String)
}

fn split_blocks(md: String) -> List(Block) {
  let lines = string.split(md, "\n")
  let #(blocks, in_fence, buf) =
    list.fold(lines, #([], False, []), fn(state, line) {
      let #(blocks, in_fence, buf) = state
      let is_fence = string.starts_with(string.trim(line), "```")
      case in_fence, is_fence {
        // 펜스 닫기 → Code 방출
        True, True -> #([Code(joined(buf)), ..blocks], False, [])
        // 펜스 안 → 코드 줄 누적(원문 그대로)
        True, False -> #(blocks, True, [line, ..buf])
        // 펜스 열기 → prose 버퍼 flush
        False, True -> #(flush_prose(buf, blocks), True, [])
        // 일반 prose 줄
        False, False -> #(blocks, False, [line, ..buf])
      }
    })
  let final = case in_fence {
    // 미종료 펜스도 코드로 살림
    True -> [Code(joined(buf)), ..blocks]
    False -> flush_prose(buf, blocks)
  }
  list.reverse(final)
}

fn joined(buf: List(String)) -> String {
  buf |> list.reverse |> string.join("\n")
}

fn flush_prose(buf: List(String), blocks: List(Block)) -> List(Block) {
  case buf {
    [] -> blocks
    _ -> [Prose(joined(buf)), ..blocks]
  }
}

fn render_block(b: Block) -> List(Element(msg)) {
  case b {
    Code(code) -> [
      html.pre([attribute.class("code")], [html.code([], [html.text(code)])]),
    ]
    Prose(text) ->
      text
      |> string.split("\n\n")
      |> list.filter(fn(p) { string.trim(p) != "" })
      |> list.flat_map(render_paragraph)
  }
}

// 한 블록(빈 줄로 구분된 문단) 안에서도 불릿·숫자 리스트가 일반 텍스트 줄과
// 섞일 수 있다("…입니다:" 다음 줄에 바로 "- …"). 줄을 종류별 연속 구간으로
// 묶어 각각 ul/ol/p 로 렌더한다 — 한 덩어리로 합쳐 리스트가 사라지는 걸 막는다.
fn render_paragraph(block: String) -> List(Element(msg)) {
  block
  |> string.split("\n")
  |> list.map(string.trim_start)
  |> list.filter(fn(l) { l != "" })
  |> group_lines
  |> list.map(render_group)
}

type Kind {
  KBullet
  KOrdered
  KText
}

fn classify(line: String) -> Kind {
  case is_bullet(line), parse_ordered(line) {
    True, _ -> KBullet
    _, Ok(_) -> KOrdered
    _, _ -> KText
  }
}

// 연속한 같은 종류의 줄을 하나의 구간(#(종류, 줄들))으로 접는다. 원래 순서 유지.
fn group_lines(lines: List(String)) -> List(#(Kind, List(String))) {
  lines
  |> list.fold([], fn(acc, line) {
    let kind = classify(line)
    case acc {
      [#(k, items), ..rest] if k == kind -> [#(k, [line, ..items]), ..rest]
      _ -> [#(kind, [line]), ..acc]
    }
  })
  |> list.reverse
  |> list.map(fn(g) {
    let #(k, items) = g
    #(k, list.reverse(items))
  })
}

fn render_group(group: #(Kind, List(String))) -> Element(msg) {
  let #(kind, lines) = group
  case kind {
    KBullet ->
      html.ul([attribute.class("md-ul")], list.map(lines, bullet_item))
    KOrdered ->
      html.ol([attribute.class("md-ol")], list.map(lines, ordered_item))
    KText ->
      case lines {
        [single] ->
          case parse_heading(single) {
            Ok(#(level, body)) -> heading(level, body)
            Error(_) -> html.p([], inline(single))
          }
        // 소프트 개행은 공백으로 접어 한 문단으로 (마크다운 표준 동작)
        many -> html.p([], inline(string.join(many, " ")))
      }
  }
}

fn is_bullet(line: String) -> Bool {
  string.starts_with(line, "- ") || string.starts_with(line, "* ")
}

fn bullet_item(line: String) -> Element(msg) {
  html.li([], inline(string.drop_start(line, 2)))
}

// "1. ", "12. " 처럼 [숫자]+". " 로 시작하면 본문을 돌려준다.
fn parse_ordered(line: String) -> Result(String, Nil) {
  case string.split_once(line, ". ") {
    Ok(#(prefix, body)) ->
      case prefix != "" && is_all_digits(prefix) {
        True -> Ok(body)
        False -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

fn ordered_item(line: String) -> Element(msg) {
  case parse_ordered(line) {
    Ok(body) -> html.li([], inline(body))
    Error(_) -> html.li([], inline(line))
  }
}

fn is_all_digits(s: String) -> Bool {
  string.to_graphemes(s)
  |> list.all(fn(c) {
    case c {
      "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
      _ -> False
    }
  })
}

fn parse_heading(line: String) -> Result(#(Int, String), Nil) {
  case line {
    "### " <> rest -> Ok(#(3, rest))
    "## " <> rest -> Ok(#(2, rest))
    "# " <> rest -> Ok(#(1, rest))
    _ -> Error(Nil)
  }
}

fn heading(level: Int, body: String) -> Element(msg) {
  case level {
    1 -> html.h3([attribute.class("md-h md-h1")], inline(body))
    _ -> html.h4([attribute.class("md-h")], inline(body))
  }
}
