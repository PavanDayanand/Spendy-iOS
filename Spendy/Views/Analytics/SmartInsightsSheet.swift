//
//  SmartInsightsSheet.swift
//  Spendy
//
//  Full Detail View for Spending by Category
//  Features:
//  - Top Spent Summary
//  - "Spending by Category" Widget Cards Carousel (Compact CategoryCards)
//  - Classic Category Breakdown List Rows (with Chevron & Tap to Detail)
//

import SwiftUI

struct SmartInsightsSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategoryForSheet: Category? = nil
    var topControlsNamespace: Namespace.ID? = nil
    @Namespace private var fallbackNamespace
    
    // Category Breakdown sorted by total spend descending
    private var categoryTotals: [(category: Category, total: Double, count: Int)] {
        let expenses = store.transactions.filter { $0.type == .expense }
        var map: [String: (total: Double, count: Int)] = [:]
        for tx in expenses {
            let current = map[tx.categoryId, default: (0.0, 0)]
            map[tx.categoryId] = (current.total + tx.amount, current.count + 1)
        }
        
        return map.compactMap { (catId, data) in
            guard let cat = store.categories.first(where: { $0.id == catId }) else { return nil }
            return (cat, data.total, data.count)
        }.sorted(by: { $0.total > $1.total })
    }
    
    private var totalSpentThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        return store.transactions.filter {
            $0.type == .expense &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Top spacing to clear the floating header bar
                        Spacer().frame(height: 52)
                        
                        // 1. Spent Summary Section
                        spentSummarySection
                        
                        // 2. Spending by Category Widget Cards Carousel
                        if !categoryTotals.isEmpty {
                            categoryCardsCarouselSection
                        }
                        
                        // 3. Classic Category List Section
                        categoryListSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
                
                // Floating Sticky Header Bar on Top Layer
                headerBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .zIndex(100)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $selectedCategoryForSheet) { category in
            CategoryAnalyticsSheet(
                category: category,
                topControlsNamespace: topControlsNamespace
            ) {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    selectedCategoryForSheet = nil
                }
            }
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack {
            // Liquid Glass Back Button
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                accessibilityLabel: "Back",
                morphID: "backButton_smartInsights",
                namespace: topControlsNamespace ?? fallbackNamespace
            ) {
                HapticsManager.shared.trigger(.selection)
                dismiss()
            }
            
            Spacer()
            
            Text("Spending by Category")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            // Empty placeholder to balance centered title
            Color.clear
                .frame(width: 44, height: 44)
        }
    }
    
    // MARK: - 1. Spent Summary Section
    private var spentSummarySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Spent in \(currentMonthName)")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
            
            Text(totalSpentThisMonth.formattedCurrency(symbol: store.currencySymbol))
                .spendyNumberFont(size: 38, weight: .heavy, tracking: -1.0)
                .foregroundStyle(SpendyColors.textPrimary)
            
            Text("No data from last period")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(.top, 4)
    }
    
    // MARK: - 2. Spending by Category Widget Cards Carousel
    private var categoryCardsCarouselSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Categories")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categoryTotals, id: \.category.id) { item in
                        CategoryCard(
                            title: item.category.label,
                            value: item.total.formattedCurrency(symbol: store.currencySymbol),
                            subtitle: "\(item.count) \(item.count == 1 ? "expense" : "expenses")",
                            icon: item.category.sfSymbol,
                            color: Color(hex: item.category.colorHex)
                        ) {
                            HapticsManager.shared.trigger(.selection)
                            selectedCategoryForSheet = item.category
                        }
                        .frame(width: 154)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    // MARK: - 3. Classic Category List Section
    private var categoryListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Categories")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            if categoryTotals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(SpendyColors.textTertiary)
                    Text("No category expenses logged")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 10) {
                    ForEach(categoryTotals, id: \.category.id) { item in
                        Button(action: {
                            HapticsManager.shared.trigger(.selection)
                            selectedCategoryForSheet = item.category
                        }) {
                            HStack(spacing: 14) {
                                // Category Icon Avatar
                                SpendyIconBadge(
                                    sfSymbol: item.category.sfSymbol,
                                    color: Color(hex: item.category.colorHex),
                                    size: .medium,
                                    style: .circle
                                )
                                
                                // Title & Expense Count
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.category.label)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                    
                                    Text("\(item.count) \(item.count == 1 ? "expense" : "expenses")")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(SpendyColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                // Category Spend Amount
                                Text(item.total.formattedCurrency(symbol: store.currencySymbol))
                                    .spendyNumberFont(size: 17, weight: .bold, tracking: -0.5)
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
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
}

#Preview {
    SmartInsightsSheet()
        .environment(ExpenseStore())
}
