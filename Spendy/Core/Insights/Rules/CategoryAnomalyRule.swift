//
//  CategoryAnomalyRule.swift
//  Spendy
//
//  Statistical outlier detection for unusually large transactions within established categories.
//

import Foundation

struct CategoryAnomalyRule: InsightRule {
    let id = "category_anomaly_rule"
    let family = InsightFamily.anomaly
    let supportedPeriods: Set<InsightPeriod> = [.week, .month, .threeMonths, .sixMonths, .year, .all, .custom]
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        
        for summary in facts.categorySummaries.values {
            // Require at least 5 transactions in the category to establish a reliable mean
            guard summary.txCount >= 5, summary.meanTxAmount > 0 else { continue }
            
            let catId = summary.categoryId
            let catName = summary.categoryName
            let mean = summary.meanTxAmount
            let threshold = mean * 3.0
            
            let catTxs = facts.transactions.filter { $0.categoryId == catId }
            let anomalies = catTxs.filter { $0.amount >= threshold && $0.amount >= 150.0 }
            
            for tx in anomalies {
                let multiplier = tx.amount / mean
                let materiality = min(1.0, tx.amount / 5000.0)
                let evidence = InsightEvidence.transactionAnomaly(
                    transactionId: tx.id,
                    categoryId: catId,
                    categoryName: catName,
                    amount: tx.amount,
                    meanAmount: mean,
                    multiplier: multiplier,
                    date: tx.date
                )
                
                candidates.append(
                    InsightCandidate(
                        id: "anomaly_\(catId)_\(tx.id.uuidString.prefix(8))",
                        semanticKey: "transaction_anomaly",
                        family: .anomaly,
                        kind: .anomaly,
                        surfaceAffinity: [.home, .category(id: catId), .analytics],
                        affectedEntityId: catId,
                        period: context.period,
                        confidence: 0.90,
                        severity: multiplier >= 5.0 ? 0.85 : 0.70,
                        relevance: 0.90,
                        actionability: 0.85,
                        materiality: materiality,
                        evidence: evidence,
                        actionTitle: "View Transaction →",
                        destination: .transaction(id: tx.id),
                        isCritical: multiplier >= 5.0,
                        canActAsDriver: false
                    )
                )
            }
        }
        
        return candidates
    }
}
