# Logic review — October 14, 2026

Update October 17: the five findings below are addressed in the `1.0.2 (10)` release candidate. The complete suite passes 447 tests, and the original persistence audits now pass. Unsupported history retries now offer a valid replacement review while preserving the original record. See [release preparation and remaining distribution steps](APP_STORE_RELEASE.md). The findings and reproductions below describe the earlier reviewed version.

Reviewed generation and answer validation, challenge/retry/reveal flow, foreground timing, adaptive progression, completion recovery, rewards/profile updates, and learning-history semantics. This is a review: application code and learning policy were not changed.

## Verification

- The existing complete Flutter suite passes **421 tests in 21 seconds**.
- `flutter analyze --no-pub` reports **no issues**.
- A focused mathematical audit passed **2,109 allowed-value sampler mappings** and **441,918 generated-domain subtraction/correction checks**. No new defect was found in generated question arithmetic or the exact second-operand exclusions of 10, 100 and 1000.
- Additional temporary regression checks reproduce the findings below. They assert the desired behavior and currently fail; they are outside the passing project suite.
- Baseline logs: `/private/tmp/numberbond-logic-review-tests.log` and `/private/tmp/numberbond-logic-review-analysis.log`.

## Correctness fixes, in recommended order

### 1. Some older saved questions cannot be retried successfully

**Impact:** A child can open an old mistake and follow its suggested correction, yet every answer is rejected.

**Reproduction:** Saved legacy questions `19 − 7`, `19 − 8` and `18 − 7` reopen unchanged from profile history. For `19 − 7`, there are no accepted two-part choices, no suggested valid breakdown, and the fallback explanation `3 + 4` is itself rejected. The current generator no longer produces these unsupported questions, but existing saved history remains reachable.

**Source:** [History replay](/Users/Mani/Documents/MyProjects/NumberBond/lib/screens/profile_screen.dart:829), [subtraction acceptance](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/answer_validator.dart:133), [fallback correction](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/answer_validator.dart:191).

**Recommended fix:** Check that a saved question has an accepted, selectable decomposition before offering its learning retry. Keep the original history readable; when it is unsupported, use a valid generated review for the same operation and appropriate level. Do not silently broaden the agreed subtraction rules.

**Evidence:** `/private/tmp/numberbond_legacy_history_review_test.dart`, `/private/tmp/numberbond_legacy_history_review.log`, `/private/tmp/numberbond_math_scope_audit.dart`, `/private/tmp/numberbond_math_scope_audit.log`.

### 2. A partially saved level change can reuse old mastery evidence on migrated data

**Impact:** In an older installation with a missing or stale level-start marker, a child can return to a harder level after one fresh success rather than five fresh lower-level outcomes.

**Reproduction:** Start with five older Level 1 successes and five later Level 2 failures, with no valid Level 2 start marker. Reject the demotion's baseline write after the new level and decision identity have saved. Retry accepts that decision without repairing the marker. One new Level 1 success then combines with old Level 1 successes and promotes back to Level 2.

This reproduction is specific to missing/stale baseline data. A successful ordinary promotion previously saving the correct baseline excludes the older successes; the finding should not be described as affecting every demotion.

**Source:** [Separate level/decision/baseline writes](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/adaptive_challenge_engine.dart:212), [duplicate-decision early return](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/adaptive_challenge_engine.dart:189).

**Recommended fix:** Persist level, decision identity and the fresh-evidence baseline as one versioned snapshot. Initialize the baseline explicitly for migrated histories, and make retry complete or roll back the entire decision.

**Evidence:** `/private/tmp/numberbond_persistence_audit_test.dart`.

### 3. Abrupt termination between writes leaves counters inconsistent

**Impact:** Review cadence and insight-analysis cadence can remain out of step with the actual saved outcomes after recovery.

**Reproduction:** Seed the on-disk prefix produced when history saves but the subsequent counter write has not completed, then replay the pending event. Adaptive recovery leaves **one history event with count zero**. Insight recovery leaves **20 logs with count 19 and no analysis**. Duplicate checks skip the event before repairing its counter. These checks simulate interrupted-write snapshots; they do not claim a physical device was forcibly terminated during the audit.

The existing rejected-write rollback is useful, but a terminated process cannot execute rollback.

**Source:** [Adaptive duplicate guard](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/adaptive_challenge_engine.dart:58), [adaptive counter write](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/adaptive_challenge_engine.dart:80), [insight duplicate guard](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/insights_engine.dart:67), [separate insight writes](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/insights_engine.dart:121).

**Recommended fix:** Store each history and its cumulative counter together, or add a durable commit marker that recovery can use to finish the counter exactly once. Retain cumulative totals independently from the 100-event recent-history cap.

**Evidence:** `/private/tmp/numberbond_persistence_audit_test.dart`.

### 4. Loading a question in the background adds background time to solving time

**Impact:** The child can appear slower even though they were not using the app.

**Reproduction:** Hold the initial profile read, pause the app, release loading while paused, wait 450 ms, resume and solve. A temporary regression recorded approximately **0.742 seconds** for approximately **0.186 seconds of foreground time**. The pause callback stops the previous timer, but a subsequent `_startAttempt` starts it again while still paused.

**Source:** [Lifecycle handling](/Users/Mani/Documents/MyProjects/NumberBond/lib/screens/adaptive_challenge_screen.dart:179), [unconditional timer start](/Users/Mani/Documents/MyProjects/NumberBond/lib/screens/adaptive_challenge_screen.dart:187).

**Recommended fix:** Track the current lifecycle state, including its initial value, and start a new attempt's stopwatch only while the app is resumed. Keep the existing pause/resume handling.

**Evidence:** `/private/tmp/numberbond_background_timer_review_test.dart`.

### 5. A failed insight write is discarded after an otherwise successful completion

**Impact:** Insight data can permanently miss a completed challenge, delaying the documented 20-outcome analysis cadence.

**Reproduction:** Reject the first insight-log write during an actual challenge-screen completion. The main history, reward and profile outcome complete, and the completion journal is cleared. After 19 more outcomes, there are **20 primary outcomes, 19 insight logs, no analysis and no pending journal**. The normal UI has no remaining event to retry for analytics.

**Source:** [Swallowed analytics failure](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/adaptive_problem_service.dart:74), [completion journal clear](/Users/Mani/Documents/MyProjects/NumberBond/lib/screens/adaptive_challenge_screen.dart:385).

**Recommended fix:** Retain failed analytics in a durable queue and retry them independently, without blocking a child's reward or making them solve the question again. Reuse the original event identity so retries cannot duplicate logs.

**Evidence:** `/private/tmp/numberbond_persistence_audit_test.dart`.

## Learning improvements to consider separately

1. **Make history describe the submitted bond.** Failed questions currently show “Your answer: No answer”, despite the child having selected parts. Successful outcomes also synthesize a numeric `userAnswer`, although the child never enters a final answer. Save the selected parts and display the attempted split and method. [Current recording](/Users/Mani/Documents/MyProjects/NumberBond/lib/services/adaptive_problem_service.dart:58), [current history label](/Users/Mani/Documents/MyProjects/NumberBond/lib/screens/profile_screen.dart:877).
2. **Separate independent success from success after help.** The current progression contract treats a correct terminal outcome as success even after earlier errors and hints. Keep that existing behavior until a learning-policy change is agreed, but use first-attempt and hint data to report independent mastery separately.
3. **Track addition and subtraction readiness separately.** A shared difficulty level can carry an addition-only success streak into subtraction when the operation preference changes. Separate operation evidence would make adaptation more specific; this would be a product change rather than a correction to the existing shared-level contract.

Fix the correctness and recovery gaps before changing learning policy or adding new controls.
