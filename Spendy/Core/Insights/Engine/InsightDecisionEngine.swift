//
//  InsightDecisionEngine.swift
//  Spendy
//
//  Contextual decision, scoring, fatigue filtering, compound synthesis, and surface router.
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
        if let customRules = rules {
            self.rules = customRules
        } else {
            self.rules = [
                SpendingVelocityRule(),
                BudgetPacingRule(),
                CategoryTrendRule(),
                CategoryAnomalyRule(),
                BehavioralHabitRule(),
                SubscriptionRule(),
                IncomeRule()
            ]
        }
        self.exposureStore = exposureStore
    }
    
    // MARK: - Primary Public Evaluation API
    
    /// Evaluates facts and produces the best contextual InsightMoments for a given surface
    func evaluate(
        facts: InsightFacts,
        surface: InsightSurface,
        currencySymbol: String = "₹",
        recordExposures: Bool = true,
        now: Date = Date()
    ) -> [InsightMoment] {
        // Data Sufficiency Gate: If facts indicate insufficient general data, return empty state
        guard facts.hasSufficientGeneralData else {
            return [InsightMoment.insufficientData(for: surface)]
        }
        
        let context = InsightEvaluationContext(surface: surface, currencySymbol: currencySymbol, now: now)
        
        // 1. Generate all candidate insights across domain rules
        var allCandidates: [InsightCandidate] = []
        for rule in rules {
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
            return [InsightMoment.insufficientData(for: surface)]
        }
        
        // 3. Filter out fatigued candidates (unless critical or materially changed)
        let eligibleCandidates = surfaceCandidates.filter { candidate in
            let (delta, val) = extractDeltaAndValue(from: candidate)
            let isSuppressed = exposureStore.shouldSuppress(
                semanticId: candidate.semanticKey,
                isCritical: candidate.isCritical,
                currentDelta: delta,
                currentValue: val,
                now: now
            )
            return !isSuppressed
        }
        
        guard !eligibleCandidates.isEmpty else {
            return [InsightMoment.insufficientData(for: surface)]
        }
        
        // 4. Score eligible candidates
        let scoredCandidates: [(candidate: InsightCandidate, score: Double)] = eligibleCandidates.map { candidate in
            let novelty = calculateNovelty(for: candidate.semanticKey)
            let score = (candidate.severity * 0.35)
                      + (candidate.confidence * 0.25)
                      + (candidate.relevance * 0.20)
                      + (novelty * 0.15)
                      + (candidate.actionability * 0.05)
            return (candidate, score)
        }.sorted(by: { $0.score > $1.score })
        
        // 5. Compound Insight Synthesis & Surface Routing
        var moments: [InsightMoment] = []
        
        if surface == .home {
            // Home Surface: Strictly 1 primary moment (or second only if critical)
            if let topCandidate = scoredCandidates.first?.candidate {
                
                // Check if we can synthesize a compound moment with an explanatory driver
                let driverCandidate = scoredCandidates.first(where: {
                    $0.candidate.kind == .explanation &&
                    $0.candidate.family == .category &&
                    $0.candidate.id != topCandidate.id
                })?.candidate
                
                if (topCandidate.family == .budget || topCandidate.family == .spending) && driverCandidate != nil {
                    let compoundPayload = InsightMessageBuilder.buildCompoundMessage(
                        primary: topCandidate,
                        driver: driverCandidate!,
                        currencySymbol: currencySymbol
                    )
                    
                    moments.append(
                        InsightMoment(
                            id: "moment_\(topCandidate.id)_\(driverCandidate!.id)",
                            candidateId: topCandidate.id,
                            kind: topCandidate.kind,
                            family: topCandidate.family,
                            surface: .home,
                            headline: compoundPayload.headline,
                            supportingText: compoundPayload.supportingText,
                            emphasis: compoundPayload.emphasis,
                            destination: topCandidate.destination ?? driverCandidate?.destination
                        )
                    )
                } else {
                    let payload = InsightMessageBuilder.buildMessage(for: topCandidate, currencySymbol: currencySymbol)
                    moments.append(
                        InsightMoment(
                            id: "moment_\(topCandidate.id)",
                            candidateId: topCandidate.id,
                            kind: topCandidate.kind,
                            family: topCandidate.family,
                            surface: .home,
                            headline: payload.headline,
                            supportingText: payload.supportingText,
                            emphasis: payload.emphasis,
                            destination: topCandidate.destination
                        )
                    )
                }
                
                // Check for a secondary critical warning if distinct from the primary
                if let secondaryCritical = scoredCandidates.dropFirst().first(where: {
                    $0.candidate.isCritical && $0.candidate.family != topCandidate.family
                })?.candidate {
                    let secPayload = InsightMessageBuilder.buildMessage(for: secondaryCritical, currencySymbol: currencySymbol)
                    moments.append(
                        InsightMoment(
                            id: "moment_\(secondaryCritical.id)",
                            candidateId: secondaryCritical.id,
                            kind: secondaryCritical.kind,
                            family: secondaryCritical.family,
                            surface: .home,
                            headline: secPayload.headline,
                            supportingText: secPayload.supportingText,
                            emphasis: secPayload.emphasis,
                            destination: secondaryCritical.destination
                        )
                    )
                }
            }
        } else {
            // Category / Budget / Subscriptions / Analytics surfaces: Deduplicate by family and pick top 1-2
            var seenFamilies = Set<InsightFamily>()
            for item in scoredCandidates {
                let candidate = item.candidate
                if !seenFamilies.contains(candidate.family) || surface != .analytics {
                    seenFamilies.insert(candidate.family)
                    let payload = InsightMessageBuilder.buildMessage(for: candidate, currencySymbol: currencySymbol)
                    moments.append(
                        InsightMoment(
                            id: "moment_\(candidate.id)",
                            candidateId: candidate.id,
                            kind: candidate.kind,
                            family: candidate.family,
                            surface: surface,
                            headline: payload.headline,
                            supportingText: payload.supportingText,
                            emphasis: payload.emphasis,
                            destination: candidate.destination
                        )
                    )
                }
                if moments.count >= 2 { break }
            }
        }
        
        // 6. Record exposures if requested
        if recordExposures {
            for moment in moments where !moment.isInsufficientData {
                if let matched = surfaceCandidates.first(where: { $0.id == moment.candidateId }) {
                    let (delta, val) = extractDeltaAndValue(from: matched)
                    exposureStore.recordExposure(
                        semanticId: matched.semanticKey,
                        delta: delta,
                        value: val,
                        now: now
                    )
                }
            }
        }
        
        return moments.isEmpty ? [InsightMoment.insufficientData(for: surface)] : moments
    }
    
    // MARK: - Helpers
    
    private func calculateNovelty(for semanticId: String) -> Double {
        return 0.85
    }
    
    private func extractDeltaAndValue(from candidate: InsightCandidate) -> (delta: Double?, value: Double?) {
        switch candidate.evidence {
        case .spendingVelocity(let cur, _, let deltaPct, _, _):
            return (deltaPct, cur)
        case .budgetPacing(_, let spent, _, let overPace, _, _, _, _):
            return (overPace, spent)
        case .budgetExceeded(_, _, let excess):
            return (100.0, excess)
        case .categoryTrend(_, _, _, _, let deltaAmount, let deltaPct):
            return (deltaPct, deltaAmount)
        case .categoryDriver(_, _, let catInc, _, let sharePct):
            return (sharePct, catInc)
        case .categoryDominance(_, _, let cur, _, let sharePct):
            return (sharePct, cur)
        case .categoryForecast(_, _, _, let proj, _, _):
            return (nil, proj)
        case .transactionAnomaly(_, _, _, let amount, _, let mult, _):
            return (mult * 100.0, amount)
        case .zeroSpendStreak(let streak):
            return (nil, Double(streak))
        case .zeroSpendWeekly(let count):
            return (nil, Double(count))
        case .weekendRhythm(_, _, let ratio, let share):
            return (share, ratio)
        case .subscriptionDoubleCharge(_, _, _, let total):
            return (nil, total)
        case .subscriptionPriceChange(_, _, _, let actual, let deltaPct):
            return (deltaPct, actual)
        case .subscriptionDue(_, _, let amount, _, _):
            return (nil, amount)
        case .subscriptionOverdue(_, _, let amount, _):
            return (nil, amount)
        case .subscriptionCommitment(_, let monthly):
            return (nil, monthly)
        case .incomeShift(let cur, _, let deltaPct):
            return (deltaPct, cur)
        case .incomeDiversification(let count):
            return (nil, Double(count))
        }
    }
}
