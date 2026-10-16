import SwiftUI
import OSLog
import RiveRuntime

/// A bundled, optional coffee break. It never blocks the onboarding flow.
struct SpendyCoffeeMascot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var rive: Rive?
    @State private var loadingFailed = false

    var body: some View {
        Group {
            if reduceMotion || loadingFailed {
                still
                    .accessibilityLabel("Spendy’s coffee character")
                    .accessibilityIdentifier("intro-coffee-mascot")
            } else {
                Button {
                    rive?.viewModelInstance?.fire(trigger: TriggerProperty(path: "sip"))
                } label: {
                    ZStack {
                        still
                            .opacity(rive == nil ? 1 : 0)
                        if let rive {
                            RiveUIViewRepresentable(rive: rive)
                                .semantics(.off)
                                .paused(scenePhase != .active)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(rive == nil)
                .accessibilityLabel("Make Spendy sip coffee")
                .accessibilityHint("Lifts his cup, takes a sip, and puts it down.")
                .accessibilityIdentifier("intro-coffee-mascot")
            }
        }
        .task(id: reduceMotion) {
            guard !reduceMotion, rive == nil, !loadingFailed else { return }
            do {
                let worker = try await Worker()
                let file = try await RiveRuntime.File(source: .local("spendy-coffee", Bundle.main), worker: worker)
                let loaded = try await Rive(file: file)
                guard !Task.isCancelled else { return }
                Logger(subsystem: "com.Spendy", category: "CoffeeMascot").debug("Bundled coffee mascot loaded")
                rive = loaded
            } catch {
                guard !Task.isCancelled else { return }
                Logger(subsystem: "com.Spendy", category: "CoffeeMascot").error("Mascot could not load: \(String(describing: error), privacy: .public)")
                loadingFailed = true
            }
        }
    }

    private var still: some View {
        Image("SpendyCoffeeStill")
            .resizable()
            .scaledToFit()
    }
}
