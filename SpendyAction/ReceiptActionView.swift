import SwiftUI

struct ReceiptActionView: View {
    let providers: [NSItemProvider]
    let text: String
    let finish: () -> Void
    @State private var payload: ReceiptActionPayload?
    @State private var context: ReceiptShareContext?
    @State private var error: String?

    var body: some View {
        Group {
            if let payload, let context {
                ReceiptReviewView(images: payload.images, categories: context.categories, accounts: context.accounts,
                    currencySymbol: context.currencySymbol, balances: context.balances,
                    sharedText: payload.text, allowsIntelligence: false, onClose: finish,
                    initialAccountId: nil, initialCategoryId: nil,
                    onAddResult: { result in
                        try ReceiptShareStore.enqueueReviewedReceipt(result, sourceData: payload.sourceData, context: context)
                        finish()
                    })
                    .safeAreaInset(edge: .bottom) {
                        Text("Added receipts appear when you next open Spendy.")
                            .font(.footnote).foregroundStyle(.secondary).padding(.bottom, 8)
                    }
            } else if let error {
                ContentUnavailableView {
                    Label("Receipt unavailable", systemImage: "doc.text.magnifyingglass")
                } description: { Text(error) } actions: { Button("Close", action: finish) }
            } else {
                VStack(spacing: 20) {
                    ProgressView("Opening receipt…")
                    Button("Cancel", action: finish)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SpendyColors.appBackground)
        .environment(\.isMonoIconMode, true)
        .tint(.primary)
        .task {
            do {
                let context = try ReceiptShareStore.context()
                let payload = try await ReceiptActionAttachmentLoader.load(providers, attributedText: text)
                guard !Task.isCancelled else { return }
                self.context = context
                self.payload = payload
            } catch { self.error = error.localizedDescription }
        }
    }
}
