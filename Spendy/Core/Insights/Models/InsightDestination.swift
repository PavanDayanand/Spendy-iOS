//
//  InsightDestination.swift
//  Spendy
//
//  Semantic destination targets for interactive moments.
//  Completely decoupled from SwiftUI navigation or routing frameworks.
//

import Foundation

enum InsightDestination: Hashable, Sendable {
    case category(id: String)
    case budget
    case subscriptions
    case subscriptionDetail(id: String)
    case analytics
    case transaction(id: UUID)
}
