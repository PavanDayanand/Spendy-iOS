//
//  UpcomingThisMonthCard.swift
//  Spendy
//
//  Subscription reminder card showing upcoming expenses & income for the current month.
//  Collects real subscription icons into overlapping badge clusters.
//

import SwiftUI

// MARK: - Upcoming This Month Card

struct UpcomingThisMonthCard: View {
    @Environment(ExpenseStore.self) private var store
    
    /// Only show this card when there are upcoming subscriptions this month
    var showOnlyWhenRelevant: Bool = true
    
    // MARK: - Computed Data
    
    private var upcomingExpenseSubs: [Subscription] {
        let calendar = Calendar.current
        let now = Date()
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1),
            to: calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now)
        else { return [] }
        
        return store.subscriptions.filter { sub in
            !sub.isPaused &&
            !sub.isCancelled &&
            sub.nextBillingDate >= calendar.startOfDay(for: now) &&
            sub.nextBillingDate <= endOfMonth
        }.sorted { $0.nextBillingDate < $1.nextBillingDate }
    }
    
    private var upcomingExpenseTotal: Double {
        upcomingExpenseSubs.reduce(0) { $0 + $1.amount }
    }
    
    private var currentMonthIncomeTxs: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        return store.transactions.filter {
            $0.type == .income &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
    }
    
    private var incomeTotal: Double {
        currentMonthIncomeTxs.reduce(0) { $0 + $1.amount }
    }
    
    /// Unique income category icons for the badge cluster
    private var incomeIconInfos: [(icon: String, color: Color)] {
        var seen = Set<String>()
        var results: [(icon: String, color: Color)] = []
        for tx in currentMonthIncomeTxs {
            guard !seen.contains(tx.categoryId) else { continue }
            seen.insert(tx.categoryId)
            let cat = store.categories.first(where: { $0.id == tx.categoryId })
            let icon = cat?.sfSymbol ?? "dollarsign.circle.fill"
            let color = Color(hex: cat?.colorHex ?? "#30D158")
            results.append((icon, color))
            if results.count >= 3 { break }
        }
        return results
    }
    
    private var shouldShow: Bool {
        if !showOnlyWhenRelevant { return true }
        return !upcomingExpenseSubs.isEmpty || !currentMonthIncomeTxs.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        if shouldShow {
            VStack(alignment: .leading, spacing: 14) {
                // Card Title
                Text("Upcoming this month")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                // Two Sub-Cards Side by Side
                HStack(spacing: 10) {
                    // Expenses Sub-Card
                    expensesSubCard
                    
                    // Income Sub-Card
                    incomeSubCard
                }
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - Expenses Sub-Card
    
    private var expensesSubCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Overlapping Subscription Icon Badges
            if !upcomingExpenseSubs.isEmpty {
                OverlappingBadgeCluster(
                    items: upcomingExpenseSubs.prefix(4).map { sub in
                        BadgeItem(icon: sub.sfSymbol, color: sub.color)
                    }
                )
            } else {
                // Empty state placeholder
                ZStack {
                    Circle()
                        .fill(SpendyColors.cardBackgroundSecondary)
                        .frame(width: 32, height: 32)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            
            Text("Expenses")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(upcomingExpenseTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text("\(upcomingExpenseSubs.count) \(upcomingExpenseSubs.count == 1 ? "transaction" : "transactions")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackgroundSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.6)
                }
        }
    }
    
    // MARK: - Income Sub-Card
    
    private var incomeSubCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Overlapping Income Category Icon Badges
            if !incomeIconInfos.isEmpty {
                OverlappingBadgeCluster(
                    items: incomeIconInfos.map { info in
                        BadgeItem(icon: info.icon, color: info.color)
                    }
                )
            } else {
                // Empty state placeholder
                ZStack {
                    Circle()
                        .fill(SpendyColors.cardBackgroundSecondary)
                        .frame(width: 32, height: 32)
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            
            Text("Income")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("+\(incomeTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Color(hex: "#30D158"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text("\(currentMonthIncomeTxs.count) \(currentMonthIncomeTxs.count == 1 ? "transaction" : "transactions")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackgroundSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.6)
                }
        }
    }
}

// MARK: - Badge Item Model

struct BadgeItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
}

// MARK: - Overlapping Badge Cluster

/// Renders circular icon badges in a compact triangle cluster, matching the reference design.
// MARK: - Overlapping Badge Cluster

/// Renders circular icon badges in a compact cluster pattern, matching the reference design.
struct OverlappingBadgeCluster: View {
    let items: [BadgeItem]
    var badgeSize: CGFloat = 34
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                singleBadge(item)
                    .offset(x: offsetX(for: index), y: offsetY(for: index))
                    .zIndex(Double(items.count - index))
            }
        }
        .frame(
            width: clusterWidth,
            height: clusterHeight,
            alignment: .topLeading
        )
    }
    
    private func singleBadge(_ item: BadgeItem) -> some View {
        SpendyIconBadge(
            sfSymbol: item.icon,
            color: item.color,
            size: .small,
            style: .circle
        )
    }
    
    // MARK: - Cluster Position Logic
    
    private func offsetX(for index: Int) -> CGFloat {
        switch index {
        case 0: return 0                        // top-left
        case 1: return badgeSize * 0.65         // top-right, overlapping
        case 2: return badgeSize * 0.2          // bottom-left, offset slightly
        case 3: return badgeSize * 0.85         // bottom-right
        case 4: return badgeSize * 0.5          // center-bottom peek
        default: return 0
        }
    }
    
    private func offsetY(for index: Int) -> CGFloat {
        switch index {
        case 0: return 0                        // top row
        case 1: return 0                        // top row
        case 2: return badgeSize * 0.6          // bottom row
        case 3: return badgeSize * 0.6          // bottom row
        case 4: return badgeSize * 0.8          // extra bottom peek
        default: return 0
        }
    }
    
    private var clusterWidth: CGFloat {
        switch items.count {
        case 0: return 0
        case 1: return badgeSize
        case 2: return badgeSize * 1.65
        case 3: return badgeSize * 1.65
        case 4: return badgeSize * 1.85
        default: return badgeSize * 1.85
        }
    }
    
    private var clusterHeight: CGFloat {
        if items.count <= 2 { return badgeSize }
        if items.count <= 4 { return badgeSize * 1.6 }
        return badgeSize * 1.8
    }
}

// MARK: - Animated Badge Cluster (Controlled In-Bounds Layout)

struct AnimatedBadgeCluster: View {
    let items: [BadgeItem]
    var badgeSize: CGFloat = 28
    
    var body: some View {
        OverlappingBadgeCluster(items: items, badgeSize: badgeSize)
    }
}
