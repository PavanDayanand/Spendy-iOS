//
//  GeminiGlowModifier.swift
//  Spendy
//

import SwiftUI

// MARK: - Default Gemini Gradient Colors
public enum GeminiGlowDefaults {
    public static let colors: [Color] = [
        Color.blue,
        Color.cyan,
        Color.purple,
        Color.indigo,
        Color.blue
    ]
    
    public static let lineWidth: CGFloat = 2.0
    public static let glowRadius: CGFloat = 8.0
    public static let glowLineWidth: CGFloat = 6.0
    public static let autoDismissDuration: TimeInterval = 5.0
    public static let cornerRadius: CGFloat = 16.0
}

// MARK: - Lightweight Static Noise Generator
public struct GeminiNoiseOverlay: View {
    public var opacity: Double = 0.20
    
    public init(opacity: Double = 0.20) {
        self.opacity = opacity
    }
    
    public var body: some View {
        // Pre-computed static grid drawing to avoid per-frame CPU load
        Canvas(rendersAsynchronously: true) { context, size in
            guard size.width > 0, size.height > 0 else { return }
            let step: CGFloat = 3.0
            var x: CGFloat = 0
            while x < size.width {
                var y: CGFloat = 0
                while y < size.height {
                    let seed = (Int(x) &* 374761393) ^ (Int(y) &* 668265263) ^ 0x5bf03635
                    let val = Double(seed & 0xFF) / 255.0
                    if val > 0.65 {
                        context.fill(
                            Path(CGRect(x: x, y: y, width: step, height: step)),
                            with: .color(.white.opacity(val > 0.85 ? 0.4 : 0.15))
                        )
                    }
                    y += step
                }
                x += step
            }
        }
        .blendMode(.overlay)
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}

// MARK: - Gemini Glow Border Shape Container
public struct GeminiGlowBorder<S: InsettableShape>: View {
    public var shape: S
    public var colors: [Color]
    public var rotationAngle: Double
    public var lineWidth: CGFloat
    public var glowRadius: CGFloat
    public var glowLineWidth: CGFloat
    public var showNoise: Bool

    public init(
        shape: S,
        colors: [Color] = GeminiGlowDefaults.colors,
        rotationAngle: Double,
        lineWidth: CGFloat = GeminiGlowDefaults.lineWidth,
        glowRadius: CGFloat = GeminiGlowDefaults.glowRadius,
        glowLineWidth: CGFloat = GeminiGlowDefaults.glowLineWidth,
        showNoise: Bool = true
    ) {
        self.shape = shape
        self.colors = colors
        self.rotationAngle = rotationAngle
        self.lineWidth = lineWidth
        self.glowRadius = glowRadius
        self.glowLineWidth = glowLineWidth
        self.showNoise = showNoise
    }

    public var body: some View {
        ZStack {
            // 1. Ambient Bloom / Halo Stroke
            shape
                .strokeBorder(
                    AngularGradient(
                        colors: colors,
                        center: .center
                    ),
                    lineWidth: glowLineWidth
                )
                .rotationEffect(.degrees(rotationAngle))
                .blur(radius: glowRadius)

            // 2. Crisp Foreground Stroke
            shape
                .strokeBorder(
                    AngularGradient(
                        colors: colors,
                        center: .center
                    ),
                    lineWidth: lineWidth
                )
                .rotationEffect(.degrees(rotationAngle))

            // 3. Subtle Noise / Grain Overlay
            if showNoise {
                GeminiNoiseOverlay(opacity: 0.25)
                    .mask {
                        shape.strokeBorder(
                            Color.white,
                            lineWidth: max(lineWidth + 1.0, glowLineWidth * 0.75)
                        )
                    }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Gemini Animated Glow View Modifier
public struct GeminiGlowModifier<S: InsettableShape>: ViewModifier {
    public var isActive: Bool
    public var shape: S
    public var colors: [Color]
    public var lineWidth: CGFloat
    public var glowRadius: CGFloat
    public var glowLineWidth: CGFloat
    public var showNoise: Bool
    public var autoDismissDuration: TimeInterval?
    public var onDismiss: (() -> Void)?

    @State private var rotationAngle: Double = 0.0
    @State private var glowOpacity: Double = 0.0
    @State private var autoDismissTask: Task<Void, Never>? = nil
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        isActive: Bool,
        shape: S,
        colors: [Color] = GeminiGlowDefaults.colors,
        lineWidth: CGFloat = GeminiGlowDefaults.lineWidth,
        glowRadius: CGFloat = GeminiGlowDefaults.glowRadius,
        glowLineWidth: CGFloat = GeminiGlowDefaults.glowLineWidth,
        showNoise: Bool = true,
        autoDismissDuration: TimeInterval? = GeminiGlowDefaults.autoDismissDuration,
        onDismiss: (() -> Void)? = nil
    ) {
        self.isActive = isActive
        self.shape = shape
        self.colors = colors
        self.lineWidth = lineWidth
        self.glowRadius = glowRadius
        self.glowLineWidth = glowLineWidth
        self.showNoise = showNoise
        self.autoDismissDuration = autoDismissDuration
        self.onDismiss = onDismiss
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                GeminiGlowBorder(
                    shape: shape,
                    colors: colors,
                    rotationAngle: rotationAngle,
                    lineWidth: lineWidth,
                    glowRadius: glowRadius,
                    glowLineWidth: glowLineWidth,
                    showNoise: showNoise
                )
                .opacity(glowOpacity)
                .allowsHitTesting(false)
            }
            .onAppear {
                if isActive {
                    startGlowEffect()
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startGlowEffect()
                } else {
                    stopGlowEffect()
                }
            }
            .onDisappear {
                autoDismissTask?.cancel()
                autoDismissTask = nil
            }
    }

    private func startGlowEffect() {
        autoDismissTask?.cancel()
        autoDismissTask = nil

        withAnimation(.easeIn(duration: 0.3)) {
            glowOpacity = 1.0
        }

        if !reduceMotion {
            rotationAngle = 0.0
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360.0
            }
        } else {
            rotationAngle = 45.0
        }

        if let duration = autoDismissDuration, duration > 0 {
            autoDismissTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                
                withAnimation(.easeOut(duration: 0.6)) {
                    glowOpacity = 0.0
                }
                
                onDismiss?()
            }
        }
    }

    private func stopGlowEffect() {
        autoDismissTask?.cancel()
        autoDismissTask = nil

        withAnimation(.easeOut(duration: 0.6)) {
            glowOpacity = 0.0
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !isActive else { return }
            withAnimation(nil) {
                rotationAngle = 0.0
            }
        }
    }
}

// MARK: - View Extensions
public extension View {
    /// Applies Gemini's animated blooming multi-color gradient border glow to any SwiftUI view.
    func geminiGlow(
        isActive: Bool,
        cornerRadius: CGFloat = GeminiGlowDefaults.cornerRadius,
        colors: [Color] = GeminiGlowDefaults.colors,
        lineWidth: CGFloat = GeminiGlowDefaults.lineWidth,
        glowRadius: CGFloat = GeminiGlowDefaults.glowRadius,
        glowLineWidth: CGFloat = GeminiGlowDefaults.glowLineWidth,
        showNoise: Bool = true,
        autoDismissAfter: TimeInterval? = GeminiGlowDefaults.autoDismissDuration,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            GeminiGlowModifier(
                isActive: isActive,
                shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                colors: colors,
                lineWidth: lineWidth,
                glowRadius: glowRadius,
                glowLineWidth: glowLineWidth,
                showNoise: showNoise,
                autoDismissDuration: autoDismissAfter,
                onDismiss: onDismiss
            )
        )
    }

    /// Convenience modifier specifically for AI thinking & streaming states.
    func geminiGlow(
        isThinking: Bool,
        cornerRadius: CGFloat = GeminiGlowDefaults.cornerRadius,
        autoDismissAfter: TimeInterval? = GeminiGlowDefaults.autoDismissDuration
    ) -> some View {
        self.geminiGlow(
            isActive: isThinking,
            cornerRadius: cornerRadius,
            colors: GeminiGlowDefaults.colors,
            lineWidth: GeminiGlowDefaults.lineWidth,
            glowRadius: GeminiGlowDefaults.glowRadius,
            glowLineWidth: GeminiGlowDefaults.glowLineWidth,
            showNoise: true,
            autoDismissAfter: autoDismissAfter
        )
    }

    /// Generic shape overload supporting `Capsule`, `Circle`, `UnevenRoundedRectangle`, or custom `InsettableShape`.
    func geminiGlow<S: InsettableShape>(
        isActive: Bool,
        shape: S,
        colors: [Color] = GeminiGlowDefaults.colors,
        lineWidth: CGFloat = GeminiGlowDefaults.lineWidth,
        glowRadius: CGFloat = GeminiGlowDefaults.glowRadius,
        glowLineWidth: CGFloat = GeminiGlowDefaults.glowLineWidth,
        showNoise: Bool = true,
        autoDismissAfter: TimeInterval? = GeminiGlowDefaults.autoDismissDuration,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            GeminiGlowModifier(
                isActive: isActive,
                shape: shape,
                colors: colors,
                lineWidth: lineWidth,
                glowRadius: glowRadius,
                glowLineWidth: glowLineWidth,
                showNoise: showNoise,
                autoDismissDuration: autoDismissAfter,
                onDismiss: onDismiss
            )
        )
    }

    /// Generic shape overload specifically for `isThinking: Bool`.
    func geminiGlow<S: InsettableShape>(
        isThinking: Bool,
        shape: S,
        autoDismissAfter: TimeInterval? = GeminiGlowDefaults.autoDismissDuration
    ) -> some View {
        self.geminiGlow(
            isActive: isThinking,
            shape: shape,
            colors: GeminiGlowDefaults.colors,
            lineWidth: GeminiGlowDefaults.lineWidth,
            glowRadius: GeminiGlowDefaults.glowRadius,
            glowLineWidth: GeminiGlowDefaults.glowLineWidth,
            showNoise: true,
            autoDismissAfter: autoDismissAfter
        )
    }
}
