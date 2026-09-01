//
//  ManageView.swift
//  Spendy
//
//  Dedicated Full-Screen Subscriptions Management Hub.
//  Features: Solid Pure Dark Theme, Floating Header on Top Layer,
//  Balanced Hero Spend Card with Left Spend Metrics and Right Top 5 Bubble Cluster,
//  High-Contrast Filter Capsules (Blue active / Dark card unselected),
//  Clean Subscription Row Cards, and Standard Floating Plus Button.
//

import SwiftUI

enum SubscriptionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case paid = "Paid"
    case trial = "Trials"
    case paused = "Paused"

    var id: String { rawValue }
}

// MARK: - Subscriptions Full-Screen View

struct SubscriptionsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var onDismiss: (() -> Void)? = nil
    var topControlsNamespace: Namespace.ID? = nil

    @State private var subFilter: SubscriptionFilter = .all
    @State private var showAddSubscription: Bool = false
    @State private var subscriptionToEdit: Subscription? = nil
    @State private var selectedSubscriptionForDetail: Subscription? = nil
    @State private var showCancelledSubs: Bool = false
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

    private var pausedCount: Int {
        activeAndTrialSubs.filter { $0.isPaused }.count
    }

    private var trialCount: Int {
        activeAndTrialSubs.filter { $0.isTrial }.count
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

    private var upcomingSubscriptions: [Subscription] {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        return activeAndTrialSubs.filter { sub in
            guard !sub.isPaused else { return false }
            let target = calendar.startOfDay(for: sub.nextBillingDate)
            let days = calendar.dateComponents([.day], from: now, to: target).day ?? 999
            return days >= 0 && days <= 10
        }.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }

    private var nextDueSubscription: Subscription? {
        upcomingSubscriptions.first ?? activeAndTrialSubs.filter { !$0.isPaused }.sorted(by: { $0.nextBillingDate < $1.nextBillingDate }).first
    }

    // Top 5 Subscription Badges for Bubble Cluster
    private var top5SubscriptionBadges: [BadgeItem] {
        activeAndTrialSubs
            .sorted(by: { $0.amount > $1.amount })
            .prefix(5)
            .map { sub in
                BadgeItem(icon: sub.sfSymbol, color: sub.color)
            }
    }

    private var filteredSubscriptions: [Subscription] {
        activeAndTrialSubs.filter { sub in
            switch subFilter {
            case .all:    return true
            case .paid:   return !sub.isTrial && !sub.isPaused
            case .trial:  return sub.isTrial
            case .paused: return sub.isPaused
            }
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Clean Solid Dark Background (No Gradient)
            SpendyColors.appBackground
                .ignoresSafeArea()

            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        Spacer().frame(height: 56) // Top clearance for floating header

                        // 1. Balanced Hero Spend Card (Metrics on Left, Top 5 Bubble Cluster on Right)
                        balancedHeroSpendCard
                            .padding(.horizontal, 20)

                        // 2. Subscriptions List Section (with Filters & Cards)
                        subscriptionsListSection
                            .padding(.horizontal, 20)

                        // 3. Past & Cancelled Section
                        if !cancelledSubs.isEmpty {
                            pastAndCancelledSection
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 110) // Clearance for bottom floating plus button
                }
                .scrollDismissesKeyboard(.interactively)

                // Sticky Floating Header Bar on Top Layer
                headerBar
                    .padding(.top, 8)
                    .zIndex(100)
            }

            // Bottom Floating Action Button (Add +) on Top Layer
            VStack {
                Spacer()
                bottomFloatingBar
            }
            .zIndex(100)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            NotificationManager.shared.syncAllSubscriptionReminders(subscriptions: store.subscriptions)
        }
        .sheet(isPresented: $showAddSubscription) {
            AddSubscriptionSheet()
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $subscriptionToEdit) { sub in
            AddSubscriptionSheet(subscriptionToEdit: sub)
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $selectedSubscriptionForDetail) { sub in
            SubscriptionQuickActionSheet(sub: sub)
        }
    }

    // MARK: - Top Header Bar (Elevated on Top Layer)

    private var headerBar: some View {
        HStack(alignment: .center) {
            // Circular Glass Back Button
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Back",
                morphID: "backButton",
                namespace: subsNamespace
            ) {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }
            .optionalMatchedGeometry(id: "topControl_left", in: topControlsNamespace)

            Spacer()

            Text("Subscriptions")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Symmetrical Placeholder
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
    }

    // Typealias for backwards compatibility
    typealias ManageView = SubscriptionsView

    // MARK: - Balanced Hero Spend Card (Left: Metrics, Right: Top 5 Bubble Cluster)

    private var balancedHeroSpendCard: some View {
        HStack(alignment: .center, spacing: 14) {
            // Left Column: Total Monthly Spend & On-Point Metrics
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("Total Monthly")
                        .font(AppTypography.footnoteMedium)
                        .foregroundStyle(SpendyColors.textSecondary)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(SpendyColors.incomeGreen)
                            .frame(width: 5, height: 5)
                        Text("\(activeCount) active")
                            .font(AppTypography.eyebrow)
                            .foregroundStyle(SpendyColors.incomeGreen)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(SpendyColors.incomeGreen.opacity(0.12), in: Capsule())
                }

                Text(totalMonthly.formattedCurrency(symbol: store.currencySymbol))
                    .spendyNumberFont(size: 30, weight: .heavy, tracking: -0.9)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 6) {
                    Text("\(totalAnnual.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/yr")
                        .font(AppTypography.captionMedium)
                        .foregroundStyle(SpendyColors.textTertiary)

                    if let next = nextDueSubscription {
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(SpendyColors.textTertiary)

                        Text(relativeDueText(for: next.nextBillingDate, isTrial: next.isTrial))
                            .font(AppTypography.captionMedium.weight(.semibold))
                            .foregroundStyle(dueColor(for: next.nextBillingDate))
                    }
                }
            }

            Spacer(minLength: 8)

            // Right Column: Top 5 Overlapping Subscription Icon Bubble Cluster
            if !top5SubscriptionBadges.isEmpty {
                OverlappingBadgeCluster(items: top5SubscriptionBadges, badgeSize: 36)
            } else {
                Circle()
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: SFIcons.subscriptions)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }

    // MARK: - Subscriptions List Section

    private var subscriptionsListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Horizontal Type Filter Pills (High-Contrast: Blue active / Dark card unselected)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SubscriptionFilter.allCases) { filter in
                        let isSelected = subFilter == filter
                        Button {
                            HapticsManager.shared.trigger(.selection)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                subFilter = filter
                            }
                        } label: {
                            Text(filter.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Color.white : SpendyColors.textSecondary)
                                .padding(.horizontal, 16)
                                .frame(height: 34)
                                .background {
                                    Capsule(style: .continuous)
                                        .fill(isSelected ? SpendyColors.primaryBlue : SpendyColors.cardBackground)
                                        .overlay {
                                            Capsule(style: .continuous)
                                                .stroke(isSelected ? Color.clear : SpendyColors.separator, lineWidth: 0.8)
                                        }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Section Header: Title & Count Badge
            HStack {
                Text(subFilter == .all ? "Recurring Services" : "\(subFilter.rawValue) Services")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)

                Spacer()

                Text("\(filteredSubscriptions.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
            }
            .padding(.top, 4)

            // List of Subscription Cards
            if filteredSubscriptions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredSubscriptions) { sub in
                        subscriptionRowCard(sub: sub)
                    }
                }
            }
        }
    }

    // MARK: - Subscription Row Card

    private func subscriptionRowCard(sub: Subscription) -> some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            selectedSubscriptionForDetail = sub
        }) {
            HStack(spacing: AppSpacing.md14) {
                // Vibrant Subscription Icon Badge
                SpendyIconBadge(
                    sfSymbol: sub.sfSymbol,
                    color: Color(hex: sub.colorHex),
                    size: .medium,
                    style: .circle
                )

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
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
                            .foregroundStyle(SpendyColors.textTertiary)

                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(SpendyColors.textTertiary)

                        Text(relativeDueText(for: sub.nextBillingDate, isTrial: sub.isTrial))
                            .font(AppTypography.footnoteMedium.weight(.semibold))
                            .foregroundStyle(dueColor(for: sub.nextBillingDate))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                        .spendyNumberFont(size: 16, weight: .bold, tracking: -0.4)
                        .foregroundStyle(
                            sub.isPaused
                                ? SpendyColors.textTertiary
                                : SpendyColors.textPrimary
                        )

                    statusBadge(for: sub)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.cardRow, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppRadius.cardRow, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: AppGlass.strokeWidth)
                    }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                HapticsManager.shared.trigger(.light)
                selectedSubscriptionForDetail = sub
            } label: {
                Label("View Details", systemImage: "info.circle")
            }

            Button {
                HapticsManager.shared.trigger(.light)
                subscriptionToEdit = sub
            } label: {
                Label("Edit Subscription", systemImage: "pencil")
            }

            Button {
                HapticsManager.shared.trigger(.light)
                store.toggleSubscriptionPause(id: sub.id)
            } label: {
                Label(
                    sub.isPaused ? "Resume Subscription" : "Pause Subscription",
                    systemImage: sub.isPaused ? "play.fill" : "pause.fill"
                )
            }

            Button {
                HapticsManager.shared.trigger(.light)
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
        } else {
            Text("Active")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(SpendyColors.textPrimary.opacity(0.08), in: Capsule())
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 36))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.top, 24)

            Text("No subscriptions found")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)

            Button("Add Subscription") {
                showAddSubscription = true
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(SpendyColors.primaryBlue)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }

    // MARK: - Past & Cancelled Section

    @ViewBuilder
    private var pastAndCancelledSection: some View {
        VStack(spacing: 10) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showCancelledSubs.toggle()
                }
            }) {
                HStack {
                    Text("Past & Cancelled (\(cancelledSubs.count))")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                    Spacer()
                    Image(systemName: SFIcons.chevronDown)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .rotationEffect(.degrees(showCancelledSubs ? 180 : 0))
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(SpendyColors.cardBackgroundSecondary)
                }
            }
            .buttonStyle(.plain)

            if showCancelledSubs {
                VStack(spacing: 10) {
                    ForEach(cancelledSubs) { sub in
                        HStack(spacing: 14) {
                            SpendyIconBadge(
                                sfSymbol: sub.sfSymbol,
                                color: SpendyColors.separator,
                                size: .small
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(sub.name)
                                    .font(.system(.body, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textSecondary)
                                Text("Cancelled")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(SpendyColors.expenseRed.opacity(0.85))
                            }

                            Spacer()

                            Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                                .font(.system(.body, weight: .bold))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(SpendyColors.cardBackgroundSecondary.opacity(0.6))
                        }
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
            }
        }
    }

    // MARK: - Bottom Floating Action Bar (Standard Liquid Glass Plus Button)

    private var bottomFloatingBar: some View {
        HStack {
            Spacer()

            // Standard Liquid Glass Floating Quick Add Button (+)
            Button {
                HapticsManager.shared.trigger(.cardSnap)
                showAddSubscription = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .frame(width: 54, height: 54)
                    .nativeLiquidGlassCircle(isInteractive: true)
                    .shadow(color: Color.black.opacity(0.18), radius: 14, y: 6)
            }
            .buttonStyle(LiquidScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
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
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        return "\(prefix) \(fmt.string(from: date))"
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
