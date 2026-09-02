//
//  InsightSurface.swift
//  Spendy
//
//  Target view surfaces requesting contextual intelligence.
//

import Foundation

enum InsightSurface: Hashable, Sendable {
    case home
    case category(id: String)
    case budget
    case subscriptions
    case analytics
    
    var rawIdentifier: String {
        switch self {
        case .home: return "home"
        case .category(let id): return "category_\(id)"
        case .budget: return "budget"
        case .subscriptions: return "subscriptions"
        case .analytics: return "analytics"
        }
    }
}
