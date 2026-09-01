---
name: swiftui-api-reference
description: Complete SwiftUI API reference and architectural guide for iOS, macOS, watchOS, and visionOS. Covers App lifecycle, State & Swift Observation, SwiftData, Layouts, NavigationStack, Sheets & Presentations, Controls, Materials & Liquid Glass, Animation, Phase/Keyframe Animators, Gestures, SF Symbols, Accessibility, and native Apple system frameworks (PassKit, StoreKit, PhotosUI, MapKit, ActivityKit, AppIntents).
---

# SwiftUI API Reference & Architectural Guide

An authoritative, comprehensive API reference and implementation guide for building modern declarative Apple-platform applications in SwiftUI.

---

## 1. App Lifecycle & Scene Hierarchy

### Scene Types & Entry Point
- **`@main struct AppName: App`**: Primary declarative entry point.
- **`WindowGroup`**: Standard window container for single-window iOS/watchOS apps and multi-window macOS/iPadOS/visionOS apps.
- **`DocumentGroup`**: Document-based architecture supporting `FileDocument` and `ReferenceFileDocument`.
- **`Settings`**: Preferences scene on macOS (`Settings { SettingsView() }`).
- **`MenuBarExtra`**: Persistent menu bar app on macOS (`MenuBarExtra("Spendy", systemImage: "dollarsign.circle")`).
- **`ImmersiveSpace`**: visionOS spatial immersion scene.

### Lifecycle & Environment State
```swift
@main
struct SpendyApp: App {
    @State private var appModel = AppModel()
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .modelContainer(for: [Account.self, Transaction.self])
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                appModel.refreshData()
            case .inactive:
                appModel.saveDrafts()
            case .background:
                appModel.scheduleBackgroundSync()
            @unknown default:
                break
            }
        }
    }
}
```

---

## 2. State Management & Data Flow

### Modern Swift Observation (iOS 17+)
| Macro / Property Wrapper | Role & Lifecycle | Scope |
| :--- | :--- | :--- |
| **`@Observable`** | Macro transforming classes into fine-grained observation targets. Only views reading a property will re-render when it mutates. | Models / ViewModels |
| **`@State`** | Instantiates and owns value types or `@Observable` class references. | View-owned source of truth |
| **`@Binding`** | Creates a 2-way reference to state owned higher up in the hierarchy. | Subview parameter |
| **`@Bindable`** | Generates `Binding<T>` projections for properties on an `@Observable` model inside a view. | View-scoped projection |
| **`@Environment`** | Reads shared `@Observable` objects or system values (`\.dismiss`, `\.colorScheme`, `\.locale`). | View subtree |

```swift
// 1. Declare Observable Model
@Observable
final class AccountManager {
    var accounts: [Account] = []
    var selectedAccount: Account?
    var isRefreshing: Bool = false
    
    func addAccount(name: String, balance: Double) {
        accounts.append(Account(name: name, balance: balance))
    }
}

// 2. Consume and Bind in Views
struct AccountDetailView: View {
    @Environment(AccountManager.self) private var manager
    @Bindable var account: Account // Enables $account.name binding
    
    var body: some View {
        Form {
            TextField("Account Name", text: $account.name)
            Toggle("Archived", isOn: $account.isArchived)
        }
    }
}
```

### Persistence with SwiftData
```swift
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var title: String
    var amount: Double
    var date: Date
    @Relationship(deleteRule: .cascade) var category: Category?
    
    init(title: String, amount: Double, date: Date = .now) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.date = date
    }
}

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    var body: some View {
        List(transactions) { tx in
            Text(tx.title)
        }
    }
    
    func delete(transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }
}
```

### Persistent Storage Property Wrappers
- **`@AppStorage("user_currency") var currencyCode: String = "USD"`**: Backed by `UserDefaults`.
- **`@SceneStorage("selected_tab") var selectedTab: Int = 0`**: State restored across app launches per window.

---

## 3. View Composition, Layout & Geometry

### Layout Containers
- **`VStack` / `HStack` / `ZStack`**: Linear stack layout with `alignment` and `spacing`.
- **`LazyVStack` / `LazyHStack`**: Virtualized stacks that allocate rows on demand inside scroll views.
- **`Grid` / `GridRow`**: Structured, column-aligned 2D layout engine.
- **`LazyVGrid` / `LazyHGrid`**: Virtualized grid layouts using `[GridItem(.flexible())]`.
- **`ViewThatFits`**: Evaluates child views in order and picks the first that fits without truncation.
- **`AnyLayout`**: Seamlessly swaps layouts (e.g. `HStack` to `VStack`) based on environment or orientation without destroying view identity.

### Geometry & Sizing Modifiers
```swift
// Responsive Layout switching
let layout = horizontalSizeClass == .regular ? AnyLayout(HStackLayout(spacing: 20)) : AnyLayout(VStackLayout(spacing: 12))
layout {
    CardViewA()
    CardViewB()
}

// Container Relative Frame (iOS 17+)
ScrollView(.horizontal) {
    HStack(spacing: 16) {
        ForEach(cards) { card in
            CardView(card: card)
                .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 16)
        }
    }
}

// Safe Area Custom Insets
.safeAreaInset(edge: .bottom) {
    FloatingActionBar()
}
.ignoresSafeArea(.keyboard, edges: .bottom)
```

---

## 4. ScrollViews, Lists, Forms & Search

### Modern ScrollView Enhancements (iOS 17+)
```swift
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
    .scrollTargetLayout() // Required for item-level scroll snapping
}
.scrollTargetBehavior(.viewAligned) // Snaps to each card/row
.scrollPosition(id: $currentScrolledItemID) // 2-way binding to visible item ID
.scrollBounceBehavior(.basedOnSize) // Disables bounce if content fits
.scrollDismissesKeyboard(.interactively)
```

### Lists, Sections & Swipe Actions
```swift
List {
    Section {
        ForEach(accounts) { account in
            AccountCardRow(account: account)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { delete(account) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button { toggleFavorite(account) } label: {
                        Label("Favorite", systemImage: "star.fill")
                    }
                    .tint(.yellow)
                }
        }
    } header: {
        Text("Bank Accounts")
    } footer: {
        Text("Updated just now")
    }
}
.listStyle(.insetGrouped)
.refreshable { await loadLatestData() }
```

### Search & Filtering
```swift
.searchable(text: $searchQuery, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search transactions...")
.searchScopes($selectedScope) {
    Text("All").tag(SearchScope.all)
    Text("Income").tag(SearchScope.income)
    Text("Expenses").tag(SearchScope.expense)
}
.searchSuggestions {
    Text("Groceries").searchCompletion("Groceries")
    Text("Subscriptions").searchCompletion("Subscriptions")
}
```

---

## 5. Navigation & Presentations

### NavigationStack & Data-Driven Architecture
- **Lightweight Path Invariant**: Always store lightweight identifiers (e.g. `UUID`, enum cases, or route structs) in `NavigationPath` rather than heavy model instances to prevent state bloat and facilitate deep linking.
- **Homogenous vs. Heterogeneous Stacks**:
  - Homogenous (single destination type): Use `@State private var path: [Route] = []` with standard Array operations (`path.append(route)`, `path.popLast()`, `path.removeAll()`).
  - Heterogeneous (mixed destination types): Use `@State private var path = NavigationPath()`.
- **Value vs. View Destinations**: Value-destinations are recorded in the bound `NavigationPath`. View-destinations (`NavigationLink(destination:)`) are pushed on top of the stack but are **not** tracked in `NavigationPath`.

```swift
// 1. Define Lightweight Navigation Routes
enum AppRoute: Hashable, Codable {
    case transaction(id: UUID)
    case account(id: String)
    case category(id: String)
    case whatIfPlanner
}

// 2. Programmatic Navigation Controller
@Observable
final class NavigationRouter {
    var path: [AppRoute] = []
    
    func navigate(to route: AppRoute) { path.append(route) }
    func pop() { path.popLast() }
    func popToRoot() { path.removeAll() }
}

// 3. NavigationStack with Route Decoupling
struct RootNavigationView: View {
    @State private var router = NavigationRouter()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            DashboardView()
                .navigationTitle("Dashboard")
                .navigationBarTitleDisplayMode(.large)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .transaction(let id):
                        TransactionDetailView(transactionId: id)
                    case .account(let id):
                        AccountAnalyticsView(accountId: id)
                    case .category(let id):
                        CategoryAnalyticsView(categoryId: id)
                    case .whatIfPlanner:
                        WhatIfPlannerView()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { /* action */ }) {
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                }
        }
    }
}
```

### Destination Presentation Variants
```swift
// A. Value-Driven (Tracks in NavigationPath)
NavigationLink("View Details", value: AppRoute.account(id: "bank"))

// B. Item-Driven (Optional Binding to Identifiable item)
.navigationDestination(item: $selectedAccount) { account in
    AccountAnalyticsSheet(account: account)
}

// C. Boolean-Driven (Stateful one-off push)
.navigationDestination(isPresented: $showSettings) {
    SettingsView()
}
```

### Navigation State Serialization & Deep Linking
```swift
// Save Navigation Path to AppStorage / Disk
func savePath(path: NavigationPath) -> Data? {
    guard let representation = path.codable else { return nil }
    return try? JSONEncoder().encode(representation)
}

// Restore Navigation Path on Launch
func restorePath(from data: Data) -> NavigationPath {
    guard let representation = try? JSONDecoder().decode(NavigationPath.CodableRepresentation.self, from: data) else {
        return NavigationPath()
    }
    return NavigationPath(representation)
}
```

### Fluid Zoom Navigation Transitions (iOS 18+)
```swift
// Match card to detail view with fluid zoom
NavigationLink(value: AppRoute.account(id: account.id)) {
    AccountCard(account: account)
}
.matchedTransitionSource(id: account.id, in: namespace)

.navigationDestination(for: AppRoute.self) { route in
    if case .account(let id) = route, let acc = store.account(for: id) {
        AccountAnalyticsSheet(account: acc)
            .navigationTransition(.zoom(sourceID: acc.id, in: namespace))
    }
}
```

### Multi-Column Layouts (`NavigationSplitView`)
```swift
struct AdaptiveSplitAppView: View {
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var selectedFolder: Folder? = nil
    @State private var selectedCategory: Category? = nil
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar Column
            List(store.folders, selection: $selectedFolder) { folder in
                Text(folder.name)
            }
            .navigationTitle("Folders")
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 320)
        } content: {
            // Content Column
            if let folder = selectedFolder {
                List(store.categories(in: folder), selection: $selectedCategory) { cat in
                    Text(cat.label)
                }
                .navigationTitle(folder.name)
            } else {
                Text("Select a Folder")
            }
        } detail: {
            // Detail Column
            if let category = selectedCategory {
                CategoryDetailView(category: category)
            } else {
                Text("Select a Category")
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

### Modern TabView & Adaptable Sidebar Navigation (iOS 18+ / visionOS)
```swift
struct AppRootTabView: View {
    @AppStorage("tabCustomizations") private var tabCustomization: TabViewCustomization
    @State private var selectedTab: TabDestination = .dashboard
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "house", value: .dashboard) {
                DashboardView()
            }
            .customizationID("app.tab.dashboard")
            .customizationBehavior(.disabled, for: .sidebar, .tabBar) // Pinned permanent tab
            
            Tab("Budget", systemImage: "chart.pie", value: .budget) {
                BudgetView()
            }
            .customizationID("app.tab.budget")
            
            Tab("Analytics", systemImage: "chart.bar", value: .analytics) {
                AnalyticsView()
            }
            .customizationID("app.tab.analytics")
            
            Tab("Subscriptions", systemImage: "creditcard", value: .subscriptions) {
                ManageView()
            }
            .customizationID("app.tab.subscriptions")
            
            Tab(value: .search, role: .search) {
                SearchAllTransactionsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabViewCustomization($tabCustomization)
    }
}
```

### Modal Sheets, Detents & Inspectors
```swift
.sheet(isPresented: $showSheet) {
    AddTransactionSheet()
        .presentationDetents([.medium, .fraction(0.85), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .presentationCornerRadius(28)
        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        .interactiveDismissDisabled(hasUnsavedData)
}
.inspector(isPresented: $showInspector) {
    ContextualInspectorView()
        .inspectorColumnWidth(min: 250, ideal: 300, max: 400)
}
.confirmationDialog("Delete Transaction?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
    Button("Delete Permanently", role: .destructive) { performDelete() }
    Button("Cancel", role: .cancel) { }
}
.alert("Network Failure", isPresented: $showErrorAlert) {
    Button("Retry") { retry() }
    Button("Dismiss", role: .cancel) { }
} message: {
    Text("Please check your internet connection and try again.")
}
```

---

## 6. Controls, Pickers & User Input

### Buttons & Menus
```swift
// Prominent Action Button
Button("Save Transaction", action: save)
    .buttonStyle(.borderedProminent)
    .buttonBorderShape(.capsule)
    .controlSize(.large)

// Menu with Primary Action
Menu {
    Button("Export CSV", action: exportCSV)
    Button("Export PDF", action: exportPDF)
    Divider()
    Button("Delete All", role: .destructive, action: deleteAll)
} label: {
    Label("Options", systemImage: "ellipsis.circle")
} primaryAction: {
    exportCSV()
}
```

### Pickers & Toggles
```swift
// Segmented Picker
Picker("Interval", selection: $selectedInterval) {
    Text("Weekly").tag(Interval.weekly)
    Text("Monthly").tag(Interval.monthly)
    Text("Yearly").tag(Interval.yearly)
}
.pickerStyle(.segmented)

// Date & Color Pickers
DatePicker("Transaction Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
ColorPicker("Card Tint", selection: $cardColor, supportsOpacity: false)
```

### Text Input & Keyboard Toolbar
```swift
enum InputField: Hashable { case title, amount, notes }
@FocusState private var focusedField: InputField?

VStack {
    TextField("Title", text: $title)
        .focused($focusedField, equals: .title)
        .submitLabel(.next)
    
    TextField("Amount", text: $amount)
        .focused($focusedField, equals: .amount)
        .keyboardType(.decimalPad)
}
.toolbar {
    ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") { focusedField = nil }
    }
}
```

---

## 7. Typography, Colors, Shapes & Materials

### System Typography & Formats
```swift
Text(amount, format: .currency(code: "USD"))
    .font(.title2.weight(.bold))
    .fontDesign(.rounded)
    .monospacedDigit()

Text(Date.now, format: .dateTime.month().day().year())
    .font(.footnote)
    .foregroundStyle(.secondary)
```

### Shapes, Gradients & Liquid Glass Materials
```swift
// Modern Rounded Shapes
UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 8, bottomTrailingRadius: 24, topTrailingRadius: 8)
    .fill(
        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    )
    .frame(height: 120)

// Liquid Glass Card
VStack {
    Text("Liquid Glass Card")
}
.padding(20)
.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 20, style: .continuous)
        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
)
.shadow(color: .black.opacity(0.08), radius: 12, y: 6)
```

---

## 8. Animations, Phase/Keyframe Animators & Transitions

### Fluid Spring Animations
```swift
withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
    isExpanded.toggle()
}

// Content Transitions
Text("\(count)")
    .contentTransition(.numericText(value: Double(count)))

Image(systemName: isLiked ? "heart.fill" : "heart")
    .contentTransition(.symbolEffect(.replace))
```

### PhaseAnimator & KeyframeAnimator (iOS 17+)
```swift
// Phase Animator
Button("Success Action") { triggerSuccess.toggle() }
    .phaseAnimator([false, true], trigger: triggerSuccess) { content, isTriggered in
        content
            .scaleEffect(isTriggered ? 1.2 : 1.0)
            .opacity(isTriggered ? 0.8 : 1.0)
    } animation: { isTriggered in
        isTriggered ? .bouncy(duration: 0.3) : .smooth
    }

// Sensory Feedback
Button("Delete", role: .destructive, action: deleteItem)
    .sensoryFeedback(.error, trigger: isDeleted)
```

---

## 9. Gestures & Direct Manipulation

```swift
@GestureState private var dragOffset = CGSize.zero

let dragGesture = DragGesture(minimumDistance: 10)
    .updating($dragOffset) { value, state, _ in
        state = value.translation
    }
    .onEnded { value in
        if value.translation.width > 100 {
            dismiss()
        }
    }

CardView()
    .offset(dragOffset)
    .gesture(dragGesture)
    .simultaneousGesture(
        TapGesture(count: 2).onEnded { handleDoubleTap() }
    )
```

---

## 10. Native System Framework Integrations

| Capability | Framework | Implementation Example |
| :--- | :--- | :--- |
| **Photos Picker** | `PhotosUI` | `PhotosPicker(selection: $photoItem, matching: .images) { Label("Photo", systemImage: "photo") }` |
| **File Import/Export** | `SwiftUI` | `.fileImporter(isPresented: $showPicker, allowedContentTypes: [.pdf, .png]) { result in ... }` |
| **In-App Purchases** | `StoreKit` | `SubscriptionStoreView(groupID: "spendy_pro")`, `ProductView(id: "pro_yearly")` |
| **Apple Pay** | `PassKit` | `PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .automatic)` |
| **Maps & Locations** | `MapKit` | `Map(position: $cameraPosition) { Marker("Bank", coordinate: location) }` |
| **Authentication** | `AuthenticationServices` | `SignInWithAppleButton(.signIn, onRequest: { ... }, onCompletion: { ... })` |
| **Live Activities** | `ActivityKit` | `Activity<SpendAttributes>.request(attributes: attrs, content: content)` |
| **Widgets** | `WidgetKit` | `@main struct SpendyWidgets: WidgetBundle { SpendySummaryWidget() }` |
| **App Intents** | `AppIntents` | `struct LogExpenseIntent: AppIntent { ... }` |
| **UIKit Bridging** | `SwiftUI` | `struct SafariView: UIViewControllerRepresentable { func makeUIViewController(...) }` |

---

## 11. Accessibility (A11y) & Localization

```swift
// VoiceOver Optimization
VStack(alignment: .leading, spacing: 4) {
    Text("Checking Account")
    Text("$1,250.00")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Checking Account, balance 1,250 dollars")
.accessibilityAddTraits(.isButton)

// Dynamic Type & Motion Adapters
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 24

// Localization with String Catalogs
Text(String(localized: "welcome_message", defaultValue: "Welcome back to Spendy!"))
```

---

## API Cheatsheet & Rapid Decision Matrix

| Task | Preferred SwiftUI API |
| :--- | :--- |
| **State across views** | `@Observable` class + `@Environment` or `@Bindable` |
| **Local state** | `@State private var value: Type` |
| **Two-way child binding** | `@Binding var value: Type` |
| **Paging list / card carousel** | `ScrollView` + `.scrollTargetBehavior(.viewAligned)` |
| **Bottom Sheet with heights** | `.sheet` + `.presentationDetents([.medium, .large])` |
| **Adaptive column switching** | `ViewThatFits` or `AnyLayout` |
| **Translucent glass surface** | `.ultraThinMaterial` in `RoundedRectangle` |
| **Multi-step trigger animation**| `PhaseAnimator` or `KeyframeAnimator` |
| **Haptic response** | `.sensoryFeedback(.selection, trigger: value)` |
| **Photo selection** | `PhotosPicker` (`PhotosUI`) |
| **StoreKit paywall** | `SubscriptionStoreView` (`StoreKit`) |
