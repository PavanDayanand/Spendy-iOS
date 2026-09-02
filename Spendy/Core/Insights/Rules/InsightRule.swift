//
//  InsightRule.swift
//  Spendy
//
//  Protocol defining a modular, testable domain rule evaluator.
//

import Foundation

struct InsightEvaluationContext: Sendable {
    let surface: InsightSurface
    let currencySymbol: String
    let now: Date
    
    init(
        surface: InsightSurface,
        currencySymbol: String = "₹",
        now: Date = Date()
    ) {
        self.surface = surface
        self.currencySymbol = currencySymbol
        self.now = now
    }
}

protocol InsightRule: Sendable {
    var id: String { get }
    var family: InsightFamily { get }
    
    func evaluate(
        facts: InsightFacts,
        context: InsightEvaluationContext
    ) -> [InsightCandidate]
}
