import SwiftUI
import WidgetKit

/// A small, hands-on introduction. Demo interactions never create financial records.
public struct OnboardingView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @GestureState private var pageDrag: CGFloat = 0
    @State private var currentStep: Int
    @State private var movingForward = true
    @State private var showCurrencyPicker = false
    @FocusState private var isNameFocused: Bool
    @State private var demoVisible = false
    @State private var mediumWidget = false
    @State private var shortcutType: TransactionType?
    @State private var brandVisible = false
    @State private var remindersAllowed = false
    @State private var requestingReminders = false
    private let totalSteps = 7
    private let onComplete: () -> Void

    public init(initialStep: Int = 0, onComplete: @escaping () -> Void = {}) {
        #if DEBUG
        let argument = CommandLine.arguments.first { $0.starts(with: "--onboarding-step=") }
        let requested = argument.flatMap { Int($0.replacingOccurrences(of: "--onboarding-step=", with: "")) }
        #else
        let requested: Int? = nil
        #endif
        _currentStep = State(initialValue: min(max(requested ?? initialStep, 0), 6))
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
        .background(introBackground.ignoresSafeArea())
        .foregroundStyle(SpendyColors.textPrimary)
        .tint(SpendyColors.textPrimary)
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selectedCode: store.currencyCode) { currency in
                store.updateCurrency(symbol: currency.symbol, code: currency.code)
                showCurrencyPicker = false
            }
        }
        .task(id: currentStep) {
            demoVisible = false
            brandVisible = false
            if currentStep == 4 { mediumWidget = false }
            if currentStep == 3 { shortcutType = nil }
            do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? .easeIn(duration: 0.2) : .spring(response: 0.55, dampingFraction: 0.82)) {
                demoVisible = true
            }
            do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: reduceMotion ? 0.15 : 0.6)) { brandVisible = true }
            if currentStep == 3 {
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                guard !Task.isCancelled, shortcutType == nil else { return }
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.88)) {
                    shortcutType = .expense
                }
            }
        }
        .sensoryFeedback(.selection, trigger: currentStep)
    }

    private var introBackground: some View {
        GeometryReader { geometry in
            ZStack {
                SpendyColors.appBackground
                RadialGradient(colors: [SpendyColors.textPrimary.opacity(0.09), .clear],
                    center: UnitPoint(x: currentStep.isMultiple(of: 2) ? 0.28 : 0.72, y: 0.36),
                    startRadius: 12, endRadius: geometry.size.width * 0.95)
                LinearGradient(colors: [.clear, SpendyColors.textPrimary.opacity(0.025)], startPoint: .top, endPoint: .bottom)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: currentStep)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var pageContent: some View {
        stepContent
            .frame(maxWidth: 480, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, 24)
            .padding(.vertical, isNameFocused ? 8 : 16)
            .frame(maxHeight: dynamicTypeSize.isAccessibilitySize ? nil : .infinity)
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
        ["Get started", "Continue", "Continue", "Continue", "Continue", remindersAllowed ? "Continue" : "Enable reminders", "Open Spendy"][currentStep]
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
                if currentStep == 5 && !remindersAllowed { enableReminders() }
                else if currentStep == totalSteps - 1 { finishSetup() }
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
                .foregroundStyle(SpendyColors.textPrimary)
                .nativeLiquidGlassCapsule(isInteractive: false)
            }
            .buttonStyle(IntroPressStyle(reduceMotion: reduceMotion))
            .disabled(requestingReminders)
            if currentStep == 5 {
                Button("Not now") { move(to: 6) }
                    .font(.subheadline).frame(minHeight: 44)
                    .foregroundStyle(.secondary)
                    .disabled(requestingReminders)
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
        case 1: insights
        case 2: planning
        case 3: shortcuts
        case 4: widgets
        case 5: reminders
        default: customization
        }
    }

    private func heading(_ eyebrow: String, _ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(AppTypography.largeTitle)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func featurePage<Preview: View>(_ title: String, _ detail: String, @ViewBuilder preview: () -> Preview) -> some View {
        VStack(spacing: 24) {
            preview()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 12) {
                Text(title)
                    .font(AppTypography.largeTitle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 16)
        }
    }

    private var welcome: some View {
        featurePage("A little clarity.\nEvery day.", "Spending, budgets, and bills. Together.") {
            VStack(spacing: 24) {
                SpendyCoffeeMascot().frame(width: 160, height: 175)
                VStack(spacing: 0) {
                    introTransaction("Coffee & Cafés", icon: "cup.and.saucer.fill", amount: 25)
                    Divider().padding(.leading, 64)
                    introTransaction("Groceries", icon: "cart.fill", amount: 740)
                    Divider().padding(.leading, 64)
                    introTransaction("Fuel", icon: "fuelpump.fill", amount: 500)
                }
                .padding(.horizontal, 16)
                .background(SpendyColors.recentActivityBackground, in: RoundedRectangle(cornerRadius: 26))
            }
            .modifier(IntroDemoEntrance(visible: demoVisible, reduceMotion: reduceMotion))
        }
    }

    private func introTransaction(_ name: String, icon: String, amount: Double) -> some View {
        HStack(spacing: 12) {
            SpendyIconBadge(sfSymbol: icon, color: SpendyColors.textPrimary, size: .medium, style: .circle, monogramName: name)
            Text(name).font(.subheadline.weight(.semibold))
            Spacer(minLength: 4)
            Text(amount.formattedCurrency(symbol: store.currencySymbol)).font(.subheadline.weight(.semibold)).monospacedDigit()
        }
        .padding(.vertical, 12)
    }

    private var insights: some View {
        featurePage("Your spending.\nUnderstood.", "Personal insights, calculated on your device.") {
            VStack(spacing: 20) {
                Image(systemName: SpendyInsightBrandMark.symbol)
                    .font(.system(size: 48, weight: .light))
                    .symbolEffect(.pulse, value: demoVisible)
                    .scaleEffect(reduceMotion || demoVisible ? 1 : 0.6)
                    .opacity(demoVisible ? 1 : 0)
                    .accessibilityHidden(true)
                ShinyText(text: "spendy insights", font: .title2.weight(.semibold),
                    color: SpendyColors.textPrimary, shineColor: SpendyColors.textPrimary, speed: 1.8, delay: 0)
                    .opacity(brandVisible ? 1 : 0)
                    .offset(y: reduceMotion || brandVisible ? 0 : 8)
                    .accessibilityIdentifier("intro-insight-brand")
                VStack(alignment: .leading, spacing: 10) {
                    let days = SpendyWidgetSnapshot.preview.weeklySpending
                    let total = days.reduce(0) { $0 + $1.amount }
                    let peak = days.enumerated().max { $0.element.amount < $1.element.amount }
                    Text("Last 7 days").font(.caption).foregroundStyle(.secondary)
                    Text(total.formattedCurrency(symbol: store.currencySymbol)).font(AppTypography.heroAmount)
                    SpendyWeekBars(days: days, accentHex: "", height: 44)
                    if let peak, total > 0 {
                        let day = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][peak.offset % 7]
                        ShinyHeadlineText(headline: "\(peak.element.amount.formattedCurrency(symbol: store.currencySymbol)) on \(day) · \(Int((peak.element.amount / total * 100).rounded()))% of the week.",
                            emphasis: [], font: .subheadline.weight(.semibold), emphasisFont: .subheadline.bold())
                    }
                }
                .padding(20)
                .nativeLiquidGlass(cornerRadius: 26, isInteractive: false)
                .opacity(brandVisible ? 1 : 0)
            }
        }
    }

    private var planning: some View {
        featurePage("Room to spend.\nBills in view.", "Budgets and subscriptions, side by side.") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Budget room").font(.subheadline).foregroundStyle(.secondary)
                    Text(4000.formattedCurrency(symbol: store.currencySymbol)).font(AppTypography.heroAmount)
                    ProgressView(value: 0.6).tint(SpendyColors.textPrimary)
                        .accessibilityLabel("Budget used").accessibilityValue("60 percent")
                    HStack {
                        Text("\(6000.formattedCurrency(symbol: store.currencySymbol, decimals: 0)) spent")
                        Spacer()
                        Text("of \(10000.formattedCurrency(symbol: store.currencySymbol, decimals: 0))")
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
                .padding(20)
                .nativeLiquidGlass(cornerRadius: 26, isInteractive: false)
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Subscriptions").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text("\(148.formattedCurrency(symbol: store.currencySymbol, decimals: 0))/mo").font(.subheadline.weight(.semibold))
                    }
                    ForEach(["Music", "Storage"], id: \.self) { name in
                        HStack(spacing: 12) {
                            SpendyIconBadge(sfSymbol: name == "Music" ? "music.note" : "externaldrive", color: SpendyColors.textPrimary, size: .small, style: .circle)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name).font(.subheadline.weight(.semibold))
                                Text(name == "Music" ? "Renews tomorrow" : "Renews in 3 days").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text((name == "Music" ? 99.0 : 49.0).formattedCurrency(symbol: store.currencySymbol, decimals: 0)).font(.subheadline.weight(.semibold))
                        }
                    }
                }
                .padding(20)
                .nativeLiquidGlass(cornerRadius: 26, isInteractive: false)
            }
            .modifier(IntroDemoEntrance(visible: demoVisible, reduceMotion: reduceMotion))
        }
    }

    private var shortcuts: some View {
        featurePage("A shortcut\nto your day.", "“Siri, log transaction in Spendy.”") {
            VStack(alignment: .leading, spacing: 20) {
                if shortcutType == nil {
                    Text("Expense or income?").font(AppTypography.sectionTitle)
                    VStack(spacing: 0) {
                        ForEach([TransactionType.expense, .income], id: \.self) { type in
                            Button {
                                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.88)) { shortcutType = type }
                            } label: {
                                Label(type == .expense ? "Expense" : "Income", systemImage: type == .expense ? "arrow.up.right" : "arrow.down.left")
                                    .font(.title3).frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                                    .padding(.horizontal, 18)
                            }
                            .buttonStyle(.plain)
                            if type == .expense { Divider().padding(.horizontal, 18) }
                        }
                    }
                    .background(SpendyColors.textPrimary.opacity(0.06), in: RoundedRectangle(cornerRadius: 22))
                } else {
                    Text("Amount").font(AppTypography.sectionTitle)
                    Text("11.11").font(AppTypography.heroAmount).frame(maxWidth: .infinity, minHeight: 76)
                        .background(SpendyColors.textPrimary.opacity(0.06), in: RoundedRectangle(cornerRadius: 22))
                    HStack(spacing: 12) {
                        ForEach(["Cancel", "Done"], id: \.self) { title in
                            Button(title) { withAnimation { shortcutType = nil } }
                                .font(.headline).frame(maxWidth: .infinity, minHeight: 48)
                                .nativeLiquidGlassCapsule(isInteractive: false)
                        }
                    }
                }
            }
            .padding(22)
            .nativeLiquidGlass(cornerRadius: 30, isInteractive: false)
            .modifier(IntroDemoEntrance(visible: demoVisible, reduceMotion: reduceMotion))
            .accessibilityIdentifier("intro-shortcut-preview")
        }
    }

    private var widgets: some View {
        featurePage("Your day.\nAt a glance.", "Spendy, on your Home Screen.") {
            GeometryReader { geometry in
                let width = mediumWidget ? geometry.size.width : (geometry.size.width - 16) / 2
                let layout = mediumWidget
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                    : AnyLayout(HStackLayout(alignment: .center, spacing: 16))
                layout {
                    Button {
                        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.86)) { mediumWidget.toggle() }
                    } label: {
                        ZStack {
                            SpendySmallWidgetView(snapshot: .preview).opacity(mediumWidget ? 0 : 1)
                            SpendyMediumWeekWidgetView(snapshot: .preview).opacity(mediumWidget ? 1 : 0)
                        }
                        .frame(width: width, height: 170)
                        .environment(\.spendyWidgetGlassPreview, true)
                        .nativeLiquidGlass(cornerRadius: 24, isInteractive: false)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .accessibilityHidden(true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Resize widget preview")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityValue(mediumWidget ? "Medium" : "Small")
                    .accessibilityHint("Double tap to switch between small and medium")
                    .accessibilityIdentifier("intro-widget-resize")
                    .modifier(IntroDemoEntrance(visible: demoVisible, reduceMotion: reduceMotion))
                    SpendyQuickActionsWidgetView(snapshot: .preview, previewFamily: mediumWidget ? .systemMedium : .systemSmall)
                        .environment(\.spendyWidgetGlassPreview, true)
                        .frame(width: width, height: mediumWidget ? 110 : 170)
                        .nativeLiquidGlass(cornerRadius: 24, isInteractive: false)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .allowsHitTesting(false)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Quick launch widget: Add, Scan, Trends")
                        .accessibilityIdentifier("intro-quick-launch-widget")
                        .modifier(IntroDemoEntrance(visible: demoVisible, reduceMotion: reduceMotion))
                }
            }
            .frame(height: mediumWidget ? 296 : 170)
        }
    }

    private var reminders: some View {
        featurePage("A timely\nheads-up.", "Renewal reminders and weekly summaries.") {
            VStack(spacing: 28) {
                Text("11:11").font(.system(size: 64, weight: .light)).foregroundStyle(.secondary).accessibilityHidden(true)
                HStack(spacing: 12) {
                    Image("SpendyLogo").resizable().scaledToFit().frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Weekly summary").font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("now").font(.caption).foregroundStyle(.secondary)
                        }
                        Text("\(125.formattedCurrency(symbol: store.currencySymbol)) recorded this week.").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .nativeLiquidGlass(cornerRadius: 24, isInteractive: false)
                .modifier(IntroDemoEntrance(visible: demoVisible, reduceMotion: reduceMotion))
            }
        }
    }

    private func enableReminders() {
        guard !requestingReminders else { return }
        requestingReminders = true
        Task {
            let allowed = await NotificationManager.shared.requestAuthorization()
            if allowed {
                store.notificationsEnabled = true
                store.weeklySummaryEnabled = true
                NotificationManager.shared.refresh(from: store)
            }
            remindersAllowed = allowed
            requestingReminders = false
            move(to: 6)
        }
    }

    private var customization: some View {
        featurePage("Ready for\nyour everyday.", "Choose your currency.") {
            VStack(spacing: 30) {
                Image("SpendyLogo").resizable().scaledToFit().frame(width: 160, height: 160)
                Button { showCurrencyPicker = true } label: {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(store.currencyCode).font(AppTypography.heroAmount)
                            Text(CurrencyInfo.name(for: store.currencyCode)).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.headline)
                    }
                    .padding(24)
                    .nativeLiquidGlass(cornerRadius: 28, isInteractive: false)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose currency")
            }
            .modifier(IntroDemoEntrance(visible: demoVisible, reduceMotion: reduceMotion))
        }
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

private struct IntroDemoEntrance: ViewModifier {
    let visible: Bool
    let reduceMotion: Bool
    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .scaleEffect(reduceMotion || visible ? 1 : 0.94)
            .offset(y: reduceMotion || visible ? 0 : -18)
    }
}
