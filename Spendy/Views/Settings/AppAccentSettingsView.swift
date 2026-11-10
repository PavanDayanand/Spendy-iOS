import SwiftUI

struct AppAccentSettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 160 : 136), spacing: 12)]
    }

    var body: some View {
        @Bindable var store = store
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Color scheme")
                        .font(.headline)
                    GlassSegmentedPicker(
                        selection: $store.appearanceMode,
                        items: [.system, .light, .dark],
                        titleFor: { $0.rawValue },
                        iconFor: { $0.sfSymbol }
                    )
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("App accent")
                        .font(.headline)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(SpendyAccentPreset.allCases) { preset in
                            Button { select(preset) } label: {
                                Label(preset.title, systemImage: store.accentPreset == preset ? "checkmark" : "plus")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(preset.foreground)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, minHeight: 52)
                                    .padding(.vertical, 4)
                                    .modifier(HeroSpendLiquidGlassModifier(tint: preset.fill))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(preset.title) accent")
                            .accessibilityValue(store.accentPreset == preset ? "Selected" : "Not selected")
                            .accessibilityAddTraits(store.accentPreset == preset ? .isSelected : [])
                            .accessibilityIdentifier("accent-\(preset.rawValue)")
                        }
                    }
                }
            }
            .foregroundStyle(SpendyColors.textPrimary)
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(SpendyColors.settingsBackground)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func select(_ preset: SpendyAccentPreset) {
        guard store.accentPreset != preset else { return }
        store.accentPreset = preset
        HapticsManager.shared.trigger(.selection)
    }
}
