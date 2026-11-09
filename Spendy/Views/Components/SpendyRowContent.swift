import SwiftUI

/// Shares alignment and accessibility reflow without imposing padding or card styling.
struct SpendyRowContent<Icon: View, Content: View, Value: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var spacing: CGFloat = 12
    var iconWidth: CGFloat? = nil
    @ViewBuilder let icon: () -> Icon
    @ViewBuilder let content: () -> Content
    @ViewBuilder let value: () -> Value

    var body: some View {
        HStack(alignment: dynamicTypeSize.isAccessibilitySize ? .top : .center, spacing: spacing) {
            icon().frame(width: iconWidth)
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
    }
}
