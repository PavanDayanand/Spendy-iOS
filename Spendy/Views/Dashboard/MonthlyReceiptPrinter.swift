import SwiftUI

/// A single, interruptible feed. Only this view redraws while the paper prints.
struct MonthlyReceiptPrinter: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let snapshot: MonthlyReceiptSnapshot
    let printSequence: Int
    var animates = true
    @State private var paperHeight: CGFloat = 1

    @State private var started = false

    var body: some View {
        Group {
            if reduceMotion || !animates {
                printout(progress: 1)
            } else {
                Color.clear.frame(height: 0)
                    .keyframeAnimator(initialValue: CGFloat(0), trigger: started) { _, progress in
                        printout(progress: progress)
                    } keyframes: { _ in
                        LinearKeyframe(CGFloat(1), duration: 4.5)
                    }
            }
        }
        .task {
            guard !started else { return }
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            started = true
        }
    }

    private func printout(progress: CGFloat) -> some View {
        ZStack(alignment: .top) {
            printerBody(progress: progress)
            VStack(spacing: 0) {
                // Slot occupies y=48...57. Paper begins at its center.
                Color.clear.frame(height: 52)
                MonthlyReceiptPaper(snapshot: snapshot)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { paperHeight = $0 }
                    .offset(y: -paperHeight * (1 - progress))
                    .frame(height: max(0, paperHeight * progress), alignment: .top)
                    .clipped()
                    .overlay(alignment: .top) {
                        LinearGradient(colors: [.black.opacity(0.22), .clear],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: min(14, paperHeight * progress))
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 18)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 7)
            }
        }
        .padding(.bottom, 12)
    }

    private func printerBody(progress: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("spendy")
                    .font(.caption.monospaced().weight(.semibold))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.65))
                Spacer()
                Circle()
                    .fill(Color(red: 0.65, green: 0.9, blue: 0.72))
                    .frame(width: 5, height: 5)
                    .opacity(progress < 1 ? 0.5 + 0.5 * sin(Double(progress) * Double.pi * 12) : 0.85)
                Text(progress < 1 ? "PRINTING" : "READY")
                    .font(.caption2.monospaced())
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.horizontal, 22)
            .frame(height: 48)

            Capsule()
                .fill(.black)
                .frame(height: 9)
                .overlay(alignment: .bottom) {
                    Capsule().fill(.white.opacity(0.13)).frame(height: 1)
                }
                .padding(.horizontal, 14)
        }
        .padding(.bottom, 12)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [Color(white: 0.23), Color(white: 0.11)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
        }
        .accessibilityHidden(true)
    }
}
