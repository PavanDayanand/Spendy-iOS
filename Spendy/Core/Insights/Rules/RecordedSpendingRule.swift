import Foundation

struct RecordedSpendingRule: InsightRule {
    let id = "recorded_spending"
    let family = InsightFamily.spending
    let supportedPeriods = Set(InsightPeriod.allCases)

    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        guard facts.totalExpenseTxCount >= 3, facts.currentSpendTotal > 0 else { return [] }
        var surfaces: [InsightSurface] = [.analytics]
        if case .category(let id) = facts.context.scope { surfaces.append(.category(id: id)) }
        return [InsightCandidate(id: "recorded_spending_\(context.period.id)", semanticKey: "recorded_spending",
            family: .spending, kind: .observation, surfaceAffinity: surfaces, period: context.period,
            confidence: 1, severity: 0.1, relevance: 0.5, actionability: 0, materiality: 0.2,
            evidence: .recordedSpending(total: facts.currentSpendTotal, count: facts.totalExpenseTxCount, period: context.period))]
    }
}
