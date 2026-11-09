//
//  SpendyCreateSheetChrome.swift
//  Spendy
//
//  Shared chrome for create/edit category, folder, and account sheets.
//

import SwiftUI

struct SpendyCreateFormCard<Content: View>: View {
    var fillColor: Color = SpendyColors.cardBackground
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fillColor)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
                .spendyCardLift()
        }
    }
}

struct SpendyCreateFormRow<Leading: View, Trailing: View>: View {
    var minHeight: CGFloat = 52
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var trailing: () -> Trailing
    
    var body: some View {
        HStack(spacing: 12) {
            leading()
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 16)
        .frame(minHeight: minHeight)
        .contentShape(Rectangle())
    }
}

struct SpendyCreateFormDivider: View {
    var body: some View {
        Rectangle()
            .fill(SpendyColors.separator.opacity(0.7))
            .frame(height: 0.5)
            .padding(.leading, 16)
    }
}

struct SpendyColorSwatchButton: View {
    let hex: String
    var action: () -> Void
    
    var body: some View {
        Button {
            HapticsManager.shared.trigger(.light)
            action()
        } label: {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(hex: hex))
                .frame(width: 28, height: 28)
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 1)
                }
                .shadow(color: Color(hex: hex).opacity(0.28), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("Color")
    }
}

struct SpendyColorSwatchPicker: View {
    @Binding var selectedHex: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SpendyColors.presetAccentColors, id: \.self) { hex in
                        Button {
                            HapticsManager.shared.trigger(.selection)
                            selectedHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay {
                                    if selectedHex.uppercased() == hex.uppercased() {
                                        Circle()
                                            .stroke(SpendyColors.textPrimary, lineWidth: 2.5)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Select color \(hex)")
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 12)
        }
    }
}

struct SpendyCreateColorPalette: View {
    @Binding var selectedHex: String
    @Binding var hue: Double
    @Binding var brightness: Double
    
    var body: some View {
        VStack(spacing: 16) {
            SpendyColorPresetSwatches(
                selectedHex: $selectedHex,
                hue: $hue,
                brightness: $brightness
            )
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
                .spendyCardLift()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

struct SpendyCreatePrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    var action: () -> Void
    
    var body: some View {
        Button {
            guard isEnabled else { return }
            HapticsManager.shared.trigger(.success)
            action()
        } label: {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(SpendyColors.elevatedControlForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(SpendyColors.elevatedControlFill, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
        .accessibilityLabel(title)
    }
}

struct SpendyCreateSheetHeader: View {
    var title: String? = nil
    var showDelete: Bool = false
    var deleteLabel: String = "Delete"
    var onClose: () -> Void
    var onDelete: (() -> Void)? = nil
    var center: () -> AnyView
    var trailing: (() -> AnyView)? = nil
    
    init(
        title: String? = nil,
        showDelete: Bool = false,
        deleteLabel: String = "Delete",
        onClose: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        @ViewBuilder center: @escaping () -> some View = { EmptyView() },
        @ViewBuilder trailing: @escaping () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.showDelete = showDelete
        self.deleteLabel = deleteLabel
        self.onClose = onClose
        self.onDelete = onDelete
        self.center = { AnyView(center()) }
        let trailingView = trailing()
        if !(trailingView is EmptyView) {
            self.trailing = { AnyView(trailingView) }
        } else {
            self.trailing = nil
        }
    }
    
    var body: some View {
        HStack {
            GlassCircleButton(
                icon: SFIcons.close,
                size: 44,
                iconSize: 14,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close"
            ) {
                onClose()
            }
            
            Spacer()
            
            if let title {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
            } else {
                center()
            }
            
            Spacer()
            
            if let trailing {
                trailing()
            } else if showDelete, let onDelete {
                GlassCircleButton(
                    icon: SFIcons.delete,
                    size: 44,
                    iconSize: 14,
                    tintColor: SpendyColors.expenseRed.opacity(0.18),
                    foregroundColor: SpendyColors.expenseRed,
                    haptic: .warning,
                    accessibilityLabel: deleteLabel
                ) {
                    onDelete()
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }
}
