//
//  ManageView.swift
//  Spendy
//
//  Subscriptions dashboard: uncarded monthly total, sentence insights,
//  and a single grouped list card.
//

import SwiftUI
import TipKit

// MARK: - Subscriptions Full-Screen View

struct SubscriptionsView: View {
    @Environment(\.spendyTipsAllowed) private var tipsAllowed
    @Environment(ExpenseStore.self) private var store
    @Environment(\.spendyUsesSystemNavigation) private var usesSystemNavigation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var isPushed: Bool = false
    var initialSelectedSubscriptionId: String? = nil

    @State private var showAddSubscription: Bool = false
    @State private var pendingSubscriptionEdit: Subscription? = nil
    @State private var subscriptionToEdit: Subscription? = nil
    @State private var selectedSubscriptionForDetail: Subscription? = nil
    @State private var showTrackedSubscriptions = true
    @State private var showCancelledSubs = false
    @State private var subscriptionToDelete: Subscription?
    @Namespace private var subscriptionTransitions
    @State private var subscriptionTransitionID: String? = nil
    @Namespace private var subsNamespace

    // MARK: - Computed Properties

    private var activeAndTrialSubs: [Subscription] {
        store.subscriptions.filter { !$0.isCancelled }
    }

    private var cancelledSubs: [Subscription] {
        store.subscriptions.filter { $0.isCancelled }
    }

    private var activeCount: Int {
        activeAndTrialSubs.filter { !$0.isTrial && !$0.isPaused }.count
    }

    private var totalMonthly: Double {
        activeAndTrialSubs.filter { !$0.isPaused && !$0.isTrial }.reduce(0.0) { sum, sub in
            switch sub.cycle {
            case .monthly: return sum + sub.amount
            case .yearly:  return sum + (sub.amount / 12.0)
            case .weekly:  return sum + (sub.amount * 4.33)
            }
        }
    }

    private var totalAnnual: Double { totalMonthly * 12.0 }

    // Top 5 Subscription Badges for Bubble Cluster
    private var summaryBadges: [BadgeItem] {
        activeAndTrialSubs
            .sorted(by: { $0.amount > $1.amount })
            .prefix(3)
            .map { sub in
                BadgeItem(id: sub.id.uuidString, icon: sub.sfSymbol, color: sub.color, name: sub.name)
            }
    }

    private var displayedSubscriptions: [Subscription] {
        activeAndTrialSubs.sorted { a, b in
            if a.isOverdue != b.isOverdue { return a.isOverdue && !b.isOverdue }
            if a.isDueSoon != b.isDueSoon { return a.isDueSoon && !b.isDueSoon }
            return a.nextBillingDate < b.nextBillingDate
        }
    }
    
    private var overdueCount: Int {
        activeAndTrialSubs.filter(\.isOverdue).count
    }

    private var chargesThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        return activeAndTrialSubs.filter { !$0.isPaused }.reduce(0) { sum, sub in
            if sub.isOverdue { return sum + sub.amount }
            let due = sub.nextBillingDate
            if calendar.isDate(due, equalTo: now, toGranularity: .month)
                && calendar.isDate(due, equalTo: now, toGranularity: .year) {
                return sum + sub.amount
            }
            return sum
        }
    }

    private var nextUpcomingSubscription: Subscription? {
        activeAndTrialSubs
            .filter { !$0.isPaused && !$0.isOverdue }
            .sorted { $0.nextBillingDate < $1.nextBillingDate }
            .first
    }
    
    private var subscriptionInsightMoments: [InsightMoment] {
        guard store.insightsEnabled else { return [] }
        let facts = InsightFactsExtractor.extractFacts(
            transactions: store.transactions,
            budget: store.budget,
            categories: store.categories,
            subscriptions: store.subscriptions
        )
        let moments = InsightDecisionEngine.shared.evaluate(
            facts: facts,
            surface: .subscriptions,
            currencySymbol: store.currencySymbol
        )
        let featuredRenewal = nextUpcomingSubscription.map { "sub_due_\($0.id.uuidString)" }
        return Array(moments.filter { moment in
            !moment.isInsufficientData
                && moment.candidateId.lowercased() != featuredRenewal?.lowercased()
        }.prefix(5))
    }
    
    private var groupedCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(SpendyColors.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SpendyColors.separator, lineWidth: 0.8)
            }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()

            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        summaryCard
                            .padding(.horizontal, 20)
                            .padding(.top, isPushed ? 12 : 2)

                        subscriptionsListSection
                            .padding(.horizontal, 20)

                        if !cancelledSubs.isEmpty {
                            pastAndCancelledSection
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, usesSystemNavigation || isPushed ? 24 : 120)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationTitle("Subscriptions")
        .navigationBarTitleDisplayMode(isPushed ? .inline : .large)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Subscription", systemImage: "plus") { showAddSubscription = true }
                    .accessibilityIdentifier("subscriptions-add")
            }
        }
        .task {
            NotificationManager.shared.refresh(from: store)
        }
        .sheet(isPresented: $showAddSubscription) {
            AddSubscriptionSheet()
        }
        .sheet(item: $subscriptionToEdit) { sub in
            AddSubscriptionSheet(subscriptionToEdit: sub)
        }
        .sheet(item: $selectedSubscriptionForDetail, onDismiss: {
            subscriptionToEdit = pendingSubscriptionEdit
            pendingSubscriptionEdit = nil
        }) { sub in
            SubscriptionQuickActionSheet(sub: sub) { subToEdit in
                pendingSubscriptionEdit = subToEdit
                selectedSubscriptionForDetail = nil
            }
        }
        .subscriptionDeleteConfirmation($subscriptionToDelete) { store.deleteSubscription(id: $0.id) }
        .onAppear {
            selectInitialSubscriptionIfNeeded()
        }
        .task(id: initialSelectedSubscriptionId) {
            selectInitialSubscriptionIfNeeded()
        }
    }
    
    private func selectInitialSubscriptionIfNeeded() {
        if let targetId = initialSelectedSubscriptionId,
           let match = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == targetId.lowercased() }) {
            subscriptionTransitionID = nil
            selectedSubscriptionForDetail = match
        }
    }



    // Typealias for backwards compatibility

    typealias ManageView = SubscriptionsView

    // MARK: - Summary card (amount + icons on one row, insight in the card)

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Monthly commitment")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(SpendyColors.textSecondary)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    monthlyAmount.fixedSize()
                    Spacer(minLength: 0)
                    if !summaryBadges.isEmpty {
                        OverlappingBadgeCluster(items: summaryBadges, badgeSize: 32)
                            .accessibilityHidden(true)
                    }
                }
                monthlyAmount
            }
            heroSecondaryLine

            if let next = nextUpcomingSubscription {
                Divider().padding(.vertical, 4)
                nextBillRow(next)
            }

            if !cardInsights.isEmpty {
                Divider().padding(.vertical, 4)
                SpendyInsightSummary(moments: cardInsights, onSelect: handleInsightDestination)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background { groupedCardBackground }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Monthly subscription total")
    }

    private var monthlyAmount: some View {
        Text(totalMonthly.formattedCurrency(symbol: store.currencySymbol, decimals: 2))
            .font(.largeTitle.weight(.bold).monospacedDigit())
            .foregroundStyle(SpendyColors.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .contentTransition(.numericText())
    }

    private var cardInsights: [InsightMoment] {
        subscriptionInsightMoments
    }

    private var heroSecondaryLine: some View {
        HStack(spacing: 6) {
            Text("\(totalAnnual.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/yr")
                .font(AppTypography.footnoteMedium)
                .foregroundStyle(SpendyColors.textSecondary)

            if chargesThisMonth > 0 {
                Text("·")
                    .foregroundStyle(SpendyColors.textTertiary)
                Text("\(chargesThisMonth.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) this month")
                    .font(AppTypography.footnoteMedium.weight(.semibold))
                    .foregroundStyle(overdueCount > 0 ? SpendyColors.expenseRed : SpendyColors.textSecondary)
            } else {
                Text("·")
                    .foregroundStyle(SpendyColors.textTertiary)
                Text("\(activeCount) active")
                    .font(AppTypography.footnoteMedium)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private func nextBillRow(_ sub: Subscription) -> some View {
        Button {
            HapticsManager.shared.trigger(.selection)
            subscriptionTransitionID = AppTransitionIDs.nextBill(sub.id)
            selectedSubscriptionForDetail = sub
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(sub.isTrial ? "Next trial ending" : "Next payment")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text(sub.name)
                        .font(.headline)
                        .foregroundStyle(SpendyColors.textPrimary)
                    Text(relativeDueText(for: sub.nextBillingDate, isTrial: sub.isTrial))
                        .font(.footnote)
                        .foregroundStyle(SpendyColors.textSecondary)
                }

                Spacer(minLength: 8)
                
                Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(SpendyColors.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .spendyNavigationSource(AppTransitionIDs.nextBill(sub.id), in: subscriptionTransitions)
        .accessibilityLabel("Next up \(sub.name)")
        .accessibilityValue("\(sub.amount.formattedCurrency(symbol: store.currencySymbol)), \(relativeDueText(for: sub.nextBillingDate, isTrial: sub.isTrial))")
    }

    private func handleInsightDestination(_ destination: InsightDestination) {
        if case .subscriptionDetail(let id) = destination {
            if let match = store.subscriptions.first(where: { $0.id.uuidString.lowercased() == id.lowercased() }) {
                subscriptionTransitionID = nil
                selectedSubscriptionForDetail = match
            }
        }
    }

    // MARK: - Subscriptions List Section

    private var subscriptionsListSection: some View {
        Group {
            if displayedSubscriptions.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    sectionDisclosure(
                        "Tracked subscriptions",
                        count: displayedSubscriptions.count,
                        isExpanded: $showTrackedSubscriptions
                    )
                    .accessibilityIdentifier("tracked-subscriptions-disclosure")

                    if showTrackedSubscriptions {
                        SpendyGroupedList(
                            items: displayedSubscriptions,
                            iconWidth: SubscriptionProgressRingBadge.Size.medium.outerDimension,
                            rowSpacing: 14
                        ) { sub in
                            subscriptionRowCard(sub: sub)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subscription Row Card

    private func subscriptionRowCard(sub: Subscription) -> some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            subscriptionTransitionID = AppTransitionIDs.subscriptionRow(sub.id)
            selectedSubscriptionForDetail = sub
        }) {
            SpendyRowContent(spacing: 14) {
                SubscriptionProgressRingBadge(
                    subscription: sub,
                    size: .medium
                )
            } content: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(sub.name)
                        .font(AppTypography.rowTitle)
                        .foregroundStyle(
                            sub.isPaused
                                ? SpendyColors.textTertiary
                                : SpendyColors.textPrimary
                        )
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(sub.cycle.label)
                            .font(AppTypography.footnoteMedium)
                            .foregroundStyle(SpendyColors.textSecondary)

                        Text("·")
                            .font(.system(size: 10))
                            .foregroundStyle(SpendyColors.textTertiary)

                        Text(relativeDueText(for: sub.nextBillingDate, isTrial: sub.isTrial))
                            .font(AppTypography.footnoteMedium.weight(.semibold))
                            .foregroundStyle(dueColor(for: sub.nextBillingDate))
                            .lineLimit(1)

                        statusBadge(for: sub)
                    }
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            } value: {
                Text(sub.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                    .spendyRowAmount()
                    .foregroundStyle(
                        sub.isPaused
                            ? SpendyColors.textTertiary
                            : SpendyColors.textPrimary
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .spendyNavigationSource(AppTransitionIDs.subscriptionRow(sub.id), in: subscriptionTransitions)
        .popoverTip(tipsAllowed && store.hasCompletedOnboarding && sub.id == displayedSubscriptions.first?.id && selectedSubscriptionForDetail == nil && !showAddSubscription && subscriptionToEdit == nil ? SubscriptionActionsTip() : nil)
        .contextMenu {
            Button {
                HapticsManager.shared.trigger(.light)
                subscriptionTransitionID = AppTransitionIDs.subscriptionRow(sub.id)
                selectedSubscriptionForDetail = sub
            } label: {
                Label("View Details", systemImage: "info.circle")
            }

            Button {
                HapticsManager.shared.trigger(.light)
                SubscriptionActionsTip().invalidate(reason: .actionPerformed)
                subscriptionToEdit = sub
            } label: {
                Label("Edit Subscription", systemImage: "pencil")
            }

            Button {
                HapticsManager.shared.trigger(.light)
                SubscriptionActionsTip().invalidate(reason: .actionPerformed)
                store.toggleSubscriptionPause(id: sub.id)
            } label: {
                Label(
                    sub.isPaused ? "Resume Subscription" : "Pause Subscription",
                    systemImage: sub.isPaused ? "play.fill" : "pause.fill"
                )
            }

            Button {
                HapticsManager.shared.trigger(.light)
                SubscriptionActionsTip().invalidate(reason: .actionPerformed)
                store.cancelSubscription(id: sub.id)
            } label: {
                Label("Cancel Subscription", systemImage: "xmark.circle")
            }

            Divider()

            Button(role: .destructive) {
                subscriptionToDelete = sub
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for sub: Subscription) -> some View {
        if sub.isTrial {
            Text("Trial")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(SpendyColors.warningOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(SpendyColors.warningOrange.opacity(0.14), in: Capsule())
        } else if sub.isPaused {
            Text("Paused")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(SpendyColors.separator, in: Capsule())
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        SpendyPlainEmptyState(
            title: "No subscriptions yet",
            message: "Keep your recurring payments and upcoming renewals together.",
            icon: "arrow.trianglehead.2.clockwise.rotate.90",
            actionTitle: "Add subscription"
        ) {
            showAddSubscription = true
        }
    }

    // MARK: - Past & Cancelled Section

    @ViewBuilder
    private var pastAndCancelledSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionDisclosure("Past & cancelled", count: cancelledSubs.count, isExpanded: $showCancelledSubs)
                .accessibilityIdentifier("past-subscriptions-disclosure")

            if showCancelledSubs {
                SpendyGroupedList(items: cancelledSubs,
                    iconWidth: SpendyIconBadge.Size.small.dimension,
                    rowSpacing: 14) { sub in
                    cancelledRow(sub)
                }
            }
        }
    }

    private func sectionDisclosure(_ title: String, count: Int, isExpanded: Binding<Bool>) -> some View {
        Button {
            HapticsManager.shared.trigger(.selection)
            withAnimation(reduceMotion ? nil : AppMotion.snappySpring) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Text(title).font(.headline)
                Text(count, format: .number)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(SpendyColors.textSecondary)
                Spacer()
                Image(systemName: SFIcons.chevronDown)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 180 : 0))
            }
            .foregroundStyle(SpendyColors.textPrimary)
            .padding(.horizontal, 4)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue("\(count), \(isExpanded.wrappedValue ? "Expanded" : "Collapsed")")
    }

    private func cancelledRow(_ sub: Subscription) -> some View {
        Button {
            selectedSubscriptionForDetail = sub
        } label: {
            SpendyRowContent(spacing: 14) {
                SpendyIconBadge(
                    sfSymbol: sub.sfSymbol,
                    color: SpendyColors.separator,
                    size: .small,
                    style: .circle,
                    monogramName: sub.name
                )

            } content: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sub.name)
                        .font(AppTypography.rowTitle)
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text("Cancelled")
                        .font(AppTypography.footnoteMedium)
                        .foregroundStyle(SpendyColors.expenseRed.opacity(0.85))
                }

            } value: {
                Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                    .spendyRowAmount()
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .contextMenu {
            Button {
                var updated = sub
                updated.status = "active"
                updated.isPaused = false
                store.updateSubscription(updated)
            } label: {
                Label("Reactivate", systemImage: "arrow.clockwise")
            }
            Button(role: .destructive) {
                subscriptionToDelete = sub
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Helper Functions

fileprivate func relativeDueText(for date: Date, isTrial: Bool) -> String {
    let calendar = Calendar.current
    let now = calendar.startOfDay(for: Date())
    let target = calendar.startOfDay(for: date)
    let days = calendar.dateComponents([.day], from: now, to: target).day ?? 0
    let prefix = isTrial ? "Ends" : "Due"
    if days < 0        { return "\(abs(days))d overdue" }
    else if days == 0  { return "\(prefix) today" }
    else if days == 1  { return "\(prefix) tomorrow" }
    else if days <= 10 { return "\(prefix) in \(days)d" }
    else {
        return "\(prefix) \(SpendyDateFormatterCache.monthDay.string(from: date))"
    }
}

fileprivate func dueColor(for date: Date) -> Color {
    let days = Calendar.current.dateComponents(
        [.day],
        from: Calendar.current.startOfDay(for: Date()),
        to: Calendar.current.startOfDay(for: date)
    ).day ?? 0
    if days < 0    { return SpendyColors.expenseRed }
    if days <= 3   { return SpendyColors.warningOrange }
    return SpendyColors.textTertiary
}
