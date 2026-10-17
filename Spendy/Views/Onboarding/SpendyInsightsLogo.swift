import SwiftUI
import OSLog
import RiveRuntime

/// The approved ribbon reveal, with a still for Reduce Motion or loading failures.
struct SpendyInsightsLogo: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var rive: Rive?
    @State private var loadingFailed = false

    var body: some View {
        ZStack {
            Image("SpendyInsightsLogo")
                .resizable()
                .scaledToFit()
                .opacity(reduceMotion || rive == nil || loadingFailed ? 1 : 0)
            if !reduceMotion, let rive {
                RiveUIViewRepresentable(rive: rive)
                    .semantics(.off)
                    .paused(scenePhase != .active)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityHidden(true)
        .task(id: reduceMotion) {
            guard !reduceMotion, rive == nil, !loadingFailed else { return }
            do {
                let worker = try await Worker()
                let file = try await RiveRuntime.File(source: .local("spendy-insights", Bundle.main), worker: worker)
                let artboard = try await file.createArtboard("Spendy Insights · Ribbon Reveal")
                let loaded = try await Rive(file: file, artboard: artboard, dataBind: .none)
                guard !Task.isCancelled else { return }
                rive = loaded
            } catch {
                guard !Task.isCancelled else { return }
                Logger(subsystem: "com.Spendy", category: "InsightsLogo").error("Insights reveal could not load: \(String(describing: error), privacy: .public)")
                loadingFailed = true
            }
        }
    }
}
