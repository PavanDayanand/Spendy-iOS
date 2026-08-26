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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                SpendyColors.cardBackground
                    .ignoresSafeArea()
                
                // Scrollable Content (offset below floating topActionBar)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Spacer to clear floating top bar (44pt button + 20pt top inset + 12pt gap)
                        Spacer().frame(height: 76)
                        
                        // Hero Avatar & Amount
                        heroAmountSection
                        
                        // Structured Details Card with circular account icon badge
                        detailsCard
                        
                        // Auto-Log Toggle Card
                        autoLogCard
                        
                        // Action Buttons Section
                        actionButtonsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
                
                // Floating Top Bar (Matching TransactionDetailSheet - Single Edit Button)
                topActionBar
            }
        }
        .presentationDetents([.fraction(0.85), .large])
        .presentationDragIndicator(.visible)
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
    }
    
    // MARK: - Top Floating Action Bar (Shared Spendy Pattern from TransactionDetailSheet - Single Edit Button)
    private var topActionBar: some View {
        HStack(alignment: .center) {
            // Close ✕ Button (Top Left)
            SpendyGlassEffectContainer {
                GlassCircleButton(
                    icon: "xmark",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .selection,
                    accessibilityLabel: "Close"
                ) {
                    dismiss()
                }
            }
            
            Spacer()
            
            // Edit ✎ Button (Top Right)
            SpendyGlassEffectContainer {
                GlassCircleButton(
                    icon: "pencil",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .light,
                    accessibilityLabel: "Edit Subscription"
                ) {
                    showEditSheet = true
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Hero Brand & Amount Section
    private var heroAmountSection: some View {
        VStack(spacing: 8) {
            // Brand Icon with glowing halo
            ZStack {
                Circle()
                    .fill(Color(hex: liveSub.colorHex).opacity(0.18))
                    .frame(width: 64, height: 64)
                
                SpendyIconBadge(
                    sfSymbol: liveSub.sfSymbol,
                    color: Color(hex: liveSub.colorHex),
                    size: .large,
                    style: .circle
                )
            }
            
            VStack(spacing: 4) {
                Text(liveSub.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Text(liveSub.amount.formattedCurrency(symbol: store.currencySymbol))
                    .font(.system(size: 38, weight: .heavy, design: .default).monospacedDigit())
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                HStack(spacing: 6) {
                    Text(liveSub.cycle.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text(dueStatusText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(dueStatusColor)
                }
            }
        }
    }
    
    // MARK: - Structured Details Card
    private var detailsCard: some View {
        VStack(spacing: 12) {
            // Row 1: Payment Method with Real Account Symbol & Color
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
                
                Text(formattedDueDate)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            
            Divider().overlay(SpendyColors.separator)
            
            // Row 2: Category
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
    
    // MARK: - Auto-Log Toggle Card
    private var autoLogCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Auto-Log Expense")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                Text("Automatically record transaction on due date")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            
            Spacer()
            
            Toggle("", isOn: $autoDeductToggle)
                .labelsHidden()
                .tint(Color(hex: "#34C759"))
                .onChange(of: autoDeductToggle) { _, newValue in
                    HapticsManager.shared.trigger(.light)
                    var updated = liveSub
                    updated.autoDeduct = newValue
                    store.updateSubscription(updated)
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
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 10) {
            // Primary Settle Button (No Credit Card Icon, Clean Bold Text)
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
            
            // Secondary Options Row (Pause & Delete with Matching SF Symbol Icons)
            HStack(spacing: 10) {
                Button {
                    HapticsManager.shared.trigger(.medium)
                    store.toggleSubscriptionPause(id: liveSub.id)
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: liveSub.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(liveSub.isPaused ? "Resume" : "Pause")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(SpendyColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(SpendyColors.cardBackgroundSecondary)
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(SpendyColors.separator, lineWidth: 0.8))
                    }
                }
                .buttonStyle(.plain)
                
                if liveSub.isTrial {
                    Button {
                        HapticsManager.shared.trigger(.medium)
                        store.cancelSubscription(id: liveSub.id)
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Cancel Trial")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(SpendyColors.expenseRed)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SpendyColors.cardBackgroundSecondary)
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(SpendyColors.expenseRed.opacity(0.3), lineWidth: 0.8))
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        HapticsManager.shared.trigger(.warning)
                        showDeleteConfirmation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Delete")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(SpendyColors.expenseRed)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SpendyColors.cardBackgroundSecondary)
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(SpendyColors.expenseRed.opacity(0.3), lineWidth: 0.8))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
}
