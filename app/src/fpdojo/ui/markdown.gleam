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
      |> list.map(render_paragraph)
  }
}

fn render_paragraph(block: String) -> Element(msg) {
  let lines =
    block
    |> string.split("\n")
    |> list.map(string.trim_start)
    |> list.filter(fn(l) { l != "" })
  case lines {
    [] -> html.p([], [])
    [single] ->
      case parse_heading(single) {
        Ok(#(level, body)) -> heading(level, body)
        Error(_) ->
          case is_bullet(single) {
            True -> html.ul([attribute.class("md-ul")], [bullet_item(single)])
            False -> html.p([], inline(single))
          }
      }
    many ->
      case list.all(many, is_bullet) {
        True -> html.ul([attribute.class("md-ul")], list.map(many, bullet_item))
        // 소프트 개행은 공백으로 접어 한 문단으로 (마크다운 표준 동작)
        False -> html.p([], inline(string.join(many, " ")))
      }
  }
}

fn is_bullet(line: String) -> Bool {
  string.starts_with(line, "- ") || string.starts_with(line, "* ")
}

fn bullet_item(line: String) -> Element(msg) {
  html.li([], inline(string.drop_start(line, 2)))
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
