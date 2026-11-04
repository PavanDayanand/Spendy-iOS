//
//  WidgetSetupGuide.swift
//  Spendy
//

import SwiftUI

struct WidgetSetupGuide: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add one to your Home Screen")
                .font(.headline.bold())
                .foregroundStyle(SpendyColors.textPrimary)

            step(number: 1, title: "Touch and hold", detail: "Press an empty area until your apps jiggle.")
            step(number: 2, title: "Tap Add (+)", detail: "Open the widget gallery and choose Spendy.")
            step(number: 3, title: "Pick a size", detail: "Choose the layout that fits your Home Screen.")
            step(number: 4, title: "Make it yours", detail: "Edit Today to focus on a budget, week, or category.")
        }
        .padding(18)
        .nativeLiquidGlass(cornerRadius: 24)
    }

    private func step(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number.formatted())
                .font(.subheadline.bold())
                .foregroundStyle(SpendyColors.textPrimary)
                .frame(width: 30, height: 30)
                .nativeLiquidGlassCircle(isInteractive: false)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(SpendyColors.textPrimary)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
