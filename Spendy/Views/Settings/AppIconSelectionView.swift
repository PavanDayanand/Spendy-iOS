import SwiftUI

struct AppIconSelectionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var previewDark = false
    @State private var previewIcon: SpendyAppIcon = SpendyAppIcon.current == .default ? .frosted : SpendyAppIcon.current
    @State private var selectedIcon = SpendyAppIcon.current
    @State private var isChanging = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            iconPreview
            Text("Each icon adapts to your Home Screen’s light or dark appearance.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 136), spacing: 12)], spacing: 12) {
                ForEach(SpendyAppIcon.selectableIcons) { icon in
                    Button {
                        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.82)) {
                            previewIcon = icon
                        }
                        HapticsManager.shared.trigger(.selection)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(icon.assetImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 76, height: 76)
                            HStack {
                                Text(icon.title)
                                Spacer(minLength: 4)
                                if selectedIcon == icon {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            Text(icon.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(SpendyColors.cardBackground, in: .rect(cornerRadius: 20))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(previewIcon == icon ? SpendyColors.textPrimary : SpendyColors.separator,
                                        lineWidth: previewIcon == icon ? 1.5 : 0.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isChanging)
                    .accessibilityLabel("\(icon.title) app icon")
                    .accessibilityValue(selectedIcon == icon ? "Selected" : "Not selected")
                    .accessibilityAddTraits(selectedIcon == icon ? .isSelected : [])
                    .accessibilityIdentifier("app-icon-\(icon.rawValue)")
                }
            }
            Button {
                changeIcon(to: previewIcon)
            } label: {
                Text(selectedIcon == previewIcon ? "Current icon" : "Use \(previewIcon.title)")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isChanging || selectedIcon == previewIcon)
            .accessibilityIdentifier("app-icon-apply")

            Button {
                changeIcon(to: .default)
            } label: {
                Label("Use original icon", systemImage: selectedIcon == .default ? "checkmark.circle.fill" : "arrow.counterclockwise")
                    .font(.subheadline)
                    .padding(.vertical, 8)
            }
            .disabled(isChanging)
            .accessibilityValue(selectedIcon == .default ? "Selected" : "Not selected")
            .accessibilityIdentifier("app-icon-original")

            if isChanging {
                ProgressView("Changing icon…")
                    .font(.caption)
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity)
        }
        .foregroundStyle(SpendyColors.textPrimary)
        .background(SpendyColors.settingsBackground)
        .navigationTitle("App icons")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { previewDark = colorScheme == .dark }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { selectedIcon = SpendyAppIcon.current }
        }
    }

    private var iconPreview: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: previewColors.map { $0.opacity(previewDark ? 0.28 : 0.15) },
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                HStack(spacing: 54) {
                    ForEach([SpendyAppIcon.ember, .graphite]) { icon in
                        Image(icon.assetImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                            .rotationEffect(.degrees(icon == .ember ? -12 : 12))
                            .opacity(0.35)
                    }
                }
                .accessibilityHidden(true)
                Image(previewIcon.assetImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 154, height: 154)
                    .shadow(color: .black.opacity(previewDark ? 0.35 : 0.16), radius: 16, y: 14)
                    .id(previewIcon)
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.93)))
                    .accessibilityLabel("\(previewIcon.title), \(previewDark ? "dark" : "light") preview")
            }
            .frame(height: 238)
            .environment(\.colorScheme, previewDark ? .dark : .light)
            .animation(.easeInOut(duration: 0.25), value: previewDark)

            Picker("Preview appearance", selection: $previewDark) {
                Text("Light").tag(false)
                Text("Dark").tag(true)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("app-icon-preview-appearance")
        }
    }

    private var previewColors: [Color] {
        switch previewIcon {
        case .ember: [.red, .orange]
        case .graphite: [.gray, .black]
        default: [.cyan, .blue]
        }
    }

    private func changeIcon(to icon: SpendyAppIcon) {
        guard !isChanging, selectedIcon != icon else { return }
        isChanging = true
        errorMessage = nil
        Task { @MainActor in
            defer { isChanging = false }
            do {
                try await SpendyAppIcon.setIcon(icon)
                selectedIcon = SpendyAppIcon.current
                HapticsManager.shared.trigger(.selection)
            } catch {
                selectedIcon = SpendyAppIcon.current
                errorMessage = error.localizedDescription
            }
        }
    }
}
