import SwiftUI

struct InsightsPreferencesView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store
        Group {
            Form {
                Section {
                    Toggle("Spendy Insights", isOn: $store.insightsEnabled)
                } footer: {
                    Text("Useful observations from the spending you record. Calculated on your iPhone, without generative AI or uploading your ledger.")
                }
                Section("What you'll see") {
                    Label { Text("Spending patterns and category changes") } icon: { Image(systemName: "chart.bar").foregroundStyle(SpendyColors.textPrimary) }
                    Label { Text("Budget pace and upcoming bills") } icon: { Image(systemName: "target").foregroundStyle(SpendyColors.textPrimary) }
                    Label { Text("One useful insight at a time") } icon: { Image(systemName: SpendyInsightBrandMark.symbol).foregroundStyle(SpendyColors.textPrimary) }
                }
                Section {
                    Text("Insights appear in Analytics, Budget, subscriptions, and category details. They follow the selected dates and account. Small samples are held back, and forecasts are estimates—not promises.")
                        .font(.subheadline).foregroundStyle(SpendyColors.textSecondary)
                    Text("Turning this off hides insight suggestions. Your charts, transactions, and notification preferences stay available.")
                        .font(.subheadline).foregroundStyle(SpendyColors.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(SpendyColors.settingsBackground)
            .navigationTitle("Spendy Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
        }
        .tint(SpendyColors.controlAccent)
    }
}
