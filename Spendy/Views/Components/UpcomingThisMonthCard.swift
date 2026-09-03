//
//  UpcomingThisMonthCard.swift
//  Spendy
//
//  Minimal, Authentic Apple HIG Upcoming Subscriptions & Bills Card.
//  Presents real upcoming commitments with clean typography, due dates,
//  and compact layout with zero clutter.
//

import SwiftUI

struct UpcomingThisMonthCard: View {
    @Environment(ExpenseStore.self) private var store
    
    /// Only show this card when there are upcoming subscriptions this month
    var showOnlyWhenRelevant: Bool = true
    var onOpenSubscriptions: (() -> Void)? = nil
    
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
    
    private var shouldShow: Bool {
        if !showOnlyWhenRelevant { return true }
        return !upcomingExpenseSubs.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        if shouldShow {
            VStack(alignment: .leading, spacing: 10) {
                // MARK: - Section Header
                HStack(alignment: .center) {
                    Text("Upcoming")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    if !upcomingExpenseSubs.isEmpty {
                        HStack(spacing: 4) {
                            Text(upcomingExpenseTotal.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                .spendyNumberFont(size: 13, weight: .bold, tracking: -0.3)
                            
                            Text("due")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(SpendyColors.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background {
                            Capsule(style: .continuous)
                                .fill(SpendyColors.cardBackgroundSecondary)
                        }
                    }
                }
                
                // MARK: - Grouped Card Container
                VStack(spacing: 0) {
                    if upcomingExpenseSubs.isEmpty {
                        emptyUpcomingView
                    } else {
                        ForEach(Array(upcomingExpenseSubs.prefix(3).enumerated()), id: \.element.id) { index, sub in
                            subscriptionUpcomingRow(sub: sub)
                            
                            if index < min(upcomingExpenseSubs.count, 3) - 1 {
                                Rectangle()
                                    .fill(SpendyColors.separator.opacity(0.5))
                                    .frame(height: 0.5)
                                    .padding(.leading, 56)
                                    .padding(.trailing, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            }
        }
    }
    
    // MARK: - Subscription Upcoming Row
    private func subscriptionUpcomingRow(sub: Subscription) -> some View {
        let calendar = Calendar.current
        let startToday = calendar.startOfDay(for: Date())
        let startBilling = calendar.startOfDay(for: sub.nextBillingDate)
        let daysRemaining = calendar.dateComponents([.day], from: startToday, to: startBilling).day ?? 0
        
        let dueText: String = {
            if daysRemaining == 0 { return "Due today" }
            if daysRemaining == 1 { return "Due tomorrow" }
            return "Due in \(daysRemaining) days"
        }()
        
        return HStack(spacing: 12) {
            // Subscription Icon Badge with Timing Progress Ring
            SubscriptionProgressRingBadge(
                subscription: sub,
                size: .small
            )
            
            // Name & Due Date
            VStack(alignment: .leading, spacing: 2) {
                Text(sub.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                
                Text(dueText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(daysRemaining <= 2 ? SpendyColors.expenseRed : SpendyColors.textSecondary)
            }
            
            Spacer()
            
            // Amount
            Text(sub.amount.formattedCurrency(symbol: store.currencySymbol))
                .spendyNumberFont(size: 15, weight: .bold, tracking: -0.3)
                .foregroundStyle(SpendyColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }
    
    // MARK: - Empty State Placeholder
    private var emptyUpcomingView: some View {
        SpendyEmptyCardView(
            icon: "repeat.circle",
            iconColor: SpendyColors.vibrantPurple,
            title: "No upcoming bills due",
            subtitle: "All recurring subscriptions for this month are up to date",
            actionTitle: nil,
            isEnclosedInCard: false
        )
    }
}
