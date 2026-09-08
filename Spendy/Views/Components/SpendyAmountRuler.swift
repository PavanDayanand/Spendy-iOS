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
        .nativeLiquidGlassCapsule(isInteractive: true)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Sliding Money Ruler

struct SpendyAmountRuler: View {
    @Binding var amountString: String
    @Binding var step: AmountRulerStep
    var maxDigits: Int = 8
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var rawAmount: Double = 0
    @State private var dragOrigin: Double = 0
    @State private var isDragging = false
    @State private var lastHapticTick: Double = .nan
    @State private var lastHapticAt: Date = .distantPast
    
    private let tickSpacing: CGFloat = 11
    private let rulerHeight: CGFloat = 92
    private let tickColor = Color(hex: "#E8B86D")
    
    private var maxValue: Double {
        pow(10, Double(maxDigits)) - (step == .cents ? 0.01 : 1)
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
                titleFor: { $0.title }
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
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tickColor)
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
            
            for index in -ticksEachSide...ticksEachSide {
                let tickValue = snapped + Double(index) * stepValue
                if tickValue < -0.0001 { continue }
                if tickValue > maxValue + stepValue { continue }
                
                let x = centerX + CGFloat(index) * spacing - pixelOffset
                guard x > -12 && x < size.width + 12 else { continue }
                
                let isMajor = isNearMultiple(tickValue, of: stepValue * Double(majorEvery))
                let isLabeled = isNearMultiple(tickValue, of: stepValue * Double(labelEvery))
                let edgeFade = 1 - min(abs(x - centerX) / (size.width * 0.52), 1) * 0.55
                let opacity = max(0.28, edgeFade)
                
                let height: CGFloat = isMajor ? 36 : 22
                var path = Path()
                path.move(to: CGPoint(x: x, y: baseline))
                path.addLine(to: CGPoint(x: x, y: baseline - height))
                
                context.stroke(
                    path,
                    with: .color(tickColor.opacity(opacity)),
                    style: StrokeStyle(lineWidth: isMajor ? 2.4 : 1.5, lineCap: .round)
                )
                
                if isLabeled && tickValue >= -0.0001 {
                    let label = tickLabel(tickValue)
                    let resolved = context.resolve(
                        Text(label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(tickColor.opacity(min(1, opacity + 0.2)))
                    )
                    context.draw(
                        resolved,
                        at: CGPoint(x: x, y: baseline - height - 12),
                        anchor: .center
                    )
                }
            }
        }
        .animation(isDragging || reduceMotion ? nil : AppMotion.snappySpring, value: snappedAmount)
    }
    
    // MARK: Gesture
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    dragOrigin = rawAmount
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
                let projected = reduceMotion
                    ? value.translation.width
                    : value.predictedEndTranslation.width
                let deltaSteps = Double(-projected / tickSpacing)
                var next = dragOrigin + deltaSteps * step.value
                next = snap(clamp(next))
                
                if reduceMotion {
                    rawAmount = next
                } else {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                        rawAmount = next
                    }
                }
                commit(next)
                hapticIfNeeded(for: next, force: true)
                isDragging = false
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
        if reduceMotion {
            rawAmount = next
        } else {
            withAnimation(AppMotion.snappySpring) {
                rawAmount = next
            }
        }
        commit(next)
        HapticsManager.shared.trigger(.tick)
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
    
    private func tickLabel(_ value: Double) -> String {
        let safe = max(0, value)
        if step == .cents {
            return String(format: "%.2f", safe)
        }
        if safe >= 1000 {
            return safe.formattedNumber(decimals: 0)
        }
        return String(format: "%.0f", safe)
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
