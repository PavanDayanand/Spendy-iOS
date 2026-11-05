import SwiftUI

/// Full spending breakdown, presented like the app's transaction browser.
struct SpendingBreakdownSheet: View {
    let snapshot: SpendingChartSnapshot
    let items: [AnalyticsBreakdownItem]
    let byCategory: Bool
    let accountLabel: String
    let accountID: String
    var topControlsNamespace: Namespace.ID? = nil
    var sharedNavigationHeader: AnalyticsNavigationHeaderState? = nil
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("spendingBreakdownShowsChart") private var showsChart = true
    @State private var showsFilter = false
    @State private var selectedIDs: Set<String>?
    @Namespace private var internalControlsNamespace
    private var controlsNamespace: Namespace.ID { topControlsNamespace ?? internalControlsNamespace }
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    private var isIncome: Bool { snapshot.transactionType == .income }
    private var title: String { (isIncome ? "Income" : "Spending") + (byCategory ? " by Category" : " by Account") }

    private var spendingScope: SpendingScope {
        SpendingScope(start: snapshot.start, end: snapshot.end, referenceDate: snapshot.referenceDate,
            accountIDs: accountID != "all" ? (byCategory ? [accountID] : selectedIDs.map { $0.intersection([accountID]) } ?? [accountID]) : (byCategory ? nil : selectedIDs),
            categoryIDs: byCategory ? selectedIDs : nil, transactionType: snapshot.transactionType)
    }

    private var filteredSnapshot: SpendingChartSnapshot {
        let transactions = store.transactions.filter { transaction in
            guard let selectedIDs else { return true }
            return selectedIDs.contains(byCategory ? transaction.categoryId : transaction.accountId)
        }
        return SpendingChartSnapshot(transactions: transactions, accountID: accountID,
            period: snapshot.period, anchor: snapshot.start, referenceDate: snapshot.referenceDate, transactionType: snapshot.transactionType)
    }

    private var visibleItems: [AnalyticsBreakdownItem] {
        let current = filteredSnapshot
        return items.filter { selectedIDs?.contains($0.id) ?? true }.map { item in
            let transactions = current.transactions.filter { (byCategory ? $0.categoryId : $0.accountId) == item.id }
            let amount = transactions.reduce(0) { $0 + $1.amount }
            return AnalyticsBreakdownItem(id: item.id, label: item.label, sfSymbol: item.sfSymbol,
                colorHex: item.colorHex, txCount: transactions.count, amount: amount,
                percentage: current.total > 0 ? amount / current.total * 100 : 0)
        }
    }

    private func configureNavigationHeader() {
        guard selectedCategory == nil, selectedAccount == nil else { return }
        let chart = $showsChart
        let filter = $showsFilter
        let selection = $selectedIDs
        let dismissAction = dismiss
        var items = [
            AnalyticsNavigationHeaderMenuItem(id: "breakdown-chart-toggle", title: "Show chart",
                systemImage: "chart.pie", isSelected: showsChart) {
                withAnimation(.easeInOut(duration: 0.2)) { chart.wrappedValue.toggle() }
            },
            AnalyticsNavigationHeaderMenuItem(id: "breakdown-filter",
                title: selectedIDs.map { "Filter · \($0.count) selected" } ?? "Filter",
                systemImage: "line.3.horizontal.decrease") { filter.wrappedValue = true }
        ]
        if selectedIDs != nil {
            items.append(AnalyticsNavigationHeaderMenuItem(id: "breakdown-reset-filters",
                title: "Reset filters", systemImage: "arrow.counterclockwise") { selection.wrappedValue = nil })
        }
        sharedNavigationHeader?.show(title: title, onBack: { dismissAction() },
            menuItems: items, menuLabel: isIncome ? "Income options" : "Spending options",
            menuIdentifier: "breakdown-menu",
            menuValue: selectedIDs.map { "\($0.count) selected" } ?? "All selected")
    }

    private var headerBar: some View {
        HStack {
            GlassCircleButton(icon: "chevron.left", size: 44, iconSize: 15,
                iconWeight: .bold, foregroundColor: SpendyColors.textPrimary,
                haptic: .selection, accessibilityLabel: "Back",
                morphID: "topControl_left", namespace: controlsNamespace) { dismiss() }
            Spacer()
            Text(title).font(.system(size: 17, weight: .bold)).accessibilityAddTraits(.isHeader)
            Spacer()
            Menu {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showsChart.toggle() }
                } label: {
                    Label("Show chart", systemImage: showsChart ? "checkmark" : "chart.pie")
                }
                .accessibilityValue(showsChart ? "On" : "Off")
                .accessibilityIdentifier("breakdown-chart-toggle")
                Button { showsFilter = true } label: {
                    Label(selectedIDs.map { "Filter · \($0.count) selected" } ?? "Filter", systemImage: "line.3.horizontal.decrease")
                }
                .accessibilityIdentifier("breakdown-filter")
                if selectedIDs != nil {
                    Button("Reset filters") { selectedIDs = nil }
                        .accessibilityIdentifier("breakdown-reset-filters")
                }
            } label: {
                GlassCircleIcon(size: 44, morphID: "topControl_right", namespace: controlsNamespace) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .overlay(alignment: .topTrailing) {
                if let selectedIDs {
                    Text("\(selectedIDs.count)")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(SpendyColors.inverseText)
                        .padding(4)
                        .background(SpendyColors.textPrimary, in: Capsule())
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(isIncome ? "Income options" : "Spending options")
            .accessibilityIdentifier("breakdown-menu")
            .accessibilityValue(selectedIDs.map { "\($0.count) selected" } ?? "All selected")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }

    var body: some View {
        let snapshot = filteredSnapshot
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(snapshot.total.formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                            .font(.largeTitle.bold()).monospacedDigit()
                            .accessibilityIdentifier("breakdown-total")
                        Text(accountLabel + " · "
                            + snapshot.start.formatted(.dateTime.month(.abbreviated).day()) + " – "
                            + snapshot.recordedEnd.formatted(.dateTime.month(.abbreviated).day().year()))
                            .font(.caption)
                            .foregroundStyle(SpendyColors.textSecondary)
                        if showsChart && visibleItems.contains(where: { $0.amount > 0 }) {
                            SpendingMixChart(items: visibleItems, currencySymbol: store.currencySymbol, isIncome: isIncome)
                                .accessibilityIdentifier("breakdown-spending-chart")
                        }
                    }
                    if visibleItems.isEmpty {
                        SpendyPlainEmptyState(
                            title: items.isEmpty ? (isIncome ? "No income yet" : "No spending yet") : "No selections",
                            message: items.isEmpty ? "Recorded transactions will appear here."
                                : byCategory ? "Choose categories to see transactions." : "Choose accounts to see transactions.",
                            icon: byCategory ? "square.grid.2x2" : "creditcard",
                            actionTitle: items.isEmpty ? nil : "Select all",
                            action: { selectedIDs = nil }
                        )
                    }
                    VStack(spacing: 12) {
                        ForEach(visibleItems) { item in
                            Button {
                                if byCategory { selectedCategory = store.categories.first { $0.id == item.id } }
                                else { selectedAccount = store.accounts.first { $0.id == item.id } }
                            } label: {
                                HStack(spacing: 12) {
                                    Circle().fill(Color(hex: item.colorHex))
                                        .frame(width: 8, height: 8)
                                        .accessibilityHidden(true)
                                    SpendyIconBadge(sfSymbol: item.sfSymbol, color: SpendyColors.textPrimary,
                                        size: .medium, style: .circle, monogramName: item.label)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.label).font(AppTypography.rowTitle)
                                        Text("\(item.txCount) \(isIncome ? "income transactions" : (item.txCount == 1 ? "expense" : "expenses"))")
                                            .font(AppTypography.footnoteMedium).foregroundStyle(SpendyColors.textSecondary)
                                    }
                                    Spacer(minLength: 4)
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                                            .font(.headline.monospacedDigit())
                                        Text("\(item.percentage.formatted(.number.precision(.fractionLength(1))))%")
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(SpendyColors.textSecondary)
                                    }
                                    .lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(SpendyColors.cardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay { RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8) }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("breakdown-\(item.id)")
                        }
                    }
                }
                .padding(20)
            }
            .accessibilityIdentifier("breakdown-scroll")
            .safeAreaBar(edge: .top, spacing: 0) {
                if sharedNavigationHeader != nil {
                    Color.clear.frame(height: 58).accessibilityHidden(true)
                } else {
                    headerBar.padding(.bottom, 8)
                }
            }
            .scrollEdgeEffectStyle(.soft, for: .top)
        }
        .background(SpendyColors.appBackground.ignoresSafeArea())
        .foregroundStyle(SpendyColors.textPrimary)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $selectedCategory) { category in
            CategoryAnalyticsSheet(category: category, spendingScope: spendingScope,
                topControlsNamespace: controlsNamespace, sharedNavigationHeader: sharedNavigationHeader)
        }
        .navigationDestination(item: $selectedAccount) { account in
            AccountAnalyticsSheet(account: account, spendingScope: spendingScope,
                topControlsNamespace: controlsNamespace, sharedNavigationHeader: sharedNavigationHeader)
        }
        .onAppear { configureNavigationHeader() }
        .onChange(of: selectedCategory?.id) { _, _ in configureNavigationHeader() }
        .onChange(of: selectedAccount?.id) { _, _ in configureNavigationHeader() }
        .onChange(of: showsChart) { _, _ in configureNavigationHeader() }
        .sheet(isPresented: $showsFilter) {
            SpendingBreakdownFilter(items: items, byCategory: byCategory, selectedIDs: $selectedIDs)
        }
        .onChange(of: selectedIDs) { _, selection in
            if selection == Set(items.map(\.id)) { selectedIDs = nil }
            configureNavigationHeader()
        }
        .tint(SpendyColors.textPrimary)
    }
}

struct SpendingBreakdownFilter: View {
    let items: [AnalyticsBreakdownItem]
    let byCategory: Bool
    @Binding var selectedIDs: Set<String>?
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
            .navigationTitle(byCategory ? "Categories" : "Accounts")
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
