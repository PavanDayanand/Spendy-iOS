import SwiftUI
import WidgetKit

/// Preserve the app badge's glyph as a transparent cutout when WidgetKit
/// tints foreground content white for Clear and tinted appearances.
struct SpendyWidgetBadgeAppearance: ViewModifier {
    @Environment(\.widgetRenderingMode) private var renderingMode

    func body(content: Content) -> some View {
        if renderingMode == .fullColor {
            content
        } else {
            content
                .environment(\.colorScheme, .dark)
                .compositingGroup()
                .luminanceToAlpha()
                .widgetAccentable()
        }
    }
}
