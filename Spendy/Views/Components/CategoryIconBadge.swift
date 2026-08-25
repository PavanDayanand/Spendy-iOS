//
//  CategoryIconBadge.swift
//  Spendy
//
//  Unified Icon Badge with SF Symbol and Vibrant Tint
//

import SwiftUI

struct CategoryIconBadge: View {
    typealias Size = SpendyIconBadge.Size
    typealias Style = SpendyIconBadge.Style
    
    var sfSymbol: String
    var tintColor: Color
    var size: Size = .medium
    var style: Style = .circle
    var isGradient: Bool = false
    
    var body: some View {
        SpendyIconBadge(
            sfSymbol: sfSymbol,
            color: tintColor,
            size: size,
            style: style,
            isGradient: isGradient
        )
    }
}

