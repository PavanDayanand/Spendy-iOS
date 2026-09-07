//
//  GlassCard.swift
//  Spendy
//
//  Clean Native iOS Grouped Card Container
//

import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 18
    var tintColor: Color? = nil
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(padding)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    if let tint = tintColor {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(0.06))
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
                .spendyCardLift()
        }
    }
}
