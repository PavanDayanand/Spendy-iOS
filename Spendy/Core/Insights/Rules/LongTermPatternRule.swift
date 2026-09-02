//
//  LongTermPatternRule.swift
//  Spendy
//
//  Evaluates multi-month sustained category trends, quarterly shifts, and annual seasonality patterns.
//

import Foundation

struct LongTermPatternRule: InsightRule {
    let id = "long_term_pattern_rule"
    let family = InsightFamily.spending
    let supportedPeriods: Set<InsightPeriod> = [.threeMonths, .sixMonths, .year, .all, .custom]
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        guard facts.hasSufficientMultiMonthData else { return candidates }
        
        // 1. Annual Seasonality & Peak Month (1Y / All)
        if (context.period == .year || context.period == .all),
           let highest = facts.highestHistoricalMonth,
           facts.averageMonthlySpendPastYear > 0 {
            
            let multiplier = highest.total / facts.averageMonthlySpendPastYear
            if multiplier >= 1.35 && highest.total >= 500.0 {
                let evidence = InsightEvidence.seasonality(
                    peakMonthName: highest.name,
                    peakMonthSpend: highest.total,
                    averageMonthSpend: facts.averageMonthlySpendPastYear,
                    multiplier: multiplier
                )
                
                candidates.append(
                    InsightCandidate(
                        id: "seasonality_peak_\(highest.name.lowercased())",
                        semanticKey: "seasonality_peak",
                        family: .spending,
                        kind: .observation,
                        surfaceAffinity: [.home, .analytics],
                        period: context.period,
                        confidence: 0.90,
                        severity: 0.35,
                        relevance: 0.85,
                        actionability: 0.40,
                        materiality: min(1.0, highest.total / 10000.0),
                        evidence: evidence,
                        actionTitle: nil,
                        destination: nil,
                        isCritical: false,
                        canActAsDriver: false
                    )
                )
            }
        }
        
        // 2. Multi-Month Category Shifts (3M)
        if context.period == .threeMonths {
            if let topCat = facts.topSpendingCategory, topCat.currentSharePercent >= 35.0, topCat.currentSpend >= 500.0 {
                let monthlyAvg = topCat.currentSpend / 3.0
                let evidence = InsightEvidence.longTermCategoryTrend(
                    categoryId: topCat.categoryId,
                    categoryName: topCat.categoryName,
                    monthsCount: 3,
                    direction: "largest",
                    monthlyAverage: monthlyAvg,
                    totalSpend: topCat.currentSpend
                )
                
                candidates.append(
                    InsightCandidate(
                        id: "long_term_top_\(topCat.categoryId)",
                        semanticKey: "long_term_category_shift",
                        family: .category,
                        kind: .observation,
                        surfaceAffinity: [.home, .analytics, .category(id: topCat.categoryId)],
                        affectedEntityId: topCat.categoryId,
                        period: context.period,
                        confidence: 0.88,
                        severity: 0.30,
                        relevance: 0.85,
                        actionability: 0.45,
                        materiality: min(1.0, topCat.currentSpend / 5000.0),
                        evidence: evidence,
                        actionTitle: "View \(topCat.categoryName) →",
                        destination: .category(id: topCat.categoryId),
                        isCritical: false,
                        canActAsDriver: false
                    )
                )
            }
        }
        
        return candidates
    }
}
