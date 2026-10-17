# Product requirement: Flexible number bonds and tailored explanations

Status: Full challenge layout retained, with question, circles, choices and actions above profile and rewards/progress cards. The reordered page passed 327 tests in 12 seconds with clean analysis. Its signed release is installed in place on Mani's iPhone 12 Pro; unlock the phone and open the app to test it. Updated October 10, 2026.

## Goal

Allow children to split the second operand into two or more parts using the existing make/reach-ten strategy, round-number chunks, or place value. Accept either order for the new methods, and make retry feedback and worked solutions teach the method the child attempted.

| Problem | Accepted decompositions of the second operand | Answer |
| --- | --- | --- |
| 4 + 14 | 6 + 8; 10 + 4; 4 + 10 | 18 |
| 29 − 15 | 9 + 6; 10 + 5; 5 + 10 | 14 |
| 100 + 24 | 10 + 14; 20 + 4, in either order | 124 |
| 100 + 120 | 100 + 20; 20 + 100 | 220 |
| 110 + 235 | 200 + 30 + 5, in any order | 345 |

The first operand stays unchanged. For the last example, the full expression is **110 + 200 + 30 + 5 = 345**. Replacing 110 with 100 would change the problem and produce 335.

## Confirmed scope

- Eligibility depends on the second operand, the number being split. Support any operand size handled by the app, including 100 and above; do not impose the previous 11–99 restriction.
- Both **10 + remainder** and **tens + ones** are accepted: 24 can be 10 + 14 or 20 + 4.
- Extend round-number chunks to hundreds and larger place values: 120 can be 100 + 20; 235 can be 200 + 30 + 5.
- The new methods accept either order, including reversed subtraction parts. Place-value decompositions with three or more parts also accept any order.
- Preserve existing accepted valid answers. Addition already accepts any correct two-part sum; extend that arithmetic rule to additional parts.
- Feedback follows the latest completed attempt on the current problem. Clearing the entry does not erase that context; a new problem does.
- Check filled answers automatically after 700 ms without further input. Children can select numbers from the existing grid or by tapping a part circle to open its picker.
- After a correct bond, immediately reveal the calculated result in the top equation and keep the existing worked steps. Do not add a separate final-answer input.
- Start with two part circles and automatically extend incomplete canonical place-value entries. Manual Add Part and Remove Part controls are outside the current scope.
- Keep the full challenge page and original branching diagram. Put the question, circles, choices, feedback and challenge actions first, with expanded profile/rewards/progress sections below. Preserve styles and gameplay; vertical page scrolling is allowed. The earlier compact no-scroll layout remains withdrawn.
- Strategy detection is deterministic from the selected parts and does not require an AI service.
- Extend Level 4 generation to first operands 100–999 and second operands up to 999. Addition must cross the next ten boundary; subtraction must satisfy the existing crossing rules and keep the second operand smaller than the first. Operands have up to three digits, while addition results may reach 1998. Levels 1–3 keep their existing ranges.
- For every generated normal or review challenge, exclude second operands exactly **10, 100 and 1000** for both addition and subtraction. First operands and other multiples such as 20 or 200 remain subject to the existing level and crossing rules. Current ranges cannot produce 1000; keep that value explicitly excluded if ranges expand. Generation fallbacks must satisfy this rule too.

## Functional requirements

### FR1 — Validate flexible decompositions

All parts must be nonnegative integers, at least two parts must be supplied, and their sum must equal the second operand B. Selecting a round number identifies a possible method; it never bypasses the sum check. For example, 15 = 10 + 4 and 235 = 200 + 30 + 4 are incorrect.

The generated-second-operand exclusions do not change these validation rules for an existing or supplied problem.

**Addition:** Accept any supplied decomposition that satisfies these arithmetic rules, including two-part splits, round chunks, place-value parts, and their permutations.

**Subtraction:** Preserve the existing valid two-part reach-the-lower-ten answers and special rules for first operands ending in zero. Also accept a correct decomposition containing one or more positive multiples of 10 and at most one non-round remainder, in any order. This includes:

- 15 = 10 + 5 or 5 + 10.
- 24 = 10 + 14 or 20 + 4, including their reversed orders.
- 120 = 100 + 20.
- 235 = 200 + 30 + 5, in any order.

The subtraction extension teaches round chunks; it does not make every arbitrary sum a new accepted subtraction strategy. For example, 29 − 15 with parts 7 + 8 still fails the strategy requirement. Existing valid zero-containing answers remain supported, but suggested decompositions should use positive parts whenever possible.

All accepted methods receive the same reward and progress treatment. Submit a completed answer once and award success once for that problem.

### FR2 — Start with two parts and automatically extend place-value entries

Show the second operand B in a centered top whole circle, with two descending connector lines to two editable answer circles below. Keep those two lower circles as the initial entry. Create additional connected circles only when an incomplete canonical place-value entry needs them; do not expose manual Add Part or Remove Part controls. Automatically check a complete selected list after **700 ms without further input**. Remove the Check Answer button.

Each visible part field must be filled before checking. Editing numbers, clearing entry, automatic field changes, or opening a picker cancels a pending check. Check the latest eligible entry after a fresh idle period; do not validate while a picker is open or after the widget is disposed, a problem is replaced, or a challenge is restarted.

If the filled parts are a proper subset of the second operand's canonical place-value expansion, treat the entry as incomplete. After the idle period, add an empty circle for each missing place-value part without counting a failure or filling in the answer. For 235 with 200 + 30, add a third empty circle so the child can choose 5. Preserve the selected parts and recognize them in either order. The validator still supports other valid multi-part decompositions when supplied, but the UI provides no manual controls to create fields for arbitrary multi-part splits.

Clearing the entry restores two empty answer circles, including after automatic place-value extension, so the child can choose a different two-part split. Keep the latest completed attempt's feedback as required by FR5.

Tapping any editable part circle opens a localized number picker for that circle, using the same available number choices as the grid. The existing grid remains visible and usable outside the modal. Picker selection updates the tapped circle through the same entry and automatic-checking rules as grid selection. Canceling the picker does not change the selected numbers or spend another attempt on an already checked entry. Ignore stale picker results when the current problem, retry, targeted field, or widget lifetime has changed.

The number selection grid must include the values needed for the original strategy and the new strategies for the current problem. Examples include 10 and 14 for B = 24; 100 and 20 for B = 120; and 200, 30, and 5 for B = 235. Required suggestions must survive sorting and distractor generation. A fixed 14-option truncation must not hide them.

The same value can be chosen more than once; 20 = 10 + 10 must work. The layout must remain usable with larger values and more than two fields.

The active challenge page keeps the previous full layout and styles. Its section order is: large question, branching whole-to-parts diagram, number choices, feedback and challenge actions, then the child's name/profile and expanded rewards/progress cards. The challenge interaction must precede these supporting cards. Allow vertical page scrolling to reach every section, worked step and action. Keep the whole circle above the connected lower answer circles; automatically created place-value fields remain accessible. Use at least 44-pixel targets for part circles and number choices. Keep small-screen and landscape content usable without overflow, including 390 × 844 and 320 × 568 phone viewports. The localized circle picker remains available. The earlier compact no-scroll requirement remains withdrawn.

The grid and circle pickers offer a curated set of teaching suggestions rather than every mathematically accepted partition. Validation may accept other correct decompositions, such as 235 = 110 + 125, whose values are not offered in the current choices. This scope guarantees access to the specified original, round-chunk, and place-value examples; unrestricted numeric entry or enumeration of every accepted split is outside this change.

### FR3 — Detect the attempted method

Use one shared strategy decision for validation feedback, retry hints, diagrams, and final worked solutions. Infer the method from the completed selected list even when its total is incorrect.

- Keep existing make/reach-ten teaching when a two-part attempt starts with the appropriate existing boundary part. For overlapping valid answers such as 29 − 19 with 9 + 10, preserve the existing reach-the-lower-ten explanation.
- If the child attempts round-number chunks, teach the corresponding corrected round split. For example, 4 + 14 with 10 + 3 should explain 10 + 4, and 100 + 24 with 20 + 3 should explain 20 + 4.
- If the child attempts three or more place-value parts, teach the corrected canonical place-value decomposition. For example, 110 + 235 with 200 + 30 + 4 should explain 200 + 30 + 5.
- Recognize the new method in any selected order, including a round chunk in a later field. For an incorrect two-part round split, preserve the chosen round chunk's position where a valid correction exists. A reversed ten split should receive a valid explanation rather than an instruction requiring ten first.
- For an ambiguous or unrelated attempt, fall back to the existing teaching method with a correct decomposition.

Use corrected parts when an attempt is wrong. Use the child's accepted parts and order when explaining a successful attempt. Every worked step must preserve the original first operand and calculate the correct intermediate and final values.

### FR4 — Tailor retry feedback and final worked solutions

Keep helpful retry feedback after unsuccessful submissions. Show a worked solution after a correct answer using the child's actual selected parts and order, and after the existing three-failure limit using corrected parts for the attempted method. All feedback surfaces must follow the same detected method.

The top equation starts with `?`. Immediately after a correct bond is checked, replace it with the calculated result without waiting for persistence to succeed. Keep that result visible through a save failure, a saving retry, or recovery of a correct pending completion. Preserve the existing worked steps and do not require a separate final-answer entry. Starting a new problem or a new learning attempt restores `?`; retrying the save keeps the answer visible. A failed terminal attempt or a history explanation may show worked steps while the top equation remains `?` until the child completes a correct bond.

| Failed attempt | Corrected teaching |
| --- | --- |
| 4 + 14, parts 10 + 3 | 14 = 10 + 4; 4 + 10 = 14; 14 + 4 = 18. |
| 4 + 14, parts 6 + 7 | Keep make-ten teaching: 14 = 6 + 8; 4 + 6 = 10; 10 + 8 = 18. |
| 29 − 15, parts 10 + 4 | 15 = 10 + 5; 29 − 10 = 19; 19 − 5 = 14. |
| 29 − 15, parts 9 + 5 | Keep reach-ten teaching: 15 = 9 + 6; 29 − 9 = 20; 20 − 6 = 14. |
| 100 + 24, parts 20 + 3 | 24 = 20 + 4; 100 + 20 = 120; 120 + 4 = 124. |
| 110 + 235, parts 200 + 30 + 4 | 235 = 200 + 30 + 5; 110 + 200 = 310; 310 + 30 = 340; 340 + 5 = 345. |

Describe round splits as adding/subtracting round chunks or using place value. Adding/subtracting ten does not necessarily reach a multiple of ten; for example, 29 − 10 = 19.

Any hint, diagram, or proposed solution shown for the same submitted attempt must agree with its selected method. New child-facing text must use the app's English, Spanish, and French translation mechanism.

### FR5 — Keep validation, feedback, and state consistent

Represent the selected parts, correctness, detected method, corrected parts, and worked steps together so the validator and UI cannot independently produce contradictory explanations. Retain a compatible two-part validation entry point for existing callers while supporting a list of parts.

Store the latest completed attempt before clearing fields. Refreshing or clearing fields after failed submissions must not switch an existing round-split solution back to the original method or unlock a completed problem. A later completed attempt replaces the context; starting a new problem or explicitly retrying the challenge resets it.

Keep the three-failure limit and current success/failure flow. Count each stable checked entry once. Choosing the same value or reopening/canceling a picker must not recheck an already counted entry; clearing and re-entering the same wrong split establishes a new retry. Cancel pending checks when editing, clearing, changing part count, opening a picker, changing the problem, restarting a challenge, or disposing the widget. Prevent repeat checking from duplicating rewards or completion callbacks.

### FR6 — Preserve progression and learning records

Persist a normal challenge level per child and evaluate each newly completed normal challenge once. Advance with at least 80% accuracy over five outcomes at the current level, stay at 60–79%, and move down below 60%, within Levels 1–4. Require five fresh current-level outcomes after changing level; easier reviews do not change the normal level. Review after two consecutive incorrect outcomes or after every four recorded outcomes when a suitable past mistake exists. Preserve the mistaken operation, respect the saved operation preference, and make the review easier when possible.

Record measured elapsed seconds, actual checked-attempt count, hint use, and selected method for each terminal event. Repeated callbacks for the same event must not duplicate history or rewards; a failed challenge followed by a successful explicit retry remains two outcomes. Keep cumulative totals separate from the most recent 100 history entries per child. Persist earned badges, stickers, and rewarded-event receipts together so they survive reopening and the recent reward list's limit.

Generate learning analysis every 20 unique terminal events per child, using up to 100 recent logs from the last seven days. The analysis cadence must continue after that log limit is reached. Insight-generation errors must not undo or duplicate primary challenge records. Generated insight-card UI, a multiple-profile chooser, dedicated practice mode, and favorite-number weighting remain planned features; current profile performance metrics and favorite-number editing remain available.

## Acceptance criteria

| Case | Expected behavior |
| --- | --- |
| Normal or review generation draws a second operand of 10, 100 or 1000 | Return a different eligible second operand for either operation; generation fallbacks must also respect the exclusion. |
| A first operand is 10 or 100, or a second operand is another multiple such as 20 or 200 | Apply the existing level, crossing and subtraction-validity rules without an additional exclusion. |
| 4 + 14, parts 6 + 8 | Accepted under existing rules. |
| 4 + 14, parts 10 + 4 or 4 + 10 | Accepted; explanation follows the selected round split. |
| 29 − 15, parts 9 + 6 | Accepted under existing rules. |
| 29 − 15, parts 10 + 5 or 5 + 10 | Accepted with the same reward as the existing method. |
| 29 − 15, parts 7 + 8 | Rejected: correct sum, but not an existing or new subtraction strategy. |
| 4 + 14, parts 10 + 3 | Rejected; retry and final solution teach corrected 10 + 4. |
| 29 − 15, parts 9 + 5 | Rejected; retry and final solution teach corrected 9 + 6. |
| 29 − 19, parts 9 + 10 | Accepted using existing rules; retain reach-the-lower-ten teaching. |
| 100 + 14, parts 10 + 4 | Accepted; result is 114. |
| 100 + 24, parts 10 + 14 or 20 + 4, in either order | Both accepted; required values remain selectable. |
| 100 + 120, parts 100 + 20 or 20 + 100 | Accepted; result is 220. |
| 110 + 235, parts 200 + 30 + 5, in any order | Accepted; result is 345 and the first operand remains 110. |
| 345 − 235, parts 200 + 30 + 5, in any order | Accepted under the new subtraction rule; result is 110. |
| B = 20, parts 10 + 10 | Same value can be selected twice and the answer is accepted. |
| Negative part, fewer than two parts, blank field, or incorrect total | Not accepted; blank or incomplete entry does not consume an attempt. |
| Child fills a correct answer | Automatic success after 700 ms of idle input; immediately reveal the calculated result in the top equation and retain the existing worked steps, with no final-answer input. |
| Saving a correct completion fails or resumes from its pending journal | Keep the top equation's result visible while saving is retried or recovered. |
| Child starts a new problem or an explicit learning retry | Restore `?` in the top equation; retrying persistence alone does not reset it. |
| A terminal failure or history review displays a worked explanation | Keep `?` in the top equation until a correct bond is completed. |
| Child edits or clears entry within the 700 ms delay | Pending check is canceled; only the current eligible entry can be checked. |
| 235 with selected parts 200 + 30, or 30 + 200 | After idle, add an empty third circle without a failed attempt; selecting 5 completes the answer automatically. |
| Child clears an automatically extended entry | Restore two empty circles while retaining the latest completed attempt's feedback. |
| A noncanonical decomposition needs three or more parts | Validation still accepts supported parts when supplied; no manual UI controls create or remove fields for this method. |
| Child taps a part circle | A localized number picker opens for that circle with the same choices as the grid. |
| Child opens/cancels a picker or chooses the same value after an incorrect check | No additional failure is counted for the unchanged entry. |
| Child clears and re-enters the same wrong split | Counts as a new retry after the idle delay. |
| Problem changes or challenge restarts while a picker or pending timer is active | Old timer and modal results cannot modify or complete the new entry. |
| Child changes from a round attempt to an existing-method attempt | Feedback follows the latest completed attempt. |
| Child clears fields after the third failure | The shown solution retains the last submitted method and cannot be submitted again. |
| Child starts a new problem or explicitly retries the challenge | Previous method and attempt context reset. |
| Child submits a successful answer repeatedly | Reward and success tracking occur once. |
| Full page exceeds the visible space | All sections, number choices and actions remain reachable through vertical scrolling; touch targets remain at least 44 pixels. |
| Automatic place-value extension creates more parts | Additional editable circles remain connected below the whole and accessible when they exceed the available width. |
| Child opens the full challenge page | The question, branching circles, number choices and challenge actions appear before the name/profile and rewards/progress cards; existing styles and gameplay remain. |
| Child sees a retry or worked explanation | Show method-aware feedback in the full challenge flow; all content remains reachable through scrolling. |
| Correct answer uses a reversed or multi-part decomposition | The worked solution uses the child's selected parts and order, with correct intermediate values. |
| Level 4 generated problems | Second operands can exceed 99; operands stay within the stated three-digit ranges and existing crossing rules. Addition results up to 1998 are supported. |

Verification must cover validator regressions, arbitrary supported operand sizes, permutations, incorrect totals, negative inputs, repeated parts, required option availability, picker selection/cancellation, stale modal results, automatic-check timing/cancellation, automatic incomplete place-value fields, absence of manual Add Part/Remove Part controls, attempt counting, and rendered retry/final feedback across a sequence of checks.

## Implementation work and verification

| Area | Required work |
| --- | --- |
| `lib/services/answer_validator.dart` | Add list-based validation and shared strategy/solution data; preserve valid legacy two-part answers; remove the 11–99 and ten-first limits. |
| `lib/widgets/interactive_number_bond_widget.dart` — entry | Keep the top whole circle and descending branches to two initial answer circles; extend incomplete canonical place-value entries automatically, check after 700 ms, and provide a picker for each editable circle without manual part-count controls. |
| Same widget — number choices | Preserve original, round-chunk, and place-value suggestions before adding distractors; remove truncation that hides required parts. |
| Same widget — feedback and state | Share attempted-method routing across retry/final solutions; retain the latest completed attempt through clear/refresh; cancel stale checks/modal results; prevent duplicate checking effects. |
| `lib/screens/adaptive_challenge_screen.dart` and `ChallengeWorkspace` | Keep the full scrolling page and place the question/diagram/choices/actions above profile/rewards/progress cards; preserve three-failure/retry flow and record actual time, attempts, hint use and method with a distinct terminal event identity. |
| Adaptive progression and persistence services | Persist each child's normal level, enforce the documented five-outcome accuracy thresholds, preserve levels through reviews, and retain unique terminal events and earned rewards across reopening. |
| Learning insights | Log terminal events with their measured metrics and analyze every 20 unique events, independently of capped recent history. |
| Level 4 problem generation and labels | Generate second operands up to 999 with valid crossing; describe three-digit operands rather than implying answers are limited to 1000. |
| `lib/services/language_service.dart` | Localize new child-facing controls and explanations in English, Spanish, and French. |
| Validator and widget tests | Verify flexible multi-part validation, automatic canonical place-value extension, absence of manual part-count controls, method consistency, reset behavior, and selectable large values. |
| `REQUIREMENTS.md` | Replace the outdated universal first-circle ordering rule with the agreed flexible decomposition rules. |

The reordered full-layout version passed the full Flutter suite: **327 tests in 12 seconds**. Coverage includes 197,604 ordered round-split scenarios and 9,720 place-value permutations, plus arithmetic, automatic-check timing/cancellation, per-entry deduplication, incomplete canonical place-value fields, stale picker dismissal, localization, variable parts, and worked solutions through four digits. The restored full page adds 27 branching-layout cases covering whole-above-parts geometry, connector endpoints, extra parts, scrolling, pickers, automatic checking, and localized portrait/landscape flows; 16 full reward-card cases check narrow cards, larger text and localization. Earlier compact component checks do not describe the active full-page layout. Generator regressions prevent invalid random bounds, unsolvable stretch problems, incompatible subtraction hints, and zero crossing remainders.

The fresh review adds 45 focused progression/recording/persistence cases: reachable and persisted Levels 1–4, five-outcome accuracy thresholds, review isolation and operation preferences, actual terminal metrics, duplicate delivery, per-child history/reset, insight cadence, rejected-write recovery, unreadable-history protection, earned reward persistence, concurrent awards, and reward receipts beyond recent-history limits. App navigation, profile editing/reset/failure recovery, repository identity, and birth-year lifecycle tests also pass.

Full-project `flutter analyze` reported **no issues found**, and `git diff --check` passed. Formatter verification checked 74 files with zero changes. Twelve previews across English 390 × 844, French 320 × 568 and landscape 568 × 320 were rendered and visually checked, including the challenge-first order and lower supporting cards. The fresh question-first signed iOS release built successfully in 18.2 seconds (17.4 MB) and was installed in place on Mani's iPhone 12 Pro. Automatic launch was blocked because the device is locked; unlock the phone and open the app for hands-on testing. Product source is unchanged after the build. See [the scenario test report](NUMBER_BOND_TEST_REPORT.md) for commands, results, and remaining limits.

Large second operands expose more selectable values through the existing grid; vertical scrolling keeps the full page accessible. Adaptive progression now reaches Level 4 through the documented learning rules. A multiple-profile chooser, dedicated practice mode, favorite-number weighting, and generated insight-card UI remain planned.
