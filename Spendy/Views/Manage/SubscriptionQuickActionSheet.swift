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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    let sub: Subscription
    let onEdit: (Subscription) -> Void
    
    // Action & Animation States
    @State private var isPaidSuccess: Bool = false
    @State private var isProcessing: Bool = false
    @State private var showDeleteConfirmation: Bool = false
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
        SpendyDateFormatterCache.dayMonth.string(from: liveSub.nextBillingDate)
    }
    
    private var daysUntilDue: Int {
        let calendar = Calendar.current
        let now = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: liveSub.nextBillingDate)
        return calendar.dateComponents([.day], from: now, to: target).day ?? 0
    }
    
    private var relativeDueString: String {
        if daysUntilDue == 0 {
            return "today"
        } else if daysUntilDue == 1 {
            return "in 1 day"
        } else if daysUntilDue > 1 {
            return "in \(daysUntilDue) days"
        } else {
            return "\(abs(daysUntilDue)) days ago"
        }
    }
    
    private var nextPaymentDisplay: String {
        "\(formattedDueDate) (\(relativeDueString))"
    }
    
    private var totalSpent: Double {
        store.transactions
            .filter {
                ($0.subscriptionId?.lowercased() == liveSub.id.uuidString.lowercased()) ||
                ($0.title.lowercased() == liveSub.name.lowercased() && $0.type == .expense)
            }
            .reduce(0.0) { $0 + $1.amount }
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
    
    private var capsuleBackgroundColor: Color { store.accentPreset.fill }
    private var capsuleContentColor: Color { store.accentPreset.foreground }
    private var capsuleStrokeColor: Color { SpendyColors.separator }

    private var contextualNoteText: String {
        if liveSub.isPaused {
            return "Subscription is currently paused. No upcoming expenses will be charged or logged."
        } else if liveSub.isTrial {
            if daysUntilDue < 0 {
                return "Free trial ended \(abs(daysUntilDue)) days ago. Convert to paid anytime to continue tracking."
            } else if daysUntilDue == 0 {
                return "Free trial ends today. Convert to paid anytime to continue tracking."
            } else if daysUntilDue == 1 {
                return "Free trial active (1 day remaining). Convert to paid anytime to continue tracking."
            } else {
                return "Free trial active (\(daysUntilDue) days remaining). Convert to paid anytime to continue tracking."
            }
        } else if liveSub.autoDeduct {
            return "Auto-log is active. Next payment of \(liveSub.amount.formattedCurrency(symbol: store.currencySymbol)) will be recorded from \(linkedAccount.label) on \(formattedDueDate)."
        } else {
            return "Manual logging enabled. Next billing is scheduled on \(formattedDueDate). Tap above to record payment now."
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Ambient Subscription Gradient Header Glow
            SpendyAmbientHeaderBackground(color: themeColor, height: 320, opacity: 0.30)
            
            // MARK: - Scrollable Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Spacer to clear pinned top bar
                    Spacer().frame(height: 56)
                    
                    // MARK: - Hero Section (Standard Spendy Progress Ring Badge)
                    heroSection
                        .padding(.top, 4)
                        .padding(.bottom, 6)
                    
                    // MARK: - Grouped Details Card (Consistent with Edit Subscription Sheet)
                    detailsCard
                    
                    // MARK: - Action Capsule Button & Footnote (Image 2)
                    actionSection
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            
            // MARK: - Pinned Top Action Bar (✕ on Left, Pen Icon on Right)
            topActionBar
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            // MARK: - Floating Toast Feedback
            if showToast, let toast = toastMessage {
                feedbackToastView(message: toast, icon: toastIcon, color: toastColor)
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(200)
            }
        }
        .background(Color.clear)
        .alert("Delete Subscription?", isPresented: $showDeleteConfirmation) {
            Button("Delete Subscription", role: .destructive) {
                HapticsManager.shared.trigger(.warning)
                store.deleteSubscription(id: liveSub.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(liveSub.name)? This action cannot be undone.")
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(500), .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Top Action Bar (✕ on Left, Pen Circle on Right)
    private var topActionBar: some View {
        SpendyCreateSheetHeader(
            onClose: { dismiss() },
            trailing: {
                GlassCircleButton(
                    icon: SFIcons.edit,
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .selection,
                    accessibilityLabel: "Edit Subscription"
                ) {
                    onEdit(liveSub)
                }
            }
        )
    }
    
    // MARK: - Hero Section (Standard Spendy Progress Ring Badge, Title & Status Pill)
    private var heroSection: some View {
        VStack(spacing: 8) {
            // Existing SubscriptionProgressRingBadge with cycle progress ring
            SubscriptionProgressRingBadge(
                subscription: liveSub,
                size: .large
            )
            .scaleEffect(heroPulseScale)
            .padding(.bottom, 2)
            
            // Subscription Name
            Text(liveSub.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            // Cycle • Price Subtitle
            Text("\(liveSub.cycle.label) • \(liveSub.amount.formattedCurrency(symbol: store.currencySymbol))")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            
            // Status Menu Capsule Pill (Active / Free Trial / Paused) pushed to the body itself
            statusPillMenu
                .padding(.top, 2)
        }
    }
    
    // MARK: - Status Pill Menu (In Body)
    private var statusPillMenu: some View {
        Menu {
            Button {
                handleSetActive()
            } label: {
                Label("Active", systemImage: "checkmark.circle")
            }
            
            Button {
                handleSetTrial()
            } label: {
                Label("Free Trial", systemImage: "clock")
            }
            
            Button {
                handleTogglePause()
            } label: {
                Label(
                    liveSub.isPaused ? "Resume Subscription" : "Pause Subscription",
                    systemImage: liveSub.isPaused ? "play.fill" : "pause.fill"
                )
            }
            
            Divider()
            
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Subscription", systemImage: "trash")
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusBadgeColor)
                    .frame(width: 8, height: 8)
                
                Text(statusBadgeText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .nativeLiquidGlassCapsule(isInteractive: true)
            .contentShape(Capsule())
        }
    }
    
    // MARK: - Grouped Details Card (Consistent with Edit Subscription Sheet)
    private var detailsCard: some View {
        VStack(spacing: 0) {
            // 1. Amount Row
            HStack {
                Text("Amount")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Text(liveSub.amount.formattedCurrency(symbol: store.currencySymbol))
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.vertical, 14)
            
            Divider().background(SpendyColors.separator)
            
            // 2. Next payment Row
            HStack {
                Text("Next payment")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Text(nextPaymentDisplay)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.vertical, 14)
            
            Divider().background(SpendyColors.separator)
            
            // 3. Total spent Row
            HStack {
                Text("Total spent")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Text(totalSpent.formattedCurrency(symbol: store.currencySymbol))
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.vertical, 14)
            
            Divider().background(SpendyColors.separator)
            
            // 4. Notifications Row
            HStack {
                Text("Notifications")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                Menu {
                    Button {
                        handleToggleAutoDeduct(to: false)
                    } label: {
                        Label("Default (Reminders Only)", systemImage: "bell.fill")
                    }
                    Button {
                        handleToggleAutoDeduct(to: true)
                    } label: {
                        Label("Auto-Log Payment", systemImage: "bolt.fill")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(liveSub.autoDeduct ? "Auto-Log" : "Default")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                    .frame(minHeight: 32)
                    .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 12)
            
            Divider().background(SpendyColors.separator)
            
            // 5. Category Row
            HStack {
                Text("Category")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    SpendyIconBadge(
                        sfSymbol: linkedCategory?.sfSymbol ?? SFIcons.subscriptions,
                        color: Color(hex: linkedCategory?.colorHex ?? "#5856D6"),
                        size: .small,
                        style: .circle,
                        monogramName: linkedCategory?.label ?? ""
                    )
                    
                    Text(linkedCategory?.label ?? "Subscriptions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            .padding(.vertical, 12)
            
            Divider().background(SpendyColors.separator)
            
            // 6. Payment Account Row
            HStack {
                Text("Payment Account")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    let accountSymbol: String = {
                        if !linkedAccount.sfSymbol.isEmpty {
                            return linkedAccount.sfSymbol
                        }
                        return linkedAccount.type.defaultSymbol
                    }()
                    SpendyIconBadge(
                        sfSymbol: accountSymbol,
                        color: Color(hex: linkedAccount.colorHex),
                        size: .small,
                        style: .rounded(),
                        monogramName: linkedAccount.label
                    )
                    
                    Text(linkedAccount.label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }

    
    // MARK: - Action Section (Image 2: Capsule Button & Contextual Note)
    private var actionSection: some View {
        VStack(spacing: 10) {
            // Interactive Action Capsule Button
            Button {
                handleCapsuleAction()
            } label: {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView()
                            .tint(capsuleContentColor)
                            .scaleEffect(0.85)
                        Text("Processing...")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(capsuleContentColor)
                    } else if isPaidSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(capsuleContentColor)
                            .contentTransition(.symbolEffect(.replace))
                        Text(liveSub.isTrial ? "Trial Converted to Paid!" : "Payment Recorded!")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(capsuleContentColor)
                    } else {
                        Image(systemName: capsuleIcon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(capsuleContentColor)
                            .contentTransition(.symbolEffect(.replace))
                        
                        Text(capsuleTitle)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(capsuleContentColor)
                        
                        Spacer()
                        
                        Image(systemName: capsuleTrailingIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(capsuleContentColor.opacity(0.8))
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(capsuleBackgroundColor, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(capsuleStrokeColor, lineWidth: 0.8)
                )
            }
            .buttonStyle(GlassCapsulePressStyle())
            .disabled(isProcessing || isPaidSuccess)
            
            // Contextual Explanatory Note with Fixed Days Logic
            Text(contextualNoteText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Action Handlers with Rich Spring Animation & Toast Feedback
    
    private func handleCapsuleAction() {
        if liveSub.isPaused {
            handleTogglePause()
        } else {
            handleSettlePayment()
        }
    }
    
    private func handleSetActive() {
        HapticsManager.shared.trigger(.selection)
        var updated = liveSub
        updated.isPaused = false
        updated.isTrial = false
        updated.status = "active"
        store.updateSubscription(updated)
        showFeedback(message: "Subscription Set to Active", icon: "checkmark.circle.fill", color: SpendyColors.incomeGreen)
    }
    
    private func handleSetTrial() {
        HapticsManager.shared.trigger(.selection)
        var updated = liveSub
        updated.isTrial = true
        updated.isPaused = false
        updated.status = "active"
        store.updateSubscription(updated)
        showFeedback(message: "Subscription Marked as Free Trial", icon: "clock.fill", color: SpendyColors.warningOrange)
    }
    
    private func handleTogglePause() {
        HapticsManager.shared.trigger(.medium)
        
        let wasPaused = liveSub.isPaused
        
        withAnimation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.65)) {
            if !reduceMotion {
                heroPulseScale = 1.12
            }
            store.toggleSubscriptionPause(id: liveSub.id)
            showFeedback(
                message: wasPaused ? "Subscription Resumed & Active!" : "Subscription Paused",
                icon: wasPaused ? "checkmark.circle.fill" : "pause.circle.fill",
                color: wasPaused ? SpendyColors.incomeGreen : SpendyColors.warningOrange
            )
        }
        
        if !reduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    heroPulseScale = 1.0
                }
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
            showFeedback(
                message: nextValue ? "Auto-Log Enabled" : "Auto-Log Disabled",
                icon: nextValue ? "bolt.fill" : "bolt.slash.fill",
                color: nextValue ? SpendyColors.incomeGreen : SpendyColors.textSecondary
            )
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
                showFeedback(
                    message: "Payment Logged for \(liveSub.name)!",
                    icon: "checkmark.circle.fill",
                    color: SpendyColors.incomeGreen
                )
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                dismiss()
            }
        }
    }
    
    private func showFeedback(message: String, icon: String, color: Color) {
        toastMessage = message
        toastIcon = icon
        toastColor = color
        withAnimation(.easeInOut(duration: 0.25)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showToast = false
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
