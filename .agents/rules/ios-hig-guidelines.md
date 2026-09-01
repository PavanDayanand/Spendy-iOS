---
trigger: model_decision
description: Enforces Apple Human Interface Guidelines (HIG) standards when writing Swift/SwiftUI and architecting iOS views.
---

# iOS Human Interface Guidelines (HIG) Invariants

When writing, refactoring, or reviewing iOS / SwiftUI code in this project, adhere strictly to these rules:

1. **Touch Targets**: All interactive elements (buttons, tappable rows, icons) must have a minimum hit target of **44 × 44 pt** (`.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())`).
2. **Safe Areas**: Never hardcode screen heights or top/bottom padding for notches or Home Indicators. Always respect system safe area insets. Backgrounds may ignore safe areas; interactive content never.
3. **Semantic Colors**: Use adaptive semantic system colors (`Color(.systemBackground)`, `Color(.secondarySystemBackground)`, `Color.primary`, `Color.secondary`, `Color.accentColor`) or semantic design system tokens. Never use hardcoded light-only hex colors.
4. **Dynamic Type & Typography**: Use SwiftUI semantic text styles (`.largeTitle`, `.title2`, `.headline`, `.body`, `.footnote`) and `@ScaledMetric` for proportional layout scaling. Avoid fixed font sizes without Dynamic Type scaling.
5. **Monospaced Numbers**: For financial amounts, timestamps, and counters, always use `.monospacedDigit()` and `.fontDesign(.rounded)` to prevent layout jitter.
6. **SF Symbols**: Use standard SF Symbols with appropriate rendering modes and filled variants for selected states (e.g. `house.fill` vs `house`).
7. **Modals & Sheets**: Use standard presentation detents (`.presentationDetents([.medium, .large])`), visible drag indicators, and protect against data loss with `.interactiveDismissDisabled()`.
8. **Haptics**: Pair significant user actions (save, delete, toggle, selection) with native haptic feedback (`.sensoryFeedback`).
9. **Accessibility**: Provide descriptive `.accessibilityLabel` for custom controls, support Dark Mode, and honor `accessibilityReduceMotion`.
