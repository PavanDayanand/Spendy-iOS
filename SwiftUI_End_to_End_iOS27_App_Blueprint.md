# SwiftUI End-to-End App Blueprint — iOS 27 / Xcode 27

> **Updated:** August 2026  
> **Target:** modern SwiftUI apps using the iOS 27 / Xcode 27 SDK and the current Apple platform design system.
>
> **Important version note:** Apple’s current public documentation in this reference is for the **2027 releases / iOS 27 generation**. There is no public iOS 28 SwiftUI API surface in the Apple documentation available at this time. Do **not** invent iOS 28 APIs. When Apple publishes the next SDK, update the version-specific section from Apple’s official SwiftUI updates page.

This is the **end-to-end version** of the previous reference. It is organized around what you actually need to build a polished production app — not just a list of SwiftUI types.

---

# 1. The architecture you should start with

A serious app should be thought of as:

```text
App
│
├── App entry / scenes
│
├── Root navigation
│   ├── TabView
│   ├── NavigationStack
│   └── NavigationSplitView
│
├── Design system
│   ├── Typography
│   ├── Colors
│   ├── Spacing
│   ├── Corner radii
│   ├── Icons
│   ├── Materials
│   └── Liquid Glass
│
├── Feature modules
│   ├── Home
│   ├── Search
│   ├── Detail
│   ├── Settings
│   └── Account
│
├── State / data
│   ├── @State
│   ├── @Binding
│   ├── @Observable
│   ├── Environment
│   └── SwiftData
│
├── Services
│   ├── Networking
│   ├── Authentication
│   ├── Payments
│   ├── Notifications
│   └── System integrations
│
└── Polish
    ├── Transitions
    ├── Morphing
    ├── Haptics
    ├── Accessibility
    ├── Localization
    └── Performance
```

Apple's current SwiftUI documentation is the master reference:

- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [SwiftUI Pathway](https://developer.apple.com/swiftui/get-started/)
- [What's New in SwiftUI](https://developer.apple.com/swiftui/whats-new/)
- [SwiftUI Updates](https://developer.apple.com/documentation/updates/swiftui)
- [WWDC26 SwiftUI Guide](https://developer.apple.com/wwdc26/guides/swiftui/)

Apple's 2027-release SwiftUI guide specifically highlights the expanded Document API, toolbar controls, presentation/interaction improvements, and performance/data-flow changes. [Apple SwiftUI Guide](https://developer.apple.com/wwdc26/guides/swiftui/)

---

# 2. Root app structure

## App lifecycle

Use:

- `App`
- `Scene`
- `WindowGroup`
- `Window`
- `Settings`
- `DocumentGroup`
- `MenuBarExtra`
- `ImmersiveSpace`
- `ScenePhase`

Docs:

- [App](https://developer.apple.com/documentation/swiftui/app)
- [Scenes](https://developer.apple.com/documentation/swiftui/scene)
- [Windows](https://developer.apple.com/documentation/swiftui/windows)
- [App organization](https://developer.apple.com/documentation/swiftui/app-organization)
- [ScenePhase](https://developer.apple.com/documentation/swiftui/scenephase)

### Recommended root

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

Do not build the app around a giant `ContentView`.

---

# 3. Root navigation

The current navigation foundation is:

## `TabView`

Use for major top-level destinations.

- [TabView](https://developer.apple.com/documentation/swiftui/tabview)
- [Tab](https://developer.apple.com/documentation/swiftui/tab)
- [TabSection](https://developer.apple.com/documentation/swiftui/tabsection)

### iOS 27 prominent tab role

A tab can be given a prominent role:

```swift
TabView {
    Tab {
        HomeView()
    }

    Tab {
        SearchView()
    }

    Tab(role: .prominent) {
        CartView()
    }
}
```

Apple shows `.prominent` being used to distinguish an important tab such as a shopping cart.

- [What's New in SwiftUI — prominent tab role](https://developer.apple.com/videos/play/wwdc2026/269/)
- [Tab](https://developer.apple.com/documentation/swiftui/tab)

---

# 4. NavigationStack

Use for normal hierarchical navigation.

```swift
NavigationStack {
    HomeView()
}
```

Important APIs:

- [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)
- [NavigationLink](https://developer.apple.com/documentation/swiftui/navigationlink)
- [NavigationPath](https://developer.apple.com/documentation/swiftui/navigationpath)
- [navigationDestination](https://developer.apple.com/documentation/swiftui/view/navigationdestination(for:destination:))
- [navigationTitle](https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:))
- [navigationSubtitle](https://developer.apple.com/documentation/swiftui/view/navigationsubtitle(_:))

Navigation supports programmatic paths and deep-linkable data-driven destinations.

- [SwiftUI Navigation](https://developer.apple.com/documentation/swiftui/navigation)

---

# 5. NavigationSplitView

Use for iPad/Mac multi-column experiences.

```swift
NavigationSplitView {
    Sidebar()
} detail: {
    DetailView()
}
```

- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [navigationSplitViewColumnWidth](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(_:))
- [navigationSplitViewVisibility](https://developer.apple.com/documentation/swiftui/view/navigationsplitviewvisibility(_:))

Apple's current guidance emphasizes adaptive layouts and avoiding hard-coded screen sizes. [Navigation documentation](https://developer.apple.com/documentation/swiftui/navigation)

---

# 6. Design system BEFORE building screens

Create one design system rather than manually styling every screen.

Recommended tokens:

```text
AppTypography
AppSpacing
AppRadius
AppColors
AppIcons
AppMotion
AppGlass
```

Example:

```swift
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}
```

Use:

- [Font](https://developer.apple.com/documentation/swiftui/font)
- [Color](https://developer.apple.com/documentation/swiftui/color)
- [Material](https://developer.apple.com/documentation/swiftui/material)
- [ShapeStyle](https://developer.apple.com/documentation/swiftui/shapestyle)
- [RoundedRectangle](https://developer.apple.com/documentation/swiftui/roundedrectangle)
- [Capsule](https://developer.apple.com/documentation/swiftui/capsule)

---

# 7. Typography

Important APIs:

- [Font](https://developer.apple.com/documentation/swiftui/font)
- [font](https://developer.apple.com/documentation/swiftui/view/font(_:))
- [fontWeight](https://developer.apple.com/documentation/swiftui/view/fontweight(_:))
- [fontDesign](https://developer.apple.com/documentation/swiftui/view/fontdesign(_:))
- [Dynamic Type](https://developer.apple.com/documentation/swiftui/dynamic-type)

Prefer Apple's system typography unless your design specifically requires a bundled/custom font.

---

# 8. Layout system

Core:

- [HStack](https://developer.apple.com/documentation/swiftui/hstack)
- [VStack](https://developer.apple.com/documentation/swiftui/vstack)
- [ZStack](https://developer.apple.com/documentation/swiftui/zstack)
- [Grid](https://developer.apple.com/documentation/swiftui/grid)
- [LazyVGrid](https://developer.apple.com/documentation/swiftui/lazyvgrid)
- [LazyHGrid](https://developer.apple.com/documentation/swiftui/lazyhgrid)
- [LazyVStack](https://developer.apple.com/documentation/swiftui/lazyvstack)
- [LazyHStack](https://developer.apple.com/documentation/swiftui/lazyhstack)
- [ScrollView](https://developer.apple.com/documentation/swiftui/scrollview)
- [GeometryReader](https://developer.apple.com/documentation/swiftui/geometryreader)
- [ViewThatFits](https://developer.apple.com/documentation/swiftui/viewthatfits)
- [Layout](https://developer.apple.com/documentation/swiftui/layout)

Use adaptive layouts rather than:

```swift
if screenWidth > 390 { ... }
```

Prefer size classes, container-relative sizing, adaptive grids, and flexible layouts.

Apple specifically recommends avoiding hard-coded window sizes for the new resizable environments. [WWDC26 SwiftUI Group Lab](https://developer.apple.com/videos/play/wwdc2026/8120/)

---

# 9. Safe areas

Use:

- [safeAreaInset](https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:))
- [safeAreaPadding](https://developer.apple.com/documentation/swiftui/view/safeareapadding(_:_:))
- [ignoresSafeArea](https://developer.apple.com/documentation/swiftui/view/ignoressafearea(_:edges:))
- [containerRelativeFrame](https://developer.apple.com/documentation/swiftui/view/containerrelativeframe(_:alignment:))
- [containerRelativeShape](https://developer.apple.com/documentation/swiftui/containerrelativeshape)

Do not assume every iPhone has the same usable content rectangle.

---

# 10. Scrolling

Use:

- [ScrollView](https://developer.apple.com/documentation/swiftui/scrollview)
- [ScrollViewReader](https://developer.apple.com/documentation/swiftui/scrollviewreader)
- [scrollPosition](https://developer.apple.com/documentation/swiftui/view/scrollposition(_:anchor:))
- [scrollTargetBehavior](https://developer.apple.com/documentation/swiftui/view/scrolltargetbehavior(_:))
- [scrollTransition](https://developer.apple.com/documentation/swiftui/view/scrolltransition(_:axis:transition:))
- [scrollContentBackground](https://developer.apple.com/documentation/swiftui/view/scrollcontentbackground(_:))
- [scrollEdgeEffectStyle](https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:))

---

# 11. Lists and custom collections

Use:

- [List](https://developer.apple.com/documentation/swiftui/list)
- [Section](https://developer.apple.com/documentation/swiftui/section)
- [LazyVStack](https://developer.apple.com/documentation/swiftui/lazyvstack)
- [LazyVGrid](https://developer.apple.com/documentation/swiftui/lazyvgrid)
- [Table](https://developer.apple.com/documentation/swiftui/table)

## iOS 27: reordering anywhere

Newer SwiftUI supports reordering beyond `List`.

Look at:

- `reorderable()`
- `reorderContainer(...)`

Apple says these APIs work across containers such as lists and grids and provide the lift/drop animations.

- [What's New in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/)
- [SwiftUI What's New](https://developer.apple.com/swiftui/whats-new/)

---

# 12. Buttons

Core:

- [Button](https://developer.apple.com/documentation/swiftui/button)
- [ButtonStyle](https://developer.apple.com/documentation/swiftui/buttonstyle)
- [PrimitiveButtonStyle](https://developer.apple.com/documentation/swiftui/primitivebuttonstyle)
- [buttonStyle](https://developer.apple.com/documentation/swiftui/view/buttonstyle(_:))

## Liquid Glass buttons

For a native Liquid Glass button, prefer Apple's button styles rather than placing a raw glass effect behind a button.

- [GlassButtonStyle](https://developer.apple.com/documentation/swiftui/glassbuttonstyle)
- [GlassProminentButtonStyle](https://developer.apple.com/documentation/swiftui/glassprominentbuttonstyle)

Apple's SwiftUI team specifically recommends `glassButtonStyle` / `glassProminent` for glass buttons rather than simply putting `.glassEffect()` on the button. [WWDC26 SwiftUI Group Lab](https://developer.apple.com/videos/play/wwdc2026/8120/)

---

# 13. Button morphing / Liquid Glass morphing

This is one of the most important sections for the type of UI you're describing.

Liquid Glass supports:

```text
View A
   ↓
animation
   ↓
View B
```

where the glass shapes can physically morph rather than simply fade.

Core APIs:

- `GlassEffectContainer`
- `.glassEffect()`
- `.glassEffectID(_:in:)`
- `.glassEffectTransition(...)`
- `GlassEffectTransition`
- `.glassEffectUnion(...)`
- `.buttonStyle(.glass)`
- `.buttonStyle(.glassProminent)`

Official docs:

- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- [Liquid Glass](https://developer.apple.com/documentation/swiftui/liquid-glass)
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)
- [GlassEffectTransition](https://developer.apple.com/documentation/swiftui/glasseffecttransition)
- [glassEffect](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))

### Example architecture

```swift
@Namespace private var glassNamespace
@State private var expanded = false

GlassEffectContainer(spacing: 40) {
    HStack(spacing: 40) {
        Button {
            withAnimation {
                expanded.toggle()
            }
        } label: {
            Image(systemName: "plus")
        }
        .buttonStyle(.glass)
        .glassEffectID("mainButton", in: glassNamespace)

        if expanded {
            Button("Edit") {}
                .buttonStyle(.glass)
                .glassEffectID("edit", in: glassNamespace)

            Button("Delete") {}
                .buttonStyle(.glass)
                .glassEffectID("delete", in: glassNamespace)
        }
    }
}
```

Apple documents `GlassEffectContainer` as the mechanism for combining multiple glass shapes and morphing them during transitions. [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)

---

# 14. Liquid Glass unions

For multiple glass elements that should behave as one logical shape:

- [glassEffectUnion](https://developer.apple.com/documentation/swiftui/view/glasseffectunion(id:namespace:))
- [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer)

Use this when controls visually merge into a shared glass surface.

---

# 15. Interactive Liquid Glass

For glass that responds to touch/pointer interaction:

```swift
.glassEffect(.regular.interactive())
```

See:

- [Applying Liquid Glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)

---

# 16. Liquid Glass design rule

Do NOT put glass everywhere.

Apple's guidance is:

```text
CONTENT
   ↓
simple/flat
   ↓
CONTROLS + NAVIGATION
   ↓
Liquid Glass
```

Standard SwiftUI controls, navigation bars, sheets, popovers and toolbars already receive system Liquid Glass treatment on supported releases.

Avoid custom backgrounds that fight the system glass.

- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Applying Liquid Glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)

---

# 17. Navigation morphing / hero transitions

For:

```text
Card
 ↓ tap
Card expands
 ↓
Detail page
```

use Apple's navigation transition APIs.

Core:

- `@Namespace`
- `.matchedTransitionSource(id:in:)`
- `.navigationTransition(...)`
- `.zoom(sourceID:in:)`

Docs:

- [navigationTransition](https://developer.apple.com/documentation/swiftui/view/navigationtransition(_:))
- [ZoomNavigationTransition](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition)
- [matchedTransitionSource](https://developer.apple.com/documentation/swiftui/view/matchedtransitionsource(id:in:))
- [Animations and transitions](https://developer.apple.com/documentation/swiftui/animations)

### Example

```swift
@Namespace private var namespace

NavigationStack {
    NavigationLink {
        DetailView()
            .navigationTransition(
                .zoom(sourceID: "product", in: namespace)
            )
    } label: {
        ProductCard()
            .matchedTransitionSource(
                id: "product",
                in: namespace
            )
    }
}
```

Apple's own Wishlist sample uses this pattern to make a card smoothly zoom into a detail screen while interpolating position, size, and corner radius.

- [Wishlist: Planning travel in a SwiftUI app](https://developer.apple.com/documentation/swiftui/wishlist-planning-travel-in-a-swiftui-app)
- [ZoomNavigationTransition](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition)

---

# 18. Navigation transition choices

Current built-in transition concepts include:

- `.automatic`
- `.zoom(sourceID:in:)`
- `.crossFade` where available

Docs:

- [NavigationTransition](https://developer.apple.com/documentation/swiftui/navigationtransition)
- [ZoomNavigationTransition](https://developer.apple.com/documentation/swiftui/zoomnavigationtransition)
- [navigationTransition](https://developer.apple.com/documentation/swiftui/view/navigationtransition(_:))

Do not build a custom hero-animation engine before checking these APIs.

---

# 19. matchedGeometryEffect

For custom view-to-view geometry continuity:

- [matchedGeometryEffect](https://developer.apple.com/documentation/swiftui/view/matchedgeometryeffect(id:in:properties:anchor:isactivematch:))

Use it for:

```text
small card → large card
icon → icon
thumbnail → hero image
compact control → expanded control
```

For navigation specifically, prefer the newer `matchedTransitionSource` + `navigationTransition` APIs when they fit.

---

# 20. General animations

- [Animation](https://developer.apple.com/documentation/swiftui/animation)
- [withAnimation](https://developer.apple.com/documentation/swiftui/withanimation(_:_:))
- [transition](https://developer.apple.com/documentation/swiftui/view/transition(_:))
- [contentTransition](https://developer.apple.com/documentation/swiftui/view/contenttransition(_:))
- [PhaseAnimator](https://developer.apple.com/documentation/swiftui/phaseanimator(_:content:animation:))
- [KeyframeAnimator](https://developer.apple.com/documentation/swiftui/keyframeanimator(initialvalue:trigger:content:keyframes:))
- [symbolEffect](https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:value:))
- [sensoryFeedback](https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(_:trigger:))

---

# 21. Sheets

Use:

```swift
.sheet(isPresented: $show) {
    SheetView()
}
```

Docs:

- [Modal presentations](https://developer.apple.com/documentation/swiftui/modal-presentations)
- [sheet](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:))
- [sheet(item:onDismiss:content:)](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:))

---

# 22. Sheet heights

Use:

- `.presentationDetents([.medium, .large])`
- `.height(...)`
- `.fraction(...)`
- custom `PresentationDetent`

Docs:

- [presentationDetents](https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:))
- [PresentationDetent](https://developer.apple.com/documentation/swiftui/presentationdetent)

---

# 23. Sheet styling

Use:

- `.presentationBackground(...)`
- `.presentationCornerRadius(...)`
- `.presentationDragIndicator(...)`
- `.presentationBackgroundInteraction(...)`
- `.presentationContentInteraction(...)`
- `.interactiveDismissDisabled(...)`

Docs:

- [Modal presentations](https://developer.apple.com/documentation/swiftui/modal-presentations)

Apple's current Liquid Glass design gives sheets increased corner radius and inset half-sheet behavior on supported releases. [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)

---

# 24. Full-screen presentation

```swift
.fullScreenCover(isPresented: $show) {
    FullScreenView()
}
```

- [fullScreenCover](https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:))

---

# 25. Popovers

```swift
.popover(isPresented: $show) {
    CardView()
}
```

- [popover](https://developer.apple.com/documentation/swiftui/view/popover(ispresented:attachmentanchor:arrowedge:content:))

---

# 26. Alerts

- [alert](https://developer.apple.com/documentation/swiftui/view/alert(ispresented:content:))

Current SwiftUI supports Boolean, item, data-driven, message, and error-based alert APIs.

---

# 27. Confirmation dialogs

- [confirmationDialog](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(ispresented:titlevisibility:actions:))

The current presentation APIs also support item-driven confirmation dialogs.

Apple's 2027 SwiftUI release aligns confirmation-dialog and alert presentation with the item-binding pattern already used by sheets. [What's New in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/)

---

# 28. Inspector

For iPad/Mac inspector-style UI:

- [inspector](https://developer.apple.com/documentation/swiftui/view/inspector(ispresented:content:))
- [inspectorColumnWidth](https://developer.apple.com/documentation/swiftui/view/inspectorcolumnwidth(_:))

---

# 29. The Apple Pay sheet

Do NOT recreate this in SwiftUI.

Use:

- [PassKit](https://developer.apple.com/documentation/passkit)
- [PKPaymentAuthorizationController](https://developer.apple.com/documentation/passkit/pkpaymentauthorizationcontroller)
- [PKPaymentRequest](https://developer.apple.com/documentation/passkit/pkpaymentrequest)
- [PKPaymentButton](https://developer.apple.com/documentation/passkit/pkpaymentbutton)

System payment flow:

```text
Your UI
 ↓
Apple Pay button
 ↓
PassKit
 ↓
Apple Pay system sheet
 ↓
Face ID / Touch ID
 ↓
Payment authorization
```

---

# 30. StoreKit purchase UI

For App Store subscriptions/in-app purchases:

- [StoreKit](https://developer.apple.com/documentation/storekit)
- [Product](https://developer.apple.com/documentation/storekit/product)
- [ProductView](https://developer.apple.com/documentation/storekit/productview)
- [StoreView](https://developer.apple.com/documentation/storekit/storeview)
- [SubscriptionStoreView](https://developer.apple.com/documentation/storekit/subscriptionstoreview)
- [offerCodeRedemption](https://developer.apple.com/documentation/swiftui/view/offercoderedemption(options:ispresented:oncompletion:))

---

# 31. Photos / Files / Quick Look

Photos:

- [PhotosPicker](https://developer.apple.com/documentation/photosui/photospicker)
- [PhotosUI](https://developer.apple.com/documentation/photosui)

Files:

- [fileImporter](https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:allowsmultipleselection:oncompletion:))
- [fileExporter](https://developer.apple.com/documentation/swiftui/view/fileexporter(ispresented:document:contenttype:defaultfilename:oncompletion:))
- [fileMover](https://developer.apple.com/documentation/swiftui/view/filemover(ispresented:file:oncompletion:))

Preview:

- [quickLookPreview](https://developer.apple.com/documentation/swiftui/view/quicklookpreview(_:))
- [Quick Look](https://developer.apple.com/documentation/quicklook)

---

# 32. State architecture

For modern projects:

```text
View
 ↓
@State / @Binding
 ↓
@Observable model
 ↓
Service / repository
 ↓
SwiftData / API
```

Read:

- [Observation](https://developer.apple.com/documentation/observation)
- [Observable](https://developer.apple.com/documentation/observation/observable())
- [State](https://developer.apple.com/documentation/swiftui/state)
- [Binding](https://developer.apple.com/documentation/swiftui/binding)
- [Bindable](https://developer.apple.com/documentation/swiftui/bindable)
- [Environment](https://developer.apple.com/documentation/swiftui/environment)

---

# 33. iOS 27 `@State` / data-flow changes

Apple's 2027 release notes explain that `State` has become a macro and classes stored in `@State` can initialize lazily, reducing redundant allocations.

Also see:

- [What's New in SwiftUI](https://developer.apple.com/swiftui/whats-new/)
- [WWDC26 What's New in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/)

---

# 34. SwiftData

Use when local persistence fits your app.

- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [Model](https://developer.apple.com/documentation/swiftdata/model())
- [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)
- [ModelContext](https://developer.apple.com/documentation/swiftdata/modelcontext)
- [Query](https://developer.apple.com/documentation/swiftdata/query)
- [FetchDescriptor](https://developer.apple.com/documentation/swiftdata/fetchdescriptor)
- [Predicate](https://developer.apple.com/documentation/swiftdata/predicate)
- [Relationship](https://developer.apple.com/documentation/swiftdata/relationship)
- [Attribute](https://developer.apple.com/documentation/swiftdata/attribute)

---

# 35. Networking

SwiftUI UI:

```swift
.task {
    await viewModel.load()
}
```

Foundation layer:

- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)
- [Swift Concurrency](https://developer.apple.com/documentation/swift/concurrency)
- [Task](https://developer.apple.com/documentation/swift/task)
- [MainActor](https://developer.apple.com/documentation/swift/mainactor)

SwiftUI integration:

- [task](https://developer.apple.com/documentation/swiftui/view/task(priority:_:))
- [refreshable](https://developer.apple.com/documentation/swiftui/view/refreshable(action:))

---

# 36. AsyncImage — iOS 27 improvements

The current SwiftUI release adds standard HTTP caching behavior to `AsyncImage`.

Newer control includes:

- `asyncImageURLSession(_:)`
- request-based initializers

- [SwiftUI Updates](https://developer.apple.com/documentation/updates/swiftui)
- [AsyncImage](https://developer.apple.com/documentation/swiftui/asyncimage)

---

# 37. Forms and input

- [TextField](https://developer.apple.com/documentation/swiftui/textfield)
- [SecureField](https://developer.apple.com/documentation/swiftui/securefield)
- [TextEditor](https://developer.apple.com/documentation/swiftui/texteditor)
- [Toggle](https://developer.apple.com/documentation/swiftui/toggle)
- [Picker](https://developer.apple.com/documentation/swiftui/picker)
- [DatePicker](https://developer.apple.com/documentation/swiftui/datepicker)
- [MultiDatePicker](https://developer.apple.com/documentation/swiftui/multidatepicker)
- [ColorPicker](https://developer.apple.com/documentation/swiftui/colorpicker)
- [Slider](https://developer.apple.com/documentation/swiftui/slider)
- [Stepper](https://developer.apple.com/documentation/swiftui/stepper)
- [Form](https://developer.apple.com/documentation/swiftui/form)

---

# 38. Keyboard / focus

- [FocusState](https://developer.apple.com/documentation/swiftui/focusstate)
- [FocusedValue](https://developer.apple.com/documentation/swiftui/focusedvalue)
- [FocusedBinding](https://developer.apple.com/documentation/swiftui/focusedbinding)
- [focused](https://developer.apple.com/documentation/swiftui/view/focused(_:equals:))
- [defaultFocus](https://developer.apple.com/documentation/swiftui/view/defaultfocus(_:_:))
- [onSubmit](https://developer.apple.com/documentation/swiftui/view/onsubmit(of:_:))
- [submitLabel](https://developer.apple.com/documentation/swiftui/view/submitlabel(_:))
- [scrollDismissesKeyboard](https://developer.apple.com/documentation/swiftui/view/scrolldismisseskeyboard(_:))

---

# 39. Gestures

- [Gestures](https://developer.apple.com/documentation/swiftui/gestures)
- [TapGesture](https://developer.apple.com/documentation/swiftui/tapgesture)
- [LongPressGesture](https://developer.apple.com/documentation/swiftui/longpressgesture)
- [DragGesture](https://developer.apple.com/documentation/swiftui/draggesture)
- [MagnifyGesture](https://developer.apple.com/documentation/swiftui/magnifygesture)
- [RotateGesture](https://developer.apple.com/documentation/swiftui/rotategesture)
- [SpatialTapGesture](https://developer.apple.com/documentation/swiftui/spatialtapgesture)
- [SpatialLongPressGesture](https://developer.apple.com/documentation/swiftui/spatiallongpressgesture)

---

# 40. iOS 27 swipe actions on arbitrary views

Previously, swipe actions were strongly associated with `List`.

Current SwiftUI adds:

```text
.swipeActions()
.swipeActionsContainer()
```

so custom rows inside scroll views can participate.

- [What's New in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/)
- [SwiftUI What's New](https://developer.apple.com/swiftui/whats-new/)

Architecture:

```text
ScrollView
 └── LazyVStack
      ├── Row
      │    └── swipeActions
      ├── Row
      │    └── swipeActions
      └── Row
           └── swipeActions

      + swipeActionsContainer()
```

---

# 41. Context menus

- [contextMenu](https://developer.apple.com/documentation/swiftui/view/contextmenu(menuitems:))
- [Menu](https://developer.apple.com/documentation/swiftui/menu)
- [confirmationDialog](https://developer.apple.com/documentation/swiftui/view/confirmationdialog(ispresented:titlevisibility:actions:))

---

# 42. Toolbar architecture

Toolbar is now much more important because of resizable iPhone/iPad/Mac environments.

Use:

- [toolbar](https://developer.apple.com/documentation/swiftui/view/toolbar(content:))
- [ToolbarItem](https://developer.apple.com/documentation/swiftui/toolbaritem)
- [ToolbarItemGroup](https://developer.apple.com/documentation/swiftui/toolbaritemgroup)
- [ToolbarSpacer](https://developer.apple.com/documentation/swiftui/toolbarspacer)
- [ToolbarContent](https://developer.apple.com/documentation/swiftui/toolbarcontent)

---

# 43. iOS 27 toolbar visibility priority

Use:

```swift
ToolbarItemGroup {
    UndoButton()
    RedoButton()
}
.visibilityPriority(.high)
```

This tells SwiftUI which actions matter most when space becomes limited.

- [ToolbarContent](https://developer.apple.com/documentation/swiftui/toolbarcontent)
- [What's New in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/)

---

# 44. Toolbar overflow menu

Use:

```swift
ToolbarOverflowMenu {
    DeleteButton()
    ExportButton()
}
```

Use this for secondary actions that should not compete with the primary actions.

- [What's New in SwiftUI](https://developer.apple.com/swiftui/whats-new/)
- [WWDC26 What's New](https://developer.apple.com/videos/play/wwdc2026/269/)

---

# 45. Pinned trailing toolbar actions

For critical actions such as Share:

```swift
ToolbarItem(placement: .topBarPinnedTrailing) {
    ShareButton()
}
```

Apple added this specifically for resizable layouts.

- [What's New in SwiftUI](https://developer.apple.com/swiftui/whats-new/)
- [WWDC26 What's New](https://developer.apple.com/videos/play/wwdc2026/269/)

---

# 46. Toolbar minimization

Current API:

```swift
.toolbarMinimizeBehavior(
    .onScrollDown,
    for: .navigationBar
)
```

This lets the navigation bar minimize as the user scrolls.

- [SwiftUI Updates](https://developer.apple.com/documentation/updates/swiftui)
- [WWDC26 What's New](https://developer.apple.com/videos/play/wwdc2026/269/)

---

# 47. Toolbar transition sources

Toolbar content can participate in matched navigation transitions:

- [matchedTransitionSource](https://developer.apple.com/documentation/swiftui/toolbarcontent/matchedtransitionsource(id:in:))
- [ToolbarContent](https://developer.apple.com/documentation/swiftui/toolbarcontent)

This allows a toolbar button to be the source of a zoom-style presentation.

---

# 48. Search

- [searchable](https://developer.apple.com/documentation/swiftui/view/searchable(text:placement:prompt:))
- [searchSuggestions](https://developer.apple.com/documentation/swiftui/view/searchsuggestions(_:))
- [searchScopes](https://developer.apple.com/documentation/swiftui/view/searchscopes(_:scopes:))
- [Search](https://developer.apple.com/documentation/swiftui/search)

---

# 49. SF Symbols

- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Image(systemName:)](https://developer.apple.com/documentation/swiftui/image/init(systemname:))
- [symbolRenderingMode](https://developer.apple.com/documentation/swiftui/view/symbolrenderingmode(_:))
- [symbolVariant](https://developer.apple.com/documentation/swiftui/view/symbolvariant(_:))
- [symbolEffect](https://developer.apple.com/documentation/swiftui/view/symboleffect(_:options:value:))

---

# 50. Haptics / sensory feedback

- [sensoryFeedback](https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(_:trigger:))

Use subtle feedback for:

```text
successful save
toggle
delete
selection
completion
important confirmation
```

Do not add haptics to every tap.

---

# 51. Accessibility

Every custom component should support:

- [Accessibility](https://developer.apple.com/documentation/swiftui/accessibility)
- [accessibilityLabel](https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:))
- [accessibilityValue](https://developer.apple.com/documentation/swiftui/view/accessibilityvalue(_:))
- [accessibilityHint](https://developer.apple.com/documentation/swiftui/view/accessibilityhint(_:))
- [accessibilityAddTraits](https://developer.apple.com/documentation/swiftui/view/accessibilityaddtraits(_:))
- [accessibilityHidden](https://developer.apple.com/documentation/swiftui/view/accessibilityhidden(_:))
- [Dynamic Type](https://developer.apple.com/documentation/swiftui/dynamic-type)

Do not make text unreadable just to match a screenshot.

---

# 52. Localization

- [Localization](https://developer.apple.com/documentation/swiftui/localization)
- [LocalizedStringKey](https://developer.apple.com/documentation/swiftui/localizedstringkey)
- [LocalizedStringResource](https://developer.apple.com/documentation/foundation/localizedstringresource)
- [String(localized:)](https://developer.apple.com/documentation/foundation/string/init(localized:))

Build layouts that survive longer translated strings.

---

# 53. Drag and drop

- [CoreTransferable](https://developer.apple.com/documentation/coretransferable)
- [Transferable](https://developer.apple.com/documentation/coretransferable/transferable)
- [draggable](https://developer.apple.com/documentation/swiftui/view/draggable(_:))
- [dropDestination](https://developer.apple.com/documentation/swiftui/view/dropdestination(for:action:isallowed:))

---

# 54. Sharing

- [ShareLink](https://developer.apple.com/documentation/swiftui/sharelink)
- [SharePreview](https://developer.apple.com/documentation/swiftui/sharepreview)

---

# 55. Authentication

- [AuthenticationServices](https://developer.apple.com/documentation/authenticationservices)
- [Sign in with Apple](https://developer.apple.com/sign-in-with-apple/)
- [ASAuthorizationController](https://developer.apple.com/documentation/authenticationservices/asauthorizationcontroller)
- [LocalAuthentication](https://developer.apple.com/documentation/localauthentication)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain-services)

---

# 56. Notifications

- [UserNotifications](https://developer.apple.com/documentation/usernotifications)
- [UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter)

---

# 57. Widgets

- [WidgetKit](https://developer.apple.com/documentation/widgetkit)
- [Widget](https://developer.apple.com/documentation/widgetkit/widget)
- [WidgetBundle](https://developer.apple.com/documentation/widgetkit/widgetbundle)

---

# 58. Live Activities

- [ActivityKit](https://developer.apple.com/documentation/activitykit)
- [Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)

---

# 59. App Intents / Siri / Apple Intelligence

- [App Intents](https://developer.apple.com/documentation/appintents)
- [AppIntent](https://developer.apple.com/documentation/appintents/appintent)
- [AppShortcutsProvider](https://developer.apple.com/documentation/appintents/appshortcutsprovider)
- [Siri](https://developer.apple.com/siri/)

The current Apple platform releases also introduce deeper integration between app context, Siri, and Apple Intelligence. See Apple's 2026 platform sessions before implementing custom integration.

- [Platforms State of the Union — WWDC26](https://developer.apple.com/videos/play/wwdc2026/102/)
- [Modernize your UIKit app — WWDC26](https://developer.apple.com/videos/play/wwdc2026/278/)

---

# 60. Maps

- [MapKit](https://developer.apple.com/documentation/mapkit)
- [Map](https://developer.apple.com/documentation/mapkit/map)
- [MapCameraPosition](https://developer.apple.com/documentation/mapkit/mapcameraposition)
- [Marker](https://developer.apple.com/documentation/mapkit/marker)
- [UserAnnotation](https://developer.apple.com/documentation/mapkit/userannotation)
- [Core Location](https://developer.apple.com/documentation/corelocation)

---

# 61. Web

- [WebKit](https://developer.apple.com/documentation/webkit)
- [SafariServices](https://developer.apple.com/documentation/safariservices)
- [WKWebView](https://developer.apple.com/documentation/webkit/wkwebview)
- [SFSafariViewController](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller)

---

# 62. UIKit/AppKit bridging

Only bridge when needed.

iOS:

- [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)
- [UIViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/uiviewcontrollerrepresentable)
- [UIHostingController](https://developer.apple.com/documentation/swiftui/uihostingcontroller)

macOS:

- [NSViewRepresentable](https://developer.apple.com/documentation/swiftui/nsviewrepresentable)
- [NSViewControllerRepresentable](https://developer.apple.com/documentation/swiftui/nsviewcontrollerrepresentable)
- [NSHostingController](https://developer.apple.com/documentation/swiftui/nshostingcontroller)

---

# 63. Resizability — critical for iOS 27

Do not assume:

```text
iPhone = fixed portrait rectangle
```

The current platform direction is toward fluid resizing and more environments.

Build for:

```text
portrait
landscape
iPhone Mirroring
iPhone on iPad
iPad multitasking
external displays
Mac
Mac Catalyst where applicable
```

Apple's 2026 SwiftUI sessions explicitly recommend adaptive layouts, size classes, and flexible containers rather than hard-coded screen sizes.

- [WWDC26 SwiftUI Group Lab](https://developer.apple.com/videos/play/wwdc2026/8120/)
- [Modernize your UIKit app](https://developer.apple.com/videos/play/wwdc2026/278/)

---

# 64. Environment values for adaptivity

Important values include:

- `horizontalSizeClass`
- `verticalSizeClass`
- `dynamicTypeSize`
- `colorScheme`
- `controlSize`
- `layoutDirection`
- `scenePhase`
- `redactionReasons`

Docs:

- [EnvironmentValues](https://developer.apple.com/documentation/swiftui/environmentvalues)

---

# 65. Documents — major iOS 27 SwiftUI expansion

For document-based apps, study:

- [DocumentGroup](https://developer.apple.com/documentation/swiftui/documentgroup)
- [FileDocument](https://developer.apple.com/documentation/swiftui/filedocument)
- [ReferenceFileDocument](https://developer.apple.com/documentation/swiftui/referencefiledocument)
- `ReadableDocument`
- `WritableDocument`
- `DocumentReader`
- `DocumentWriter`
- `DocumentCreationSource`
- `NewDocumentButton`
- `URLDocumentConfiguration`

Apple's current SwiftUI guide describes direct URL access, asynchronous incremental reads/writes, progress reporting, and custom document creation sources.

- [WWDC26 SwiftUI Guide](https://developer.apple.com/wwdc26/guides/swiftui/)
- [SwiftUI Updates](https://developer.apple.com/documentation/updates/swiftui)

---

# 66. Performance

Use:

- lazy containers
- stable IDs
- Observation
- async/await
- cached images
- Instruments
- Xcode previews
- appropriate task cancellation

Read:

- [Performance analysis](https://developer.apple.com/documentation/xcode/performance-analysis)
- [Instruments](https://developer.apple.com/documentation/instruments)
- [SwiftUI What's New](https://developer.apple.com/swiftui/whats-new/)

---

# 67. Testing

- [Swift Testing](https://developer.apple.com/documentation/testing)
- [XCTest](https://developer.apple.com/documentation/xctest)
- [Xcode Previews](https://developer.apple.com/documentation/xcode/previewing-your-apps-interface)
- [Accessibility Inspector](https://developer.apple.com/documentation/accessibility/accessibility-inspector)
- [Instruments](https://developer.apple.com/documentation/instruments)

Test:

```text
empty state
loading
error
offline
slow network
large Dynamic Type
VoiceOver
light/dark
different languages
small width
large width
landscape
iPad
iPhone Mirroring
```

---

# 68. Production app folder structure

A useful structure:

```text
MyApp/
│
├── App/
│   ├── MyApp.swift
│   ├── AppRouter.swift
│   └── AppEnvironment.swift
│
├── DesignSystem/
│   ├── Typography.swift
│   ├── Colors.swift
│   ├── Spacing.swift
│   ├── Radii.swift
│   ├── Motion.swift
│   ├── Glass.swift
│   └── Components/
│
├── Features/
│   ├── Home/
│   ├── Search/
│   ├── Detail/
│   ├── Account/
│   └── Settings/
│
├── Models/
│
├── Services/
│   ├── API/
│   ├── Authentication/
│   ├── Payments/
│   └── Notifications/
│
├── Persistence/
│   └── SwiftData/
│
├── Navigation/
│   ├── Routes.swift
│   └── AppRouter.swift
│
├── Resources/
│   ├── Assets.xcassets
│   └── Localizations/
│
├── Widgets/
│
├── LiveActivities/
│
├── AppIntents/
│
└── Tests/
```

---

# 69. The animation hierarchy

Use this priority:

```text
1. System animation
       ↓
2. SwiftUI built-in transition
       ↓
3. navigationTransition
       ↓
4. Liquid Glass morphing
       ↓
5. matchedGeometryEffect
       ↓
6. custom transition / keyframes
```

Do not immediately build custom geometry math.

---

# 70. The presentation hierarchy

Use this decision tree:

```text
Is this a system-owned experience?
│
├── YES → use Apple's framework
│         Apple Pay / StoreKit / Photos / Files / Quick Look
│
└── NO
    │
    ├── Small focused choice → alert / confirmationDialog
    │
    ├── Focused task → sheet
    │
    ├── Entire task → fullScreenCover
    │
    ├── Anchored contextual content → popover
    │
    ├── iPad/Mac editing controls → inspector
    │
    └── Navigation destination → NavigationStack
```

---

# 71. The navigation animation hierarchy

For a card opening into a page:

```text
Card
 ↓
matchedTransitionSource
 ↓
NavigationLink
 ↓
navigationTransition(.zoom)
 ↓
Detail
```

For Liquid Glass controls:

```text
GlassEffectContainer
 ↓
glassEffect
 ↓
glassEffectID
 ↓
withAnimation
 ↓
GlassEffectTransition
```

For generic custom geometry:

```text
matchedGeometryEffect
```

---

# 72. The Liquid Glass hierarchy

Use:

```text
SYSTEM UI
│
├── Toolbar
├── Navigation
├── Tabs
├── Sheets
└── Popovers
       ↓
     automatic Liquid Glass

CUSTOM CONTROLS
│
├── Button
├── Capsule
├── Floating control
└── Custom toolbar control
       ↓
GlassButtonStyle / glassEffect
       ↓
GlassEffectContainer
       ↓
glassEffectID
       ↓
morphing transition
```

Official:

- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Applying Liquid Glass](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)

---

# 73. What NOT to build yourself

Do not manually reproduce:

```text
Apple Pay sheet
Apple StoreKit purchase sheet
System photo picker
System file picker
Quick Look
System alerts
System confirmation dialogs
Standard navigation behavior
Standard Liquid Glass toolbar
Standard tab bar
```

Use Apple's framework/API and let the OS own the behavior.

---

# 74. What you SHOULD build yourself

These are where your app's identity belongs:

```text
Brand
 ↓
Color system
 ↓
Typography
 ↓
Cards
 ↓
Content layout
 ↓
Custom controls
 ↓
Feature-specific interactions
 ↓
Custom data visualization
 ↓
Custom Liquid Glass components
 ↓
App-specific transitions
```

---

# 75. AI coding-agent instruction

Paste this into an AI coding agent when starting the project:

```text
Build this app using the latest Apple-native SwiftUI APIs available in the
target SDK.

Use Apple's current SwiftUI navigation architecture:
NavigationStack, NavigationSplitView, TabView, NavigationPath,
navigationDestination.

Use Apple's native presentation APIs:
sheet, fullScreenCover, popover, alert, confirmationDialog, inspector,
presentationDetents, presentationSizing, presentationBackground,
presentationCornerRadius, presentationDragIndicator.

Use Apple's current Liquid Glass APIs on supported SDKs:
glassEffect, GlassEffectContainer, glassEffectID,
glassEffectTransition, glassEffectUnion, GlassButtonStyle,
GlassProminentButtonStyle.

For card-to-detail and source-to-destination animations, use:
matchedTransitionSource + navigationTransition(.zoom(...))
when appropriate.

For Liquid Glass shape morphing, use:
GlassEffectContainer + glassEffectID + GlassEffectTransition.

Do not fake Apple system UI:
use PassKit for Apple Pay,
StoreKit for App Store purchases,
PhotosUI for photo picking,
fileImporter/fileExporter for Files,
Quick Look for previews,
MapKit for maps,
AuthenticationServices for Sign in with Apple,
LocalAuthentication for biometrics.

Use Swift Observation for new state architecture where supported.
Use SwiftData for local persistence when appropriate.
Use async/await and URLSession for networking.

Do not hard-code screen sizes.
Design for arbitrary window sizes, size classes, iPhone Mirroring,
iPad, landscape, and Mac where applicable.

Use Dynamic Type and accessibility.
Use system fonts and SF Symbols unless a custom design explicitly requires
otherwise.

Prefer system animations and transitions before custom animation code.

Do not recreate Liquid Glass with arbitrary blur backgrounds if the native
Liquid Glass API can provide the effect.

Do not use deprecated NavigationView for new architecture.

Before implementing an API, verify its availability in the target SDK and
consult Apple's official Developer Documentation.
```

---

# 76. Official current SwiftUI resources

- [Complete SwiftUI API](https://developer.apple.com/documentation/swiftui)
- [SwiftUI What's New](https://developer.apple.com/swiftui/whats-new/)
- [SwiftUI Updates](https://developer.apple.com/documentation/updates/swiftui)
- [WWDC26 SwiftUI Guide](https://developer.apple.com/wwdc26/guides/swiftui/)
- [What's New in SwiftUI — WWDC26](https://developer.apple.com/videos/play/wwdc2026/269/)
- [SwiftUI Group Lab — WWDC26](https://developer.apple.com/videos/play/wwdc2026/8120/)
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [Navigation](https://developer.apple.com/documentation/swiftui/navigation)
- [Modal presentations](https://developer.apple.com/documentation/swiftui/modal-presentations)
- [Animations](https://developer.apple.com/documentation/swiftui/animations)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Apple Design Resources](https://developer.apple.com/design/resources/)

---

# 77. Version policy

## iOS 27 / Xcode 27

This document includes the current public 2027-release SwiftUI additions documented by Apple, including:

- refreshed Liquid Glass behavior
- Liquid Glass morphing
- `GlassEffectContainer`
- `glassEffectID`
- navigation zoom transitions
- toolbar visibility priority
- `ToolbarOverflowMenu`
- `topBarPinnedTrailing`
- `toolbarMinimizeBehavior`
- prominent tab role
- arbitrary-view swipe actions
- `swipeActionsContainer`
- generalized reorderable containers
- expanded document APIs
- improved `AsyncImage` caching
- newer Observation/`@State` behavior
- expanded presentation and interaction APIs

Sources:

- [WWDC26 What's New in SwiftUI](https://developer.apple.com/videos/play/wwdc2026/269/)
- [WWDC26 SwiftUI Guide](https://developer.apple.com/wwdc26/guides/swiftui/)
- [SwiftUI What's New](https://developer.apple.com/swiftui/whats-new/)

## iOS 28

**Do not treat iOS 28 as having a public SwiftUI API set yet.**

At the time this document was updated, Apple's public current material is the **iOS 27 / 2027-release generation**. Any supposed "iOS 28 SwiftUI API list" would be speculation unless Apple has published that SDK/documentation.

When the next SDK is released, update this section from:

- [SwiftUI Updates](https://developer.apple.com/documentation/updates/swiftui)
- [SwiftUI What's New](https://developer.apple.com/swiftui/whats-new/)
- [Apple Developer Videos](https://developer.apple.com/videos/)
- [SwiftUI API Reference](https://developer.apple.com/documentation/swiftui)

---

# 78. Final build checklist

Before calling an app "finished":

## Architecture

- [ ] App lifecycle
- [ ] Root navigation
- [ ] Route model
- [ ] Feature modules
- [ ] Dependency injection
- [ ] State architecture

## Design

- [ ] Typography
- [ ] Colors
- [ ] Spacing
- [ ] Radius
- [ ] SF Symbols
- [ ] Light mode
- [ ] Dark mode
- [ ] Liquid Glass
- [ ] Dynamic Type

## Navigation

- [ ] TabView
- [ ] NavigationStack
- [ ] NavigationSplitView where needed
- [ ] Deep links
- [ ] State restoration
- [ ] Zoom transitions
- [ ] Matched transition sources

## Interaction

- [ ] Buttons
- [ ] Menus
- [ ] Context menus
- [ ] Gestures
- [ ] Swipe actions
- [ ] Reordering
- [ ] Haptics
- [ ] Keyboard/focus

## Presentation

- [ ] Sheet
- [ ] Detents
- [ ] Full screen
- [ ] Popover
- [ ] Alert
- [ ] Confirmation dialog
- [ ] Inspector
- [ ] Presentation transitions

## System integrations

- [ ] Apple Pay if needed
- [ ] StoreKit if needed
- [ ] Photos
- [ ] Files
- [Quick Look]
- [Maps
- [Authentication]
- [Notifications]
- [Widgets]
- [Live Activities]
- [App Intents]

## Quality

- [ ] Accessibility
- [ ] Localization
- [ ] Resizable layouts
- [iPhone landscape
- [ ] iPad
- [ ] iPhone Mirroring
- [ ] Mac where applicable
- [ ] Offline/error states
- [ ] Loading states
- [ ] Performance
- [ ] Tests
- [ ] Instruments
- [ ] TestFlight

---

# 79. The single most important rule

**Build with the system, not against it.**

For modern Apple UI:

```text
Native SwiftUI
      +
Adaptive layout
      +
System navigation
      +
Liquid Glass
      +
Native transitions
      +
System presentation
      +
Observation / SwiftData
      +
Accessibility
      +
Platform adaptation
      =
Production-quality Apple app
```

The goal is not to make every pixel custom.

The goal is to make your app feel like it **belongs on the current Apple platform** while your content and product remain uniquely yours.
