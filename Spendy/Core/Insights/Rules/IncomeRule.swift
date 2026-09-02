//
//  IncomeRule.swift
//  Spendy
//
//  Evaluates income stability shifts and multi-stream diversification.
//

import Foundation

struct IncomeRule: InsightRule {
    let id = "income_rule"
    let family = InsightFamily.income
    let supportedPeriods: Set<InsightPeriod> = [.month, .threeMonths, .sixMonths, .year, .custom]
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        
        let curIncome = facts.currentIncomeTotal
        let baseIncome = facts.baselineIncomeTotal
        let materiality = min(1.0, abs(curIncome - baseIncome) / 10000.0)
        
        if baseIncome > 0 && curIncome > 0 {
            let deltaPct = ((curIncome - baseIncome) / baseIncome) * 100.0
            
            if deltaPct >= 20.0 {
                candidates.append(
                    InsightCandidate(
                        id: "income_spike_\(context.period.rawValue)",
                        semanticKey: "income_spike",
                        family: .income,
                        kind: .celebration,
                        surfaceAffinity: [.analytics, .home],
                        period: context.period,
                        confidence: 0.85,
                        severity: 0.15,
                        relevance: 0.75,
                        actionability: 0.20,
                        materiality: materiality,
                        evidence: .incomeShift(currentIncome: curIncome, baselineIncome: baseIncome, deltaPercent: deltaPct, period: context.period),
                        actionTitle: nil,
                        destination: nil,
                        isCritical: false,
                        canActAsDriver: false
                    )
                )
            } else if deltaPct <= -20.0 {
                candidates.append(
                    InsightCandidate(
                        id: "income_drop_\(context.period.rawValue)",
                        semanticKey: "income_drop",
                        family: .income,
                        kind: .warning,
                        surfaceAffinity: [.analytics, .home],
                        period: context.period,
                        confidence: 0.85,
                        severity: 0.65,
                        relevance: 0.80,
                        actionability: 0.60,
                        materiality: materiality,
                        evidence: .incomeShift(currentIncome: curIncome, baselineIncome: baseIncome, deltaPercent: deltaPct, period: context.period),
                        actionTitle: nil,
                        destination: nil,
                        isCritical: false,
                        canActAsDriver: false
                    )
                )
            }
        }
        
        if facts.incomeSourceCount >= 3 {
            candidates.append(
                InsightCandidate(
                    id: "income_diversification_\(context.period.rawValue)",
                    semanticKey: "income_diversified",
                    family: .income,
                    kind: .observation,
                    surfaceAffinity: [.analytics],
                    period: context.period,
                    confidence: 0.90,
                    severity: 0.10,
                    relevance: 0.60,
                    actionability: 0.10,
                    materiality: 0.40,
                    evidence: .incomeDiversification(sourceCount: facts.incomeSourceCount),
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
