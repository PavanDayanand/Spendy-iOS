//
//  CategoryCard.swift
//  Spendy
//
//  Dedicated Category Widget Card (Compact & Focused)
//  Features:
//  - Compact 156pt height with squircle corners (22pt radius)
//  - Top: 42×42pt solid vibrant circular icon badge with soft glow
//  - Just below icon: Category Name (Semibold)
//  - Open middle spacing
//  - Bottom: Formatted spend amount + 2-line wrapped subtitle (moved one step up)
//

import SwiftUI

struct CategoryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            HapticsManager.shared.trigger(.selection)
            action?()
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Top: Circular Icon Badge with Subtle Glow
                Circle()
                    .fill(color)
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: color.opacity(0.35), radius: 5, x: 0, y: 2.5)
                
                Spacer().frame(height: 10)
                
                // 2. Just below icon: Category Name
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                // 3. Middle: Open Space
                Spacer(minLength: 10)
                
                // 4. Bottom: Spend Amount + 2-Line Subtitle (Moved one step up)
                VStack(alignment: .leading, spacing: 2) {
                    if !value.isEmpty {
                        Text(value)
                            .spendyNumberFont(size: 19, weight: .bold, tracking: -0.4)
                            .foregroundStyle(SpendyColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 11.5, weight: .regular))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.80)
                }
                .padding(.bottom, 2)
            }
            .padding(14)
            .frame(minHeight: 156, maxHeight: 156, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(.plain)
        ._onButtonGesture { pressing in
            isPressed = pressing
        } perform: {}
        .accessibilityLabel("\(title), \(value), \(subtitle)")
    }
}

#Preview {
    ZStack {
        SpendyColors.appBackground.ignoresSafeArea()
        
        HStack(spacing: 12) {
            CategoryCard(
                title: "Subscriptions",
                value: "₹17,782",
                subtitle: "4 active · Monthly committed",
                icon: "repeat.circle.fill",
                color: .purple
            )
            
            CategoryCard(
                title: "Food delivery",
                value: "$21,144",
                subtitle: "3 expenses this month",
                icon: "pizza.fill",
                color: .orange
            )
        }
        .padding(16)
    }
    .preferredColorScheme(.dark)
}
