import Foundation

extension ExpenseStore {
    /// Acknowledge only after a successful ledger write. Stable IDs make retries safe.
    func ingestSharedReceipts(at directory: URL? = nil) {
        guard loadError == nil else { return }
        do {
            let pending = try ReceiptShareStore.pending(at: directory)
            var accepted: [SharedReceiptEntry] = []
            var needsAttention = false
            for entry in pending {
                if transactions.contains(where: { $0.id == entry.id }) {
                    accepted.append(entry)
                    continue
                }
                guard entry.amount.isFinite, entry.amount > 0, entry.type != .transfer,
                      !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      entry.date.timeIntervalSince1970.isFinite,
                      entry.sourceKey.range(of: #"^[a-f0-9]{64}$"#, options: .regularExpression) != nil,
                      entry.currencySymbol == currencySymbol, entry.currencyCode == currencyCode,
                      accounts.contains(where: { $0.id == entry.accountId }),
                      categories.contains(where: { $0.id == entry.categoryId && $0.type == entry.type }) else {
                    needsAttention = true
                    continue
                }
                transactions.insert(Transaction(id: entry.id, title: entry.title, amount: entry.amount,
                    type: entry.type, categoryId: entry.categoryId, accountId: entry.accountId,
                    date: entry.date), at: 0)
                accepted.append(entry)
            }
            if !accepted.isEmpty {
                flushPendingSave()
                guard persistenceError == nil else {
                    sharedReceiptImportError = "Your shared receipt is safe. Retry saving to finish adding it."
                    return
                }
                try ReceiptShareStore.acknowledge(accepted, at: directory)
            }
            sharedReceiptImportError = needsAttention
                ? "An account, category, or currency changed after sharing. Your receipt is kept safely. Restore that setting and tap Retry."
                : nil
        } catch {
            sharedReceiptImportError = "Your shared receipts are kept safely. \(error.localizedDescription)"
        }
    }
}
