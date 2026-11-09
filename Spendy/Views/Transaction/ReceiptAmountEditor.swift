import SwiftUI

struct ReceiptAmountEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State var amount: Double
    let currencySymbol: String
    let onSave: (Double) -> Void

    var body: some View {
        NavigationStack {
        VStack(spacing: 20) {
            HStack {
                Text(currencySymbol)
                TextField("Amount", value: $amount, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("receipt-amount-input")
            }
            .font(.title.monospacedDigit())
            .padding(16)
            .background(SpendyColors.cardBackground, in: .rect(cornerRadius: 18))
            Text("Enter the amount in \(currencySymbol).").font(.footnote).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .foregroundStyle(SpendyColors.textPrimary)
        .padding(20)
        .navigationTitle("Amount")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityLabel("Cancel amount changes")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    HapticsManager.shared.trigger(.success)
                    onSave(amount)
                    dismiss()
                }
                .disabled(!amount.isFinite || amount <= 0)
            }
        }
        }
        .tint(SpendyColors.textPrimary)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(280), .large])
        .presentationDragIndicator(.visible)
    }
}
