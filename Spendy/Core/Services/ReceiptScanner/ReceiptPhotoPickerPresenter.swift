import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// A native sheet contains the embedded picker and app header. UIKit owns
/// interactive layout; SwiftUI only requests presentation and receives results.
struct ReceiptPhotoPickerPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onSelect: (UIImage) -> Void
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> Presenter {
        let controller = Presenter()
        controller.view.backgroundColor = .clear
        controller.request = self
        return controller
    }

    func updateUIViewController(_ controller: Presenter, context: Context) {
        controller.request = self
        controller.updatePresentation()
    }

    final class Presenter: UIViewController, PHPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
        var request: ReceiptPhotoPickerPresenter?
        private var panel: UIViewController?
        private var picker: PHPickerViewController?
        private var chrome: UIHostingController<ReceiptPhotoPickerHeader>?
        private var loadProgress: Progress?
        private var loading = false
        private var dismissing = false

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            updatePresentation()
        }

        func updatePresentation() {
            guard let request else { return }
            if request.isPresented {
                guard panel == nil, view.window != nil, presentedViewController == nil else { return }
                var configuration = PHPickerConfiguration()
                configuration.filter = .images
                configuration.selectionLimit = 1
                configuration.selection = .continuous
                configuration.preferredAssetRepresentationMode = .compatible
                configuration.disabledCapabilities = [.selectionActions, .search]
                configuration.edgesWithoutContentMargins = .bottom
                let picker = PHPickerViewController(configuration: configuration)
                picker.delegate = self
                let panel = UIViewController()
                panel.modalPresentationStyle = .pageSheet
                panel.view.backgroundColor = .systemBackground
                panel.view.clipsToBounds = true
                picker.view.clipsToBounds = true
                panel.view.accessibilityIdentifier = "receipt-photo-panel"
                panel.addChild(picker)
                picker.view.translatesAutoresizingMaskIntoConstraints = false
                panel.view.addSubview(picker.view)
                NSLayoutConstraint.activate([
                    picker.view.leadingAnchor.constraint(equalTo: panel.view.leadingAnchor),
                    picker.view.trailingAnchor.constraint(equalTo: panel.view.trailingAnchor),
                    picker.view.topAnchor.constraint(equalTo: panel.view.topAnchor),
                    picker.view.bottomAnchor.constraint(equalTo: panel.view.bottomAnchor)
                ])
                picker.didMove(toParent: panel)
                if let sheet = panel.sheetPresentationController {
                    let compact = UISheetPresentationController.Detent.Identifier("receipt-compact")
                    sheet.detents = [.custom(identifier: compact) { $0.maximumDetentValue * 0.72 }, .large()]
                    sheet.selectedDetentIdentifier = compact
                    sheet.prefersGrabberVisible = false
                    sheet.prefersScrollingExpandsWhenScrolledToEdge = true
                }
                self.picker = picker
                self.panel = panel
                let header = UIHostingController(rootView: makeHeader())
                header.view.backgroundColor = .clear
                header.view.translatesAutoresizingMaskIntoConstraints = false
                panel.addChild(header)
                panel.view.addSubview(header.view)
                NSLayoutConstraint.activate([
                    header.view.leadingAnchor.constraint(equalTo: panel.view.leadingAnchor),
                    header.view.trailingAnchor.constraint(equalTo: panel.view.trailingAnchor),
                    header.view.topAnchor.constraint(equalTo: panel.view.topAnchor),
                    header.view.heightAnchor.constraint(equalToConstant: 74)
                ])
                header.didMove(toParent: panel)
                chrome = header
                panel.presentationController?.delegate = self
                present(panel, animated: true)
            } else if panel != nil {
                close()
            }
        }

        private func makeHeader() -> ReceiptPhotoPickerHeader {
            ReceiptPhotoPickerHeader(loading: loading, onCancel: { [weak self] in self?.close() })
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else { close(); return }
            guard !loading else { return }
            loading = true
            chrome?.rootView = makeHeader()
            loadProgress = result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self, weak picker] data, _ in
                Task { @MainActor [weak self, weak picker] in
                    guard let self, let picker, self.picker === picker, !self.dismissing else { return }
                    self.loading = false
                    self.chrome?.rootView = self.makeHeader()
                    guard let data, let image = UIImage(data: data) else {
                        let alert = UIAlertController(title: "Receipt image",
                            message: "That photo could not be opened. Choose another receipt or screenshot.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.panel?.present(alert, animated: true)
                        return
                    }
                    self.request?.onSelect(image)
                    self.close()
                }
            }
        }

        private func close() {
            guard let panel, !dismissing else { return }
            dismissing = true
            loadProgress?.cancel()
            panel.dismiss(animated: true) { [weak self] in self?.finishDismissal() }
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            finishDismissal()
        }

        private func finishDismissal() {
            guard picker != nil else { return }
            loadProgress?.cancel()
            loadProgress = nil
            picker = nil
            panel = nil
            chrome = nil
            loading = false
            dismissing = false
            request?.isPresented = false
            request?.onDismiss()
        }
    }
}
