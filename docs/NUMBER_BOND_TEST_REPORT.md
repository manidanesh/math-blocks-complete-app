# Number-bond formula and scenario verification

Verified October 10, 2026: the reordered full page passed **327 tests in 12 seconds**, and full-project `flutter analyze` reported **no issues**. Verification covers the agreed number-bond examples, accepted orders, worked arithmetic, automatic checking, challenge layouts, adaptive progression, profiles, rewards, and persisted learning records. The question, circles, choices and actions precede the profile and rewards/progress cards. The fresh signed release was built and installed in place on Mani's iPhone 12 Pro. Unlock the phone and open the app to test it.

## Formula checked

The first operand A is preserved. The parts must be nonnegative integers, contain at least two entries, and sum to the second operand B. Addition applies each part to A in order; subtraction subtracts each part in order. The final value must equal A + B or A − B respectively.

Addition retains its general correct-sum rule. Subtraction retains the original ordered reach-ten and zero-ending rules, and also accepts one or more positive multiples of ten with at most one non-round remainder, in any order.

Current generation requirements exclude second operands exactly 10, 100 or 1000 from normal and review challenges for both operations, including fallback paths. First operands and other multiples such as 20 or 200 retain their existing eligibility rules. Current operands are capped at 999, but 1000 remains explicitly excluded for future ranges. This filter does not change validator acceptance for existing or supplied problems.

| Problem | Checked parts | Result |
| --- | --- | --- |
| 4 + 14 | 6 + 8; 10 + 4; 4 + 10 | Accepted; 18 |
| 29 − 15 | 9 + 6; 10 + 5; 5 + 10 | Accepted; 14 |
| 100 + 14 | 10 + 4; 4 + 10 | Accepted; 114 |
| 100 + 24 | 10 + 14; 14 + 10; 20 + 4; 4 + 20 | Accepted; 124 |
| 100 + 120 | 100 + 20; 20 + 100 | Accepted; 220 |
| 110 + 235 | Every order of 200 + 30 + 5 | Accepted; 345 |
| 345 − 235 | Every order of 200 + 30 + 5 | Accepted; 110 |
| 100 + 24 | 10 + 10 + 4 | Accepted; repeated chunks work |
| 129 − 9 | 9 + 0 | Accepted; zero is selectable; result 120 |
| 400 − 205 | 200 + 5; 5 + 200 | Accepted; empty tens place omitted |
| 2345 − 1234 | Reordered 1000 + 200 + 30 + 4 | Accepted; result 1111 |
| 110 + 235 | 100 + 200 + 30 + 5 | Rejected; parts sum to 335 |
| 29 − 15 | 7 + 8; 6 + 9 | Rejected under the retained subtraction strategy rules |
| Any supported problem | Wrong total, negative part, fewer than two entries | Rejected |

The table records validator acceptance, including multi-part decompositions that the UI does not provide manual controls to enter.

Worked-solution tests independently parse and evaluate every displayed equation. Incorrect-attempt corrections are checked for both arithmetic and acceptance by the validator. UI tests check retry hints, final explanations, part order, clearing, parent retry, and one completion callback per problem.

## Automatic checking and circle picker

Filled answers are checked after 700 ms without further input. The Check Answer button is removed. Tapping a part circle opens a localized picker with the same curated values as the existing grid; the grid remains available.

The top equation starts with `?` and immediately reveals the calculated result after a correct bond, alongside the existing worked steps. There is no separate final-answer input. The result remains visible through saving errors, saving retries and recovery of a correct pending completion. A new problem or learning retry restores `?`. Showing a terminal failure or history explanation alone does not reveal the top answer; a correct bond is still required.

The entry widget tests cover strategy, arithmetic, picker, branching-layout, and automatic-check timing/state cases. They verify:

- No check before the idle delay or while a visible part is empty.
- Cancellation on number edits, clear, automatic field changes, picker opening, problem changes, retry, and widget disposal.
- One failed attempt per checked entry, with no extra failure from selecting the same value or reopening/canceling its picker.
- Clearing and re-entering a wrong answer creates a new retry; three failures retain the latest method's worked solution.
- One success/completion callback per problem, including after waiting, clearing, or tapping completed circles.
- An incomplete canonical place-value entry such as 235 = 200 + 30 gains an empty circle without failure; the child then selects 5.
- Picker selection updates the tapped circle, repeated values remain selectable, and stale picker results cannot change a replacement problem.
- Stale picker dismissal, retained feedback during automatic field extension, English/Spanish/French controls, and narrow-screen layout.

The current UI starts with two part circles. Automatic canonical place-value extension creates only the missing empty fields and does not fill in their numbers. Clearing restores two empty circles so the child can choose another two-part split. Manual Add Part and Remove Part controls are outside the current scope. Other valid multi-part decompositions remain supported by the validator when supplied; the UI does not provide manual field controls for arbitrary multi-part splits.

## Challenge layout and learning flow

The latest user request keeps the full challenge page and styles, with the large question, original top whole circle branching down to lower answer circles, number choices, feedback and challenge actions first. The child's name/profile and expanded rewards/progress cards follow below the challenge interaction. Vertical page scrolling is allowed so every section remains reachable. The earlier compact no-scroll requirement remains withdrawn. Number/circle controls retain targets of at least 44 pixels, and automatic checking, localized circle pickers and automatic canonical place-value extension remain available. The 27 branching-layout tests check the top whole circle, lower part geometry, connector endpoints, multi-part scrolling, localized picker/automatic-check behavior and full-page portrait/landscape flows. The 16 full reward-card cases verify narrow cards, larger text and localization. Full-page tests verify the interactions, and refreshed previews confirm the latest section order. Historical compact-component viewport tests do not describe the active full-page layout.

The active adaptive path now reaches Levels 1–4 and saves the normal level across reopening. It evaluates five fresh normal outcomes at the current level: at least 80% accuracy advances, 60–79% stays, and below 60% moves down. Repeated loading cannot apply the same progression decision twice. Easier reviews preserve the normal level, retain the mistaken operation, and respect the saved operation preference.

Records retain measured elapsed seconds, actual attempt counts, hint use, and selected method. Distinct terminal event identities preserve a successful retry after failure while deduplicating repeated callbacks. Each child keeps up to 100 recent attempts independently; cumulative profile and reward totals remain separate from that history limit. Insight analysis runs every 20 unique outcomes, including after its recent-log cap is reached. Generated insight-card UI remains planned.

## Defects corrected

| Defect | Resulting behavior |
| --- | --- |
| Level 2 addition could call Random.nextInt with an invalid bound when A ended in 0 or 1 | Regenerate A until a single-digit B can cross the next ten with a positive remainder |
| Level 1 stretch subtraction included 19 − 7, 19 − 8, and 18 − 7, which have no accepted split under the existing rules | Retain the nine solvable stretch examples |
| Standard Level 1 subtraction could teach an even split that the validator rejected, such as 15 − 8 using 4 + 4 | Teach the valid boundary split, 5 + 3, with correct intermediate arithmetic |
| Level 3 addition could produce 10 + 10 with a zero crossing remainder | Choose B strictly greater than the amount needed to reach the next ten |
| The live adaptive API restarted at Level 1, with unreachable weighted level-up criteria and a hardcoded 30-second solve time | Persist normal levels, apply the documented five-outcome accuracy thresholds, and record measured time |
| Easier reviews could alter progression or change an addition mistake into subtraction | Keep review outcomes out of normal progression and preserve the mistaken operation |
| Attempts on the same equation within one minute were discarded, including successful retries | Deduplicate by terminal event identity and retain distinct outcomes |
| One child's attempt history could evict another child's entries at the global 100-entry limit | Retain 100 recent outcomes per child |
| Earned badges/stickers were appended after saving, and duplicate reward protection depended on the recent list | Persist rewards and event receipts together, retain award identity beyond the 20-reward display limit, and serialize awards/resets |
| Insight analysis was not called by the live path, then would repeat every event after reaching 100 logs | Log terminal events with their actual metrics and maintain a per-child 20-event analysis cadence |
| Failed preference writes left phantom cached history, and unreadable attempt JSON could be overwritten | Reload disk-backed state on failure, recover rejected writes on retry, and preserve unreadable saved bytes |
| Profile totals could shrink when reconstructed from capped history, or resetting a child could clear others | Preserve cumulative totals, isolate resets, and restore previous data when a reset fails |
| Full-project analysis contained a profile type-bound error and stale duplicate helpers | Repair the repository model contract and remove or update obsolete code; full analysis is clean |

Scripted random inputs make the first, third, and fourth regressions deterministic. A deterministic test enumerates every remaining Level 1 stretch combination.

## Verification evidence

The checked-in tests include:

- 197,604 round two-part splits for B = 11–999, both orders and both operations.
- 9,720 permutations of nonzero place-value expansions through three digits, with independent worked-step arithmetic checks.
- Incorrect totals, negative parts, corrected examples, and all suggested decompositions across those operand sizes.
- Repeated chunks, zero remainders, legacy single-digit crossing cases, and selected four-digit scenarios.
- Entry widget and challenge tests for strategy/arithmetic/picker behavior, idle checking, variable parts, localized inline feedback, and lifecycle cancellation.
- 27 branching-layout cases verify connector geometry, two initial answer circles, extra parts, circle pickers, automatic checking, and scrolling to the final choice and challenge actions; 16 full reward-card cases verify narrow layouts, larger text and English/Spanish/French. Earlier compact layout checks cover the optional component.
- Generator properties including 4,000 seeded problems across all four levels and both operations, plus the diagnostic that checks the actual central generator against the shared validator.
- 45 focused progression/recording/persistence cases: 14 adaptive, 7 attempt-recording, 6 insights, 8 storage-recovery, and 10 reward tests.
- Real plugin-channel storage tests reject writes or throw without changing saved data, then verify retry recovery and unreadable-history preservation.
- The full suite also includes app navigation, live attempt metrics, profile editing/reset/failure recovery, repository identity, birth-year migration, resume, and calendar-year refresh tests.

Additional independent seeded audits checked 8,000 and 80,000 generated problems. They found no remaining arithmetic errors, exceptions, unsolvable generated problems, rejected suggested splits, or rejected corrections. The larger audit independently evaluated 48,053 numeric hint chains.

Commands run:

```sh
flutter test --reporter expanded
flutter analyze
git diff --check
```

The reordered-page full test command exited successfully with **327 tests passed in 12 seconds**. Full-project analysis reported **no issues found**, and whitespace validation passed. Current logs are `/private/tmp/number_bond_question_first_tests.log` and `/private/tmp/number_bond_question_first_analysis.log`. Formatter verification checked 74 files with zero changes.

The fresh question-first signed iOS release built successfully in 18.2 seconds (17.4 MB) and was installed in place on Mani's iPhone 12 Pro as `com.numberbondmath.app`. Automatic launch was blocked by the locked device (`CoreDevice 10002` / `FBS Locked`); unlock the phone and open the app to test the reordered page. Product source is unchanged after the build. Logs are `/private/tmp/number_bond_question_first_iphone_build.log`, `/private/tmp/number_bond_question_first_iphone_install.log` and `/private/tmp/number_bond_question_first_iphone_launch.log`.

Twelve reordered full-page previews using production AppBar typography were rendered and visually checked: English at 390 × 844, French at 320 × 568, and landscape at 568 × 320, each captured at the top, question, branching diagram and profile. The temporary preview harness passed its separate check (1/1). Preview paths follow `/private/tmp/number_bond_question_first_{en_390,fr_320,landscape_568}_{top,question,bond,profile}.png`. They confirm the question, circles, choices and actions precede the lower profile/rewards/progress cards, while retaining the full page, branching diagram and vertical scrolling. Hands-on device testing remains with the user.


## Limits

The number grid and circle picker provide the same curated teaching choices. A mathematically accepted split such as 235 = 110 + 125 may use values that these controls do not offer; all specified teaching examples remain selectable. Entry starts with two fields and gains fields automatically only for an incomplete canonical place-value split; there are no manual part-count controls for arbitrary multi-part methods.

Small non-crossing subtractions such as 29 − 3 do not have an accepted split under the retained strategy rules. The corrected generator does not produce these problems. Arbitrary externally supplied problems of that kind need a separate basic-subtraction policy before the widget can support them.

A multiple-profile chooser, dedicated practice mode, favorite-number weighting, and generated insight-card UI remain planned. The current interface uses one active profile; its favorite numbers are saved and editable. Automated tests verify arithmetic, state transitions, persistence, and layout; hands-on device testing remains with the user.
