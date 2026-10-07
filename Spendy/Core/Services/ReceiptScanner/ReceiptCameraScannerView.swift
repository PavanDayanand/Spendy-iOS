//
//  ReceiptCameraScannerView.swift
//  Spendy
//
//  VNDocumentCameraViewController wrapper for live auto-edge detecting receipt scanning.
//  Includes simulator / device capability fallback.
//

import SwiftUI
import VisionKit

struct ReceiptCameraScannerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onScanCompleted: ([UIImage]) -> Void
    var onCancel: (() -> Void)? = nil
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        if VNDocumentCameraViewController.isSupported {
            let docScanner = VNDocumentCameraViewController()
            docScanner.delegate = context.coordinator
            return docScanner
        } else {
            // Simulator or unsupported device fallback view controller
            let fallbackVC = UIHostingController(rootView: UnsupportedCameraFallbackView {
                onCancel?()
            })
            return fallbackVC
        }
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ReceiptCameraScannerView
        
        init(_ parent: ReceiptCameraScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedImages: [UIImage] = []
            for i in 0..<scan.pageCount {
                scannedImages.append(scan.imageOfPage(at: i))
            }
            parent.onScanCompleted(scannedImages)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel?()
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onCancel?()
            parent.dismiss()
        }
    }
}

private struct UnsupportedCameraFallbackView: View {
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(SpendyColors.textTertiary)
                
                Text("Camera Scanner Unavailable")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Text("Document camera is only supported on physical iOS devices with camera hardware. You can still pick receipt screenshots or photos from your library.")
                    .font(.system(size: 14))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: onClose) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white, in: Capsule())
                }
                .padding(.top, 12)
            }
        }
    }
}
