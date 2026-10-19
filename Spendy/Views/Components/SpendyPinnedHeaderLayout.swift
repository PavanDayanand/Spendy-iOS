import SwiftUI

/// Keeps custom header controls fixed; opt in to the native soft edge only on uncovered scroll headers.
/// Measured padding keeps the initial content clear, including with larger text.
struct SpendyPinnedHeaderLayout<Header: View, Content: View>: View {
    let isEnabled: Bool
    let usesSoftScrollEdge: Bool
    private let header: Header
    private let content: Content
    @State private var headerHeight: CGFloat = 0

    init(isEnabled: Bool = true, usesSoftScrollEdge: Bool = false, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.isEnabled = isEnabled
        self.usesSoftScrollEdge = usesSoftScrollEdge
        self.header = header()
        self.content = content()
    }

    var body: some View {
        if isEnabled && usesSoftScrollEdge {
            content
                .safeAreaBar(edge: .top, spacing: 0) { header }
                .scrollEdgeEffectStyle(.soft, for: .top)
        } else if isEnabled {
            ZStack(alignment: .top) {
                content.safeAreaPadding(.top, headerHeight)
                header
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
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
