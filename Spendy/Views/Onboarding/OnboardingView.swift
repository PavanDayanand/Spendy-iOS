//
//  OnboardingView.swift
//  Spendy
//
//  Artistic, minimal, and ultra-smooth onboarding experience.
//  Features:
//  - Pure black canvas with signature 3-color liquid mesh gradient in a center circle
//  - 10 stickers drop into center one by one stacking with haptic feedback
//  - 0.5s pause, then explosive asymmetric burst spread across the screen
//  - Centered lowercase "spendy" with "choose your companion" prompt
//  - Tapping a sticker dissolves other 9; chosen sticker glides to center
//  - Editorial feature showcase with 3 transaction cards animated one-by-one
//  - Clean currency selector defaulting to India (INR, ₹)
//  - Minimalist name input without emojis or colored greeting
//  - Exit transition: UI vanishes, circular gradient in center with loader & subtext
//  - 100% tactile haptics, zero sound effects
//

import SwiftUI

public struct OnboardingView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    // Steps:
    // 0: Stacking -> Burst Galaxy -> Pick Companion -> Glide to Center
    // 1: Feature Showcase (3 stacked transaction cards + companion)
    // 2: Choose Currency (defaults to INR ₹)
    // 3: What's your name? -> "start"
    // isSettingUp = true: Loader screen ("setting up spendy for you...")
    @State private var currentStep: Int = 0
    private let totalSteps: Int = 4
    
    // User profile state
    @State private var inputName: String = ""
    @State private var chosenSticker: SpendySticker? = nil
    @State private var showFullCurrencyPicker: Bool = false
    
    // Step 0 animation states
    @State private var isGradientAtTop: Bool = false
    @State private var stackedCount: Int = 0
    @State private var isBurstSpread: Bool = false
    @State private var dissolvingOthers: Bool = false
    @State private var isCompanionCentered: Bool = false
    
    // Step 1 feature cards state
    @State private var visibleCardsCount: Int = 0
    
    // Setting up Spendy final loader state
    @State private var isSettingUp: Bool = false
    
    // Subtle ambient floating pulse
    @State private var isFloatingLoop: Bool = false
    
    // Focus & Accessibility
    @FocusState private var isNameFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Stack offsets and rotations for the 8 stickers when stacked in center
    private let stackOffsets: [(x: CGFloat, y: CGFloat)] = [
        (0, 0), (-3, 2), (4, -1), (-2, 3), (3, -2),
        (-4, 1), (2, -3), (0, 0)
    ]
    private let stackRotations: [Double] = [
        -4, 3, -2, 5, -6, 2, -3, 1
    ]
    
    public init(initialStep: Int = 0) {
        if let stepArg = CommandLine.arguments.first(where: { $0.starts(with: "--onboarding-step=") }) {
            let val = stepArg.replacingOccurrences(of: "--onboarding-step=", with: "")
            if val == "0-picked" {
                _currentStep = State(initialValue: 0)
                _isGradientAtTop = State(initialValue: true)
                _stackedCount = State(initialValue: 8)
                _isBurstSpread = State(initialValue: true)
                _dissolvingOthers = State(initialValue: true)
                _isCompanionCentered = State(initialValue: true)
                _chosenSticker = State(initialValue: .catCompanion)
            } else if val == "0-burst" {
                _currentStep = State(initialValue: 0)
                _isGradientAtTop = State(initialValue: true)
                _stackedCount = State(initialValue: 8)
                _isBurstSpread = State(initialValue: true)
                _dissolvingOthers = State(initialValue: false)
                _isCompanionCentered = State(initialValue: false)
            } else if val == "loader" {
                _currentStep = State(initialValue: 3)
                _isGradientAtTop = State(initialValue: false)
                _isSettingUp = State(initialValue: true)
                _chosenSticker = State(initialValue: .catCompanion)
            } else if val == "0" {
                _currentStep = State(initialValue: 0)
                _isGradientAtTop = State(initialValue: false)
                _stackedCount = State(initialValue: 0)
                _isBurstSpread = State(initialValue: false)
                _dissolvingOthers = State(initialValue: false)
                _isCompanionCentered = State(initialValue: false)
                _chosenSticker = State(initialValue: nil)
            } else if let intVal = Int(val), intVal > 0 {
                _currentStep = State(initialValue: intVal)
                _isGradientAtTop = State(initialValue: true)
                _stackedCount = State(initialValue: 8)
                _isBurstSpread = State(initialValue: true)
                _dissolvingOthers = State(initialValue: true)
                _isCompanionCentered = State(initialValue: true)
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
            // MARK: - 1. Screen Canvas & Gradient Layer
            backgroundCanvasLayer
            
            // MARK: - 2. Step Content or Setting Up Loader
            if isSettingUp {
                settingUpLoaderStage
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    // Top Bar (Back / Progress / Skip)
                    topHeaderBar
                        .padding(.horizontal, 22)
                        .padding(.top, 10)
                    
                    // Main Stage View
                    Group {
                        switch currentStep {
                        case 0:
                            introStickerGalaxyStage
                        case 1:
                            featureShowcaseStage
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
            // Ensure INR default if uninitialized
            if store.currencyCode.isEmpty {
                store.updateCurrency(symbol: "₹", code: "INR")
            }
            if !store.userName.isEmpty && inputName.isEmpty {
                inputName = store.userName
            }
            if currentStep > 0 && chosenSticker == nil {
                if let saved = store.selectedSticker, let sticker = SpendySticker(rawValue: saved) {
                    chosenSticker = sticker
                } else {
                    chosenSticker = .catCompanion
                }
            }
            
            // Start subtle ambient float loop
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    isFloatingLoop = true
                }
            }
            
            // Run intro sequence if starting at step 0 unburst
            if currentStep == 0 && !isBurstSpread {
                runIntroSequence()
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
    
    // MARK: - Background Layer
    // App opens: A wide, atmospheric liquid gradient breathes in the middle of the black canvas.
    // Then slowly glides up to the top, forming the exact signature home screen header gradient.
    private var isGradientInCenter: Bool {
        !isGradientAtTop || isSettingUp
    }
    
    private var backgroundCanvasLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // 1. Home Screen Top Header Gradient (Active when at top)
                LiquidMeshBackground(style: .screen, opacity: 0.60)
                    .frame(width: w, height: h)
                    .opacity(isGradientInCenter ? 0.0 : 1.0)
                    .offset(y: isGradientInCenter ? 50 : 0)
                    .animation(.easeInOut(duration: 1.5), value: isGradientInCenter)
                
                // 2. Diffused Liquid Ambient Gradient (Starts in center, glides up to header)
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
    
    // MARK: - Diffused Liquid Ambient Gradient Layer
    // A wide, atmospheric, soft liquid mesh blending the signature 3 colors:
    // Neon Electric Blue (#00E5FF), Royal Blue (#1870FF), Deep Electric Blue (#1B17E9).
    // Spreads widely across the AMOLED black canvas without appearing as a rigid circle ball.
    private var diffusedCenterLiquidGradient: some View {
        ZStack {
            // Layer 1: Wide Deep Electric Blue (#1B17E9) ambient floor spreading into black
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
            
            // Layer 2: Saturated Royal Blue (#1870FF) drifting fluid body
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
            
            // Layer 3: Luminous Neon Electric Blue (#00E5FF) fluid crest
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
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        VStack(spacing: 12) {
            // Segmented Progress Bar
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(
                            index <= currentStep
                                ? Color.white
                                : Color.white.opacity(0.18)
                        )
                        .frame(height: 3)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentStep)
                }
            }
            .opacity(currentStep > 0 || isCompanionCentered ? 1 : 0.4)
            
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
                }
            }
            .frame(height: 44)
        }
    }
    
    // MARK: - STEP 0: Stacking -> Burst Galaxy -> Pick Companion
    private var introStickerGalaxyStage: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let centerX = w / 2
            let centerY = h * 0.44  // True optical and geometric center!
            let allStickers = SpendySticker.allCases
            
            ZStack {
                // MARK: - 10 Stickers (Stacking in center, then bursting outward)
                ForEach(Array(allStickers.enumerated()), id: \.element.id) { index, sticker in
                    let isSelected = chosenSticker == sticker
                    let isVisible = index < stackedCount
                    let spreadPos = organicSpreadPosition(for: index, width: w, height: h)
                    let currentSize: CGFloat = isSelected && isCompanionCentered ? 215 : (isBurstSpread ? spreadPos.size : 160)
                    
                    // Gentle, organic floating loop effect when spread in the galaxy
                    let floatDirection: CGFloat = (index % 2 == 0) ? 1.0 : -1.0
                    let floatY: CGFloat = isBurstSpread ? (isFloatingLoop ? -8 * floatDirection : 8 * floatDirection) : 0
                    let floatRot: Double = isBurstSpread ? (isFloatingLoop ? 2.0 * Double(floatDirection) : -2.0 * Double(floatDirection)) : 0
                    let floatScale: CGFloat = isBurstSpread ? (isFloatingLoop ? 1.03 : 0.97) : 1.0
                    
                    let targetX = isSelected && isCompanionCentered
                        ? centerX
                        : (isBurstSpread ? centerX + spreadPos.x : centerX + stackOffsets[index].x)
                    let targetY = isSelected && isCompanionCentered
                        ? centerY - 45 + (isFloatingLoop ? -6 : 6)
                        : (isBurstSpread
                            ? centerY + spreadPos.y + floatY
                            : centerY + stackOffsets[index].y)
                    
                    Button {
                        guard isBurstSpread, !dissolvingOthers else { return }
                        selectCompanion(sticker)
                    } label: {
                        sticker.image
                            .resizable()
                            .scaledToFit()
                            .frame(width: currentSize, height: currentSize)
                            .rotationEffect(.degrees(
                                isSelected && isCompanionCentered
                                    ? 0
                                    : (isBurstSpread ? spreadPos.rotation + floatRot : stackRotations[index])
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
                                        : (dissolvingOthers && !isSelected ? 0.35 : floatScale))
                                    : 2.0
                            )
                            .opacity(
                                isVisible
                                    ? (dissolvingOthers && !isSelected ? 0.0 : 1.0)
                                    : 0.0
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(width: isSelected && isCompanionCentered ? 220 : max(spreadPos.size, 120),
                           height: isSelected && isCompanionCentered ? 220 : max(spreadPos.size, 120))
                    .contentShape(Rectangle())
                    .position(x: targetX, y: targetY)
                    .disabled(!isBurstSpread || (dissolvingOthers && !isSelected))
                }
                
                // MARK: - Center Content
                if isBurstSpread && !dissolvingOthers && !isCompanionCentered {
                    // Central lowercase brand and clean prompt (no card, no border, no emoji)
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
                } else if isCompanionCentered, let active = chosenSticker {
                    // Picked State: Selected Companion title and details centered right below the hero sticker
                    VStack(spacing: 8) {
                        Text(active.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                        
                        Text(active.subtitle)
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .lineSpacing(2)
                        
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                                isCompanionCentered = false
                                dissolvingOthers = false
                                chosenSticker = nil
                            }
                        } label: {
                            Text("choose another companion")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.65))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .nativeLiquidGlassCapsule(isInteractive: true)
                                .padding(.top, 6)
                        }
                        .buttonStyle(.plain)
                    }
                    .position(x: centerX, y: centerY + 115)
                    .transition(.opacity.combined(with: .offset(y: 20)))
                    
                    // Liquid Glass Continue Button at bottom
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
                }
            }
            .frame(width: w, height: h)
        }
    }
    
    // Organic, asymmetrical spread coordinates across the screen (wider spread, bigger stickers, balanced clearance)
    private func organicSpreadPosition(for index: Int, width: CGFloat, height: CGFloat) -> (x: CGFloat, y: CGFloat, rotation: Double, size: CGFloat) {
        let wScale = width / 393.0
        let hScale = height / 780.0
        
        switch index {
        case 0: // growthChart: top-left
            return (-120 * wScale, -285 * hScale, -8, 120)
        case 1: // zenPeace: top-right
            return (120 * wScale, -285 * hScale, 7, 120)
        case 2: // billDue: upper-mid right
            return (152 * wScale, -145 * hScale, -9, 122)
        case 3: // coffeeExpenses: lower-mid right
            return (152 * wScale, 140 * hScale, 9, 120)
        case 4: // catCompanion: upper-mid left
            return (-152 * wScale, -145 * hScale, 8, 124)
        case 5: // piggySavings: lower-mid left
            return (-152 * wScale, 140 * hScale, -8, 122)
        case 6: // moneyHug: bottom-left
            return (-88 * wScale, 325 * hScale, 8, 120)
        case 7: // icedBoba: bottom-right
            return (88 * wScale, 325 * hScale, -7, 120)
        default:
            return (0, 0, 0, 110)
        }
    }
    
    // MARK: - STEP 1: Feature Showcase (3 stacked transaction cards animated one-by-one)
    private var featureShowcaseStage: some View {
        VStack(spacing: 20) {
            // 3 Stacked Transaction Cards (Inspired directly by user reference)
            VStack(spacing: 12) {
                if visibleCardsCount >= 1 {
                    transactionFeatureCard(
                        icon: "cup.and.saucer.fill",
                        title: "Coffee",
                        amount: "\(store.currencySymbol)180.00"
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if visibleCardsCount >= 2 {
                    transactionFeatureCard(
                        icon: "cart.fill",
                        title: "Groceries",
                        amount: "\(store.currencySymbol)1,450.00"
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if visibleCardsCount >= 3 {
                    transactionFeatureCard(
                        icon: "tv.fill",
                        title: "Subscriptions",
                        amount: "\(store.currencySymbol)649.00"
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
            
            Spacer()
            
            // Hero Floating Companion
            if let companion = chosenSticker {
                FloatingStickerView(sticker: companion, size: 145)
            }
            
            // Title & Subtitle (Clean lowercase styling)
            VStack(spacing: 8) {
                Text("track expenses & subscriptions")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                
                Text("your simple, delightful way to track expenses.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Continue Button with Native Liquid Glass
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
        .onAppear {
            runFeatureCardsAnimation()
        }
    }
    
    private func transactionFeatureCard(icon: String, title: String, amount: String) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
            
            Spacer()
            
            Text(amount)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .nativeLiquidGlass(cornerRadius: 20, isInteractive: false)
    }
    
    // MARK: - STEPS 2 & 3: Unified Personalization Stage
    // Persistent floating companion (never reloads or jitters), smooth ghost text transitions,
    // cross-fading input fields, and anchored Apple Liquid Glass action button.
    private var unifiedPersonalizationStage: some View {
        VStack(spacing: 24) {
            // Persistent Floating Hero Companion (stays mounted, never reloads or resets)
            if let companion = chosenSticker {
                FloatingStickerView(sticker: companion, size: 155)
                    .padding(.top, 8)
            }
            
            // Editorial Header with Smooth Ghost Fade & Drift Transition
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
                        Text("what's your name?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                        
                        Text("to personalize your daily dashboard.")
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
            .frame(height: 64)
            .animation(.easeInOut(duration: 0.40), value: currentStep)
            
            // Interactive Box Field (Currency Card <-> Name Input Field)
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
            
            // Anchored Apple Native Liquid Glass Button with Smooth Label Transition
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
    
    // MARK: - Final Setup Loader Stage (Everything vanishes, loader in center)
    private var settingUpLoaderStage: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.2)
            
            Text("setting up spendy for you...")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.70))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Action Handlers & Animations
    
    private func runIntroSequence() {
        Task { @MainActor in
            // Step 1: Start with diffused liquid gradient glowing in the center
            isGradientAtTop = false
            stackedCount = 0
            isBurstSpread = false
            
            // Brief 350ms beat for the canvas and center glow to illuminate
            try? await Task.sleep(for: .milliseconds(350))
            guard currentStep == 0 && !isBurstSpread else { return }
            
            // Step 2: Stack stickers in the center right on top of the glowing center gradient!
            for i in 1...8 {
                withAnimation(.spring(response: 0.40, dampingFraction: 0.72)) {
                    stackedCount = i
                }
                HapticsManager.shared.trigger(i == 8 ? .medium : .light)
                try? await Task.sleep(for: .milliseconds(220))
            }
            
            // Step 3: 0.5s pause with stacked stickers resting in the center
            try? await Task.sleep(for: .milliseconds(500))
            guard currentStep == 0 && !isBurstSpread else { return }
            
            // Step 4: Simultaneously glide gradient to the top header AND burst spread stickers into galaxy
            withAnimation(.easeInOut(duration: 1.8)) {
                isGradientAtTop = true
            }
            HapticsManager.shared.trigger(.cardSnap)
            withAnimation(.spring(response: 0.95, dampingFraction: 0.74)) {
                isBurstSpread = true
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
        
        // Phase 1: Dissolve all other 9 stickers slowly
        withAnimation(.easeInOut(duration: 0.38)) {
            dissolvingOthers = true
        }
        
        // Phase 2: Once dissolved, chosen sticker glides into center
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(340))
            HapticsManager.shared.trigger(.cardSnap)
            withAnimation(.spring(response: 0.65, dampingFraction: 0.76)) {
                isCompanionCentered = true
            }
        }
    }
    
    private func runFeatureCardsAnimation() {
        visibleCardsCount = 0
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { visibleCardsCount = 1 }
            HapticsManager.shared.trigger(.soft)
            
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { visibleCardsCount = 2 }
            HapticsManager.shared.trigger(.soft)
            
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { visibleCardsCount = 3 }
            HapticsManager.shared.trigger(.light)
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
        if store.profileImageData == nil,
           let uiImage = UIImage(named: sticker.assetName),
           let data = uiImage.pngData() {
            store.profileImageData = data
            store.selectedSticker = sticker.rawValue
        }
        
        HapticsManager.shared.trigger(.medium)
        
        // Everything vanishes into loader screen
        withAnimation(.easeInOut(duration: 0.35)) {
            isSettingUp = true
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2000))
            HapticsManager.shared.trigger(.success)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                store.hasCompletedOnboarding = true
            }
            dismiss()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(ExpenseStore())
        .preferredColorScheme(.dark)
}
