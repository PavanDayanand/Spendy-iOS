//
//  EditorialInsightMomentView.swift
//  Spendy
//
//  Quiet, integrated Apple-like editorial presentation view for semantic Insight Moments.
//  Replaces the large card carousel with a calm, typographic financial observation.
//

import SwiftUI

struct EditorialInsightMomentView: View {
    let moment: InsightMoment
    var onSelectDestination: ((InsightDestination) -> Void)? = nil
    
    init(
        moment: InsightMoment,
        onSelectDestination: ((InsightDestination) -> Void)? = nil
    ) {
        self.moment = moment
        self.onSelectDestination = onSelectDestination
    }
    
    var body: some View {
        Group {
            if moment.isInsufficientData {
                // Canonical Empty / Insufficient Data State
                VStack(alignment: .leading, spacing: 10) {
                    Text("Insights")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text("Add more transactions to unlock personalised insights")
                        .font(.system(size: 13.5, weight: .regular))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            } else {
                // Active Semantic Insight Moment
                Button(action: {
                    if let dest = moment.destination {
                        HapticsManager.shared.trigger(.selection)
                        onSelectDestination?(dest)
                    }
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 6) {
                            Text("Insights")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(SpendyColors.textTertiary)
                            
                            Spacer()
                            
                            if moment.destination != nil {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(SpendyColors.textTertiary)
                            }
                        }
                        
                        Text(moment.headline)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let supporting = moment.supportingText {
                            Text(supporting)
                                .font(.system(size: 13.5, weight: .medium))
                                .foregroundStyle(SpendyColors.textSecondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .fill(SpendyColors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                                    .stroke(SpendyColors.separator, lineWidth: 0.8)
                            }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
