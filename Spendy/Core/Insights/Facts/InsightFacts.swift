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
    // 1. Temporal Context
    let periodStart: Date
    let periodEnd: Date
    let baselineStart: Date
    let baselineEnd: Date
    let elapsedDays: Int
    let remainingDays: Int
    let totalDaysInCycle: Int
    let isEarlyPeriod: Bool      // e.g. < 3 days elapsed in period
    
    // 2. Spending & Velocity Totals
    let currentSpendTotal: Double
    let baselineSpendTotal: Double
    let totalExpenseTxCount: Int
    let dailyRunRate: Double
    let projectedPeriodSpend: Double
    let spendDeltaPercent: Double
    let primarySpendingDriver: CategoryFactSummary?
    
    // 3. Budget & Pacing
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
    
    // 8. Data Sufficiency & Stability Indicators
    let dataDensityScore: Double
    let hasSufficientGeneralData: Bool
    let transactions: [Transaction]
    let categories: [Category]
    
    init(
        periodStart: Date,
        periodEnd: Date,
        baselineStart: Date,
        baselineEnd: Date,
        elapsedDays: Int,
        remainingDays: Int,
        totalDaysInCycle: Int,
        isEarlyPeriod: Bool,
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
        dataDensityScore: Double,
        hasSufficientGeneralData: Bool,
        transactions: [Transaction],
        categories: [Category]
    ) {
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.baselineStart = baselineStart
        self.baselineEnd = baselineEnd
        self.elapsedDays = elapsedDays
        self.remainingDays = remainingDays
        self.totalDaysInCycle = totalDaysInCycle
        self.isEarlyPeriod = isEarlyPeriod
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
        self.dataDensityScore = dataDensityScore
        self.hasSufficientGeneralData = hasSufficientGeneralData
        self.transactions = transactions
        self.categories = categories
    }
}
