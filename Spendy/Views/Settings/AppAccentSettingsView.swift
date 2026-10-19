import SwiftUI

struct AppAccentSettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 110 : 56), spacing: 12)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(spacing: 18) {
                    HStack(spacing: 7) {
                        Image(systemName: SFIcons.plus)
                        Text("Add")
                    }
                    .font(.headline)
                    .foregroundStyle(store.accentPreset.foreground)
                    .padding(.horizontal, 28)
                    .frame(height: 56)
                    .modifier(HeroSpendLiquidGlassModifier(tint: store.accentPreset.fill))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Add button preview")
                    .accessibilityValue(store.accentPreset.title)
                    .accessibilityIdentifier("accent-preview")
                    Text("Preview").font(.subheadline).foregroundStyle(SpendyColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(SpendyAccentPreset.allCases) { preset in
                        Button { select(preset) } label: {
                            VStack(spacing: 10) {
                                Circle()
                                    .fill(preset.fill)
                                    .overlay { Circle().strokeBorder(SpendyColors.textPrimary.opacity(0.18), lineWidth: 1) }
                                    .overlay {
                                        if store.accentPreset == preset {
                                            Image(systemName: SFIcons.checkmark)
                                                .font(.headline).foregroundStyle(preset.foreground)
                                        }
                                    }
                                    .frame(width: 44, height: 44)
                                Text(preset.title).font(.subheadline)
                                    .foregroundStyle(SpendyColors.textPrimary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 78)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(preset.title) accent")
                        .accessibilityValue(store.accentPreset == preset ? "Selected" : "Not selected")
                        .accessibilityAddTraits(store.accentPreset == preset ? .isSelected : [])
                        .accessibilityIdentifier("accent-\(preset.rawValue)")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("A little color. Still Spendy.").font(.headline)
                    Text("Applies to Add, transaction Save and budget Save buttons.")
                        .font(.subheadline).foregroundStyle(SpendyColors.textSecondary)
                    Text("Available during beta. Part of Spendy Pro at launch.")
                        .font(.footnote).foregroundStyle(SpendyColors.textSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: 560)
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(SpendyColors.settingsBackground)
        .navigationTitle("App accent")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func select(_ preset: SpendyAccentPreset) {
        guard store.accentPreset != preset else { return }
        store.accentPreset = preset
        HapticsManager.shared.trigger(.selection)
    }
}
