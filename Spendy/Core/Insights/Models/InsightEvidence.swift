//
//  InsightEvidence.swift
//  Spendy
//
//  Structured, type-safe mathematical evidence produced by domain rules.
//

import Foundation

enum InsightEvidence: Hashable, Sendable {
    // Spending & Velocity
    case spendingVelocity(currentSpend: Double, baselineSpend: Double, deltaPercent: Double, projectedMonthSpend: Double, daysElapsed: Int, period: InsightPeriod)
    
    // Budget & Exhaustion
    case budgetPacing(limit: Double, spent: Double, percentSpent: Double, overPacePercent: Double, daysToExhaustion: Int, exhaustionDate: Date?, safeDailyRemaining: Double, daysRemaining: Int)
    case budgetExceeded(limit: Double, spent: Double, excessAmount: Double)
    
    // Category Trends & Drivers
    case categoryTrend(categoryId: String, categoryName: String, currentAmount: Double, baselineAmount: Double, deltaAmount: Double, deltaPercent: Double, period: InsightPeriod)
    case categoryDriver(categoryId: String, categoryName: String, categoryIncrease: Double, totalIncrease: Double, driverSharePercent: Double, period: InsightPeriod)
    case categoryDominance(categoryId: String, categoryName: String, categorySpend: Double, totalSpend: Double, sharePercent: Double, period: InsightPeriod)
    case categoryForecast(categoryId: String, categoryName: String, currentSpend: Double, projectedSpend: Double, baselineSpend: Double, isSurging: Bool)
    
    // Statistical Anomaly
    case transactionAnomaly(transactionId: UUID, categoryId: String, categoryName: String, amount: Double, meanAmount: Double, multiplier: Double, date: Date)
    
    // Habits & Rhythms
    case zeroSpendStreak(streakDays: Int)
    case zeroSpendWeekly(zeroDaysInWeek: Int)
    case weekendRhythm(weekendSpend: Double, weekdaySpend: Double, weekendRatio: Double, weekendSharePercent: Double)
    
    // Subscriptions
    case subscriptionDoubleCharge(subscriptionId: String, subscriptionName: String, chargeCount: Int, totalCharged: Double)
    case subscriptionPriceChange(subscriptionId: String, subscriptionName: String, expectedAmount: Double, actualAmount: Double, deltaPercent: Double)
    case subscriptionDue(subscriptionId: String, subscriptionName: String, amount: Double, daysUntilDue: Int, dueDate: Date)
    case subscriptionOverdue(subscriptionId: String, subscriptionName: String, amount: Double, daysOverdue: Int)
    case subscriptionCommitment(activeCount: Int, monthlyCommitted: Double)
    
    // Income
    case incomeShift(currentIncome: Double, baselineIncome: Double, deltaPercent: Double, period: InsightPeriod)
    case incomeDiversification(sourceCount: Int)
    
    // Long-Term & Multi-Month Evidence
    case longTermCategoryTrend(categoryId: String, categoryName: String, monthsCount: Int, direction: String, monthlyAverage: Double, totalSpend: Double)
    case seasonality(peakMonthName: String, peakMonthSpend: Double, averageMonthSpend: Double, multiplier: Double)
    case subscriptionBudgetImpact(subscriptionName: String, increaseAmount: Double, committedTotal: Double, budgetSharePercent: Double)
    case anomalyDominance(categoryId: String, categoryName: String, anomalyAmount: Double, categorySharePercent: Double)
}
