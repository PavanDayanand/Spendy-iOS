//
//  LiquidMeshBackground.swift
//  Spendy
//
//  Adaptive edge-to-edge ambient header gradient background matching Category and Account sheets.
//

import SwiftUI

struct LiquidMeshBackground: View {
    @Environment(ExpenseStore.self) private var store
    
    enum Style {
        case screen
        case sheet
    }
    
    var color: Color? = nil
    var style: Style = .screen
    var height: CGFloat? = nil
    var opacity: Double = 0.38
    
    private var effectiveHeight: CGFloat {
        if let height = height { return height }
        return style == .sheet ? 380 : 580
    }
    
    private var ambientColor: Color {
        if let color = color { return color }
        if let hex = store.profileColorHex, !hex.isEmpty {
            return Color(hex: hex)
        }
        if !store.topGradientColorHex.isEmpty {
            return Color(hex: store.topGradientColorHex)
        }
        return Color(hex: "#007AFF")
    }
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            SpendyAmbientHeaderBackground(
                color: ambientColor,
                height: effectiveHeight,
                opacity: opacity
            )
        }
        .ignoresSafeArea()
    }
}
