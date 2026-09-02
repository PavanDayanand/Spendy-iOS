//
//  InsightMoment.swift
//  Spendy
//
//  Semantic output moment selected by the decision engine for a given surface.
//  Completely presentation-independent.
//

import Foundation

enum InsightEmphasis: Hashable, Sendable {
    case currency(Double)
    case percentage(Double)
    case date(Date)
    case count(Int)
    case text(String)
}

struct InsightMoment: Identifiable, Hashable, Sendable {
    let id: String
    let candidateId: String
    let kind: InsightKind
    let family: InsightFamily
    let surface: InsightSurface
    
    // Human-authored editorial copy
    let headline: String
    let supportingText: String?
    
    // Semantic emphasis points
    let emphasis: [InsightEmphasis]
    
    // Semantic interaction target
    let destination: InsightDestination?
    
    // Insufficient data flag
    let isInsufficientData: Bool
    
    init(
        id: String,
        candidateId: String,
        kind: InsightKind,
        family: InsightFamily,
        surface: InsightSurface,
        headline: String,
        supportingText: String? = nil,
        emphasis: [InsightEmphasis] = [],
        destination: InsightDestination? = nil,
        isInsufficientData: Bool = false
    ) {
        self.id = id
        self.candidateId = candidateId
        self.kind = kind
        self.family = family
        self.surface = surface
        self.headline = headline
        self.supportingText = supportingText
        self.emphasis = emphasis
        self.destination = destination
        self.isInsufficientData = isInsufficientData
    }
    
    /// Canonical empty / insufficient data moment
    static func insufficientData(for surface: InsightSurface) -> InsightMoment {
        InsightMoment(
            id: "insufficient_data_\(surface.rawIdentifier)",
            candidateId: "insufficient_data",
            kind: .observation,
            family: .spending,
            surface: surface,
            headline: "Insights",
            supportingText: "Add more transactions to unlock personalised insights",
            destination: nil,
            isInsufficientData: true
        )
    }
}
