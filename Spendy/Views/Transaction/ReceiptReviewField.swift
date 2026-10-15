import Foundation

enum ReceiptReviewField: String, Identifiable {
    case note, date, category, account, createCategory
    var id: String { rawValue }
}
