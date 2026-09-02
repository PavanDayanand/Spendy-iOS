//
//  SubscriptionRule.swift
//  Spendy
//
//  Evaluates recurring subscription commitments, price shifts, double billing, and due dates.
//

import Foundation

struct SubscriptionRule: InsightRule {
    let id = "subscription_rule"
    let family = InsightFamily.subscription
    
    init() {}
    
    func evaluate(facts: InsightFacts, context: InsightEvaluationContext) -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        let now = context.now
        let calendar = Calendar.current
        
        for sub in facts.activeSubscriptions {
            let subId = sub.id.uuidString.lowercased()
            let subTxs = facts.subscriptionExpensesInPeriod.filter {
                $0.subscriptionId?.lowercased() == subId
            }
            
            // 1. Double Billing Detection (Critical)
            if subTxs.count > 1 {
                let totalCharged = subTxs.reduce(0.0) { $0 + $1.amount }
                let evidence = InsightEvidence.subscriptionDoubleCharge(
                    subscriptionId: subId,
                    subscriptionName: sub.name,
                    chargeCount: subTxs.count,
                    totalCharged: totalCharged
                )
                candidates.append(
                    InsightCandidate(
                        id: "sub_double_\(subId)",
                        semanticKey: "sub_double_billing",
                        family: .subscription,
                        kind: .warning,
                        surfaceAffinity: [.home, .subscriptions, .analytics],
                        affectedEntityId: subId,
                        confidence: 1.0,
                        severity: 0.85,
                        relevance: 1.0,
                        actionability: 0.95,
                        evidence: evidence,
                        destination: .subscriptions,
                        isCritical: true
                    )
                )
            }
            
            // 2. Price Change / Creep Detection
            for tx in subTxs {
                if sub.amount > 0 && abs(tx.amount - sub.amount) >= 1.0 {
                    let deltaPct = ((tx.amount - sub.amount) / sub.amount) * 100.0
                    let evidence = InsightEvidence.subscriptionPriceChange(
                        subscriptionId: subId,
                        subscriptionName: sub.name,
                        expectedAmount: sub.amount,
                        actualAmount: tx.amount,
                        deltaPercent: deltaPct
                    )
                    candidates.append(
                        InsightCandidate(
                            id: "sub_price_\(subId)",
                            semanticKey: "sub_price_change",
                            family: .subscription,
                            kind: .warning,
                            surfaceAffinity: [.subscriptions, .analytics],
                            affectedEntityId: subId,
                            confidence: 1.0,
                            severity: 0.65,
                            relevance: 0.85,
                            actionability: 0.80,
                            evidence: evidence,
                            destination: .subscriptions,
                            isCritical: false
                        )
                    )
                }
            }
            
            // 3. Billing Date Alerts (Overdue vs. Upcoming)
            let daysUntil = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: sub.nextBillingDate)).day ?? 999
            
            if daysUntil <= 0 && daysUntil >= -7 {
                // Overdue (Critical)
                let evidence = InsightEvidence.subscriptionOverdue(
                    subscriptionId: subId,
                    subscriptionName: sub.name,
                    amount: sub.amount,
                    daysOverdue: abs(daysUntil)
                )
                candidates.append(
                    InsightCandidate(
                        id: "sub_overdue_\(subId)",
                        semanticKey: "sub_overdue",
                        family: .subscription,
                        kind: .warning,
                        surfaceAffinity: [.home, .subscriptions],
                        affectedEntityId: subId,
                        confidence: 1.0,
                        severity: 0.90,
                        relevance: 0.95,
                        actionability: 0.90,
                        evidence: evidence,
                        destination: .subscriptions,
                        isCritical: true
                    )
                )
            } else if daysUntil > 0 && daysUntil <= 3 {
                // Upcoming Due in 1-3 Days
                let evidence = InsightEvidence.subscriptionDue(
                    subscriptionId: subId,
                    subscriptionName: sub.name,
                    amount: sub.amount,
                    daysUntilDue: daysUntil,
                    dueDate: sub.nextBillingDate
                )
                candidates.append(
                    InsightCandidate(
                        id: "sub_due_\(subId)",
                        semanticKey: "sub_upcoming_due",
                        family: .subscription,
                        kind: .observation,
                        surfaceAffinity: [.home, .subscriptions],
                        affectedEntityId: subId,
                        confidence: 1.0,
                        severity: 0.45,
                        relevance: 0.85,
                        actionability: 0.70,
                        evidence: evidence,
                        destination: .subscriptions,
                        isCritical: false
                    )
                )
            }
        }
        
        // 4. Committed Subscription Total Overview
        if facts.activeSubscriptions.count >= 2 && facts.totalMonthlySubscriptionCommitted > 0 {
            let evidence = InsightEvidence.subscriptionCommitment(
                activeCount: facts.activeSubscriptions.count,
                monthlyCommitted: facts.totalMonthlySubscriptionCommitted
            )
            candidates.append(
                InsightCandidate(
                    id: "sub_commitment_overview",
                    semanticKey: "sub_commitment_overview",
                    family: .subscription,
                    kind: .observation,
                    surfaceAffinity: [.subscriptions],
                    confidence: 1.0,
                    severity: 0.20,
                    relevance: 0.60,
                    actionability: 0.30,
                    evidence: evidence,
                    destination: .subscriptions,
                    isCritical: false
                )
            )
        }
        
        return candidates
    }
}
