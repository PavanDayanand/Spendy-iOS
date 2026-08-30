//
//  AccountsSettingsView.swift
//  Spendy
//
//  Real-Time Accounts Hub with Net Worth Trends, Balance Adjustments & Segregation
//

import SwiftUI

struct AccountsSettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddAccount: Bool = false
    @State private var showCurrencyPicker: Bool = false
    @State private var editingAccount: Account? = nil
    @State private var selectedAccountForAnalytics: Account? = nil
    @State private var selectedFilter: AccountFilter = .all
    @Namespace private var accountsNamespace
    
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
            
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 64) // Clean top clearance for floating header
                        
                        // 1. Net Worth Hero Card with Currency Switcher
                        heroNetWorthSection
                            .padding(.horizontal, 16)
                        
                        // 2. Accounts List Section (with horizontal type filters)
                        accountsListSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100) // Clearance for bottom floating button
                    }
                }
                
                // Floating Sticky Header Bar
                headerBar
                    .padding(.top, 16)
                    .zIndex(100)
            }

            
            // Bottom Floating Action (Add +)
            VStack {
                Spacer()
                bottomFloatingBar
            }
        }
        .navigationBarBackButtonHidden(true)
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
    
    // MARK: - Top Header Bar
    private var headerBar: some View {
        SpendyGlassEffectContainer(spacing: 0) {
            ZStack {
                Text("Accounts")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 60)
                
                HStack {
                    // Circular Glass Back Button
                    GlassCircleButton(
                        icon: "chevron.left",
                        size: 44,
                        iconSize: 16,
                        iconWeight: .bold,
                        foregroundColor: SpendyColors.textPrimary,
                        haptic: .selection,
                        accessibilityLabel: "Back",
                        morphID: "backButton",
                        namespace: accountsNamespace
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
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
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: SFIcons.chevronDown)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .nativeLiquidGlassCapsule(isInteractive: true)
                .glassMorphID("currencyPill", in: accountsNamespace)
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
                            .font(.system(size: 11, weight: .bold))
                        Text(String(format: "%+.1f%% raise vs last month", change))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(change >= 0 ? SpendyColors.incomeGreen : SpendyColors.expenseRed)
                }
                
                Spacer()
                
                // Sparkline Trend Curve
                sparklineView
                    .frame(width: 90, height: 38)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Account Filter Tabs Switcher
    private var filterTabs: some View {
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
    }

    
    // MARK: - Accounts List Section
    private var accountsListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Horizontal Filters
            filterTabs
                .padding(.vertical, 4)
            
            // Section Header: Group Name on left, Total on right
            HStack {
                Text(selectedFilter == .all ? "Wallets & Accounts" : "\(selectedFilter.rawValue) Accounts")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                let totalFiltered = filteredAccounts.map { store.balance(for: $0.id) }.reduce(0, +)
                Text(totalFiltered.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .spendyNumberFont(size: 17, weight: .medium, tracking: -0.4)
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                if filteredAccounts.isEmpty {
                    VStack(spacing: 8) {
                        Text("No accounts in this category")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        Button(action: {
                            showAddAccount = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 12))
                                Text("Add Account")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(SpendyColors.primaryBlue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(SpendyColors.sheetCardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(SpendyColors.separator, lineWidth: 0.8)
                            }
                    }
                } else {
                    ForEach(filteredAccounts, id: \.id) { account in
                        let balance = store.balance(for: account.id)
                        
                        Button(action: {
                            HapticsManager.shared.trigger(.selection)
                            selectedAccountForAnalytics = account
                        }) {
                            HStack(spacing: 14) {
                                // SpendyIconBadge using Custom Symbol & Color
                                SpendyIconBadge(
                                    sfSymbol: account.sfSymbol.isEmpty ? account.type.defaultSymbol : account.sfSymbol,
                                    color: Color(hex: account.colorHex),
                                    size: .medium
                                )
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(account.label)
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                    
                                    Text("Tap for analytics & details")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(SpendyColors.textTertiary)
                                }
                                
                                Spacer()
                                
                                Text(balance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                    .spendyNumberFont(size: 17, weight: .medium, tracking: -0.4)
                                    .foregroundStyle(SpendyColors.textPrimary)
                            }
                            .padding(16)
                            .background {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(SpendyColors.sheetCardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                                    }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Sparkline Curve
    private var sparklineView: some View {
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
        SpendyGlassEffectContainer {
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
                    accessibilityLabel: "Add Account",
                    morphID: "addAccountButton",
                    namespace: accountsNamespace
                ) {
                    showAddAccount = true
                }
                .shadow(color: Color.black.opacity(0.15), radius: 14, y: 6)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
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
