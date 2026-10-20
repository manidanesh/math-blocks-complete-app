# App Store release preparation

Updated October 19, 2026 for version `1.0.3`, build `11`. The new archive and App Store-signed IPA are built, verified and successfully uploaded. App Store Connect processing and submission remain pending. Application code and the 447-test suite are unchanged from the October 17 verification; only the version and build have increased for the new candidate.

| Item | Release information |
| --- | --- |
| App | Number Bond Challenge |
| App Store ID | [6753198796](https://apps.apple.com/app/id6753198796) |
| Bundle identifier | `com.numberbondmath.app` |
| Approved version reported by Apple validation | `1.0.2`; supersedes the earlier public lookup result of `1.0` |
| Uploaded candidate version and build | `1.0.3` / `11`; accepted for upload, processing pending |
| Verified new archive | `build/ios/archive/NumberBond-1.0.3-11.xcarchive`; version `1.0.3`, build `11` |
| Verified App Store IPA | `build/ios/ipa/1.0.3-11/Number Bond Challenge.ipa`; version `1.0.3`, build `11` |
| Languages | English, Spanish, French |
| Support URL | https://manidanesh.github.io/math-blocks-complete-app/ |
| Privacy policy URL | https://manidanesh.github.io/math-blocks-complete-app/privacy.html |

Apple rejected `1.0.2 (10)` because version `1.0.2` was already approved and its release train was closed. The replacement `1.0.3 (11)` was accepted for upload and is processing. After processing, create or select version `1.0.3` in App Store Connect and attach build `11`.

Both URLs returned HTTP 200 during the October 17 release preparation. Confirm these exact URLs in App Store Connect; older deployment documents contain a different website address.

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
- [x] October 17 verification of the unchanged application code and test suite: **447 tests pass**. Analyzer is clean; formatting and whitespace checks pass. Logs: `/private/tmp/numberbond-appstore-tests.log`, `/private/tmp/numberbond-appstore-analysis.log`.
- [x] Original persistence audits: **5 checks pass**, including normal/migrated progression, retained analytics, and interrupted adaptive/insight counter recovery. Log: `/private/tmp/numberbond-appstore-original-audit.log`.
- [x] Foreground-only timing and safe old-history replacement regressions pass. Durable analytics retries and atomic per-child state snapshots address the five prior review findings without changing the learning policy.
- [x] Correct icon sizes, remove unused icon variants, replace the template launch image with a native branded launch screen, and remove the old version suffix from the display name.
- [x] Historical October 17 archive and development signature verified: `build/ios/archive/Runner.xcarchive`, bundle `com.numberbondmath.app`, version `1.0.2`, build `10`, SDK `iphoneos26.0`, minimum iOS 13, iPhone only. Archive log: `/private/tmp/numberbond-appstore-final-archive.log`. This is not the new candidate.
- [x] Historical October 17 development-signed `1.0.2 (10)` installed in place on the connected iPhone 12 Pro. Install log: `/private/tmp/numberbond-appstore-phone-install.log`. No installation of `1.0.3 (11)` is recorded yet.
- [x] Build and verify `1.0.3 (11)` at `build/ios/archive/NumberBond-1.0.3-11.xcarchive`. Both the app and archive metadata confirm version `1.0.3`, build `11`, bundle `com.numberbondmath.app`; SDK `iphoneos26.0`, minimum iOS 13, iPhone only. Apple Development signature verification (`codesign --verify --deep --strict`) succeeds. Build log: `/private/tmp/numberbond-1.0.3-archive.log`.
- [ ] Confirm the existing app record and create or select editable version `1.0.3` in App Store Connect.
- [x] Export the new archive with App Store distribution signing using the existing Xcode account. IPA: `build/ios/ipa/1.0.3-11/Number Bond Challenge.ipa`. Embedded metadata confirms version `1.0.3`, build `11`, bundle `com.numberbondmath.app`; deep, strict code-signature verification succeeds. Export log: `/private/tmp/numberbond-1.0.3-export.log`.
- [x] Upload `1.0.3 (11)` successfully. `xcodebuild` exited successfully and reported that the uploaded package is processing. Upload log: `/private/tmp/numberbond-1.0.3-upload.log`.
- [ ] Confirm build `11` finishes processing in App Store Connect and select it for version `1.0.3`.
- [ ] Install `1.0.3 (11)` through TestFlight when available and test on a phone: new profile, correct-answer reveal, retries, saved progress after reopening, and preservation of an existing profile after updating.
- [ ] Prepare current screenshots in the device formats and localizations required by App Store Connect. Show the current two-circle entry and correct-answer result; use sample profile data. See [Apple's screenshot guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-your-app-store-assets/).
- [ ] Confirm the current name, subtitle, description, What's New, support URL, privacy URL, review contact and review notes in App Store Connect. Exclude planned features from the description.
- [ ] Confirm App Privacy responses against the actual app and included SDKs, and keep the linked policy consistent. See [Apple's App Privacy guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/). This document does not change the privacy policy.
- [ ] Confirm the existing age-rating questionnaire, Made for Kids setting and chosen Kids age band in App Store Connect. The app's profile ages 4–9 do not establish the store's category or age band. See [Apple's age-rating guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/).
- [ ] Confirm pricing, availability, export-compliance answers and release timing, then submit the selected version for review when ready.

## Account history and current handoff

On October 17, the App Store IPA export reported `No Accounts`, `No signing certificate "iOS Distribution" found`, and no distribution provisioning profile for `com.numberbondmath.app`. That archive was development-signed. Browser/native account access was also denied by the computer-use permissions, and no relevant App Store Connect plugin was found at that time. These are historical failures.

On October 19, App Store export succeeded using the existing Xcode account, resolving the signing blocker. The IPA has a verified Apple Distribution signature for the existing team; `get-task-allow` is false, and its provisioning profile contains neither `ProvisionedDevices` nor `ProvisionsAllDevices`. Upload then succeeded; the upload log reports that the package is processing. Processing completion has not been confirmed, and `1.0.3 (11)` has not been submitted for review.

Wait for App Store Connect processing, then create or select version `1.0.3` in the existing app record and attach build `11`. Install the processed build through TestFlight, complete the phone checks, confirm the metadata and review information in the checklist, and use the draft review notes above when submitting for review. No further upload is needed unless processing fails and a corrected build is required. Do not retry the old `1.0.2 (10)` archive.

The October 19 archive log has no icon-size, unassigned-icon, device-family or launch-placeholder warnings. Its only warnings are App Intents metadata-extraction notices because this app does not link AppIntents.

The successful upload also returned a nonblocking deployment-target warning: Apple reported that starting in April 2027, iOS apps must target iOS 15.0 or later for upload or distribution submission. This upload was accepted with the existing iOS 13 minimum; the project's minimum iOS version has not changed. Plan that compatibility decision before a release affected by the announced requirement.

Legacy counters are normalized where retained history proves a mismatch. An already-capped historical counter discrepancy cannot always be reconstructed from the retained 100 events; future writes now have a coherent commit snapshot.
