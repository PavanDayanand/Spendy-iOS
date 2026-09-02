//
//  InsightRule.swift
//  Spendy
//
//  Protocol defining a modular, testable domain rule evaluator with Period Capability Matrix support.
//

import Foundation

struct InsightEvaluationContext: Sendable {
    let surface: InsightSurface
    let period: InsightPeriod
    let currencySymbol: String
    let now: Date
    
    init(
        surface: InsightSurface,
        period: InsightPeriod = .month,
        currencySymbol: String = "₹",
        now: Date = Date()
    ) {
        self.surface = surface
        self.period = period
        self.currencySymbol = currencySymbol
        self.now = now
    }
}

protocol InsightRule: Sendable {
    var id: String { get }
    var family: InsightFamily { get }
    var supportedPeriods: Set<InsightPeriod> { get }
    
    func evaluate(
        facts: InsightFacts,
        context: InsightEvaluationContext
    ) -> [InsightCandidate]
}
