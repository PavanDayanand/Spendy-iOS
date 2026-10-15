import UIKit

enum HomeReceiptSheet: Identifiable {
    case introduction
    case camera
    case review([UIImage])

    var id: String {
        switch self {
        case .introduction: "introduction"
        case .camera: "camera"
        case .review: "review"
        }
    }
}
