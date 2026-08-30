//
//  SubscriptionsView.swift
//  Spendy
//
//  Dedicated Full-Screen Subscriptions Management Hub — Matched with AccountsView Layout.
//  Features: Pure Black Background, Ambient Header Glow, Hero Spend Card with Sparkline,
//  GlassSegmentedPicker Filters, Polished Glass Cards, and Bottom Floating Add Button.
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
    @State private var isSearching: Bool = false
    @State private var searchQuery: String = ""
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
        let base = activeAndTrialSubs.filter { sub in
            switch subFilter {
            case .all:    return true
            case .paid:   return !sub.isTrial && !sub.isPaused
            case .trial:  return sub.isTrial
            case .paused: return sub.isPaused
            }
        }
        
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return base
        }
        let q = searchQuery.lowercased()
        return base.filter {
            $0.name.lowercased().contains(q)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            SpendyColors.appBackground
                .ignoresSafeArea()

            // Ambient Glow Header
            SpendyAmbientHeaderBackground(color: SpendyColors.vibrantPurple, height: 380, opacity: 0.28)

            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 64) // Clean top clearance for floating header

                        // 1. Hero Spend Card (Matched with AccountsView Hero)
                        heroSpendSection
                            .padding(.horizontal, 16)

                        // 2. Subscriptions List Section (with GlassSegmentedPicker)
                        subscriptionsListSection
                            .padding(.horizontal, 16)

                        // 3. Past & Cancelled Section
                        if !cancelledSubs.isEmpty {
                            pastAndCancelledSection
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 100) // Clearance for bottom floating button
                }
                .scrollDismissesKeyboard(.interactively)

                // Sticky Floating Header Bar
                headerBar
                    .padding(.top, 16)
                    .zIndex(100)
            }

            // Bottom Floating Action Button (Add +)
            VStack {
                Spacer()
                bottomFloatingBar
            }
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

    // MARK: - Top Header Bar

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
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // Typealias for backwards compatibility
    typealias ManageView = SubscriptionsView

    // MARK: - Hero Spend Section (Matched with AccountsView Net Worth Hero)

    private var heroSpendSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Currency / Frequency Chip Pill
            HStack(spacing: 4) {
                Text("Monthly in \(store.currencyCode)")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(SpendyColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .nativeLiquidGlassCapsule(isInteractive: false)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(totalMonthly.formattedCurrency(symbol: store.currencySymbol))
                        .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text("\(activeCount) active")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(SpendyColors.textTertiary)
                        Text("\(totalAnnual.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/yr")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                }

                Spacer()

                // Sparkline Visual Curve
                trendSparkline
                    .frame(width: 110, height: 44)
                    .padding(.trailing, 4)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
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
            // Horizontal Type Filter Pills with GlassSegmentedPicker
            ScrollView(.horizontal, showsIndicators: false) {
                GlassSegmentedPicker(
                    selection: $subFilter,
                    items: SubscriptionFilter.allCases,
                    titleFor: { $0.rawValue },
                    expandsToFillWidth: false
                )
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }

            // Subheader: Title, Subtotal, and Search Toggle
            HStack {
                Text(subFilter == .all ? "Recurring Services" : "\(subFilter.rawValue) Services")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)

                Spacer()

                Button {
                    withAnimation(AppMotion.snappySpring) {
                        isSearching.toggle()
                        if !isSearching {
                            searchQuery = ""
                        }
                    }
                    HapticsManager.shared.trigger(.selection)
                } label: {
                    Image(systemName: isSearching ? "xmark.circle.fill" : "magnifyingglass")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .padding(AppSpacing.xs)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)

            // Prominent, Visible Search Bar Input Field
            if isSearching {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)

                    TextField("Search subscriptions, services, bills...", text: $searchQuery)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .submitLabel(.search)

                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            HapticsManager.shared.trigger(.tick)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(SpendyColors.cardBackgroundSecondary)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.9)
                        }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

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

    // MARK: - Subscription Row Card (Matched with AccountsView Row Card Styling)

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
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(
                            sub.isPaused
                                ? SpendyColors.textTertiary
                                : SpendyColors.textPrimary
                        )
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(sub.cycle.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)

                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(SpendyColors.textTertiary)

                        Text(relativeDueText(for: sub.nextBillingDate, isTrial: sub.isTrial))
                            .font(.system(size: 13, weight: .semibold))
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
                selectedSubscriptionForDetail = sub
            } label: {
                Label("View Details", systemImage: "info.circle")
            }

            Button {
                subscriptionToEdit = sub
            } label: {
                Label("Edit Subscription", systemImage: "pencil")
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
                Label("Cancel Subscription", systemImage: "xmark.circle")
            }

            Button(role: .destructive) {
                store.deleteSubscription(id: sub.id)
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

    // MARK: - Sparkline Curve

    private var trendSparkline: some View {
        let col = SpendyColors.vibrantPurple

        return GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack(alignment: .bottomTrailing) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.8))
                    path.addCurve(
                        to: CGPoint(x: w, y: h * 0.15),
                        control1: CGPoint(x: w * 0.5, y: h * 0.75),
                        control2: CGPoint(x: w * 0.75, y: h * 0.25)
                    )
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [col.opacity(0.35), col.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Path { path in
                    path.move(to: CGPoint(x: 0, y: h * 0.8))
                    path.addCurve(
                        to: CGPoint(x: w, y: h * 0.15),
                        control1: CGPoint(x: w * 0.5, y: h * 0.75),
                        control2: CGPoint(x: w * 0.75, y: h * 0.25)
                    )
                }
                .stroke(col, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .shadow(color: col.opacity(0.3), radius: 4, y: 1)
            }
        }
    }

    // MARK: - Bottom Floating Action Bar (Add +)

    private var bottomFloatingBar: some View {
        HStack {
            Spacer()

            // Plus (+) Add Subscription Button
            GlassCircleButton(
                icon: SFIcons.plus,
                size: 54,
                iconSize: 20,
                tintColor: SpendyColors.primaryBlue,
                foregroundColor: Color.white,
                haptic: .medium,
                accessibilityLabel: "Add Subscription",
                morphID: "addSubscriptionButton",
                namespace: subsNamespace
            ) {
                showAddSubscription = true
            }
            .shadow(color: Color.black.opacity(0.15), radius: 14, y: 6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
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

