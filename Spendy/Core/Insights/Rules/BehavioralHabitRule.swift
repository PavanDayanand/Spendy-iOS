//
//  BehavioralHabitRule.swift
//  Spendy
//
//  Evaluates zero-spend discipline habits and weekend vs. weekday spending rhythms.
//

import Foundation

struct BehavioralHabitRule: InsightRule {
    let id = "behavioral_habit_rule"
    let family = InsightFamily.behavior
    let supportedPeriods: Set<InsightPeriod> = [.week, .month, .threeMonths, .sixMonths, .custom]
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        
        // 1. Zero-Spend Consecutive Streak
        if facts.zeroSpendStreakDays >= 2 {
            candidates.append(
                InsightCandidate(
                    id: "no_spend_streak_\(context.period.rawValue)",
                    semanticKey: "no_spend_streak",
                    family: .behavior,
                    kind: .celebration,
                    surfaceAffinity: [.home, .analytics],
                    period: context.period,
                    confidence: 0.90,
                    severity: 0.10,
                    relevance: 0.70,
                    actionability: 0.20,
                    materiality: 0.30,
                    evidence: .zeroSpendStreak(streakDays: facts.zeroSpendStreakDays),
                    actionTitle: nil,
                    destination: nil,
                    isCritical: false,
                    canActAsDriver: false
                )
            )
        }
        
        // 2. Rolling 7-day Zero-Spend Days
        if facts.zeroSpendDaysInPastWeek >= 3 && facts.totalExpenseTxCount >= 3 {
            candidates.append(
                InsightCandidate(
                    id: "zero_day_week_\(context.period.rawValue)",
                    semanticKey: "zero_day_week",
                    family: .behavior,
                    kind: .celebration,
                    surfaceAffinity: [.home, .analytics],
                    period: context.period,
                    confidence: 0.90,
                    severity: 0.15,
                    relevance: 0.75,
                    actionability: 0.25,
                    materiality: 0.35,
                    evidence: .zeroSpendWeekly(zeroDaysInWeek: facts.zeroSpendDaysInPastWeek),
                    actionTitle: nil,
                    destination: nil,
                    isCritical: false,
                    canActAsDriver: false
                )
            )
        }
        
        // 3. Weekend Spending Rhythm
        if facts.weekendCount >= 2 && facts.weekdayCount >= 3 {
            let ratio = facts.weekendToWeekdayRatio
            if ratio >= 1.40 || facts.weekendSpendSharePercent >= 55.0 {
                let evidence = InsightEvidence.weekendRhythm(
                    weekendSpend: facts.weekendSpendTotal,
                    weekdaySpend: facts.weekdaySpendTotal,
                    weekendRatio: ratio,
                    weekendSharePercent: facts.weekendSpendSharePercent
                )
                candidates.append(
                    InsightCandidate(
                        id: "weekend_bias_\(context.period.rawValue)",
                        semanticKey: "weekend_bias",
                        family: .behavior,
                        kind: .observation,
                        surfaceAffinity: [.home, .analytics],
                        period: context.period,
                        confidence: facts.dataDensityScore,
                        severity: 0.35,
                        relevance: 0.70,
                        actionability: 0.40,
                        materiality: min(1.0, facts.weekendSpendTotal / 4000.0),
                        evidence: evidence,
                        actionTitle: nil,
                        destination: nil,
                        isCritical: false,
                        canActAsDriver: false
                    )
                )
            }
        }
        
        return candidates
    }
}
