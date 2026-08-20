//
//  InsightsEngine.swift
//  Spendy
//
//  Intelligent spending analytics and behavioral insights engine
//

import SwiftUI

struct InsightItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let sfSymbol: String
    let tintColor: Color
    let score: Int // Priority score for sorting
}

struct InsightsEngine {
    static func generateInsights(
        transactions: [Transaction],
        categories: [Category],
        budget: Budget,
        currencySymbol: String
    ) -> [InsightItem] {
        var insights: [InsightItem] = []
        let calendar = Calendar.current
        let now = Date()
        
        let monthTxs = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month) &&
            calendar.isDate($0.date, equalTo: now, toGranularity: .year)
        }
        let expenseTxs = monthTxs.filter { $0.type == .expense }
        let totalExpense = expenseTxs.reduce(0.0) { $0 + $1.amount }
        
        // 1. Empty / Beginner Insight
        if expenseTxs.isEmpty {
            insights.append(
                InsightItem(
                    title: "Ready to Track",
                    description: "Add your first expense to unlock smart spending velocity & category trends.",
                    sfSymbol: "sparkles",
                    tintColor: SpendyColors.primaryBlue,
                    score: 100
                )
            )
            return insights
        }
        
        // 2. Budget Pacing Insight
        if budget.monthlyBudget > 0 {
            let limit = budget.monthlyBudget
            let percentSpent = (totalExpense / limit) * 100
            let day = calendar.component(.day, from: now)
            let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
            let expectedPace = (Double(day) / Double(daysInMonth)) * 100
            let remaining = max(0, limit - totalExpense)
            
            if percentSpent > 100 {
                insights.append(
                    InsightItem(
                        title: "Budget Exceeded",
                        description: "You've exceeded your \(currencySymbol)\(Int(limit)) monthly budget by \(currencySymbol)\(Int(totalExpense - limit)).",
                        sfSymbol: "exclamationmark.triangle.fill",
                        tintColor: SpendyColors.expenseRed,
                        score: 95
                    )
                )
            } else if percentSpent > expectedPace + 15 {
                insights.append(
                    InsightItem(
                        title: "Fast Pacing",
                        description: "You've spent \(Int(percentSpent))% of your budget on day \(day) of \(daysInMonth). Slow down to stay within \(currencySymbol)\(Int(limit)).",
                        sfSymbol: "speedometer",
                        tintColor: SpendyColors.warningOrange,
                        score: 90
                    )
                )
            } else {
                insights.append(
                    InsightItem(
                        title: "Budget on Track",
                        description: "You're pacing well! \(currencySymbol)\(Int(remaining)) safe to spend for the next \(daysInMonth - day) days.",
                        sfSymbol: "checkmark.shield.fill",
                        tintColor: SpendyColors.incomeGreen,
                        score: 85
                    )
                )
            }
        }
        
        // 3. Top Category Insight
        var catSpend: [String: Double] = [:]
        for t in expenseTxs {
            catSpend[t.categoryId, default: 0] += t.amount
        }
        if let topCatId = catSpend.max(by: { $0.value < $1.value }), totalExpense > 0 {
            let catObj = categories.first(where: { $0.id == topCatId.key })
            let catName = catObj?.label ?? "Everyday"
            let pct = Int((topCatId.value / totalExpense) * 100)
            
            insights.append(
                InsightItem(
                    title: "Top Category: \(catName)",
                    description: "\(catName) accounts for \(pct)% (\(currencySymbol)\(Int(topCatId.value))) of this month's spending.",
                    sfSymbol: catObj?.sfSymbol ?? "chart.pie.fill",
                    tintColor: catObj?.color ?? SpendyColors.primaryBlue,
                    score: 80
                )
            )
        }
        
        // 4. Largest Transaction
        if let largest = expenseTxs.max(by: { $0.amount < $1.amount }), largest.amount > 0 {
            let catObj = categories.first(where: { $0.id == largest.categoryId })
            insights.append(
                InsightItem(
                    title: "Largest Expense",
                    description: "\(largest.title.isEmpty ? (catObj?.label ?? "Expense") : largest.title) was \(currencySymbol)\(Int(largest.amount)).",
                    sfSymbol: "arrow.up.right.circle.fill",
                    tintColor: SpendyColors.expenseRed,
                    score: 70
                )
            )
        }
        
        // 5. Weekend vs Weekday Habit
        var weekendTotal = 0.0
        var weekdayTotal = 0.0
        var weekendCount = 0
        var weekdayCount = 0
        
        for t in expenseTxs {
            let weekday = calendar.component(.weekday, from: t.date)
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                weekendTotal += t.amount
                weekendCount += 1
            } else {
                weekdayTotal += t.amount
                weekdayCount += 1
            }
        }
        
        if weekendCount >= 2 && weekdayCount >= 2 {
            let weekendAvg = weekendTotal / Double(weekendCount)
            let weekdayAvg = weekdayTotal / Double(weekdayCount)
            if weekendAvg > weekdayAvg * 1.4 {
                let ratio = Int((weekendAvg / max(weekdayAvg, 1)) * 100) - 100
                insights.append(
                    InsightItem(
                        title: "Weekend Spending Peak",
                        description: "You spend ~\(ratio)% more per transaction on weekends compared to weekdays.",
                        sfSymbol: "calendar.badge.clock",
                        tintColor: SpendyColors.warningOrange,
                        score: 60
                    )
                )
            }
        }
        
        return insights.sorted(by: { $0.score > $1.score })
    }
}
