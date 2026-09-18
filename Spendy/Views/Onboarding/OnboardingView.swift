//
//  OnboardingView.swift
//  Spendy
//
//  Cinematic onboarding: signature glow, random screen-filling sticker galaxy,
//  companion pick, then the companion introduces insights, subscriptions,
//  budget, and theme before currency, name, and a home handoff.
//

import SwiftUI

public struct OnboardingView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: Int = 0
    private let totalSteps: Int = 4

    @State private var inputName: String = ""
    @State private var chosenSticker: SpendySticker? = nil
    @State private var showFullCurrencyPicker: Bool = false

    @State private var isGradientAtTop: Bool = false
    @State private var stackedCount: Int = 0
    @State private var isBurstSpread: Bool = false
    @State private var isWordmarkVisible: Bool = false
    @State private var dissolvingOthers: Bool = false
    @State private var isCompanionCentered: Bool = false
    @State private var showPickedDetails: Bool = false
    @State private var showPickedContinue: Bool = false

    @State private var isSettingUp: Bool = false
    @State private var isLaunchingHome: Bool = false

    @State private var isFloatingLoop: Bool = false
    @State private var galaxySlots: [OnboardingGalaxyLayout.Slot] = []
    @State private var galaxySeed: UInt64 = UInt64.random(in: 1...UInt64.max)

    @FocusState private var isNameFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var allStickers: [SpendySticker] { SpendySticker.allCases }

    public init(initialStep: Int = 0) {
        if let stepArg = CommandLine.arguments.first(where: { $0.starts(with: "--onboarding-step=") }) {
            let val = stepArg.replacingOccurrences(of: "--onboarding-step=", with: "")
            if val == "0-picked" {
                _currentStep = State(initialValue: 0)
                _isGradientAtTop = State(initialValue: true)
                _stackedCount = State(initialValue: SpendySticker.allCases.count)
                _isBurstSpread = State(initialValue: true)
                _dissolvingOthers = State(initialValue: true)
                _isCompanionCentered = State(initialValue: true)
                _showPickedDetails = State(initialValue: true)
                _showPickedContinue = State(initialValue: true)
                _chosenSticker = State(initialValue: .catCompanion)
            } else if val == "0-burst" {
                _currentStep = State(initialValue: 0)
                _isGradientAtTop = State(initialValue: true)
                _stackedCount = State(initialValue: SpendySticker.allCases.count)
                _isBurstSpread = State(initialValue: true)
            } else if val == "loader" {
                _currentStep = State(initialValue: 3)
                _isGradientAtTop = State(initialValue: true)
                _isSettingUp = State(initialValue: true)
                _chosenSticker = State(initialValue: .catCompanion)
            } else if val == "0" {
                _currentStep = State(initialValue: 0)
            } else if let intVal = Int(val), intVal > 0 {
                _currentStep = State(initialValue: intVal)
                _isGradientAtTop = State(initialValue: true)
                _stackedCount = State(initialValue: SpendySticker.allCases.count)
                _isBurstSpread = State(initialValue: true)
                _dissolvingOthers = State(initialValue: true)
                _isCompanionCentered = State(initialValue: true)
                _showPickedDetails = State(initialValue: true)
                _showPickedContinue = State(initialValue: true)
                _chosenSticker = State(initialValue: .catCompanion)
            } else {
                _currentStep = State(initialValue: initialStep)
                _isGradientAtTop = State(initialValue: initialStep > 0)
            }
        } else {
            _currentStep = State(initialValue: initialStep)
            _isGradientAtTop = State(initialValue: initialStep > 0)
        }
    }

    public var body: some View {
        ZStack {
            backgroundCanvasLayer

            if isSettingUp {
                launchHandoffStage
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    topHeaderBar
                        .padding(.horizontal, 22)
                        .padding(.top, 10)

                    Group {
                        switch currentStep {
                        case 0:
                            introStickerGalaxyStage
                        case 1:
                            OnboardingCompanionTourStage(
                                companion: chosenSticker ?? fallbackCompanion,
                                onFinished: { advanceToNextStep() }
                            )
                        case 2, 3:
                            unifiedPersonalizationStage
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showFullCurrencyPicker) {
            CurrencyPickerSheet(
                selectedCode: store.currencyCode,
                onSelect: { currency in
                    store.updateCurrency(symbol: currency.symbol, code: currency.code)
                    HapticsManager.shared.trigger(.selection)
                    showFullCurrencyPicker = false
                }
            )
        }
        .onAppear {
            if store.currencyCode.isEmpty {
                store.updateCurrency(symbol: "₹", code: "INR")
            }
            if !store.userName.isEmpty && inputName.isEmpty {
                inputName = store.userName
            }
            if currentStep > 0 && chosenSticker == nil {
                chosenSticker = fallbackCompanion
            }

            if !reduceMotion {
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    isFloatingLoop = true
                }
            }

            if currentStep == 0 && !isBurstSpread {
                runIntroSequence()
            } else if currentStep == 0 && isBurstSpread && !isWordmarkVisible && !isCompanionCentered {
                revealWordmark(after: reduceMotion ? 80 : 400)
            }
        }
        .onChange(of: currentStep) { _, newStep in
            if newStep == 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    isNameFieldFocused = true
                }
            } else {
                isNameFieldFocused = false
            }
        }
    }

    private var fallbackCompanion: SpendySticker {
        if let saved = store.selectedSticker, let sticker = SpendySticker(rawValue: saved) {
            return sticker
        }
        return .catCompanion
    }

    private var isChromeVisible: Bool {
        currentStep > 0 || isBurstSpread
    }

    // MARK: - Background

    private var isGradientInCenter: Bool {
        !isGradientAtTop
    }

    private var backgroundCanvasLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                LiquidMeshBackground(style: .screen, opacity: 0.60)
                    .frame(width: w, height: h)
                    .opacity(isGradientInCenter ? 0.0 : 1.0)
                    .offset(y: isGradientInCenter ? 50 : 0)
                    .animation(.easeInOut(duration: 1.5), value: isGradientInCenter)

                diffusedCenterLiquidGradient
                    .position(
                        x: w / 2,
                        y: isGradientInCenter ? (h * 0.44) : -60
                    )
                    .scaleEffect(isGradientInCenter ? 1.0 : 1.35)
                    .opacity(isGradientInCenter ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.5), value: isGradientInCenter)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }

    private var diffusedCenterLiquidGradient: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: SpendySignatureTheme.deepElectricBlue.opacity(0.92), location: 0.0),
                            .init(color: SpendySignatureTheme.deepElectricBlue.opacity(0.60), location: 0.45),
                            .init(color: SpendySignatureTheme.deepElectricBlue.opacity(0.20), location: 0.76),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 370
                    )
                )
                .frame(width: 740, height: 740)
                .blur(radius: 90)

            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: SpendySignatureTheme.royalBlue.opacity(0.88), location: 0.0),
                            .init(color: SpendySignatureTheme.royalBlue.opacity(0.48), location: 0.52),
                            .init(color: Color.clear, location: 0.95)
                        ],
                        center: isFloatingLoop ? UnitPoint(x: 0.56, y: 0.46) : UnitPoint(x: 0.44, y: 0.54),
                        startRadius: 10,
                        endRadius: 290
                    )
                )
                .frame(width: 580, height: 580)
                .offset(
                    x: isFloatingLoop ? 24 : -24,
                    y: isFloatingLoop ? -18 : 18
                )
                .blur(radius: 75)

            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: SpendySignatureTheme.neonBlue.opacity(0.84), location: 0.0),
                            .init(color: SpendySignatureTheme.neonBlue.opacity(0.35), location: 0.48),
                            .init(color: Color.clear, location: 0.92)
                        ],
                        center: isFloatingLoop ? UnitPoint(x: 0.45, y: 0.40) : UnitPoint(x: 0.55, y: 0.48),
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .offset(
                    x: isFloatingLoop ? -28 : 28,
                    y: isFloatingLoop ? 20 : -20
                )
                .blur(radius: 55)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Top Header

    private var topHeaderBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.white : Color.white.opacity(0.18))
                        .frame(height: 3)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentStep)
                }
            }
            .opacity(isChromeVisible ? 1 : 0)

            HStack {
                if currentStep > 0 {
                    Button {
                        goToPreviousStep()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Back")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .transition(.opacity)
                } else {
                    Spacer()
                        .frame(width: 44, height: 44)
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button {
                        startSetupAndLaunch()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                            .contentShape(Rectangle())
                    }
                    .opacity(isChromeVisible ? 1 : 0)
                    .allowsHitTesting(isChromeVisible)
                }
            }
            .frame(height: 44)
        }
        .animation(.easeInOut(duration: 0.35), value: isChromeVisible)
    }

    // MARK: - STEP 0: Galaxy

    private var introStickerGalaxyStage: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let centerX = w / 2
            let centerY = h * 0.44

            ZStack {
                ForEach(Array(allStickers.enumerated()), id: \.element.id) { index, sticker in
                    galaxySticker(
                        sticker,
                        index: index,
                        centerX: centerX,
                        centerY: centerY
                    )
                }

                if isBurstSpread && isWordmarkVisible && !dissolvingOthers && !isCompanionCentered {
                    VStack(spacing: 8) {
                        Text("spendy")
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .tracking(-0.5)
                            .foregroundStyle(Color.white)

                        Text("choose your companion")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.65))
                    }
                    .position(x: centerX, y: centerY)
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(40)
                } else if isCompanionCentered, let active = chosenSticker {
                    if showPickedDetails {
                        VStack(spacing: 12) {
                            SpendyComicSpeechBubble(
                                active.subtitle,
                                tailDirection: .topTrailing,
                                fontSize: 14,
                                maxWidth: 260
                            )
                            
                            SpendyComicBadge(
                                active.title,
                                palette: .cyberGold,
                                size: .small,
                                rotationAngle: -5
                            )

                            Button {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                                    isCompanionCentered = false
                                    dissolvingOthers = false
                                    showPickedDetails = false
                                    showPickedContinue = false
                                    chosenSticker = nil
                                }
                            } label: {
                                Text("choose another companion")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.75))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .nativeLiquidGlassCapsule(isInteractive: true)
                                    .padding(.top, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .position(x: centerX, y: centerY + 118)
                        .transition(.opacity.combined(with: .offset(y: 14)))
                        .zIndex(41)
                    }

                    if showPickedContinue {
                        VStack {
                            Spacer()
                            Button {
                                advanceToNextStep()
                            } label: {
                                HStack(spacing: 8) {
                                    Text("continue")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Capsule().fill(Color.white))
                                .nativeLiquidGlassCapsule(isInteractive: true)
                                .shadow(color: Color.white.opacity(0.30), radius: 14, y: 6)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(42)
                    }
                }
            }
            .frame(width: w, height: h)
            .animation(.easeInOut(duration: 0.50), value: isWordmarkVisible)
            .onAppear { ensureGalaxySlots(size: geo.size) }
            .onChange(of: geo.size) { _, newSize in
                if galaxySlots.count != allStickers.count {
                    ensureGalaxySlots(size: newSize)
                }
            }
        }
    }

    @ViewBuilder
    private func galaxySticker(
        _ sticker: SpendySticker,
        index: Int,
        centerX: CGFloat,
        centerY: CGFloat
    ) -> some View {
        let isSelected = chosenSticker == sticker
        let isVisible = index < stackedCount
        let slot = slotForSticker(index: index)
        let stack = OnboardingGalaxyLayout.stackJitter(for: index)
        let currentSize: CGFloat = isSelected && isCompanionCentered ? 215 : (isBurstSpread ? slot.size : 158)

        let floatDirection: CGFloat = (index % 2 == 0) ? 1.0 : -1.0
        let floatY: CGFloat = isBurstSpread && !isCompanionCentered ? (isFloatingLoop ? -9 * floatDirection : 9 * floatDirection) : 0
        let floatRot: Double = isBurstSpread && !isCompanionCentered ? (isFloatingLoop ? 2.4 * Double(floatDirection) : -2.4 * Double(floatDirection)) : 0
        let floatScale: CGFloat = 1.0

        let spreadX = slot.x * (dissolvingOthers && !isSelected ? 1.55 : 1.0)
        let spreadY = slot.y * (dissolvingOthers && !isSelected ? 1.55 : 1.0)

        let targetX = isSelected && isCompanionCentered
            ? centerX
            : (isBurstSpread ? centerX + spreadX : centerX + stack.x)
        let targetY = isSelected && isCompanionCentered
            ? centerY - 48 + (isFloatingLoop ? -6 : 6)
            : (isBurstSpread ? centerY + spreadY + floatY : centerY + stack.y)

        Button {
            guard isBurstSpread, isWordmarkVisible, !dissolvingOthers else { return }
            selectCompanion(sticker)
        } label: {
            sticker.image
                .resizable()
                .scaledToFit()
                .frame(width: currentSize, height: currentSize)
                .rotationEffect(.degrees(
                    isSelected && isCompanionCentered
                        ? 0
                        : (isBurstSpread ? slot.rotation + floatRot : stack.rotation)
                ))
                .shadow(
                    color: Color.black.opacity(isSelected ? 0.45 : (isFloatingLoop ? 0.35 : 0.22)),
                    radius: isSelected ? 24 : (isFloatingLoop ? 14 : 8),
                    y: isSelected ? 16 : (isFloatingLoop ? 10 : 4)
                )
                .scaleEffect(
                    isVisible
                        ? (isSelected && isCompanionCentered
                            ? (isFloatingLoop ? 1.03 : 0.97)
                            : (dissolvingOthers && !isSelected ? 0.22 : floatScale))
                        : 1.8
                )
                .opacity(
                    isVisible
                        ? (dissolvingOthers && !isSelected ? 0.0 : 1.0)
                        : 0.0
                )
        }
        .buttonStyle(OnboardingStickerPressStyle())
        .frame(
            width: isSelected && isCompanionCentered ? 220 : max(slot.size, 110),
            height: isSelected && isCompanionCentered ? 220 : max(slot.size, 110)
        )
        .contentShape(Rectangle())
        .position(x: targetX, y: targetY)
        .zIndex(isSelected ? 30 : Double(index))
        .disabled(!isBurstSpread || !isWordmarkVisible || (dissolvingOthers && !isSelected))
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.2)
                : .spring(response: 0.72, dampingFraction: 0.68).delay(isBurstSpread ? slot.burstDelay : 0),
            value: isBurstSpread
        )
        .animation(.easeInOut(duration: 0.42), value: dissolvingOthers)
        .animation(.spring(response: 0.65, dampingFraction: 0.76), value: isCompanionCentered)
        .accessibilityLabel(sticker.title)
        .accessibilityHint("Choose this companion")
        .accessibilityHidden(!isBurstSpread || (dissolvingOthers && !isSelected))
    }

    private func slotForSticker(index: Int) -> OnboardingGalaxyLayout.Slot {
        if galaxySlots.indices.contains(index) {
            return galaxySlots[index]
        }
        return OnboardingGalaxyLayout.Slot(x: 0, y: 0, rotation: 0, size: 118)
    }

    private func ensureGalaxySlots(size: CGSize) {
        guard size.width > 40, size.height > 40 else { return }
        if galaxySlots.count != allStickers.count {
            galaxySlots = OnboardingGalaxyLayout.makeSlots(
                count: allStickers.count,
                canvas: size,
                seed: galaxySeed
            )
        }
    }

    // MARK: - STEPS 2 & 3: Personalization

    private var unifiedPersonalizationStage: some View {
        VStack(spacing: 24) {
            if let companion = chosenSticker {
                FloatingStickerView(sticker: companion, size: 155)
                    .padding(.top, 8)
            }

            ZStack {
                if currentStep == 2 {
                    VStack(spacing: 6) {
                        Text("choose currency")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)

                        Text("select your primary currency. you can change this anytime.")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 8)),
                        removal: .opacity.combined(with: .offset(y: -8))
                    ))
                } else {
                    VStack(spacing: 6) {
                        Text("what’s your name?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)

                        Text(namePrompt)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 8)),
                        removal: .opacity.combined(with: .offset(y: -8))
                    ))
                }
            }
            .frame(minHeight: 72)
            .animation(.easeInOut(duration: 0.40), value: currentStep)

            ZStack {
                if currentStep == 2 {
                    VStack(spacing: 12) {
                        Button {
                            HapticsManager.shared.trigger(.selection)
                            showFullCurrencyPicker = true
                        } label: {
                            HStack(spacing: 16) {
                                Text(CurrencyInfo.flag(for: store.currencyCode))
                                    .font(.system(size: 40))

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(store.currencySymbol)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .monospacedDigit()
                                        Text(store.currencyCode)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(Color.white)

                                    Text(CurrencyInfo.name(for: store.currencyCode))
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(Color.white.opacity(0.65))
                                }

                                Spacer()

                                HStack(spacing: 4) {
                                    Text("change")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .nativeLiquidGlassCapsule(isInteractive: true)
                            }
                            .padding(20)
                            .nativeLiquidGlass(cornerRadius: 24, isInteractive: true)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)

                        Text("tap card to choose from 160+ currencies")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    ))
                } else {
                    HStack(spacing: 14) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.70))
                            .frame(width: 28)

                        TextField("your name", text: $inputName)
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white)
                            .autocorrectionDisabled()
                            .focused($isNameFieldFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                startSetupAndLaunch()
                            }
                            .onChange(of: inputName) { _, _ in
                                HapticsManager.shared.trigger(.selection)
                            }

                        if !inputName.isEmpty {
                            Button {
                                inputName = ""
                                HapticsManager.shared.trigger(.light)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.white.opacity(0.40))
                            }
                            .frame(minWidth: 36, minHeight: 36)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .nativeLiquidGlass(cornerRadius: 22, isInteractive: true)
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    ))
                }
            }
            .animation(.easeInOut(duration: 0.38), value: currentStep)

            Spacer()

            Button {
                if currentStep == 2 {
                    advanceToNextStep()
                } else {
                    startSetupAndLaunch()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentStep == 2 ? "continue" : "start")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .id("personalizationBtnTitle_\(currentStep)")
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 4)),
                            removal: .opacity.combined(with: .offset(y: -4))
                        ))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(Color.white))
                .nativeLiquidGlassCapsule(isInteractive: true)
                .shadow(color: Color.white.opacity(0.30), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .animation(.easeInOut(duration: 0.30), value: currentStep)
        }
    }

    private var namePrompt: String {
        if let companion = chosenSticker {
            return "so \(companion.title.lowercased()) knows who to talk to."
        }
        return "to personalize your daily dashboard."
    }

    // MARK: - Launch Handoff

    private var launchHandoffStage: some View {
        GeometryReader { geo in
            let companion = chosenSticker ?? fallbackCompanion
            VStack(spacing: 16) {
                Spacer()
                FloatingStickerView(sticker: companion, size: isLaunchingHome ? 64 : 168, interactiveTap: false)
                    .offset(
                        x: isLaunchingHome ? -geo.size.width * 0.38 : 0,
                        y: isLaunchingHome ? -geo.size.height * 0.38 : 0
                    )
                    .opacity(isLaunchingHome ? 0.0 : 1.0)
                    .animation(.spring(response: 0.88, dampingFraction: 0.86), value: isLaunchingHome)

                Text(companion.launchLine)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .opacity(isLaunchingHome ? 0 : 1)

                Text("setting up spendy for you...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .opacity(isLaunchingHome ? 0 : 1)

                Spacer()
            }
            .animation(.easeInOut(duration: 0.35), value: isLaunchingHome)
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Actions

    private func runIntroSequence() {
        Task { @MainActor in
            isGradientAtTop = false
            stackedCount = 0
            isBurstSpread = false

            try? await Task.sleep(for: .milliseconds(reduceMotion ? 80 : 320))
            guard currentStep == 0 && !isBurstSpread else { return }

            if reduceMotion {
                stackedCount = allStickers.count
                isBurstSpread = true
                isGradientAtTop = true
                isWordmarkVisible = true
                return
            }

            for i in 1...allStickers.count {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.70)) {
                    stackedCount = i
                }
                HapticsManager.shared.trigger(i == allStickers.count ? .medium : .light)
                try? await Task.sleep(for: .milliseconds(170))
            }

            try? await Task.sleep(for: .milliseconds(420))
            guard currentStep == 0 && !isBurstSpread else { return }

            withAnimation(.easeInOut(duration: 1.6)) {
                isGradientAtTop = true
            }
            HapticsManager.shared.trigger(.cardSnap)
            isBurstSpread = true
            revealWordmark(after: 900)
        }
    }

    private func revealWordmark(after milliseconds: Int) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(milliseconds))
            guard currentStep == 0, isBurstSpread, !isCompanionCentered else { return }
            withAnimation(.easeInOut(duration: 0.50)) {
                isWordmarkVisible = true
            }
        }
    }

    private func selectCompanion(_ sticker: SpendySticker) {
        HapticsManager.shared.trigger(.selection)
        chosenSticker = sticker
        store.selectedSticker = sticker.rawValue
        if let uiImage = UIImage(named: sticker.assetName),
           let data = uiImage.pngData() {
            store.profileImageData = data
        }

        showPickedDetails = false
        showPickedContinue = false

        withAnimation(.easeInOut(duration: 0.42)) {
            dissolvingOthers = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            HapticsManager.shared.trigger(.cardSnap)
            withAnimation(.spring(response: 0.68, dampingFraction: 0.76)) {
                isCompanionCentered = true
            }

            try? await Task.sleep(for: .milliseconds(reduceMotion ? 80 : 520))
            guard chosenSticker == sticker, isCompanionCentered else { return }
            withAnimation(.easeInOut(duration: 0.55)) {
                showPickedDetails = true
            }

            try? await Task.sleep(for: .milliseconds(reduceMotion ? 80 : 640))
            guard chosenSticker == sticker, isCompanionCentered else { return }
            withAnimation(.easeOut(duration: 0.75).delay(0.05)) {
                showPickedContinue = true
            }
        }
    }

    private func goToPreviousStep() {
        guard currentStep > 0 else { return }
        HapticsManager.shared.trigger(.light)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            currentStep -= 1
        }
    }

    private func advanceToNextStep() {
        HapticsManager.shared.trigger(.medium)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            currentStep += 1
        }
    }

    private func startSetupAndLaunch() {
        isNameFieldFocused = false
        let clean = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.isEmpty {
            store.userName = clean
        }
        let sticker = chosenSticker ?? .catCompanion
        chosenSticker = sticker
        if store.profileImageData == nil,
           let uiImage = UIImage(named: sticker.assetName),
           let data = uiImage.pngData() {
            store.profileImageData = data
        }
        store.selectedSticker = sticker.rawValue

        HapticsManager.shared.trigger(.medium)

        withAnimation(.easeInOut(duration: 0.35)) {
            isSettingUp = true
            isGradientAtTop = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 400 : 720))
            withAnimation(.spring(response: 0.90, dampingFraction: 0.86)) {
                isLaunchingHome = true
            }
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 280 : 880))
            HapticsManager.shared.trigger(.success)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                store.hasCompletedOnboarding = true
            }
            dismiss()
        }
    }
}

private struct OnboardingStickerPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.52), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
