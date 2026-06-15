# Research: existing-platforms

Survey of interactive programming-learning platforms (June 2026), for positioning a chess-platform-style Gleam FP trainer.

EXERCISM separates Concept Exercises (extremely focused, teach one concept, one expected approach) from Practice Exercises (open-ended, unlocked once prerequisite concepts are learned). A track's syllabus is a tree of concepts unique to each language; config.json encodes per-exercise "prerequisites" (concepts needed) and "practices" (concepts reinforced). The Gleam track has 122 exercises / 33 advertised concepts (config.json lists 36 concept slugs, 28 active concept exercises + 97 practice exercises, difficulty rated 1-9), ~7,700 students, 112 contributors, 109 mentors. Concepts span basics through results, options, pipe-operator, recursion/TCO, generics, opaque types, phantom types, use-expressions. Test-runner architecture: one Docker image per track (gleam-test-runner is written in Gleam, generated from a generic template, AGPL-3.0); invoked as run.sh <exercise-slug> <input-dir> <output-dir>, must write results.json and exit 0 regardless of test outcome; 20s wall-clock limit, 3GB RAM; results.json has version 1/2/3 (v2 = per-test results, required for concept exercises; v3 adds task_id), status pass/fail/error, per-test name/status/message/test_code/output (500-char cap).

EXECUTE PROGRAM (Gary Bernhardt) is the closest existing "Chessable for code": lessons interleave prose with machine-graded typed-code questions; later lessons stay locked until prerequisites are both read AND successfully reviewed under SRS; expanding review intervals retire an item after its 4th success (~day 64); wrong answers don't penalize unless you "give up" (then interval shrinks); daily new-lesson caps prevent binging; reviews ~10 min/day initially, decaying. $39/mo or $235/yr. Courses are TypeScript/JS/SQL/Regex/Python — zero FP languages.

CODEWARS: kata rated 8 kyu (easiest) to 1 kyu, then 1-8 dan for users. Rank progress points per kata: 8kyu=2, 7=3, 6=8, 5=21, 4=55, 3=149, 2=404, 1kyu=1,097; only first-ever completion of a kata counts. Honor (activity currency) per completion: 2/8/32/128 by color tier, plus authoring, translations, upvotes; rank-up bonuses 20→12,800 honor. Supports Haskell, Elixir, F#, OCaml etc. but NOT Gleam (open request, codewars.com discussion #3242).

FIX-THE-BROKEN-CODE LINEAGE: Rustlings (official rust-lang project, ~23 topic folders, variables→conversions) gives tiny programs that fail to compile or fail tests; watch mode re-runs on save, 'h' for hints, explicit advance. Ziglings: 111 broken programs, same model. Elixir koans: `mix meditate`, fill in ___ blanks, autorunner on save.

BRILLIANT.ORG: problem-first lessons interleaving short explanations with manipulable interactives and embedded check questions, instant feedback, Rive-animated celebrations, near-neighbor practice problems, ML-driven misconception targeting.

FP LANDSCAPE: Haskell MOOC (Helsinki) is free and exercise-driven but uses local .hs files + test harness, no SRS/ratings. Gleam Language Tour (tour.gleam.run) compiles Gleam to JavaScript and runs it entirely in-browser as you type — proof that a serverless code-execution sandbox is feasible for a solo dev — but it's editable examples only, no exercises, accounts, or progress. TypeHero offers TypeScript type-challenge "tracks" + Advent of TypeScript badges (leaderboard still an open issue). CodinGame Clash of Code has timed 8-player modes (fastest/reverse/shortest) with leaderboards, but no Gleam and no curriculum. Only passive Brainscape/Quizlet flashcard decks exist for FP SRS.

GAP: no product combines structured concept-tree lessons + rated puzzles + timed drills + spaced repetition for any FP language, and nothing puzzle/SRS-shaped exists for Gleam at all (its ecosystem = tour, Exercism, CodeCrafters).

## Key facts

- Exercism distinguishes Concept Exercises (single-concept, one expected solution, form the syllabus tree) from Practice Exercises (open-ended, unlocked by prerequisite concepts); dependencies live in track config.json as 'prerequisites' and 'practices' arrays.
- Exercism Gleam track (June 2026): 122 exercises, 33 advertised concepts; config.json shows 36 concept slugs, 28 active concept exercises, 97 practice exercises with difficulty 1-9; ~7,700 students, 112 contributors, 109 mentors.
- Gleam track concept slugs include: basics, bools, ints, floats, modules, case-expressions, tuples, lists, strings, custom-types, labelled-fields, recursion, tail-call-optimisation, anonymous-functions, pipe-operator, generics, results, dicts, type-aliases, orders, constants, labelled-arguments, sets, options, let-assertions, bit-arrays, iterators, nil, io, opaque-types, queues, phantom-types, regular-expressions, external-functions, external-types, use-expressions.
- Exercism test-runner contract: per-track Docker image invoked with (exercise-slug, read-only input dir, writable output dir); must write results.json and exit 0 even on test failure; 20-second limit, 3GB memory; results.json versions 1/2/3 (v2 per-test detail required for concept exercises, v3 adds task_id); status pass|fail|error; per-test output capped at 500 chars, message at 65,535 chars.
- exercism/gleam-test-runner is written in Gleam itself (75%), generated from exercism/generic-test-runner, uses golden tests, licensed AGPL-3.0, latest release v1.8.0 (May 2024).
- Execute Program: lessons begin locked and unlock only after all dependency lessons are read AND successfully reviewed via spaced repetition; expanding intervals retire an item after the 4th successful review around day 64; wrong answers are not penalized unless the student 'gives up' (which shrinks the interval); daily new-lesson caps per course; reviews ~10 min/day initially; $39/mo or $235/yr; courses limited to TypeScript, JavaScript, SQL, Regex, Python — no FP languages.
- Codewars rating: kata difficulty 8kyu→1kyu, user ranks continue 1dan→8dan; rank-progress points per first completion: 2/3/8/21/55/149/404/1097 from 8kyu to 1kyu; kata ~2 levels above your rank gives ~+30% progress, same-level ~+5%; honor per completion 2/8/32/128 by tier; rank-up honor bonuses 20→12,800.
- Codewars supports Haskell, Elixir, and F# but NOT Gleam (open feature request: codewars/codewars.com discussion #3242) — so no rated-kata platform exists for Gleam.
- Rustlings model: tiny programs that fail to compile or fail tests, organized in ~23 topic directories; watch mode re-runs current exercise on file save, 'h' shows hints, user action required to advance; installed via 'cargo install rustlings && rustlings init'. Ziglings: 111 broken programs, same model, hosted on Codeberg. Elixir koans: 'mix meditate' autorunner, fill in ___ blanks.
- Brilliant.org pedagogy: problem-first lessons interleaving short explanations with embedded check questions and manipulable interactives, instant feedback with celebration animations (built with Rive) and encouragement on struggle, plus 'near-neighbor' practice problems matched to the learner's misconception.
- Gleam Language Tour (tour.gleam.run) compiles Gleam to JavaScript and executes it entirely in the browser as you type — demonstrating a zero-server execution sandbox for Gleam; but it has only editable examples, no exercises, accounts, or progress tracking.
- Haskell MOOC (haskell.mooc.fi, University of Helsinki): free 2-part FP course (basics; then IO/monads), but exercises are local SetN.hs files checked by a downloaded test harness — no browser interactivity, ratings, or SRS.
- CodinGame Clash of Code: timed up-to-8-player rounds in fastest/reverse/shortest modes with global leaderboards (score formula N^((N-C+1)/N)*2); TypeHero offers TypeScript type-challenge tracks and Advent of TypeScript badges, with a leaderboard only as an open GitHub issue (#1487).
- No existing product combines lessons + rated puzzles + timed drills + SRS for functional programming; the only FP 'SRS' artifacts found are passive Brainscape/Quizlet flashcard decks; Execute Program has the mechanics but no FP content; Exercism has FP content (incl. Gleam) but is explicitly non-competitive with no SRS, ratings, or timing.
- Gleam learning ecosystem today consists of: the language tour, the Exercism track, and CodeCrafters ('build Redis in Gleam') — leaving lessons-with-SRS, rated puzzles, and timed drills entirely unoccupied for Gleam.

## Recommendations

- Steal Exercism's two-axis content model directly: a concept tree (use the Gleam track's 36 concept slugs as your initial taxonomy) where each lesson session is a 'concept exercise' and each training drill is tagged with the concepts it practices — this gives you lichess-style puzzle themes for free.
- Run all code client-side by compiling Gleam to JavaScript in the browser, as tour.gleam.run proves is possible — this eliminates the Docker sandbox fleet (20s/3GB per submission) that Exercism needs, which is decisive for a single developer. Keep Exercism's results.json schema (status pass/fail/error + per-test name/message/test_code) as your internal test-result contract anyway, so a server-side runner can be added later for Erlang-target content.
- Copy Execute Program's three best mechanics verbatim: (1) lessons unlock only when prerequisite lessons are read AND recently reviewed; (2) forgiving grading — retries don't penalize, only explicit 'give up' shrinks the interval; (3) hard cap on new lessons per day to force spacing. Retire items after ~4 spaced successes rather than reviewing forever.
- For training sessions, make the atomic drill item a Rustlings-style 'fix this tiny broken Gleam program' — Gleam's famously friendly compiler errors make compile-error puzzles self-explanatory, they're fast to author in bulk, and they fit SRS review slots (30-90 seconds) far better than Exercism-sized exercises.
- Rate puzzles and players: use a Codewars-style kyu ladder for static difficulty labeling of drills, but Glicko-2 (lichess's system) for the rated-puzzle mode so puzzle difficulty calibrates itself from solve data; add a Clash-of-Code-style timed mode later, not at launch.
- Borrow Brilliant's lesson UX for the lesson sessions: short prose chunks each followed by an embedded check (predict the output, choose the type, fill one hole), instant feedback with light celebration, and a 'near-neighbor' variant offered on failure.
- Positioning: market explicitly as 'lichess/Chessable for functional programming' — the survey confirms Execute Program owns SRS-for-code but ignores FP, Codewars owns ratings but lacks Gleam and curriculum, Exercism owns Gleam content but rejects competition and scheduling; the intersection is empty.
- Before reusing any Exercism exercise text/tests, check the exercism/gleam repo license (content repos are typically MIT but verify); do not vendor code from gleam-test-runner (AGPL-3.0) into a closed-source service.

## Risks / limitations

- Exercise/concept counts and student numbers are point-in-time (June 2026) and grow continuously; Gleam config.json counts (28 concept / 97 practice exercises) were read from the main branch and will drift.
- Execute Program's interval specifics (4th success ≈ day 64, daily lesson caps) come from third-party reviews (mike.place 2020, Brett Chalupa) and Andy Matuschak's notes, not official docs; the algorithm may have changed since.
- Licensing must be verified before reusing Exercism Gleam exercise content: the gleam-test-runner is AGPL-3.0 (copyleft — avoid embedding its code in a proprietary service); the exercise-content repo license (exercism/gleam) was not independently confirmed in this pass.
- Brilliant.org pedagogy details partly derive from its own marketing and a design-agency case study (ustwo, Rive blog), so treat the 'ML misconception targeting' claims as directional, not verified.
- One primary source 404'd (an Andy Matuschak note on EP lesson unlocking); the unlock-requires-reviewed-prerequisites claim is corroborated by the note's title in search results and a sibling note that was fetched successfully.
- In-browser Gleam→JS execution (per the language tour) covers pure-stdlib code; exercises depending on Erlang-target behavior (BitArrays differences, OTP/actors) would still need server-side execution like Exercism's Docker runners.

## Sources

- https://exercism.org/docs/building/tracks/syllabus
- https://exercism.org/docs/building/tracks/concept-exercises
- https://exercism.org/tracks/gleam
- https://exercism.org/tracks/gleam/concepts
- https://raw.githubusercontent.com/exercism/gleam/main/config.json
- https://exercism.org/docs/building/tooling/test-runners
- https://exercism.org/docs/building/tooling/test-runners/interface
- https://github.com/exercism/gleam-test-runner
- https://exercism.org/docs/tracks/gleam/learning
- https://www.executeprogram.com/spaced-repetition
- https://mike.place/2020/executeprogram/
- https://code.brettchalupa.com/execute-program-review
- https://notes.andymatuschak.org/zX7RdiHGbHYnkFznUr9VZx7
- https://docs.codewars.com/gamification/ranks/
- https://docs.codewars.com/gamification/honor/
- https://docs.codewars.com/curation/references/kata-ranks/
- https://github.com/codewars/codewars.com/discussions/3242
- https://rustlings.rust-lang.org/
- https://rustlings.rust-lang.org/usage/
- https://github.com/rust-lang/rustlings
- https://codeberg.org/ziglings/exercises
- https://github.com/elixirkoans/elixir-koans
- https://brilliant.org/about/
- https://rive.app/blog/how-brilliant-org-motivates-learners-with-rive-animations
- https://ustwo.com/work/brilliant/
- https://haskell.mooc.fi/
- https://github.com/moocfi/haskell-mooc
- https://tour.gleam.run/
- https://typehero.dev/tracks
- https://github.com/typehero/typehero/issues/1487
- https://www.codingame.com/multiplayer/clashofcode/leaderboard
- https://forum.codingame.com/t/how-is-the-coding-rank-calculated/790
- https://www.brainscape.com/flashcards/haskell-practice-prompts-12026272/packs/21028535
