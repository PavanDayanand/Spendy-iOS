import SwiftUI

enum SpendyAdaptiveLayout {
    enum Home: Equatable { case compact, portrait, arranged }

    static func home(size: CGSize, regularWidth: Bool, activeFold: Bool = false) -> Home {
        guard regularWidth && size.width >= 600 else { return .compact }
        if activeFold || usesColumns(size: size) { return .arranged }
        return .portrait
    }

    /// Reserve the header, three recent rows, and dock clearance before positioning the card.
    static func activityRestingOffset(totalHeight: CGFloat, bottomInset: CGFloat) -> CGFloat {
        let cardHeight: CGFloat = 72 + 3 * 60 + 42 + 56 + bottomInset
        return max(0, totalHeight - cardHeight)
    }

    static func usesColumns(size: CGSize) -> Bool {
        size.width >= 760 && size.height >= 300 && size.width > size.height * 1.1
    }

    static func hasActiveFold(in geometry: GeometryProxy) -> Bool {
        if #available(iOS 27.1, *) {
            return geometry.reservedRegions(kind: .division).contains { $0.isActive }
        }
        return false
    }
}
