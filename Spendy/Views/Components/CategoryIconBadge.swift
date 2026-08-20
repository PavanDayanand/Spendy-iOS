//
//  CategoryIconBadge.swift
//  Spendy
//
//  Vibrant Icon Badge with SF Symbol and Glowing Tint (No Emojis)
//

import SwiftUI

struct CategoryIconBadge: View {
    enum Size {
        case small
        case medium
        case large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 46
            case .large: return 58
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 20
            case .large: return 26
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 15
            case .large: return 18
            }
        }
    }
    
    var sfSymbol: String
    var tintColor: Color
    var size: Size = .medium
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tintColor.opacity(0.35),
                            tintColor.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
                        .stroke(tintColor.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: tintColor.opacity(0.25), radius: 6, x: 0, y: 3)
            
            Image(systemName: SFIcons.symbol(named: sfSymbol))
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundStyle(tintColor)
        }
        .frame(width: size.dimension, height: size.dimension)
    }
}
