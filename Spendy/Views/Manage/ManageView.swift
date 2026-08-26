//
//  ManageView.swift
//  Spendy
//
//  Subscriptions Management Hub — Airy Hero Stats, Native Action Cards, Apple Quick-Pay Drawer
//

import SwiftUI

enum SubscriptionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case paid = "Paid"
    case trial = "Trials"
    case paused = "Paused"

    var id: String { rawValue }
}

// MARK: - Manage View

struct ManageView: View {
    @Environment(ExpenseStore.self) private var store

    @State private var subFilter: SubscriptionFilter = .all
    @State private var showAddSubscription: Bool = false
    @State private var subscriptionToEdit: Subscription? = nil
    @State private var selectedSubscriptionForDetail: Subscription? = nil
    @State private var showCancelledSubs: Bool = false
    @Namespace private var manageNamespace

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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // 1. Dynamic Canvas Background framing the centerpiece card
                store.canvasBackgroundColor
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        // 2. Detached Top Capsule Navbar (44x44 Circular Action Buttons)
                        topDetachedPillBar
                            .padding(.top, 4)

                        // 3. Main Centerpiece Sheet Card
                        centerpieceWhiteCard
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddSubscription) {
                AddSubscriptionSheet()
            }
            .sheet(item: $subscriptionToEdit) { sub in
                AddSubscriptionSheet(subscriptionToEdit: sub)
            }
            .sheet(item: $selectedSubscriptionForDetail) { sub in
                SubscriptionQuickActionSheet(sub: sub) { subToEdit in
                    subscriptionToEdit = subToEdit
                }
            }
        }
    }

    // MARK: - 1. Top Detached Capsule Navbar (44x44 Circular Buttons)
    private var topDetachedPillBar: some View {
        HStack(alignment: .center) {
            // Subscriptions Repeat Badge (44x44 Circle)
            ZStack {
                Circle()
                    .fill(store.cardChipBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: "repeat")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(store.canvasBackgroundColor)
            }

            Spacer()

            // Top Right Action Buttons Group (Add Subscription - 44x44 Circle)
            HStack(spacing: 8) {
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showAddSubscription = true
                }) {
                    ZStack {
                        Circle()
                            .fill(store.cardChipBackground)
                            .frame(width: 44, height: 44)
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(store.cardChipText)
                    }
                }
                .buttonStyle(PressableSpringButtonStyle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(store.cardBackgroundColor)
                .overlay(
                    Capsule().stroke(store.cardBorderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 3)
        }
    }

    // MARK: - 2. Main Centerpiece Sheet Card
    private var centerpieceWhiteCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header Row inside Card: Title + Subtitle
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Subscriptions")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(store.cardTextPrimary)

                    Text("\(activeCount) active • \(store.currencySymbol)\(String(format: "%.0f", totalMonthly))/mo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(store.cardTextSecondary)
                }

                Spacer()
            }

            Divider()
                .overlay(store.cardDividerColor)

            heroSpendSection
            upcomingActionSection
            filterBar
            mainList
            pastAndCancelled
        }
        .padding(20)
        .padding(.bottom, 100) // Full clearance for bottom GlassTabBar
        .background {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(store.cardBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 38, style: .continuous)
                        .stroke(store.cardBorderColor, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 24, y: 8)
        }
    }

    // MARK: - Hero Spend Section

    private var heroSpendSection: some View {
        HStack(spacing: 12) {
            heroStatCard(
                title: "MONTHLY",
                amount: totalMonthly,
                icon: "calendar",
                tint: store.canvasBackgroundColor
            )

            heroStatCard(
                title: "YEARLY",
                amount: totalAnnual,
                icon: "calendar.badge.clock",
                tint: SpendyColors.accentCyan
            )
        }
    }

    private func heroStatCard(title: String, amount: Double, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)

                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(store.cardTextSecondary)
                    .tracking(0.5)
            }

            Text(amount.formattedCurrency(symbol: store.currencySymbol))
                .font(.system(size: 22, weight: .heavy, design: .default).monospacedDigit())
                .foregroundStyle(store.cardTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(store.cardChipBackground)
        }
    }

    // MARK: - Upcoming Action Section (Hero Highlight)

    @ViewBuilder
    private var upcomingActionSection: some View {
        if let nextSub = upcomingSubscriptions.first {
            Button {
                selectedSubscriptionForDetail = nextSub
            } label: {
                HStack(spacing: 12) {
                    SpendyIconBadge(
                        sfSymbol: nextSub.sfSymbol,
                        color: Color(hex: nextSub.colorHex),
                        size: .medium,
                        style: .circle
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Next Due")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(SpendyColors.textTertiary)

                            Text("•")
                                .font(.system(size: 9))
                                .foregroundStyle(SpendyColors.textTertiary)

                            Text(relativeDueText(for: nextSub.nextBillingDate, isTrial: nextSub.isTrial))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(dueColor(for: nextSub.nextBillingDate))
                        }

                        Text(nextSub.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(nextSub.amount.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(size: 17, weight: .heavy, design: .default).monospacedDigit())
                            .foregroundStyle(SpendyColors.textPrimary)

                        HStack(spacing: 4) {
                            Text(nextSub.cycle.label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(SpendyColors.textTertiary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(SpendyColors.textTertiary.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Apple Native Filter & Sort Menu Bar

    private var filterBar: some View {
        SpendyGlassEffectContainer(spacing: 0) {
            HStack(alignment: .center) {
                Text(subFilter == .all ? "All Subscriptions" : "\(subFilter.rawValue) Subscriptions")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)

                Spacer()

                Menu {
                    Picker("Filter Subscriptions", selection: $subFilter) {
                        ForEach(SubscriptionFilter.allCases) { filter in
                            Label(filter.rawValue, systemImage: filterSystemImage(filter))
                                .tag(filter)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "#007AFF"))

                        Text(subFilter.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .nativeLiquidGlassCapsule(isInteractive: true)
                    .glassMorphID("manageFilterCapsule", in: manageNamespace)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
    }

    private func filterSystemImage(_ filter: SubscriptionFilter) -> String {
        switch filter {
        case .all: return "square.grid.2x2"
        case .paid: return "checkmark.circle"
        case .trial: return "clock"
        case .paused: return "pause.circle"
        }
    }

    // MARK: - Main List

    private var mainList: some View {
        VStack(spacing: 0) {
            if filteredSubscriptions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 14) {
                    ForEach(Array(filteredSubscriptions.enumerated()), id: \.element.id) { index, sub in
                        SubscriptionRowCard(
                            sub: sub,
                            currencySymbol: store.currencySymbol,
                            onTap: {
                                HapticsManager.shared.trigger(.light)
                                selectedSubscriptionForDetail = sub
                            }
                        )
                        .contextMenu {
                            Button {
                                selectedSubscriptionForDetail = sub
                            } label: {
                                Label("Quick Settle", systemImage: "creditcard.fill")
                            }

                            Button {
                                subscriptionToEdit = sub
                            } label: {
                                Label("Edit Full Details", systemImage: SFIcons.edit)
                            }

                            Button {
                                store.toggleSubscriptionPause(id: sub.id)
                            } label: {
                                Label(
                                    sub.isPaused ? "Resume Subscription" : "Pause Subscription",
                                    systemImage: sub.isPaused ? "play.fill" : "pause.fill"
                                )
                            }

                            Button {
                                store.cancelSubscription(id: sub.id)
                            } label: {
                                Label("Cancel Subscription", systemImage: SFIcons.close)
                            }

                            Button(role: .destructive) {
                                store.deleteSubscription(id: sub.id)
                            } label: {
                                Label("Delete", systemImage: SFIcons.delete)
                            }
                        }

                        if index < filteredSubscriptions.count - 1 {
                            Divider()
                                .overlay(SpendyColors.separator)
                        }
                    }

                    // Inline "+ Add a new subscription" Button (Image 1 Style)
                    Divider()
                        .overlay(SpendyColors.separator)

                    Button {
                        HapticsManager.shared.trigger(.light)
                        showAddSubscription = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                            Text("Add a new subscription")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(SpendyColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)

            VStack(spacing: 4) {
                Text("No subscriptions found")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)

                Text("Add your recurring bills and streaming services to track upcoming payments.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                HapticsManager.shared.trigger(.medium)
                showAddSubscription = true
            } label: {
                Text("Add Subscription")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(uiColor: .dynamic(light: .white, dark: .black)))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(SpendyColors.primaryBlue, in: Capsule())
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }

    // MARK: - Past & Cancelled

    @ViewBuilder
    private var pastAndCancelled: some View {
        if !cancelledSubs.isEmpty {
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
                                    Label("Delete", systemImage: SFIcons.delete)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Subscription Row Card

struct SubscriptionRowCard: View {
    let sub: Subscription
    let currencySymbol: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Circle Icon Avatar
                SpendyIconBadge(
                    sfSymbol: sub.sfSymbol,
                    color: Color(hex: sub.colorHex),
                    size: .medium
                )

                // Name + metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text(sub.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(
                            sub.isPaused
                                ? SpendyColors.textTertiary
                                : SpendyColors.textPrimary
                        )
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(sub.cycle.label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)

                        Text("·")
                            .font(.system(size: 10))
                            .foregroundStyle(SpendyColors.textTertiary)

                        Text(relativeDueText(for: sub.nextBillingDate, isTrial: sub.isTrial))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(dueColor(for: sub.nextBillingDate))
                    }
                }

                Spacer()

                // Amount + status pill
                VStack(alignment: .trailing, spacing: 4) {
                    Text(sub.amount.formattedCurrency(symbol: currencySymbol))
                        .font(.system(size: 15, weight: .bold, design: .default).monospacedDigit())
                        .foregroundStyle(
                            sub.isPaused
                                ? SpendyColors.textTertiary
                                : SpendyColors.textPrimary
                        )

                    statusBadge(for: sub)
                }

                // Chevron hint
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary.opacity(0.4))
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
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

    private func pillTag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.10), in: Capsule())
    }
}

// MARK: - Fileprivate Helpers

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

// MARK: - Pressable Spring Button Style
private struct PressableSpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.70), value: configuration.isPressed)
    }
}

