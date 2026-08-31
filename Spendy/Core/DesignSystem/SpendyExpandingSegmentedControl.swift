//
//  SpendyExpandingSegmentedControl.swift
//  Spendy
//
//  Original Pixel-Perfect Expanding Capsule Type Switcher
//  Restored directly from commit 800293beedaaf070ee8c18bec37820548fd10def
//  Supports both SF Symbols (e.g. arrow icons) and Letter Badges (e.g. "M", "W").
//

import SwiftUI

// MARK: - Generic Expanding Segmented Control
struct SpendyExpandingSegmentedControl<T: Hashable & Identifiable>: View {
    @Binding var selection: T
    let items: [T]
    var titleFor: (T) -> String
    var iconFor: (T) -> String
    var onSelect: ((T) -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(items) { item in
                let isSelected = selection == item
                let iconKey = iconFor(item)
                let isLetterBadge = iconKey.count == 1
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selection = item
                        onSelect?(item)
                    }
                    HapticsManager.shared.trigger(.selection)
                }) {
                    if isSelected {
                        // Selected Tab: Elevated dark capsule with white circular badge containing black symbol/letter + bold text
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 24, height: 24)
                                
                                if isLetterBadge {
                                    Text(iconKey)
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(Color.black)
                                } else {
                                    Image(systemName: iconKey)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.black)
                                }
                            }
                            
                            Text(titleFor(item))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background {
                            Capsule()
                                .fill(Color(hex: "#242426"))
                                .overlay {
                                    Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                                }
                        }
                        .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // Unselected Tab: Circular disc with icon or letter only (36x36)
                        ZStack {
                            if isLetterBadge {
                                Text(iconKey)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.65))
                            } else {
                                Image(systemName: iconKey)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.white.opacity(0.65))
                            }
                        }
                        .frame(width: 36, height: 36)
                        .background {
                            Circle()
                                .fill(Color(hex: "#101012"))
                                .overlay {
                                    Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                                }
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(height: 44)
        .background {
            Capsule()
                .fill(Color(hex: "#18181A"))
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
}

// MARK: - Specialized Transaction Type Expanding Toggle
struct SpendyTransactionTypeToggle: View {
    @Binding var selection: TransactionType
    var availableTypes: [TransactionType] = [.expense, .income, .transfer]
    var onSelect: ((TransactionType) -> Void)? = nil
    
    var body: some View {
        SpendyExpandingSegmentedControl(
            selection: $selection,
            items: availableTypes,
            titleFor: { $0.title },
            iconFor: { type in
                switch type {
                case .expense: return "arrow.up.right"
                case .income: return "arrow.down.left"
                case .transfer: return "arrow.left.and.right"
                }
            },
            onSelect: onSelect
        )
    }
}

// MARK: - Specialized Budget Period Expanding Toggle
struct SpendyBudgetPeriodToggle: View {
    @Binding var selection: BudgetPeriod
    var availablePeriods: [BudgetPeriod] = [.monthly, .weekly]
    var onSelect: ((BudgetPeriod) -> Void)? = nil
    
    var body: some View {
        SpendyExpandingSegmentedControl(
            selection: $selection,
            items: availablePeriods,
            titleFor: { $0.title },
            iconFor: { period in
                switch period {
                case .monthly: return "M"
                case .weekly: return "W"
                }
            },
            onSelect: onSelect
        )
    }
}

// MARK: - Previews
#Preview("Expanding Type Switcher - 3 Items") {
    struct PreviewWrapper: View {
        @State private var type: TransactionType = .expense
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    SpendyTransactionTypeToggle(selection: $type)
                    
                    Text("Selected: \(type.title)")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
                .padding()
            }
        }
    }
    
    return PreviewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Budget Period Switcher - M & W") {
    struct BudgetPreviewWrapper: View {
        @State private var period: BudgetPeriod = .monthly
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    SpendyBudgetPeriodToggle(selection: $period)
                    
                    Text("Selected: \(period.title)")
                        .foregroundStyle(.white)
                        .font(.headline)
                }
                .padding()
            }
        }
    }
    
    return BudgetPreviewWrapper()
        .preferredColorScheme(.dark)
}
