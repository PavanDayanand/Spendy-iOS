//
//  WidgetShowcaseView.swift
//  Spendy
//
//  In-app gallery for Home Screen widgets.
//

import SwiftUI
import WidgetKit

struct WidgetShowcaseView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var snapshot: SpendyWidgetSnapshot = .preview

    var body: some View {
        ZStack {
            SpendyColors.settingsBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Home Screen widgets")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(SpendyColors.textPrimary)

                        Text("A quick read on today, your budget, and the month. Choose the size that fits your Home Screen.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                            .lineSpacing(3)
                    }
                    .padding(.top, 8)

                    HStack(alignment: .top, spacing: 12) {
                        previewCard(title: "Today", badge: "Small") {
                            SpendySmallWidgetView(snapshot: snapshot)
                                .frame(height: 158)
                        }
                        previewCard(title: "Budget room", badge: "Small") {
                            SpendyBudgetWidgetView(snapshot: snapshot, previewFamily: .systemSmall)
                                .frame(height: 158)
                        }
                    }

                    previewCard(title: "Quick actions", badge: "Small · Medium") {
                        SpendyQuickActionsWidgetView(snapshot: snapshot, previewFamily: .systemMedium)
                            .frame(height: 158)
                    }

                    previewCard(title: "Spending Pulse", badge: "Medium") {
                        SpendyMediumWeekWidgetView(snapshot: snapshot)
                            .frame(height: 158)
                    }

                    previewCard(title: "Where It Went", badge: "Medium") {
                        SpendyMediumCategoriesWidgetView(snapshot: snapshot)
                            .frame(height: 158)
                    }

                    previewCard(title: "Monthly Brief", badge: "Large") {
                        SpendyLargeOverviewWidgetView(snapshot: snapshot)
                            .frame(height: 338)
                    }

                    guideCard(title: "Make it yours") {
                        stepRow(number: "1", title: "Touch & hold", detail: "Press an empty area on the Home Screen until apps jiggle.")
                        stepRow(number: "2", title: "Tap Add (+)", detail: "Use the + button in the top-left corner.")
                        stepRow(number: "3", title: "Choose Spendy", detail: "Pick the insight or action layout you want.")
                        stepRow(number: "4", title: "Edit its focus", detail: "Touch and hold Today to choose a budget, seven-day view, or category.")
                    }

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Widgets")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            WidgetDataManager.shared.publish(from: store)
            snapshot = WidgetDataManager.shared.loadSnapshot()
        }
    }

    private func previewCard<Content: View>(title: String, badge: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Text(badge)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            content()
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 1)
                }
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func guideCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(SpendyColors.textPrimary)
            content()
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }

    private func stepRow(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(SpendyColors.chipBackground)
                    .frame(width: 26, height: 26)
                Text(number)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(SpendyColors.textPrimary)
                Text(detail)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineSpacing(2)
            }
        }
    }
}
