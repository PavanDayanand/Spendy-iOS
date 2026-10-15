import SwiftUI
import UIKit

/// A native source menu that can also open after the first-use sheet is dismissed.
struct ReceiptSourceMenuButton: UIViewRepresentable {
    enum Source { case paste, photos, camera }

    var usesDockStyle: Bool = false
    var needsIntroduction: Bool
    var presentationRequest: Int
    var onIntroduction: () -> Void
    var onSelect: (Source) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "doc.text.viewfinder",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .bold)), for: .normal)
        button.layer.cornerRadius = 22
        button.layer.borderWidth = 0.8
        button.accessibilityLabel = usesDockStyle ? "Scan receipt" : "Add receipt"
        button.accessibilityIdentifier = usesDockStyle ? "home-receipt-scan" : "add-receipt-source"
        button.addAction(UIAction { [weak coordinator = context.coordinator] _ in
            guard let coordinator, coordinator.parent.needsIntroduction else { return }
            coordinator.parent.onIntroduction()
        }, for: .primaryActionTriggered)
        return button
    }

    func updateUIView(_ button: UIButton, context: Context) {
        context.coordinator.parent = self
        button.tintColor = UIColor(SpendyColors.textPrimary)
        button.backgroundColor = usesDockStyle ? .clear : UIColor(SpendyColors.transactionKeySurface)
        button.layer.borderWidth = usesDockStyle ? 0 : 0.8
        button.layer.borderColor = UIColor(SpendyColors.separator).resolvedColor(with: button.traitCollection).cgColor
        button.menu = needsIntroduction ? nil : UIMenu(children: [
            action("Paste image", symbol: "doc.on.clipboard", source: .paste),
            action("Photos", symbol: "photo.on.rectangle", source: .photos),
            action("Camera", symbol: "camera", source: .camera)
        ])
        button.showsMenuAsPrimaryAction = !needsIntroduction

        guard presentationRequest != context.coordinator.lastPresentationRequest else { return }
        context.coordinator.lastPresentationRequest = presentationRequest
        guard !needsIntroduction else { return }
        // The parent requests this from sheet onDismiss; wait one layout pass for the updated menu.
        DispatchQueue.main.async { [weak button] in
            guard let button, button.window != nil else { return }
            button.performPrimaryAction()
        }
    }

    private func action(_ title: String, symbol: String, source: Source) -> UIAction {
        UIAction(title: title, image: UIImage(systemName: symbol)) { _ in onSelect(source) }
    }

    final class Coordinator {
        var parent: ReceiptSourceMenuButton
        var lastPresentationRequest = 0
        init(_ parent: ReceiptSourceMenuButton) { self.parent = parent }
    }
}
