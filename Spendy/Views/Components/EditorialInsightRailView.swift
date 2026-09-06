//
//  EditorialInsightRailView.swift
//  Spendy
//
//  Stable "Insights" section anchor with ephemeral, dynamic insight moments.
//  Enforces a strict maximum of 3 moments, fixed 136pt canonical height, and restrained transitions.
//

import SwiftUI

struct EditorialInsightRailView: View {
    let moments: [InsightMoment]
    var showSectionHeader: Bool = true
    var onSelectDestination: ((InsightDestination) -> Void)? = nil
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Filter to at most 3 non-empty moments
    private var validMoments: [InsightMoment] {
        Array(moments.prefix(5))
    }
    
    private var cardTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        } else {
            return .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                removal: .opacity
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Stable "Insights" Header Anchor (Always present and visually calm)
            if showSectionHeader {
                HStack(alignment: .center) {
                    SpendyInsightBrandMark(style: .header)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // 2. Ephemeral Dynamic Content Container
            ZStack(alignment: .leading) {
                if validMoments.isEmpty || (validMoments.count == 1 && validMoments.first?.isInsufficientData == true) {
                    // Canonical Single Empty State (Full-Width, Fixed 136pt Height)
                    if let first = validMoments.first {
                        EditorialInsightMomentView(
                            moment: first,
                            widthMode: .fullWidth,
                            onSelectDestination: onSelectDestination
                        )
                        .transition(cardTransition)
                    } else {
                        EditorialInsightMomentView(
                            moment: .insufficientData(for: .home),
                            widthMode: .fullWidth,
                            onSelectDestination: onSelectDestination
                        )
                        .transition(cardTransition)
                    }
                } else if validMoments.count == 1, let first = validMoments.first {
                    // Single High-Utility Moment (Full-Width, Fixed 136pt Height)
                    EditorialInsightMomentView(
                        moment: first,
                        widthMode: .fullWidth,
                        onSelectDestination: onSelectDestination
                    )
                    .transition(cardTransition)
                } else {
                    // Horizontal Editorial Rail (Strictly 2 or 3 Ranked Half-Width Moments)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(validMoments) { moment in
                                EditorialInsightMomentView(
                                    moment: moment,
                                    widthMode: .halfWidth,
                                    onSelectDestination: onSelectDestination
                                )
                                .transition(cardTransition)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: validMoments.map { $0.id })
        }
    }
}
