//
//  InsightFactsExtractor.swift
//  Spendy
//
//  Single canonical source of truth for extracting immutable mathematical facts from raw data
//  driven by the exact AnalyticsInsightContext (dates, scope, and comparison boundaries).
//

import Foundation

enum InsightFactsExtractor {
    
    /// Canonical context-driven fact extractor
    static func extractFacts(
        transactions: [Transaction],
        budget: Budget,
        categories: [Category],
        subscriptions: [Subscription],
        context: AnalyticsInsightContext,
        calendar: Calendar = Calendar.current
    ) -> InsightFacts {
        let now = context.referenceDate
        
        // 0. Filter transactions by analytical scope (Global, Category-specific, Account-specific)
        let scopedTransactions: [Transaction] = {
            switch context.scope {
            case .global:
                return transactions
            case .category(let catId):
                return transactions.filter { $0.categoryId == catId }
            case .account(let accId):
                return transactions.filter { $0.accountId == accId }
            }
        }()
        
        // Filter by exact date boundaries
        let currentExpenseTxs = scopedTransactions.filter {
            $0.type == .expense && $0.date >= context.startDate && $0.date <= min(context.endDate, now)
        }
        
        let baselineExpenseTxs = scopedTransactions.filter {
            $0.type == .expense && $0.date >= context.baselineStartDate && $0.date <= context.baselineEndDate
        }
        
        let currentIncomeTxs = scopedTransactions.filter {
            $0.type == .income && $0.date >= context.startDate && $0.date <= min(context.endDate, now)
        }
        
        let baselineIncomeTxs = scopedTransactions.filter {
            $0.type == .income && $0.date >= context.baselineStartDate && $0.date <= context.baselineEndDate
        }
        
        // 1. Temporal Math & Sufficiency
        let totalDaysInCycle = max(1, (calendar.dateComponents([.day],
            from: calendar.startOfDay(for: context.startDate), to: calendar.startOfDay(for: context.endDate)).day ?? 0) + 1)
        let elapsedDays: Int = {
            if context.isHistorical {
                return totalDaysInCycle
            } else if context.isPeriodInProgress {
                let elapsedRaw = (calendar.dateComponents([.day], from: context.startDate, to: now).day ?? 0) + 1
                return max(1, min(totalDaysInCycle, elapsedRaw))
            } else {
                return 1
            }
        }()
        let remainingDays = context.isPeriodInProgress ? max(1, totalDaysInCycle - elapsedDays + 1) : 0
        let isEarlyPeriod = elapsedDays < 3 && context.period != .week && !context.isHistorical
        let isPeriodInProgress = context.isPeriodInProgress
        
        let periodPhrase = context.isCustomRange ? "over this period" : context.period.currentPeriodPhrase
        let baselinePeriodPhrase = context.isCustomRange ? "previous period" : context.period.baselinePeriodPhrase
        let periodTitle = context.isCustomRange ? (context.customRangeLabel ?? "Custom Period") : context.period.title
        
        // Count represented days, weeks, months with activity
        let representedDaysSet = Set(currentExpenseTxs.map { calendar.startOfDay(for: $0.date) })
        let representedDaysCount = representedDaysSet.count
        let representedWeeksCount = max(1, (calendar.dateComponents([.weekOfYear], from: context.startDate, to: min(now, context.endDate)).weekOfYear ?? 0) + 1)
        let representedMonthsCount = max(1, (calendar.dateComponents([.month], from: context.startDate, to: min(now, context.endDate)).month ?? 0) + 1)
        let hasBaselineHistory = !baselineExpenseTxs.isEmpty
        
        // 2. Spend Totals & Velocity
        let currentSpendTotal = currentExpenseTxs.reduce(0.0) { $0 + $1.amount }
        let baselineSpendTotal = baselineExpenseTxs.reduce(0.0) { $0 + $1.amount }
        let dailyRunRate = currentSpendTotal / Double(elapsedDays)
        let projectedPeriodSpend = isPeriodInProgress ? (dailyRunRate * Double(totalDaysInCycle)) : currentSpendTotal
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
        for cat in categories {
            let cur = currentCatTotals[cat.id] ?? 0.0
            let base = baselineCatTotals[cat.id] ?? 0.0
            let count = currentCatCounts[cat.id] ?? 0
            let mean = count > 0 ? (cur / Double(count)) : 0.0
            let curShare = currentSpendTotal > 0 ? (cur / currentSpendTotal) * 100.0 : 0.0
            let baseShare = baselineSpendTotal > 0 ? (base / baselineSpendTotal) * 100.0 : 0.0
            let deltaSpend = cur - base
            let deltaPct = base > 0 ? ((cur - base) / base) * 100.0 : 0.0
            
            summaries[cat.id] = CategoryFactSummary(
                categoryId: cat.id,
                categoryName: cat.label,
                currentSpend: cur,
                baselineSpend: base,
                txCount: count,
                meanTxAmount: mean,
                currentSharePercent: curShare,
                baselineSharePercent: baseShare,
                deltaSpend: deltaSpend,
                deltaPercent: deltaPct
            )
        }
        
        let topCategory = summaries.values.max { $0.currentSpend < $1.currentSpend }
        
        // Primary spending driver (largest absolute contributor to current spend increase)
        let driver = summaries.values
            .filter { $0.deltaSpend > 0 && $0.currentSpend > 0 }
            .max { $0.deltaSpend < $1.deltaSpend }
        
        // 4. Budget & Pacing Math (Only if global scope and budget is active)
        let expectedBudgetStart: Date = {
            let today = calendar.startOfDay(for: now)
            if budget.period == .weekly {
                let diff = (calendar.component(.weekday, from: now) - budget.startDay + 7) % 7
                return calendar.date(byAdding: .day, value: -diff, to: today) ?? today
            }
            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = min(28, max(1, budget.startDay))
            let candidate = calendar.date(from: components) ?? today
            return candidate <= now ? candidate : (calendar.date(byAdding: .month, value: -1, to: candidate) ?? candidate)
        }()
        let hasActiveBudget = budget.isActive && budget.amount > 0 && context.scope == .global
            && context.isPeriodInProgress && calendar.isDate(context.startDate, inSameDayAs: expectedBudgetStart)
            && (budget.period == .weekly ? context.period == .week : context.period == .month)
        let budgetLimit = budget.amount
        let budgetExpenses = currentSpendTotal
        let budgetPercentSpent = budgetLimit > 0 ? (budgetExpenses / budgetLimit) * 100.0 : 0.0
        let expectedTimelinePacePercent = totalDaysInCycle > 0 ? (Double(elapsedDays) / Double(totalDaysInCycle)) * 100.0 : 0.0
        let budgetOverPace = budgetPercentSpent - expectedTimelinePacePercent
        
        var exhaustionDays: Int? = nil
        var exhaustionDate: Date? = nil
        if dailyRunRate > 0 && hasActiveBudget {
            let daysUntilExhaustion = Int(ceil(budgetLimit / dailyRunRate))
            if daysUntilExhaustion < totalDaysInCycle {
                exhaustionDays = daysUntilExhaustion
                exhaustionDate = calendar.date(byAdding: .day, value: max(0, daysUntilExhaustion - 1), to: context.startDate)
            }
        }
        
        let safeDaily = remainingDays > 0 ? max(0.0, (budgetLimit - budgetExpenses) / Double(remainingDays)) : 0.0
        
        // 5. Habits & Weekend Rhythms
        var weekendTotal = 0.0
        var weekdayTotal = 0.0
        var weekendTxCount = 0
        var weekdayTxCount = 0
        
        for tx in currentExpenseTxs {
            let weekday = calendar.component(.weekday, from: tx.date)
            if weekday == 1 || weekday == 7 { // Sunday or Saturday
                weekendTotal += tx.amount
                weekendTxCount += 1
            } else {
                weekdayTotal += tx.amount
                weekdayTxCount += 1
            }
        }
        
        let weekendRatio = weekdayTotal > 0 ? (weekendTotal / weekdayTotal) : 0.0
        let weekendShare = currentSpendTotal > 0 ? (weekendTotal / currentSpendTotal) * 100.0 : 0.0
        
        // Zero-spend streak (consecutive days with 0 expenses ending today)
        var streak = 0
        var checkDate = calendar.startOfDay(for: now)
        while streak < 30 && checkDate >= context.startDate && checkDate <= context.endDate {
            let dayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: checkDate) ?? checkDate
            let dayTxs = scopedTransactions.filter { $0.type == .expense && $0.date >= checkDate && $0.date <= min(dayEnd, now) }
            if dayTxs.isEmpty {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }
        
        // Zero spend days in past 7 days
        var zeroDaysPastWeek = 0
        for i in 0..<7 {
            if let d = calendar.date(byAdding: .day, value: -i, to: calendar.startOfDay(for: now)) {
                let dEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: d) ?? d
                let hasTx = scopedTransactions.contains { $0.type == .expense && $0.date >= d && $0.date <= min(dEnd, now) }
                if d >= context.startDate && d <= context.endDate && !hasTx { zeroDaysPastWeek += 1 }
            }
        }
        
        // 6. Committed Subscriptions
        let activeSubs = subscriptions.filter { !$0.isCancelled && !$0.isPaused }
        let totalMonthlyCommitted = activeSubs.filter { !$0.isTrial }.reduce(0.0) { (sum: Double, sub: Subscription) -> Double in
            switch sub.cycle {
            case .monthly: return sum + sub.amount
            case .yearly: return sum + (sub.amount / 12.0)
            case .weekly: return sum + (sub.amount * 4.33)
            }
        }
        
        let subTxList = currentExpenseTxs.filter { tx in
            activeSubs.contains { sub in
                tx.subscriptionId?.lowercased() == sub.id.uuidString.lowercased()
            }
        }
        
        // 7. Income Totals
        let curIncomeTotal = currentIncomeTxs.reduce(0.0) { $0 + $1.amount }
        let baseIncomeTotal = baselineIncomeTxs.reduce(0.0) { $0 + $1.amount }
        let incomeSources = Set(currentIncomeTxs.map { $0.title.lowercased() }).count
        
        // 8. Long-Term Multi-Month Metrics
        var monthlyTotals: [Date: Double] = [:]
        for tx in currentExpenseTxs {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: tx.date)) ?? tx.date
            monthlyTotals[monthStart, default: 0.0] += tx.amount
        }
        
        let highestMonth = monthlyTotals.max { $0.value < $1.value }.map { item -> (Date, Double, String) in
            let df = DateFormatter()
            df.dateFormat = "MMMM"
            return (item.key, item.value, df.string(from: item.key))
        }
        
        let avgPastYear = monthlyTotals.values.isEmpty ? 0.0 : (monthlyTotals.values.reduce(0.0, +) / Double(monthlyTotals.count))
        
        // 9. Data Sufficiency Gates
        let totalExpenseTxCount = currentExpenseTxs.count
        let generalSufficiency: Bool = {
            switch context.period {
            case .week:
                return totalExpenseTxCount >= 1
            case .month:
                return totalExpenseTxCount >= 3 || (totalExpenseTxCount >= 1 && hasBaselineHistory)
            case .threeMonths, .sixMonths:
                return totalExpenseTxCount >= 5 && representedMonthsCount >= 2
            case .year, .all:
                return totalExpenseTxCount >= 8 && representedMonthsCount >= 3
            case .custom:
                return totalExpenseTxCount >= 1
            }
        }()
        
        let multiMonthSufficiency = monthlyTotals.count >= 3 && currentExpenseTxs.count >= 10
        let densityScore = min(1.0, Double(totalExpenseTxCount) / 15.0)
        
        return InsightFacts(
            context: context,
            period: context.period,
            periodStart: context.startDate,
            periodEnd: context.endDate,
            baselineStart: context.baselineStartDate,
            baselineEnd: context.baselineEndDate,
            periodTitle: periodTitle,
            periodPhrase: periodPhrase,
            baselinePeriodPhrase: baselinePeriodPhrase,
            elapsedDays: elapsedDays,
            remainingDays: remainingDays,
            totalDaysInCycle: totalDaysInCycle,
            isEarlyPeriod: isEarlyPeriod,
            isPeriodInProgress: isPeriodInProgress,
            representedDaysCount: representedDaysCount,
            representedWeeksCount: representedWeeksCount,
            representedMonthsCount: representedMonthsCount,
            hasBaselineHistory: hasBaselineHistory,
            currentSpendTotal: currentSpendTotal,
            baselineSpendTotal: baselineSpendTotal,
            totalExpenseTxCount: totalExpenseTxCount,
            dailyRunRate: dailyRunRate,
            projectedPeriodSpend: projectedPeriodSpend,
            spendDeltaPercent: spendDeltaPercent,
            primarySpendingDriver: driver,
            hasActiveBudget: hasActiveBudget,
            budgetLimit: budgetLimit,
            budgetPeriodType: budget.period,
            budgetCycleExpenses: budgetExpenses,
            budgetPercentSpent: budgetPercentSpent,
            budgetSafePacePercent: expectedTimelinePacePercent,
            budgetOverPacePercent: budgetOverPace,
            budgetDaysToExhaustion: exhaustionDays,
            budgetExhaustionDate: exhaustionDate,
            budgetSafeDailyRemaining: safeDaily,
            categorySummaries: summaries,
            topSpendingCategory: topCategory,
            weekendSpendTotal: weekendTotal,
            weekdaySpendTotal: weekdayTotal,
            weekendCount: weekendTxCount,
            weekdayCount: weekdayTxCount,
            weekendToWeekdayRatio: weekendRatio,
            weekendSpendSharePercent: weekendShare,
            zeroSpendStreakDays: streak,
            zeroSpendDaysInPastWeek: zeroDaysPastWeek,
            activeSubscriptions: activeSubs,
            totalMonthlySubscriptionCommitted: totalMonthlyCommitted,
            subscriptionExpensesInPeriod: subTxList,
            currentIncomeTotal: curIncomeTotal,
            baselineIncomeTotal: baseIncomeTotal,
            incomeSourceCount: incomeSources,
            monthlyHistoricalTotals: monthlyTotals,
            highestHistoricalMonth: highestMonth,
            averageMonthlySpendPastYear: avgPastYear,
            dataDensityScore: densityScore,
            hasSufficientGeneralData: generalSufficiency,
            hasSufficientMultiMonthData: multiMonthSufficiency,
            transactions: scopedTransactions,
            categories: categories
        )
    }
    
    /// Convenience helper for standard periods
    static func extractFacts(
        transactions: [Transaction],
        budget: Budget,
        categories: [Category],
        subscriptions: [Subscription],
        period: InsightPeriod = .month,
        scope: AnalyticsInsightContext.Scope = .global,
        now: Date = Date(),
        calendar: Calendar = Calendar.current
    ) -> InsightFacts {
        let context = AnalyticsInsightContext.standard(
            period: period,
            scope: scope,
            referenceDate: now,
            calendar: calendar
        )
        return extractFacts(
            transactions: transactions,
            budget: budget,
            categories: categories,
            subscriptions: subscriptions,
            context: context,
            calendar: calendar
        )
    }
}
