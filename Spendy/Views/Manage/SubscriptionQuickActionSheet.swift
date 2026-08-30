//
//  SubscriptionQuickActionSheet.swift
//  Spendy
//
//  Native Apple Floating Glass Sheet Card for Subscriptions — Matched with TransactionDetailSheet Layout.
//  Features: Pinned Glass Top Bar (✕, ⏸/▶, ✎, 🗑), Centered Hero with Dynamic Glow,
//  Spacious Clean Detail Rows, Native Tinted Toggle, Solid Apple Button Colors, and Nested Edit Sheet.
//

import SwiftUI

struct SubscriptionQuickActionSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    let sub: Subscription
    
    // Action & Animation States
    @State private var isPaidSuccess: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var heroPulseScale: CGFloat = 1.0
    @Namespace private var sheetNamespace
    
    // Live subscription lookup so edits and toggles update in real-time
    private var liveSub: Subscription {
        store.subscriptions.first(where: { $0.id == sub.id }) ?? sub
    }
    
    private var linkedAccount: Account {
        store.account(for: liveSub.accountId)
    }
    
    private var linkedCategory: Category? {
        store.categories.first(where: { $0.id == liveSub.categoryId })
    }
    
    private var themeColor: Color {
        Color(hex: liveSub.colorHex)
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
            if daysUntilDue == 0 { return "Trial ends today" }
            if daysUntilDue == 1 { return "Trial ends tomorrow" }
            return "\(daysUntilDue)d left"
        } else {
            if daysUntilDue < 0 { return "\(abs(daysUntilDue))d overdue" }
            if daysUntilDue == 0 { return "Due today" }
            if daysUntilDue == 1 { return "Due tomorrow" }
            return "\(daysUntilDue)d left"
        }
    }
    
    private var dueStatusColor: Color {
        if daysUntilDue < 0 { return SpendyColors.expenseRed }
        if daysUntilDue <= 3 { return SpendyColors.warningOrange }
        return SpendyColors.incomeGreen
    }
    
    private var statusBadgeText: String {
        if liveSub.isPaused { return "Paused" }
        if liveSub.isTrial { return "Free Trial" }
        return "Active"
    }
    
    private var statusBadgeColor: Color {
        if liveSub.isPaused { return SpendyColors.textTertiary }
        if liveSub.isTrial { return SpendyColors.warningOrange }
        return SpendyColors.incomeGreen
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Spacer to clear pinned floating top bar (44pt button + 20pt top inset + 16pt gap)
                        Spacer().frame(height: 72)
                        
                        // MARK: - Hero Section
                        heroSection
                        
                        Divider().overlay(SpendyColors.separator.opacity(0.8))
                            .padding(.horizontal, 4)
                        
                        // MARK: - Structured Details List (No Duplication & Spacious)
                        detailsList
                        
                        // MARK: - Primary Action Button
                        primaryActionButton
                            .padding(.top, 10)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)
                }
                
                // MARK: - Floating Top Action Bar
                topActionBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // MARK: - Floating Dynamic Toast Feedback Banner
                if showToast, let toast = toastMessage {
                    feedbackToastView(message: toast)
                        .padding(.top, 74)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(200)
                }
            }
            .background(Color.clear)
            .navigationBarHidden(true)
            .confirmationDialog(
                "Delete Subscription?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Subscription", role: .destructive) {
                    HapticsManager.shared.trigger(.warning)
                    store.deleteSubscription(id: liveSub.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \(liveSub.name)? This action cannot be undone.")
            }
            .sheet(isPresented: $showEditSheet) {
                AddSubscriptionSheet(subscriptionToEdit: liveSub)
                    .presentationBackground(SpendyColors.appBackground)
            }
        }
        .presentationDetents([.height(580), .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(32)
        .presentationBackground {
            ZStack {
                SpendyColors.cardBackground
                SpendyAmbientHeaderBackground(color: themeColor, height: 280, opacity: 0.26)
            }
        }
    }
    
    // MARK: - Floating Top Action Bar
    private var topActionBar: some View {
        HStack {
            // Close Button ✕
            GlassCircleButton(
                icon: "xmark",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close",
                morphID: "closeButton",
                namespace: sheetNamespace
            ) {
                dismiss()
            }
            
            Spacer()
            
            // Action Buttons Group: Pause/Resume ⏸/▶, Edit ✎, Delete 🗑
            GlassButtonGroup(spacing: 10) {
                // Pause / Resume Toggle Button with Dynamic Spring Feedback
                GlassCircleButton(
                    icon: liveSub.isPaused ? "play.fill" : "pause.fill",
                    size: 44,
                    iconSize: 15,
                    iconWeight: .bold,
                    tintColor: liveSub.isPaused ? SpendyColors.incomeGreen.opacity(0.18) : SpendyColors.warningOrange.opacity(0.18),
                    foregroundColor: liveSub.isPaused ? SpendyColors.incomeGreen : SpendyColors.warningOrange,
                    haptic: .medium,
                    accessibilityLabel: liveSub.isPaused ? "Resume Subscription" : "Pause Subscription",
                    morphID: "pauseButton",
                    namespace: sheetNamespace
                ) {
                    handleTogglePause()
                }
                .contentTransition(.symbolEffect(.replace))
                
                // Edit Button — Opens edit sheet directly on top
                GlassCircleButton(
                    icon: "pencil",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .light,
                    accessibilityLabel: "Edit Subscription",
                    morphID: "editButton",
                    namespace: sheetNamespace
                ) {
                    showEditSheet = true
                }
                
                // Delete Button
                GlassCircleButton(
                    icon: "trash.fill",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    tintColor: SpendyColors.expenseRed.opacity(0.18),
                    foregroundColor: SpendyColors.expenseRed,
                    haptic: .warning,
                    accessibilityLabel: "Delete Subscription",
                    morphID: "deleteButton",
                    namespace: sheetNamespace
                ) {
                    showDeleteConfirmation = true
                }
            }
        }
    }
    
    // MARK: - Centered Hero Section
    private var heroSection: some View {
        VStack(spacing: 12) {
            // Subscription Avatar Icon Badge
            SpendyIconBadge(
                sfSymbol: liveSub.sfSymbol,
                color: themeColor,
                size: .large,
                style: .circle
            )
            .scaleEffect(heroPulseScale)
            
            // Title
            Text(liveSub.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
            
            // Amount & Clean Subtitle
            VStack(spacing: 6) {
                Text(liveSub.amount.formattedCurrency(symbol: store.currencySymbol))
                    .spendyNumberFont(size: 40, weight: .heavy, tracking: -1.0)
                    .foregroundStyle(liveSub.isPaused ? SpendyColors.textTertiary : SpendyColors.textPrimary)
                
                // Clean Text Subtitle (No Clunky Dark Box)
                HStack(spacing: 6) {
                    Text("Billed \(liveSub.cycle.label.lowercased())")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    Text(statusBadgeText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(statusBadgeColor)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Structured Details List (Spacious & Clean)
    private var detailsList: some View {
        VStack(spacing: 18) {
            // 1. Billing Frequency Row
            detailRow(icon: "repeat", label: "Billing Cycle") {
                Text(liveSub.cycle.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            // 2. Next Billing Due Date Row + Status Badge
            detailRow(icon: "calendar", label: "Next Billing") {
                HStack(spacing: 8) {
                    Text(formattedDueDate)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text(dueStatusText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(dueStatusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(dueStatusColor.opacity(0.12), in: Capsule())
                }
            }
            
            // 3. Payment Method / Account Row
            detailRow(icon: "creditcard.fill", label: "Payment Method") {
                HStack(spacing: 8) {
                    SpendyIconBadge(
                        sfSymbol: linkedAccount.sfSymbol.isEmpty ? linkedAccount.type.defaultSymbol : linkedAccount.sfSymbol,
                        color: Color(hex: linkedAccount.colorHex),
                        size: .small,
                        style: .circle
                    )
                    Text(linkedAccount.label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            
            // 4. Category Row
            detailRow(icon: "tag.fill", label: "Category") {
                HStack(spacing: 8) {
                    SpendyIconBadge(
                        sfSymbol: linkedCategory?.sfSymbol ?? SFIcons.subscriptions,
                        color: Color(hex: linkedCategory?.colorHex ?? "#5856D6"),
                        size: .small,
                        style: .circle
                    )
                    Text(linkedCategory?.label ?? "Subscriptions")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            
            // 5. Auto-Log Toggle Row (Native Sleek Dark Tinted Toggle)
            detailRow(icon: "bolt.fill", label: "Auto-Log Expense") {
                Toggle("", isOn: Binding(
                    get: { liveSub.autoDeduct },
                    set: { newValue in
                        HapticsManager.shared.trigger(.light)
                        var updated = liveSub
                        updated.autoDeduct = newValue
                        store.updateSubscription(updated)
                    }
                ))
                .labelsHidden()
                .tint(SpendyColors.incomeGreen)
            }
            
            // 6. Status Row
            detailRow(icon: "checkmark.shield.fill", label: "Status") {
                Text(statusBadgeText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(statusBadgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusBadgeColor.opacity(0.14), in: Capsule())
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: liveSub.isPaused)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Primary Action Button (Clean Solid Blue / Green)
    private var primaryActionButton: some View {
        Button {
            if liveSub.isPaused {
                handleTogglePause()
            } else {
                handleSettlePayment()
            }
        } label: {
            HStack(spacing: 8) {
                if isPaidSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .heavy))
                    Text(liveSub.isTrial ? "Trial Converted to Paid!" : "Payment Recorded!")
                        .font(.system(size: 16, weight: .bold))
                } else if isProcessing {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    if liveSub.isPaused {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Resume Subscription")
                            .font(.system(size: 16, weight: .bold))
                    } else if liveSub.isTrial {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Keep & Pay Subscription")
                            .font(.system(size: 16, weight: .bold))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Mark as Paid & Log Expense")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(solidButtonColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isProcessing || isPaidSuccess)
    }
    
    private var solidButtonColor: Color {
        if isPaidSuccess || liveSub.isPaused {
            return SpendyColors.incomeGreen
        } else if liveSub.isTrial {
            return SpendyColors.warningOrange
        } else {
            return SpendyColors.primaryBlue
        }
    }
    
    // MARK: - Action Handlers with Rich Spring Animation & Toast Feedback
    
    private func handleTogglePause() {
        HapticsManager.shared.trigger(.medium)
        
        let wasPaused = liveSub.isPaused
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            heroPulseScale = 1.15
            store.toggleSubscriptionPause(id: liveSub.id)
            toastMessage = wasPaused ? "Subscription Resumed & Active!" : "Subscription Paused"
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                heroPulseScale = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showToast = false
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                dismiss()
            }
        }
    }
    
    // MARK: - Toast Banner View
    private func feedbackToastView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: liveSub.isPaused ? "pause.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(liveSub.isPaused ? SpendyColors.warningOrange : SpendyColors.incomeGreen)
            
            Text(message)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background {
            Capsule()
                .fill(SpendyColors.cardBackgroundSecondary)
                .overlay(Capsule().stroke(SpendyColors.separator, lineWidth: 0.8))
                .shadow(color: Color.black.opacity(0.35), radius: 12, y: 6)
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func detailRow<V: View>(icon: String, label: String, @ViewBuilder valueView: () -> V) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Spacer()
            
            valueView()
        }
    }
}
