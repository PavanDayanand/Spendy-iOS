# Spendy iOS

Spendy is a local-first personal finance app built with SwiftUI. It brings together expenses, income, transfers, accounts, budgets, subscriptions, spending insights, receipt scanning, widgets, and Siri shortcuts.

## Build and run

- Use Xcode 27 with the iOS SDK installed.
- The app and extensions currently target iOS 26.5 and later.
- Swift Package Manager resolves the Rive runtime when the project opens.

1. Open `Spendy.xcodeproj`.
2. Select the `Spendy` scheme and an available iPhone or iPad simulator.
3. Build and run. For a physical device, configure signing for the app and its extensions.

## Project layout

```text
SpendyIOS/
├── Configuration/              App and extension Info plists and action entitlements
├── Design/                     Retained mascot sources, editable icon source, and previews
├── Docs/
│   ├── Architecture/           Navigation, receipt sharing, and spending charts
│   ├── Release/                Beta preparation and dated release records
│   └── Validation/             Navigation and receipt-scanner validation records
├── Scripts/                    Release and package validation
├── Spendy.xcodeproj/           Xcode project, schemes, and package references
├── Spendy/                     Main app target
│   ├── Assets.xcassets/        Runtime images, colors, and alternate icons
│   ├── Core/                   Design system, navigation, persistence, and services
│   ├── Models/                 Accounts, transactions, budgets, and subscriptions
│   ├── Resources/              Rive animations and privacy-policy content
│   ├── Spendy_iOS.icon/        Active Icon Composer artwork
│   ├── Store/                  Observable state and local persistence
│   └── Views/                  Screens grouped by feature
├── SpendyAction/               Receipt action extension
├── SpendyShared/               Shared widget data, views, intents, and privacy manifest
├── SpendyTests/                Unit and regression tests
├── SpendyUITests/              UI regression and opt-in capture tests
└── SpendyWidgets/              WidgetKit extension and widget configurations
```

`.agents/` contains repository guidance and development skills.

## Documentation

### Architecture

- [Navigation and transitions](Docs/Architecture/navigation.md)
- [Receipt sharing and review](Docs/Architecture/receipt-sharing.md)
- [Spending charts and data rules](Docs/Architecture/spending-charts.md)

### Release and validation

- [Beta preparation and outstanding release checks](Docs/Release/beta-readiness.md)
- [Release validation record, 10 October 2026](Docs/Release/release-readiness-2026-10-10.md)
- [Navigation header audit](Docs/Validation/navigation-header-audit.md)
- [Receipt scanner validation](Docs/Validation/receipt-scanner-validation.md)

These records describe the validation performed on their stated dates and the remaining device or distribution checks.

## Validation commands

Run the unit suite on an installed iPhone 17 simulator.

```sh
xcodebuild -project Spendy.xcodeproj -scheme Spendy \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SpendyTests test
```

Run the release script to execute the test suite, create a signed archive, verify its signature, and check the packaged app and extensions. Set `SPENDY_TEST_DESTINATION` to use another simulator. Signing requires a configured development team.

```sh
Scripts/check-release.sh
```

To inspect an existing archive, pass its app bundle to the package checker.

```sh
python3 Scripts/check-beta-package.py /path/to/Spendy.xcarchive/Products/Applications/Spendy.app
```

## Repository housekeeping

Keep runtime images in the appropriate asset catalog and Rive files in `Spendy/Resources/`. Store project-specific documentation under `Docs/` using descriptive lowercase names with hyphens. Release scripts belong in `Scripts/`.

Build output, Xcode user settings, UI-test result bundles, and personal ledger exports are ignored by Git. Retained mascot originals and editable icon source live in [Design/](Design/README.md). Keep redundant exports, temporary marketing captures, and general reference material outside the app repository.
