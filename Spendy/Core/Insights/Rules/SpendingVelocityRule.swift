//
//  SpendingVelocityRule.swift
//  Spendy
//
//  Evaluates period run-rate velocity and month-end projections vs. baseline.
//

import Foundation

struct SpendingVelocityRule: InsightRule {
    let id = "spending_velocity_rule"
    let family = InsightFamily.spending
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        
        // Data Sufficiency Gate: Minimum 3 elapsed days and at least 3 transactions
        guard !facts.isEarlyPeriod,
              facts.elapsedDays >= 3,
              facts.totalExpenseTxCount >= 3,
              facts.currentSpendTotal > 0,
              facts.baselineSpendTotal > 50.0 else {
            return candidates
        }
        
        let projected = facts.projectedPeriodSpend
        let baseline = facts.baselineSpendTotal
        let deltaPct = ((projected - baseline) / baseline) * 100.0
        
        if projected > baseline * 1.15 {
            // High Spending Velocity / Accelerated Pace
            let evidence = InsightEvidence.spendingVelocity(
                currentSpend: facts.currentSpendTotal,
                baselineSpend: baseline,
                deltaPercent: deltaPct,
                projectedMonthSpend: projected,
                daysElapsed: facts.elapsedDays
            )
            candidates.append(
                InsightCandidate(
                    id: "velocity_high",
                    semanticKey: "velocity_high",
                    family: .spending,
                    kind: .prediction,
                    surfaceAffinity: [.home, .analytics],
                    confidence: 0.85,
                    severity: deltaPct >= 30.0 ? 0.75 : 0.60,
                    relevance: 0.90,
                    actionability: 0.70,
                    evidence: evidence,
                    destination: .analytics,
                    isCritical: false
                )
            )
        } else if projected < baseline * 0.85 {
            // Under Pace / Conservative Spending Trajectory
            let underPct = abs(deltaPct)
            let evidence = InsightEvidence.spendingVelocity(
                currentSpend: facts.currentSpendTotal,
                baselineSpend: baseline,
                deltaPercent: -underPct,
                projectedMonthSpend: projected,
                daysElapsed: facts.elapsedDays
            )
            candidates.append(
                InsightCandidate(
                    id: "velocity_low",
                    semanticKey: "velocity_low",
                    family: .spending,
                    kind: .celebration,
                    surfaceAffinity: [.home, .analytics],
                    confidence: 0.85,
                    severity: 0.15,
                    relevance: 0.80,
                    actionability: 0.30,
                    evidence: evidence,
                    destination: .analytics,
                    isCritical: false
                )
            )
        }
        
        return candidates
    }
}
