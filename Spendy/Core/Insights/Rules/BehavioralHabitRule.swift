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
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        
        // 1. Zero-Spend Consecutive Streak
        if facts.zeroSpendStreakDays >= 2 {
            candidates.append(
                InsightCandidate(
                    id: "no_spend_streak",
                    semanticKey: "no_spend_streak",
                    family: .behavior,
                    kind: .celebration,
                    surfaceAffinity: [.home, .analytics],
                    confidence: 0.90,
                    severity: 0.10,
                    relevance: 0.70,
                    actionability: 0.20,
                    evidence: .zeroSpendStreak(streakDays: facts.zeroSpendStreakDays),
                    destination: .analytics,
                    isCritical: false
                )
            )
        }
        
        // 2. Rolling 7-day Zero-Spend Days
        if facts.zeroSpendDaysInPastWeek >= 3 && facts.totalExpenseTxCount >= 3 {
            candidates.append(
                InsightCandidate(
                    id: "zero_day_week",
                    semanticKey: "zero_day_week",
                    family: .behavior,
                    kind: .celebration,
                    surfaceAffinity: [.home, .analytics],
                    confidence: 0.90,
                    severity: 0.15,
                    relevance: 0.75,
                    actionability: 0.25,
                    evidence: .zeroSpendWeekly(zeroDaysInWeek: facts.zeroSpendDaysInPastWeek),
                    destination: .analytics,
                    isCritical: false
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
                        id: "weekend_bias",
                        semanticKey: "weekend_bias",
                        family: .behavior,
                        kind: .observation,
                        surfaceAffinity: [.home, .analytics],
                        confidence: facts.dataDensityScore,
                        severity: 0.35,
                        relevance: 0.70,
                        actionability: 0.40,
                        evidence: evidence,
                        destination: .analytics,
                        isCritical: false
                    )
                )
            }
        }
        
        return candidates
    }
}
