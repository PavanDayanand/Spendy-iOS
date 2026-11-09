import SwiftUI

/// One surface for a related set of rows, separated at the shared text inset.
struct SpendyGroupedList<Item: Identifiable, Row: View>: View {
    let items: [Item]
    var background: Color = SpendyColors.cardBackground
    var isEnclosed = true
    var horizontalPadding: CGFloat = 16
    var iconWidth: CGFloat = 44
    var rowSpacing: CGFloat = 12
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(item)
                if index < items.count - 1 {
                    Divider()
                        .overlay(SpendyColors.separator)
                        .padding(.leading, horizontalPadding + iconWidth + rowSpacing)
                        .padding(.trailing, horizontalPadding)
                }
            }
        }
        .background {
            if isEnclosed && !items.isEmpty {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(background)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
}
