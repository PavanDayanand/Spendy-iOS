import SwiftUI

/// Shared amount-entry layout for transactions and budgets.
struct SpendyAmountEntrySheet<Header: View, Content: View, Dock: View>: View {
    var bottomPadding: CGFloat = 14
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content
    @ViewBuilder var dock: () -> Dock

    var body: some View {
        VStack(spacing: 0) {
            header()
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            dock()
                .padding(.horizontal, 12)
                .padding(.bottom, bottomPadding)
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationBackground(.ultraThinMaterial)
    }
}

extension View {
    func spendyAmountEntryDock(bottomPadding: CGFloat = 22) -> some View {
        self
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, bottomPadding)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 28))
    }
}
