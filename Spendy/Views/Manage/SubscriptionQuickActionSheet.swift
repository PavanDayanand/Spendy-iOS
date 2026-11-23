import SwiftUI

struct SubscriptionQuickActionSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let sub: Subscription
    let onEdit: (Subscription) -> Void

    @State private var subscriptionToDelete: Subscription?
    @State private var paymentRecorded = false

    private var subscription: Subscription {
        store.subscriptions.first { $0.id == sub.id } ?? sub
    }

    private var status: String {
        if subscription.isCancelled { return "Cancelled" }
        if subscription.isPaused { return "Paused" }
        return subscription.isTrial ? "Free Trial" : "Active"
    }

    private var actionTitle: String {
        if paymentRecorded { return "Payment Recorded" }
        if subscription.isCancelled { return "Reactivate Subscription" }
        if subscription.isPaused { return "Resume Subscription" }
        return subscription.isTrial ? "Convert Trial & Mark as Paid" : "Mark as Paid"
    }

    private var recordsPayment: Bool {
        !subscription.isCancelled && !subscription.isPaused
    }

    private var totalSpent: Double {
        store.transactions
            .filter { transaction in
                transaction.subscriptionId?.lowercased() == subscription.id.uuidString.lowercased()
                    || (transaction.title.lowercased() == subscription.name.lowercased() && transaction.type == .expense)
            }
            .reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        SpendyPinnedHeaderLayout {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)
        } content: {
            ScrollView {
                VStack(spacing: 16) {
                    summary
                    details
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .accessibilityIdentifier("subscription-detail-scroll")
            .safeAreaBar(edge: .bottom, spacing: 0) {
                paymentFooter
            }
            .scrollEdgeEffectStyle(.soft, for: .bottom)
        }
        .presentationBackground(SpendyColors.sheetBackgroundGradient)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(530), .large])
        .presentationDragIndicator(.visible)
        .subscriptionDeleteConfirmation($subscriptionToDelete) { item in
            store.deleteSubscription(id: item.id)
            dismiss()
        }
        .task(id: paymentRecorded) {
            guard paymentRecorded else { return }
            try? await Task.sleep(for: .milliseconds(850))
            if !Task.isCancelled { dismiss() }
        }
    }

    private var paymentFooter: some View {
        VStack(spacing: 8) {
            if recordsPayment || paymentRecorded {
                Text(paymentRecorded ? "Expense added to Spendy" : "Records an expense in Spendy")
                    .font(.footnote)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            SubscriptionGlassAction(title: actionTitle, isEnabled: !paymentRecorded) {
                performPrimaryAction()
            }
            .accessibilityIdentifier("subscription-primary-action")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var header: some View {
        HStack(spacing: 8) {
            SubscriptionToolbarButton("Close", icon: SFIcons.close) { dismiss() }
            Spacer()
            if !subscription.isCancelled {
                SubscriptionToolbarButton("Edit Subscription", icon: SFIcons.edit) { onEdit(subscription) }
            }
            SubscriptionToolbarButton("Delete Subscription", icon: SFIcons.trash, haptic: .warning) {
                subscriptionToDelete = subscription
            }
        }
        .disabled(paymentRecorded)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                SubscriptionProgressRingBadge(subscription: subscription, size: .large)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.headline)
                    Text(subscription.amount.formattedCurrency(symbol: store.currencySymbol))
                        .font(.largeTitle.weight(.bold).monospacedDigit())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    billingCycleLabel
                    statusControl
                }
                    .fixedSize()
                VStack(alignment: .leading, spacing: 6) {
                    billingCycleLabel
                    statusControl
                }
            }
        }
        .foregroundStyle(SpendyColors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var statusControl: some View {
        if subscription.isCancelled {
            Text(status)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SpendyColors.textSecondary)
        } else {
            statusMenu
        }
    }

    private var billingCycleLabel: some View {
        Text(subscription.cycle.label)
            .font(.subheadline)
            .foregroundStyle(SpendyColors.textSecondary)
    }

    private var statusMenu: some View {
        Menu {
            Button {
                setTrial(false)
            } label: {
                Label("Active", systemImage: status == "Active" ? "checkmark" : "checkmark.circle")
            }
            Button {
                setTrial(true)
            } label: {
                Label("Free Trial", systemImage: status == "Free Trial" ? "checkmark" : "clock")
            }
            Button(subscription.isPaused ? "Resume Subscription" : "Pause Subscription",
                   systemImage: subscription.isPaused ? "play.fill" : "pause.fill") {
                store.toggleSubscriptionPause(id: subscription.id)
            }
        } label: {
            HStack(spacing: 6) {
                Text(status).font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down").font(.caption2.weight(.semibold))
            }
            .foregroundStyle(SpendyColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .frame(minHeight: 34)
            .nativeLiquidGlassCapsule(isInteractive: true)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Subscription status")
        .accessibilityValue(status)
        .disabled(paymentRecorded)
    }

    private var details: some View {
        VStack(spacing: 0) {
            if recordsPayment {
                detailRow(subscription.isTrial ? "Trial ends" : "Next payment",
                          value: subscription.nextBillingDate.formatted(date: .abbreviated, time: .omitted))
                Divider()
            }
            detailRow("Payment account", value: store.account(for: subscription.accountId).label)
            Divider()
            detailRow("Category", value: store.categories.first { $0.id == subscription.categoryId }?.label ?? "Subscriptions")
            Divider()
            detailRow("Total spent", value: totalSpent.formattedCurrency(symbol: store.currencySymbol))
        }
        .padding(.horizontal, 16)
        .background(SpendyColors.cardBackgroundSecondary, in: RoundedRectangle(cornerRadius: 18))
    }

    private func detailRow(_ label: String, value: String) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                Text(label).foregroundStyle(SpendyColors.textSecondary).fixedSize()
                Text(value)
                    .fixedSize()
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(label).foregroundStyle(SpendyColors.textSecondary)
                Text(value).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.body)
        .foregroundStyle(SpendyColors.textPrimary)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private func setTrial(_ isTrial: Bool) {
        var updated = subscription
        updated.isTrial = isTrial
        updated.isPaused = false
        updated.status = "active"
        store.updateSubscription(updated)
    }

    private func performPrimaryAction() {
        guard !paymentRecorded else { return }
        if subscription.isCancelled {
            var updated = subscription
            updated.status = "active"
            updated.isPaused = false
            store.updateSubscription(updated)
        } else if subscription.isPaused {
            store.toggleSubscriptionPause(id: subscription.id)
        } else {
            paymentRecorded = true
            if subscription.isTrial {
                store.keepSubscription(id: subscription.id)
            } else {
                store.markSubscriptionAsPaid(id: subscription.id)
            }
        }
    }
}

struct SubscriptionToolbarButton: View {
    private let title: String
    private let icon: String
    private let haptic: HapticsManager.FeedbackStyle
    private let action: () -> Void

    init(
        _ title: String,
        icon: String,
        haptic: HapticsManager.FeedbackStyle = .selection,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.haptic = haptic
        self.action = action
    }

    var body: some View {
        GlassCircleButton(
            icon: icon,
            size: 44,
            iconSize: 16,
            iconWeight: .semibold,
            haptic: haptic,
            accessibilityLabel: title,
            action: action
        )
    }
}

struct SubscriptionGlassAction: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonSizing(.flexible)
        .buttonStyle(.glass(.regular.tint(SpendyColors.textPrimary.opacity(0.22))))
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .foregroundStyle(SpendyColors.textPrimary)
        .disabled(!isEnabled)
    }
}

extension View {
    func subscriptionDeleteConfirmation(
        _ selection: Binding<Subscription?>,
        onDelete: @escaping (Subscription) -> Void
    ) -> some View {
        alert("Delete Subscription?", isPresented: Binding(
            get: { selection.wrappedValue != nil },
            set: { if !$0 { selection.wrappedValue = nil } }
        ), presenting: selection.wrappedValue) { item in
            Button("Delete Subscription", role: .destructive) { onDelete(item) }
            Button("Cancel", role: .cancel) {}
        } message: { item in
            Text("Delete \(item.name) from your subscriptions? Recorded expenses will stay in Spendy.")
        }
    }
}
