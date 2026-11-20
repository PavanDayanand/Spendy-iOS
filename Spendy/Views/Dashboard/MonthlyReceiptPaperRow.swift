import SwiftUI

struct MonthlyReceiptPaperRow: View {
    let label: String
    let value: String
    var emphasized = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(label).fixedSize()
                Spacer(minLength: 8)
                Text(value).fixedSize()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                Text(value)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(emphasized ? .subheadline.monospaced().bold() : .caption.monospaced())
        .foregroundStyle(Color.black.opacity(emphasized ? 0.9 : 0.65))
        .accessibilityElement(children: .combine)
    }
}
