# Birth year and automatic age

Implemented and verified October 10, 2026.

Profiles now capture a **birth year**. Displayed age is calculated from the device's current local year:

```text
age = current year − birth year
```

For a birth year of 2020, age is 6 throughout 2026 and 7 throughout 2027. This is a calendar-year estimate and changes January 1. No birth month or day is captured.

New profile creation requires a name and an age selection from 4–9. The selected age corresponds to a birth year in the current calendar year, which remains the source for annual age updates. Profile settings allow adding or changing a birth year and retain saved years as children grow beyond that range. There is no upper cap on calculated age for an existing profile.

## Existing profiles and storage

Existing profiles without a birth year retain their previously stored age. The app does not guess a birth year from that age or the profile creation date. The Profile screen explains how to add the year; selecting one immediately enables automatic calculation.

The birth year and profile stay in local SharedPreferences storage. A derived age snapshot remains in JSON for compatibility, but a valid birth year takes precedence over a stale snapshot. Edits, progress updates, and progress resets preserve the year. Adding a year preserves identity, preferences, dates, and learning progress.

Age is calculated when loading a profile, refreshed on returning to the foreground, and refreshed at local midnight while the app remains open. Refresh timers stop in the background and on disposal. Age snapshot refreshes preserve other saved fields and do not overwrite the profile with an old copy.

Malformed, noninteger, nonpositive, or future stored years fall back to an available legacy age. A profile with neither a valid year nor a usable saved age fails parsing. Future years cannot be selected or saved through the profile provider.

## Verification

The full Flutter suite passed **149 tests**, including **44 new birth-year tests**:

- 20 model tests: calendar-year changes, live clock updates, ages beyond 12, serialization, legacy and malformed storage, edits, and progress reset preservation.
- 10 provider/lifecycle tests: save/reopen in a later year, compatible age snapshot refresh, extra saved fields, legacy confirmation, edits, progress/reset, clearing, foreground resume, and an open app crossing New Year.
- 14 widget tests: required creation fields, persisted selected year, legacy editing without progress loss, growing children, localized labels, invalid/future years, year preview rollover, and narrow layout.

English, Spanish, and French labels explain the January 1 behavior. The existing number-bond tests continued to pass.

Commands run:

```sh
flutter test --reporter expanded
flutter analyze
git diff --check
```

Tests and whitespace validation passed. Full-project static analysis continues to report existing diagnostics, including the unchanged profile-repository `Entity` type-bound error. The birth-year model, new selectors/lifecycle widget, and new tests reported no diagnostics; existing profile screens and provider retain older lint diagnostics.
