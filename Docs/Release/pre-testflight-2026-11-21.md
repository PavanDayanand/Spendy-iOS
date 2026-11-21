# Spendy — preparation before TestFlight

Reviewed 21 November 2026. Apple Developer Program enrollment, agreements, account administration, distribution signing, and uploading are deferred at the user's request.

## Changes made

- Removed the in-app external developer-tip button, sheet, and payment URL. No StoreKit purchase or paywall was added.
- Added Contact support in Help & about, using the existing privacy-contact email. Changed the Website row from the personal portfolio to the Spendy website.
- Privacy Policy always opens the bundled document, including offline. The document also links to the configured public policy URL.
- Updated the policy revision and removed development-placeholder wording. App and website policy data now match, including receipt sharing and current Siri behavior. The website's obsolete microphone/speech-recognition description was removed.
- Preserved the website's Google Sheets/Vercel disclosures when synchronizing the app policy. No waitlist storage or live deployment changed.
- Added Scripts/sync-privacy-policy.py. Run it with --check to detect drift, or without --check after reviewing changes to the canonical app policy. It does not deploy the website.
- Consolidated camera/photo purpose strings in Configuration/Spendy-Info.plist; removed competing photo text from the Xcode build settings.
- Expanded the package checker to verify expected bundle identifiers, matching app/extension versions, app/App Group UserDefaults reasons, public-policy URL configuration, contact details, purpose strings, launch-screen keys, primary icon, and readable privacy manifests. Existing personal-demo/debug-fixture checks remain.
- Updated privacy UI tests for the current Help & about navigation and added support/payment-link coverage.
- Normalized the Icon Composer PNG filename without changing the image data. The subsequent Release build no longer emitted the previous image-extension warning.
- Fixed completed/non-animated monthly receipt rendering so the whole paper lays out before asynchronous geometry measurement. An existing rendering regression caught the clipping.

## Public privacy page — unresolved external gate

The configured address is https://spendy-ebon.vercel.app/privacy. A direct HTTP request in this session returned **404**, while the homepage returned **200**. The source has a React privacy route but lacked a Vercel deep-link rewrite. A narrow local vercel.json rewrite now serves the SPA entry point for /privacy and /privacy/ without matching API or asset paths. Deployment and a live recheck remain outstanding. A configured HTTPS string is not evidence of an accessible hosted policy.

Before TestFlight invitations, restore/deploy the intended website or select its replacement domain, update the canonical policy URL if needed, synchronize the copies, and verify the live policy matches the shipped app. The app keeps its offline policy available. No website deployment was performed in this task.

## Release configuration

- Marketing version: 1.0. Build: 1 in the app and both extensions. Check the highest uploaded build before assigning a new number; this task does not claim build 1 is unused.
- Minimum OS: iOS/iPadOS 26.5. This is an intentional compatibility decision still to confirm; it was not lowered.
- Device families: iPhone and iPad. iPad layout/device QA and screenshots are therefore required.
- Xcode 27.2 / iOS 27.2 SDK are installed. The project enables generated launch-screen configuration.
- Local signing/build success does not establish distribution signing, accepted upload, or TestFlight processing.

## Privacy and dependency audit

- The app manifest declares UserDefaults access for the app (CA92.1) and App Group (1C8F.1), no collected data types, and no tracking.
- The cached Rive 6.24.0 iOS framework includes its own manifest, with SystemBootTime reason 35F9.1 and no collected data types. Manifest presence does not prove every binary behavior has been audited.
- The reviewed app network request fetches USD exchange rates from open.er-api.com. No ledger payload is passed to that endpoint. Its provider's retention/use of technical request data must be assessed before finalizing App Privacy answers; do not automatically select Data Not Collected.
- Receipt recognition uses on-device Vision and optional on-device Foundation Models. No third-party AI upload was found in the reviewed receipt flow.
- CryptoKit SHA-256 is used for receipt deduplication; HTTPS and operating-system file protection are also used. ITSAppUsesNonExemptEncryption remains unset pending the final app/dependency classification. Do not claim the app has no cryptographic use or add an exemption declaration without completing that review.
- File-size reads alone were not established as missing required-reason declarations. No speculative manifest reason was added.

## Still required before inviting testers

- [ ] Restore/verify the live privacy page and confirm support email delivery. The public App Store Support URL will also need a working page/contact route.
- [ ] Run physical-device smoke tests on the release candidate: fresh install and upgrade without clearing the user's real ledger; entry/edit/delete; transfers; budgets; subscriptions; currencies; backup/restore; recovery; relaunch; offline use.
- [ ] Exercise camera/photo/files/share-extension receipt imports, denied permissions, cancellation, malformed/large images, and Apple Intelligence unavailable/disabled cases on a real device.
- [ ] Verify widgets, lock-screen privacy, controls, Siri/Shortcuts, and local reminders in foreground, background, and locked states. Live Activities are retired; the current app only ends legacy activities.
- [ ] Complete hands-on VoiceOver, large text, reduced motion, contrast, and supported-screen/orientation checks across core tasks. Automated tests are bounded coverage.
- [ ] Confirm the minimum supported OS and intended launch territories. Assess regional age-assurance obligations before deciding whether implementation is needed; no generic age gate or new identity collection was added.
- [ ] Review remaining compiler warnings and inspect the final app icon on device. The previous Icon Composer image-extension warning was removed by the filename normalization.
- [ ] Freeze the final candidate and assign a build number after checking App Store Connect.
- [ ] After the deferred account work: validate distribution archive, upload, resolve processing/export compliance, and install the uploaded build through TestFlight.
- [ ] Provide beta description, feedback email, review contact, what-to-test instructions, and any required external Beta App Review information.

## Later App Store submission work

- Finalize App Privacy answers, export compliance, age-rating questionnaire (including social-media, Shared Location, and Dating and Relationships descriptors), pricing, categories, rights, availability, and applicable regional declarations.
- Prepare accurate current screenshots for iPhone and 13-inch iPad, app description, keywords, copyright, privacy/support URLs, and review notes. Use fictional financial data.
- Explain to review: no Spendy login or bank connection; locally managed account labels; manual entry; receipt review and optional AI fallback; widgets and Siri; no purchases in this build.
- For EU availability, complete trader status. Review mainland China permits/AI declarations if choosing that territory. These decisions are deferred, not implemented speculatively.
- Accessibility Nutrition Labels are currently described as initially voluntary; publish support claims only after evaluating core tasks.

## Apple references

- [Upload/toolchain requirements](https://developer.apple.com/news/upcoming-requirements/)
- [App Store Connect release notes](https://developer.apple.com/help/app-store-connect/release-notes/)
- [Review guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy disclosures](https://developer.apple.com/app-store/app-privacy-details/)
- [Export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/)
- [Regional age assurance](https://developer.apple.com/support/age-assurance/)
- [TestFlight workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
- [Vercel SPA deep-link configuration](https://vercel.com/docs/frameworks/frontend/vite)

## Validation

Validation results and known limits are recorded below after the final relevant changes.

- Unit suite: **125 tests executed, two skipped, zero failures** after the monthly-receipt fix. Evidence: `/tmp/spendy-presubmit-20261121/tests-final.log` and `tests-final.xcresult`. This run also captured the identifier-only UI failures subsequently corrected; its overall result is not a passing full run.
- Final focused privacy/support UI run: **three tests, zero failures**, including dark mode, largest text, return navigation, online policy-link exposure, and support without the external-tip CTA. Evidence: `/tmp/spendy-presubmit-20261121/privacy-final.log` and `privacy-final.xcresult` (`TEST SUCCEEDED`).
- Website: `npm run build` passed; `npm test` passed **28 tests**. The existing large-bundle warning remains. Policy copies match; the narrow privacy rewrite targets the built SPA entry point and does not match API/asset paths. Hosting behavior must be checked after deployment.
- The renamed icon PNG is byte-for-byte identical to the original tracked source image; no artwork was regenerated or changed.
- JSON/plist/helper syntax and `git diff --check` passed. The release candidate retains the user's unrelated pending appearance changes.
- Native compiler warnings remain in BudgetView/AddFolderSheet (deprecated trailing-closure matching), MonthlyReceiptPrinter (main-actor callback warning), and an extension with no AppIntents dependency (metadata extraction skipped). These are reported separately from the corrected test failures; no claim of a warning-free build is made.
- Physical-device testing, exhaustive accessibility review, SDK binary/network completeness, distribution signing, App Store Connect state, upload, and live policy deployment were not validated in this task.

- Final unsigned Release archive: **ARCHIVE SUCCEEDED**, with package checks passing against `/tmp/spendy-presubmit-20261121/Spendy-final.xcarchive/Products/Applications/Spendy.app`. Verified the current policy, authoritative purpose string, launch-screen configuration, primary icon, both extensions and four readable manifests. Log: `/tmp/spendy-presubmit-20261121/archive-final.log`. This archive is not distribution-signed.

VERDICT: PASS — scoped local fixes and checks above. The unchecked release gates remain outstanding.
