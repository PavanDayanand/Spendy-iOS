//
//  SpendyIconBadge.swift
//  Spendy
//
//  Shared Unified Icon Badge Component for Categories, Subscriptions, and Accounts
//

import SwiftUI

struct SpendyIconBadge: View {
    enum Style {
        case circle
        case rounded(cornerRadius: CGFloat)
    }
    
    enum Size {
        case small    // 36x36
        case medium   // 44x44
        case large    // 56x56
        
        var dimension: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 15
            case .medium: return 18
            case .large: return 24
            }
        }
    }
    
    var sfSymbol: String
    var color: Color
    var size: Size = .medium
    var style: Style = .circle
    var isGradient: Bool = false
    
    var body: some View {
        ZStack {
            switch style {
            case .circle:
                if isGradient {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.35), color.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(Circle().stroke(color.opacity(0.35), lineWidth: 1))
                        .shadow(color: color.opacity(0.25), radius: 4, y: 2)
                } else {
                    Circle()
                        .fill(color)
                }
            case .rounded(let radius):
                if isGradient {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.35), color.opacity(0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(color.opacity(0.35), lineWidth: 1))
                        .shadow(color: color.opacity(0.25), radius: 4, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(color)
                }
            }
            
            Image(systemName: SFIcons.symbol(named: sfSymbol))
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundStyle(isGradient ? color : Color.white)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}
