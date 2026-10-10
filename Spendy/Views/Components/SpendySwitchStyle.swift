import SwiftUI

/// A native switch with a clearly visible blue enabled color throughout Spendy.
struct SpendySwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .toggleStyle(.switch)
            .tint(SpendyColors.controlAccent)
    }
}
