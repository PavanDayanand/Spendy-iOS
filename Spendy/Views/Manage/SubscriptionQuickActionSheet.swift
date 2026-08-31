//
//  SubscriptionQuickActionSheet.swift
//  Spendy
//
//  Native Apple Floating Glass Sheet Card for Subscriptions (Rainbow / Apple Wallet Style).
//  Features:
//  - Top Bar: Close Button (✕) on Left, More Options Menu (•••) on Right
//  - Clean Seamless Hero: Avatar with Dynamic Glow, Large Amount & Status Subtitle
//  - Interactive Action Capsule Button: Live State, Spring Press Feedback, Loading & Success Morph
//  - Dynamic Contextual Info Note
//  - Structured Metadata Rows: Payment Method, Category, Billing Cycle, Next Date, Auto-Log, Annual Cost
//  - Dynamic Toast Feedback & Tactile Haptic Physics
//

import SwiftUI

struct SubscriptionQuickActionSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let sub: Subscription
    
    // Action & Animation States
    @State private var isPaidSuccess: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var toastIcon: String = "checkmark.circle.fill"
    @State private var toastColor: Color = SpendyColors.incomeGreen
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
    
    private var annualProjectedCost: Double {
        switch liveSub.cycle {
        case .monthly: return liveSub.amount * 12
        case .yearly:  return liveSub.amount
        case .weekly:  return liveSub.amount * 52
        }
    }
    
    // MARK: - Capsule State Properties
    
    private var capsuleIcon: String {
        if liveSub.isPaused {
            return "play.fill"
        } else if liveSub.isTrial {
            return "creditcard.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private var capsuleTitle: String {
        if liveSub.isPaused {
            return "Resume Subscription"
        } else if liveSub.isTrial {
            return "Convert Trial & Mark as Paid"
        } else {
            return "Mark as Paid & Record Expense"
        }
    }
    
    private var capsuleTrailingIcon: String {
        if liveSub.isPaused {
            return "arrow.triangle.2.circlepath"
        } else if liveSub.isTrial {
            return "arrow.right.circle.fill"
        } else {
            return "sparkles"
        }
    }
    
    private var capsuleBackgroundColor: Color {
        if liveSub.isPaused {
            return SpendyColors.incomeGreen.opacity(0.14)
        } else if liveSub.isTrial {
            return SpendyColors.warningOrange.opacity(0.14)
        } else {
            return themeColor.opacity(0.14)
        }
    }
    
    private var capsuleContentColor: Color {
        if liveSub.isPaused {
            return SpendyColors.incomeGreen
        } else if liveSub.isTrial {
            return SpendyColors.warningOrange
        } else {
            return themeColor
        }
    }
    
    private var capsuleStrokeColor: Color {
        if liveSub.isPaused {
            return SpendyColors.incomeGreen.opacity(0.32)
        } else if liveSub.isTrial {
            return SpendyColors.warningOrange.opacity(0.32)
        } else {
            return themeColor.opacity(0.30)
        }
    }
    
    private var contextualNoteText: String {
        if liveSub.isPaused {
            return "Subscription is currently paused. No upcoming expenses will be charged or logged."
        } else if liveSub.isTrial {
            return "Free trial active (\(daysUntilDue) days remaining). Convert to paid anytime to continue tracking."
        } else if liveSub.autoDeduct {
            return "Auto-log is active. Next payment of \(liveSub.amount.formattedCurrency(symbol: store.currencySymbol)) will be recorded from \(linkedAccount.label) on \(formattedDueDate)."
        } else {
            return "Manual logging enabled. Next billing is scheduled on \(formattedDueDate). Tap above to record payment now."
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // MARK: - Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Spacer to clear pinned floating top bar (44pt button + 20pt top inset + 8pt gap)
                        Spacer().frame(height: 64)
                        
                        // MARK: - Hero Section
                        heroSection
                        
                        Divider().overlay(SpendyColors.separator)
                            .padding(.horizontal, 4)
                        
                        // MARK: - Structured Details List
                        detailsList
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 24)
                }
                
                // MARK: - Floating Top Bar (✕ on Left, ••• on Right)
                topActionBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // MARK: - Floating Dynamic Toast Feedback Banner
                if showToast, let toast = toastMessage {
                    feedbackToastView(message: toast, icon: toastIcon, color: toastColor)
                        .padding(.top, 74)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(200)
                }
            }
            .background(Color.clear)
            .toolbar(.hidden, for: .navigationBar)
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
        .presentationDetents([.height(540), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
    
    // MARK: - Top Action Bar (✕ on Left, ••• Menu on Right)
    private var topActionBar: some View {
        HStack {
            // Close Button ✕ (Left)
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
            
            // More Options Menu ••• (Right)
            Menu {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit Subscription", systemImage: "pencil")
                }
                
                Button {
                    handleTogglePause()
                } label: {
                    Label(
                        liveSub.isPaused ? "Resume Subscription" : "Pause Subscription",
                        systemImage: liveSub.isPaused ? "play.fill" : "pause.fill"
                    )
                }
                
                Button {
                    handleToggleAutoDeduct()
                } label: {
                    Label(
                        liveSub.autoDeduct ? "Disable Auto-Log" : "Enable Auto-Log",
                        systemImage: liveSub.autoDeduct ? "bolt.slash.fill" : "bolt.fill"
                    )
                }
                
                Divider()
                
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Subscription", systemImage: "trash")
                }
            } label: {
                GlassCircleIcon(
                    size: 44,
                    tintColor: nil,
                    isInteractive: true,
                    morphID: "moreOptionsMenu",
                    namespace: sheetNamespace
                ) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Hero Section (Airy & Seamless)
    private var heroSection: some View {
        VStack(spacing: 12) {
            // Subscription Avatar Icon Badge + Title
            VStack(spacing: 6) {
                SpendyIconBadge(
                    sfSymbol: liveSub.sfSymbol,
                    color: themeColor,
                    size: .large,
                    style: .circle
                )
                .scaleEffect(heroPulseScale)
                .shadow(color: themeColor.opacity(liveSub.isPaused ? 0.05 : 0.35), radius: 12, y: 4)
                
                Text(liveSub.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
            }
            
            // Amount & Cycle Subtitle
            VStack(spacing: 4) {
                Text(liveSub.amount.formattedCurrency(symbol: store.currencySymbol))
                    .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                    .foregroundStyle(liveSub.isPaused ? SpendyColors.textTertiary : SpendyColors.textPrimary)
                    .contentTransition(.numericText())
                
                HStack(spacing: 6) {
                    Image(systemName: liveSub.isPaused ? "pause.circle.fill" : "repeat")
                        .font(.system(size: 11, weight: .bold))
                    Text("Billed \(liveSub.cycle.label.lowercased()) • \(statusBadgeText)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(statusBadgeColor)
            }
            
            // MARK: - Interactive Action Capsule Button (Compact & Integrated)
            Button {
                handleCapsuleAction()
            } label: {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .tint(capsuleContentColor)
                            .scaleEffect(0.8)
                        Text("Processing...")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(capsuleContentColor)
                    } else if isPaidSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(SpendyColors.incomeGreen)
                            .contentTransition(.symbolEffect(.replace))
                        Text(liveSub.isTrial ? "Trial Converted to Paid!" : "Payment Recorded!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.incomeGreen)
                    } else {
                        Image(systemName: capsuleIcon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(capsuleContentColor)
                            .contentTransition(.symbolEffect(.replace))
                        
                        Text(capsuleTitle)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(capsuleContentColor)
                        
                        Spacer()
                        
                        Image(systemName: capsuleTrailingIcon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(capsuleContentColor.opacity(0.75))
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(capsuleBackgroundColor, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(capsuleStrokeColor, lineWidth: 0.8)
                )
            }
            .buttonStyle(GlassCapsulePressStyle())
            .disabled(isProcessing || isPaidSuccess)
            .padding(.horizontal, 8)
            .padding(.top, 2)
            
            // Contextual Explanatory Note
            Text(contextualNoteText)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .lineSpacing(1.5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Structured Details List (Clean & Spacious)
    private var detailsList: some View {
        VStack(spacing: 14) {
            // 1. Payment Method / Account Row
            detailRow(icon: "creditcard.fill", label: "Payment Account") {
                HStack(spacing: 8) {
                    SpendyIconBadge(
                        sfSymbol: linkedAccount.sfSymbol.isEmpty ? linkedAccount.type.defaultSymbol : linkedAccount.sfSymbol,
                        color: Color(hex: linkedAccount.colorHex),
                        size: .small,
                        style: .circle
                    )
                    Text(linkedAccount.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            
            // 2. Category Row
            detailRow(icon: "tag.fill", label: "Category") {
                HStack(spacing: 8) {
                    SpendyIconBadge(
                        sfSymbol: linkedCategory?.sfSymbol ?? SFIcons.subscriptions,
                        color: Color(hex: linkedCategory?.colorHex ?? "#5856D6"),
                        size: .small,
                        style: .circle
                    )
                    Text(linkedCategory?.label ?? "Subscriptions")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            
            // 3. Billing Cycle Row
            detailRow(icon: "repeat", label: "Billing Cycle") {
                HStack(spacing: 8) {
                    Text(liveSub.cycle.label)
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
            
            // 4. Next Billing Due Date Row
            detailRow(icon: "calendar", label: "Next Billing") {
                Text(formattedDueDate)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            
            // 5. Auto-Log Toggle Row
            detailRow(icon: "bolt.fill", label: "Auto-Log Expense") {
                Toggle("", isOn: Binding(
                    get: { liveSub.autoDeduct },
                    set: { newValue in
                        handleToggleAutoDeduct(to: newValue)
                    }
                ))
                .labelsHidden()
                .tint(SpendyColors.incomeGreen)
            }
            
            // 6. Annual Projection Row
            detailRow(icon: "chart.line.uptrend.xyaxis", label: "Annual Cost") {
                Text("\(annualProjectedCost.formattedCurrency(symbol: store.currencySymbol)) / yr")
                    .spendyNumberFont(size: 14, weight: .bold, tracking: -0.4)
                    .foregroundStyle(SpendyColors.textPrimary)
            }
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Action Handlers with Rich Spring Animation & Toast Feedback
    
    private func handleCapsuleAction() {
        if liveSub.isPaused {
            handleTogglePause()
        } else {
            handleSettlePayment()
        }
    }
    
    private func handleTogglePause() {
        HapticsManager.shared.trigger(.medium)
        
        let wasPaused = liveSub.isPaused
        
        withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.65)) {
            if !reduceMotion {
                heroPulseScale = 1.12
            }
            store.toggleSubscriptionPause(id: liveSub.id)
            toastMessage = wasPaused ? "Subscription Resumed & Active!" : "Subscription Paused"
            toastIcon = wasPaused ? "checkmark.circle.fill" : "pause.circle.fill"
            toastColor = wasPaused ? SpendyColors.incomeGreen : SpendyColors.warningOrange
            showToast = true
        }
        
        if !reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    heroPulseScale = 1.0
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showToast = false
            }
        }
    }
    
    private func handleToggleAutoDeduct(to newValue: Bool? = nil) {
        HapticsManager.shared.trigger(.light)
        var updated = liveSub
        let nextValue = newValue ?? !liveSub.autoDeduct
        updated.autoDeduct = nextValue
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            store.updateSubscription(updated)
            toastMessage = nextValue ? "Auto-Log Enabled" : "Auto-Log Disabled"
            toastIcon = nextValue ? "bolt.fill" : "bolt.slash.fill"
            toastColor = nextValue ? SpendyColors.incomeGreen : SpendyColors.textSecondary
            showToast = true
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
                toastMessage = "Payment Logged for \(liveSub.name)!"
                toastIcon = "checkmark.circle.fill"
                toastColor = SpendyColors.incomeGreen
                showToast = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                dismiss()
            }
        }
    }
    
    // MARK: - Toast Banner View
    private func feedbackToastView(message: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            
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
                .shadow(color: Color.black.opacity(0.25), radius: 12, y: 6)
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func detailRow<V: View>(icon: String, label: String, @ViewBuilder valueView: () -> V) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
                .frame(width: 24, height: 24)
            
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Spacer()
            
            valueView()
        }
    }
}

// MARK: - Glass Capsule Press Style
struct GlassCapsulePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

