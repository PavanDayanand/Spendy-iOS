#if DEBUG
import SwiftUI

/// An isolated UI-test source for the mixed payload shown by payment apps.
struct ReceiptActionTestHost: View {
    @Environment(ExpenseStore.self) private var store
    @State private var request: ReceiptTestShareRequest?
    @State private var error: String?

    var body: some View {
        Button("Share test receipt") {
            do {
                let items: [Any]
                try ReceiptShareStore.publish(ReceiptShareContext(currencySymbol: store.currencySymbol,
                    currencyCode: store.currencyCode, categories: store.categories, accounts: store.accounts))
                let text = "Google Pay\nPaid to Corner Cafe\n₹228\nCompleted\n17 Oct 2026\nUPI transaction ID 123456789012"
                switch ProcessInfo.processInfo.environment["SPENDY_UI_TEST_ACTION_PAYLOAD"] {
                case "text": items = [text]
                case "pdf":
                    let pdf = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 600, height: 800)).pdfData { context in
                        context.beginPage()
                        (text as NSString).draw(in: CGRect(x: 30, y: 40, width: 540, height: 700),
                            withAttributes: [.font: UIFont.systemFont(ofSize: 30)])
                    }
                    let url = FileManager.default.temporaryDirectory.appending(path: "action-test-receipt.pdf")
                    try pdf.write(to: url, options: .atomic)
                    items = ["Payment receipt", url]
                default:
                    guard let image = ReceiptImageClipboard.image else { return }
                    items = ["Payment receipt", image]
                }
                request = ReceiptTestShareRequest(items: items)
            } catch { self.error = error.localizedDescription }
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("share-test-receipt")
        .sheet(item: $request) { request in
            ReceiptTestActivity(items: request.items) { self.request = nil }
        }
        .alert("Test receipt unavailable", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
    }
}

private struct ReceiptTestShareRequest: Identifiable {
    let id = UUID()
    let items: [Any]
}

private struct ReceiptTestActivity: UIViewControllerRepresentable {
    let items: [Any]
    let finish: () -> Void
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in finish() }
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
