//
//  SubscriptionQuickActionSheet.swift
//  Spendy
//
//  Native Apple Floating Glass Sheet Card for Subscriptions
//  Features: Shared Glass Top Bar (✕, ✎), Clean Primary Button (No Card Icon), Balanced Icon Buttons (⏸ Pause & 🗑 Delete), Standard Sheet Background
//

import SwiftUI

struct SubscriptionQuickActionSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let sub: Subscription
    var onEdit: ((Subscription) -> Void)? = nil
    
    @State private var isPaidSuccess: Bool = false
    @State private var autoDeductToggle: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var showActionsDialog: Bool = false
    @Namespace private var actionSheetNamespace
    
    // Live subscription lookup so edits update in real-time
    private var liveSub: Subscription {
        store.subscriptions.first(where: { $0.id == sub.id }) ?? sub
    }
    
    private var linkedAccount: Account {
        store.account(for: liveSub.accountId)
    }
    
    private var linkedCategory: Category? {
        store.categories.first(where: { $0.id == liveSub.categoryId })
    }
    
    private var formattedDueDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: liveSub.nextBillingDate)
    }
    
    private var daysUntilDue: Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: liveSub.nextBillingDate)
        return calendar.dateComponents([.day], from: now, to: target).day ?? 0
    }
    
    private var dueStatusText: String {
        if liveSub.isTrial {
            if daysUntilDue < 0 { return "Trial expired \(abs(daysUntilDue))d ago" }
            if daysUntilDue == 0 { return "Free trial ends today" }
            return "Free trial ends in \(daysUntilDue) days"
        } else {
            if daysUntilDue < 0 { return "\(abs(daysUntilDue)) days overdue" }
            if daysUntilDue == 0 { return "Due today" }
            if daysUntilDue == 1 { return "Due tomorrow" }
            return "Due in \(daysUntilDue) days"
        }
    }
    
    private var dueStatusColor: Color {
        if daysUntilDue < 0 { return SpendyColors.expenseRed }
        if daysUntilDue <= 3 { return SpendyColors.warningOrange }
        return SpendyColors.incomeGreen
    }

    private var statusTitle: String {
        if liveSub.isPaused { return "Paused" }
        if liveSub.isTrial { return "Trial" }
        return "Active"
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                SpendyColors.appBackground
                    .ignoresSafeArea()

                SpendyAmbientHeaderBackground(color: Color(hex: liveSub.colorHex), height: 360, opacity: 0.22)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        Spacer().frame(height: 76)

                        heroCard
                        infoSection
                        primaryActionButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
                
                topActionBar
            }
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            autoDeductToggle = liveSub.autoDeduct
        }
        .sheet(isPresented: $showEditSheet) {
            AddSubscriptionSheet(subscriptionToEdit: liveSub)
        }
        .alert("Delete Subscription?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                store.deleteSubscription(id: liveSub.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(liveSub.name)? This action cannot be undone.")
        }
        .confirmationDialog("Subscription Actions", isPresented: $showActionsDialog) {
            Button("Edit") {
                showEditSheet = true
            }
            Button(liveSub.isPaused ? "Resume" : "Pause") {
                store.toggleSubscriptionPause(id: liveSub.id)
                dismiss()
            }
            if liveSub.isTrial {
                Button("Cancel Trial", role: .destructive) {
                    store.cancelSubscription(id: liveSub.id)
                    dismiss()
                }
            } else {
                Button("Delete Subscription", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
    }
    
    // MARK: - Top Action Bar
    private var topActionBar: some View {
        ZStack {
            Text("Subscription")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .padding(.horizontal, 60)
            
            HStack(alignment: .center) {
                SpendyGlassEffectContainer {
                    GlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        iconSize: 16,
                        iconWeight: .bold,
                        foregroundColor: SpendyColors.textPrimary,
                        haptic: .selection,
                        accessibilityLabel: "Close",
                        morphID: "closeButton",
                        namespace: actionSheetNamespace
                    ) {
                        dismiss()
                    }
                }
                
                Spacer()
                
                SpendyGlassEffectContainer {
                    GlassCircleButton(
                        icon: "ellipsis",
                        size: 44,
                        iconSize: 16,
                        iconWeight: .bold,
                        foregroundColor: SpendyColors.textPrimary,
                        haptic: .light,
                        accessibilityLabel: "More Actions",
                        morphID: "moreButton",
                        namespace: actionSheetNamespace
                    ) {
                        showActionsDialog = true
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Hero Card
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: liveSub.colorHex).opacity(0.18))
                            .frame(width: 72, height: 72)

                        SpendyIconBadge(
                            sfSymbol: liveSub.sfSymbol,
                            color: Color(hex: liveSub.colorHex),
                            size: .large,
                            style: .circle
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(liveSub.name)
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)

                        HStack(spacing: 6) {
                            detailPill(statusTitle, color: dueStatusColor)
                            detailPill(liveSub.cycle.label, color: SpendyColors.textSecondary)
                        }
                    }
                }

                Spacer(minLength: 12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(liveSub.amount.formattedCurrency(symbol: store.currencySymbol))
                    .font(.system(size: 38, weight: .heavy, design: .default).monospacedDigit())
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(dueStatusText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(dueStatusColor)
            }

        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            SpendyColors.cardBackground,
                            Color(hex: "#111319")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.9)
                }
        }
    }
    
    // MARK: - Information Section
    private var infoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SpendyIconBadge(
                    sfSymbol: linkedAccount.sfSymbol,
                    color: Color(hex: linkedAccount.colorHex),
                    size: .small,
                    style: .circle
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Payment Method")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Text(linkedAccount.label)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Renews")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)

                    Text(formattedDueDate)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
            }
            
            Divider().overlay(SpendyColors.separator)

            HStack(spacing: 12) {
                SpendyIconBadge(
                    sfSymbol: linkedCategory?.sfSymbol ?? SFIcons.subscriptions,
                    color: Color(hex: linkedCategory?.colorHex ?? "#5856D6"),
                    size: .small,
                    style: .circle
                )
                
                Text("Category")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Text(linkedCategory?.label ?? "Subscriptions")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }

            Divider().overlay(SpendyColors.separator)

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(SpendyColors.cardBackgroundSecondary, in: Circle())

                Text("Next Billing")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)

                Spacer()

                Text(formattedDueDate)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            Divider().overlay(SpendyColors.separator)
            
            // Row 3: Status
            HStack(spacing: 12) {
                SpendyIconBadge(
                    sfSymbol: "checkmark.shield.fill",
                    color: liveSub.isTrial ? SpendyColors.warningOrange : SpendyColors.incomeGreen,
                    size: .small,
                    style: .circle
                )
                
                Text("Subscription Status")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Text(liveSub.isPaused ? "Paused" : (liveSub.isTrial ? "Free Trial" : "Active"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(liveSub.isTrial ? SpendyColors.warningOrange : (liveSub.isPaused ? SpendyColors.textTertiary : SpendyColors.incomeGreen))
            }

            Divider().overlay(SpendyColors.separator)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Log Expense")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    Text("Automatically record the transaction on the billing date")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }

                Spacer()

                Toggle("", isOn: $autoDeductToggle)
                    .labelsHidden()
                    .toggleStyle(GlassToggleStyle(tintColor: SpendyColors.incomeGreen))
                    .onChange(of: autoDeductToggle) { _, newValue in
                        HapticsManager.shared.trigger(.light)
                        var updated = liveSub
                        updated.autoDeduct = newValue
                        store.updateSubscription(updated)
                    }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackgroundSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Primary Action
    private var primaryActionButton: some View {
        Button {
            handleSettlePayment()
        } label: {
            HStack(spacing: 8) {
                if isPaidSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .heavy))
                    Text("Payment Recorded!")
                        .font(.system(size: 15, weight: .bold))
                } else if isProcessing {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    Text(liveSub.isTrial ? "Keep & Pay Subscription" : "Mark as Paid & Log Expense")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isPaidSuccess
                                    ? [Color(hex: "#30D158"), Color(hex: "#248A3D")]
                                    : [Color(hex: "#007AFF"), Color(hex: "#0051A8")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                }
                .shadow(color: (isPaidSuccess ? Color(hex: "#30D158") : Color(hex: "#007AFF")).opacity(0.35), radius: 10, y: 4)
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing || isPaidSuccess)
    }
    
    private func handleSettlePayment() {
        HapticsManager.shared.trigger(.heavy)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isProcessing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if liveSub.isTrial {
                store.keepSubscription(id: liveSub.id)
            } else {
                store.markSubscriptionAsPaid(id: liveSub.id)
            }
            
            HapticsManager.shared.trigger(.success)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isProcessing = false
                isPaidSuccess = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                dismiss()
            }
        }
    }

    private func detailPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.14), in: Capsule())
    }

}
