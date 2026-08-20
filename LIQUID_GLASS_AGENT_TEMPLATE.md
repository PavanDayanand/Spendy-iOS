# Spendy Liquid Glass Agent Template

Use this instruction block whenever another agent edits Spendy UI.

````text
You are editing the Spendy SwiftUI app. For every new or changed interactive UI component, use Apple's Liquid Glass design language through the app's existing design system in `Spendy/Core/DesignSystem/LiquidGlass.swift`.

Hard rules:
- Do not make flat opaque buttons, old-style cards, or plain gray controls when the component is interactive.
- Use the existing helpers first:
  - `.nativeLiquidGlass(cornerRadius:isInteractive:tint:)` for rectangular panels, sheets, drawers, and dropdown surfaces.
  - `.nativeLiquidGlassCapsule(isInteractive:tint:)` for pill controls, segmented groups, chips, search bars, and bottom nav containers.
  - `.nativeLiquidGlassCircle(isInteractive:tint:)` for floating action buttons, icon buttons, close buttons, and compact controls.
  - `.nativeLiquidGlassPill(isSelected:tint:)` for selected pills and filter chips.
  - `.toggleStyle(.liquidGlass)` or `.toggleStyle(.liquidGlass(tint: SpendyColors.primaryBlue))` for toggles.
  - `GlassSegmentedPicker` for segmented controls instead of building a plain picker.
- For iOS 26 and newer, these helpers use real SwiftUI Liquid Glass APIs such as `glassEffect`, `.regular`, `.clear`, `.interactive()`, `.tint(...)`, `.capsule`, `.circle`, and rounded rect shapes.
- Keep older OS fallbacks through the existing helpers. Do not call `glassEffect` directly unless adding a new design-system helper with `#available(iOS 26, *)`.
- Use SF Symbols from `SFIcons.swift`. Do not use emoji icons.
- Use `SpendyColors.primaryBlue` as the default active tint unless the screen already has a more specific semantic color.
- Interactive controls should trigger haptics using `HapticsManager.shared.trigger(.selection)` for selection changes and `.medium` for primary actions.
- Selected state should be visually obvious with a tinted glass pill/circle, white foreground, and a subtle shadow.
- Unselected state should remain translucent, using white opacity around 0.55-0.70 for text/icons.
- Use spring animation for state changes: `.spring(response: 0.30, dampingFraction: 0.76)` or close to it.
- Do not put the plus/add button inside a multi-tab pill unless explicitly asked. In Spendy, the bottom nav is four toggles in one pill and the plus button is detached to the right.

Preferred component patterns:

Bottom navigation:
- One horizontal capsule containing exactly the four app tabs.
- A separate circular plus button to the right, visually detached by spacing.
- The selected tab uses a moving capsule highlight with `matchedGeometryEffect`.

Toggle:
```swift
Toggle("Recurring", isOn: $isRecurring)
    .toggleStyle(.liquidGlass(tint: SpendyColors.primaryBlue))
````

Segmented control:
```swift
GlassSegmentedPicker(
    selection: $selectedMode,
    items: modes,
    titleFor: { $0.title },
    iconFor: { $0.icon },
    activeTint: SpendyColors.primaryBlue
)
```

Primary icon button:
```swift
Button {
    HapticsManager.shared.trigger(.medium)
    action()
} label: {
    Image(systemName: SFIcons.plus)
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 52, height: 52)
        .nativeLiquidGlassCircle(isInteractive: true, tint: SpendyColors.primaryBlue)
}
.buttonStyle(.plain)
```

Dropdown/menu trigger:
```swift
Menu {
    Button("This Month") { selectedRange = .month }
    Button("This Year") { selectedRange = .year }
} label: {
    HStack(spacing: 8) {
        Text(selectedRange.title)
        Image(systemName: SFIcons.chevronDown)
    }
    .font(.system(size: 14, weight: .semibold))
    .foregroundStyle(.white)
    .padding(.horizontal, 14)
    .frame(height: 42)
    .nativeLiquidGlassCapsule(isInteractive: true)
}
```

Drawer/sheet surface:
```swift
VStack(spacing: 16) {
    // Drawer content
}
.padding(20)
.nativeLiquidGlass(cornerRadius: 28, isInteractive: false)
```

Floating close button:
```swift
Button {
    HapticsManager.shared.trigger(.selection)
    dismiss()
} label: {
    Image(systemName: SFIcons.close)
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(.white.opacity(0.85))
        .frame(width: 36, height: 36)
        .nativeLiquidGlassCircle(isInteractive: true)
}
.buttonStyle(.plain)
```

Before finishing:
- Run Xcode diagnostics on edited Swift files.
- Build the project with Xcode.
- Confirm the UI still has readable contrast on the app background.
- Confirm bottom controls do not overlap the safe area or keyboard.
```
