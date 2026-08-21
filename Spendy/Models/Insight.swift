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
