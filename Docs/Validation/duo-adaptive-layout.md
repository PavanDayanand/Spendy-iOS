# iPhone Duo and adaptive layout — 21 November 2026

## Implementation

The app retains its compact iPhone floating dock when the system uses horizontal bars. A stable native TabView owns Home, Subscriptions, and Stats across size changes. In regular-width layouts, or when the system supplies a vertical toolbar edge, system tabs replace the custom dock. Each destination reports adaptation from inside its navigation context. This avoids device-name/idiom checks and does not replace the root navigation hierarchy during resizing.

Home exposes Add Transaction and receipt sources through native toolbar actions in adaptive navigation. Add receives high visibility priority. Budget, month selection, exchange rates and amount visibility use the system overflow menu in supported adaptive layouts. The existing compact iPhone toolbar and dock remain available.

The Home layout now distinguishes compact, open portrait, and open landscape by size class and available container geometry. Compact native-navigation contexts use one scrolling page with three recent entries. Regular-width portrait uses one continuous page with up to eight recent entries and filters; it does not force equal-height panes or put a scrolling activity list inside a scrolling page. Landscape uses independently scrolling summary/activity panes when both can fit usefully. An active fold still selects the system ArrangementView so content can avoid the divided region. On earlier systems, the arrangement falls back to container-relative stacks.

Home's selected chart bucket and spending-period filter are bindings owned above the layout branch, so changing layouts does not create a fresh chart selection. Active activity filters remain discoverable in the compact flow. Expanded activity headings are readable text rather than disabled drawer buttons.

Shared transaction/budget entry splits into adjacent panes only when the container is sufficiently wide relative to its height. Open portrait keeps the amount above the keypad in a centered single-column form. Short displays can scroll; editing a note keeps the full column. Editor state remains above the layout branch. Onboarding, readable settings/analytics/subscription widths, and receipt-camera safe-area changes remain as described in the source.

The deployment target remains iOS 26.5. APIs introduced in iOS 27/27.1 have availability checks and older-system fallbacks. No data schema, persistence format, account behavior, or financial calculation was changed.

## Apple guidance consulted

- [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)
- [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- [Prepare your app for iPhone Duo — Tech Talk](https://developer.apple.com/videos/play/tech-talks/111461/)
- [Build a great camera experience for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111465/)

## Validation limits

Xcode 27.2 and its iOS 27.2 SDK are installed. The only installed simulator runtime is iOS 27.0. Creating an iPhone Duo simulator with that runtime returned `Incompatible device`. A regular-width iPad simulator and a conventional iPhone simulator therefore exercise the fallback layouts and system-navigation flows. They are not evidence of actual Duo vertical-bar, hinge, reserved-region, or display-handoff behavior. The iOS 27.1-specific branches must be exercised on a compatible runtime or real Duo before claiming complete device validation.

No simulator runtime was downloaded: the machine had limited free disk space and creating the additional simulator consumed further space. No physical device or saved user ledger was reset. Debug UI tests use isolated fixture ledgers; temporary test artifacts remain under `/tmp/spendy-duo-20261121`.

## Required follow-up on iPhone Duo

- Outer display: portrait, landscape, camera occlusion, keyboard, onboarding, transaction/budget entry, Settings, subscriptions and analytics.
- Inner display: portrait/landscape, fully open and partially folded, two-app Split View on either side, and right-to-left layout.
- Preserve the selected tab, pushed navigation, filters, pending sheets and an unsaved transaction across opening/closing and rotation.
- Verify Add and receipt actions remain accessible as toolbar items overflow. Check the native Back/Close controls on pushed pages and sheets.
- Confirm the active fold separates the Home/editor panes without hiding essential controls; confirm smaller contexts keep all functions reachable by scrolling.
- Test the receipt camera on hardware while changing displays/rotation. This task changes its layout only; physical camera selection, preview/capture orientation and focus across poses still require validation.
- Check accessibility text sizes, VoiceOver traversal, Reduce Motion, and light/dark appearance on both displays.

## Earlier compatibility verification (before the usability refinement)

Final build/test evidence will be recorded here after completion. Earlier exploratory runs under the same temporary directory may contain superseded failures.

- Final native build: unsigned Release archive succeeded (`final-archive.log`). The archive at `/tmp/spendy-duo-20261121/Spendy-final.xcarchive` passed `Scripts/check-beta-package.py`, including app/extension versions, launch screen, primary icon, policy, permission descriptions and privacy manifests.
- Unit suite: **125 tests, two skipped, zero failures** against the final production code (`final-phone-tests.log`).
- iPhone focused UI suite: **eight tests, one regular-width-only skip, zero failures** (`final-phone-tests.xcresult`, `TEST SUCCEEDED`). Covers adaptive/native navigation and receipt sources, short onboarding, transaction draft rotation, unchanged compact appearance controls, privacy/support, and large text.
- Regular-width simulator UI suite: **three tests, zero failures** (`verified-wide-tests.xcresult`, `TEST SUCCEEDED`). Covers system tabs/receipt actions, draft rotation/Save reachability, and independent nonoverlapping Home panes. Floating-tab automation uses label queries because iPad exposes native tabs as cells rather than a conventional TabBar.
- Navigation continuity regression: **one test, zero failures** (`navigation-tests.xcresult`, `TEST EXECUTE SUCCEEDED`). Exercises category/breakdown navigation, transaction detail-to-edit handoff, cancelled Back gesture, and returning through the native stack.
- Strengthened rotation geometry check: **one test, zero failures** (`rotation-tests.xcresult`). The test waits for a landscape app viewport and confirms the complete Save control fits within it while preserving the amount on return to portrait.
- Visual review: inspected the native-navigation and regular-width Home screenshots. The in-session rotation screenshots were clipped/misoriented by the simulator capture surface despite the viewport checks; these captures are not accepted as visual certification of the landscape editor. Hardware/new-runtime visual testing remains required.
- Existing compiler warnings in BudgetView/AddFolderSheet (trailing closures), MonthlyReceiptPrinter (actor isolation), and the AppIntents metadata-extraction warning remain outside this layout change. No new compiler errors remain. `git diff --check` passed.
- Final rotation/action check: **one test, zero failures** (`rotation-save-tests.xcresult`, `TEST SUCCEEDED`). The unsaved amount survives a portrait/landscape/portrait cycle; after a second resize, tapping Save successfully dismisses the editor and returns to Home. Only isolated fixture data was saved.

VERDICT: PASS — the scoped adaptive implementation, archive and executable checks above. Actual iPhone Duo pose/vertical-bar/camera and landscape visual validation remain pending.

## Usability refinement — current verification

The layout-policy tests cover closed portrait and landscape, open portrait, open landscape, a partial fold, and narrow multitasking. The policy does not infer an open device from landscape orientation alone. UI checks separately verify compact preview row count, a continuous portrait page, nonoverlapping landscape panes, the return to portrait, and transaction draft/save behavior. These use conventional iPhone and regular-width iPad simulators, not a Duo simulator.

The current unsigned archive is `/tmp/spendy-duo-20261121/Spendy-usability.xcarchive`. Build log: `usability-archive.log`. The physical Duo/runtime limits and remaining camera/fold checks above still apply.

- `usability-wide.xcresult`: three layout-policy unit tests and two regular-width UI tests passed. Checks open portrait → landscape → portrait, portrait flow without nested activity scrolling, adjacent landscape panes, and draft/save continuity.
- `usability-phone.xcresult`: **128 unit tests, two skipped, zero failures**, plus **two focused UI tests, zero failures**. Checks the compact three-row activity flow and saving a preserved draft after resizing.
- `usability-landscape.xcresult`: **two UI tests, zero failures**. Checks landscape pane bounds and confirms portrait entry places the amount above the keypad; the draft survives rotations and can be saved. The landscape capture surface remains malformed even on initial landscape launch; geometry/action checks passed, but visual certification of landscape still requires a newer runtime or hardware. Portrait Home and entry screenshots were inspected successfully.
- `usability-archive.log`: **ARCHIVE SUCCEEDED**. The unsigned archive passed the beta-package checker after the current production edits. `git diff --check` passed.

VERDICT: PASS — scoped usability refinements and executable checks. Actual Duo display/fold/camera behavior and landscape rendering remain unverified on a compatible runtime/device.
