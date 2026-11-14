# Beta preparation — 11 November 2026

## Current assessment

The cleanup and local Release validation below are complete. This is a candidate for device QA and TestFlight distribution validation, not a claim that every feature or App Store requirement is verified.

The approved interface and accent work remain intact. No saved device ledger was erased or reset. Changes are local and uncommitted.

## Cleanup completed

- Removed the personal backup-derived dataset from `SpendyDefaultData.swift`, retaining only the non-personal constants used by fresh installs.
- Removed the unused `resetToSampleData()` method and the tracked personal `spendy_demo_data.json`. A recovery copy was placed outside the checkout at `/tmp/spendy-beta-personal-sample-recovery`; this is temporary storage, not a durable backup.
- Added the demo-ledger filename to `.gitignore`. Prior Git history still contains the previously committed data; this cleanup does not rewrite history.
- Release backup-import failures no longer print raw error details. Import validation and user-visible failure handling remain intact.
- Added a clean-install regression: empty name, transactions, subscriptions, folders, zero account balance, and onboarding required, including persistence/reload.
- Added `Scripts/check-beta-package.py` and integrated it into `Scripts/check-release.sh`. The simulator default now matches the available iPhone 17; override `SPENDY_TEST_DESTINATION` when needed.

## Evidence from this session

- Final unit suite: **119 tests, zero failures, two skipped**. Log: `/tmp/spendy-beta-unit-final.log`; result: `/tmp/spendy-beta-unit-final.xcresult`.
- Signed Release archive succeeded: `/tmp/Spendy-beta-readiness.xcarchive`; log: `/tmp/spendy-beta-archive.log`.
- Strict/deep signature verification passed with access to macOS security services. Signing authority is **Apple Development**; this does not establish App Store distribution signing or successful TestFlight export.
- App, `SpendyWidgets.appex`, and `SpendyAction.appex` each contain a readable privacy manifest and report version **1.0**, build **1**, minimum iOS **26.5**. Four privacy manifests are present across the package, including its dependencies.
- Package checks passed: both expected extensions, matching versions, privacy plists, and no checked DEBUG fixture markers or personal demo JSON.
- Additional spot-check: the former personal ledger marker checked during this session is absent from the Release executable. This is a bounded check, not a comprehensive secrets/history audit.
- Info/privacy plist lint, release-script shell syntax, and `git diff --check` passed.

Run locally:

```sh
python3 Scripts/check-beta-package.py /tmp/Spendy-beta-readiness.xcarchive/Products/Applications/Spendy.app
SPENDY_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17' Scripts/check-release.sh
```

The full release script also runs UI tests and requires working signing credentials. The full UI suite was not rerun during this cleanup.

## Open gates before inviting beta testers

1. **Distribution:** validate/export for App Store Connect with the appropriate distribution profile. Confirm that build 1 has not already been uploaded; use a new build number if necessary. Upload and TestFlight processing were not performed.
2. **TestFlight metadata:** provide the beta description, feedback address, review contact, what-to-test text, and export-compliance answers. External testing may require Beta App Review. See [Apple’s TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/).
3. **Physical-device smoke test:** fresh installation, existing-data upgrade, create/edit/delete, transfers, currency, budget, subscription payment recording, export/import, background/relaunch, and offline behavior. Validate camera/photo permission denial and receipt review.
4. **System integrations:** widgets, control widgets, Siri, notifications, and Live Activities on a real phone, including locked/background states.
5. **Navigation/accessibility:** full VoiceOver and large-text pass; resolve or reproduce the previously observed canceled-back-swipe header failures. They were not revalidated in this cleanup.
6. **Packaging warnings:** Xcode warns that Icon Composer's generated `c8` image set uses `image.PNG`. The actual source PNG is valid; normalizing its source filename did not remove the warning, so that experiment was reverted. Review/re-export through Icon Composer before submission. A metadata-extraction warning for a target with no AppIntents dependency also appears; archive creation succeeds.
7. **Privacy/support:** review the App Store privacy answers against actual app/dependency behavior and confirm hosted privacy/support links. Manifest syntax/package presence alone does not establish completeness.
8. **Device coverage:** current minimum OS is iOS 26.5. Confirm the intended beta devices can install it; iPad presentation and the minimum supported OS still need hands-on checks.

## Suggested TestFlight “What to Test”

Please test recording and editing expenses, income and transfers; account balances; budget progress; subscription reminders and payment recording; receipt capture and review; appearance settings; and backup export/import. Check that your information remains correct after closing and reopening Spendy and while offline. Try widgets and Siri if available on your device.

When reporting a problem, include the screen, steps to reproduce, expected result, device model, iOS version, and app build. Share a redacted screenshot if useful; do not include your full ledger or private financial details in feedback.
