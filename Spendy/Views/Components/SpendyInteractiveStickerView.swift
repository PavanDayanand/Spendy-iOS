//
//  SpendyInteractiveStickerView.swift
//  Spendy
//
//  Living, tactile code sticker wrapping authentic Spendy sticker graphics.
//  Features die-cut vinyl border, dynamic holographic/iridescent sheen glint,
//  multi-phase elastic hug/squish physics, 3D tilt perspective, floating particle bursts
//  (hearts 🖤/💖, sparkles ✨, and currency ₹), and ambient levitation.
//

import SwiftUI

public struct StickerParticle: Identifiable {
    public let id = UUID()
    public let text: String
    public var x: CGFloat
    public var y: CGFloat
    public var scale: CGFloat
    public var opacity: Double
    public var rotation: Double
}

public struct SpendyInteractiveStickerView: View {
    public let sticker: SpendySticker
    public var size: CGFloat = 90
    public var enableIdleHover: Bool = true
    public var enableTouchReactivity: Bool = true
    public var dragTiltOffset: CGFloat = 0
    public var externalTrigger: Int = 0
    public var onStickerTap: (() -> Void)? = nil
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var isHovering: Bool = false
    @State private var squishScaleX: CGFloat = 1.0
    @State private var squishScaleY: CGFloat = 1.0
    @State private var wiggleAngle: Double = 0
    @State private var sheenProgress: CGFloat = -0.7
    @State private var particles: [StickerParticle] = []
    @State private var tapCycle: Int = 0
    
    public init(
        sticker: SpendySticker,
        size: CGFloat = 90,
        enableIdleHover: Bool = true,
        enableTouchReactivity: Bool = true,
        dragTiltOffset: CGFloat = 0,
        externalTrigger: Int = 0,
        onStickerTap: (() -> Void)? = nil
    ) {
        self.sticker = sticker
        self.size = size
        self.enableIdleHover = enableIdleHover
        self.enableTouchReactivity = enableTouchReactivity
        self.dragTiltOffset = dragTiltOffset
        self.externalTrigger = externalTrigger
        self.onStickerTap = onStickerTap
    }
    
    public var body: some View {
        ZStack {
            // 1. Floating Ground Contact Shadow
            Ellipse()
                .fill(Color.black.opacity(isHovering ? 0.15 : 0.28))
                .frame(width: size * 0.74, height: size * 0.18)
                .scaleEffect(isHovering ? 0.86 : 1.08)
                .blur(radius: isHovering ? 5 : 3)
                .offset(y: size * 0.45 + (isHovering ? 5 : 1))
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: isHovering)
            
            // 2. The Core Interactive Sticker Decal
            ZStack {
                // A. Die-Cut White Vinyl Base Layer (Multi-contour halo)
                sticker.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .shadow(color: .white.opacity(0.96), radius: 1.2, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.92), radius: 2.4, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.75), radius: 4.5, x: 0, y: 0)
                    .shadow(color: Color.black.opacity(0.24), radius: 6, x: 0, y: 4)
                
                // B. Authentic High-Res Artwork
                sticker.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                
                // C. Holographic / Iridescent Gloss Sheen Sweep Mask
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color.white.opacity(0.0), location: 0.22),
                        .init(color: Color.cyan.opacity(0.38), location: 0.38),
                        .init(color: Color.white.opacity(0.78), location: 0.50),
                        .init(color: Color(hex: "#EC4899").opacity(0.38), location: 0.62),
                        .init(color: Color.white.opacity(0.0), location: 0.78),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: UnitPoint(x: sheenProgress - 0.35, y: sheenProgress - 0.35),
                    endPoint: UnitPoint(x: sheenProgress + 0.35, y: sheenProgress + 0.35)
                )
                .mask(
                    sticker.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                )
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
            .scaleEffect(x: squishScaleX, y: squishScaleY)
            .rotationEffect(.degrees(wiggleAngle))
            .offset(y: (enableIdleHover && !reduceMotion) ? (isHovering ? -3.5 : 3.5) : 0)
            .rotation3DEffect(
                .degrees(Double(dragTiltOffset * 0.14)),
                axis: (x: 0, y: 1, z: 0.04),
                perspective: 0.55
            )
            .onTapGesture {
                guard enableTouchReactivity else { return }
                triggerInteractiveStickerBurst()
            }
            
            // 3. Floating Emitter Particles (Hearts 🖤/💖, Sparkles ✨, Coins ₹)
            ForEach(particles) { p in
                Text(p.text)
                    .font(.system(size: size * 0.22))
                    .scaleEffect(p.scale)
                    .rotationEffect(.degrees(p.rotation))
                    .opacity(p.opacity)
                    .offset(x: p.x, y: p.y)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size + 20, height: size + 20)
        .onChange(of: externalTrigger) { _, _ in
            triggerInteractiveStickerBurst()
        }
        .onAppear {
            if enableIdleHover && !reduceMotion {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    isHovering = true
                }
            }
            schedulePeriodicAmbientSheen()
        }
    }
    
    // MARK: - Interactive Tactile Squeeze & Particle Burst
    public func triggerInteractiveStickerBurst() {
        HapticsManager.shared.trigger(.cardSnap)
        tapCycle += 1
        
        // 1. Multi-phase Elastic "Hug/Squish" Physics
        withAnimation(.spring(response: 0.18, dampingFraction: 0.38)) {
            squishScaleX = 1.20
            squishScaleY = 0.82
            wiggleAngle = (tapCycle % 2 == 0 ? 8 : -8)
        }
        
        // Phase 2: Joyful Rebound
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.44)) {
                squishScaleX = 0.93
                squishScaleY = 1.08
                wiggleAngle = (tapCycle % 2 == 0 ? -4 : 4)
            }
        }
        
        // Phase 3: Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.55)) {
                squishScaleX = 1.0
                squishScaleY = 1.0
                wiggleAngle = 0
            }
        }
        
        // 2. Holographic Sheen Sweep
        triggerSheenSweep()
        
        // 3. Spawn Floating Particles from Mascot
        spawnParticles()
        
        // 4. Callback
        onStickerTap?()
    }
    
    private func triggerSheenSweep() {
        sheenProgress = -0.7
        withAnimation(.easeInOut(duration: 0.65)) {
            sheenProgress = 1.7
        }
    }
    
    private func schedulePeriodicAmbientSheen() {
        // Occasional ambient shimmer every 8 seconds
        Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            guard !isHovering || !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1)) {
                sheenProgress = (sheenProgress > 1.0 ? -0.7 : 1.7)
            }
        }
    }
    
    private func spawnParticles() {
        let pool = ["🖤", "✨", "₹", "💖", "🪙"]
        let count = Int.random(in: 3...4)
        
        for i in 0..<count {
            let symbol = pool[i % pool.count]
            let startX = CGFloat.random(in: -12...12)
            let startY = -size * 0.15
            let targetX = startX + CGFloat.random(in: -35...35)
            let targetY = startY - CGFloat.random(in: 40...70)
            let targetRot = Double.random(in: -25...25)
            
            let particle = StickerParticle(
                text: symbol,
                x: startX,
                y: startY,
                scale: 0.4,
                opacity: 0.95,
                rotation: 0
            )
            particles.append(particle)
            let pId = particle.id
            
            withAnimation(.easeOut(duration: 0.75)) {
                if let index = particles.firstIndex(where: { $0.id == pId }) {
                    particles[index].x = targetX
                    particles[index].y = targetY
                    particles[index].scale = 1.15
                    particles[index].opacity = 0.0
                    particles[index].rotation = targetRot
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                particles.removeAll(where: { $0.id == pId })
            }
        }
    }
}
