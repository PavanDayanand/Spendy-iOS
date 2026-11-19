import SwiftUI

/// Full spending breakdown, presented like the app's transaction browser.
struct SpendingBreakdownSheet: View {
    let snapshot: SpendingChartSnapshot
    let byCategory: Bool
    let accountLabel: String
    let accountID: String
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("spendingBreakdownShowsChart") private var showsChart = true
    @State private var showsFilter = false
    @State private var periodFilter: SpendingPeriodFilter?
    @State private var selectedIDs: Set<String>?
    @State private var selectedBucket: String?
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    private var isIncome: Bool { snapshot.transactionType == .income }
    private var title: String { (isIncome ? "Income" : "Spending") + (byCategory ? " by Category" : " by Account") }

    private var spendingScope: SpendingScope {
        let current = filteredSnapshot
        return SpendingScope(start: current.start, end: current.end, referenceDate: current.referenceDate,
            accountIDs: accountID != "all" ? (byCategory ? [accountID] : selectedIDs.map { $0.intersection([accountID]) } ?? [accountID]) : (byCategory ? nil : selectedIDs),
            categoryIDs: byCategory ? selectedIDs : nil, transactionType: snapshot.transactionType)
    }

    private var filteredSnapshot: SpendingChartSnapshot {
        makeSnapshot(store.transactions.filter { transaction in
            selectedIDs?.contains(byCategory ? transaction.categoryId : transaction.accountId) ?? true
        })
    }

    private func makeSnapshot(_ transactions: [Transaction]) -> SpendingChartSnapshot {
        if let periodFilter {
            return periodFilter.snapshot(transactions: transactions, accountID: accountID,
                referenceDate: snapshot.referenceDate, transactionType: snapshot.transactionType)
        }
        return SpendingChartSnapshot(transactions: transactions, accountID: accountID,
            period: snapshot.period, anchor: snapshot.start, referenceDate: snapshot.referenceDate,
            transactionType: snapshot.transactionType)
    }

    private var filterItems: [AnalyticsBreakdownItem] {
        let current = makeSnapshot(store.transactions)
        return breakdownItems(for: current)
    }

    private func breakdownItems(for current: SpendingChartSnapshot) -> [AnalyticsBreakdownItem] {
        Dictionary(grouping: current.transactions, by: { byCategory ? $0.categoryId : $0.accountId })
            .map { id, transactions in
                let category = byCategory ? store.category(for: id) : nil
                let account = byCategory ? nil : store.account(for: id)
                let amount = transactions.reduce(0) { $0 + $1.amount }
                return AnalyticsBreakdownItem(id: id, label: category?.label ?? account?.label ?? id,
                    sfSymbol: category?.sfSymbol ?? account?.sfSymbol ?? "tag",
                    colorHex: category?.colorHex ?? account?.colorHex ?? "#808080",
                    txCount: transactions.count, amount: amount,
                    percentage: current.total > 0 ? amount / current.total * 100 : 0)
            }
            .sorted { $0.amount == $1.amount ? $0.id < $1.id : $0.amount > $1.amount }
    }

    var body: some View {
        let snapshot = filteredSnapshot
        let visibleItems = breakdownItems(for: snapshot)
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(accountLabel + " · " + snapshot.start.formatted(.dateTime.month(.wide).year())
                            + (selectedIDs.map { " · \($0.count) selected" } ?? ""))
                            .font(.subheadline).foregroundStyle(SpendyColors.textSecondary)
                        Text((snapshot.buckets.first { $0.id == selectedBucket }?.amount ?? snapshot.total)
                            .formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                            .font(.largeTitle.bold()).monospacedDigit()
                            .accessibilityIdentifier("breakdown-total")
                        Text(snapshot.start.formatted(.dateTime.day().month(.abbreviated)) + " – " + snapshot.recordedEnd.formatted(.dateTime.day().month(.abbreviated).year()) + (snapshot.isInProgress ? " · To date" : ""))
                            .font(.caption).foregroundStyle(SpendyColors.textSecondary)
                        if let bucket = snapshot.buckets.first(where: { $0.id == selectedBucket }) {
                            HStack {
                                Text(bucket.start.formatted(.dateTime.day().month(.abbreviated)) + " · \(bucket.transactionCount) transactions")
                                Spacer()
                            }.font(.caption)
                        } else {
                            Text(snapshot.comparisonText(currencySymbol: store.currencySymbol))
                                .font(.caption).foregroundStyle(SpendyColors.textSecondary)
                        }
                        if showsChart {
                            SpendingChartPlot(buckets: snapshot.buckets, currencySymbol: store.currencySymbol,
                                selectedID: $selectedBucket, height: 160, transactionType: snapshot.transactionType)
                                .accessibilityIdentifier("breakdown-spending-chart")
                        }
                        if selectedBucket != nil {
                            Text("Categories below cover the full period.")
                                .font(.caption2).foregroundStyle(SpendyColors.textSecondary)
                        }
                    }
                    if visibleItems.isEmpty {
                        SpendyPlainEmptyState(
                            title: selectedIDs != [] ? (isIncome ? "No income yet" : "No spending yet") : "No selections",
                            message: selectedIDs != [] ? "No recorded transactions match the current filters."
                                : byCategory ? "Choose categories to see transactions." : "Choose accounts to see transactions.",
                            icon: byCategory ? "square.grid.2x2" : "creditcard",
                            actionTitle: selectedIDs != [] ? nil : "Select all",
                            action: { selectedIDs = nil }
                        )
                    }
                    VStack(spacing: 12) {
                        ForEach(visibleItems) { item in
                            Button {
                                if byCategory { selectedCategory = store.categories.first { $0.id == item.id } }
                                else { selectedAccount = store.accounts.first { $0.id == item.id } }
                            } label: {
                                SpendingBreakdownRow(item: item, isIncome: isIncome, currencySymbol: store.currencySymbol)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("breakdown-\(item.id)")
                        }
                    }
                }
                .padding(20)
            }
            .accessibilityIdentifier("breakdown-scroll")
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
        .background(SpendyColors.appBackground.ignoresSafeArea())
        .foregroundStyle(SpendyColors.textPrimary)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Options", systemImage: "ellipsis") {
                    Toggle("Show chart", isOn: $showsChart)
                        .accessibilityIdentifier("breakdown-chart-toggle")
                    Button(selectedIDs.map { "Filter · \($0.count) selected" }
                           ?? periodFilter.map { "Filter · \($0.title)" } ?? "Filter",
                           systemImage: "line.3.horizontal.decrease") { showsFilter = true }
                        .accessibilityIdentifier("breakdown-filter")
                    if selectedIDs != nil || periodFilter != nil {
                        Button("Reset filters", systemImage: "arrow.counterclockwise") {
                            selectedIDs = nil
                            periodFilter = nil
                        }
                        .accessibilityIdentifier("breakdown-reset-filters")
                    }
                }
                .accessibilityLabel(isIncome ? "Income options" : "Spending options")
                .accessibilityIdentifier("breakdown-menu")
                .accessibilityValue(selectedIDs.map { "\($0.count) selected" } ?? "All selected")
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $selectedCategory) { category in
            CategoryAnalyticsSheet(category: category, spendingScope: spendingScope)
        }
        .navigationDestination(item: $selectedAccount) { account in
            AccountAnalyticsSheet(account: account, spendingScope: spendingScope)
        }
        .sheet(isPresented: $showsFilter) {
            SpendingBreakdownFilter(items: filterItems, byCategory: byCategory, selectedIDs: $selectedIDs,
                periodFilter: $periodFilter, initialMonth: snapshot.start,
                referenceDate: snapshot.referenceDate)
        }
        .onChange(of: selectedIDs) { _, _ in
            selectedBucket = nil
        }
        .onChange(of: periodFilter) { _, _ in
            selectedBucket = nil
        }
        .tint(SpendyColors.textPrimary)
    }
}

struct SpendingBreakdownFilter: View {
    let items: [AnalyticsBreakdownItem]
    let byCategory: Bool
    @Binding var selectedIDs: Set<String>?
    var periodFilter: Binding<SpendingPeriodFilter?>? = nil
    var initialMonth: Date? = nil
    var referenceDate: Date? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @FocusState private var searchFocused: Bool
    @State private var detent: PresentationDetent = .medium
    private var matches: [AnalyticsBreakdownItem] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? items : items.filter { $0.label.localizedCaseInsensitiveContains(query) }
    }
    var body: some View {
        NavigationStack {
            List {
                if let periodFilter, let initialMonth, let referenceDate {
                    DisclosureGroup {
                        SpendingMonthPicker(month: Binding(
                            get: { periodFilter.wrappedValue?.month ?? initialMonth },
                            set: { periodFilter.wrappedValue = SpendingPeriodFilter(month: $0) }
                        ), latestDate: referenceDate)
                        .frame(height: 156)
                    } label: {
                        Label(periodFilter.wrappedValue?.title ?? "Select month", systemImage: "calendar")
                    }
                    .accessibilityIdentifier("breakdown-month-filter")
                }
                Section {
                    Button("Select all") { selectedIDs = nil }
                        .accessibilityIdentifier("breakdown-select-all")
                    Button("Clear all") { selectedIDs = [] }
                }
                Section {
                    ForEach(matches) { item in
                        Button {
                            var selection = selectedIDs ?? Set(items.map(\.id))
                            if selection.contains(item.id) { selection.remove(item.id) }
                            else { selection.insert(item.id) }
                            selectedIDs = selection
                        } label: {
                            HStack {
                                SpendyIconBadge(sfSymbol: item.sfSymbol, color: SpendyColors.textPrimary,
                                    size: .small, style: .circle, monogramName: item.label)
                                Text(item.label)
                                Spacer()
                                if selectedIDs?.contains(item.id) ?? true { Image(systemName: "checkmark") }
                            }
                            .frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("filter-category-\(item.id)")
                        .accessibilityValue((selectedIDs?.contains(item.id) ?? true) ? "Selected" : "Not selected")
                    }
                    if matches.isEmpty { Text("No matches").foregroundStyle(.secondary) }
                }
            }
            .navigationTitle(periodFilter == nil ? (byCategory ? "Categories" : "Accounts") : "Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField(byCategory ? "Search categories" : "Search accounts", text: $search)
                        .autocorrectionDisabled()
                        .focused($searchFocused)
                        .submitLabel(.done)
                        .onSubmit { searchFocused = false }
                    if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Clear search") }
                }
                .padding(14)
                .nativeLiquidGlassCapsule(isInteractive: true)
                .padding()
            }
        }
        .tint(SpendyColors.textPrimary)
        .presentationDetents([.medium, .large], selection: $detent)
        .onChange(of: searchFocused) { _, focused in
            if focused { detent = .large }
        }
        .presentationDragIndicator(.visible)
    }
}
