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
    let supportedPeriods: Set<InsightPeriod> = [.week, .month, .threeMonths, .sixMonths, .custom]
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        
        // Data Sufficiency Gate: At least 2 transactions and baseline history
        guard !facts.isEarlyPeriod,
              facts.totalExpenseTxCount >= 2,
              facts.currentSpendTotal > 0,
              facts.baselineSpendTotal > 50.0 else {
            return candidates
        }
        
        let projected = facts.projectedPeriodSpend
        let baseline = facts.baselineSpendTotal
        let deltaPct = ((projected - baseline) / baseline) * 100.0
        let absoluteDelta = abs(projected - baseline)
        let materiality = min(1.0, absoluteDelta / 5000.0) // Scaled financial significance
        
        if projected > baseline * 1.15 {
            // High Spending Velocity / Accelerated Pace
            let evidence = InsightEvidence.spendingVelocity(
                currentSpend: facts.currentSpendTotal,
                baselineSpend: baseline,
                deltaPercent: deltaPct,
                projectedMonthSpend: projected,
                daysElapsed: facts.elapsedDays,
                period: context.period
            )
            candidates.append(
                InsightCandidate(
                    id: "velocity_high_\(context.period.rawValue)",
                    semanticKey: "velocity_high",
                    family: .spending,
                    kind: .prediction,
                    surfaceAffinity: [.home, .analytics],
                    period: context.period,
                    confidence: 0.85,
                    severity: deltaPct >= 30.0 ? 0.75 : 0.60,
                    relevance: 0.90,
                    actionability: 0.70,
                    materiality: materiality,
                    evidence: evidence,
                    actionTitle: nil,
                    destination: nil,
                    isCritical: false,
                    canActAsDriver: false
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
                daysElapsed: facts.elapsedDays,
                period: context.period
            )
            candidates.append(
                InsightCandidate(
                    id: "velocity_low_\(context.period.rawValue)",
                    semanticKey: "velocity_low",
                    family: .spending,
                    kind: .celebration,
                    surfaceAffinity: [.home, .analytics],
                    period: context.period,
                    confidence: 0.85,
                    severity: 0.15,
                    relevance: 0.80,
                    actionability: 0.30,
                    materiality: materiality,
                    evidence: evidence,
                    actionTitle: nil,
                    destination: nil,
                    isCritical: false,
                    canActAsDriver: false
                )
            )
        }
        
        return candidates
    }
}
