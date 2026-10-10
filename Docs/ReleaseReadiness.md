# Release readiness — 10 October 2026

The app has a repeatable regression suite and safer local persistence. Passing these checks is evidence for the tested flows; it is not an App Store approval or exhaustive product certification.

## Changes

- Serialized atomic saves retain the previous successful snapshot. Lifecycle flushes drain pending writes before suspension.
- An unreadable primary file blocks normal editing and saving. Recovery validates the selected backup and preserves the unreadable original before replacing it.
- Failed saves retain an unsaved status after dismissing the alert. Retry and JSON export remain available.
- Native imports reject invalid dates, duplicate IDs, invalid amounts, and missing accounts before changing the ledger. Arbitrary JSON cannot clear transactions through the legacy importer.
- Explicit data erasure also removes recovery copies. Account deletion preserves reloadable transaction history and retains the last account.
- Cancelled subscriptions are excluded from monthly commitments. Logged payments retain their subscription ID.
- Shortcut transactions flush before reporting success. Pending widget transactions are acknowledged after a successful store write.
- The app embeds its widget extension. The app and widget package a privacy manifest for their app-local and App Group UserDefaults access, following [Apple’s approved reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
- Runtime insight assertions moved from app startup into XCTest. Settings displays the actual bundle version. Concurrency warnings in storage, receipt scanning, live activity attributes, glass IDs, and onboarding have been corrected.

## Automated coverage

`SpendyTests` covers transaction creation/edit/deletion, transfer balance conservation, budget boundaries, monthly/yearly/weekly billing, cancelled subscriptions, JSON round trips and invalid imports, ordered writes, lifecycle flush/relaunch, damaged-file recovery, invalid recovery backups, visible write failures/retries, recovery-file erasure, supported date formats, account deletion, cached exchange rates while offline, and 10,000-transaction balance/persistence performance. The existing insight regression groups also run under XCTest.

`SpendyUITests` uses isolated temporary ledgers. It exercises backup recovery, transaction details, horizontal filters, the recovery screen at the largest accessibility text size, and Home touch targets/accessibility descriptions. DEBUG-only test fixtures and integration suppression do not ship in Release builds.

Run `Scripts/check-release.sh` from the checkout. Override `SPENDY_TEST_DESTINATION` to select another device. It runs the suite, creates a signed Release archive, and verifies the app and embedded extension signatures. Xcode signing credentials and profiles must already be available; the script does not authorize provisioning updates.

## Validation record

- Physical iPhone 17 Pro, iOS 27.0.1: **22 tests passed** (18 unit tests and 4 UI tests), with zero failures. This includes the existing 20 insight regression groups within one unit test.
- The 10,000-transaction benchmark on that device averaged about **2 ms** for balance calculation and **31 ms** for persistence. These are local measurements without a regression baseline; persistence varied across iterations.
- iPad mini (A17 Pro), iOS 27 simulator: **4 UI tests passed**, including recovery at the largest accessibility text size and the Home accessibility audit.
- Earlier iPhone simulator run: 21 tests passed before the additional Home accessibility audit was added. The final device run includes that audit.
- A default whole-module optimized Release archive succeeded. The final source archive also succeeded with `SWIFT_COMPILATION_MODE=incremental`, retaining Release `-O` optimization, to reduce compiler resource pressure. The project default remains whole-module compilation.

- Final archive: `/tmp/Spendy-readiness.xcarchive`. Deep, strict signature verification passed. The widget and both privacy manifests are present; DEBUG UI fixtures are absent from the Release binary. Bundle version is 1.0 (1).
- Xcode project and privacy plist lint, release-script syntax, and `git diff --check` passed. Your original simulator and physical app were relaunched normally after testing.

Logs and `.xcresult` bundles are kept in `/tmp` for this session. Final device log: `/tmp/spendy-device-final-tests.log`; final tablet log: `/tmp/spendy-ipad-final-tests.log`; final archive log: `/tmp/spendy-release-final.log`.

## Release gates requiring broader review

- App Store distribution/export validation and TestFlight installation. The local archive uses development signing.
- A hands-on camera, receipt-photo, speech, notification, widget/control-widget, Live Activity, and Siri review, including denied permissions and device lock/background behavior.
- Full VoiceOver navigation, all screen sizes/orientations, and Dynamic Type throughout the app. The automated accessibility checks cover the named screens and audit types only.
- A sustained real-data beta to exercise storage growth, repeated upgrades/imports, memory/energy behavior, and device suspension. The 10,000-row test is a bounded benchmark, not a long-running Instruments session.
- Review the App Store privacy answers, privacy/support URLs, screenshots, and intended minimum OS (currently iOS 26.5).

Do not submit this as a fully validated production release while these broader release gates are outstanding.
