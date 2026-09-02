//
//  InsightFacts.swift
//  Spendy
//
//  Canonical immutable snapshot of calculated financial, temporal, and behavioral facts.
//

import Foundation

struct CategoryFactSummary: Hashable, Sendable {
    let categoryId: String
    let categoryName: String
    let currentSpend: Double
    let baselineSpend: Double
    let txCount: Int
    let meanTxAmount: Double
    let currentSharePercent: Double
    let baselineSharePercent: Double
    let deltaSpend: Double
    let deltaPercent: Double
}

struct InsightFacts: Sendable {
    // 0. Exact Analytical Context
    let context: AnalyticsInsightContext
    
    // 1. Temporal Context & Period Information
    let period: InsightPeriod
    let periodStart: Date
    let periodEnd: Date
    let baselineStart: Date
    let baselineEnd: Date
    let periodTitle: String
    let periodPhrase: String
    let baselinePeriodPhrase: String
    let elapsedDays: Int
    let remainingDays: Int
    let totalDaysInCycle: Int
    let isEarlyPeriod: Bool
    let isPeriodInProgress: Bool
    let representedDaysCount: Int
    let representedWeeksCount: Int
    let representedMonthsCount: Int
    let hasBaselineHistory: Bool
    
    // 2. Spending & Velocity Totals
    let currentSpendTotal: Double
    let baselineSpendTotal: Double
    let totalExpenseTxCount: Int
    let dailyRunRate: Double
    let projectedPeriodSpend: Double
    let spendDeltaPercent: Double
    let primarySpendingDriver: CategoryFactSummary?
    
    // 3. Budget & Pacing (Contextual for monthly/weekly cycle)
    let hasActiveBudget: Bool
    let budgetLimit: Double
    let budgetPeriodType: BudgetPeriod
    let budgetCycleExpenses: Double
    let budgetPercentSpent: Double
    let budgetSafePacePercent: Double
    let budgetOverPacePercent: Double
    let budgetDaysToExhaustion: Int?
    let budgetExhaustionDate: Date?
    let budgetSafeDailyRemaining: Double
    
    // 4. Category Matrices
    let categorySummaries: [String: CategoryFactSummary]
    let topSpendingCategory: CategoryFactSummary?
    
    // 5. Habits & Weekend Rhythms
    let weekendSpendTotal: Double
    let weekdaySpendTotal: Double
    let weekendCount: Int
    let weekdayCount: Int
    let weekendToWeekdayRatio: Double
    let weekendSpendSharePercent: Double
    let zeroSpendStreakDays: Int
    let zeroSpendDaysInPastWeek: Int
    
    // 6. Subscriptions
    let activeSubscriptions: [Subscription]
    let totalMonthlySubscriptionCommitted: Double
    let subscriptionExpensesInPeriod: [Transaction]
    
    // 7. Income
    let currentIncomeTotal: Double
    let baselineIncomeTotal: Double
    let incomeSourceCount: Int
    
    // 8. Long-Term Multi-Month Metrics
    let monthlyHistoricalTotals: [Date: Double]
    let highestHistoricalMonth: (date: Date, total: Double, name: String)?
    let averageMonthlySpendPastYear: Double
    
    // 9. Data Sufficiency & Stability Indicators
    let dataDensityScore: Double
    let hasSufficientGeneralData: Bool
    let hasSufficientMultiMonthData: Bool
    let transactions: [Transaction]
    let categories: [Category]
    
    init(
        context: AnalyticsInsightContext? = nil,
        period: InsightPeriod,
        periodStart: Date,
        periodEnd: Date,
        baselineStart: Date,
        baselineEnd: Date,
        periodTitle: String,
        periodPhrase: String,
        baselinePeriodPhrase: String,
        elapsedDays: Int,
        remainingDays: Int,
        totalDaysInCycle: Int,
        isEarlyPeriod: Bool,
        isPeriodInProgress: Bool,
        representedDaysCount: Int,
        representedWeeksCount: Int,
        representedMonthsCount: Int,
        hasBaselineHistory: Bool,
        currentSpendTotal: Double,
        baselineSpendTotal: Double,
        totalExpenseTxCount: Int,
        dailyRunRate: Double,
        projectedPeriodSpend: Double,
        spendDeltaPercent: Double,
        primarySpendingDriver: CategoryFactSummary?,
        hasActiveBudget: Bool,
        budgetLimit: Double,
        budgetPeriodType: BudgetPeriod,
        budgetCycleExpenses: Double,
        budgetPercentSpent: Double,
        budgetSafePacePercent: Double,
        budgetOverPacePercent: Double,
        budgetDaysToExhaustion: Int?,
        budgetExhaustionDate: Date?,
        budgetSafeDailyRemaining: Double,
        categorySummaries: [String: CategoryFactSummary],
        topSpendingCategory: CategoryFactSummary?,
        weekendSpendTotal: Double,
        weekdaySpendTotal: Double,
        weekendCount: Int,
        weekdayCount: Int,
        weekendToWeekdayRatio: Double,
        weekendSpendSharePercent: Double,
        zeroSpendStreakDays: Int,
        zeroSpendDaysInPastWeek: Int,
        activeSubscriptions: [Subscription],
        totalMonthlySubscriptionCommitted: Double,
        subscriptionExpensesInPeriod: [Transaction],
        currentIncomeTotal: Double,
        baselineIncomeTotal: Double,
        incomeSourceCount: Int,
        monthlyHistoricalTotals: [Date: Double] = [:],
        highestHistoricalMonth: (date: Date, total: Double, name: String)? = nil,
        averageMonthlySpendPastYear: Double = 0.0,
        dataDensityScore: Double,
        hasSufficientGeneralData: Bool,
        hasSufficientMultiMonthData: Bool = false,
        transactions: [Transaction],
        categories: [Category]
    ) {
        self.context = context ?? AnalyticsInsightContext(
            scope: .global,
            period: period,
            startDate: periodStart,
            endDate: periodEnd,
            baselineStartDate: baselineStart,
            baselineEndDate: baselineEnd
        )
        self.period = period
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.baselineStart = baselineStart
        self.baselineEnd = baselineEnd
        self.periodTitle = periodTitle
        self.periodPhrase = periodPhrase
        self.baselinePeriodPhrase = baselinePeriodPhrase
        self.elapsedDays = elapsedDays
        self.remainingDays = remainingDays
        self.totalDaysInCycle = totalDaysInCycle
        self.isEarlyPeriod = isEarlyPeriod
        self.isPeriodInProgress = isPeriodInProgress
        self.representedDaysCount = representedDaysCount
        self.representedWeeksCount = representedWeeksCount
        self.representedMonthsCount = representedMonthsCount
        self.hasBaselineHistory = hasBaselineHistory
        self.currentSpendTotal = currentSpendTotal
        self.baselineSpendTotal = baselineSpendTotal
        self.totalExpenseTxCount = totalExpenseTxCount
        self.dailyRunRate = dailyRunRate
        self.projectedPeriodSpend = projectedPeriodSpend
        self.spendDeltaPercent = spendDeltaPercent
        self.primarySpendingDriver = primarySpendingDriver
        self.hasActiveBudget = hasActiveBudget
        self.budgetLimit = budgetLimit
        self.budgetPeriodType = budgetPeriodType
        self.budgetCycleExpenses = budgetCycleExpenses
        self.budgetPercentSpent = budgetPercentSpent
        self.budgetSafePacePercent = budgetSafePacePercent
        self.budgetOverPacePercent = budgetOverPacePercent
        self.budgetDaysToExhaustion = budgetDaysToExhaustion
        self.budgetExhaustionDate = budgetExhaustionDate
        self.budgetSafeDailyRemaining = budgetSafeDailyRemaining
        self.categorySummaries = categorySummaries
        self.topSpendingCategory = topSpendingCategory
        self.weekendSpendTotal = weekendSpendTotal
        self.weekdaySpendTotal = weekdaySpendTotal
        self.weekendCount = weekendCount
        self.weekdayCount = weekdayCount
        self.weekendToWeekdayRatio = weekendToWeekdayRatio
        self.weekendSpendSharePercent = weekendSpendSharePercent
        self.zeroSpendStreakDays = zeroSpendStreakDays
        self.zeroSpendDaysInPastWeek = zeroSpendDaysInPastWeek
        self.activeSubscriptions = activeSubscriptions
        self.totalMonthlySubscriptionCommitted = totalMonthlySubscriptionCommitted
        self.subscriptionExpensesInPeriod = subscriptionExpensesInPeriod
        self.currentIncomeTotal = currentIncomeTotal
        self.baselineIncomeTotal = baselineIncomeTotal
        self.incomeSourceCount = incomeSourceCount
        self.monthlyHistoricalTotals = monthlyHistoricalTotals
        self.highestHistoricalMonth = highestHistoricalMonth
        self.averageMonthlySpendPastYear = averageMonthlySpendPastYear
        self.dataDensityScore = dataDensityScore
        self.hasSufficientGeneralData = hasSufficientGeneralData
        self.hasSufficientMultiMonthData = hasSufficientMultiMonthData
        self.transactions = transactions
        self.categories = categories
    }
}
