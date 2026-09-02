//
//  InsightKind.swift
//  Spendy
//
//  Semantic classifications for deterministic intelligence moments.
//

import Foundation

enum InsightKind: String, Codable, Sendable, CaseIterable {
    case observation     // Direct observation of an active pattern or rhythm
    case explanation     // Identification of the root cause or primary driver
    case comparison      // Period-over-period or baseline delta
    case prediction      // Forward-looking run-rate or month-end projection
    case warning         // Action-required risk (budget exhaustion, over-burn, overdue)
    case celebration     // Positive financial discipline or milestone
    case recommendation  // Safe daily allowance or pacing guidance
    case anomaly         // Statistical outlier transaction or unexpected billing
}
