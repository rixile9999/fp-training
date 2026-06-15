# Research: gleam-ecosystem

Gleam status as of June 2026: current stable is v1.17.0 (released 2026-06-02). Release cadence is roughly every 6-7 weeks; the last year shipped v1.11 (2025-06-02, `assert` keyword, 30% faster JS via decision-tree pattern matching, `gleam dev` command + dev/ directory), v1.12 (2025-08-05, better dependency-resolution errors, `echo` with messages), v1.13 (2025-10-19, formalised external/FFI APIs incl. generated JS constructors like `Person$Teacher()`), v1.14 (2025-12-25, @external type annotations, type-directed autocompletion), v1.15 (2026-03-16, Hex security), v1.16 (2026-04-24, JavaScript source maps, package-level fault tolerance), v1.17 (escript export, `todo` in constants). gleam_stdlib reached 1.0 (1.0.3, 2026-05-29) — stable APIs, good for curriculum longevity.

Platform-building stack: Lustre v5.7.0 (2026-05-06, 252k downloads, 2.3k stars, primary maintainer Hayleigh Thompson) is explicitly Elm-inspired Model-View-Update with managed effects, and supports four render modes: SPA, SSR/static HTML templating, standalone Web Components, and real-time server components (server-held state, ~10kb client runtime patching DOM over WebSocket/SSE/polling). Backend: Wisp 2.2.2 (2026-03-27) on Mist 6.0.3 (2026-04-18) is the standard Erlang-target HTTP stack; both actively maintained with ~20k monthly downloads each. A static-only architecture is highly viable because the official Gleam compiler ships a browser/WASM build with every release (gleam-$VERSION-browser.tar.gz on GitHub releases); the official language tour and LiveCodes both compile Gleam→JS fully in-browser (Web Worker + base64 data-URL dynamic import of ES modules, precompiled stdlib). This is the proven pattern for interactive lessons/drills without any code-execution server.

Editor tooling: CodeMirror 6 has a community Gleam package (@exercism/codemirror-lang-gleam, Lezer grammar + LanguageSupport, v1.0.0 from July 2023 — old but Gleam syntax is stable post-1.0; the giacomocavalieri original is archived). Monaco has no Gleam support (would need a custom Monarch grammar). No in-browser LSP exists — the Gleam language server is bundled in the native Rust `gleam` binary only. The official tour uses lightweight CodeFlask, proving sophisticated editing isn't required; compiler diagnostics from the WASM compiler are the realistic feedback channel. tree-sitter-gleam (official, gleam-lang org) exists for static highlighting of lesson content.

Curriculum facts verified via the official tour (tour.gleam.run/everything/): the language covers pipelines (|>), case with exhaustiveness, custom types/records, Result + Option (Option lives in stdlib, not core), use expressions (sugar passing trailing anonymous function), function captures `f(_, x)`, labelled arguments + shorthand, opaque types, generics, recursion/tail calls (no loop constructs exist), let assert (partial pattern, crashes on mismatch), `assert` (bool, v1.11+), todo/panic, externals/multi-target externals. Concurrency: gleam_otp v1.2.0 (typed actors, static/factory supervisors) runs only on the Erlang VM — confirmed; the compiler tracks target support per-expression so OTP code simply won't compile for JS. Deliberately absent (FAQ-confirmed): type classes (explicitly "no", with stated reasoning), exceptions, mutable state, macros/metaprogramming (none currently, "open" long-term), auto-currying (captures instead), laziness (eager evaluation; lazy sequences live in the separate gleam_yielder package, not stdlib).

## Key facts

- Current Gleam version: v1.17.0, released 2026-06-02 (gleam.run/news, GitHub releases). Prior year: v1.11.0 2025-06-02, v1.12.0 2025-08-05, v1.13.0 2025-10-19, v1.14.0 2025-12-25, v1.15.0 2026-03-16 (patches to 1.15.4), v1.16.0 2026-04-24, v1.17.0 2026-06-02.
- Notable features added Jun 2025–Jun 2026: `assert` keyword for boolean assertions with rich failure info (v1.11); pattern matching compiled to decision trees making JS output ~30% faster (v1.11); `gleam dev` command + dev/ directory (v1.11); `echo` with custom messages and clearer dependency-conflict errors (v1.12); formalised FFI with documented JS APIs for Gleam data (e.g. Person$Teacher(), Person$isTeacher()) (v1.13); @external type annotations for precise Erlang/TypeScript types (v1.14); JavaScript source maps via javascript.source_maps=true in gleam.toml (v1.16); package-level fault-tolerant compilation (v1.16); `gleam export escript` single-file BEAM executables and `todo` in constants (v1.17).
- gleam_stdlib reached 1.0: current 1.0.3 released 2026-05-29, 1.7M+ all-time downloads, 1504 dependent packages (hex.pm/packages/gleam_stdlib).
- Lustre v5.7.0 (released 2026-05-06; 252,141 all-time / ~7.7k monthly downloads; 2.3k GitHub stars; maintainer hayleigh-dot-dev): explicitly 'Erlang and Elm-inspired' Model-View-Update architecture with init/update/view, managed side effects (lustre/effect), and modules for html/svg/attribute/event/component.
- Lustre supports: SPAs, server-side rendering to static HTML, exporting components as standalone Web Components, and 'universal components' that run in browser, web-component, or server contexts (github.com/lustre-labs/lustre).
- Lustre server components: server-held app state with a ~10kb client runtime; DOM patches pushed over WebSocket (default), SSE, or polling; built on OTP actors on the Erlang target (register_subject) with a JS-target callback variant (register_callback); components persist without connected clients and support multiple clients per instance (lustre.hexdocs.pm/lustre/server_component.html).
- Backend stack: Wisp 2.2.2 (2026-03-27, 'a practical web framework for Gleam', 22k downloads/30 days, maintainer lpil) and Mist 6.0.3 (2026-04-18, Gleam web server, 18.6k downloads/30 days, maintainer rawhat). Both actively maintained on the Erlang target.
- Static-only architecture is proven: every Gleam release publishes an official browser/WASM compiler artifact at https://github.com/gleam-lang/gleam/releases/download/$VERSION/gleam-$VERSION-browser.tar.gz (pattern confirmed in gleam-lang/language-tour bin/download-compiler, which pins v1.15.2).
- The official language tour (tour.gleam.run, source: github.com/gleam-lang/language-tour) compiles Gleam→JavaScript entirely in-browser: Rust compiler compiled to WASM with an in-memory virtual filesystem, compilation in a Web Worker, output ES modules executed via base64 data-URL dynamic import, imports redirected to a precompiled stdlib. LiveCodes (livecodes.io/docs/languages/gleam/) uses the same WASM compiler.
- The tour's editor is CodeFlask (lightweight textarea-overlay editor), not CodeMirror/Monaco — chosen as 'lightweight and easy to use' (gleam.run/news/gleams-new-interactive-language-tour/, Jan 2024).
- CodeMirror 6 Gleam support exists: @exercism/codemirror-lang-gleam on npm (Lezer grammar + LanguageSupport + LRLanguage, exports gleam()/gleamLanguage/lezerParser), v1.0.0 published July 2023; the original giacomocavalieri/codemirror-lang-gleam repo is archived and points to the Exercism org. Low download volume (~380/month).
- Monaco has no built-in or notable community Gleam language support; adding it requires a custom Monarch grammar.
- No in-browser LSP for Gleam exists. The Gleam language server is built into the native `gleam` binary (Rust) and serves desktop editors (VS Code, Zed, Helix) via LSP (gleam.run/language-server/). In-browser feedback must come from WASM-compiler diagnostics instead.
- Official tree-sitter grammar exists at gleam-lang/tree-sitter-gleam for static syntax highlighting of content.
- Tour curriculum topics confirmed (tour.gleam.run/everything/): pipelines |>, case expressions with exhaustiveness, custom types/records/record updates, Results, Option/Result/List/Dict stdlib modules, use expressions, function captures f(_, x), labelled arguments + label shorthand, generic functions and generic custom types, recursion + tail calls (Gleam has no loop constructs), opaque types, let assert, bool assert, todo, panic, externals/multi-target externals, bit arrays, guards, alternative patterns, pattern aliases.
- gleam_otp v1.2.0 (Oct 3, 2025): typed actors, static_supervisor and factory_supervisor, request-reply messaging. It runs ONLY on the Erlang VM — actor functionality is not available on the JavaScript target; the Gleam compiler tracks target support per-expression, so multi-target projects compile as long as OTP code is only reached on Erlang (hexdocs gleam_otp; gleam.run/news/v0.34-multi-target-projects/). gleam_otp itself notes not all OTP system messages are supported and some Erlang/OTP features cannot be typed safely.
- Deliberate omissions vs Haskell-style FP, per official FAQ (gleam.run/frequently-asked-questions/): type classes — explicit no ('confusing error messages... high compile time cost... runtime cost'); exceptions — not used, on the unplanned list; mutable state — none, all data immutable with structural sharing (escape hatches: Erlang ETS, databases); macros/metaprogramming — none currently, team 'open' only if it preserves readability and fast compilation; auto-currying — absent (function captures are the idiom); laziness — evaluation is eager, lazy sequences live in the separate gleam_yielder package (v1.1.0, Nov 2024), not in stdlib.
- Gleam compiles to two targets (Erlang/BEAM and JavaScript); Elixir interop is supported by the build tool (compiles Elixir deps/source), but Elixir macros cannot be called from Gleam.
- Community signals: first all-Gleam conference 'Gleam Gathering' announced 2026-02-11 (gleam.run/news); Exercism has a Gleam track (the CodeMirror grammar is maintained under the Exercism org).

## Recommendations

- Architecture: build the platform as a Lustre SPA (MVU pairs pedagogically with the Elm-style FP being taught) with in-browser Gleam compilation via the official WASM compiler artifact, copying the language-tour pattern (Web Worker + precompiled stdlib + data-URL dynamic import). This makes lessons and drills work static-only; add a thin Wisp/Mist backend later only for accounts, ratings, and spaced-repetition state — or start with localStorage and defer the backend entirely.
- Editor: use CodeMirror 6 with @exercism/codemirror-lang-gleam (fork it to add post-2023 keywords like assert/echo); avoid Monaco (no Gleam grammar, heavier bundle). Surface WASM-compiler diagnostics inline as the feedback loop instead of an LSP.
- Pin a specific Gleam compiler version per curriculum release (the tour pins exactly this way) and upgrade deliberately, since exercises' expected compiler errors/warnings are version-sensitive.
- Curriculum scope (verified feature set): Basics → pipelines → case/exhaustiveness → custom types + generics → Result/Option railway-style error handling → recursion/tail-calls (no loops) → function captures + labelled arguments → use expressions → opaque types → todo/panic/let assert/assert as deliberate-crash tools. Treat OTP actors/supervisors as a capstone Erlang-target module that is illustrative or server-executed, never run in the browser sandbox.
- Explicitly scope OUT typeclasses, currying, macros, and laziness, and turn each into a short 'why Gleam doesn't have this' lesson citing the official FAQ — this is a differentiator versus Haskell-based FP courses and reduces curriculum surface for a solo developer.
- For drill/puzzle content rendering (non-editable code in lessons, spaced-repetition cards), use the official tree-sitter-gleam grammar or highlight.js for cheap static highlighting; reserve the full CodeMirror editor for interactive exercises.
- Exploit new compiler features for exercise UX: v1.16 source maps for debugging compiled output, fault-tolerant compilation for partial-code feedback, and the `assert`/`let assert` keywords for writing self-checking exercise harnesses that produce rich failure messages.

## Risks / limitations

- The @exercism/codemirror-lang-gleam Lezer grammar is v1.0.0 from July 2023 and minimally maintained; it predates newer syntax (echo, assert, label shorthand) so highlighting of new keywords may need a fork/patch. Gleam's core syntax is stable post-v1.0, so drift is limited but real.
- No in-browser language server: in-editor diagnostics must be built from WASM-compiler error output (which is good quality and fault-tolerant since v1.16, but not interactive LSP features like completion/hover).
- gleam_otp/actors are Erlang-target only — an OTP/concurrency curriculum module cannot run in the in-browser (JS-target) sandbox; it would need a server-side execution sandbox or be taught as read-only/illustrative content.
- The WASM browser compiler artifact is published per release but is primarily built for the official tour; its JS API is not a formally documented stable public interface, so pinning a version (as the tour does, v1.15.2) is advisable.
- Lustre has effectively one primary maintainer; ecosystem is small (Lustre ~252k total downloads vs millions for mainstream JS frameworks). Risk is moderate given sponsorship and steady releases, but factor it into a single-developer commitment.
- Lustre server components require a persistent BEAM server and WebSocket infrastructure — likely overkill for a lessons/drills platform where in-browser execution suffices; they also add latency per interaction.
- Some hexdocs summaries above were fetched via an AI-assisted page reader; exact wording of minor changelog items should be re-checked against CHANGELOG.md files before quoting verbatim in published curriculum.
- Running learner-submitted code via dynamic import of compiled JS executes arbitrary code in the page context; the tour accepts this, but a platform with accounts/progress data should isolate execution (worker + sandboxed iframe/CSP).

## Sources

- https://gleam.run/news/
- https://github.com/gleam-lang/gleam/releases
- https://gleam.run/news/single-file-gleam-beam-programs-with-escript
- https://gleam.run/news/javascript-source-maps
- https://gleam.run/news/the-happy-holidays-2025-release
- https://gleam.run/news/formalising-external-apis
- https://gleam.run/news/no-more-dependency-management-headaches
- https://gleam.run/news/gleam-javascript-gets-30-percent-faster
- https://gleam.run/news/upgrading-hex-security
- https://github.com/lustre-labs/lustre
- https://lustre.hexdocs.pm/
- https://lustre.hexdocs.pm/lustre/server_component.html
- https://hex.pm/packages/lustre
- https://hex.pm/packages/wisp
- https://hex.pm/packages/mist
- https://hex.pm/packages/gleam_stdlib
- https://hex.pm/packages/gleam_yielder
- https://gleam-otp.hexdocs.pm/
- https://github.com/gleam-lang/otp
- https://gleam.run/frequently-asked-questions/
- https://tour.gleam.run/everything/
- https://github.com/gleam-lang/language-tour
- https://raw.githubusercontent.com/gleam-lang/language-tour/main/bin/download-compiler
- https://gleam.run/news/gleams-new-interactive-language-tour/
- https://github.com/exercism/codemirror-lang-gleam
- https://github.com/giacomocavalieri/codemirror-lang-gleam
- https://github.com/gleam-lang/tree-sitter-gleam
- https://livecodes.io/docs/languages/gleam/
- https://gleam.run/language-server/
- https://gleam.run/news/v0.34-multi-target-projects/
