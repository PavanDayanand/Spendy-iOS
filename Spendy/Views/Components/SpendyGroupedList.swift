import SwiftUI

/// One surface for a related set of rows, separated at the shared text inset.
struct SpendyGroupedList<Item: Identifiable, Row: View>: View {
    let items: [Item]
    var background: Color = SpendyColors.cardBackground
    var isEnclosed = true
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(item)
                if index < items.count - 1 {
                    Divider()
                        .overlay(SpendyColors.separator)
                        .padding(.leading, 72)
                        .padding(.trailing, 16)
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
