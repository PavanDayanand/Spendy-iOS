//
//  InsightMessageBuilder.swift
//  Spendy
//
//  100% deterministic, human-authored editorial message templates.
//  Zero generative models, zero LLMs, zero cloud dependencies.
//

import Foundation

struct InsightMessagePayload: Sendable {
    let headline: String
    let supportingText: String?
    let emphasis: [InsightEmphasis]
}

enum InsightMessageBuilder {
    
    /// Builds deterministic editorial headline and supporting text from evidence
    static func buildMessage(
        for candidate: InsightCandidate,
        currencySymbol: String
    ) -> InsightMessagePayload {
        switch candidate.evidence {
            
        // MARK: - 1. Spending Velocity & Projections
        case .spendingVelocity(_, _, let deltaPercent, let projected, _):
            let formattedProjected = formatCurrency(projected, symbol: currencySymbol)
            if deltaPercent > 0 {
                return InsightMessagePayload(
                    headline: "You're on pace to spend more this month.",
                    supportingText: "Projected to finish around \(formattedProjected).",
                    emphasis: [.currency(projected), .percentage(deltaPercent)]
                )
            } else {
                return InsightMessagePayload(
                    headline: "Spending is running below usual.",
                    supportingText: "Projected to finish around \(formattedProjected).",
                    emphasis: [.currency(projected), .percentage(abs(deltaPercent))]
                )
            }
            
        // MARK: - 2. Budget & Exhaustion
        case .budgetExceeded(_, _, let excess):
            let formattedExcess = formatCurrency(excess, symbol: currencySymbol)
            return InsightMessagePayload(
                headline: "Monthly budget limit exceeded.",
                supportingText: "\(formattedExcess) over limit for this cycle.",
                emphasis: [.currency(excess)]
            )
            
        case .budgetPacing(_, _, let pctSpent, let overPace, _, let exhaustionDate, let safeDaily, let daysRemaining):
            if let date = exhaustionDate {
                let dateStr = formatDateShort(date)
                return InsightMessagePayload(
                    headline: "Your budget runs out around \(dateStr) at this pace.",
                    supportingText: "Safe daily spend is \(formatCurrency(safeDaily, symbol: currencySymbol)) for the next \(daysRemaining) days.",
                    emphasis: [.date(date), .currency(safeDaily)]
                )
            } else if overPace > 12.0 {
                return InsightMessagePayload(
                    headline: "Spending is outpacing your budget timeline.",
                    supportingText: "\(Int(pctSpent))% spent with \(daysRemaining) days left in the cycle.",
                    emphasis: [.percentage(pctSpent), .count(daysRemaining)]
                )
            } else if safeDaily > 0 {
                return InsightMessagePayload(
                    headline: "Safe daily spend is \(formatCurrency(safeDaily, symbol: currencySymbol)).",
                    supportingText: "\(daysRemaining) days remaining in current budget cycle.",
                    emphasis: [.currency(safeDaily), .count(daysRemaining)]
                )
            } else {
                return InsightMessagePayload(
                    headline: "Pacing smoothly within budget.",
                    supportingText: "\(Int(pctSpent))% spent so far.",
                    emphasis: [.percentage(pctSpent)]
                )
            }
            
        // MARK: - 3. Category Trends & Magnitude Branching
        case .categoryTrend(_, let name, _, _, let deltaAmount, let deltaPercent):
            let formattedAmount = formatCurrency(abs(deltaAmount), symbol: currencySymbol)
            if deltaAmount < 0 {
                // Savings / Reduction
                if abs(deltaPercent) >= 35.0 {
                    return InsightMessagePayload(
                        headline: "Significant decrease in \(name) spending.",
                        supportingText: "\(formattedAmount) lower than last month.",
                        emphasis: [.currency(abs(deltaAmount)), .percentage(abs(deltaPercent))]
                    )
                } else if abs(deltaPercent) >= 15.0 {
                    return InsightMessagePayload(
                        headline: "You're spending less on \(name).",
                        supportingText: "\(formattedAmount) below last month.",
                        emphasis: [.currency(abs(deltaAmount)), .percentage(abs(deltaPercent))]
                    )
                } else {
                    return InsightMessagePayload(
                        headline: "\(name) is a little lower this month.",
                        supportingText: "\(formattedAmount) below last month.",
                        emphasis: [.currency(abs(deltaAmount))]
                    )
                }
            } else {
                // Surge / Increase
                if deltaPercent >= 35.0 {
                    return InsightMessagePayload(
                        headline: "Noticeable increase in \(name) spending.",
                        supportingText: "+\(formattedAmount) higher than last month.",
                        emphasis: [.currency(deltaAmount), .percentage(deltaPercent)]
                    )
                } else {
                    return InsightMessagePayload(
                        headline: "\(name) spending is running higher.",
                        supportingText: "+\(formattedAmount) vs previous period.",
                        emphasis: [.currency(deltaAmount), .percentage(deltaPercent)]
                    )
                }
            }
            
        case .categoryDriver(_, let name, _, _, _):
            return InsightMessagePayload(
                headline: "\(name) is driving most of this month's increase.",
                supportingText: "Primary contributor to higher total spending.",
                emphasis: [.text(name)]
            )
            
        case .categoryDominance(_, let name, _, _, let sharePercent):
            return InsightMessagePayload(
                headline: "\(name) accounts for \(Int(sharePercent))% of your spending.",
                supportingText: "Largest spending allocation this cycle.",
                emphasis: [.percentage(sharePercent)]
            )
            
        case .categoryForecast(_, let name, _, let projected, _, let isSurging):
            let formattedProjected = formatCurrency(projected, symbol: currencySymbol)
            if isSurging {
                return InsightMessagePayload(
                    headline: "\(name) is on pace to reach \(formattedProjected).",
                    supportingText: "Running higher than your previous cycle.",
                    emphasis: [.currency(projected)]
                )
            } else {
                return InsightMessagePayload(
                    headline: "\(name) is projected to finish around \(formattedProjected).",
                    supportingText: "Based on current monthly pace.",
                    emphasis: [.currency(projected)]
                )
            }
            
        // MARK: - 4. Statistical Anomaly
        case .transactionAnomaly(_, _, let name, let amount, _, let multiplier, _):
            let formattedAmount = formatCurrency(amount, symbol: currencySymbol)
            return InsightMessagePayload(
                headline: "That \(name) transaction stands out.",
                supportingText: "\(formattedAmount) is \(Int(multiplier))x higher than your category average.",
                emphasis: [.currency(amount), .percentage(multiplier * 100)]
            )
            
        // MARK: - 5. Habits & Weekend Rhythms
        case .zeroSpendStreak(let streak):
            return InsightMessagePayload(
                headline: "\(streak) consecutive days with zero expenses.",
                supportingText: "Great discipline maintaining your budget.",
                emphasis: [.count(streak)]
            )
            
        case .zeroSpendWeekly(let zeroDays):
            return InsightMessagePayload(
                headline: "\(zeroDays) zero-spend days this week.",
                supportingText: "Consistent restraint across the week.",
                emphasis: [.count(zeroDays)]
            )
            
        case .weekendRhythm(_, _, _, let sharePercent):
            return InsightMessagePayload(
                headline: "Weekend spending is running noticeably higher.",
                supportingText: "\(Int(sharePercent))% of your expenses occur on Saturday & Sunday.",
                emphasis: [.percentage(sharePercent)]
            )
            
        // MARK: - 6. Subscriptions
        case .subscriptionDoubleCharge(_, let name, let count, _):
            return InsightMessagePayload(
                headline: "Double charge detected on \(name).",
                supportingText: "\(count) charges recorded in this cycle.",
                emphasis: [.text(name), .count(count)]
            )
            
        case .subscriptionPriceChange(_, let name, let expected, let actual, let deltaPct):
            let formattedActual = formatCurrency(actual, symbol: currencySymbol)
            let formattedExpected = formatCurrency(expected, symbol: currencySymbol)
            return InsightMessagePayload(
                headline: "\(name) price changed to \(formattedActual).",
                supportingText: "Previously \(formattedExpected) (\(deltaPct > 0 ? "+" : "")\(Int(deltaPct))%).",
                emphasis: [.currency(actual), .currency(expected)]
            )
            
        case .subscriptionOverdue(_, let name, let amount, let daysOverdue):
            let formattedAmount = formatCurrency(amount, symbol: currencySymbol)
            return InsightMessagePayload(
                headline: "\(name) bill is past due.",
                supportingText: "\(formattedAmount) was due \(daysOverdue == 0 ? "today" : "\(daysOverdue) days ago").",
                emphasis: [.currency(amount)]
            )
            
        case .subscriptionDue(_, let name, let amount, let daysUntil, _):
            let formattedAmount = formatCurrency(amount, symbol: currencySymbol)
            let dayText = daysUntil == 1 ? "tomorrow" : "in \(daysUntil) days"
            return InsightMessagePayload(
                headline: "\(name) bill is due \(dayText).",
                supportingText: "\(formattedAmount) scheduled for renewal.",
                emphasis: [.currency(amount)]
            )
            
        case .subscriptionCommitment(let count, let monthly):
            let formattedMonthly = formatCurrency(monthly, symbol: currencySymbol)
            return InsightMessagePayload(
                headline: "\(formattedMonthly) monthly across \(count) active subscriptions.",
                supportingText: "Committed recurring expenses.",
                emphasis: [.currency(monthly), .count(count)]
            )
            
        // MARK: - 7. Income
        case .incomeShift(_, _, let deltaPercent):
            if deltaPercent > 0 {
                return InsightMessagePayload(
                    headline: "Income increased by \(Int(deltaPercent))% this period.",
                    supportingText: "Higher earnings compared to previous period.",
                    emphasis: [.percentage(deltaPercent)]
                )
            } else {
                return InsightMessagePayload(
                    headline: "Income is \(Int(abs(deltaPercent)))% lower this period.",
                    supportingText: "Earnings are below your previous period baseline.",
                    emphasis: [.percentage(abs(deltaPercent))]
                )
            }
            
        case .incomeDiversification(let count):
            return InsightMessagePayload(
                headline: "Earnings across \(count) separate income streams.",
                supportingText: "Diversified income distribution.",
                emphasis: [.count(count)]
            )
        }
    }
    
    // MARK: - Compound Message Builder
    
    /// Builds a compound message synthesizing primary pacing/velocity observation with its root-cause driver
    static func buildCompoundMessage(
        primary: InsightCandidate,
        driver: InsightCandidate,
        currencySymbol: String
    ) -> InsightMessagePayload {
        let primaryPayload = buildMessage(for: primary, currencySymbol: currencySymbol)
        let driverPayload = buildMessage(for: driver, currencySymbol: currencySymbol)
        
        return InsightMessagePayload(
            headline: primaryPayload.headline,
            supportingText: driverPayload.headline,
            emphasis: primaryPayload.emphasis + driverPayload.emphasis
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
