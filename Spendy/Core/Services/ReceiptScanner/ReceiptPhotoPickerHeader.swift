import SwiftUI

/// App controls over the native picker's own header. UIKit owns sheet gestures.
struct ReceiptPhotoPickerHeader: View {
    let loading: Bool
    let onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                Color.black.opacity(0.001).frame(height: 18)
                HStack(spacing: 0) {
                    Color.black.opacity(0.001)
                    Color.clear.frame(width: 200).allowsHitTesting(false)
                    Color.black.opacity(0.001)
                }
                .frame(height: 56)
            }
            .accessibilityHidden(true)

            GlassCircleButton(size: 44, accessibilityLabel: "Cancel", action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
            .padding(.leading, 12)
            .padding(.top, 15)

            if loading {
                ProgressView("Opening photo…")
                    .padding(12)
                    .background(.regularMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
