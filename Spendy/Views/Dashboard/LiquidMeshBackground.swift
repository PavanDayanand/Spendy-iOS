//
//  LiquidMeshBackground.swift
//  Spendy
//
//  Adaptive monochrome field with subtle liquid depth.
//

import SwiftUI

struct LiquidMeshBackground: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateFlow: Bool = false
    
    enum Style {
        case screen
        case sheet
    }
    
    var style: Style = .screen
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let maxDimension = max(size.width, size.height)
            let primaryRadius = maxDimension * (style == .sheet ? 1.12 : 0.92)
            
            ZStack {
                SpendyColors.appBackground
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()
        }
    }
}
