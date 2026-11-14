import SwiftUI

/// Shared 280-degree arc used by the budget screen and Home Screen widgets.
struct SpendyBudgetArcDrawing: View {
    let progress: Double?
    var lineWidth: CGFloat = 24
    let tint: Color
    let track: Color

    private let sweep = 280.0 / 360.0
    private var fraction: Double { min(max(progress ?? 0, 0), 1) }

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let radius = (side - lineWidth) / 2
            let angle = (130 + 280 * fraction) * Double.pi / 180
            ZStack {
                Circle()
                    .trim(from: 0, to: sweep)
                    .stroke(track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(130))
                if fraction > 0 {
                    Circle()
                        .trim(from: 0, to: sweep * fraction)
                        .stroke(
                            AngularGradient(colors: [tint.opacity(0.35), tint], center: .center,
                                startAngle: .degrees(0), endAngle: .degrees(280 * fraction)),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(130))
                    Circle()
                        .fill(tint)
                        .frame(width: lineWidth * 0.48, height: lineWidth * 0.48)
                        .offset(x: radius * cos(angle), y: radius * sin(angle))
                }
            }
            .padding(lineWidth / 2)
            .frame(width: side, height: side)

        }
        .accessibilityHidden(true)
    }
}
