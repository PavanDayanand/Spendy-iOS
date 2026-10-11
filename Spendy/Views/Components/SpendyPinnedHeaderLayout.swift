import SwiftUI

/// A custom header with the system navigation-bar material.
/// The material adapts to appearance, contrast and the content underneath it.
extension View {
    func spendyBarBackground(isVisible: Bool = true) -> some View {
        background {
            if isVisible {
                Rectangle()
                    .fill(.bar)
                    .ignoresSafeArea(edges: .top)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// Measures the header so scoped labels and larger text keep the first row clear.
/// Scrolling content can pass beneath the pinned bar, as with native navigation.
struct SpendyPinnedHeaderLayout<Header: View, Content: View>: View {
    let isEnabled: Bool
    private let header: Header
    private let content: Content
    @State private var headerHeight: CGFloat = 0

    init(isEnabled: Bool = true, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.isEnabled = isEnabled
        self.header = header()
        self.content = content()
    }

    var body: some View {
        if isEnabled {
            ZStack(alignment: .top) {
                content.safeAreaPadding(.top, headerHeight)
                header
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
                    .spendyBarBackground()
                    .zIndex(1)
            }
        } else {
            VStack(spacing: 0) {
                header
                content
            }
        }
    }
}
