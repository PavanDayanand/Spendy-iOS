//
//  InsightMessageBuilder.swift
//  Spendy
//
//  Deterministic, human-authored insight copy. You-voice, named entities,
//  no lecture words. Zero generative models.
//

import Foundation

struct InsightMessagePayload: Sendable {
    let headline: String
    let supportingText: String?
    let emphasis: [InsightEmphasis]
    let actionTitle: String?
}

enum InsightMessageBuilder {
    
    static func buildMessage(
        for candidate: InsightCandidate,
        currencySymbol: String
    ) -> InsightMessagePayload {
        let hasDestination = candidate.destination != nil
        
        switch candidate.evidence {
            
        case .spendingVelocity(_, _, let deltaPercent, let projected, _, let period):
            let formattedProjected = formatCurrency(projected, symbol: currencySymbol)
            let formattedPct = "\(Int(abs(deltaPercent)))%"
            let periodWord = period.currentPeriodPhrase
            
            if deltaPercent > 0 {
                return InsightMessagePayload(
                    headline: "You're on pace to spend more \(periodWord).",
                    supportingText: "Looks like you'll land around \(formattedProjected).",
                    emphasis: [.highlight(formattedProjected), .percentage(deltaPercent)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
                )
            } else {
                return InsightMessagePayload(
                    headline: "You're spending \(formattedPct) less than usual.",
                    supportingText: "Looks like you'll land around \(formattedProjected).",
                    emphasis: [.highlight(formattedPct), .currency(projected)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
                )
            }
            
        case .budgetExceeded(_, _, let excess):
            let formattedExcess = formatCurrency(excess, symbol: currencySymbol)
            return InsightMessagePayload(
                headline: "You've gone past this month's budget.",
                supportingText: "\(formattedExcess) over the limit.",
                emphasis: [.highlight(formattedExcess), .currency(excess)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
            )
            
        case .budgetPacing(_, _, let pctSpent, let overPace, _, let exhaustionDate, let safeDaily, let daysRemaining):
            let formattedSafeDaily = formatCurrency(safeDaily, symbol: currencySymbol)
            let formattedPct = "\(Int(pctSpent))%"
            let daysText = daysWord(daysRemaining)
            
            if let date = exhaustionDate {
                let dateStr = formatDateShort(date)
                return InsightMessagePayload(
                    headline: "Your budget runs out around \(dateStr) at this pace.",
                    supportingText: "You can spend \(formattedSafeDaily) a day for the next \(daysText).",
                    emphasis: [.highlight(dateStr), .highlight(formattedSafeDaily), .date(date)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
                )
            } else if overPace > 12.0 {
                return InsightMessagePayload(
                    headline: "You're spending faster than this month's budget.",
                    supportingText: "\(formattedPct) used, with \(daysText) left.",
                    emphasis: [.highlight(formattedPct), .count(daysRemaining)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
                )
            } else if safeDaily > 0 {
                return InsightMessagePayload(
                    headline: "You can spend \(formattedSafeDaily) a day and stay on track.",
                    supportingText: "\(daysText) left in this cycle.",
                    emphasis: [.highlight(formattedSafeDaily), .count(daysRemaining)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
                )
            } else {
                return InsightMessagePayload(
                    headline: "You're still in control of this month's budget.",
                    supportingText: "\(formattedPct) used so far.",
                    emphasis: [.highlight(formattedPct)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Budget →") : nil
                )
            }
            
        case .categoryTrend(_, let name, _, _, let deltaAmount, let deltaPercent, let period):
            let formattedAmount = formatCurrency(abs(deltaAmount), symbol: currencySymbol)
            let basePeriodWord = period.baselinePeriodPhrase
            
            if deltaAmount < 0 {
                if abs(deltaPercent) >= 35.0 {
                    return InsightMessagePayload(
                        headline: "You're spending a lot less on \(name).",
                        supportingText: "\(formattedAmount) less than \(basePeriodWord).",
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
                        headline: "You're spending more on \(name).",
                        supportingText: "+\(formattedAmount) vs \(basePeriodWord).",
                        emphasis: [.highlight(name), .highlight("+\(formattedAmount)")],
                        actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                    )
                } else {
                    return InsightMessagePayload(
                        headline: "You're spending a bit more on \(name).",
                        supportingText: "+\(formattedAmount) vs \(basePeriodWord).",
                        emphasis: [.highlight(name), .highlight("+\(formattedAmount)")],
                        actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                    )
                }
            }
            
        case .categoryDriver(_, let name, _, _, _, let period):
            let periodWord = period.currentPeriodPhrase
            return InsightMessagePayload(
                headline: "\(name) is doing most of the extra spend \(periodWord).",
                supportingText: "That's where the increase is coming from.",
                emphasis: [.highlight(name)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .categoryDominance(_, let name, _, _, let sharePercent, _):
            let formattedShare = "\(Int(sharePercent))%"
            return InsightMessagePayload(
                headline: "\(name) is \(formattedShare) of what you spent.",
                supportingText: "That's your biggest category this period.",
                emphasis: [.highlight(name), .highlight(formattedShare)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .categoryForecast(_, let name, _, let projected, _, let isSurging):
            let formattedProjected = formatCurrency(projected, symbol: currencySymbol)
            if isSurging {
                return InsightMessagePayload(
                    headline: "\(name) is heading toward \(formattedProjected).",
                    supportingText: "You're spending more here than last cycle.",
                    emphasis: [.highlight(formattedProjected)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                )
            } else {
                return InsightMessagePayload(
                    headline: "\(name) looks like it'll finish around \(formattedProjected).",
                    supportingText: "Based on how this month is going.",
                    emphasis: [.highlight(formattedProjected)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
                )
            }
            
        case .transactionAnomaly(_, _, let name, let amount, _, let multiplier, _):
            let formattedAmount = formatCurrency(amount, symbol: currencySymbol)
            let formattedMult = "\(Int(multiplier))x"
            return InsightMessagePayload(
                headline: "That \(name) charge stands out.",
                supportingText: "\(formattedAmount) is \(formattedMult) your usual for this category.",
                emphasis: [.highlight(formattedAmount), .highlight(formattedMult)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Transaction →") : nil
            )
            
        case .zeroSpendStreak(let streak):
            return InsightMessagePayload(
                headline: "\(daysWord(streak)) with nothing spent.",
                supportingText: "You're in control of the spending.",
                emphasis: [.highlight(daysWord(streak))],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
            )
            
        case .zeroSpendWeekly(let zeroDays):
            return InsightMessagePayload(
                headline: "\(daysWord(zeroDays)) this week with nothing spent.",
                supportingText: "That's a quiet week so far.",
                emphasis: [.highlight(daysWord(zeroDays))],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
            )
            
        case .weekendRhythm(_, _, _, let sharePercent):
            let formattedShare = "\(Int(sharePercent))%"
            return InsightMessagePayload(
                headline: "Weekends are taking more of your spend.",
                supportingText: "\(formattedShare) of it lands on Saturday and Sunday.",
                emphasis: [.highlight(formattedShare)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
            )
            
        case .subscriptionDoubleCharge(_, let name, let count, _):
            let formattedCount = "\(count) charges"
            return InsightMessagePayload(
                headline: "\(name) was charged twice.",
                supportingText: "\(formattedCount) in this cycle.",
                emphasis: [.highlight(name), .highlight(formattedCount)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .subscriptionPriceChange(_, let name, let expected, let actual, let deltaPct):
            let formattedActual = formatCurrency(actual, symbol: currencySymbol)
            let formattedExpected = formatCurrency(expected, symbol: currencySymbol)
            let formattedPct = "\(deltaPct > 0 ? "+" : "")\(Int(deltaPct))%"
            return InsightMessagePayload(
                headline: "\(name) now costs \(formattedActual).",
                supportingText: "It used to be \(formattedExpected) (\(formattedPct)).",
                emphasis: [.highlight(name), .highlight(formattedActual)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .subscriptionOverdue(_, let name, let amount, let daysOverdue):
            let formattedAmount = formatCurrency(amount, symbol: currencySymbol)
            let dueText = daysAgoPhrase(daysOverdue)
            return InsightMessagePayload(
                headline: "\(name) is past due.",
                supportingText: "\(formattedAmount) was \(dueText).",
                emphasis: [.highlight(name), .highlight(formattedAmount)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .subscriptionDue(_, let name, let amount, let daysUntil, _):
            let formattedAmount = formatCurrency(amount, symbol: currencySymbol)
            let dayText: String = {
                if daysUntil <= 0 { return "today" }
                if daysUntil == 1 { return "tomorrow" }
                return "in \(daysWord(daysUntil))"
            }()
            return InsightMessagePayload(
                headline: "\(name) is due \(dayText).",
                supportingText: "\(formattedAmount) comes out then.",
                emphasis: [.highlight(name), .highlight(dayText)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .subscriptionCommitment(let count, let monthly):
            let formattedMonthly = formatCurrency(monthly, symbol: currencySymbol)
            let countText = count == 1 ? "1 subscription" : "\(count) subscriptions"
            return InsightMessagePayload(
                headline: "\(formattedMonthly) a month across your \(countText).",
                supportingText: "That's locked in every month.",
                emphasis: [.highlight(formattedMonthly)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Subscriptions →") : nil
            )
            
        case .incomeShift(_, _, let deltaPercent, let period):
            let formattedPct = "\(Int(abs(deltaPercent)))%"
            let periodWord = period.currentPeriodPhrase
            if deltaPercent > 0 {
                return InsightMessagePayload(
                    headline: "Income came in \(formattedPct) higher \(periodWord).",
                    supportingText: "You earned more than your usual.",
                    emphasis: [.highlight(formattedPct)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Income →") : nil
                )
            } else {
                return InsightMessagePayload(
                    headline: "Income came in \(formattedPct) lower \(periodWord).",
                    supportingText: "You earned less than your usual.",
                    emphasis: [.highlight(formattedPct)],
                    actionTitle: hasDestination ? (candidate.actionTitle ?? "View Income →") : nil
                )
            }
            
        case .incomeDiversification(let count):
            let placeWord = count == 1 ? "1 place" : "\(count) places"
            return InsightMessagePayload(
                headline: "Money is coming in from \(placeWord).",
                supportingText: "You're not tied to a single source.",
                emphasis: [.highlight(placeWord)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Income →") : nil
            )
            
        case .longTermCategoryTrend(_, let name, let months, _, let monthlyAvg, _):
            let formattedAvg = formatCurrency(monthlyAvg, symbol: currencySymbol)
            return InsightMessagePayload(
                headline: "\(name) has been your biggest category for \(months) months.",
                supportingText: "About \(formattedAvg) a month.",
                emphasis: [.highlight(name), .highlight(formattedAvg)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
            
        case .seasonality(let peakMonth, _, _, let multiplier):
            let formattedMult = String(format: "%.1fx", multiplier)
            return InsightMessagePayload(
                headline: "\(peakMonth) is usually your most expensive month.",
                supportingText: "Spending then runs about \(formattedMult) the rest of the year.",
                emphasis: [.highlight(peakMonth), .highlight(formattedMult)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View spending →") : nil
            )
            
        case .subscriptionBudgetImpact(let name, _, let committedTotal, let budgetSharePct):
            let formattedTotal = formatCurrency(committedTotal, symbol: currencySymbol)
            let formattedShare = "\(Int(budgetSharePct))%"
            return InsightMessagePayload(
                headline: "\(name) raised what you pay every month.",
                supportingText: "Subscriptions now total \(formattedTotal) (\(formattedShare) of your budget).",
                emphasis: [.highlight(name), .highlight(formattedTotal)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View Subscriptions →") : nil
            )
            
        case .anomalyDominance(_, let name, let anomalyAmount, let sharePct):
            let formattedAmount = formatCurrency(anomalyAmount, symbol: currencySymbol)
            let formattedShare = "\(Int(sharePct))%"
            return InsightMessagePayload(
                headline: "One \(formattedAmount) charge drove \(name).",
                supportingText: "That's \(formattedShare) of the category.",
                emphasis: [.highlight(formattedAmount), .highlight(name)],
                actionTitle: hasDestination ? (candidate.actionTitle ?? "View \(name) →") : nil
            )
        }
    }
    
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
    
    static func daysWord(_ count: Int) -> String {
        abs(count) == 1 ? "1 day" : "\(count) days"
    }
    
    static func daysAgoPhrase(_ count: Int) -> String {
        if count <= 0 { return "due today" }
        if count == 1 { return "due 1 day ago" }
        return "due \(count) days ago"
    }
}
