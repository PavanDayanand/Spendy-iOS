import SwiftUI

/// Home and Add Transaction supply live app data to the shared receipt review.
struct ReceiptScannerSheet: View {
    @Environment(ExpenseStore.self) private var store
    var images: [UIImage]
    var initialAccountId: String?
    var initialCategoryId: String?
    var onEditResult: (ReceiptScanResult) -> Void
    var onAddResult: (ReceiptScanResult) -> Void

    var body: some View {
        ReceiptReviewView(images: images, categories: store.categories, accounts: store.accounts,
            currencySymbol: store.currencySymbol,
            balances: Dictionary(uniqueKeysWithValues: store.accounts.map { ($0.id, store.balance(for: $0.id)) }),
            categoryCreation: { type, created in
                AnyView(AddCategorySheet(defaultType: type, onCreated: created))
            },
            initialAccountId: initialAccountId, initialCategoryId: initialCategoryId,
            onEditResult: onEditResult, onAddResult: onAddResult)
    }
}
