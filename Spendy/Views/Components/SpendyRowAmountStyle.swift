import SwiftUI

/// Consistent, scalable amount typography for list rows. Colour remains contextual.
extension View {
    func spendyRowAmount() -> some View {
        font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .layoutPriority(1)
    }
}
