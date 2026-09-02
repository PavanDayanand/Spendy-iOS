//
//  BudgetPacingRule.swift
//  Spendy
//
//  Evaluates budget adherence, exhaustion date risk, over-burn rate, and recovery allowance.
//

import Foundation

struct BudgetPacingRule: InsightRule {
    let id = "budget_pacing_rule"
    let family = InsightFamily.budget
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        guard facts.hasActiveBudget, facts.budgetLimit > 0 else { return candidates }
        
        let limit = facts.budgetLimit
        let spent = facts.budgetCycleExpenses
        let pctSpent = facts.budgetPercentSpent
        let overPace = facts.budgetOverPacePercent
        
        // 1. Budget Exceeded (Critical)
        if pctSpent >= 100.0 {
            let excess = spent - limit
            candidates.append(
                InsightCandidate(
                    id: "budget_exceeded",
                    semanticKey: "budget_exceeded",
                    family: .budget,
                    kind: .warning,
                    surfaceAffinity: [.home, .budget, .analytics],
                    confidence: 1.0,
                    severity: 1.0,
                    relevance: 1.0,
                    actionability: 0.90,
                    evidence: .budgetExceeded(limit: limit, spent: spent, excessAmount: excess),
                    destination: .budget,
                    isCritical: true
                )
            )
            return candidates
        }
        
        // 2. Budget Exhaustion Risk (Critical)
        if let daysToExhaust = facts.budgetDaysToExhaustion,
           daysToExhaust < facts.totalDaysInCycle,
           let exhaustionDate = facts.budgetExhaustionDate,
           facts.elapsedDays >= 3 {
            
            let evidence = InsightEvidence.budgetPacing(
                limit: limit,
                spent: spent,
                percentSpent: pctSpent,
                overPacePercent: overPace,
                daysToExhaustion: daysToExhaust,
                exhaustionDate: exhaustionDate,
                safeDailyRemaining: facts.budgetSafeDailyRemaining,
                daysRemaining: facts.remainingDays
            )
            candidates.append(
                InsightCandidate(
                    id: "budget_exhaustion_risk",
                    semanticKey: "budget_exhaustion_risk",
                    family: .budget,
                    kind: .warning,
                    surfaceAffinity: [.home, .budget, .analytics],
                    confidence: 0.92,
                    severity: 0.88,
                    relevance: 0.95,
                    actionability: 0.85,
                    evidence: evidence,
                    destination: .budget,
                    isCritical: true
                )
            )
        }
        
        // 3. High Burn Rate Alert
        if overPace > 12.0 && facts.elapsedDays >= 2 {
            let evidence = InsightEvidence.budgetPacing(
                limit: limit,
                spent: spent,
                percentSpent: pctSpent,
                overPacePercent: overPace,
                daysToExhaustion: facts.budgetDaysToExhaustion ?? facts.totalDaysInCycle,
                exhaustionDate: facts.budgetExhaustionDate,
                safeDailyRemaining: facts.budgetSafeDailyRemaining,
                daysRemaining: facts.remainingDays
            )
            candidates.append(
                InsightCandidate(
                    id: "budget_burn_rate",
                    semanticKey: "budget_burn_rate",
                    family: .budget,
                    kind: .warning,
                    surfaceAffinity: [.home, .budget],
                    confidence: 0.88,
                    severity: 0.70,
                    relevance: 0.85,
                    actionability: 0.75,
                    evidence: evidence,
                    destination: .budget,
                    isCritical: false
                )
            )
        }
        
        // 4. Safe Daily Allowance Guidance
        if overPace > 5.0 && facts.remainingDays > 0 && facts.budgetSafeDailyRemaining > 0 {
            let evidence = InsightEvidence.budgetPacing(
                limit: limit,
                spent: spent,
                percentSpent: pctSpent,
                overPacePercent: overPace,
                daysToExhaustion: facts.budgetDaysToExhaustion ?? facts.totalDaysInCycle,
                exhaustionDate: facts.budgetExhaustionDate,
                safeDailyRemaining: facts.budgetSafeDailyRemaining,
                daysRemaining: facts.remainingDays
            )
            candidates.append(
                InsightCandidate(
                    id: "budget_safe_allowance",
                    semanticKey: "budget_safe_allowance",
                    family: .budget,
                    kind: .recommendation,
                    surfaceAffinity: [.budget, .home],
                    confidence: 0.85,
                    severity: 0.50,
                    relevance: 0.80,
                    actionability: 0.90,
                    evidence: evidence,
                    destination: .budget,
                    isCritical: false
                )
            )
        }
        
        // 5. Positive Pacing (On Track)
        if overPace <= 0.0 && pctSpent >= 20.0 {
            let evidence = InsightEvidence.budgetPacing(
                limit: limit,
                spent: spent,
                percentSpent: pctSpent,
                overPacePercent: overPace,
                daysToExhaustion: facts.budgetDaysToExhaustion ?? facts.totalDaysInCycle,
                exhaustionDate: facts.budgetExhaustionDate,
                safeDailyRemaining: facts.budgetSafeDailyRemaining,
                daysRemaining: facts.remainingDays
            )
            candidates.append(
                InsightCandidate(
                    id: "budget_on_track",
                    semanticKey: "budget_on_track",
                    family: .budget,
                    kind: .celebration,
                    surfaceAffinity: [.budget, .home],
                    confidence: 0.82,
                    severity: 0.15,
                    relevance: 0.65,
                    actionability: 0.20,
                    evidence: evidence,
                    destination: .budget,
                    isCritical: false
                )
            )
        }
        
        return candidates
    }
}
