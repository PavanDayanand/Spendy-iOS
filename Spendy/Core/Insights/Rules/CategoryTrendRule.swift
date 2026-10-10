//
//  CategoryTrendRule.swift
//  Spendy
//
//  Evaluates category surges, reductions, primary spending drivers, dominance, and forecasts across timeframes.
//

import Foundation

struct CategoryTrendRule: InsightRule {
    let id = "category_trend_rule"
    let family = InsightFamily.category
    let supportedPeriods: Set<InsightPeriod> = [.week, .month, .threeMonths, .sixMonths, .year, .all, .custom]
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        guard facts.hasSufficientGeneralData else { return candidates }
        
        let totalSpend = facts.currentSpendTotal
        let totalBaseline = InsightComparison.baselineSpending(facts: facts)
        let isOverallSpendUp = totalSpend > totalBaseline && totalBaseline > 0
        let overallIncrease = totalSpend - totalBaseline
        
        // Adaptive minimum transaction threshold per timeframe
        let minTxThreshold: Int = {
            switch context.period {
            case .week, .custom: return 1
            case .month: return 2
            case .threeMonths, .sixMonths: return 3
            case .year, .all: return 4
            }
        }()
        
        let targetSummaries: [CategoryFactSummary] = {
            if case .category(let scopedId) = facts.context.scope {
                if let summary = facts.categorySummaries[scopedId] {
                    return [summary]
                }
                return []
            }
            return Array(facts.categorySummaries.values)
        }()
        
        for summary in targetSummaries {
            guard summary.txCount >= minTxThreshold else { continue }
            
            let catId = summary.categoryId
            let catName = summary.categoryName
            let curSpend = summary.currentSpend
            let baseSpend = InsightComparison.baselineSpending(facts: facts, categoryID: catId)
            let delta = curSpend - baseSpend
            let deltaPct = baseSpend > 0 ? delta / baseSpend * 100 : 0
            let txCount = summary.txCount
            let materiality = min(1.0, abs(delta) / 3000.0)
            
            // 1. Savings Win / Spend Reduction
            if baseSpend >= 50.0 && deltaPct <= -20.0 && abs(delta) >= 100.0 {
                let evidence = InsightEvidence.categoryTrend(
                    categoryId: catId,
                    categoryName: catName,
                    currentAmount: curSpend,
                    baselineAmount: baseSpend,
                    deltaAmount: delta,
                    deltaPercent: deltaPct,
                    period: context.period
                )
                candidates.append(
                    InsightCandidate(
                        id: "cat_savings_\(catId)_\(context.period.rawValue)",
                        semanticKey: "cat_savings",
                        family: .category,
                        kind: .celebration,
                        surfaceAffinity: [.home, .category(id: catId), .analytics],
                        affectedEntityId: catId,
                        period: context.period,
                        confidence: 0.85,
                        severity: 0.20,
                        relevance: 0.80,
                        actionability: 0.40,
                        materiality: materiality,
                        evidence: evidence,
                        actionTitle: "View \(catName) →",
                        destination: .category(id: catId),
                        isCritical: false,
                        canActAsDriver: false
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
                    deltaPercent: deltaPct,
                    period: context.period
                )
                candidates.append(
                    InsightCandidate(
                        id: "cat_surge_\(catId)_\(context.period.rawValue)",
                        semanticKey: "cat_surge",
                        family: .category,
                        kind: .warning,
                        surfaceAffinity: [.home, .category(id: catId), .analytics],
                        affectedEntityId: catId,
                        period: context.period,
                        confidence: 0.85,
                        severity: 0.65,
                        relevance: 0.85,
                        actionability: 0.70,
                        materiality: materiality,
                        evidence: evidence,
                        actionTitle: "View \(catName) →",
                        destination: .category(id: catId),
                        isCritical: false,
                        canActAsDriver: false
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
                        driverSharePercent: driverShare,
                        period: context.period
                    )
                    candidates.append(
                        InsightCandidate(
                            id: "cat_driver_\(catId)_\(context.period.rawValue)",
                            semanticKey: "cat_driver",
                            family: .category,
                            kind: .explanation,
                            surfaceAffinity: [.home, .analytics],
                            affectedEntityId: catId,
                            period: context.period,
                            confidence: 0.90,
                            severity: 0.65,
                            relevance: 0.95,
                            actionability: 0.70,
                            materiality: materiality,
                            evidence: evidence,
                            actionTitle: "View \(catName) →",
                            destination: .category(id: catId),
                            isCritical: false,
                            canActAsDriver: true
                        )
                    )
                }
            }
            
            // 4. Category Dominance (Only when >= minTxThreshold and share >= 40%)
            if facts.context.scope != .category(id: catId) && summary.currentSharePercent >= 40.0 && curSpend >= 250.0 {
                let evidence = InsightEvidence.categoryDominance(
                    categoryId: catId,
                    categoryName: catName,
                    categorySpend: curSpend,
                    totalSpend: totalSpend,
                    sharePercent: summary.currentSharePercent,
                    period: context.period
                )
                candidates.append(
                    InsightCandidate(
                        id: "cat_dominance_\(catId)_\(context.period.rawValue)",
                        semanticKey: "cat_dominance",
                        family: .category,
                        kind: .observation,
                        surfaceAffinity: [.home, .analytics],
                        affectedEntityId: catId,
                        period: context.period,
                        confidence: 0.80,
                        severity: 0.40,
                        relevance: 0.75,
                        actionability: 0.40,
                        materiality: materiality,
                        evidence: evidence,
                        actionTitle: "View \(catName) →",
                        destination: .category(id: catId),
                        isCritical: false,
                        canActAsDriver: false
                    )
                )
            }
            
            // 5. Category Run-Rate Forecast (Active for monthly pacing when >= 5 txs and >= 3 elapsed days)
            if facts.isPeriodInProgress && context.period == .month && txCount >= 5 && facts.elapsedDays >= 3 && curSpend > 0 {
                let dailyRate = curSpend / Double(facts.elapsedDays)
                let projected = dailyRate * Double(facts.totalDaysInCycle)
                let isSurging = summary.baselineSpend > 0 ? (projected > summary.baselineSpend * 1.20) : false
                
                let evidence = InsightEvidence.categoryForecast(
                    categoryId: catId,
                    categoryName: catName,
                    currentSpend: curSpend,
                    projectedSpend: projected,
                    baselineSpend: summary.baselineSpend,
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
                        period: context.period,
                        confidence: 0.85,
                        severity: isSurging ? 0.60 : 0.30,
                        relevance: 0.80,
                        actionability: 0.50,
                        materiality: materiality,
                        evidence: evidence,
                        actionTitle: "View \(catName) →",
                        destination: .category(id: catId),
                        isCritical: false,
                        canActAsDriver: false
                    )
                )
            }
        }
        
        return candidates
    }
}
