//
//  SpendyExpandingSegmentedControl.swift
//  Spendy
//
//  Compact monochrome switcher with equal-width, always-visible labels.
//

import SwiftUI

// MARK: - Shared Compact Segmented Control
// Existing call sites retain their API; every option now stays labeled.
struct SpendyExpandingSegmentedControl<T: Hashable & Identifiable>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.spendySelectionFill) private var selectionFill
    @Environment(\.spendySelectionForeground) private var selectionForeground
    @Binding var selection: T
    let items: [T]
    var titleFor: (T) -> String
    var iconFor: (T) -> String
    var onSelect: ((T) -> Void)? = nil
    @Namespace private var selectionAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isSelected = selection == item
                Button {
                    guard selection != item else { return }
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        selection = item
                        onSelect?(item)
                    }
                    HapticsManager.shared.trigger(.selection)
                } label: {
                    Text(titleFor(item))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? selectionForeground : SpendyColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(selectionFill)
                                    .padding(.vertical, 4)
                                    .matchedGeometryEffect(id: "selection", in: selectionAnimation)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(titleFor(item))
                .accessibilityAddTraits(isSelected ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: CGFloat(items.count) * 80 + 8)
        .frame(height: 44)
        .background {
            Capsule()
                .fill(SpendyColors.transactionControlSurface)
                .overlay {
                    Capsule().stroke(SpendyColors.separator, lineWidth: 0.8)
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
