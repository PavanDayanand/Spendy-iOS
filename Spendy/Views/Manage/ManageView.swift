//
//  ManageView.swift
//  Spendy
//
//  Manage Hub for Accounts, Categories, and Subscriptions with Pure SF Symbols
//

import SwiftUI

enum ManageSection: String, CaseIterable, Identifiable {
    case accounts
    case categories
    case subscriptions
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .accounts: return "Accounts"
        case .categories: return "Categories"
        case .subscriptions: return "Subscriptions"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .accounts: return SFIcons.bankAccount
        case .categories: return SFIcons.categoriesFolder
        case .subscriptions: return SFIcons.subscriptionsFolder
        }
    }
}

struct ManageView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var selectedSection: ManageSection = .accounts
    
    // Sheets
    @State private var showAddAccount: Bool = false
    @State private var showAddCategory: Bool = false
    @State private var showAddSubscription: Bool = false
    
    // Category Sub-filter (Expense vs Income)
    @State private var categoryTypeFilter: TransactionType = .expense
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Top Header
                        HStack {
                            Text("Manage")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        // Native Segmented Control
                        Picker("Section", selection: $selectedSection) {
                            ForEach(ManageSection.allCases) { section in
                                Text(section.title).tag(section)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedSection) { _, _ in
                            HapticsManager.shared.trigger(.selection)
                        }
                        
                        // Section Content
                        switch selectedSection {
                        case .accounts:
                            accountsSection
                        case .categories:
                            categoriesSection
                        case .subscriptions:
                            subscriptionsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddAccount) {
                AddAccountSheet()
            }
            .sheet(isPresented: $showAddCategory) {
                AddCategorySheet(defaultType: categoryTypeFilter)
            }
            .sheet(isPresented: $showAddSubscription) {
                AddSubscriptionSheet()
            }
        }
    }
    
    // MARK: - Accounts Section
    private var accountsSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("ALL ACCOUNTS (\(store.accounts.count))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.45))
                
                Spacer()
                
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showAddAccount = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: SFIcons.quickAdd)
                            .font(.system(size: 11, weight: .bold))
                        Text("Add Account")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(SpendyColors.primaryBlue)
                }
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                ForEach(store.accounts) { acc in
                    let balance = store.balance(for: acc.id)
                    HStack(spacing: 14) {
                        CategoryIconBadge(
                            sfSymbol: acc.sfSymbol,
                            tintColor: acc.color,
                            size: .medium
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(acc.label)
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text("Opening: \(acc.openingBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        
                        Spacer()
                        
                        Text(balance.formattedCurrency(symbol: store.currencySymbol))
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(SpendyColors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            }
                    }
                    .contextMenu {
                        if store.accounts.count > 1 {
                            Button(role: .destructive) {
                                store.deleteAccount(id: acc.id)
                            } label: {
                                Label("Delete Account", systemImage: SFIcons.delete)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Categories Section
    private var categoriesSection: some View {
        VStack(spacing: 14) {
            HStack {
                Picker("Category Type", selection: $categoryTypeFilter) {
                    Text("Expense").tag(TransactionType.expense)
                    Text("Income").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
                
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showAddCategory = true
                }) {
                    Image(systemName: SFIcons.quickAdd)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(SpendyColors.primaryBlue, in: Circle())
                }
                .padding(.leading, 6)
            }
            
            let filtered = store.categories.filter { $0.type == categoryTypeFilter }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(filtered) { cat in
                    HStack(spacing: 10) {
                        CategoryIconBadge(
                            sfSymbol: cat.sfSymbol,
                            tintColor: cat.color,
                            size: .small
                        )
                        
                        Text(cat.label)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(SpendyColors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            store.deleteCategory(id: cat.id)
                        } label: {
                            Label("Delete", systemImage: SFIcons.delete)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subscriptions Section
    private var subscriptionsSection: some View {
        VStack(spacing: 14) {
            let activeSubs = store.subscriptions.filter { !$0.isPaused }
            let totalMonthly = activeSubs.reduce(0.0) { sum, sub in
                switch sub.cycle {
                case .monthly: return sum + sub.amount
                case .yearly: return sum + (sub.amount / 12)
                case .weekly: return sum + (sub.amount * 4.33)
                }
            }
            
            // Monthly Summary Glass Card
            GlassCard(cornerRadius: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TOTAL RECURRING")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(.white.opacity(0.45))
                        
                        Text(totalMonthly.formattedCurrency(symbol: store.currencySymbol) + "/mo")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        showAddSubscription = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: SFIcons.quickAdd)
                                .font(.system(size: 11, weight: .bold))
                            Text("Add")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(SpendyColors.primaryBlue, in: Capsule())
                    }
                }
            }
            
            VStack(spacing: 10) {
                ForEach(store.subscriptions) { sub in
                    HStack(spacing: 14) {
                        CategoryIconBadge(
                            sfSymbol: sub.sfSymbol,
                            tintColor: sub.color,
                            size: .medium
                        )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sub.name)
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(sub.isPaused ? .white.opacity(0.4) : .white)
                            
                            Text("\(sub.cycle.label) • Next: \(sub.nextBillingDate.formattedRelative)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                                .font(.system(.body, design: .rounded, weight: .bold))
                                .foregroundStyle(sub.isPaused ? .white.opacity(0.4) : .white)
                            
                            Button(action: {
                                store.toggleSubscriptionPause(id: sub.id)
                            }) {
                                Text(sub.isPaused ? "Paused" : "Active")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(sub.isPaused ? .white.opacity(0.4) : SpendyColors.incomeGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background {
                                        Capsule()
                                            .fill(sub.isPaused ? Color.white.opacity(0.06) : SpendyColors.incomeGreen.opacity(0.12))
                                    }
                            }
                        }
                    }
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(SpendyColors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            store.deleteSubscription(id: sub.id)
                        } label: {
                            Label("Delete", systemImage: SFIcons.delete)
                        }
                    }
                }
            }
        }
    }
}
