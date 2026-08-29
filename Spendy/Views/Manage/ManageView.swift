//
//  SubscriptionsView.swift
//  Spendy
//
//  Dedicated Full-Screen Subscriptions Management Hub — Pure Black Background,
//  Hero Stats, Upcoming Due Highlights, Native Filter Chips, and Quick-Action Sheets.
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
            SpendyColors.appBackground
                .ignoresSafeArea()

            SpendyAmbientHeaderBackground(color: SpendyColors.vibrantPurple, height: 420, opacity: 0.22)

            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 64)

                        summaryHeader
                        mainList
                        pastAndCancelled
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                // Sticky Floating Header Bar
                headerBar
                    .padding(.top, 8)
                    .zIndex(100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showAddSubscription) {
            AddSubscriptionSheet()
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $subscriptionToEdit) { sub in
            AddSubscriptionSheet(subscriptionToEdit: sub)
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $selectedSubscriptionForDetail) { sub in
            SubscriptionQuickActionSheet(sub: sub) { subToEdit in
                subscriptionToEdit = subToEdit
            }
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        SpendyGlassEffectContainer(spacing: 0) {
            ZStack {
                Text("Subscriptions")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 60)

                HStack {
                    // Back / Return Button to Home
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

                    // Add Subscription Button
                    GlassCircleButton(
                        icon: SFIcons.plus,
                        size: 44,
                        iconSize: 16,
                        iconWeight: .bold,
                        foregroundColor: SpendyColors.textPrimary,
                        haptic: .light,
                        accessibilityLabel: "Add Subscription",
                        morphID: "addSubscriptionButton",
                        namespace: subsNamespace
                    ) {
                        showAddSubscription = true
                    }
                    .optionalMatchedGeometry(id: "topControl_right", in: topControlsNamespace)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // Typealias for backwards compatibility
    typealias ManageView = SubscriptionsView

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(totalMonthly.formattedCurrency(symbol: store.currencySymbol))
                    .font(.system(size: 34, weight: .heavy, design: .default).monospacedDigit())
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 8) {
                    Text("monthly spend")
                    Text("•")
                    Text("\(activeAndTrialSubs.count) subscriptions")
                    if let nextSub = upcomingSubscriptions.first {
                        Text("•")
                        Text("\(nextSub.name) \(relativeDueText(for: nextSub.nextBillingDate, isTrial: nextSub.isTrial).lowercased())")
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
                .lineLimit(2)
            }

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
                    Text(subFilter.rawValue)
                        .font(.system(size: 13, weight: .bold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(SpendyColors.textPrimary)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .nativeLiquidGlassCapsule(isInteractive: true)
            }
            .buttonStyle(.plain)
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
        Group {
            if filteredSubscriptions.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredSubscriptions) { sub in
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
                SpendyIconBadge(
                    sfSymbol: sub.sfSymbol,
                    color: Color(hex: sub.colorHex),
                    size: .medium
                )

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

                    Text(statusLine(for: sub))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

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

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SpendyColors.cardBackgroundSecondary.opacity(0.72))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SpendyColors.separator.opacity(0.9), lineWidth: 0.8)
                    }
            }
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

    private func statusLine(for sub: Subscription) -> String {
        if sub.isPaused { return "Paused until you resume it" }
        if sub.isTrial { return "Trial converts on the next billing date" }
        return "Active recurring payment"
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
