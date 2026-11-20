import SwiftUI

/// A straight feed edge and a small, regular tear along the bottom of the paper.
struct MonthlyReceiptPaperShape: Shape {
    func path(in rect: CGRect) -> Path {
        let teeth = max(1, Int(rect.width / 10))
        let step = rect.width / CGFloat(teeth)
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 5))
        for index in stride(from: teeth, to: 0, by: -1) {
            path.addLine(to: CGPoint(x: (CGFloat(index) - 0.5) * step, y: rect.maxY))
            path.addLine(to: CGPoint(x: CGFloat(index - 1) * step, y: rect.maxY - 5))
        }
        path.closeSubpath()
        return path
    }
}
