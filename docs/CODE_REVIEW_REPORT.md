# Code and usability review

Reviewed October 10, 2026 against the agreed number-bond, birth-year, answer-entry and challenge-layout requirements.

## October 14 automatic equation answer

A correct bond now immediately replaces `?` with the calculated result in the top equation, while preserving the existing worked steps. The answer remains visible while saving, after a save error, and when recovering a correct pending completion, including older journal entries without attempt details. New problems and learning retries restore `?`; failure/history explanations alone do not mark the top equation solved. No separate final-answer input was added.

The full suite passes **421 tests in 19 seconds**, including pre-save reveal, save recovery, retry/new-problem resets, addition/subtraction and multi-part answers, and narrow/landscape layouts. Analysis, formatting and whitespace checks pass. The updated debug build succeeds and is installed and launched in the iPhone 17 simulator. Logs: `/private/tmp/numberbond-auto-answer-tests.log`, `/private/tmp/numberbond-auto-answer-analysis.log`, and `/private/tmp/numberbond-auto-answer-build.log`.

## October 13 challenge operand exclusion

Generated addition and subtraction challenges now exclude second operands exactly **10, 100 and 1000**. A shared bounded chooser selects directly from allowed values across all live levels and generated reviews. The compatibility generator applies the same rule to normal choices, complementary operands and its capped fallback. First operands and other multiples retain their existing eligibility rules; answer validation and saved history are unchanged.

Added 21 regression cases, including exclusion boundaries and reachable nearby values, 4,000 seeded generated problems, all normal/review levels and operations, and the compatibility fallback. The full suite passes **419 tests in 20 seconds**; analysis, formatting and whitespace checks pass. The updated debug build is installed and launched in the iPhone 17 simulator. Logs: `/private/tmp/numberbond-exclude-round-operands-tests.log`, `/private/tmp/numberbond-exclude-round-operands-analysis.log`, and `/private/tmp/numberbond-exclude-round-operands-build.log`.

## October 13 manual part control correction

Removed the unrequested Add Part and Remove Part controls from both full and compact answer entry, along with the related English, Spanish and French instructions. Entry starts with two circles; existing automatic extension for incomplete canonical place-value answers remains. Clear restores two empty circles so another method can be selected.

The complete suite passes **398 tests in 18 seconds**. Analysis, formatting and whitespace checks pass. The updated debug simulator build succeeds and is installed and launched on the iPhone 17 simulator. Logs: `/private/tmp/numberbond-remove-manual-parts-tests.log`, `/private/tmp/numberbond-remove-manual-parts-analysis.log`, and `/private/tmp/numberbond-remove-manual-parts-build.log`.

## Home layout and age selection follow-up

Home buttons size to their text with a 48-pixel minimum touch target. Tests now use the production app theme and router in English, Spanish and French, including narrow portrait, landscape and enlarged text. The profile's favorites heading and Edit control also wrap on narrow screens with large French text.

New profile creation displays ages **4–9** directly and saves the corresponding calendar year for annual age updates. The reusable age controls offer the same range and wrap on narrow screens. Existing profiles keep their saved age/year and retain the broader birth-year editing range as they grow.

The complete suite passes **398 tests**; analyzer, formatting and whitespace checks pass. The corrected iOS simulator build succeeds. Logs: `/private/tmp/numberbond-home-age-full-tests.log`, `/private/tmp/numberbond-home-age-analysis.log`, and `/private/tmp/numberbond-home-age-simulator-build.log`.

## October 12 recheck and cleanup

The subsequent recheck corrected queued preference edits that could overwrite another edit or restore a replaced child, stale challenge display after a failed load, and missed initial rewards while a profile was loading. Storage repositories now restore their cache after both rejected and throwing writes.

Unfinished challenge completions now have a local per-child journal. Reopening resumes the same event, timing, hint use, attempt count and selected parts. Pending recovery disables fresh answer entry. Completion and progress-reset operations are coordinated so a reset clears active results and cancels older queued deliveries without replaying them afterward.

Removed unused `flutter_tts` and `cupertino_icons` dependencies and regenerated plugin registration and both CocoaPods lockfiles. Made the existing iOS 13 deployment target explicit in the Podfile. Cleaned import order, stale comments, redundant loading cleanup, and unnecessary asynchronous helpers. The standalone subtraction diagnostic now checks the production generator and validator.

Final verification completed after tool access returned:

- **385 tests pass in 16 seconds**, including navigation, exact restored decomposition explanations, rejected/throwing save recovery, concurrent reentry, and completion/reset coordination.
- `flutter analyze --no-pub` reports **no issues**.
- Formatting of **80 Dart files** requires no changes; `git diff --check` passes.
- The deterministic production diagnostic validates **400 subtraction problems** across all four levels.
- The unsigned iOS release build succeeds: **17.3 MB**, with the Xcode build completing in **30 seconds**. The app's frameworks contain Flutter and shared preferences; the removed speech plugin is absent.
- Dependency resolution and iOS/macOS CocoaPods regeneration completed.

The new widget-test startup fixture initializes the profile inside Flutter's test scheduler. This corrected the initial recovery-test timeouts without changing production behavior. The 355-test result below is the earlier verification before this additional cleanup and recovery work.

```sh
flutter test --no-pub --reporter expanded
flutter analyze --no-pub
flutter build ios --release --no-codesign --no-pub
```

Current logs are `/private/tmp/numberbond-cleanup-final-tests.log`, `/private/tmp/numberbond-cleanup-final-analysis.log`, and `/private/tmp/numberbond-cleanup-final-ios-build.log`. This build has not been installed or smoke-tested on an iPhone; the older deployment record below refers to the October 10 build.

## October 12 follow-up fixes

The five issues from the latest review are corrected:

- Failed completion saves retain the submitted answer, timing and event identity. Retry saving finishes that result without solving again; pending saves disable Next. Learning retries after a saved terminal failure still create a separate outcome.
- Profile mutations are serialized, and outcome receipts save with lifetime totals. Concurrent completions and repeated save delivery preserve accurate totals; queued preference edits retain newly saved progress.
- Reopened mistakes retain their original difficulty, including their saved review results at Levels 3 and 4.
- Profile language and favorites initialize independently of reward reads, so unreadable rewards cannot empty the preference editor.
- Rejected or throwing insight log/count writes restore the saved snapshots before retry, preserving the twentieth-outcome analysis cadence and other children's records.

Added 28 regression cases. The full suite passes **355 tests in 14 seconds**. Verification uses `flutter test --no-pub --reporter expanded`, `flutter analyze --no-pub`, and `git diff --check`.

## Corrections

- Difficulty now persists per child and can advance through levels 1–4. Five fresh normal outcomes at the current level determine the next level: at least 80% advances, 60–79% maintains, and below 60% lowers. Reviews do not advance the normal level.
- Actual foreground time, checked-entry count, hint use and chosen method replace fixed or default attempt values. Each retry receives its own event identity; duplicate delivery preserves a single result.
- Past-mistake selection opens the chosen equation and its worked explanation. Retry resets the circles, completion lock and timer.
- Lifetime profile totals no longer shrink when recent history reaches its retention cap. Recent histories retain up to 100 outcomes per child.
- Stars, badges and stickers save together; older separately saved badge and sticker lists are recovered. Reward receipts prevent duplicate awards, concurrent writes are serialized, and a completed reward level shows full progress.
- Learning analytics receives actual outcomes and analyzes every 20 unique recorded events; its cadence remains correct after history retention caps.
- Failed profile edits retain the usable profile and allow retry. Failed resets report failure and restore saved progress. Profile loading errors present recovery without replacing stored data.
- The home page and creation requirements adapt to narrow screens and larger text. English, Spanish and French flows remain available. Circle and number controls expose their labels, values and selection states to accessibility tools.
- The latest user request keeps the full challenge page and styles but moves the question, branching whole-to-parts circles, number choices, feedback and challenge actions above the child's name/profile and expanded rewards/progress cards. Vertical page scrolling is allowed. Automatic checking, circle pickers, variable parts and the learning logic remain; the earlier compact no-scroll layout remains withdrawn.

## Cleanup

Corrected the profile repository's entity type, accuracy updates and reset behavior. Removed dead private helpers, deprecated color calls, unused imports and analyzer findings. Diagnostic math checks now exercise the production generator and shared validator and fail on incorrect answers or rejected suggested splits. Debug service logs are disabled in release builds.

## Validation

The reordered full page passed **327 automated tests in 12 seconds** in the complete Flutter suite. Full `flutter analyze` reported **no issues**, and `git diff --check` passed. Automated coverage includes the agreed arithmetic examples and orders, generated equations, automatic-check timing, circle pickers, three-failure retry, hint tracking, birth-year migration and rollover, cold and saved-profile startup, navigation, lifetime totals, storage failures, reset isolation, rewards and analytics persistence. The restored page adds 27 branching-layout cases and 16 full reward-card cases, including connector geometry, extra parts, localized pickers/automatic checking, narrow cards, larger text and full-page scrolling.

Commands and logs:

```sh
flutter test --reporter expanded
flutter analyze
git diff --check
flutter build ios --release --no-pub
```

Current test and analyzer logs are `/private/tmp/number_bond_question_first_tests.log` and `/private/tmp/number_bond_question_first_analysis.log`. Formatter verification checked 74 files with zero changes. The release-build log is `/private/tmp/number_bond_question_first_iphone_build.log`.

Twelve reordered full-page previews using production AppBar typography were rendered and visually checked: English at 390 × 844, French at 320 × 568 and landscape at 568 × 320, each captured at the top, question, branching diagram and profile. They confirm the challenge interaction comes before the profile/rewards/progress cards while retaining the branching diagram. The separate preview-harness check passed (1/1). Paths follow `/private/tmp/number_bond_question_first_{en_390,fr_320,landscape_568}_{top,question,bond,profile}.png`. The old compact previews document a withdrawn active-page layout.

## iPhone deployment

The fresh question-first signed iOS release built successfully in 18.2 seconds (17.4 MB) and was installed in place on Mani's iPhone 12 Pro as `com.numberbondmath.app`. Automatic launch was blocked because the device is locked (`CoreDevice 10002` / `FBS Locked`). Unlock the phone and open the app to test the reordered page. Product source is unchanged after the build. Logs are `/private/tmp/number_bond_question_first_iphone_install.log` and `/private/tmp/number_bond_question_first_iphone_launch.log`.

## Remaining product work

Multiple-profile selection, a separate practice mode, favorite-number weighting and generated insight cards are planned and are identified that way in the requirements. The math validator accepts a broader set of decompositions than the curated number controls offer; the requested teaching examples are selectable. Hands-on learning and VoiceOver testing remain useful beyond automated layout and semantics checks.
