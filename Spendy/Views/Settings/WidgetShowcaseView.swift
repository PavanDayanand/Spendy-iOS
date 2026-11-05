//
//  WidgetShowcaseView.swift
//  Spendy
//
//  Native-size, interactive gallery for Home Screen widgets.
//

import SwiftUI

struct WidgetShowcaseView: View {
    @Environment(ExpenseStore.self) private var store
    @State private var snapshot: SpendyWidgetSnapshot = .preview
    @State private var selectedFamily: WidgetPreviewGallery.Family = .small

    var body: some View {
        ZStack {
            SpendyColors.settingsBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Widgets that feel like Spendy")
                            .font(.title2.bold())
                            .foregroundStyle(SpendyColors.textPrimary)

                        Text("Your spending, at a glance. Choose a size, then add your favourite to the Home Screen.")
                            .font(.subheadline)
                            .foregroundStyle(SpendyColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    WidgetPreviewGallery(
                        snapshot: snapshot,
                        selectedFamily: $selectedFamily
                    )

                    WidgetSetupGuide()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Widgets")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            WidgetDataManager.shared.publish(from: store)
            snapshot = WidgetDataManager.shared.loadSnapshot()
        }
    }
}
