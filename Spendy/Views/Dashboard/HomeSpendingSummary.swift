import SwiftUI
import TipKit

struct HomeSpendingSummary: View {
    let transactions: [Transaction]
    let categories: [Category]
    let accountID: String
    let accountLabel: String
    let currencySymbol: String
    let amountsHidden: Bool
    let insightsEnabled: Bool
    let tipGroup: TipGroup
    var onInsight: ((InsightDestination, Date) -> Void)? = nil
    var onExplore: (Date) -> Void
    @Environment(\.spendyTipsAllowed) private var tipsAllowed
    @Environment(ExpenseStore.self) private var store
    @State private var showsInsights = false
    @State private var pendingInsight: InsightDestination?
    @State private var insightDate = Date()
    @State private var selectedID: String?
    @State private var showsInfo = false
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize = 40.0

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let referenceDate = max(context.date, Date())
            let history = SpendingChartSnapshot.monthlyHistory(transactions: transactions,
                accountID: accountID, referenceDate: referenceDate)
            let selected = history.first { $0.id == selectedID }
            let snapshot = SpendingChartSnapshot(transactions: transactions, accountID: accountID,
                anchor: selected?.start ?? referenceDate, referenceDate: referenceDate)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Label(selected == nil || snapshot.isInProgress ? "Spent this month" : "Spent in \(snapshot.start.formatted(.dateTime.month(.wide).year()))",
                          systemImage: "chart.bar.xaxis")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Button { showsInfo = true } label: {
                        Image(systemName: "info.circle")
                            .font(.subheadline)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .accessibilityLabel("About spending")
                    Spacer(minLength: 0)
                }
                Text(amountsHidden ? "••••••" : snapshot.total.formattedCurrency(symbol: currencySymbol, decimals: 2))
                    .font(.system(size: amountSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel(amountsHidden ? "Spending hidden" : "Spending, \(snapshot.total.formattedCurrency(symbol: currencySymbol, decimals: 2))")
                    .accessibilityIdentifier("home-spending-total")

                if amountsHidden {
                    Label("Spending is hidden", systemImage: "eye.slash")
                        .font(.subheadline)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .accessibilityIdentifier("hidden-spending-chart")
                } else {
                    Text(snapshot.comparisonText(currencySymbol: currencySymbol))
                        .font(.caption)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("home-spending-comparison")
                    if history.contains(where: { $0.transactionCount > 0 }) {
                        SpendingChartPlot(buckets: history, currencySymbol: currencySymbol,
                                          selectedID: $selectedID, height: 110)
                            .padding(.top, 4)
                    } else {
                        Text("Your spending history will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(SpendyColors.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 110)
                    }
                    HStack {
                        Text(selected.map { "\($0.transactionCount) transactions\($0.isInProgress ? " · To date" : "")" }
                             ?? "Last 6 months · \(context.date.formatted(.dateTime.month(.abbreviated))) to date")
                            .font(.caption2)
                            .foregroundStyle(SpendyColors.textSecondary)
                        Spacer()

                    }
                    let attention = HomeAttentionInsights.build(transactions: transactions, subscriptions: store.subscriptions, budget: store.budget,
                        cycleSpent: store.budgetCycleExpenses, currencySymbol: currencySymbol, now: referenceDate)
                    if insightsEnabled && !attention.isEmpty {
                        SpendyInsightSummary(moments: attention, compact: true, onSelect: { _ in
                            insightDate = snapshot.start
                            showsInsights = true
                        })
                        .popoverTip(tipsAllowed && store.hasCompletedOnboarding && !showsInsights && !showsInfo ? tipGroup.currentTip as? HomeInsightTip : nil)
                        .onChange(of: showsInsights) { _, showing in
                            if showing { HomeInsightTip().invalidate(reason: .actionPerformed) }
                        }
                    } else {
                    Button {
                        if insightsEnabled {
                            insightDate = snapshot.start
                            showsInsights = true
                        } else { onExplore(snapshot.start) }
                    } label: {
                        HStack(spacing: 6) {
                            if insightsEnabled, let leading = snapshot.leadingCategory,
                               let category = categories.first(where: { $0.id == leading.id }) {
                                SpendyInsightSymbol()
                                ShinyHeadlineText(headline: "\(category.label) · \(leading.share.formatted(.percent.precision(.fractionLength(0)))) of spending", emphasis: [], font: .caption, emphasisFont: .caption.bold())
                            } else {
                                Text(insightsEnabled ? "View spending insights" : "View analytics")
                            }
                            Spacer(minLength: 2)
                            Image(systemName: "chevron.right").font(.caption2)
                        }
                        .font(.caption)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home-spending-insights")
                    .accessibilityHint(insightsEnabled ? "Open the full Spendy insights list" : "Open spending analytics for this account and month")
                    }
                }
                if amountsHidden {
                    Button {
                        insightDate = snapshot.start
                        if insightsEnabled { showsInsights = true }
                        else { onExplore(snapshot.start) }
                    } label: {
                        HStack(spacing: 6) {
                            if insightsEnabled { SpendyInsightSymbol() }
                            Text(insightsEnabled ? "Spendy insights" : "View analytics")
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2)
                        }
                        .font(.caption)
                        .foregroundStyle(SpendyColors.textSecondary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home-spending-insights")
                }
            }
            .sheet(isPresented: $showsInsights, onDismiss: {
                if let destination = pendingInsight {
                    pendingInsight = nil
                    if destination == .analytics { onExplore(insightDate) }
                    else { onInsight?(destination, insightDate) }
                }
            }) {
                SpendingChartInfoSheet(snapshot: snapshot, accountLabel: accountLabel,
                    currencySymbol: currencySymbol, amountsHidden: amountsHidden, insights: HomeAttentionInsights.build(transactions: transactions, subscriptions: store.subscriptions, budget: store.budget,
                        cycleSpent: store.budgetCycleExpenses, currencySymbol: currencySymbol, now: referenceDate) + insights(for: snapshot), insightsOnly: true,
                    onSelectInsight: { destination in
                        pendingInsight = destination
                        showsInsights = false
                    }, onViewSpending: {
                        pendingInsight = .analytics
                        showsInsights = false
                    })
            }
            .sheet(isPresented: $showsInfo) {
                SpendingChartInfoSheet(snapshot: snapshot, accountLabel: accountLabel,
                                       currencySymbol: currencySymbol, amountsHidden: amountsHidden)
            }
        }
        .onChange(of: accountID) { _, _ in selectedID = nil }
        .onChange(of: amountsHidden) { _, _ in selectedID = nil }
    }

    private func insights(for snapshot: SpendingChartSnapshot) -> [InsightMoment] {
        let context = AnalyticsInsightContext(scope: accountID == "all" ? .global : .account(id: accountID),
            period: .month, startDate: snapshot.start,
            endDate: snapshot.end.addingTimeInterval(-0.000001),
            baselineStartDate: snapshot.baselineStart,
            baselineEndDate: snapshot.baselineEnd.addingTimeInterval(-0.000001),
            referenceDate: snapshot.referenceDate)
        let facts = InsightFactsExtractor.extractFacts(transactions: transactions, budget: store.budget,
            categories: categories, subscriptions: store.subscriptions, context: context)
        return InsightDecisionEngine.shared.evaluate(facts: facts, surface: .analytics, currencySymbol: currencySymbol)
    }

}
