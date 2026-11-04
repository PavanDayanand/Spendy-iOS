//
//  WidgetPreviewGallery.swift
//  Spendy
//

import SwiftUI
import WidgetKit

struct WidgetPreviewGallery: View {
    enum Family: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"

        var id: Self { self }
    }

    let snapshot: SpendyWidgetSnapshot
    @Binding var selectedFamily: Family

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 18) {
            Picker("Widget size", selection: $selectedFamily) {
                ForEach(Family.allCases) { family in
                    Text(family.rawValue).tag(family)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("widget-family-picker")

            Group {
                switch selectedFamily {
                case .small:
                    smallWidgets
                case .medium:
                    mediumWidgets
                case .large:
                    largeWidgets
                }
            }
            .id(selectedFamily)
            .transition(
                reduceMotion
                    ? .opacity
                    : .asymmetric(
                        insertion: .scale(scale: 0.97).combined(with: .opacity),
                        removal: .opacity
                    )
            )
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.18) : AppMotion.fluidSpring, value: selectedFamily)
        .sensoryFeedback(.selection, trigger: selectedFamily)
    }

    private var smallWidgets: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            WidgetPreviewCard(title: "Today", family: .systemSmall) {
                SpendySmallWidgetView(snapshot: snapshot)
            }

            WidgetPreviewCard(title: "Budget", family: .systemSmall, tint: Color(hex: "#FF9500")) {
                SpendyBudgetWidgetView(snapshot: snapshot, previewFamily: .systemSmall)
            }

            WidgetPreviewCard(
                title: snapshot.topCategoryName == "None" ? "Category" : snapshot.topCategoryName,
                family: .systemSmall,
                tint: Color(hex: snapshot.topCategoryColorHex)
            ) {
                SpendyCategoryFocusView(snapshot: snapshot, category: nil, previewFamily: .systemSmall)
            }

            WidgetPreviewCard(title: "Quick actions", family: .systemSmall) {
                SpendyQuickActionsWidgetView(snapshot: snapshot, previewFamily: .systemSmall)
            }
        }
    }

    private var mediumWidgets: some View {
        VStack(spacing: 16) {
            WidgetPreviewCard(title: "Spending pulse", family: .systemMedium) {
                SpendyMediumWeekWidgetView(snapshot: snapshot)
            }

            WidgetPreviewCard(title: "Where it went", family: .systemMedium, tint: Color(hex: snapshot.topCategoryColorHex)) {
                SpendyMediumCategoriesWidgetView(snapshot: snapshot)
            }

            WidgetPreviewCard(title: "Quick actions", family: .systemMedium) {
                SpendyQuickActionsWidgetView(snapshot: snapshot, previewFamily: .systemMedium)
            }
        }
    }

    private var largeWidgets: some View {
        WidgetPreviewCard(title: "Monthly brief", family: .systemLarge, tint: Color(hex: snapshot.topCategoryColorHex)) {
            SpendyLargeOverviewWidgetView(snapshot: snapshot)
        }
    }
}

private struct WidgetPreviewCard<Content: View>: View {
    let title: String
    let family: WidgetFamily
    var tint: Color? = nil
    @ViewBuilder let content: Content

    private var aspectRatio: CGFloat {
        switch family {
        case .systemMedium:
            2.13
        default:
            1
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(SpendyColors.textSecondary)
                .lineLimit(1)

            content
                .environment(\.spendyWidgetGlassPreview, true)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipShape(.rect(cornerRadius: 24))
                .contentShape(.rect(cornerRadius: 24))
                .nativeLiquidGlass(cornerRadius: 24, isInteractive: true, tint: tint?.opacity(0.18))
                .accessibilityElement(children: .contain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
