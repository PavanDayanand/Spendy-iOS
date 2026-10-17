import SwiftUI

/// A quiet silver wash behind Home's summary, fading into the adaptive canvas.
struct HomeMeshBackground: View {
    var isAnimating: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    private var pausesMotion: Bool {
        !isAnimating || reduceMotion || lowPowerMode || scenePhase != .active
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                SpendyColors.appBackground

                if contrast != .increased {
                    TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: pausesMotion)) { context in
                        let time = pausesMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                        MeshGradient(
                            width: 4,
                            height: 4,
                            points: points(at: time),
                            colors: colors,
                            smoothsColors: true,
                            colorSpace: .perceptual
                        )
                    }
                    .frame(height: geometry.size.height * 0.72)
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.48),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private var colors: [Color] {
        let base = SpendyColors.appBackground
        let isDark = colorScheme == .dark
        let soft = Color(white: isDark ? 0.035 : 0.98)
        let silver = Color(white: isDark ? 0.115 : 0.92)
        let pearl = Color(white: isDark ? 0.065 : 0.965)
        return [
            base, soft, pearl, base,
            soft, silver, soft, pearl,
            pearl, soft, silver, soft,
            base, base, base, base
        ]
    }

    private func points(at time: TimeInterval) -> [SIMD2<Float>] {
        func wave(_ period: Double, _ phase: Double = 0) -> Float {
            Float(sin(time * 2 * .pi / period + phase))
        }
        // Fixed edges prevent gaps; only the four interior points drift.
        return [
            [0, 0], [0.33, 0], [0.67, 0], [1, 0],
            [0, 0.33],
            [0.30 + 0.05 * wave(31), 0.32 + 0.04 * wave(37, 1)],
            [0.69 + 0.04 * wave(41, 2), 0.35 + 0.05 * wave(43)],
            [1, 0.33],
            [0, 0.67],
            [0.32 + 0.04 * wave(47, 1), 0.69 + 0.04 * wave(37, 3)],
            [0.68 + 0.05 * wave(43, 4), 0.66 + 0.04 * wave(53, 2)],
            [1, 0.67],
            [0, 1], [0.33, 1], [0.67, 1], [1, 1]
        ]
    }
}
