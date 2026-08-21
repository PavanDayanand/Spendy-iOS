//
//  AccountsSettingsView.swift
//  Spendy
//
//  Real-Time Accounts Hub with Net Worth Trends, Balance Adjustments & Migration
//

import SwiftUI

struct AccountsSettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddAccount: Bool = false
    @State private var showAddTransfer: Bool = false
    @State private var showCurrencyPicker: Bool = false
    @State private var editingAccount: Account? = nil
    @State private var tempAccountName: String = ""
    @State private var tempAccountBalance: String = ""
    @State private var accountToDelete: Account? = nil
    
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
            
            // Bottom Floating Actions (Transfer ⇅ and Add +)
            bottomFloatingBar
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddAccount) {
            AddAccountSheet()
        }
        .sheet(isPresented: $showAddTransfer) {
            AddTransactionView()
        }
        .sheet(isPresented: $showCurrencyPicker) {
            currencyPickerSheet
        }
        .sheet(item: $editingAccount) { acc in
            editAccountSheet(for: acc)
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: Binding(
                get: { accountToDelete != nil },
                set: { if !$0 { accountToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            let fallback = store.accounts.first(where: { $0.id != accountToDelete?.id })
            
            Button("Delete & Move Transactions to \(fallback?.label ?? "Cash")", role: .destructive) {
                if let acc = accountToDelete {
                    store.deleteAccount(id: acc.id, fallbackId: fallback?.id ?? "cash")
                }
                accountToDelete = nil
            }
            
            Button("Delete Without Moving", role: .destructive) {
                if let acc = accountToDelete {
                    store.deleteAccount(id: acc.id, fallbackId: nil)
                }
                accountToDelete = nil
            }
            
            Button("Cancel", role: .cancel) {
                accountToDelete = nil
            }
        } message: {
            Text("What would you like to do with transactions linked to \(accountToDelete?.label ?? "this account")?")
        }
    }
    
    // MARK: - Top Header Bar
    private var headerBar: some View {
        HStack {
            // Circular Glass Back Button
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .nativeLiquidGlassCircle(isInteractive: true)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("Accounts")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Spacer()
            
            // Top Right Currency / Settings Icon
            Button(action: {
                HapticsManager.shared.trigger(.light)
                showCurrencyPicker = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .nativeLiquidGlassCircle(isInteractive: true)
            }
            .buttonStyle(.plain)
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
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                    Image(systemName: SFIcons.chevronDown)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .nativeLiquidGlassCapsule(isInteractive: true)
            }
            .buttonStyle(.plain)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(formatShortCurrency(store.totalBalance))
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 11, weight: .bold))
                        Text("+\(store.monthlyIncome.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) vs last month")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(SpendyColors.incomeGreen)
                }
                
                Spacer()
                
                // Sparkline Trend Curve
                sparklineView
                    .frame(width: 90, height: 38)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Accounts List Section
    private var accountsListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header: Group Name on left, Total on right
            HStack {
                Text("Wallets & Accounts")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
                
                Spacer()
                
                Text(store.totalBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.60))
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(Array(store.accounts.enumerated()), id: \.element.id) { index, account in
                    let balance = store.balance(for: account.id)
                    let isPrimary = index == 0
                    let isCash = account.id == "cash"
                    
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        tempAccountName = account.label
                        tempAccountBalance = String(format: "%.0f", balance)
                        editingAccount = account
                    }) {
                        HStack(spacing: 14) {
                            // Rounded Square Badge with Initial Letter or Icon (Monochrome)
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(account.colorHex == "#18181B" ? Color.black : Color(uiColor: .dynamic(light: UIColor(white: 0.85, alpha: 1), dark: UIColor(white: 0.2, alpha: 1))))
                                    .frame(width: 44, height: 44)
                                
                                if isCash {
                                    Image(systemName: "banknote.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(account.colorHex == "#18181B" ? Color.white : SpendyColors.textPrimary)
                                } else {
                                    Text(String(account.label.prefix(1)).uppercased())
                                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                                        .foregroundStyle(account.colorHex == "#18181B" ? Color.white : SpendyColors.textPrimary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(account.label)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                    
                                    if isPrimary {
                                        Text("PRIMARY")
                                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                                            .tracking(0.6)
                                            .foregroundStyle(SpendyColors.textPrimary.opacity(0.8))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(SpendyColors.textPrimary.opacity(0.12), in: Capsule())
                                    }
                                }
                                
                                Text("Tap to edit balance")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            
                            Spacer()
                            
                            Text(balance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
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
                    .contextMenu {
                        Button {
                            tempAccountName = account.label
                            tempAccountBalance = String(format: "%.0f", balance)
                            editingAccount = account
                        } label: {
                            Label("Edit Account", systemImage: SFIcons.edit)
                        }
                        
                        if !isCash && store.accounts.count > 1 {
                            Button(role: .destructive) {
                                accountToDelete = account
                            } label: {
                                Label("Delete Account", systemImage: SFIcons.delete)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sparkline Curve
    private var sparklineView: some View {
        GeometryReader { proxy in
            Path { path in
                let w = proxy.size.width
                let h = proxy.size.height
                
                path.move(to: CGPoint(x: 0, y: h * 0.8))
                path.addCurve(
                    to: CGPoint(x: w, y: h * 0.1),
                    control1: CGPoint(x: w * 0.6, y: h * 0.8),
                    control2: CGPoint(x: w * 0.8, y: h * 0.2)
                )
            }
            .stroke(
                LinearGradient(
                    colors: [Color.white.opacity(0.3), Color.white],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: Color.white.opacity(0.35), radius: 4, y: 1)
        }
    }
    
    // MARK: - Bottom Floating Action Buttons
    private var bottomFloatingBar: some View {
        HStack {
            // Transfer ⇅ Button
            Button(action: {
                HapticsManager.shared.trigger(.medium)
                showAddTransfer = true
            }) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .nativeLiquidGlassCircle(isInteractive: true)
                    .shadow(color: Color.black.opacity(0.25), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Plus (+) Add Account Button
            Button(action: {
                HapticsManager.shared.trigger(.medium)
                showAddAccount = true
            }) {
                Image(systemName: SFIcons.plus)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .nativeLiquidGlassCircle(isInteractive: true, tint: SpendyColors.primaryBlue)
                    .shadow(color: SpendyColors.primaryBlue.opacity(0.40), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    // MARK: - Currency Picker Sheet
    private var currencyPickerSheet: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                List {
                    ForEach(supportedCurrencies, id: \.code) { curr in
                        Button(action: {
                            store.updateCurrency(symbol: curr.symbol, code: curr.code)
                            HapticsManager.shared.trigger(.selection)
                            showCurrencyPicker = false
                        }) {
                            HStack {
                                Text("\(curr.symbol)  \(curr.name)")
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(curr.code)
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                    .foregroundStyle(store.currencyCode == curr.code ? SpendyColors.primaryBlue : .white.opacity(0.4))
                                
                                if store.currencyCode == curr.code {
                                    Image(systemName: SFIcons.checkmark)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(SpendyColors.primaryBlue)
                                }
                            }
                        }
                        .listRowBackground(SpendyColors.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showCurrencyPicker = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Edit Account Sheet
    private func editAccountSheet(for acc: Account) -> some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                Form {
                    Section("Account Details") {
                        if acc.id != "cash" {
                            TextField("Account Name", text: $tempAccountName)
                        }
                        
                        TextField("Current Balance (\(store.currencySymbol))", text: $tempAccountBalance)
                            .keyboardType(.decimalPad)
                    }
                    .listRowBackground(SpendyColors.cardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(acc.id == "cash" ? "Edit Cash Balance" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingAccount = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newName = tempAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !newName.isEmpty && acc.id != "cash" {
                            store.updateAccountName(id: acc.id, newName: newName)
                        }
                        if let bal = Double(tempAccountBalance) {
                            store.updateAccountBalance(id: acc.id, newBalance: bal)
                        }
                        editingAccount = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
