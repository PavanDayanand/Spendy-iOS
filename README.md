# Spendy iOS 💸✨

> A premium, local-first personal finance tracker built natively for iOS with SwiftUI.

Spendy gives you absolute privacy and control over your expenses. There are no servers, no third-party tracking, and no external accounts. Everything lives exclusively and securely on your device.

---

## 🌟 Features

- 🔒 **100% Privacy & Local-First**: Your financial data stays exclusively on your iPhone.
- 🎨 **Liquid Glass & Neo-Dark Design**: Custom glassmorphism, fluid micro-interactions, dynamic meshes, and haptic feedback.
- 💳 **Multi-Account Telemetry**: Track Cash, Bank Accounts, and Credit Cards with real-time balance calculations.
- 📊 **Intelligent Analytics**: Spending breakdowns, category distribution charts, and historical trends.
- 🎯 **Budget Planning & Tracking**: Set monthly spending limits per category and track your progress with visual indicators.
- 🔁 **Subscriptions & Recurring Expenses**: Monitor recurring subscriptions and upcoming bills.
- 📦 **Data Portability**: Full JSON backup and restore, compatible with Spendy web and other platforms.
- ⚡ **Native Performance**: Built with modern SwiftUI, `@Observable`, and Swift 5.9+ for butter-smooth 120Hz ProMotion animations.

---

## 📱 Tech Stack & Architecture

- **UI Framework**: SwiftUI (iOS 17+)
- **State Management**: `@Observable` macro (`ExpenseStore`)
- **Data Persistence**: Local JSON / Secure UserDefaults & File System
- **Design System**: LiquidGlass styling, SF Symbols, custom color tokens, custom `UIImpactFeedbackGenerator` haptics
- **Platform**: iOS 17.0+ (iPhone)

---

## 📂 Project Structure

```text
Spendy/
├── SpendyApp.swift             # App entry point with Environment Store injection
├── ContentView.swift           # Root view container
├── Core/
│   ├── DesignSystem/           # LiquidGlass, Colors, SFIcons, HapticsManager
│   └── Extensions/             # Date, Double currency formatting utilities
├── Models/
│   ├── Account.swift           # Account entity (Cash, Bank, Card)
│   ├── Category.swift          # Expense & Income categories with SF symbols
│   ├── Transaction.swift       # Transaction model with attachments & metadata
│   ├── Budget.swift            # Category monthly budgets
│   └── Subscription.swift      # Recurring billing trackers
├── Store/
│   └── ExpenseStore.swift      # Central reactive store & persistence engine
└── Views/
    ├── Dashboard/              # Balance cards, account lists, recent activity
    ├── Analytics/              # Chart analytics & telemetry
    ├── Budget/                 # Budget limit tracking & alerts
    ├── Manage/                 # Categories, accounts & subscriptions manager
    ├── Settings/               # Preferences, JSON backup/import, currencies
    ├── Transaction/            # Add/Edit transactions & detail sheets
    ├── Components/             # Reusable UI cards, headers, badges
    └── Navigation/             # Glass tab bar & navigation orchestrator
```

---

## 🔄 React → iOS SwiftUI Migration Status

This native iOS application is the next evolution of Spendy, migrated feature-by-feature from the React PWA version:

| Feature / Module | React PWA | iOS SwiftUI | Status |
|---|---|---|---|
| Central Store & Persistence | `ExpenseContext.jsx` | `ExpenseStore.swift` | ✅ Completed |
| Core Data Models | JS Objects / LocalStorage | Type-Safe Swift Models | ✅ Completed |
| Neo-Dark / Glass UI System | CSS Glassmorphism | `LiquidGlass.swift` & Custom Modifiers | ✅ Completed |
| Dashboard & Account Telemetry | `Dashboard.jsx` | `DashboardView.swift` | ✅ Completed |
| Transaction Entry & Details | `AddTransaction.jsx` | `AddTransactionView.swift` | ✅ Completed |
| Manage (Accounts, Categories, Subs)| `Categories.jsx` | `ManageView.swift` + Sheets | ✅ Completed |
| Analytics & Charts | `Analytics.jsx` | `AnalyticsView.swift` (Swift Charts) | ✅ Completed |
| Budget Management | `Budget.jsx` | `BudgetView.swift` | ✅ Completed |
| Settings, Backup & JSON Import | `Settings.jsx` | `SettingsView.swift` | ✅ Completed |

---

## 🚀 Getting Started

1. Open `Spendy.xcodeproj` in **Xcode 15+** or **Xcode 16+**.
2. Select your target simulator (e.g., iPhone 15 Pro / iPhone 16 Pro) or a connected physical iOS device.
3. Press **Cmd + R** to build and run.

---

## 📄 License

MIT © [Pavan Dayanand](https://github.com/PavanDayanand)
