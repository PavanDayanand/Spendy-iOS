import SwiftUI

/// First-use guidance scoped to the receipt button in Add Transaction.
struct ReceiptScanIntroductionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Close", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Close receipt introduction")
                Spacer()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "doc.text.viewfinder")
                            .font(.largeTitle)
                            .accessibilityHidden(true)
                        Text("Scan receipts")
                            .font(.title.bold())
                    }
                    explanation("Read an image", symbol: "doc.text.magnifyingglass",
                        text: "Read the amount, date, and note from a receipt or payment screenshot using Camera, Photos, or a copied image.")
                    explanation("Apple Intelligence, when available", symbol: "sparkles",
                        text: "On supported devices, Apple Intelligence can help with unclear amounts when available. Scanning also works without it.")
                    explanation("Review before adding", symbol: "checkmark.circle",
                        text: "Scanning is still in development and can make mistakes. Check and correct the details before adding a transaction.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)

            Button("Continue", action: onContinue)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
                .buttonStyle(.glass)
                .accessibilityIdentifier("receipt-introduction-continue")
        }
        .padding(24)
        .foregroundStyle(SpendyColors.textPrimary)
        .presentationDetents([.height(610), .large])
        .presentationDragIndicator(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("receipt-scan-introduction")
    }

    private func explanation(_ title: String, symbol: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(SpendyColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
