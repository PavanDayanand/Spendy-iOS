//
//  SpendyFlowIndicator.swift
//  Spendy
//
//  Reusable Directional Financial Flow Indicator Component
//  Provides standard visual iconography for Outflow (Expenses), Inflow (Income), and Net Cash Flow.
//

import SwiftUI

enum SpendyFlowType: Equatable {
    case expense
    case income
    case net(isPositive: Bool)
    
    var sfSymbol: String {
        switch self {
        case .expense:
            return "arrow.up.right.circle.fill"
        case .income:
            return "arrow.down.left.circle.fill"
        case .net:
            return "equal.circle.fill"
        }
    }
    
    var defaultColor: Color {
        switch self {
        case .expense:
            return SpendyColors.textSecondary
        case .income:
            return SpendyColors.incomeGreen
        case .net(let isPositive):
            return isPositive ? SpendyColors.incomeGreen : SpendyColors.expenseRed
        }
    }
    
    var defaultLabel: String {
        switch self {
        case .expense: return "Expenses"
        case .income: return "Income"
        case .net: return "Net"
        }
    }
}

struct SpendyFlowIndicator: View {
    let type: SpendyFlowType
    var size: CGFloat = 13
    var color: Color? = nil
    var showLabel: Bool = false
    var customLabel: String? = nil
    
    private var effectiveColor: Color {
        color ?? type.defaultColor
    }
    
    private var labelText: String {
        customLabel ?? type.defaultLabel
    }
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: type.sfSymbol)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(effectiveColor)
            
            if showLabel {
                Text(labelText)
                    .font(.system(size: size, weight: .medium))
                    .foregroundStyle(effectiveColor)
            }
        }
    }
}
