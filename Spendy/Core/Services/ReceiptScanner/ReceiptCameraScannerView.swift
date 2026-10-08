//
//  ReceiptCameraScannerView.swift
//  Spendy
//
//  A compact, in-place camera for capturing one receipt photo.
//

@preconcurrency import AVFoundation
import Combine
import SwiftUI

struct ReceiptCameraCaptureView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var camera = ReceiptCameraModel()

    var onCapture: (UIImage) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black

            if camera.status == .ready {
                ReceiptCameraPreview(session: camera.session)
                    .ignoresSafeArea()
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.42), in: Circle())
                    }
                    .accessibilityLabel("Close camera")
                    Spacer()
                    Text("Receipt")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(.black.opacity(0.42), in: Capsule())
                }

                Spacer()

                if camera.status == .ready {
                    Button { camera.capture() } label: {
                        Circle()
                            .fill(.white)
                            .frame(width: 62, height: 62)
                            .padding(6)
                            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 2))
                    }
                    .disabled(camera.isCapturing)
                    .accessibilityLabel("Take receipt photo")
                    .padding(.bottom, 16)
                } else {
                    VStack(spacing: 14) {
                        if camera.status == .loading {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "camera.slash")
                                .font(.title2)
                            Text(camera.status == .denied
                                 ? "Allow camera access in Settings to take a receipt photo."
                                 : "Camera is unavailable on this device. Choose Photos instead.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                            if camera.status == .denied {
                                Button("Open Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        openURL(url)
                                    }
                                }
                                .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
                }
            }
            .padding(24)
            .foregroundStyle(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .onAppear {
            camera.onCapture = onCapture
            camera.start()
        }
        .onDisappear { camera.stop() }
    }
}

private struct ReceiptCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

@MainActor
private final class ReceiptCameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    enum Status: Equatable {
        case loading, ready, denied, unavailable
    }

    @Published private(set) var status: Status = .loading
    @Published private(set) var isCapturing = false
    let session = AVCaptureSession()
    var onCapture: ((UIImage) -> Void)?

    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "Spendy.ReceiptCamera")
    private var isConfigured = false
    private var isActive = false

    func start() {
        isActive = true
        guard AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil else {
            status = .unavailable
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            Task {
                if await AVCaptureDevice.requestAccess(for: .video) {
                    if isActive { configureAndStart() }
                } else {
                    status = .denied
                }
            }
        case .denied, .restricted:
            status = .denied
        @unknown default:
            status = .unavailable
        }
    }

    private func configureAndStart() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            status = .unavailable
            return
        }

        if !isConfigured {
            session.beginConfiguration()
            session.sessionPreset = .photo
            guard session.canAddInput(input), session.canAddOutput(photoOutput) else {
                session.commitConfiguration()
                status = .unavailable
                return
            }
            session.addInput(input)
            session.addOutput(photoOutput)
            session.commitConfiguration()
            isConfigured = true
        }

        sessionQueue.async { [weak self, session] in
            if !session.isRunning { session.startRunning() }
            let isRunning = session.isRunning
            Task { @MainActor [weak self] in
                guard let self, self.isActive else { return }
                self.status = isRunning ? .ready : .unavailable
            }
        }
    }

    func capture() {
        guard status == .ready, !isCapturing else { return }
        isCapturing = true
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    func stop() {
        isActive = false
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        Task { @MainActor in
            isCapturing = false
            if let image {
                onCapture?(image)
            } else {
                status = .unavailable
            }
        }
    }
}
