//
//  ManageView.swift
//  Spendy
//
//  Subscriptions Management Hub — Bold Hero Stats, Interactive Cards, Edit-on-Tap
//

import SwiftUI

enum SubscriptionFilter: String, CaseIterable, Identifiable {
    case all
    case paid
    case trial

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:   return "All"
        case .paid:  return "Paid"
        case .trial: return "Trials"
        }
    }
}

// MARK: - Manage View

struct ManageView: View {
    @Environment(ExpenseStore.self) private var store

    @State private var subFilter: SubscriptionFilter = .all
    @State private var showAddSubscription: Bool = false
    @State private var subscriptionToEdit: Subscription? = nil
    @State private var showCancelledSubs: Bool = false

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
            case .all:   return true
            case .paid:  return !sub.isTrial
            case .trial: return sub.isTrial
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidMeshBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        titleHeader
                        heroStatsCard
                        dueSoonAlertSlider
                        liquidGlassFilterPicker
                        mainList
                        pastAndCancelled
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 140)
                }
            }
            .overlay(alignment: .topTrailing) {
                GlassCircleButton(
                    icon: SFIcons.plus,
                    size: 44,
                    iconSize: 18,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .light,
                    accessibilityLabel: "Add Subscription"
                ) {
                    showAddSubscription = true
                }
                .padding(.trailing, 20)
                .padding(.top, 10)
                .zIndex(100)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddSubscription) {
                AddSubscriptionSheet()
            }
            .sheet(item: $subscriptionToEdit) { sub in
                AddSubscriptionSheet(subscriptionToEdit: sub)
            }
        }
    }

    // MARK: - Title Header

    private var titleHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Subscriptions")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(SpendyColors.textPrimary)
                Text("Manage recurring bills & free trials")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            Spacer()
        }
        .padding(.top, 10)
    }

    // MARK: - Hero Stats Card

    private var heroStatsCard: some View {
        GlassCard(cornerRadius: 24) {
            VStack(spacing: 0) {

                // Top — monthly number + sparkline
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MONTHLY SPEND")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(SpendyColors.textTertiary)

                        Text(totalMonthly.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(size: 38, weight: .heavy))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        Text(totalAnnual.formattedCurrency(symbol: store.currencySymbol) + "/yr")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }

                    Spacer()

                    // Same sparkline as the Dashboard account card
                    AccountsMiniSparkline()
                        .frame(width: 100, height: 44)
                }

                Divider()
                    .background(SpendyColors.separator)
                    .padding(.vertical, 14)

                // Bottom — stat pills row
                HStack(spacing: 10) {
                    statPill(
                        icon: "checkmark.circle.fill",
                        label: "Active",
                        value: "\(activeCount)",
                        iconColor: SpendyColors.textPrimary
                    )

                    if trialCount > 0 {
                        statPill(
                            icon: "clock.badge.checkmark.fill",
                            label: "Trials",
                            value: "\(trialCount)",
                            iconColor: SpendyColors.warningOrange
                        )
                    }

                    if pausedCount > 0 {
                        statPill(
                            icon: "pause.circle.fill",
                            label: "Paused",
                            value: "\(pausedCount)",
                            iconColor: SpendyColors.textTertiary
                        )
                    }

                }
            }
            .padding(.vertical, 2)
        }
    }


    // MARK: - Filter Picker

    private var liquidGlassFilterPicker: some View {
        GlassSegmentedPicker(
            selection: $subFilter,
            items: SubscriptionFilter.allCases,
            titleFor: { $0.label }
        )
    }

    private func statPill(icon: String, label: String, value: String, iconColor: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(iconColor)
            Text("\(value) \(label)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
    }

    // MARK: - Due Soon Alert Slider

    @ViewBuilder
    private var dueSoonAlertSlider: some View {
        if !upcomingSubscriptions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                    Text("Due Soon")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    Text("· next 10 days")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(upcomingSubscriptions) { sub in
                            DueSoonCard(
                                sub: sub,
                                currencySymbol: store.currencySymbol,
                                onTap: { subscriptionToEdit = sub },
                                onPaid: { store.markSubscriptionAsPaid(id: sub.id) },
                                onKeep: { store.keepSubscription(id: sub.id) },
                                onCancelTrial: { store.cancelSubscription(id: sub.id) }
                            )
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
    }

    // MARK: - Filter Picker

    private var filterPicker: some View {
        GlassSegmentedPicker(
            selection: $subFilter,
            items: SubscriptionFilter.allCases,
            titleFor: { $0.label }
        )
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
                                subscriptionToEdit = sub
                            }
                        )
                        .contextMenu {
                            Button {
                                subscriptionToEdit = sub
                            } label: {
                                Label("Edit Subscription", systemImage: SFIcons.edit)
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
        VStack(spacing: 12) {
            Image(systemName: SFIcons.subscriptions)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
            Text("No subscriptions here")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
            Text("Tap + to add your first one")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
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

    // MARK: - Due Date Helper

    private func dueText(for date: Date, isTrial: Bool) -> String {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: now, to: target).day ?? 0

        let prefix = isTrial ? "Trial ends" : "Due"
        if days < 0       { return "\(prefix) \(abs(days))d ago" }
        else if days == 0 { return "\(prefix) Today" }
        else if days == 1 { return "\(prefix) Tomorrow" }
        else if days <= 10 { return "\(prefix) in \(days)d" }
        else {
            let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
            return "\(prefix) \(fmt.string(from: date))"
        }
    }
}

// MARK: - Subscription Row Card

struct SubscriptionRowCard: View {
    let sub: Subscription
    let currencySymbol: String
    let onTap: () -> Void

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Circle Icon Avatar (Matching Subscription Color)
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
                        if sub.isTrial {
                            pillTag("Free Trial", color: SpendyColors.textPrimary)
                        } else {
                            pillTag(sub.cycle.label, color: SpendyColors.textSecondary)
                        }

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
                        .font(.system(size: 15, weight: .bold))
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
                    .foregroundStyle(SpendyColors.textTertiary.opacity(0.5))
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
                .background(SpendyColors.textPrimary.opacity(0.10), in: Capsule())
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

    private func relativeDueText(for date: Date, isTrial: Bool) -> String {
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

    private func dueColor(for date: Date) -> Color {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: date)
        ).day ?? 0
        if days < 0    { return SpendyColors.expenseRed }
        if days <= 3   { return SpendyColors.warningOrange }
        return SpendyColors.textTertiary
    }
}

// MARK: - Due Soon Card

struct DueSoonCard: View {
    let sub: Subscription
    let currencySymbol: String
    let onTap: () -> Void
    let onPaid: () -> Void
    let onKeep: () -> Void
    let onCancelTrial: () -> Void

    var urgencyColor: Color {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: sub.nextBillingDate)
        ).day ?? 0
        if days < 0    { return SpendyColors.expenseRed }
        if days <= 3   { return SpendyColors.warningOrange }
        return SpendyColors.primaryBlue
    }

    var dueLabel: String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: sub.nextBillingDate)
        ).day ?? 0
        let prefix = sub.isTrial ? "Ends" : "Due"
        if days < 0       { return "\(abs(days))d overdue" }
        else if days == 0 { return "\(prefix) today" }
        else if days == 1 { return "\(prefix) tomorrow" }
        else              { return "\(prefix) in \(days)d" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SpendyIconBadge(
                    sfSymbol: sub.sfSymbol,
                    color: Color(hex: sub.colorHex),
                    size: .small
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(sub.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)

                    Text(dueLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(urgencyColor)
                }

                Spacer(minLength: 8)

                Text(sub.amount.formattedCurrency(symbol: currencySymbol))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }

            if sub.isTrial {
                HStack(spacing: 8) {
                    Button(action: onKeep) {
                        Text("Keep Sub")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(SpendyColors.textPrimary.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(action: onCancelTrial) {
                        Text("Cancel Trial")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.expenseRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(SpendyColors.expenseRed.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button(action: onPaid) {
                    HStack(spacing: 4) {
                        Image(systemName: SFIcons.checkmark)
                            .font(.system(size: 10, weight: .bold))
                        Text("Mark as Paid")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color(uiColor: .dynamic(light: .white, dark: .black)))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(SpendyColors.primaryBlue, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 260)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(urgencyColor.opacity(0.3), lineWidth: 1)
                }
        }
        .onTapGesture { onTap() }
    }
}
