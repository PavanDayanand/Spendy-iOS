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
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        
        let curIncome = facts.currentIncomeTotal
        let baseIncome = facts.baselineIncomeTotal
        
        if baseIncome > 0 && curIncome > 0 {
            let deltaPct = ((curIncome - baseIncome) / baseIncome) * 100.0
            
            if deltaPct >= 20.0 {
                candidates.append(
                    InsightCandidate(
                        id: "income_spike",
                        semanticKey: "income_spike",
                        family: .income,
                        kind: .celebration,
                        surfaceAffinity: [.analytics],
                        confidence: 0.85,
                        severity: 0.15,
                        relevance: 0.75,
                        actionability: 0.20,
                        evidence: .incomeShift(currentIncome: curIncome, baselineIncome: baseIncome, deltaPercent: deltaPct),
                        destination: .analytics,
                        isCritical: false
                    )
                )
            } else if deltaPct <= -20.0 {
                candidates.append(
                    InsightCandidate(
                        id: "income_drop",
                        semanticKey: "income_drop",
                        family: .income,
                        kind: .warning,
                        surfaceAffinity: [.analytics],
                        confidence: 0.85,
                        severity: 0.65,
                        relevance: 0.80,
                        actionability: 0.60,
                        evidence: .incomeShift(currentIncome: curIncome, baselineIncome: baseIncome, deltaPercent: deltaPct),
                        destination: .analytics,
                        isCritical: false
                    )
                )
            }
        }
        
        if facts.incomeSourceCount >= 3 {
            candidates.append(
                InsightCandidate(
                    id: "income_diversification",
                    semanticKey: "income_diversified",
                    family: .income,
                    kind: .observation,
                    surfaceAffinity: [.analytics],
                    confidence: 0.90,
                    severity: 0.10,
                    relevance: 0.60,
                    actionability: 0.10,
                    evidence: .incomeDiversification(sourceCount: facts.incomeSourceCount),
                    destination: .analytics,
                    isCritical: false
                )
            )
        }
        
        return candidates
    }
}
