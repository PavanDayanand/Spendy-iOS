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
        case extraLarge = "XL"

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
                case .extraLarge:
                    WidgetPreviewCard(title: "Monthly brief · iPad", family: .systemExtraLarge) {
                        SpendyLargeOverviewWidgetView(snapshot: snapshot, previewFamily: .systemExtraLarge)
                    }
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

            WidgetPreviewCard(title: "Budget", family: .systemSmall) {
                SpendyBudgetWidgetView(snapshot: snapshot, previewFamily: .systemSmall)
            }

            WidgetPreviewCard(
                title: snapshot.topCategoryName == "None" ? "Category" : snapshot.topCategoryName,
                family: .systemSmall
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
                SpendyWeekWidgetView(snapshot: snapshot, previewFamily: .systemMedium)
            }

            WidgetPreviewCard(title: "Budget", family: .systemMedium) {
                SpendyBudgetWidgetView(snapshot: snapshot, previewFamily: .systemMedium)
            }

            WidgetPreviewCard(title: "Where it went", family: .systemMedium) {
                SpendyMediumCategoriesWidgetView(snapshot: snapshot)
            }

            WidgetPreviewCard(title: "Quick actions", family: .systemMedium) {
                SpendyQuickActionsWidgetView(snapshot: snapshot, previewFamily: .systemMedium)
            }
        }
    }

    private var largeWidgets: some View {
        VStack(spacing: 16) {
            WidgetPreviewCard(title: "Monthly brief", family: .systemLarge) {
                SpendyLargeOverviewWidgetView(snapshot: snapshot, previewFamily: .systemLarge)
            }
            WidgetPreviewCard(title: "Budget", family: .systemLarge) {
                SpendyBudgetWidgetView(snapshot: snapshot, previewFamily: .systemLarge)
            }
            WidgetPreviewCard(title: "Where it went", family: .systemLarge) {
                SpendyMediumCategoriesWidgetView(previewFamily: .systemLarge, snapshot: snapshot)
            }
        }
    }
}

private struct WidgetPreviewCard<Content: View>: View {
    let title: String
    let family: WidgetFamily
    @ViewBuilder let content: Content

    private var designSize: CGSize {
        switch family {
        case .systemMedium: CGSize(width: 338, height: 158)
        case .systemLarge: CGSize(width: 338, height: 354)
        case .systemExtraLarge: CGSize(width: 715.5, height: 342)
        default: CGSize(width: 158, height: 158)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(SpendyColors.textSecondary)
                .lineLimit(1)

            GeometryReader { geometry in
                content
                    .environment(\.spendyWidgetGlassPreview, true)
                    .frame(width: designSize.width, height: designSize.height)
                    .background(SpendyWidgetPalette.canvas)
                    .clipShape(.rect(cornerRadius: 24))
                    .scaleEffect(geometry.size.width / designSize.width, anchor: .topLeading)
            }
            .aspectRatio(designSize.width / designSize.height, contentMode: .fit)
            .accessibilityElement(children: .contain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
