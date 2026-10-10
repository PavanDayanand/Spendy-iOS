import Foundation

/// Descriptive facts for a category or account, with no inferred purchases or AI.
struct SpendingDetailRule: InsightRule {
    let id = "spending_details"
    let family = InsightFamily.spending
    let supportedPeriods = Set(InsightPeriod.allCases)

    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        let surfaces: [InsightSurface]
        switch facts.context.scope {
        case .category(let id): surfaces = [.category(id: id)]
        case .account: surfaces = [.analytics]
        case .global: return []
        }
        let expenses = facts.transactions.filter {
            $0.type == .expense && $0.date >= facts.periodStart && $0.date <= min(facts.periodEnd, context.now)
        }
        guard expenses.count >= 3, facts.currentSpendTotal > 0 else { return [] }
        func candidate(_ key: String, evidence: InsightEvidence, destination: InsightDestination? = nil) -> InsightCandidate {
            InsightCandidate(id: "\(key)_\(facts.context.scope.key)", semanticKey: key, family: .spending,
                kind: .observation, surfaceAffinity: surfaces, affectedEntityId: facts.context.scope.key,
                period: context.period, confidence: 1, severity: 0.1, relevance: 0.55,
                actionability: destination == nil ? 0 : 0.5, materiality: 0.2, evidence: evidence, destination: destination)
        }
        var results = [candidate("average_expense", evidence: .averageExpense(
            average: facts.currentSpendTotal / Double(expenses.count), count: expenses.count))]
        if let largest = expenses.sorted(by: { $0.amount == $1.amount ? $0.id.uuidString < $1.id.uuidString : $0.amount > $1.amount }).first {
            results.append(candidate("largest_expense", evidence: .largestExpense(transactionId: largest.id,
                title: largest.title, amount: largest.amount, sharePercent: largest.amount / facts.currentSpendTotal * 100),
                destination: .transaction(id: largest.id)))
        }
        if facts.representedDaysCount >= 2 {
            results.append(candidate("active_spending_days", evidence: .spendingDays(
                activeDays: facts.representedDaysCount, total: facts.currentSpendTotal)))
        }
        return results
    }
}
