import SwiftUI

/// A small, hands-on introduction. Demo interactions never create financial records.
public struct OnboardingView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @GestureState private var pageDrag: CGFloat = 0
    @Namespace private var appearanceSelection
    @State private var currentStep: Int
    @State private var movingForward = true
    @State private var inputName = ""
    @State private var showCurrencyPicker = false
    @State private var triedExpense = false
    @State private var focus: Focus?
    @State private var insightIndex = 0
    @State private var widgetIndex = 0
    @FocusState private var isNameFocused: Bool
    private let totalSteps = 5
    private let onComplete: () -> Void

    private enum Focus: String, CaseIterable {
        case awareness = "Know where it goes"
        case budget = "Find room in my budget"
        case recurring = "Stay ahead of bills"

        var detail: String {
            switch self {
            case .awareness: "Notice the small purchases that repeat."
            case .budget: "See how your spending fits your plan."
            case .recurring: "Make recurring payments easier to see."
            }
        }
        var symbol: String {
            switch self {
            case .awareness: "chart.pie"
            case .budget: "circle.dashed"
            case .recurring: "calendar"
            }
        }
        var firstStep: String {
            switch self {
            case .awareness: "Start by logging one everyday expense. Clarity grows from there."
            case .budget: "Start with a comfortable budget. You can set it from Home."
            case .recurring: "Start by adding a recurring payment in Subscriptions."
            }
        }
    }

    public init(initialStep: Int = 0, onComplete: @escaping () -> Void = {}) {
        #if DEBUG
        let argument = CommandLine.arguments.first { $0.starts(with: "--onboarding-step=") }
        let requested = argument.flatMap { Int($0.replacingOccurrences(of: "--onboarding-step=", with: "")) }
        #else
        let requested: Int? = nil
        #endif
        _currentStep = State(initialValue: min(max(requested ?? initialStep, 0), 4))
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Normal text sizes use a fixed page. Scrolling is only an accessibility fallback.
                    if dynamicTypeSize.isAccessibilitySize {
                        ScrollView { pageContent }
                            .scrollDismissesKeyboard(.interactively)
                    } else {
                        pageContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .offset(x: reduceMotion ? 0 : pageDrag)
                .contentShape(Rectangle())
                .simultaneousGesture(pageSwipe(width: geometry.size.width))
                .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.86), value: pageDrag)
            }
            .clipped()
            footer
        }
        .background(SpendyColors.appBackground.ignoresSafeArea())
        .foregroundStyle(SpendyColors.textPrimary)
        .tint(SpendyColors.textPrimary)
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selectedCode: store.currencyCode) { currency in
                store.updateCurrency(symbol: currency.symbol, code: currency.code)
                showCurrencyPicker = false
            }
        }
        .onAppear { inputName = store.userName }
        .sensoryFeedback(.selection, trigger: currentStep)
    }

    private var pageContent: some View {
        stepContent
            .frame(maxWidth: 480, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.vertical, isNameFocused ? 8 : 16)
            .id(currentStep)
            .transition(pageTransition)
    }

    private func pageSwipe(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 24)
            .updating($pageDrag) { value, state, _ in
                guard !isNameFocused,
                      abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                let atEdge = (currentStep == 0 && value.translation.width > 0)
                    || (currentStep == totalSteps - 1 && value.translation.width < 0)
                // Resistance at the ends keeps the page attached to its bounds.
                state = value.translation.width * (atEdge ? 0.12 : 0.35)
            }
            .onEnded { value in
                guard !isNameFocused,
                      abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                let projected = value.predictedEndTranslation.width
                guard abs(value.translation.width) > width * 0.2
                        || (abs(value.translation.width) > 36 && abs(projected) > width * 0.45) else { return }
                move(to: currentStep + (value.translation.width < 0 ? 1 : -1))
            }
    }

    private var continueTitle: String {
        ["See how it helps", "Show my example", "Keep it close", "Make it yours", "Open Spendy"][currentStep]
    }

    // Forward and back retain their spatial meaning; each page starts at the top.
    private var pageTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .offset(x: movingForward ? 40 : -40).combined(with: .opacity),
            removal: .offset(x: movingForward ? -40 : 40).combined(with: .opacity)
        )
    }

    private var header: some View {
        HStack {
            Button { move(to: currentStep - 1) } label: {
                Image(systemName: "arrow.left")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back")
            .disabled(currentStep == 0)
            .opacity(currentStep == 0 ? 0 : 1)
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(SpendyColors.textPrimary.opacity(step == currentStep ? 1 : 0.16))
                        .frame(width: step == currentStep ? 24 : 6, height: 6)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(currentStep + 1) of \(totalSteps)")
            Spacer()
            Button("Skip") { move(to: totalSteps - 1) }
                .font(.subheadline)
                .frame(minWidth: 44, minHeight: 44)
                .opacity(currentStep == totalSteps - 1 ? 0 : 1)
                .disabled(currentStep == totalSteps - 1)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button {
                if currentStep == totalSteps - 1 { finishSetup() }
                else { move(to: currentStep + 1) }
            } label: {
                HStack {
                    Text(continueTitle)
                        .contentTransition(.opacity)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.headline)
                .padding(18)
                .foregroundStyle(SpendyColors.elevatedControlForeground)
                .background(SpendyColors.elevatedControlFill, in: Capsule())
            }
            .buttonStyle(IntroPressStyle(reduceMotion: reduceMotion))
            if !isNameFocused {
            Text(currentStep == 4 ? "You can change these later in Settings." : "Explore at your pace. You can skip the introduction.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: 480)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    @ViewBuilder private var stepContent: some View {
        switch currentStep {
        case 0: welcome
        case 1: intention
        case 2: insights
        case 3: shortcuts
        default: customization
        }
    }

    private func heading(_ eyebrow: String, _ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title.bold())
                .fontDesign(.rounded)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var welcome: some View {
        let reduceWelcomeMotion = reduceMotion
        return VStack(alignment: .leading, spacing: 16) {
            Image("AppIconPreview-Default")
                .resizable().scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 17))
                .accessibilityLabel("Spendy app icon")
            heading("Meet Spendy", "Know where your\nmoney goes.", "Quick tracking. A clear view of your spending, budgets, and subscriptions.")
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title2)
                        .keyframeAnimator(initialValue: CGFloat(1), trigger: triedExpense) { content, scale in
                            content.scaleEffect(reduceWelcomeMotion ? 1 : scale)
                        } keyframes: { _ in
                            CubicKeyframe(0.9, duration: 0.08)
                            SpringKeyframe(1.12, duration: 0.18, spring: .bouncy)
                            SpringKeyframe(1, duration: 0.22, spring: .smooth)
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coffee").font(.headline)
                        Text("Food & drink").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(25, format: .currency(code: store.currencyCode)).font(.title3.bold())
                }
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.82)) { triedExpense.toggle() }
                } label: {
                    Label(triedExpense ? "Added · tap to reset" : "Try logging a coffee", systemImage: triedExpense ? "checkmark.circle.fill" : "plus.circle")
                        .contentTransition(.opacity)
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: triedExpense)
                Divider()
                HStack {
                    Text("Spent today").foregroundStyle(.secondary)
                    Spacer()
                    Text(triedExpense ? 25 : 0, format: .currency(code: store.currencyCode))
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: triedExpense ? 25 : 0))
                }
                .accessibilityElement(children: .combine)
            }
            .padding(18)
            .background(SpendyColors.cardBackgroundSecondary, in: RoundedRectangle(cornerRadius: 26))
            Text("Just a demo. Nothing is saved.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var intention: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("Start with what matters", "What would you\nlike to see clearly?", "Choose a question. We’ll show how Spendy can help.")
            ForEach(Focus.allCases, id: \.self) { option in
                Button {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                        focus = option
                        insightIndex = option == .awareness ? 0 : option == .budget ? 1 : 2
                    }
                } label: {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: option.symbol).font(.title2).frame(width: 28)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(option.rawValue).font(.headline)
                            Text(option.detail).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: focus == option ? "checkmark.circle.fill" : "circle")
                    }
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(focus == option ? .isSelected : [])
                Divider()
            }
            Text("Just a starting point. Every feature is available whichever you choose.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var insightTitle: String {
        ["The little things add up.", "Know how much room you have.", "See what's coming."][insightIndex]
    }

    private var insightDetail: String {
        [
            "Five coffees at 25 each make 125. Small repeats are easier to notice when you see them together.",
            "A budget of 1,000 with 600 spent leaves 400. Check your pace before your next purchase.",
            "Three subscriptions at 100 each mean 300 in recurring costs. Seeing them together makes planning easier."
        ][insightIndex]
    }

    private var insights: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("From entries to understanding", "See what your\nspending tells you.", "Spending patterns and budget insights, calculated on your device. No generative AI.")
            VStack(alignment: .leading, spacing: 14) {
                Label("Example insight", systemImage: "chart.xyaxis.line")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(insightTitle)
                    .font(.title2.bold()).fontDesign(.rounded)
                    .contentTransition(.opacity)
                Text(insightDetail)
                    .font(.body).foregroundStyle(.secondary)
                insightIllustration
                    .id(insightIndex)
                    .transition(.opacity)
                Button("Show another example", systemImage: "arrow.triangle.2.circlepath") {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { insightIndex = (insightIndex + 1) % 3 }
                }
                .font(.subheadline.weight(.semibold))
                .frame(minHeight: 44)
            }
            .padding(18)
            .background(SpendyColors.cardBackgroundSecondary, in: RoundedRectangle(cornerRadius: 26))
            Text("Illustrative data. Your insights take shape as you track.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var insightIllustration: some View {
        // These visual summaries match the example above rather than inventing chart data.
        switch insightIndex {
        case 0:
            HStack(spacing: 12) {
                ForEach(0..<5) { _ in
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title3)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            .accessibilityLabel("Five coffee purchases")
        case 1:
            VStack(alignment: .leading, spacing: 10) {
                ProgressView(value: 0.6)
                    .tint(.primary)
                    .accessibilityLabel("Budget used")
                    .accessibilityValue("60 percent")
                HStack {
                    Text("600 spent")
                    Spacer()
                    Text("400 left")
                }
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
            }
            .padding(.vertical, 12)
        default:
            HStack(spacing: 12) {
                ForEach(["play.rectangle", "music.note", "externaldrive"], id: \.self) { symbol in
                    Image(systemName: symbol)
                        .font(.title2)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .accessibilityLabel("Three recurring subscriptions")
        }
    }

    private var shortcuts: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("Keep it close", "Your spending.\nA glance away.", "Check your spending with a widget. Log a transaction with Siri or Shortcuts.")
            Group {
                if widgetIndex == 0 {
                    SpendyMediumWeekWidgetView(snapshot: .preview)
                } else {
                    SpendyMediumCategoriesWidgetView(snapshot: .preview)
                }
            }
            .id(widgetIndex)
            .transition(.opacity)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            Button(widgetIndex == 0 ? "Preview spending by category" : "Preview your spending pulse", systemImage: "rectangle.2.swap") {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                    widgetIndex = 1 - widgetIndex
                }
            }
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
            Text("Widget preview · Example data")
                .font(.caption).foregroundStyle(.secondary)
            Label("“Siri, log a transaction in Spendy.”", systemImage: "waveform")
                .font(.headline).padding(.vertical, 8)
            Text("Add widgets from your Home Screen. Set up the Action Button for quick logging whenever you’re ready.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var customization: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !isNameFocused {
                heading("One last thing", "Make it yours.", "A name, a currency, and your preferred look.")
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Your name").font(.headline)
                TextField("Your name (optional)", text: $inputName)
                    .textContentType(.nickname)
                    .textInputAutocapitalization(.words)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit { isNameFocused = false }
                    .padding(16)
                    .background(SpendyColors.cardBackgroundSecondary, in: RoundedRectangle(cornerRadius: 16))
            }
            Button {
                isNameFocused = false
                showCurrencyPicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Currency").font(.headline)
                        Text("\(store.currencyCode) · \(CurrencyInfo.name(for: store.currencyCode))")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(.vertical, 12).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if !isNameFocused {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Appearance").font(.headline)
                    HStack(spacing: 8) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Button {
                                withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.82)) {
                                    store.appearanceMode = mode
                                }
                            } label: {
                                VStack(spacing: 12) {
                                    HStack(spacing: 8) {
                                        appearanceMark(mode)
                                        Text(mode.rawValue)
                                            .font(.subheadline.weight(store.appearanceMode == mode ? .semibold : .regular))
                                    }
                                    .foregroundStyle(store.appearanceMode == mode ? Color.primary : Color.secondary)
                                    ZStack {
                                        Color.clear
                                        if store.appearanceMode == mode {
                                            Capsule()
                                                .fill(Color.primary)
                                                .matchedGeometryEffect(id: "appearance", in: appearanceSelection)
                                        }
                                    }
                                    .frame(width: 24, height: 2)
                                }
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(IntroPressStyle(reduceMotion: reduceMotion))
                            .accessibilityLabel(mode.rawValue + " appearance")
                            .accessibilityAddTraits(store.appearanceMode == mode ? .isSelected : [])
                        }
                    }
                }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.9), value: isNameFocused)
    }

    private func appearanceMark(_ mode: AppearanceMode) -> some View {
        Circle()
            .strokeBorder(lineWidth: 1)
            .background {
                if mode == .dark {
                    Circle().fill(.primary)
                } else if mode == .system {
                    Rectangle()
                        .fill(.primary)
                        .frame(width: 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clipShape(Circle())
                }
            }
            .frame(width: 14, height: 14)
            .accessibilityHidden(true)
    }

    private func move(to step: Int) {
        let destination = min(max(step, 0), totalSteps - 1)
        guard destination != currentStep else { return }
        isNameFocused = false
        movingForward = destination > currentStep
        withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.9)) {
            currentStep = destination
        }
    }

    private func finishSetup() {
        isNameFocused = false
        store.userName = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        HapticsManager.shared.trigger(.success)
        store.hasCompletedOnboarding = true
        onComplete()
        dismiss()
    }
}

#Preview {
    OnboardingView().environment(ExpenseStore())
}

private struct IntroPressStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
