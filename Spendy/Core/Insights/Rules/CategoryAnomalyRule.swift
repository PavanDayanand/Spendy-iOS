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
                        confidence: 0.90,
                        severity: multiplier >= 5.0 ? 0.85 : 0.70,
                        relevance: 0.90,
                        actionability: 0.80,
                        evidence: evidence,
                        destination: .category(id: catId),
                        isCritical: multiplier >= 5.0 // Severe outliers bypass fatigue
                    )
                )
            }
        }
        
        return candidates
    }
}
