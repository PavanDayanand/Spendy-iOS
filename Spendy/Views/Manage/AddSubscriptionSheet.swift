//
//  AddSubscriptionSheet.swift
//  Spendy
//
//  Modal Drawer Sheet for Adding & Editing Subscriptions with Aligned Styling
//

import SwiftUI

struct AddSubscriptionSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var subscriptionToEdit: Subscription? = nil

    @State private var name: String = ""
    @State private var amountString: String = ""
    @State private var cycle: BillingCycle = .monthly
    @State private var nextBillingDate: Date = Date()
    @State private var initialBillingDate: Date
    @State private var isTrial: Bool = false
    @State private var selectedAccountId: String = "bank"
    @State private var selectedSymbol: String = SFIcons.subscriptions
    
    // UI states
    @State private var showIconPickerSheet: Bool = false
    @State private var subscriptionToDelete: Subscription?
    @State private var showDiscardConfirmation: Bool = false
    
    var isEditing: Bool { subscriptionToEdit != nil }

    private var hasUnsavedChanges: Bool {
        if let sub = subscriptionToEdit {
            let amountDouble = Double(amountString) ?? 0.0
            return name != sub.name ||
                   amountDouble != sub.amount ||
                   cycle != sub.cycle ||
                   nextBillingDate != sub.nextBillingDate ||
                   isTrial != sub.isTrial ||
                   selectedAccountId != sub.accountId ||
                   selectedSymbol != sub.sfSymbol
        } else {
            let amountDouble = Double(amountString) ?? 0.0
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                   amountDouble != 0.0 ||
                   selectedSymbol != SFIcons.subscriptions ||
                   isTrial != false ||
                   cycle != .monthly ||
                   selectedAccountId != "bank" ||
                   nextBillingDate != initialBillingDate
        }
    }

    private var selectedAccount: Account? {
        store.accounts.first { $0.id == selectedAccountId }
    }

    init(subscriptionToEdit: Subscription? = nil) {
        self.subscriptionToEdit = subscriptionToEdit
        let initialBillingDate = subscriptionToEdit?.nextBillingDate ?? Date()
        _initialBillingDate = State(initialValue: initialBillingDate)
        _nextBillingDate = State(initialValue: initialBillingDate)

        if let sub = subscriptionToEdit {
            _name = State(initialValue: sub.name)
            _amountString = State(initialValue: sub.amount > 0 ? String(format: "%.2f", sub.amount) : "")
            _cycle = State(initialValue: sub.cycle)
            _nextBillingDate = State(initialValue: sub.nextBillingDate)
            _isTrial = State(initialValue: sub.isTrial)
            _selectedAccountId = State(initialValue: sub.accountId)
            _selectedSymbol = State(initialValue: sub.sfSymbol)
        } else {
            _name = State(initialValue: "")
            _amountString = State(initialValue: "")
            _cycle = State(initialValue: .monthly)
            _nextBillingDate = State(initialValue: initialBillingDate)
            _isTrial = State(initialValue: false)
            _selectedAccountId = State(initialValue: "bank")
            _selectedSymbol = State(initialValue: SFIcons.subscriptions)
        }
    }

    var body: some View {
        SpendyPinnedHeaderLayout {
            topHeaderBar
                .padding(.horizontal, 20)
                .padding(.top, 20)
        } content: {
            ScrollView {
                formContentSection
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaBar(edge: .bottom, spacing: 0) {
                bottomActionButton
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }
            .scrollEdgeEffectStyle(.soft, for: .bottom)
        }
        .presentationBackground(SpendyColors.sheetBackgroundGradient)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.fraction(0.78), .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .sheet(isPresented: $showIconPickerSheet) {
            CategoryIconPickerSheet(selectedSymbol: $selectedSymbol)
        }
        .alert("Discard Changes?", isPresented: $showDiscardConfirmation) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .subscriptionDeleteConfirmation($subscriptionToDelete) { item in
            store.deleteSubscription(id: item.id)
            dismiss()
        }
    }

    // MARK: - Components

    private var topHeaderBar: some View {
        HStack {
            SubscriptionToolbarButton("Close", icon: SFIcons.close) {
                if hasUnsavedChanges {
                    showDiscardConfirmation = true
                } else {
                    dismiss()
                }
            }
            Spacer()
            Text(isEditing ? "Edit Subscription" : "New Subscription")
                .font(.headline)
                .foregroundStyle(SpendyColors.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if isEditing {
                SubscriptionToolbarButton("Delete Subscription", icon: SFIcons.trash, haptic: .warning) {
                    subscriptionToDelete = subscriptionToEdit
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
                    .accessibilityHidden(true)
            }
        }
    }

    private var previewProgress: Double {
        let calendar = Calendar.current
        let start: Date
        switch cycle {
        case .monthly:
            start = calendar.date(byAdding: .month, value: -1, to: nextBillingDate) ?? nextBillingDate
        case .yearly:
            start = calendar.date(byAdding: .year, value: -1, to: nextBillingDate) ?? nextBillingDate
        case .weekly:
            start = calendar.date(byAdding: .day, value: -7, to: nextBillingDate) ?? nextBillingDate
        }
        let total = nextBillingDate.timeIntervalSince(start)
        guard total > 0 else { return 1.0 }
        let elapsed = Date().timeIntervalSince(start)
        let ratio = elapsed / total
        if ratio <= 0 { return 0.05 }
        if ratio >= 1.0 { return 1.0 }
        return min(max(ratio, 0.05), 1.0)
    }

    private var avatarHeroSection: some View {
        SpendyEditableHeroIcon(accessibilityLabel: "Edit subscription icon") {
            showIconPickerSheet = true
        } icon: {
            SubscriptionProgressRingBadge(
                sfSymbol: selectedSymbol,
                color: SpendyColors.textPrimary,
                progress: previewProgress,
                isPaused: false,
                size: isEditing ? .medium : .large,
                monogramName: name
            )
        }
    }

    private var formContentSection: some View {
        VStack(spacing: 16) {
            if isEditing {
                editIdentity
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        avatarHeroSection
                        VStack(alignment: .leading, spacing: 4) {
                            fieldLabel("Subscription name")
                            nameInput
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background { entryFieldBackground }

                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("Amount")
                        amountInput
                            .font(.title.weight(.semibold).monospacedDigit())
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background { entryFieldBackground }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if isEditing { sectionTitle("Billing") }
                billingFields
            }
        }
        .foregroundStyle(SpendyColors.textPrimary)
    }

    private var entryFieldBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(SpendyColors.textPrimary.opacity(0.06))
            .strokeBorder(SpendyColors.separator, lineWidth: 1)
    }

    private var editIdentity: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Subscription details")
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    avatarHeroSection
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("Subscription name")
                        nameInput
                    }
                }
                Divider()
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        fieldLabel("Amount")
                        Spacer(minLength: 4)
                        amountInput
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("Amount")
                        amountInput
                    }
                }
                .font(.body.weight(.semibold).monospacedDigit())
                .frame(minHeight: 34)
            }
            .padding(16)
            .background(SpendyColors.cardBackgroundSecondary, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var nameInput: some View {
        TextField("e.g. Apple Music", text: $name)
            .font(.title3.weight(.semibold))
            .accessibilityLabel("Subscription name")
            .autocorrectionDisabled()
    }

    private var amountInput: some View {
        HStack(spacing: 4) {
            Text(store.currencySymbol)
                .foregroundStyle(SpendyColors.textSecondary)
                .accessibilityHidden(true)
            TextField("0.00", text: $amountString)
                .accessibilityLabel("Amount")
                .keyboardType(.decimalPad)
                .frame(minWidth: isEditing ? 44 : nil)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(SpendyColors.textSecondary)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .padding(.leading, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private var billingFields: some View {
        VStack(spacing: 0) {
            menuRow("Billing cycle", value: cycle.label) {
                Picker("Billing cycle", selection: $cycle) {
                    ForEach(BillingCycle.allCases) { item in
                        Text(item.label).tag(item)
                    }
                }
            }
            Divider()
            Toggle("Free Trial", isOn: $isTrial)
                .font(.subheadline)
                .tint(SpendyColors.switchTint)
                .frame(minHeight: 46)
            Divider()
            DatePicker(selection: $nextBillingDate, displayedComponents: .date) {
                fieldLabel(isTrial ? "Trial ends" : (isEditing ? "Next payment" : "First payment"))
            }
            .datePickerStyle(.compact)
            .frame(minHeight: 48)
            Divider()
            menuRow("Payment account", value: selectedAccount?.label ?? "Select account") {
                Picker("Payment account", selection: $selectedAccountId) {
                    ForEach(store.accounts) { account in
                        Label(account.label, systemImage: account.sfSymbol).tag(account.id)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background(SpendyColors.cardBackgroundSecondary, in: RoundedRectangle(cornerRadius: 20))
    }

    private func menuRow(
        _ title: String,
        value: String,
        @ViewBuilder options: () -> some View
    ) -> some View {
        Menu(content: options) {
            HStack(spacing: 8) {
                fieldLabel(title)
                Spacer(minLength: 8)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            .frame(minHeight: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private var bottomActionButton: some View {
        SubscriptionGlassAction(
            title: isEditing ? "Save Changes" : "Create Subscription",
            isEnabled: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (Double(amountString) ?? 0) > 0
        ) {
            HapticsManager.shared.trigger(.success)
            saveSubscription()
        }
    }

    private func saveSubscription() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let amountVal = Double(amountString) ?? 0.0

        if let existing = subscriptionToEdit {
            var updated = existing
            updated.name = trimmedName
            updated.amount = amountVal
            updated.cycle = cycle
            updated.nextBillingDate = nextBillingDate
            updated.isTrial = isTrial
            updated.accountId = selectedAccountId
            updated.sfSymbol = selectedSymbol
            updated.isDarkBadge = true
            store.updateSubscription(updated)
        } else {
            let newSub = Subscription(
                name: trimmedName,
                amount: amountVal,
                cycle: cycle,
                nextBillingDate: nextBillingDate,
                accountId: selectedAccountId,
                isTrial: isTrial,
                status: "active",
                sfSymbol: selectedSymbol,
                isDarkBadge: true
            )
            store.addSubscription(newSub)
        }
        dismiss()
    }

}

//
