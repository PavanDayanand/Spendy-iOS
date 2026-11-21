import SwiftUI

/// A native switch with a readable neutral enabled color throughout Spendy.
struct SpendySwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .toggleStyle(.switch)
            .tint(SpendyColors.switchTint)
    }
}
