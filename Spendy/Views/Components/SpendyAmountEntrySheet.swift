import SwiftUI

/// Shared amount-entry layout for transactions and budgets.
struct SpendyAmountEntrySheet<Header: View, Content: View, Dock: View>: View {
    var bottomPadding: CGFloat = 14
    var allowsColumns = true
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content
    @ViewBuilder var dock: () -> Dock

    var body: some View {
        GeometryReader { geometry in
            if allowsColumns && SpendyAdaptiveLayout.usesColumns(size: geometry.size) {
                SpendyAdaptiveColumns {
                    ScrollView {
                        VStack(spacing: 0) {
                            header()
                            content()
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                } secondary: {
                    ScrollView {
                        dock()
                            .padding(12)
                    }
                }
                .padding(16)
            } else if geometry.size.height < 620 {
                ScrollView {
                    VStack(spacing: 12) {
                        header()
                        content()
                        dock().padding(.horizontal, 12)
                    }
                    .padding(.bottom, bottomPadding)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                standardLayout
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            }
        }
        .presentationBackground(.ultraThinMaterial)
    }

    private var standardLayout: some View {
        VStack(spacing: 0) {
            header()
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            dock()
                .padding(.horizontal, 12)
                .padding(.bottom, bottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
