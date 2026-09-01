//
//  InsightCardGrid.swift
//  Spendy
//
//  Standardized 2-column responsive grid container for Polymorphic Insight Cards
//

import SwiftUI

struct InsightCardGrid<Content: View>: View {
    var spacing: CGFloat = 12
    @ViewBuilder var content: () -> Content
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content()
        }
    }
}
