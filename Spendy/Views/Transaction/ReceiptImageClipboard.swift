import UIKit

/// Shared copied-image import for the Home shortcut and transaction editor.
enum ReceiptImageClipboard {
    static var image: UIImage? {
        #if DEBUG
        // Reproducible OCR/UI fixture; the UI test runner's clipboard is isolated on newer simulators.
        if ProcessInfo.processInfo.environment["SPENDY_UI_TEST_MODE"] != nil,
           let text = ProcessInfo.processInfo.environment["SPENDY_UI_TEST_RECEIPT_TEXT"] {
            return UIGraphicsImageRenderer(size: CGSize(width: 900, height: 1000)).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 900, height: 1000))
                for (index, line) in text.components(separatedBy: "\n").enumerated() {
                    (line as NSString).draw(at: CGPoint(x: 40, y: 40 + index * 95), withAttributes: [
                        .font: UIFont.systemFont(ofSize: index == 2 ? 60 : 36), .foregroundColor: UIColor.black
                    ])
                }
            }
        }
        #endif
        return UIPasteboard.general.image
    }

}
