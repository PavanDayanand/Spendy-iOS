---
name: apple-hig-ios
description: Authoritative Apple Human Interface Guidelines (HIG) for iOS app development. Use when designing, architecting, building, or reviewing iOS applications in SwiftUI and UIKit. Covers layout, safe areas, 44pt tap targets, navigation, typography, dynamic type, semantic colors, materials, SF Symbols, haptics, forms, widgets, live activities, and accessibility.
---

# Apple Human Interface Guidelines (HIG) — iOS App Development

The definitive guide for architecting, designing, and implementing native iOS applications adhering to Apple's official Human Interface Guidelines (HIG).

---

## 1. Foundational Design Themes & Principles

Every great iOS application embodies three core themes and adheres to Apple's eight principles of design.

### The Three Foundational Themes

1. **Clarity**:
   - Text is legible at every size; icons are unambiguous and precise.
   - Ornaments and decorations are functional, subtle, and never distract from user content.
   - Negative space, contrast, and typography guide user focus.

2. **Deference**:
   - The user interface is fluid, translucent, and unobtrusive; it elevates and defers to content.
   - Full-bleed layouts maximize screen estate while translucent materials hint at layered depth.

3. **Depth**:
   - Visual layers, subtle shadows, dynamic materials, and realistic physical animations convey spatial hierarchy.
   - Transitions explain *where* views come from and *where* they return.

### The Eight Principles of Great Design

1. **Purpose**: Define a clear core focus. Decide what *not* to build. Avoid feature bloat.
2. **Agency**: Keep users in control. Prefer reversible actions and quick undos over repetitive confirmation dialogs.
3. **Responsibility**: Protect privacy, request permissions strictly in-context with clear justifications, and ensure AI features provide transparent safeguards.
4. **Familiarity**: Respect standard iOS conventions (swipes, standard bars, system icons, standard gestures).
5. **Flexibility**: Adapt effortlessly across iPhone sizes (SE to Pro Max), orientations, Dynamic Island, and iPads.
6. **Simplicity**: Present essential workflows first; use progressive disclosure for advanced controls.
7. **Craft**: Deliver high-fidelity typography, seamless 120Hz ProMotion animations, adaptive Dark Mode, and responsive haptics.
8. **Delight**: Enrich the experience with thoughtful micro-interactions, fluid springs, and appropriate celebratory feedback.

---

## 2. Layout, Safe Areas & Display Adaptations

### Safe Areas & Full-Bleed Geometry
- **Backgrounds**: Extend to the screen edges behind the Dynamic Island, notch, status bar, and Home Indicator.
- **Interactive Content**: MUST remain strictly within `safeAreaInsets`. Never place buttons, text fields, or tappable rows outside the safe area.
- **SwiftUI Layout Pattern**:
  ```swift
  ZStack {
      Color(.systemGroupedBackground)
          .ignoresSafeArea() // Background bleeds to physical screen edges
      
      ScrollView {
          VStack(spacing: 16) {
              // Interactive content stays within safe bounds automatically
          }
          .padding(.horizontal, 16)
      }
  }
  ```

### Hit Targets & Spatial Metrics
- **Minimum Tap Target**: **44 × 44 pt** for every interactive element, even if the icon or visual asset is smaller.
- **Hit Target Padding in SwiftUI**:
  ```swift
  Button(action: { handleAction() }) {
      Image(systemName: "ellipsis")
          .font(.system(size: 17, weight: .semibold))
          .frame(minWidth: 44, minHeight: 44) // Guaranteed HIG compliant target
          .contentShape(Rectangle())         // Expands tappable hit box
  }
  ```
- **Standard Spacing Scale**:
  - `4 pt`: Micro spacing (badges, tight icon-label gaps)
  - `8 pt`: Compact spacing (element grouping within a card)
  - `12 pt`: Standard sub-element spacing
  - `16 pt`: Screen margin (iPhone standard) & primary card padding
  - `20 pt`: Large screen margin / section header spacing
  - `24 pt`: Major section separation
  - `32 pt+`: Empty state and hero separation
- **Corner Radii**:
  - `8–10 pt`: Small chips, badges, tags
  - `12–14 pt`: Standard buttons, text fields, search bars
  - `16–20 pt`: Cards, group containers, elevated modules
  - `26–36 pt`: Sheets, floating tool docks, prominent modal banners

---

## 3. Navigation Paradigms

Choose the navigation architecture that matches the user's mental model:

### 1. Hierarchical Navigation (`NavigationStack`)
- Linear drill-down flows from summary lists to detailed item views.
- **Large Titles**: Use `.navigationBarTitleDisplayMode(.large)` on top-level root views.
- **Inline Titles**: Use `.navigationBarTitleDisplayMode(.inline)` on detail child views.
- **Toolbar Items**: Place primary actions (Add, Edit, Done) in trailing toolbar placement, secondary/cancel in leading.
  ```swift
  NavigationStack(path: $navigationPath) {
      List(items) { item in
          NavigationLink(value: item) {
              ItemRow(item: item)
          }
      }
      .navigationTitle("Transactions")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
              Button(action: { showNewTransaction = true }) {
                  Image(systemName: "plus")
              }
              .accessibilityLabel("Add Transaction")
          }
      }
      .navigationDestination(for: Item.self) { item in
          ItemDetailView(item: item)
      }
  }
  ```

### 2. Flat / Peer Navigation (`TabView`)
- 3 to 5 primary top-level destinations pinned at the bottom.
- Use **outlined icons** for unselected tabs, **filled icons** for the active tab (e.g. `house` vs `house.fill`).
- Support badge counts via `.badge(count)`.
- Never place more than 5 tabs on iPhone; use a "More" tab or sidebar if extra destinations are required.

### 3. Modal Presentation (`Sheet` & `FullScreenCover`)
- **Sheets (`.sheet`)**: Use for focused, self-contained auxiliary tasks (e.g., Add, Filter, Share, Edit).
  - Use presentation detents: `.presentationDetents([.medium, .large])`
  - Show drag indicator: `.presentationDragIndicator(.visible)`
  - Protect unsaved work: `.interactiveDismissDisabled(hasUnsavedChanges)`
  - Always provide explicit Cancel (leading) and Save/Done (trailing) toolbar buttons.
- **Full Screen Covers (`.fullScreenCover`)**: Reserve for immersive standalone tasks (e.g. Camera scanner, initial onboarding).
- **Confirmation Dialogs / Action Sheets**: Use for picking between multiple actions or confirming destructive operations.

---

## 4. Typography & Dynamic Type

Always use Apple's San Francisco (`SF Pro`) system text styles to ensure automatic Dynamic Type scaling and accessibility support.

### System Text Style Reference

| Style | Default Point Size | Default Weight | Typical Usage |
| :--- | :--- | :--- | :--- |
| `.largeTitle` | 34 pt | Regular / Bold | Primary screen headers |
| `.title` | 28 pt | Regular / Bold | Main section headers |
| `.title2` | 22 pt | Regular / Bold | Major grouping headers |
| `.title3` | 20 pt | Regular / Semibold | Card headers, summary titles |
| `.headline` | 17 pt | Semibold | Prominent list titles, bold body |
| `.body` | 17 pt | Regular | Standard body content, form values |
| `.callout` | 16 pt | Regular | Highlighted notes, callouts |
| `.subheadline`| 15 pt | Regular | Secondary labels, timestamps |
| `.footnote` | 13 pt | Regular | Captions, metadata, hints |
| `.caption` | 12 pt | Regular | Small tags, secondary metadata |
| `.caption2` | 11 pt | Regular | Smallest badges, fine print |

### Dynamic Type & Proportional Layout Rules
- Scale custom icons, avatar sizes, and row heights using `@ScaledMetric`:
  ```swift
  @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 24
  @ScaledMetric(relativeTo: .body) private var rowPadding: CGFloat = 12
  ```
- Use `.monospacedDigit()` for numbers, financial amounts, clocks, and tabular counters to prevent jitter during updates:
  ```swift
  Text(amount, format: .currency(code: "USD"))
      .font(.title2.weight(.bold))
      .fontDesign(.rounded)
      .monospacedDigit()
  ```
- Support multiline wrapping for large accessibility text sizes; never clip labels with fixed heights.

---

## 5. Colors, Dark Mode & Translucent Materials

### Adaptive Semantic System Colors
Always use dynamic semantic colors that adjust automatically between Light and Dark mode:

```swift
// Background Hierarchy
Color(.systemBackground)          // Primary screen background
Color(.secondarySystemBackground) // Card and container fill
Color(.tertiarySystemBackground)  // Sub-elements within cards
Color(.systemGroupedBackground)   // Base background for grouped lists

// Typography & Foreground Hierarchy
Color.primary                      // 100% contrast, main text
Color.secondary                    // ~60% contrast, subtitles, timestamps
Color(.tertiaryLabel)             // ~30% contrast, placeholder text
Color(.quaternaryLabel)            // Subtle dividers, inactive icons

// Separators & Borders
Color(.separator)                  // Standard hairline border
Color(.opaqueSeparator)            // Non-translucent separator
```

### Dark Mode Principles
- **Avoid pure `#000000` for cards**: In Dark Mode, background is pure black, so cards must use `.secondarySystemBackground` (elevated dark gray) or materials to provide contrast and depth.
- **Maintain Contrast**: Ensure minimum 4.5:1 contrast for regular text and 3:1 for large display text.

### Materials & Liquid Glass Translucency
- Use SwiftUI materials for floating controls, toolbars, and sheets:
  - `.ultraThinMaterial`: Lightweight floating toolbars, ambient headers
  - `.thinMaterial`: Floating action buttons, segment backgrounds
  - `.regularMaterial`: Standard modal surfaces, popovers
  - `.thickMaterial` / `.ultraThickMaterial`: High-separation overlays
- Combine materials with `.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))` for a native iOS glass look.

---

## 6. SF Symbols & Iconography

- Use Apple SF Symbols 6+ for all icons.
- **Selection Semantics**: Outlined for inactive state (`heart`), filled for active state (`heart.fill`).
- **Rendering Modes**:
  ```swift
  Image(systemName: "bell.badge.fill")
      .symbolRenderingMode(.multicolor) // Native system colors (red badge, grey bell)
  
  Image(systemName: "chart.line.uptrend.xyaxis")
      .symbolRenderingMode(.hierarchical)
      .foregroundStyle(Color.accentColor)
  ```
- **Symbol Effects (iOS 17+)**:
  ```swift
  Image(systemName: "arrow.clockwise")
      .symbolEffect(.rotate, value: isRefreshing)
  
  Image(systemName: isFavorite ? "star.fill" : "star")
      .contentTransition(.symbolEffect(.replace))
  ```

---

## 7. Multimodal Feedback & Haptics

Haptic feedback gives physical weight to digital actions. Every haptic must obey **Causality** (user knows what caused it), **Harmony** (fires on the exact same frame as visual/sound changes), and **Restraint** (not spammed).

### Declarative SwiftUI Sensory Feedback (iOS 17+)
```swift
// Action Success
Button("Confirm") { processPayment() }
    .sensoryFeedback(.success, trigger: paymentCompleted)

// Value Selection / Stepper Change
.sensoryFeedback(.selection, trigger: selectedIndex)

// Discrete Impact (Light, Medium, Heavy, Soft, Rigid)
.sensoryFeedback(.impact(weight: .light, flexibility: .soft), trigger: cardTapped)

// Warning / Error
.sensoryFeedback(.warning, trigger: validationWarning)
.sensoryFeedback(.error, trigger: validationError)
```

---

## 8. Inputs, Controls & Forms

### Buttons
- Prefer standard button styles:
  - `.buttonStyle(.borderedProminent)` for the primary action on screen (at most ONE per view).
  - `.buttonStyle(.bordered)` for secondary actions.
  - `.buttonStyle(.plain)` with custom styling for custom rows/cards.
- Use `.buttonBorderShape(.capsule)` or `.buttonBorderShape(.roundedRectangle(radius: 12))`.
- Show progress indication (`ProgressView()`) inside buttons during asynchronous operations.

### Text Fields & Inputs
- Always set appropriate input attributes:
  ```swift
  TextField("Email", text: $email)
      .textContentType(.emailAddress)
      .keyboardType(.emailAddress)
      .autocorrectionDisabled()
      .textInputAutocapitalization(.never)
      .submitLabel(.next)
  ```
- Pair number fields with `.keyboardType(.decimalPad)` or `.numberPad`.
- Automatically manage keyboard dismissal with `@FocusState` and toolbar dismissal accessories.

---

## 9. Accessibility (A11y) Invariants

Accessibility is a mandatory requirement for App Store quality.

1. **VoiceOver**:
   - Provide clean labels: `.accessibilityLabel("Total balance")`.
   - Never say "Button" or "Image" in labels; VoiceOver supplies the trait automatically.
   - Combine composite views into a single accessibility element:
     ```swift
     HStack {
         Text("Coffee")
         Spacer()
         Text("$4.50")
     }
     .accessibilityElement(children: .combine)
     .accessibilityLabel("Coffee, $4.50")
     ```
2. **Dynamic Type (AX Sizes)**:
   - Test with extra-large accessibility sizes (AX1–AX5).
   - Use `ViewThatFits` or adaptive layouts to transition from horizontal stacks (`HStack`) to vertical stacks (`VStack`) when text scales up.
3. **Reduced Motion**:
   ```swift
   @Environment(\.accessibilityReduceMotion) private var reduceMotion
   
   withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.8)) {
       isExpanded.toggle()
   }
   ```
4. **Color Independence**: Never convey status solely through color. Always accompany color with an icon (checkmark, cross, exclamation) or text description.

---

## 10. Modern iOS Features & System Integration

- **Live Activities & Dynamic Island**: Design glanceable real-time updates with CompactLeading, CompactTrailing, Minimal, and Expanded presentations.
- **Widgets**: Support Small, Medium, Large widget sizes along with Lock Screen accessories (Circular, Rectangular, Inline).
- **Context Menus (`.contextMenu`)**: Offer quick access to secondary actions without leaving the current screen.
- **Swipe Actions (`.swipeActions`)**: Offer fast leading/trailing actions on list items (e.g., Pin, Delete, Favorite).
- **In-Context Permissions**: Defer permission requests (Notifications, Camera, Face ID) until the exact moment the feature is invoked, providing clear rationale in `Info.plist`.

---

## HIG Quick Reference Checklist

| Criterion | Requirement | SwiftUI Implementation |
| :--- | :--- | :--- |
| **Touch Target** | Minimum 44×44 pt | `.frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())` |
| **Safe Areas** | Interactive UI inside insets | Background `.ignoresSafeArea()`, content in `ScrollView`/`VStack` |
| **Colors** | Adaptive dynamic tokens | `Color(.systemBackground)`, `Color(.secondarySystemBackground)`, `Color.primary` |
| **Type** | Dynamic Type support | `.font(.headline)`, `.font(.body)`, `@ScaledMetric` |
| **Numbers** | Tabular non-jittering figures | `.monospacedDigit()`, `.fontDesign(.rounded)` |
| **Haptics** | Immediate causal feedback | `.sensoryFeedback(.selection, trigger: state)` |
| **Modals** | Medium/Large detents & dismiss guard | `.presentationDetents([.medium, .large])`, `.interactiveDismissDisabled()` |
| **SF Symbols** | Outlined vs. Filled state | `Image(systemName: isSelected ? "star.fill" : "star")` |
| **A11y** | VoiceOver & Reduced Motion | `.accessibilityElement(children: .combine)`, `@Environment(\.accessibilityReduceMotion)` |
