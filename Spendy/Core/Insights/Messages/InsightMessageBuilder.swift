//
//  InsightMessageBuilder.swift
//  Spendy
//
//  100% deterministic, human-authored editorial message templates with period-awareness and rich emphasis tokens.
//  Zero generative models, zero LLMs, zero cloud dependencies.
//  Action links are generated ONLY when a meaningful destination is present.
//

import Foundation

struct InsightMessagePayload: Sendable {
    let headline: String
    let supportingText: String?
    let emphasis: [InsightEmphasis]
    let actionTitle: String?
}

enum InsightMessageBuilder {
    
    /// Builds deterministic editorial headline, supporting text, and action metadata from evidence
    static func buildMessage(
        for candidate: InsightCandidate,
        currencySymbol: String
    ) -> InsightMessagePayload {
        let hasDestination = candidate.destination != nil
        
        switch candidate.evidence {
            
        // MARK: - 1. Spending Velocity & Projections
        case .spendingVelocity(_, _, let deltaPercent, let projected, _, let period):
            let formattedProjected = formatCurrency(projected, symbol: currencySymbol)
            let formattedPct = "\(Int(abs(deltaPercent)))%"
            let periodWord = period.currentPeriodPhrase
            
            if deltaPercent > 0 {
                return InsightMessagePayload(
                    headline: "You're on pace to spend more \(periodWord).",
                    supportingText: "Projected to finish around \(formattedProjected).",
                    emphasis: [.highlight(formattedProjected), .percentage(deltaPercent)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
                )
            } else {
                return InsightMessagePayload(
                    headline: "Spending is running \(formattedPct) below usual.",
                    supportingText: "Projected to finish around \(formattedProjected).",
                    emphasis: [.highlight(formattedPct), .currency(projected)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
                )
            }
            
        // MARK: - 2. Budget & Exhaustion
        case .budgetExceeded(_, _, let excess):
            let formattedExcess = formatCurrency(excess, symbol: currencySymbol)
            return InsightMessagePayload(
                headline: "Monthly budget limit exceeded.",
                supportingText: "\(formattedExcess) over limit for this cycle.",
                emphasis: [.highlight(formattedExcess), .currency(excess)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
            )
            
        case .budgetPacing(_, _, let pctSpent, let overPace, _, let exhaustionDate, let safeDaily, let daysRemaining):
            let formattedSafeDaily = formatCurrency(safeDaily, symbol: currencySymbol)
            let formattedPct = "\(Int(pctSpent))%"
            
            if let date = exhaustionDate {
                let dateStr = formatDateShort(date)
                return InsightMessagePayload(
                    headline: "Your budget runs out around \(dateStr) at this pace.",
                    supportingText: "Safe daily spend is \(formattedSafeDaily) for the next \(daysRemaining) days.",
                    emphasis: [.highlight(dateStr), .highlight(formattedSafeDaily), .date(date)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
                )
            } else if overPace > 12.0 {
                return InsightMessagePayload(
                    headline: "Spending is outpacing your budget timeline.",
                    supportingText: "\(formattedPct) spent with \(daysRemaining) days left in the cycle.",
                    emphasis: [.highlight(formattedPct), .count(daysRemaining)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
                )
            } else if safeDaily > 0 {
                return InsightMessagePayload(
                    headline: "Safe daily spend is \(formattedSafeDaily).",
                    supportingText: "\(daysRemaining) days remaining in current budget cycle.",
                    emphasis: [.highlight(formattedSafeDaily), .count(daysRemaining)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
                )
            } else {
                return InsightMessagePayload(
                    headline: "Pacing smoothly within budget.",
                    supportingText: "\(formattedPct) spent so far.",
                    emphasis: [.highlight(formattedPct)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
                )
            }
            
        // MARK: - 3. Category Trends & Magnitude Branching
        case .categoryTrend(_, let name, _, _, let deltaAmount, let deltaPercent, let period):
            let formattedAmount = formatCurrency(abs(deltaAmount), symbol: currencySymbol)
            let formattedPct = "\(Int(abs(deltaPercent)))%"
            let basePeriodWord = period.baselinePeriodPhrase
            
            if deltaAmount < 0 {
                if abs(deltaPercent) >= 35.0 {
                    return InsightMessagePayload(
                        headline: "Significant decrease in \(name) spending.",
                        supportingText: "\(formattedAmount) lower than \(basePeriodWord).",
                        emphasis: [.highlight(formattedAmount), .percentage(abs(deltaPercent))],
                        actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                    )
                } else {
                    return InsightMessagePayload(
                        headline: "You're spending less on \(name).",
                        supportingText: "\(formattedAmount) below \(basePeriodWord).",
                        emphasis: [.highlight(formattedAmount), .percentage(abs(deltaPercent))],
                        actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                    )
                }
            } else {
                if deltaPercent >= 35.0 {
                    return InsightMessagePayload(
                        headline: "Noticeable increase in \(name) spending.",
                        supportingText: "+\(formattedAmount) (\(formattedPct)) higher than \(basePeriodWord).",
                        emphasis: [.highlight(name), .highlight("+\(formattedAmount)")],
                        actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                    )
                } else {
                    return InsightMessagePayload(
                        headline: "\(name) spending is running higher.",
                        supportingText: "+\(formattedAmount) vs \(basePeriodWord).",
                        emphasis: [.highlight(name), .highlight("+\(formattedAmount)")],
                        actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                    )
                }
            }
            
        case .categoryDriver(_, let name, _, _, _, let period):
            let periodWord = period.currentPeriodPhrase
            return InsightMessagePayload(
                headline: "\(name) is driving most of \(periodWord)'s increase.",
                supportingText: "Primary contributor to higher total spending.",
                emphasis: [.highlight(name)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .categoryDominance(_, let name, _, _, let sharePercent, _):
            let formattedShare = "\(Int(sharePercent))%"
            return InsightMessagePayload(
                headline: "\(name) accounts for \(formattedShare) of your spending.",
                supportingText: "Largest spending allocation across this timeframe.",
                emphasis: [.highlight(name), .highlight(formattedShare)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .categoryForecast(_, let name, _, let projected, _, let isSurging):
            let formattedProjected = formatCurrency(projected, symbol: currencySymbol)
            if isSurging {
                return InsightMessagePayload(
                    headline: "\(name) is on pace to reach \(formattedProjected).",
                    supportingText: "Running higher than your previous cycle.",
                    emphasis: [.highlight(formattedProjected)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                )
            } else {
                return InsightMessagePayload(
                    headline: "\(name) is projected to finish around \(formattedProjected).",
                    supportingText: "Based on current monthly pace.",
                    emphasis: [.highlight(formattedProjected)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                )
            }
            
        // MARK: - 4. Statistical Anomaly
        case .transactionAnomaly(_, _, let name, let amount, _, let multiplier, _):
            let formattedAmount = formatCurrency(amount, symbol: currencySymbol)
            let formattedMult = "\(Int(multiplier))x"
            return InsightMessagePayload(
                headline: "That \(name) transaction stands out.",
                supportingText: "\(formattedAmount) is \(formattedMult) higher than your category average.",
                emphasis: [.highlight(formattedAmount), .highlight(formattedMult)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Transaction →") : nil
            )
            
        // MARK: - 5. Habits & Weekend Rhythms
        case .zeroSpendStreak(let streak):
            let formattedStreak = "\(streak) consecutive days"
            return InsightMessagePayload(
                headline: "\(formattedStreak) with zero expenses.",
                supportingText: "Great discipline maintaining your budget.",
                emphasis: [.highlight(formattedStreak)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
            )
            
        case .zeroSpendWeekly(let zeroDays):
            let formattedDays = "\(zeroDays) zero-spend days"
            return InsightMessagePayload(
                headline: "\(formattedDays) this week.",
                supportingText: "Consistent restraint across the week.",
                emphasis: [.highlight(formattedDays)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
            )
            
        case .weekendRhythm(_, _, _, let sharePercent):
            let formattedShare = "\(Int(sharePercent))%"
            return InsightMessagePayload(
                headline: "Weekend spending is running noticeably higher.",
                supportingText: "\(formattedShare) of your expenses occur on Saturday & Sunday.",
                emphasis: [.highlight(formattedShare)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
            )
            
        // MARK: - 6. Subscriptions
        case .subscriptionDoubleCharge(_, let name, let count, _):
            let formattedCount = "\(count) charges"
            return InsightMessagePayload(
                headline: "Double charge detected on \(name).",
                supportingText: "\(formattedCount) recorded in this cycle.",
                emphasis: [.highlight(name), .highlight(formattedCount)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .subscriptionPriceChange(_, let name, let expected, let actual, let deltaPct):
            let formattedActual = formatCurrency(actual, symbol: currencySymbol)
            let formattedExpected = formatCurrency(expected, symbol: currencySymbol)
            let formattedPct = "\(deltaPct > 0 ? "+" : "")\(Int(deltaPct))%"
            return InsightMessagePayload(
                headline: "\(name) price changed to \(formattedActual).",
                supportingText: "Previously \(formattedExpected) (\(formattedPct)).",
                emphasis: [.highlight(name), .highlight(formattedActual)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .subscriptionOverdue(_, let name, let amount, let daysOverdue):
            let formattedAmount = formatCurrency(amount, symbol: currencySymbol)
            let dueText = daysOverdue == 0 ? "due today" : "due \(daysOverdue) days ago"
            return InsightMessagePayload(
                headline: "\(name) bill is past due.",
                supportingText: "\(formattedAmount) was \(dueText).",
                emphasis: [.highlight(name), .highlight(formattedAmount)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .subscriptionDue(_, let name, let amount, let daysUntil, _):
            let formattedAmount = formatCurrency(amount, symbol: currencySymbol)
            let dayText = daysUntil == 1 ? "tomorrow" : "in \(daysUntil) days"
            return InsightMessagePayload(
                headline: "\(name) bill is due \(dayText).",
                supportingText: "\(formattedAmount) scheduled for renewal.",
                emphasis: [.highlight(name), .highlight(dayText)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .subscriptionCommitment(let count, let monthly):
            let formattedMonthly = formatCurrency(monthly, symbol: currencySymbol)
            let formattedCount = "\(count) active subscriptions"
            return InsightMessagePayload(
                headline: "\(formattedMonthly) monthly across \(formattedCount).",
                supportingText: "Committed recurring expenses.",
                emphasis: [.highlight(formattedMonthly)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Subscriptions →") : nil
            )
            
        // MARK: - 7. Income
        case .incomeShift(_, _, let deltaPercent, let period):
            let formattedPct = "\(Int(abs(deltaPercent)))%"
            let periodWord = period.currentPeriodPhrase
            if deltaPercent > 0 {
                return InsightMessagePayload(
                    headline: "Income increased by \(formattedPct) \(periodWord).",
                    supportingText: "Higher earnings compared to your baseline.",
                    emphasis: [.highlight(formattedPct)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Income →") : nil
                )
            } else {
                return InsightMessagePayload(
                    headline: "Income is \(formattedPct) lower \(periodWord).",
                    supportingText: "Earnings are below your baseline.",
                    emphasis: [.highlight(formattedPct)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Income →") : nil
                )
            }
            
        case .incomeDiversification(let count):
            let formattedStreams = "\(count) separate streams"
            return InsightMessagePayload(
                headline: "Earnings across \(formattedStreams).",
                supportingText: "Diversified income distribution.",
                emphasis: [.highlight(formattedStreams)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Income →") : nil
            )
            
        // MARK: - 8. Long-Term Multi-Month & Seasonal Trends
        case .longTermCategoryTrend(_, let name, let months, _, let monthlyAvg, _):
            let formattedAvg = formatCurrency(monthlyAvg, symbol: currencySymbol)
            return InsightMessagePayload(
                headline: "\(name) has become your largest category over the last \(months) months.",
                supportingText: "Averaging \(formattedAvg) per month.",
                emphasis: [.highlight(name), .highlight(formattedAvg)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .seasonality(let peakMonth, _, _, let multiplier):
            let formattedMult = String(format: "%.1fx", multiplier)
            return InsightMessagePayload(
                headline: "\(peakMonth) is usually your most expensive month.",
                supportingText: "Historical spending averaged \(formattedMult) higher than other months.",
                emphasis: [.highlight(peakMonth), .highlight(formattedMult)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
            )
            
        case .subscriptionBudgetImpact(let name, _, let committedTotal, let budgetSharePct):
            let formattedTotal = formatCurrency(committedTotal, symbol: currencySymbol)
            let formattedShare = "\(Int(budgetSharePct))%"
            return InsightMessagePayload(
                headline: "\(name) increased your recurring commitments.",
                supportingText: "Subscriptions now total \(formattedTotal) (\(formattedShare) of budget).",
                emphasis: [.highlight(name), .highlight(formattedTotal)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Subscriptions →") : nil
            )
            
        case .anomalyDominance(_, let name, let anomalyAmount, let sharePct):
            let formattedAmount = formatCurrency(anomalyAmount, symbol: currencySymbol)
            let formattedShare = "\(Int(sharePct))%"
            return InsightMessagePayload(
                headline: "A single \(formattedAmount) transaction drove \(name) spend.",
                supportingText: "Represents \(formattedShare) of the category total.",
                emphasis: [.highlight(formattedAmount), .highlight(name)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
        }
    }
    
    // MARK: - Compound Message Synthesizers
    
    /// Builds a compound message synthesizing a primary pacing/velocity observation with its root-cause driver
    static func buildCompoundMessage(
        primary: InsightCandidate,
        driver: InsightCandidate,
        currencySymbol: String
    ) -> InsightMessagePayload {
        let primaryPayload = buildMessage(for: primary, currencySymbol: currencySymbol)
        let driverPayload = buildMessage(for: driver, currencySymbol: currencySymbol)
        
        let effectiveDestination = driver.destination ?? primary.destination
        let hasEffectiveDestination = effectiveDestination != nil
        let compoundActionTitle: String? = {
            guard hasEffectiveDestination else { return nil }
            return driver.actionTitle ?? primaryPayload.actionTitle
        }()
        
        return InsightMessagePayload(
            headline: primaryPayload.headline,
            supportingText: driverPayload.headline,
            emphasis: primaryPayload.emphasis + driverPayload.emphasis,
            actionTitle: compoundActionTitle
        )
    }
    
    // MARK: - Formatting Helpers
    
    private static func formatCurrency(_ value: Double, symbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(symbol)\(formatted)"
    }
    
    private static func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}
