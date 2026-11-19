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

                VStack(alignment: .leading, spacing: 12) {
                    Text("Home background")
                        .font(.headline)
                    Toggle(isOn: $store.isGradientBackgroundEnabled) {
                        HStack(spacing: 12) {
                            HomeNeonBackground(style: store.homeGradientStyle, animated: false)
                                .frame(width: 44, height: 56)
                                .clipShape(.rect(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Gradient")
                                    .font(.body.weight(.semibold))
                                Text("A slow wave of colour on Home.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .tint(store.accentPreset.switchTint)
                    .padding(16)
                    .background(SpendyColors.cardBackground, in: .rect(cornerRadius: 20))
                    .accessibilityIdentifier("appearance-home-gradient")

                    if store.isGradientBackgroundEnabled {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(HomeGradientStyle.allCases) { style in
                                Button {
                                    store.homeGradientStyle = style
                                    HapticsManager.shared.trigger(.selection)
                                } label: {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HomeNeonBackground(style: style, animated: false)
                                            .frame(height: 96)
                                            .clipShape(.rect(cornerRadius: 12))
                                        HStack {
                                            Text(style.title)
                                                .fixedSize(horizontal: false, vertical: true)
                                            Spacer(minLength: 4)
                                            if store.homeGradientStyle == style {
                                                Image(systemName: "checkmark.circle.fill")
                                            }
                                        }
                                        .font(.subheadline.weight(.semibold))
                                    }
                                    .padding(12)
                                    .background(SpendyColors.cardBackground, in: .rect(cornerRadius: 20))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(store.homeGradientStyle == style ? SpendyColors.textPrimary : SpendyColors.separator,
                                                    lineWidth: store.homeGradientStyle == style ? 1.5 : 0.5)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(style.title) gradient")
                                .accessibilityValue(store.homeGradientStyle == style ? "Selected" : "Not selected")
                                .accessibilityAddTraits(store.homeGradientStyle == style ? .isSelected : [])
                                .accessibilityIdentifier("home-gradient-\(style.rawValue)")
                            }
                        }
                    }
                }

                NavigationLink {
                    AppIconSelectionView()
                } label: {
                    HStack(spacing: 14) {
                        Image(SpendyAppIcon.current.assetImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 54, height: 54)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("App icons")
                                .font(.body.weight(.semibold))
                            Text("Preview icons in three colors.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(SpendyColors.cardBackground, in: .rect(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("appearance-app-icons")

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
