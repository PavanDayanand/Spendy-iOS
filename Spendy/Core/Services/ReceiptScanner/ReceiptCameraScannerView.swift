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
    var onChoosePhoto: () -> Void

    @Namespace private var cameraNamespace

    var body: some View {
        VStack(spacing: 14) {
            GlassEffectContainer(spacing: 12) {
                HStack {
                    GlassCircleButton(icon: "xmark", size: 44, iconSize: 16,
                        accessibilityLabel: "Close camera", morphID: "cameraClose",
                        namespace: cameraNamespace, action: onCancel)
                    Spacer()
                    Text("Receipt")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    Spacer()
                    GlassCircleButton(icon: "photo", size: 44, iconSize: 18,
                        accessibilityLabel: "Choose receipt photo", morphID: "cameraPhotos",
                        namespace: cameraNamespace, action: onChoosePhoto)
                }
            }
            .padding(.horizontal, 8)

            ZStack {
                Color.black
                if camera.status == .ready {
                    ReceiptCameraPreview(session: camera.session)
                        .overlay(alignment: .bottom) {
                            shutter
                                .padding(.bottom, 32)
                        }
                } else {
                    cameraStatus
                        .padding(28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // The sheet is radius 32; a 12-point inset gives a concentric inner radius of 20.
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 0.5)
            }
            .accessibilityIdentifier("receipt-camera-viewport")
        }
        .padding(.horizontal, 12)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .background(SpendyColors.appBackground.ignoresSafeArea())
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            camera.onCapture = onCapture
            camera.start()
        }
        .onDisappear { camera.stop() }
    }

    private var shutter: some View {
        Button { camera.capture() } label: {
            Circle()
                .fill(.white)
                .frame(width: 54, height: 54)
                .overlay {
                    if camera.isCapturing { ProgressView().tint(.black) }
                }
                .frame(width: 78, height: 78)
                .glassEffect(.regular.interactive(), in: .circle)
                .environment(\.colorScheme, .dark)
        }
        .buttonStyle(.plain)
        .disabled(camera.isCapturing)
        .accessibilityLabel("Take receipt photo")
    }

    private var cameraStatus: some View {
        VStack(spacing: 14) {
            if camera.status == .loading {
                ProgressView().tint(.white)
                Text("Starting camera")
                    .font(.subheadline)
            } else {
                Image(systemName: "camera.slash")
                    .font(.title2)
                    .accessibilityHidden(true)
                Text(camera.status == .denied
                     ? "Allow camera access in Settings to take a receipt photo."
                     : "Camera is unavailable on this device. Use Photos above.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                if camera.status == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .buttonStyle(.glass)
                }
            }
        }
        .foregroundStyle(.white)
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
