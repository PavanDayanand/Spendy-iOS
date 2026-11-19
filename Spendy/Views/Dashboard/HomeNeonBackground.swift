import SwiftUI

/// Only this background follows the clock; Home's content and queries remain independent.
struct HomeNeonBackground: View {
    var style: HomeGradientStyle = .blueAura
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false
    @State private var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        let paused = !animated || reduceMotion || lowPowerMode || scenePhase != .active || !isVisible
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { context in
            // Integer harmonics keep the 24-second loop seamless at its boundary.
            let phase = paused ? 0 : context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: 24) / 24 * 2 * .pi
            HomeGradientCanvas(style: style, phase: phase, motionEnabled: !paused)
        }
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Blue Aura") {
    HomeNeonBackground(animated: false).ignoresSafeArea().preferredColorScheme(.dark)
}

#Preview("Indigo") {
    HomeNeonBackground(style: .indigo, animated: false).ignoresSafeArea().preferredColorScheme(.dark)
}
