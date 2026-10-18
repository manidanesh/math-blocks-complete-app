# App Store release preparation

Prepared October 17, 2026. The release candidate is archived and tested. App Store Connect checks, distribution signing, upload and submission remain pending.

| Item | Release information |
| --- | --- |
| App | Number Bond Challenge |
| App Store ID | [6753198796](https://apps.apple.com/app/id6753198796) |
| Bundle identifier | `com.numberbondmath.app` |
| Public version reported by Apple's lookup | `1.0` |
| Proposed version and build | `1.0.2` / `10`; confirm both are available in App Store Connect |
| Languages | English, Spanish, French |
| Support URL | https://manidanesh.github.io/math-blocks-complete-app/ |
| Privacy policy URL | https://manidanesh.github.io/math-blocks-complete-app/privacy.html |

Both URLs returned HTTP 200 during release preparation. Confirm these exact URLs in App Store Connect; older deployment documents contain a different website address.

## Draft What's New

### English

Correct number bonds now reveal the answer in the equation, alongside the worked steps. This update also improves saved-progress recovery and fixes retries of older review problems.

### Español

Ahora, al completar correctamente una descomposición numérica, la respuesta aparece en la ecuación junto con los pasos de la solución. Esta actualización también mejora la recuperación del progreso guardado y corrige los reintentos de ejercicios anteriores.

### Français

Lorsqu’une décomposition est correcte, la réponse apparaît désormais dans l’équation, avec les étapes de la solution. Cette mise à jour améliore aussi la récupération des progrès enregistrés et corrige les nouvelles tentatives d’anciens exercices.

## Draft App Review notes

Number Bond Challenge helps children practice addition and subtraction by splitting the second operand. New profiles offer ages 4–9. The app works offline and requires no account or login. Profiles and learning progress are stored on the device. There are no advertisements, in-app purchases, subscriptions or paid feature unlocks.

To review:

1. Create a local profile with a sample name, an age from 4–9 and a language.
2. Open the adaptive challenge. Choose the two parts from the number grid or tap a part circle to use its picker.
3. A complete entry checks automatically after 700 ms. A correct bond reveals the result in the top equation and shows the worked steps; no separate final-answer entry is required.
4. Use Next Challenge to continue, or open Profile to review saved progress and preferences.

## Release checklist

- [x] Focused navigation tests passed: 33 tests, including legacy review replacement and supported Level 3/4 history retries. Log: `/private/tmp/numberbond_release_navigation_2026-10-17.log`.
- [x] Complete suite: **447 tests pass**. Analyzer is clean; formatting and whitespace checks pass. Logs: `/private/tmp/numberbond-appstore-tests.log`, `/private/tmp/numberbond-appstore-analysis.log`.
- [x] Original persistence audits: **5 checks pass**, including normal/migrated progression, retained analytics, and interrupted adaptive/insight counter recovery. Log: `/private/tmp/numberbond-appstore-original-audit.log`.
- [x] Foreground-only timing and safe old-history replacement regressions pass. Durable analytics retries and atomic per-child state snapshots address the five prior review findings without changing the learning policy.
- [x] Correct icon sizes, remove unused icon variants, replace the template launch image with a native branded launch screen, and remove the old version suffix from the display name.
- [x] Final archive succeeds and its development signature verifies. Archive: `build/ios/archive/Runner.xcarchive`, bundle `com.numberbondmath.app`, version `1.0.2`, build `10`, SDK `iphoneos26.0`, minimum iOS 13, iPhone only. Final archive log: `/private/tmp/numberbond-appstore-final-archive.log`.
- [x] Corrected development-signed candidate installed in place on the connected iPhone 12 Pro. Install log: `/private/tmp/numberbond-appstore-phone-install.log`.
- [ ] Confirm the app record, current editable version, and unused build number in App Store Connect before using `1.0.2 (10)`.
- [ ] Export with App Store distribution signing, validate/upload, then confirm the selected build has finished processing in App Store Connect.
- [ ] Test the candidate on a phone: new profile, correct-answer reveal, retries, saved progress after reopening, and preservation of an existing profile after updating.
- [ ] Prepare current screenshots in the device formats and localizations required by App Store Connect. Show the current two-circle entry and correct-answer result; use sample profile data. See [Apple's screenshot guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets/).
- [ ] Confirm the current name, subtitle, description, What's New, support URL, privacy URL, review contact and review notes in App Store Connect. Exclude planned features from the description.
- [ ] Confirm App Privacy responses against the actual app and included SDKs, and keep the linked policy consistent. See [Apple's App Privacy guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/). This document does not change the privacy policy.
- [ ] Confirm the existing age-rating questionnaire, Made for Kids setting and chosen Kids age band in App Store Connect. The app's profile ages 4–9 do not establish the store's category or age band. See [Apple's age-rating guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/).
- [ ] Confirm pricing, availability, export-compliance answers and release timing, then submit the selected version for review when ready.

## Current account blocker and handoff

The App Store IPA export reported `No Accounts`, `No signing certificate "iOS Distribution" found`, and no distribution provisioning profile for `com.numberbondmath.app`. The archive is signed for development; it is not an App Store-signed IPA and has not been uploaded or submitted. Browser/native account access was also denied by the computer-use permissions, and no relevant App Store Connect plugin was found.

Sign into the existing Apple Developer account in **Xcode → Settings → Accounts**, then open `build/ios/archive/Runner.xcarchive` in Xcode Organizer. Select **Distribute App → App Store Connect**, use the existing app/team, and allow Xcode to manage distribution signing. Complete any account-holder agreement prompts yourself. Confirm build/version availability and upload the candidate; after processing, attach it to the update and use the draft review notes above.

The final archive has no remaining icon-size, unassigned-icon, device-family or launch-placeholder warnings. Xcode's App Intents metadata-extraction notice remains because this app does not link AppIntents.

Legacy counters are normalized where retained history proves a mismatch. An already-capped historical counter discrepancy cannot always be reconstructed from the retained 100 events; future writes now have a coherent commit snapshot.
