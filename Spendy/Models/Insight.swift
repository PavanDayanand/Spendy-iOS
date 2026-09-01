//
//  Insight.swift
//  Spendy
//
//  Data model for dynamic behavioral insights.
//

import SwiftUI

struct Insight: Identifiable, Hashable {
    var id: String
    var family: String
    var scope: String
    var personaFit: [String]
    var confidence: Double
    var severity: Double
    var eligibility: Bool
    
    // UI details
    var title: String
    var value: String
    var desc: String
    var icon: String
    var colorHex: String
    var categoryId: String? = nil
    
    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Insight Card View Model (Unified 175x188pt Card Data)
struct InsightCardViewModel: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let value: String
    let subtitle: String
    var tagText: String? = nil
    var tagColor: Color? = nil
    var categoryId: String? = nil
    var family: String = "general"
    var isSpotlight: Bool = false
    var peakDayIndex: Int? = nil
}
