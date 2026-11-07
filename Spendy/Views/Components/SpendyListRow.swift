import SwiftUI

/// Common content alignment for transactions, categories, and accounts.
struct SpendyListRow<Icon: View, Content: View, Value: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder let icon: () -> Icon
    @ViewBuilder let content: () -> Content
    @ViewBuilder let value: () -> Value

    var body: some View {
        HStack(alignment: dynamicTypeSize.isAccessibilitySize ? .top : .center, spacing: 12) {
            icon().frame(width: 44)
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                    value()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                content().frame(maxWidth: .infinity, alignment: .leading)
                value().layoutPriority(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .contentShape(Rectangle())
    }
}
