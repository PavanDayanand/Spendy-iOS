//
//  SpendyAmountRuler.swift
//  Spendy
//
//  Watch-style sliding money ruler for Add Transaction.
//  Drag left/right to change the amount. Step chips: 1 / 50 / 100 / .01
//

import SwiftUI

// MARK: - Input Mode

enum AmountInputMode: String, CaseIterable, Identifiable {
    case keypad
    case slider
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .keypad: return SFIcons.amountKeypad
        case .slider: return SFIcons.amountRuler
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .keypad: return "Keypad"
        case .slider: return "Slider"
        }
    }
}

// MARK: - Ruler Step

enum AmountRulerStep: String, CaseIterable, Identifiable, Hashable {
    case one = "1"
    case fifty = "50"
    case hundred = "100"
    case cents = ".01"
    
    var id: String { rawValue }
    
    var value: Double {
        switch self {
        case .one: return 1
        case .fifty: return 50
        case .hundred: return 100
        case .cents: return 0.01
        }
    }
    
    var title: String { rawValue }
    
    var accessibilityTitle: String {
        switch self {
        case .one: return "1 dollar steps"
        case .fifty: return "50 dollar steps"
        case .hundred: return "100 dollar steps"
        case .cents: return "cent steps"
        }
    }
    
    /// Major tick every N minor ticks.
    var majorEvery: Int {
        switch self {
        case .cents: return 5
        default: return 5
        }
    }
    
    /// Numeric label every N minor ticks.
    var labelEvery: Int {
        switch self {
        case .cents: return 10
        default: return 5
        }
    }
}

// MARK: - Amount Input Mode Switcher

struct AmountInputModeSwitcher: View {
    @Binding var selection: AmountInputMode
    @Namespace private var switchNamespace
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(AmountInputMode.allCases) { mode in
                let isSelected = selection == mode
                
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        selection = mode
                    }
                    HapticsManager.shared.trigger(.selection)
                } label: {
                    Image(systemName: mode.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.70))
                        .frame(width: 36, height: 36)
                        .background {
                            if isSelected {
                                Capsule(style: .continuous)
                                    .fill(Color.white)
                                    .matchedGeometryEffect(id: "amountInputModeHighlight", in: switchNamespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.accessibilityLabel)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .frame(height: 44)
        .background {
            Capsule(style: .continuous)
                .fill(Color(hex: "#1C1C1E"))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.04), lineWidth: 0.8)
                }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Sliding Money Ruler

struct SpendyAmountRuler: View {
    @Binding var amountString: String
    @Binding var step: AmountRulerStep
    var maxDigits: Int = 8
    
    @State private var rawAmount: Double = 0
    @State private var dragOrigin: Double = 0
    @State private var isDragging = false
    @State private var motionGlow: CGFloat = 0
    @State private var lastHapticTick: Double = .nan
    @State private var lastHapticAt: Date = .distantPast
    
    private let tickSpacing: CGFloat = 12
    private let rulerHeight: CGFloat = 112
    private let restGold = Color(hex: "#E08A2C")
    private let liveGold = Color(hex: "#FFC14D")
    private let restSelected = Color(hex: "#F4A83A")
    private let liveSelected = Color(hex: "#FFF3B0")
    
    private var maxValue: Double {
        pow(10, Double(maxDigits)) - 0.01
    }
    
    private var snappedAmount: Double {
        snap(rawAmount)
    }
    
    var body: some View {
        VStack(spacing: 14) {
            rulerTrack
                .frame(height: rulerHeight)
            
            GlassSegmentedPicker(
                selection: $step,
                items: AmountRulerStep.allCases,
                titleFor: { $0.title },
                useLiquidGlass: false
            )
            .onChange(of: step) { _, newStep in
                let next = snap(rawAmount, using: newStep)
                rawAmount = next
                commit(next)
            }
            .accessibilityLabel("Amount step")
        }
        .onAppear {
            rawAmount = parsedAmount
        }
        .onChange(of: amountString) { _, _ in
            guard !isDragging else { return }
            let parsed = parsedAmount
            if abs(parsed - rawAmount) > 0.0001 {
                rawAmount = parsed
            }
        }
    }
    
    // MARK: Track
    
    private var rulerTrack: some View {
        ZStack(alignment: .bottom) {
            rulerCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 16)
            
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(mix(restSelected, liveSelected, motionGlow))
                .padding(.bottom, 6)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .highPriorityGesture(dragGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Amount")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Swipe up or down to change the amount, or use the step control.")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                applyDelta(step.value)
            case .decrement:
                applyDelta(-step.value)
            default:
                break
            }
        }
    }
    
    private var rulerCanvas: some View {
        let spacing = tickSpacing
        let stepValue = step.value
        let snapped = snap(rawAmount)
        let fraction = stepValue == 0 ? 0 : (rawAmount - snapped) / stepValue
        let pixelOffset = CGFloat(fraction) * spacing
        let majorEvery = step.majorEvery
        let labelEvery = step.labelEvery
        
        return Canvas { context, size in
            let centerX = size.width / 2
            let baseline = size.height - 4
            let ticksEachSide = Int(size.width / spacing) + 6
            let glow = motionGlow
            let labelInterval = stepValue * Double(labelEvery)
            var lastLabelX: CGFloat = -1_000
            var lastLabelText = ""
            
            for index in -ticksEachSide...ticksEachSide {
                let tickValue = snapped + Double(index) * stepValue
                if tickValue < -0.0001 { continue }
                if tickValue > maxValue + stepValue { continue }
                
                let x = centerX + CGFloat(index) * spacing - pixelOffset
                guard x > -16 && x < size.width + 16 else { continue }
                
                let isMajor = isNearMultiple(tickValue, of: stepValue * Double(majorEvery))
                let isSelected = abs(x - centerX) < spacing * 0.5
                let isLabeled = isNearMultiple(tickValue, of: labelInterval)
                let edgeFade = 1 - min(abs(x - centerX) / (size.width * 0.48), 1)
                let opacity = max(0.16, pow(edgeFade, 1.35) * (0.72 + 0.28 * glow))
                
                let color = isSelected
                    ? mix(restSelected, liveSelected, glow)
                    : mix(restGold, liveGold, glow)
                
                let barWidth: CGFloat = isSelected ? 4.8 : (isMajor ? 4.0 : 3.4)
                let barHeight: CGFloat = isSelected ? 48 : 44
                let barRect = CGRect(
                    x: x - barWidth / 2,
                    y: baseline - barHeight,
                    width: barWidth,
                    height: barHeight
                )
                context.fill(
                    Path(roundedRect: barRect, cornerRadius: barWidth / 2),
                    with: .color(color.opacity(opacity))
                )
                
                if isLabeled {
                    let label = compactTickLabel(tickValue)
                    if !label.isEmpty,
                       label != lastLabelText,
                       abs(x - lastLabelX) > 36 {
                        let resolved = context.resolve(
                            Text(label)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(color.opacity(min(1, opacity + 0.18)))
                        )
                        context.draw(
                            resolved,
                            at: CGPoint(x: x, y: baseline - barHeight - 13),
                            anchor: .center
                        )
                        lastLabelX = x
                        lastLabelText = label
                    }
                }
            }
        }
    }
    
    // MARK: Gesture
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragOrigin = rawAmount
                    withAnimation(.easeOut(duration: 0.12)) {
                        motionGlow = 1
                    }
                }
                let deltaSteps = Double(-value.translation.width / tickSpacing)
                var next = dragOrigin + deltaSteps * step.value
                next = rubberBand(next)
                rawAmount = next
                let snapped = snap(next)
                commit(snapped)
                hapticIfNeeded(for: snapped)
            }
            .onEnded { value in
                let deltaSteps = Double(-value.translation.width / tickSpacing)
                let next = snap(clamp(dragOrigin + deltaSteps * step.value))
                rawAmount = next
                commit(next)
                hapticIfNeeded(for: next, force: true)
                isDragging = false
                withAnimation(.easeInOut(duration: 0.38)) {
                    motionGlow = 0
                }
            }
    }
    
    // MARK: Math
    
    private var parsedAmount: Double {
        Double(amountString) ?? 0
    }
    
    private func snap(_ value: Double, using step: AmountRulerStep? = nil) -> Double {
        let unit = (step ?? self.step).value
        guard unit > 0 else { return clamp(value) }
        let rounded = (value / unit).rounded() * unit
        return clamp(rounded)
    }
    
    private func clamp(_ value: Double) -> Double {
        min(max(value, 0), maxValue)
    }
    
    private func rubberBand(_ value: Double) -> Double {
        if value < 0 {
            return value * 0.22
        }
        if value > maxValue {
            let overflow = value - maxValue
            return maxValue + overflow * 0.22
        }
        return value
    }
    
    private func applyDelta(_ delta: Double) {
        let next = snap(rawAmount + delta)
        rawAmount = next
        commit(next)
        HapticsManager.shared.trigger(.tick)
    }
    
    private func mix(_ a: Color, _ b: Color, _ t: CGFloat) -> Color {
        let clamped = min(max(t, 0), 1)
        let uiA = UIColor(a)
        let uiB = UIColor(b)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        uiA.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        uiB.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(
            red: Double(ar + (br - ar) * clamped),
            green: Double(ag + (bg - ag) * clamped),
            blue: Double(ab + (bb - ab) * clamped),
            opacity: Double(aa + (ba - aa) * clamped)
        )
    }
    
    private func commit(_ value: Double) {
        let formatted = Self.formatAmount(value, preferCents: step == .cents || abs(value.truncatingRemainder(dividingBy: 1)) > 0.0001)
        if amountString != formatted {
            amountString = formatted
        }
    }
    
    private func hapticIfNeeded(for snapped: Double, force: Bool = false) {
        let now = Date()
        if !force, now.timeIntervalSince(lastHapticAt) < 0.016 { return }
        if !force, snapped == lastHapticTick { return }
        let isMajor = isNearMultiple(snapped, of: step.value * Double(step.majorEvery))
        HapticsManager.shared.trigger(isMajor ? .soft : .tick)
        lastHapticTick = snapped
        lastHapticAt = now
    }
    
    private func isNearMultiple(_ value: Double, of multiple: Double) -> Bool {
        guard multiple > 0 else { return false }
        let quotient = value / multiple
        return abs(quotient - quotient.rounded()) < 0.001
    }
    
    /// Short tape labels that scroll with the ticks: 0, 5, 10, 1k, 12L.
    private func compactTickLabel(_ value: Double) -> String {
        let mag = max(0, value)
        if mag < 0.0001 { return "0" }
        
        if step == .cents || mag < 1 {
            var text = String(format: "%.2f", mag)
            if text.hasSuffix("0") { text.removeLast() }
            if text.hasSuffix("0") { text.removeLast() }
            if text.hasSuffix(".") { text.removeLast() }
            return text
        }
        
        if mag >= 10_000_000 {
            let crores = mag / 10_000_000
            return crores == floor(crores)
                ? String(format: "%.0fCr", crores)
                : String(format: "%.2fCr", crores)
        }
        
        if mag >= 100_000 {
            let lakhs = mag / 100_000
            return lakhs == floor(lakhs)
                ? String(format: "%.0fL", lakhs)
                : String(format: "%.1fL", lakhs)
        }
        
        if mag >= 1000 {
            let thousands = mag / 1000
            return thousands == floor(thousands)
                ? String(format: "%.0fk", thousands)
                : String(format: "%.1fk", thousands)
        }
        
        return String(format: "%.0f", mag.rounded())
    }
    
    private var accessibilityValue: String {
        let value = snappedAmount
        if step == .cents || abs(value.truncatingRemainder(dividingBy: 1)) > 0.0001 {
            return String(format: "%.2f", value)
        }
        return String(format: "%.0f", value)
    }
    
    static func formatAmount(_ value: Double, preferCents: Bool) -> String {
        if value <= 0 { return "0" }
        if preferCents {
            var text = String(format: "%.2f", value)
            if text.hasSuffix("00") {
                return String(format: "%.0f", value)
            }
            if text.hasSuffix("0") {
                text.removeLast()
            }
            return text
        }
        return String(format: "%.0f", value.rounded())
    }
}
