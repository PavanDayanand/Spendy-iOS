//
//  AccountsView.swift
//  Spendy
//
//  Dedicated Full-Screen Accounts View for the Main Dashboard Screen with Real-Time Net Worth,
//  Account Type Filtering, and Direct Navigation to Account Analytics.
//

import SwiftUI

struct AccountsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var onDismiss: (() -> Void)? = nil
    var topControlsNamespace: Namespace.ID? = nil
    
    @State private var showAddAccount: Bool = false
    @State private var showCurrencyPicker: Bool = false
    @State private var editingAccount: Account? = nil
    @State private var selectedAccountForAnalytics: Account? = nil
    @State private var selectedFilter: AccountFilter = .all
    
    enum AccountFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case cash = "Cash"
        case bank = "Bank"
        case amazonPay = "Amazon Pay"
        case savings = "Savings"
        
        var id: String { rawValue }
        
        var type: AccountType? {
            switch self {
            case .all: return nil
            case .cash: return .cash
            case .bank: return .bank
            case .amazonPay: return .amazonPay
            case .savings: return .savings
            }
        }
    }
    
    private var filteredAccounts: [Account] {
        if let type = selectedFilter.type {
            return store.accounts.filter { $0.type == type }
        }
        return store.accounts
    }
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            // Dynamic Ambient Full-Width Blue Header Glow
            SpendyAmbientHeaderBackground(color: SpendyColors.primaryBlue, height: 380, opacity: 0.28)
            
            VStack(spacing: 0) {
                if topControlsNamespace != nil {
                    topHeaderBar
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Net Worth Hero Card with Currency Switcher & Sparkline
                        heroNetWorthSection
                            .padding(.horizontal, 16)
                            .padding(.top, topControlsNamespace != nil ? 4 : 12)
                        
                        // 2. Accounts List Section (with horizontal type filters)
                        accountsListSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100) // Clearance for bottom floating button
                    }
                }
            }
            
            // Bottom Floating Action Button (Add +)
            VStack {
                Spacer()
                bottomFloatingBar
            }
        }
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(topControlsNamespace != nil ? .hidden : .visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showAddAccount) {
            AddAccountSheet()
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $editingAccount) { acc in
            AddAccountSheet(accountToEdit: acc)
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet()
        }
        .navigationDestination(item: $selectedAccountForAnalytics) { acc in
            AccountAnalyticsSheet(account: acc)
        }
    }
    
    // MARK: - Top Header Bar (When Pushed from Home with Liquid Glass Morph)
    private var topHeaderBar: some View {
        HStack {
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 15,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Back",
                morphID: "topControl_left",
                namespace: topControlsNamespace
            ) {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }
            
            Spacer()
            
            Text("Accounts")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            // Balance placeholder to center title
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 2)
    }
    
    // MARK: - Net Worth Hero Section
    private var heroNetWorthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Currency Selector Chip
            Button(action: {
                HapticsManager.shared.trigger(.light)
                showCurrencyPicker = true
            }) {
                HStack(spacing: 4) {
                    Text("Total in \(store.currencyCode)")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: SFIcons.chevronDown)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .nativeLiquidGlassCapsule(isInteractive: true)
                .modifier(OptionalGlassMorphModifier(id: topControlsNamespace != nil ? "accountDropdownCapsule" : nil, namespace: topControlsNamespace))
            }
            .buttonStyle(.plain)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatShortCurrency(store.totalBalance))
                        .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                        .foregroundStyle(SpendyColors.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    let change = store.netWorthChangePercentage
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 12, weight: .bold))
                        Text(String(format: "%+.1f%% vs last month", change))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(change >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
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
    
    // MARK: - Accounts List Section
    private var accountsListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Horizontal Type Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                GlassSegmentedPicker(
                    selection: $selectedFilter,
                    items: AccountFilter.allCases,
                    titleFor: { $0.rawValue },
                    expandsToFillWidth: false
                )
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }

            
            // Subheader: "Wallets & Accounts" with subtotal
            HStack {
                Text("Wallets & Accounts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Spacer()
                
                let subtotal = filteredAccounts.reduce(0.0) { $0 + store.balance(for: $1.id) }
                Text(formatShortCurrency(subtotal))
                    .spendyNumberFont(size: 15, weight: .semibold, tracking: -0.4)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            .padding(.top, 6)
            
            // List of Account Cards
            if filteredAccounts.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredAccounts) { acc in
                        accountRowCard(account: acc)
                    }
                }
            }
        }
    }
    
    // MARK: - Account Row Card
    private func accountRowCard(account: Account) -> some View {
        let bal = store.balance(for: account.id)
        
        return Button(action: {
            HapticsManager.shared.trigger(.selection)
            selectedAccountForAnalytics = account
        }) {
            HStack(spacing: AppSpacing.md14) {
                // Vibrant Account Icon Badge
                SpendyIconBadge(
                    sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                    color: account.color,
                    size: .medium,
                    style: .circle
                )
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(account.label)
                        .font(AppTypography.rowTitle)
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text("Tap for analytics & details")
                        .font(AppTypography.captionMedium)
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                    Text(bal.formattedCurrency(symbol: store.currencySymbol))
                        .spendyNumberFont(size: 16, weight: .bold, tracking: -0.4)
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md14)
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
            Button(action: {
                HapticsManager.shared.trigger(.light)
                selectedAccountForAnalytics = account
            }) {
                Label("View Analytics", systemImage: "chart.bar.xaxis")
            }

            Button(action: {
                HapticsManager.shared.trigger(.light)
                editingAccount = account
            }) {
                Label("Edit Account", systemImage: "pencil")
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.and.123")
                .font(.system(size: 36))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.top, 24)
            
            Text("No accounts in this category")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Button("Add Account") {
                showAddAccount = true
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
    
    // MARK: - Net Worth Sparkline
    private var trendSparkline: some View {
        let isPositive = store.netWorthChangePercentage >= 0
        let col = isPositive ? Color(hex: "#30D158") : Color(hex: "#FF3B30")
        
        return GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            
            ZStack(alignment: .bottomTrailing) {
                Path { path in
                    if isPositive {
                        path.move(to: CGPoint(x: 0, y: h * 0.8))
                        path.addCurve(
                            to: CGPoint(x: w, y: h * 0.1),
                            control1: CGPoint(x: w * 0.6, y: h * 0.8),
                            control2: CGPoint(x: w * 0.8, y: h * 0.2)
                        )
                    } else {
                        path.move(to: CGPoint(x: 0, y: h * 0.1))
                        path.addCurve(
                            to: CGPoint(x: w, y: h * 0.85),
                            control1: CGPoint(x: w * 0.4, y: h * 0.15),
                            control2: CGPoint(x: w * 0.7, y: h * 0.4)
                        )
                    }
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
                    if isPositive {
                        path.move(to: CGPoint(x: 0, y: h * 0.8))
                        path.addCurve(
                            to: CGPoint(x: w, y: h * 0.1),
                            control1: CGPoint(x: w * 0.6, y: h * 0.8),
                            control2: CGPoint(x: w * 0.8, y: h * 0.2)
                        )
                    } else {
                        path.move(to: CGPoint(x: 0, y: h * 0.1))
                        path.addCurve(
                            to: CGPoint(x: w, y: h * 0.85),
                            control1: CGPoint(x: w * 0.4, y: h * 0.15),
                            control2: CGPoint(x: w * 0.7, y: h * 0.4)
                        )
                    }
                }
                .stroke(col, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .shadow(color: col.opacity(0.3), radius: 4, y: 1)
            }
        }
    }
    
    // MARK: - Bottom Floating Action Buttons
    private var bottomFloatingBar: some View {
        HStack {
            Spacer()
            
            // Plus (+) Add Account Button
            GlassCircleButton(
                icon: SFIcons.plus,
                size: 54,
                iconSize: 20,
                tintColor: SpendyColors.primaryBlue,
                foregroundColor: Color.white,
                haptic: .medium,
                accessibilityLabel: "Add Account"
            ) {
                showAddAccount = true
            }
            .shadow(color: Color.black.opacity(0.15), radius: 14, y: 6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    private func formatShortCurrency(_ value: Double) -> String {
        let sym = store.currencySymbol
        if abs(value) >= 1_000_000 {
            return String(format: "%@%.1fM", sym, value / 1_000_000)
        } else if abs(value) >= 1_000 {
            return String(format: "%@%.1fK", sym, value / 1_000)
        } else {
            return value.formattedCurrency(symbol: sym, decimals: 0)
        }
    }
}
