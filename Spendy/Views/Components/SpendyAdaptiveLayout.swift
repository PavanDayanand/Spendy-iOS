import SwiftUI

enum SpendyAdaptiveLayout {
    enum Home: Equatable { case compact, portrait, arranged }

    static func home(size: CGSize, regularWidth: Bool, activeFold: Bool = false) -> Home {
        guard regularWidth && size.width >= 600 else { return .compact }
        if activeFold || usesColumns(size: size) { return .arranged }
        return .portrait
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
