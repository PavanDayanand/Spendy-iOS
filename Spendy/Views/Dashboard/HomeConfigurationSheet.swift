//
//  HomeConfigurationSheet.swift
//  Spendy
//
//  Apple Native Sheet Card architecture matching TransactionDetailSheet:
//  - Ambient Header Background Gradient at the top
//  - Pinned Floating Top Bar with GlassCircleButton (✕ and ⇅ / ✓)
//  - Pinned "Modify dashboard" centered title
//  - Structured Details Container Card with Toggles & Pure Drag-to-Reorder
//  - .presentationDetents([.height(540), .medium, .large]) & .presentationDragIndicator(.visible)
//

import SwiftUI

struct HomeConfigurationSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var isReordering: Bool = false
    @State private var workingOrder: [DashboardSectionId] = []
    @Namespace private var sheetNamespace
    
    private var themeColor: Color {
        if let hex = store.profileColorHex, !hex.isEmpty {
            return Color(hex: hex)
        }
        if !store.topGradientColorHex.isEmpty {
            return Color(hex: store.topGradientColorHex)
        }
        return SpendyColors.primaryBlue
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: - 1. Ambient Header Background Glow
            SpendyAmbientHeaderBackground(color: themeColor, height: 260, opacity: 0.28)
            
            // MARK: - 2. Scrollable Content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Spacer to clear the floating top action bar (44pt button + 20pt top inset + 8pt gap)
                    Spacer().frame(height: 68)
                    
                    // Section Header Label
                    Text("Sections & controls")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .padding(.leading, 6)
                    
                    if isReordering {
                        // Reorder Mode (Pure Drag Handle - No Arrow Marks)
                        reorderSectionsCard
                        
                        Text("Drag to reorder")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                            .padding(.leading, 6)
                            .padding(.top, 2)
                    } else {
                        // Standard Toggles Mode
                        togglesSectionsCard
                        
                        Text("Recent transactions is always visible and cannot be hidden.")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                            .padding(.leading, 6)
                            .padding(.top, 2)
                        
                        // Reset to Default Card Button
                        resetToDefaultCard
                            .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            
            // MARK: - 3. Pinned Floating Top Action Bar (✕, Title, ⇅ / ✓)
            topActionBar
                .padding(.horizontal, 20)
                .padding(.top, 20)
        }
        .background(Color.clear)
        .presentationDetents([.height(540), .medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            workingOrder = store.dashboardSectionOrder
        }
    }
    
    // MARK: - Top Floating Action Bar
    @ViewBuilder
    private var topActionBar: some View {
        HStack {
            // Left Dismiss Button (✕)
            GlassCircleButton(
                icon: SFIcons.close,
                size: 44,
                iconSize: 16,
                iconWeight: .bold,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close",
                morphID: "modifyCloseButton",
                namespace: sheetNamespace
            ) {
                dismiss()
            }
            
            Spacer()
            
            // Center Title
            Text("Modify dashboard")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            // Right Action Button (⇅ Reorder or ✓ Save)
            if isReordering {
                GlassCircleButton(
                    icon: "checkmark",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .heavy,
                    tintColor: Color.white,
                    foregroundColor: Color.black,
                    haptic: .selection,
                    accessibilityLabel: "Done Reordering",
                    morphID: "modifySaveButton",
                    namespace: sheetNamespace
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        store.dashboardSectionOrder = workingOrder
                        isReordering = false
                    }
                }
            } else {
                GlassCircleButton(
                    icon: "arrow.up.arrow.down",
                    size: 44,
                    iconSize: 16,
                    iconWeight: .bold,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .selection,
                    accessibilityLabel: "Reorder Sections",
                    morphID: "modifyReorderButton",
                    namespace: sheetNamespace
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        workingOrder = store.dashboardSectionOrder
                        isReordering = true
                    }
                }
            }
        }
    }
    
    // MARK: - Standard Toggles Sections Card
    private var togglesSectionsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(store.dashboardSectionOrder.enumerated()), id: \.element.id) { index, section in
                HStack {
                    Text(section.title)
                        .font(.system(size: 15.5, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    if section.isAlwaysVisible {
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .tint(Color.green)
                            .disabled(true)
                            .opacity(0.45)
                    } else {
                        Toggle("", isOn: Binding(
                            get: { store.isSectionVisible(section) },
                            set: { newVal in
                                HapticsManager.shared.trigger(.selection)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    store.setSectionVisible(section, isVisible: newVal)
                                }
                            }
                        ))
                        .labelsHidden()
                        .tint(Color.green)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                
                if index < store.dashboardSectionOrder.count - 1 {
                    Divider()
                        .overlay(Color.white.opacity(0.08))
                        .padding(.horizontal, 16)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(white: 0.15, opacity: 0.65))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Reorder Sections Card (Pure Drag Handle)
    private var reorderSectionsCard: some View {
        VStack(spacing: 0) {
            List {
                ForEach(workingOrder, id: \.id) { section in
                    HStack {
                        Text(section.title)
                            .font(.system(size: 15.5, weight: .medium))
                            .foregroundStyle(SpendyColors.textPrimary)
                        
                        Spacer()
                    }
                    .listRowBackground(Color(white: 0.15, opacity: 0.65))
                    .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                }
                .onMove { fromOffsets, toOffset in
                    workingOrder.move(fromOffsets: fromOffsets, toOffset: toOffset)
                    HapticsManager.shared.trigger(.selection)
                }
            }
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .frame(height: CGFloat(workingOrder.count * 50))
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        }
    }
    
    // MARK: - Reset to Default Button
    private var resetToDefaultCard: some View {
        Button(action: {
            HapticsManager.shared.trigger(.warning)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                store.resetDashboardConfigToDefault()
                workingOrder = store.dashboardSectionOrder
            }
        }) {
            HStack {
                Text("Reset to Default")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#FF453A"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(white: 0.15, opacity: 0.65))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
    }
}
