import PhotosUI
import SwiftUI

/// Explicit child-controller containment keeps the remote picker inside the sheet.
struct ReceiptPhotoGrid: UIViewControllerRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let onPick: (NSItemProvider) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick, onCancel: onCancel) }

    func makeUIViewController(context: Context) -> UIViewController {
        let container = UIViewController()
        container.view.backgroundColor = .systemBackground
        container.view.clipsToBounds = true
        container.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light

        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.selection = .continuous
        configuration.preferredAssetRepresentationMode = .compatible
        configuration.disabledCapabilities = [.selectionActions, .search]
        configuration.edgesWithoutContentMargins = .bottom
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        container.addChild(picker)
        picker.view.translatesAutoresizingMaskIntoConstraints = false
        picker.view.backgroundColor = .systemBackground
        picker.view.clipsToBounds = true
        container.view.addSubview(picker.view)
        NSLayoutConstraint.activate([
            picker.view.leadingAnchor.constraint(equalTo: container.view.leadingAnchor),
            picker.view.trailingAnchor.constraint(equalTo: container.view.trailingAnchor),
            picker.view.topAnchor.constraint(equalTo: container.view.topAnchor),
            picker.view.bottomAnchor.constraint(equalTo: container.view.bottomAnchor)
        ])
        picker.didMove(toParent: container)
        return container
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        if controller.overrideUserInterfaceStyle != style {
            controller.overrideUserInterfaceStyle = style
        }
        context.coordinator.onPick = onPick
        context.coordinator.onCancel = onCancel
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var onPick: (NSItemProvider) -> Void
        var onCancel: () -> Void

        init(onPick: @escaping (NSItemProvider) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else { onCancel(); return }
            onPick(result.itemProvider)
        }
    }
}
