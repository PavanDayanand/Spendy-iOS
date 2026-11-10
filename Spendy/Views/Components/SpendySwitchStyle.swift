import SwiftUI

/// A native switch with a readable accent enabled color throughout Spendy.
struct SpendySwitchStyle: ToggleStyle {
    @Environment(ExpenseStore.self) private var store
    func makeBody(configuration: Configuration) -> some View {
        Toggle(configuration)
            .toggleStyle(.switch)
            .tint(store.accentPreset.switchTint)
    }
}
