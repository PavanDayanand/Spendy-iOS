import SwiftUI

/// Common content alignment for transactions, categories, and accounts.
struct SpendyListRow<Icon: View, Content: View, Value: View>: View {
    @ViewBuilder let icon: () -> Icon
    @ViewBuilder let content: () -> Content
    @ViewBuilder let value: () -> Value

    var body: some View {
        SpendyRowContent(iconWidth: 44, icon: icon, content: content, value: value)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .contentShape(Rectangle())
    }
}
