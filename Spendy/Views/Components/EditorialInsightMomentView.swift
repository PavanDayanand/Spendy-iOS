//
//  EditorialInsightMomentView.swift
//  Spendy
//
//  Fixed-geometry, Apple-like editorial presentation view for semantic Insight Moments.
//  Enforces canonical 136pt height across both full-width and half-width layouts.
//  Uses normal title casing for kicker/category labels.
//  Renders action links only when a valid, meaningful destination exists.
//

import SwiftUI

enum EditorialInsightWidthMode: Sendable {
    case fullWidth
    case halfWidth
}

struct EditorialInsightMomentView: View {
    let moment: InsightMoment
    var widthMode: EditorialInsightWidthMode = .fullWidth
    var onSelectDestination: ((InsightDestination) -> Void)? = nil
    
    // Canonical Fixed Geometry Metrics
    static let canonicalHeight: CGFloat = 136.0
    static let railCardWidth: CGFloat = 296.0
    static let cardCornerRadius: CGFloat = 20.0
    
    init(
        moment: InsightMoment,
        widthMode: EditorialInsightWidthMode = .fullWidth,
        onSelectDestination: ((InsightDestination) -> Void)? = nil
    ) {
        self.moment = moment
        self.widthMode = widthMode
        self.onSelectDestination = onSelectDestination
    }
    
    var body: some View {
        Group {
            if moment.isInsufficientData {
                // Canonical Empty / Insufficient Data State with Exact Fixed Height
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Overview")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.textTertiary)
                            .tracking(0.3)
                        
                        Spacer()
                    }
                    .padding(.bottom, 6)
                    
                    Text("Insights")
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer(minLength: 4)
                    
                    Text("Add more transactions to unlock personalised insights")
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: widthMode == .fullWidth ? .infinity : Self.railCardWidth, alignment: .leading)
                .frame(height: Self.canonicalHeight)
                .background {
                    RoundedRectangle(cornerRadius: Self.cardCornerRadius, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: Self.cardCornerRadius, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            } else if let destination = moment.destination {
                // Actionable Insight Moment Card (Interactive Button with Deep Destination)
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    onSelectDestination?(destination)
                }) {
                    cardContent(hasDestination: true)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(moment.headline). \(moment.supportingText ?? ""). \(moment.actionTitle ?? "")")
                .accessibilityAddTraits(.isButton)
            } else {
                // Informational Insight Moment Card (Static, No Action Row, No Chevron)
                cardContent(hasDestination: false)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(moment.headline). \(moment.supportingText ?? "")")
            }
        }
    }
    
    // MARK: - Card Content Layout
    @ViewBuilder
    private func cardContent(hasDestination: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Header Tag Row (Normal Title Casing, e.g. "Subscription", "Budget", "Category")
            HStack(alignment: .center, spacing: 6) {
                Text(moment.family.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .tracking(0.3)
                
                Spacer(minLength: 0)
                
                if hasDestination {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
            }
            .padding(.bottom, 6)
            
            // 2. Primary Headline with selective shiny token emphasis
            ShinyHeadlineText(
                headline: moment.headline,
                emphasis: moment.emphasis,
                font: .system(size: 15.5, weight: .semibold),
                emphasisFont: .system(size: 15.5, weight: .bold)
            )
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 4)
            
            // 3. Supporting Text
            if let supporting = moment.supportingText {
                InsightSupportingText(text: supporting, emphasis: moment.emphasis)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            // 4. Action Callout Link (Render ONLY if meaningful destination and action title exist)
            if hasDestination, let action = moment.actionTitle, !action.isEmpty {
                Text(action)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SpendyColors.accentCyan)
                    .padding(.top, 4)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: widthMode == .fullWidth ? .infinity : Self.railCardWidth, alignment: .leading)
        .frame(height: Self.canonicalHeight)
        .background {
            RoundedRectangle(cornerRadius: Self.cardCornerRadius, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: Self.cardCornerRadius, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
}
