import Foundation

enum ReceiptReviewField: String, Identifiable {
    case amount, note, date, category, account, createCategory
    var id: String { rawValue }
}
