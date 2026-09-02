//
//  InsightFamily.swift
//  Spendy
//
//  Analytical domain families for grouping and deduplication.
//

import Foundation

enum InsightFamily: String, Codable, Sendable, CaseIterable {
    case spending        // Global spending velocity, run-rate, macro totals
    case budget          // Budget limits, burn rate, pacing, exhaustion
    case category        // Category surges, reductions, drivers, dominance
    case behavior        // Zero-spend habits, weekend/weekday rhythms
    case subscription    // Committed recurring spend, price changes, double billing, due dates
    case income          // Income shifts, multi-stream diversification
    case anomaly         // Statistical transaction outliers
}
