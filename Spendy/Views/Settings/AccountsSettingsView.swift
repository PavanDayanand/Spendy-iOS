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
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Top Custom Header Bar
                    headerBar
                    
                    // Net Worth & Trend Hero
                    heroNetWorthSection
                    
                    // Accounts List
                    accountsListSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 120) // Clearance for floating bottom bar
            }
            
            // Bottom Floating Action (Add +)
            bottomFloatingBar
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddAccount) {
            AddAccountSheet()
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            currencyPickerSheet
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $editingAccount) { acc in
            AddAccountSheet(accountToEdit: acc)
                .presentationBackground(SpendyColors.appBackground)
        }
        .navigationDestination(item: $selectedAccountForAnalytics) { acc in
            AccountAnalyticsSheet(account: acc)
        }
    }
    
    // MARK: - Top Header Bar
    private var headerBar: some View {
        HStack {
            // Circular Glass Back Button
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 15,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Back"
            ) {
                dismiss()
            }
            
            Spacer()
            
            Text("Settings")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            // Placeholder to align title
            Spacer()
                .frame(width: 44)
        }
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
            }
            .buttonStyle(.plain)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatShortCurrency(store.totalBalance))
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
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
            HStack(spacing: 8) {
                ForEach(AccountFilter.allCases) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.25)) {
                            selectedFilter = filter
                        }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(selectedFilter == filter ? Color.black : SpendyColors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                if selectedFilter == filter {
                                    Capsule()
                                        .fill(Color.white)
                                } else {
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .overlay {
                                            Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                        }
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                let totalFiltered = filteredAccounts.map { store.balance(for: $0.id) }.reduce(0, +)
                Text(totalFiltered.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 14, weight: .semibold))
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
                            .fill(SpendyColors.cardBackground)
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
                                // Rounded Square Badge using Custom Color!
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(hex: account.colorHex))
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color(hex: account.colorHex).opacity(0.35), radius: 6, y: 3)
                                    
                                    let isLightColor = account.colorHex.uppercased() == "#FFFFFF" || account.colorHex.uppercased() == "FFFFFF" || account.colorHex.uppercased() == "#E4E4E7" || account.colorHex.uppercased() == "#D4D4D8"
                                    
                                    Image(systemName: account.sfSymbol)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(isLightColor ? Color.black : Color.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(account.label)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                    
                                    Text("Tap for analytics & details")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(SpendyColors.textTertiary)
                                }
                                
                                Spacer()
                                
                                Text(balance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundStyle(SpendyColors.textPrimary)
                            }
                            .padding(16)
                            .background {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(SpendyColors.cardBackground)
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
        HStack {
            Spacer()
            
            // Plus (+) Add Account Button
            GlassCircleButton(
                icon: SFIcons.plus,
                size: 54,
                iconSize: 20,
                tintColor: SpendyColors.primaryBlue,
                foregroundColor: Color(uiColor: .dynamic(light: .white, dark: .black)),
                haptic: .medium,
                accessibilityLabel: "Add Account"
            ) {
                showAddAccount = true
            }
            .shadow(color: Color.black.opacity(0.15), radius: 14, y: 6)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Currency Picker Sheet
    private var currencyPickerSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(supportedCurrencies, id: \.code) { curr in
                            Button(action: {
                                HapticsManager.shared.trigger(.selection)
                                store.currencySymbol = curr.symbol
                                store.currencyCode = curr.code
                                showCurrencyPicker = false
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(curr.code)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(SpendyColors.textPrimary)
                                        Text(curr.name)
                                            .font(.system(size: 12))
                                            .foregroundStyle(SpendyColors.textSecondary)
                                    }
                                    Spacer()
                                    Text(curr.symbol)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(store.currencyCode == curr.code ? SpendyColors.primaryBlue : SpendyColors.textSecondary)
                                }
                                .padding(16)
                                .background {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(SpendyColors.cardBackground)
                                        .overlay {
                                            if store.currencyCode == curr.code {
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(SpendyColors.primaryBlue, lineWidth: 1.5)
                                            } else {
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .stroke(SpendyColors.separator, lineWidth: 0.8)
                                            }
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showCurrencyPicker = false }
                }
            }
        }
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
    
    private let supportedCurrencies: [(code: String, symbol: String, name: String)] = [
        ("INR", "₹", "Indian Rupee"),
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("JPY", "¥", "Japanese Yen"),
        ("CAD", "$", "Canadian Dollar"),
        ("AUD", "$", "Australian Dollar"),
        ("AED", "د.إ", "UAE Dirham"),
        ("SGD", "$", "Singapore Dollar")
    ]
}
