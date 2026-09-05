//
//  AnalyticsOverviewSection.swift
//  Spendy
//
//  Apple HIG Overview Metric List for Account & Category Analytics.
//  Presents key financial velocity and solvency metrics in a clean, minimalist vertical list.
//

import SwiftUI

struct AnalyticsOverviewRow: Identifiable {
    let id: String
    let label: String
    let value: String
    let valueColor: Color
    
    init(label: String, value: String, valueColor: Color = SpendyColors.textPrimary) {
        self.id = label
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
}

struct AnalyticsOverviewSection: View {
    var title: String = "Overview"
    var showTopDivider: Bool = true
    let rows: [AnalyticsOverviewRow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if showTopDivider {
                Divider()
                    .overlay(SpendyColors.separator)
                    .padding(.bottom, 2)
            }
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            VStack(spacing: 18) {
                ForEach(rows) { row in
                    HStack(alignment: .firstTextBaseline) {
                        Text(row.label)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Spacer()
                        
                        Text(row.value)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(row.valueColor)
                    }
                }
            }
        }
    }
}
