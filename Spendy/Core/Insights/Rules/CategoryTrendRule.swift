//
//  CategoryTrendRule.swift
//  Spendy
//
//  Evaluates category surges, reductions, primary spending drivers, dominance, and forecasts.
//

import Foundation

struct CategoryTrendRule: InsightRule {
    let id = "category_trend_rule"
    let family = InsightFamily.category
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        guard facts.hasSufficientGeneralData else { return candidates }
        
        let totalSpend = facts.currentSpendTotal
        let totalBaseline = facts.baselineSpendTotal
        let isOverallSpendUp = totalSpend > totalBaseline && totalBaseline > 0
        let overallIncrease = totalSpend - totalBaseline
        
        for summary in facts.categorySummaries.values {
            let catId = summary.categoryId
            let catName = summary.categoryName
            let curSpend = summary.currentSpend
            let baseSpend = summary.baselineSpend
            let delta = summary.deltaSpend
            let deltaPct = summary.deltaPercent
            let txCount = summary.txCount
            
            // 1. Savings Win / Spend Reduction
            if baseSpend >= 50.0 && deltaPct <= -20.0 && abs(delta) >= 100.0 {
                let evidence = InsightEvidence.categoryTrend(
                    categoryId: catId,
                    categoryName: catName,
                    currentAmount: curSpend,
                    baselineAmount: baseSpend,
                    deltaAmount: delta,
                    deltaPercent: deltaPct
                )
                candidates.append(
                    InsightCandidate(
                        id: "cat_savings_\(catId)",
                        semanticKey: "cat_savings",
                        family: .category,
                        kind: .celebration,
                        surfaceAffinity: [.home, .category(id: catId), .analytics],
                        affectedEntityId: catId,
                        confidence: 0.85,
                        severity: 0.20,
                        relevance: 0.80,
                        actionability: 0.30,
                        evidence: evidence,
                        destination: .category(id: catId),
                        isCritical: false
                    )
                )
            }
            
            // 2. Spend Surge Alert
            if baseSpend >= 50.0 && deltaPct >= 25.0 && delta >= 150.0 {
                let evidence = InsightEvidence.categoryTrend(
                    categoryId: catId,
                    categoryName: catName,
                    currentAmount: curSpend,
                    baselineAmount: baseSpend,
                    deltaAmount: delta,
                    deltaPercent: deltaPct
                )
                candidates.append(
                    InsightCandidate(
                        id: "cat_surge_\(catId)",
                        semanticKey: "cat_surge",
                        family: .category,
                        kind: .warning,
                        surfaceAffinity: [.home, .category(id: catId), .analytics],
                        affectedEntityId: catId,
                        confidence: 0.85,
                        severity: 0.65,
                        relevance: 0.85,
                        actionability: 0.70,
                        evidence: evidence,
                        destination: .category(id: catId),
                        isCritical: false
                    )
                )
            }
            
            // 3. Primary Spending Driver (Explanatory)
            if isOverallSpendUp && delta >= 200.0 && overallIncrease > 0 {
                let driverShare = (delta / overallIncrease) * 100.0
                if driverShare >= 45.0 {
                    let evidence = InsightEvidence.categoryDriver(
                        categoryId: catId,
                        categoryName: catName,
                        categoryIncrease: delta,
                        totalIncrease: overallIncrease,
                        driverSharePercent: driverShare
                    )
                    candidates.append(
                        InsightCandidate(
                            id: "cat_driver_\(catId)",
                            semanticKey: "cat_driver",
                            family: .category,
                            kind: .explanation,
                            surfaceAffinity: [.home, .analytics, .category(id: catId)],
                            affectedEntityId: catId,
                            confidence: 0.88,
                            severity: 0.60,
                            relevance: 0.90,
                            actionability: 0.60,
                            evidence: evidence,
                            destination: .category(id: catId),
                            isCritical: false
                        )
                    )
                }
            }
            
            // 4. Category Dominance (Only when >= 4 txs to avoid single transaction early-month bias)
            if txCount >= 4 && summary.currentSharePercent >= 40.0 && curSpend >= 250.0 {
                let evidence = InsightEvidence.categoryDominance(
                    categoryId: catId,
                    categoryName: catName,
                    categorySpend: curSpend,
                    totalSpend: totalSpend,
                    sharePercent: summary.currentSharePercent
                )
                candidates.append(
                    InsightCandidate(
                        id: "cat_dominance_\(catId)",
                        semanticKey: "cat_dominance",
                        family: .category,
                        kind: .observation,
                        surfaceAffinity: [.category(id: catId), .analytics],
                        affectedEntityId: catId,
                        confidence: 0.80,
                        severity: 0.40,
                        relevance: 0.75,
                        actionability: 0.40,
                        evidence: evidence,
                        destination: .category(id: catId),
                        isCritical: false
                    )
                )
            }
            
            // 5. Category Run-Rate Forecast (Unlocked at >= 5 txs and >= 3 elapsed days)
            if txCount >= 5 && facts.elapsedDays >= 3 && curSpend > 0 {
                let dailyRate = curSpend / Double(facts.elapsedDays)
                let projected = dailyRate * Double(facts.totalDaysInCycle)
                let isSurging = baseSpend > 0 ? (projected > baseSpend * 1.20) : false
                
                let evidence = InsightEvidence.categoryForecast(
                    categoryId: catId,
                    categoryName: catName,
                    currentSpend: curSpend,
                    projectedSpend: projected,
                    baselineSpend: baseSpend,
                    isSurging: isSurging
                )
                candidates.append(
                    InsightCandidate(
                        id: "cat_forecast_\(catId)",
                        semanticKey: "cat_forecast",
                        family: .category,
                        kind: .prediction,
                        surfaceAffinity: [.category(id: catId), .analytics],
                        affectedEntityId: catId,
                        confidence: 0.85,
                        severity: isSurging ? 0.60 : 0.30,
                        relevance: 0.80,
                        actionability: 0.50,
                        evidence: evidence,
                        destination: .category(id: catId),
                        isCritical: false
                    )
                )
            }
        }
        
        return candidates
    }
}
