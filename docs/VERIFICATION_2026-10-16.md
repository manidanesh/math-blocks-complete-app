# Installed-version verification — October 16, 2026

Verified the current workspace supporting the signed release installed on Mani's iPhone 12 Pro: `com.numberbondmath.app`, version **1.0.2**, build **2**. No Dart source or pubspec files were newer than the built device artifact. The device reported the installed application's process running during this recheck.

## Passing checks

| Check | Result |
| --- | --- |
| Complete Flutter suite | **421 tests passed in 25 seconds** |
| Flutter analysis | **No issues** |
| Dart formatting | **82 files, no changes required** |
| Whitespace validation | `git diff --check` passed |
| Allowed second-operand sampling | **2,109 exact mappings passed** |
| Generated-domain subtraction/correction audit | **441,918 checks passed** |
| Normal progression control | Correct prior baseline prevents promotion after only one fresh lower-level success |
| Physical device check | Installed app process running on the iPhone 12 Pro |

The automated suite checks ages 4–9 in the selector and saves the endpoint ages 4 and 9; absence of manual Add/Remove Part controls; exact second-operand exclusions of 10, 100 and 1000; arithmetic and accepted decompositions; answer reveal after the 700 ms idle interval; worked steps; addition/subtraction and multi-part answers; new-question/retry resets; layouts/localization; and many rejected/throwing save, reward, journal, reentry and reset scenarios.

## Known gaps remain reproducible

The additional fault/regression checks contain **six failing assertions across the five previously reviewed issues**. These temporary checks are outside the passing 421-test suite. The persistence audit also contains a passing normal-progression control.

1. **Legacy-history retries remain unsolvable for some old questions.** Saved `19 − 7` still opens a retry whose taught `3 + 4` correction is rejected. The math audit also reconfirms unsupported legacy `19 − 8` and `18 − 7`.
2. **Migrated progression with a missing/stale baseline can advance prematurely after a rejected baseline write.** This does not reproduce for the normal-progression control with a correct prior baseline.
3. **Interrupted history/counter writes are not repaired by replay.** Simulated on-disk prefixes still leave adaptive history/count at 1/0 and insight logs/count at 20/19, without the expected analysis. These are two failing assertions for one recovery issue.
4. **Loading while paused adds background time to the recorded solve time.** The rerun recorded approximately 1.022 seconds versus 0.397 seconds of measured foreground time after a 450 ms background wait.
5. **An insight-write failure permanently drops the analytics event.** A normal UI completion followed by 19 more outcomes still yields 20 primary outcomes, 19 insight logs, no analysis and no pending journal for retry.

The recommended fixes and their source locations are in [the logic review](LOGIC_REVIEW_2026-10-14.md). No application logic was changed during this verification.

## Evidence and limits

Baseline logs:

- `/private/tmp/numberbond-phone-version-2026-10-16-tests.log`
- `/private/tmp/numberbond-phone-version-2026-10-16-analysis.log`
- `/private/tmp/numberbond-phone-version-2026-10-16-processes.json`

Focused audit logs:

- `/private/tmp/numberbond_math_scope_audit_2026-10-16.log`
- `/private/tmp/numberbond_legacy_history_review_2026-10-16.log`
- `/private/tmp/numberbond-installed-persistence-audit-20261016.log`
- `/private/tmp/numberbond-timer-recheck-20261016.log`

Automated behavioral checks ran against the current workspace with Flutter's test harness and mocked storage. The phone check confirmed the installed process; it did not exercise every interaction on the physical phone. Simulated interrupted-write snapshots are not a physical-device force-termination test. Age options and endpoint persistence tests do not establish a separate complete device walkthrough for each age. Native VoiceOver and hands-on device usability remain outside this run.

The tested main flows pass, but the five known correctness/recovery gaps prevent a clean overall readiness result.
