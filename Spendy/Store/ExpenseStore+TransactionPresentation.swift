import SwiftUI

extension ExpenseStore {
    /// Transfers have an account route, never an expense or income category.
    func displayCategory(for transaction: Transaction) -> Category {
        guard transaction.type == .transfer else { return category(for: transaction.categoryId) }
        let label: String
        if let source = accounts.first(where: { $0.id == transaction.accountId }),
           let destination = accounts.first(where: { $0.id == transaction.toAccountId }) {
            label = "\(transferAccountKind(source.type)) to \(transferAccountKind(destination.type).lowercased())"
        } else {
            label = "Account transfer"
        }
        return Category(id: "transfer", label: label, sfSymbol: SFIcons.transfer,
                        colorHex: "#007AFF", type: .transfer)
    }

    func displayTitle(for transaction: Transaction) -> String {
        let title = transaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if transaction.type == .transfer {
            // Older saves inherited the selected category's name when no note was entered.
            let inheritedCategory = category(for: transaction.categoryId).label
            if title.isEmpty || (transaction.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false && title == inheritedCategory) {
                return "Transfer"
            }
        }
        return title.isEmpty ? displayCategory(for: transaction).label : title
    }

    func transferAccountRoute(for transaction: Transaction) -> String {
        let source = account(for: transaction.accountId).label
        guard let destinationID = transaction.toAccountId else { return source }
        return "\(source) → \(account(for: destinationID).label)"
    }

    private func transferAccountKind(_ type: AccountType) -> String {
        switch type {
        case .cash: "Cash"
        case .bank: "Bank"
        case .savings: "Savings"
        case .amazonPay: "Wallet"
        }
    }
}
