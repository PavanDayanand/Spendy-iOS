//
//  InsightFactsExtractor.swift
//  Spendy
//
//  Single canonical source of truth for extracting immutable mathematical facts from raw data.
//

import Foundation

enum InsightFactsExtractor {
    
    /// Extract facts for the active financial period (defaulting to current calendar month vs previous calendar month)
    static func extractFacts(
        transactions: [Transaction],
        budget: Budget,
        categories: [Category],
        subscriptions: [Subscription],
        now: Date = Date(),
        calendar: Calendar = Calendar.current
    ) -> InsightFacts {
        let periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let periodEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: periodStart) ?? now
        
        let baselineStart = calendar.date(byAdding: .month, value: -1, to: periodStart) ?? now
        let baselineEnd = calendar.date(byAdding: .day, value: -1, to: periodStart) ?? now
        
        return extractFacts(
            transactions: transactions,
            budget: budget,
            categories: categories,
            subscriptions: subscriptions,
            periodStart: periodStart,
            periodEnd: periodEnd,
            baselineStart: baselineStart,
            baselineEnd: baselineEnd,
            now: now,
            calendar: calendar
        )
    }
    
    /// Extract facts for explicit custom period bounds
    static func extractFacts(
        transactions: [Transaction],
        budget: Budget,
        categories: [Category],
        subscriptions: [Subscription],
        periodStart: Date,
        periodEnd: Date,
        baselineStart: Date,
        baselineEnd: Date,
        now: Date = Date(),
        calendar: Calendar = Calendar.current
    ) -> InsightFacts {
        let currentDayStart = calendar.startOfDay(for: now)
        
        let currentExpenseTxs = transactions.filter {
            $0.type == .expense && $0.date >= periodStart && $0.date <= periodEnd
        }
        
        let baselineExpenseTxs = transactions.filter {
            $0.type == .expense && $0.date >= baselineStart && $0.date <= baselineEnd
        }
        
        let currentIncomeTxs = transactions.filter {
            $0.type == .income && $0.date >= periodStart && $0.date <= periodEnd
        }
        
        let baselineIncomeTxs = transactions.filter {
            $0.type == .income && $0.date >= baselineStart && $0.date <= baselineEnd
        }
        
        // 1. Temporal Math
        let totalDaysInCycle = max(1, (calendar.dateComponents([.day], from: periodStart, to: periodEnd).day ?? 29) + 1)
        let elapsedDaysRaw = (calendar.dateComponents([.day], from: periodStart, to: now).day ?? 0) + 1
        let elapsedDays = max(1, min(totalDaysInCycle, elapsedDaysRaw))
        let remainingDays = max(0, totalDaysInCycle - elapsedDays)
        let isEarlyPeriod = elapsedDays < 3
        
        // 2. Spend Totals & Velocity
        let currentSpendTotal = currentExpenseTxs.reduce(0.0) { $0 + $1.amount }
        let baselineSpendTotal = baselineExpenseTxs.reduce(0.0) { $0 + $1.amount }
        let dailyRunRate = currentSpendTotal / Double(elapsedDays)
        let projectedPeriodSpend = dailyRunRate * Double(totalDaysInCycle)
        let spendDeltaPercent: Double = baselineSpendTotal > 0
            ? ((currentSpendTotal - baselineSpendTotal) / baselineSpendTotal) * 100.0
            : 0.0
        
        // 3. Category Summaries & Driver
        var currentCatTotals: [String: Double] = [:]
        var currentCatCounts: [String: Int] = [:]
        for tx in currentExpenseTxs {
            currentCatTotals[tx.categoryId, default: 0.0] += tx.amount
            currentCatCounts[tx.categoryId, default: 0] += 1
        }
        
        var baselineCatTotals: [String: Double] = [:]
        for tx in baselineExpenseTxs {
            baselineCatTotals[tx.categoryId, default: 0.0] += tx.amount
        }
        
        var summaries: [String: CategoryFactSummary] = [:]
        var primaryDriverCandidate: CategoryFactSummary? = nil
        var maxIncreaseAmount = 0.0
        
        for category in categories.filter({ $0.type == .expense }) {
            let catId = category.id
            let curSpend = currentCatTotals[catId] ?? 0.0
            let baseSpend = baselineCatTotals[catId] ?? 0.0
            let txCount = currentCatCounts[catId] ?? 0
            let mean = txCount > 0 ? (curSpend / Double(txCount)) : 0.0
            let curShare = currentSpendTotal > 0 ? ((curSpend / currentSpendTotal) * 100.0) : 0.0
            let baseShare = baselineSpendTotal > 0 ? ((baseSpend / baselineSpendTotal) * 100.0) : 0.0
            let delta = curSpend - baseSpend
            let deltaPct: Double = baseSpend > 0 ? ((delta / baseSpend) * 100.0) : 0.0
            
            let summary = CategoryFactSummary(
                categoryId: catId,
                categoryName: category.label,
                currentSpend: curSpend,
                baselineSpend: baseSpend,
                txCount: txCount,
                meanTxAmount: mean,
                currentSharePercent: curShare,
                baselineSharePercent: baseShare,
                deltaSpend: delta,
                deltaPercent: deltaPct
            )
            summaries[catId] = summary
            
            if delta > maxIncreaseAmount && delta >= 100.0 {
                maxIncreaseAmount = delta
                primaryDriverCandidate = summary
            }
        }
        
        let topCategory = summaries.values
            .filter { $0.currentSpend > 0 }
            .max(by: { $0.currentSpend < $1.currentSpend })
        
        // 4. Budget & Pacing Math
        let hasActiveBudget = budget.isActive && budget.amount > 0
        let budgetLimit = budget.period == .weekly ? (budget.amount * 4.3333) : budget.amount
        let budgetCycleExpenses = currentSpendTotal
        let budgetPercentSpent = budgetLimit > 0 ? ((budgetCycleExpenses / budgetLimit) * 100.0) : 0.0
        let budgetSafePacePercent = (Double(elapsedDays) / Double(totalDaysInCycle)) * 100.0
        let budgetOverPacePercent = budgetPercentSpent - budgetSafePacePercent
        
        var daysToExhaustion: Int? = nil
        var exhaustionDate: Date? = nil
        if hasActiveBudget && dailyRunRate > 0 {
            let daysDouble = budgetLimit / dailyRunRate
            let safeDays = min(365, max(1, Int(daysDouble)))
            daysToExhaustion = safeDays
            if safeDays <= totalDaysInCycle {
                exhaustionDate = calendar.date(byAdding: .day, value: safeDays, to: periodStart)
            }
        }
        let budgetSafeDailyRemaining = remainingDays > 0 ? max(0.0, (budgetLimit - budgetCycleExpenses) / Double(remainingDays)) : 0.0
        
        // 5. Habits & Weekend / Weekday Distribution
        var weekendTotal = 0.0
        var weekdayTotal = 0.0
        var weekendCount = 0
        var weekdayCount = 0
        
        for tx in currentExpenseTxs {
            let weekday = calendar.component(.weekday, from: tx.date) // 1 = Sunday, 7 = Saturday
            if weekday == 1 || weekday == 7 {
                weekendTotal += tx.amount
                weekendCount += 1
            } else {
                weekdayTotal += tx.amount
                weekdayCount += 1
            }
        }
        
        let wAvg = weekendCount > 0 ? (weekendTotal / Double(weekendCount)) : 0.0
        let dAvg = weekdayCount > 0 ? (weekdayTotal / Double(weekdayCount)) : 0.0
        let weekendToWeekdayRatio = dAvg > 0 ? (wAvg / dAvg) : 1.0
        let weekendSpendShare = currentSpendTotal > 0 ? ((weekendTotal / currentSpendTotal) * 100.0) : 0.0
        
        // Zero-Spend Days & Streaks
        var txDays = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for tx in currentExpenseTxs {
            txDays.insert(formatter.string(from: tx.date))
        }
        
        var maxStreak = 0
        var currentStreak = 0
        for i in 0..<elapsedDays {
            if let d = calendar.date(byAdding: .day, value: i, to: periodStart) {
                let dStr = formatter.string(from: d)
                if !txDays.contains(dStr) {
                    currentStreak += 1
                    maxStreak = max(maxStreak, currentStreak)
                } else {
                    currentStreak = 0
                }
            }
        }
        
        // Rolling 7-day Zero Days
        var zeroDaysPastWeek = 0
        if let weekStart = calendar.date(byAdding: .day, value: -6, to: currentDayStart) {
            let weekTxDays = Set(currentExpenseTxs.filter { $0.date >= weekStart }.map { calendar.startOfDay(for: $0.date) })
            zeroDaysPastWeek = max(0, 7 - weekTxDays.count)
        }
        
        // 6. Subscriptions
        let activeSubs = subscriptions.filter { !$0.isCancelled && !$0.isPaused }
        let totalMonthlyCommitted = activeSubs.reduce(0.0) { sum, sub in
            switch sub.cycle {
            case .monthly: return sum + sub.amount
            case .yearly:  return sum + (sub.amount / 12.0)
            case .weekly:  return sum + (sub.amount * 4.3333)
            }
        }
        let subIds = Set(subscriptions.map { $0.id.uuidString.lowercased() })
        let subExpenses = currentExpenseTxs.filter { tx in
            guard let subId = tx.subscriptionId?.lowercased() else { return false }
            return subIds.contains(subId)
        }
        
        // 7. Income Totals
        let currentIncomeTotal = currentIncomeTxs.reduce(0.0) { $0 + $1.amount }
        let baselineIncomeTotal = baselineIncomeTxs.reduce(0.0) { $0 + $1.amount }
        let activeIncomeCategories = Set(currentIncomeTxs.map { $0.categoryId }).count
        
        // 8. Data Density & Sufficiency Gates
        let totalTxCount = currentExpenseTxs.count
        let dataDensityScore = min(1.0, Double(totalTxCount) / 8.0)
        let hasSufficientGeneralData = totalTxCount >= 4
        
        return InsightFacts(
            periodStart: periodStart,
            periodEnd: periodEnd,
            baselineStart: baselineStart,
            baselineEnd: baselineEnd,
            elapsedDays: elapsedDays,
            remainingDays: remainingDays,
            totalDaysInCycle: totalDaysInCycle,
            isEarlyPeriod: isEarlyPeriod,
            currentSpendTotal: currentSpendTotal,
            baselineSpendTotal: baselineSpendTotal,
            totalExpenseTxCount: totalTxCount,
            dailyRunRate: dailyRunRate,
            projectedPeriodSpend: projectedPeriodSpend,
            spendDeltaPercent: spendDeltaPercent,
            primarySpendingDriver: primaryDriverCandidate,
            hasActiveBudget: hasActiveBudget,
            budgetLimit: budgetLimit,
            budgetPeriodType: budget.period,
            budgetCycleExpenses: budgetCycleExpenses,
            budgetPercentSpent: budgetPercentSpent,
            budgetSafePacePercent: budgetSafePacePercent,
            budgetOverPacePercent: budgetOverPacePercent,
            budgetDaysToExhaustion: daysToExhaustion,
            budgetExhaustionDate: exhaustionDate,
            budgetSafeDailyRemaining: budgetSafeDailyRemaining,
            categorySummaries: summaries,
            topSpendingCategory: topCategory,
            weekendSpendTotal: weekendTotal,
            weekdaySpendTotal: weekdayTotal,
            weekendCount: weekendCount,
            weekdayCount: weekdayCount,
            weekendToWeekdayRatio: weekendToWeekdayRatio,
            weekendSpendSharePercent: weekendSpendShare,
            zeroSpendStreakDays: maxStreak,
            zeroSpendDaysInPastWeek: zeroDaysPastWeek,
            activeSubscriptions: activeSubs,
            totalMonthlySubscriptionCommitted: totalMonthlyCommitted,
            subscriptionExpensesInPeriod: subExpenses,
            currentIncomeTotal: currentIncomeTotal,
            baselineIncomeTotal: baselineIncomeTotal,
            incomeSourceCount: activeIncomeCategories,
            dataDensityScore: dataDensityScore,
            hasSufficientGeneralData: hasSufficientGeneralData,
            transactions: currentExpenseTxs,
            categories: categories
        )
    }
}
