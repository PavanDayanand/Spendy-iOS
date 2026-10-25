//
//  ManageView.swift
//  Spendy
//
//  Subscriptions dashboard: uncarded monthly total, sentence insights,
//  and a single grouped list card. Detail sheet is unchanged.
//

import SwiftUI
import TipKit

// MARK: - Subscriptions Full-Screen View

struct SubscriptionsView: View {
    @Environment(\.spendyTipsAllowed) private var tipsAllowed
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var isPushed: Bool = false
    var initialSelectedSubscriptionId: String? = nil
    var onDismiss: (() -> Void)? = nil
    var topControlsNamespace: Namespace.ID? = nil
    var sharedNavigationHeader: AnalyticsNavigationHeaderState? = nil

    @State private var showAddSubscription: Bool = false
    @State private var pendingSubscriptionEdit: Subscription? = nil
    @State private var subscriptionToEdit: Subscription? = nil
    @State private var selectedSubscriptionForDetail: Subscription? = nil
    @State private var showCancelledSubs: Bool = false
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
    private var top5SubscriptionBadges: [BadgeItem] {
        activeAndTrialSubs
            .sorted(by: { $0.amount > $1.amount })
            .prefix(5)
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
        return Array(moments.filter { !$0.isInsufficientData }.prefix(5))
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
                        if !isPushed {
                            tabHeaderBar(showsControls: false)
                        } else {
                            Text("Subscriptions")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .padding(.top, 8)
                                .accessibilityAddTraits(.isHeader)
                                .opacity(sharedNavigationHeader == nil ? 1 : 0)
                                .accessibilityHidden(sharedNavigationHeader != nil)
                        }

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
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)
                if isPushed {
                    if sharedNavigationHeader == nil {
                        topHeaderBar.padding(.bottom, 6)
                    }
                } else {
                    tabHeaderBar(showsControls: true)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
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
        .onAppear {
            configureNavigationHeader()
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

    // MARK: - Tab Header Bar (Large Title with Top Right 44pt Add Button)
    private func tabHeaderBar(showsControls: Bool) -> some View {
        HStack(alignment: .center) {
            Text("Subscriptions")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(SpendyColors.textPrimary)
                .opacity(showsControls ? 0 : 1)
                .accessibilityHidden(showsControls)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            if showsControls {
            GlassCircleButton(
                icon: "plus",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .light,
                accessibilityLabel: "Add Subscription"
            ) {
                HapticsManager.shared.trigger(.selection)
                showAddSubscription = true
            }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private func configureNavigationHeader() {
        guard isPushed else { return }
        let backAction = onDismiss
        let dismissAction = dismiss
        let addSubscription = $showAddSubscription
        sharedNavigationHeader?.show(title: "Subscriptions", onBack: {
            if let backAction { backAction() } else { dismissAction() }
        }, primaryAction: StackHeaderAction(id: "subscriptions-add", title: "Add Subscription", symbol: "plus") {
            addSubscription.wrappedValue = true
        })
    }

    // MARK: - Top Header Bar (When Pushed from Home with Liquid Glass Morph)
    private var topHeaderBar: some View {
        HStack {
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 15,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Back",
                morphID: "topControl_left",
                namespace: topControlsNamespace
            ) {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }

            Spacer()

            Text("Subscriptions")
                .hidden()
                .accessibilityHidden(true)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            GlassCircleButton(
                icon: "plus",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .light,
                accessibilityLabel: "Add Subscription"
            ) {
                HapticsManager.shared.trigger(.selection)
                showAddSubscription = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // Typealias for backwards compatibility

    typealias ManageView = SubscriptionsView

    // MARK: - Summary card (amount + icons on one row, insight in the card)

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Total monthly")
                        .font(AppTypography.itemTitle)
                        .foregroundStyle(SpendyColors.textSecondary)

                    Text(totalMonthly.formattedCurrency(symbol: store.currencySymbol, decimals: 2))
                        .font(.system(size: 32, weight: .heavy, design: .default))
                        .monospacedDigit()
                        .tracking(-1.0)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .contentTransition(.numericText())

                    heroSecondaryLine
                }

                Spacer(minLength: 8)

                if !top5SubscriptionBadges.isEmpty {
                    OverlappingBadgeCluster(items: top5SubscriptionBadges, badgeSize: 38)
                        .accessibilityHidden(true)
                }
            }

            if !cardInsights.isEmpty {
                Divider()
                    .overlay(SpendyColors.separator.opacity(0.7))
                VStack(alignment: .leading, spacing: 8) {
                    SpendyInsightSummary(moments: cardInsights, onSelect: handleInsightDestination)
                }
            } else if let next = nextUpcomingSubscription {
                Divider()
                    .overlay(SpendyColors.separator.opacity(0.7))
                nextBillRow(next)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { groupedCardBackground }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Monthly subscription total")
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
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let billDay = calendar.startOfDay(for: sub.nextBillingDate)
        let daysUntil = calendar.dateComponents([.day], from: today, to: billDay).day ?? 0
        let daysText = daysUntil <= 0 ? "TODAY" : (daysUntil == 1 ? "1d" : "\(daysUntil)d")
        
        return Button {
            HapticsManager.shared.trigger(.selection)
            subscriptionTransitionID = AppTransitionIDs.nextBill(sub.id)
            selectedSubscriptionForDetail = sub
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Next up \(sub.name)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                    Text("\(sub.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) · \(relativeDueText(for: sub.nextBillingDate, isTrial: sub.isTrial))")
                        .font(AppTypography.footnoteMedium)
                        .foregroundStyle(SpendyColors.textSecondary)
                }

                Spacer(minLength: 8)
                
                Text(daysText)
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                    .foregroundStyle(SpendyColors.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .spendyNavigationSource(AppTransitionIDs.nextBill(sub.id), in: subscriptionTransitions)
        .accessibilityLabel("Next up \(sub.name)")
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
                VStack(spacing: 0) {
                    ForEach(Array(displayedSubscriptions.enumerated()), id: \.element.id) { index, sub in
                        subscriptionRowCard(sub: sub)

                        if index < displayedSubscriptions.count - 1 {
                            Rectangle()
                                .fill(SpendyColors.separator.opacity(0.6))
                                .frame(height: 0.5)
                                .padding(.leading, 74)
                                .padding(.trailing, 16)
                        }
                    }
                }
                .background { groupedCardBackground }
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
            HStack(alignment: .center, spacing: 14) {
                SubscriptionProgressRingBadge(
                    subscription: sub,
                    size: .medium
                )

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

                Text(sub.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 16.5, weight: .bold, design: .default))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .layoutPriority(1)
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
                HapticsManager.shared.trigger(.warning)
                withAnimation(AppMotion.snappySpring) {
                    store.deleteSubscription(id: sub.id)
                }
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
            message: "Tap the plus button at the top to add a recurring payment."
        )
    }

    // MARK: - Past & Cancelled Section

    @ViewBuilder
    private var pastAndCancelledSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    showCancelledSubs.toggle()
                }
            } label: {
                HStack {
                    Text("Past & cancelled")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Text("\(cancelledSubs.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Spacer()
                    Image(systemName: SFIcons.chevronDown)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .rotationEffect(.degrees(showCancelledSubs ? 180 : 0))
                }
                .padding(.horizontal, 4)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Past and cancelled, \(cancelledSubs.count)")

            if showCancelledSubs {
                VStack(spacing: 0) {
                    ForEach(Array(cancelledSubs.enumerated()), id: \.element.id) { index, sub in
                        cancelledRow(sub)
                        if index < cancelledSubs.count - 1 {
                            Rectangle()
                                .fill(SpendyColors.separator.opacity(0.6))
                                .frame(height: 0.5)
                                .padding(.leading, 66)
                                .padding(.trailing, 16)
                        }
                    }
                }
                .background { groupedCardBackground }
            }
        }
    }

    private func cancelledRow(_ sub: Subscription) -> some View {
        HStack(spacing: 14) {
            SpendyIconBadge(
                sfSymbol: sub.sfSymbol,
                color: SpendyColors.separator,
                size: .small,
                style: .circle,
                monogramName: sub.name
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name)
                    .font(AppTypography.rowTitle)
                    .foregroundStyle(SpendyColors.textSecondary)
                Text("Cancelled")
                    .font(AppTypography.footnoteMedium)
                    .foregroundStyle(SpendyColors.expenseRed.opacity(0.85))
            }

            Spacer()

            Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                .font(.system(size: 16, weight: .bold, design: .default))
                .monospacedDigit()
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contextMenu {
            Button {
                var updated = sub
                updated.status = "active"
                store.updateSubscription(updated)
            } label: {
                Label("Reactivate", systemImage: "arrow.clockwise")
            }
            Button(role: .destructive) {
                store.deleteSubscription(id: sub.id)
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
