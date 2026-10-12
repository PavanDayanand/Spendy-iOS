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
    case highlight(String) // Important token to receive subtle shiny highlight
}

struct InsightMoment: Identifiable, Hashable, Sendable {
    let id: String
    let candidateId: String
    let kind: InsightKind
    let family: InsightFamily
    let surface: InsightSurface
    let period: InsightPeriod
    
    // Human-authored editorial copy
    let headline: String
    let supportingText: String?
    
    // Semantic emphasis points
    let emphasis: [InsightEmphasis]
    
    // Actionable Callout & Semantic Target
    let actionTitle: String?
    let destination: InsightDestination?
    
    // Insufficient data flag
    let isInsufficientData: Bool
    let attentionPriority: Int
    let attentionLabel: String?
    
    init(
        id: String,
        candidateId: String,
        kind: InsightKind,
        family: InsightFamily,
        surface: InsightSurface,
        period: InsightPeriod = .month,
        headline: String,
        supportingText: String? = nil,
        emphasis: [InsightEmphasis] = [],
        actionTitle: String? = nil,
        destination: InsightDestination? = nil,
        isInsufficientData: Bool = false,
        attentionPriority: Int = 0,
        attentionLabel: String? = nil
    ) {
        self.id = id
        self.candidateId = candidateId
        self.kind = kind
        self.family = family
        self.surface = surface
        self.period = period
        self.headline = headline
        self.supportingText = supportingText
        self.emphasis = emphasis
        self.actionTitle = actionTitle
        self.destination = destination
        self.isInsufficientData = isInsufficientData
        self.attentionPriority = attentionPriority
        self.attentionLabel = attentionLabel
    }
    
    /// Canonical empty / insufficient data moment
    static func insufficientData(for surface: InsightSurface, period: InsightPeriod = .month) -> InsightMoment {
        InsightMoment(
            id: "insufficient_data_\(surface.rawIdentifier)_\(period.rawValue)",
            candidateId: "insufficient_data",
            kind: .observation,
            family: .spending,
            surface: surface,
            period: period,
            headline: "Insights",
            supportingText: "Add more transactions to unlock personalised insights",
            emphasis: [],
            actionTitle: nil,
            destination: nil,
            isInsufficientData: true
        )
    }
}
