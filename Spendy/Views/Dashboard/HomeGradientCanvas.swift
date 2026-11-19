import SwiftUI

/// Native gradient drawing. Still mode preserves the Figma studies exactly.
struct HomeGradientCanvas: View {
    let style: HomeGradientStyle
    let phase: Double
    let motionEnabled: Bool
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        GeometryReader { geometry in
            let height = min(geometry.size.height, geometry.size.width * 2.2)
            ZStack(alignment: .top) {
                if style == .indigo && colorScheme == .dark {
                    Color(hex: "#06070C")
                } else {
                    SpendyColors.appBackground
                }
                Canvas { context, size in
                    switch style {
                    case .blueAura: drawBlueAura(in: &context, size: size)
                    case .indigo: drawIndigo(in: &context, size: size)
                    }
                }
                .frame(height: height)
                .opacity(contrast == .increased ? 0.45 : 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawBlueAura(in context: inout GraphicsContext, size: CGSize) {
        let dark = colorScheme == .dark
        let fields: [(color: Color, height: CGFloat, top: CGFloat)] = [
            (Color(hex: dark ? "#00113F" : "#D7E5FF"), 1.17, -0.58),
            (Color(hex: dark ? "#004AB6" : "#A4CFFF"), 1.08, -0.57),
            (Color(hex: dark ? "#00F6F8" : "#F3FFFF").opacity(dark ? 0.24 : 1), 0.98, -0.54),
            (Color(hex: dark ? "#002B81" : "#A5DFFF"), 0.88, -0.54),
        ]
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: size.width * 0.13))
            for (index, field) in fields.enumerated() {
                let shift = motionEnabled ? sin(phase + Double(index) * 0.5) * size.width * 0.035 : 0
                let sway = motionEnabled ? cos(phase + Double(index) * 0.4) * size.width * 0.02 : 0
                let rect = CGRect(x: -size.width * 0.62 + sway, y: size.height * field.top + shift,
                                  width: size.width * 2.24, height: size.height * field.height)
                layer.fill(Path(ellipseIn: rect), with: .color(field.color))
            }
        }
        // Mask the drawn film, including its alpha, into the existing black/white base.
        context.blendMode = .destinationIn
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
            Gradient(stops: [.init(color: .white, location: 0), .init(color: .white, location: 0.36),
                             .init(color: .white.opacity(0.25), location: 0.56),
                             .init(color: .clear, location: 0.67), .init(color: .clear, location: 1)]),
            startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
    }

    private func drawIndigo(in context: inout GraphicsContext, size: CGSize) {
        let colours = colorScheme == .dark
            ? ["#16198B", "#16198B", "#131671", "#0E104E", "#090B25", "#06070D", "#06070C"]
            : ["#D5D6FF", "#D5D6FF", "#DFDFFF", "#E9E9FF", "#F4F4FF", "#FFFFFF", "#FFFFFF"]
        let positions = [0.0, 0.08, 0.18, 0.27, 0.37, 0.48, 1.0]
        let gradient = Gradient(stops: zip(colours, positions).map { .init(color: Color(hex: $0.0), location: $0.1) })
        // Opaque, overlapping strips bend the field into a broad travelling wave.
        // Keep their edges opaque: blurring individual strips leaves vertical seams.
        let count = motionEnabled ? 64 : 1
        for index in 0..<count {
            let progress = Double(index) / Double(count)
            let wave = motionEnabled
                ? (sin(progress * 2 * .pi + phase) + sin(progress * 4 * .pi - phase * 2) * 0.25) * size.width * 0.028
                : 0
            let width = size.width / CGFloat(count)
            let rect = CGRect(x: CGFloat(index) * width - 1, y: -16, width: width + 2, height: size.height + 32)
            context.fill(Path(rect), with: .linearGradient(gradient,
                startPoint: CGPoint(x: 0, y: wave), endPoint: CGPoint(x: 0, y: size.height + wave)))
        }
    }
}
