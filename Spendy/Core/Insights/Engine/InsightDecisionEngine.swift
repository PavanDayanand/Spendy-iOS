//
//  InsightDecisionEngine.swift
//  Spendy
//
//  Deterministic arbitration engine for Spendy's Smart Insights.
//  Applies materiality weighting, contextual fatigue filtering, deduplication, and compound synthesis.
//  Zero generative models, zero random selection.
//

import Foundation

final class InsightDecisionEngine: Sendable {
    static let shared = InsightDecisionEngine()
    
    private let rules: [any InsightRule]
    private let exposureStore: InsightExposureStore
    
    init(
        rules: [any InsightRule]? = nil,
        exposureStore: InsightExposureStore = .shared
    ) {
        self.rules = rules ?? [
            SpendingVelocityRule(),
            BudgetPacingRule(),
            CategoryTrendRule(),
            CategoryAnomalyRule(),
            BehavioralHabitRule(),
            SubscriptionRule(),
            IncomeRule(),
            LongTermPatternRule()
        ]
        self.exposureStore = exposureStore
    }
    
    // MARK: - Main Evaluation Pipeline
    
    func evaluate(
        facts: InsightFacts,
        surface: InsightSurface,
        period: InsightPeriod? = nil,
        currencySymbol: String = "₹",
        now: Date? = nil,
        recordExposures: Bool = true
    ) -> [InsightMoment] {
        let activePeriod = period ?? facts.context.period
        let activeNow = now ?? facts.context.referenceDate
        
        // Data sufficiency check
        guard facts.hasSufficientGeneralData else {
            return [InsightMoment.insufficientData(for: surface, period: activePeriod)]
        }
        
        let context = InsightEvaluationContext(surface: surface, period: activePeriod, currencySymbol: currencySymbol, now: activeNow)
        
        // 1. Generate all candidate insights across period-supported domain rules
        var allCandidates: [InsightCandidate] = []
        for rule in rules where rule.supportedPeriods.contains(activePeriod) {
            let produced = rule.evaluate(facts: facts, context: context)
            allCandidates.append(contentsOf: produced)
        }
        
        // 2. Filter candidates matching surface affinity
        let surfaceCandidates = allCandidates.filter { candidate in
            switch surface {
            case .home:
                return candidate.surfaceAffinity.contains(.home)
            case .category(let catId):
                return candidate.surfaceAffinity.contains(where: {
                    if case .category(let targetId) = $0 { return targetId == catId }
                    return false
                })
            case .budget:
                return candidate.surfaceAffinity.contains(.budget)
            case .subscriptions:
                return candidate.surfaceAffinity.contains(.subscriptions)
            case .analytics:
                return candidate.surfaceAffinity.contains(.analytics)
            }
        }
        
        guard !surfaceCandidates.isEmpty else {
            return [InsightMoment.insufficientData(for: surface, period: activePeriod)]
        }
        
        // Contextual exposure key helper
        func contextKey(for candidate: InsightCandidate) -> String {
            "\(surface.rawIdentifier):\(candidate.semanticKey):\(facts.context.scope.key):\(facts.context.period.id)"
        }
        
        // 3. Filter out fatigued candidates (unless critical or materially changed)
        let eligibleCandidates = surfaceCandidates.filter { candidate in
            let (delta, val) = extractDeltaAndValue(from: candidate)
            let isSuppressed = exposureStore.shouldSuppress(
                semanticId: contextKey(for: candidate),
                isCritical: candidate.isCritical,
                currentDelta: delta,
                currentValue: val,
                now: activeNow
            )
            return !isSuppressed
        }
        
        guard !eligibleCandidates.isEmpty else {
            return [InsightMoment.insufficientData(for: surface, period: activePeriod)]
        }
        
        // 4. Score eligible candidates with Materiality Weighting & Dynamic Novelty
        let scoredCandidates: [(candidate: InsightCandidate, score: Double)] = eligibleCandidates.map { candidate in
            let (delta, val) = extractDeltaAndValue(from: candidate)
            let novelty = exposureStore.calculateNovelty(for: contextKey(for: candidate), currentDelta: delta, currentValue: val)
            
            // Materiality-Weighted Scoring Formula
            let score = (candidate.severity * 0.30)
                      + (candidate.confidence * 0.25)
                      + (candidate.relevance * 0.20)
                      + (novelty * 0.15)
                      + (candidate.materiality * 0.05)
                      + (candidate.actionability * 0.05)
            
            return (candidate, score)
        }.sorted(by: { $0.score > $1.score })
        
        // 5. Compound Insight Synthesis & Multi-Moment Surface Routing
        var moments: [InsightMoment] = []
        var consumedCandidateIds = Set<String>()
        var seenFamilies = Set<InsightFamily>()
        
        for (candidate, _) in scoredCandidates {
            if consumedCandidateIds.contains(candidate.id) { continue }
            
            // Check for Macro + Driver Compound Pairing
            if (candidate.family == .budget || candidate.family == .spending) && candidate.kind == .warning {
                let driverMatch = scoredCandidates.map { $0.candidate }.first(where: {
                    $0.canActAsDriver && !consumedCandidateIds.contains($0.id)
                })
                
                guard let driver = driverMatch else {
                    // Output individual candidate
                    if !seenFamilies.contains(candidate.family) || candidate.isCritical {
                        seenFamilies.insert(candidate.family)
                        consumedCandidateIds.insert(candidate.id)
                        
                        let payload = InsightMessageBuilder.buildMessage(for: candidate, currencySymbol: currencySymbol)
                        let (effDest, _, isSelfRef) = resolveDestination(candidateDestination: candidate.destination, surface: surface)
                        let effActionTitle = isSelfRef ? nil : payload.actionTitle
                        
                        moments.append(
                            InsightMoment(
                                id: "moment_\(candidate.id)",
                                candidateId: candidate.id,
                                kind: candidate.kind,
                                family: candidate.family,
                                surface: surface,
                                period: activePeriod,
                                headline: payload.headline,
                                supportingText: payload.supportingText,
                                emphasis: payload.emphasis,
                                actionTitle: effActionTitle,
                                destination: effDest
                            )
                        )
                    }
                    continue
                }
                
                // Synthesize Compound Moment
                let compoundPayload = InsightMessageBuilder.buildCompoundMessage(
                    primary: candidate,
                    driver: driver,
                    currencySymbol: currencySymbol
                )
                
                let compoundDest = driver.destination ?? candidate.destination
                let (effCompoundDest, _, isCompoundSelfRef) = resolveDestination(candidateDestination: compoundDest, surface: surface)
                let effCompoundActionTitle = isCompoundSelfRef ? nil : compoundPayload.actionTitle
                
                moments.append(
                    InsightMoment(
                        id: "moment_\(candidate.id)_\(driver.id)",
                        candidateId: candidate.id,
                        kind: candidate.kind,
                        family: candidate.family,
                        surface: surface,
                        period: activePeriod,
                        headline: compoundPayload.headline,
                        supportingText: compoundPayload.supportingText,
                        emphasis: compoundPayload.emphasis,
                        actionTitle: effCompoundActionTitle,
                        destination: effCompoundDest
                    )
                )
                
                consumedCandidateIds.insert(candidate.id)
                consumedCandidateIds.insert(driver.id)
                seenFamilies.insert(candidate.family)
                seenFamilies.insert(driver.family)
                
            } else {
                // Deduplicate by family to avoid redundancy on the rail
                if !seenFamilies.contains(candidate.family) || candidate.isCritical {
                    seenFamilies.insert(candidate.family)
                    consumedCandidateIds.insert(candidate.id)
                    
                    let payload = InsightMessageBuilder.buildMessage(for: candidate, currencySymbol: currencySymbol)
                    let (effDest, _, isSelfRef) = resolveDestination(candidateDestination: candidate.destination, surface: surface)
                    let effActionTitle = isSelfRef ? nil : payload.actionTitle
                    
                    moments.append(
                        InsightMoment(
                            id: "moment_\(candidate.id)",
                            candidateId: candidate.id,
                            kind: candidate.kind,
                            family: candidate.family,
                            surface: surface,
                            period: activePeriod,
                            headline: payload.headline,
                            supportingText: payload.supportingText,
                            emphasis: payload.emphasis,
                            actionTitle: effActionTitle,
                            destination: effDest
                        )
                    )
                }
            }
            
            // Limit rail moments count: Maximum 3 moments for Home/Analytics, 2 for sub-surfaces
            let maxMoments = (surface == .home || surface == .analytics) ? 3 : 2
            if moments.count >= maxMoments { break }
        }
        
        // 6. Record exposures for surfaced moments
        if recordExposures {
            for moment in moments where !moment.isInsufficientData {
                if let matched = surfaceCandidates.first(where: { $0.id == moment.candidateId }) {
                    let (delta, val) = extractDeltaAndValue(from: matched)
                    exposureStore.recordExposure(
                        semanticId: contextKey(for: matched),
                        delta: delta,
                        value: val,
                        now: activeNow
                    )
                }
            }
        }
        
        return moments.isEmpty ? [InsightMoment.insufficientData(for: surface, period: activePeriod)] : moments
    }
    
    // MARK: - Helpers
    
    private func resolveDestination(
        candidateDestination: InsightDestination?,
        surface: InsightSurface
    ) -> (destination: InsightDestination?, actionTitle: String?, isSelfReferential: Bool) {
        guard let dest = candidateDestination else {
            return (nil, nil, false)
        }
        switch (surface, dest) {
        case (.category(let sId), .category(let dId)) where sId == dId:
            return (nil, nil, true)
        case (.budget, .budget):
            return (nil, nil, true)
        case (.subscriptions, .subscriptions):
            return (nil, nil, true)
        case (.analytics, .analytics):
            return (nil, nil, true)
        default:
            return (dest, nil, false)
        }
    }
    
    private func extractDeltaAndValue(from candidate: InsightCandidate) -> (delta: Double, value: Double) {
        switch candidate.evidence {
        case .spendingVelocity(let current, _, let deltaPct, _, _, _):
            return (deltaPct, current)
        case .categoryTrend(_, _, let current, _, _, let deltaPct, _):
            return (deltaPct, current)
        case .categoryDriver(_, _, let inc, _, let share, _):
            return (share, inc)
        case .categoryDominance(_, _, let spend, _, let share, _):
            return (share, spend)
        case .categoryForecast(_, _, let current, _, _, _):
            return (10.0, current)
        case .budgetPacing(_, let spent, _, let overPace, _, _, _, _):
            return (overPace, spent)
        case .budgetExceeded(_, let spent, let excess):
            return (excess, spent)
        case .subscriptionPriceChange(_, _, _, let actual, let deltaPct):
            return (deltaPct, actual)
        case .subscriptionOverdue(_, _, let amount, let days):
            return (Double(days), amount)
        case .subscriptionDue(_, _, let amount, let days, _):
            return (Double(days), amount)
        case .subscriptionDoubleCharge(_, _, _, let totalCharged):
            return (2.0, totalCharged)
        case .subscriptionCommitment(let count, let monthly):
            return (Double(count), monthly)
        case .incomeShift(let current, _, let deltaPct, _):
            return (deltaPct, current)
        case .incomeDiversification(let sourceCount):
            return (Double(sourceCount), Double(sourceCount))
        case .weekendRhythm(let weekend, _, let ratio, _):
            return (ratio, weekend)
        case .zeroSpendStreak(let streak):
            return (Double(streak), Double(streak))
        case .zeroSpendWeekly(let count):
            return (Double(count), Double(count))
        case .transactionAnomaly(_, _, _, let amount, _, let mult, _):
            return (mult, amount)
        case .seasonality(_, let peak, _, let mult):
            return (mult, peak)
        case .longTermCategoryTrend(_, _, _, _, _, let totalSpend):
            return (10.0, totalSpend)
        case .subscriptionBudgetImpact(_, let inc, _, let share):
            return (share, inc)
        case .anomalyDominance(_, _, let anomalyAmount, let share):
            return (share, anomalyAmount)
        }
    }
}
