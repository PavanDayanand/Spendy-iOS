//
//  AddFolderSheet.swift
//  Spendy
//
//  Drawer Sheet for Adding & Editing Folders with Liquid Glass Controls
//

import SwiftUI

struct AddFolderSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var folderToEdit: Folder? = nil
    var defaultType: TransactionType = .expense
    
    @State private var name: String = ""
    @State private var type: TransactionType = .expense
    @State private var showDeleteConfirm: Bool = false
    
    private var isEditing: Bool {
        folderToEdit != nil
    }
    
    init(folderToEdit: Folder? = nil, defaultType: TransactionType = .expense) {
        self.folderToEdit = folderToEdit
        self.defaultType = defaultType
        
        if let folder = folderToEdit {
            _name = State(initialValue: folder.name)
            _type = State(initialValue: folder.type)
        } else {
            _type = State(initialValue: defaultType)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            // Top vertical gradient glow
            LinearGradient(
                colors: [
                    SpendyColors.textPrimary.opacity(0.12),
                    SpendyColors.textPrimary.opacity(0.03),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header: Close, Type Toggle, Delete
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)
                        
                        // Folder Name input card
                        folderNameCard
                        
                        Text("Folders help you group similar categories together for cleaner insights.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // clearance for action button
                }
            }
            
            // Bottom Action Button Container (Full Width)
            VStack(spacing: 0) {
                bottomActionButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 16)
            }
            .background {
                LinearGradient(
                    colors: [Color.clear, SpendyColors.appBackground.opacity(0.95), SpendyColors.appBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .confirmationDialog(
            "Delete Folder?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Folder", role: .destructive) {
                if let folder = folderToEdit {
                    store.deleteFolder(id: folder.id)
                    HapticsManager.shared.trigger(.warning)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Categories inside \(name.isEmpty ? "this folder" : name) will be reassigned to Uncategorized.")
        }
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            // Close Button
            GlassCircleButton(
                icon: "xmark",
                size: 44,
                iconSize: 14,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close"
            ) {
                dismiss()
            }
            
            Spacer()
            
            // Segmented Type Toggle
            typeToggleCapsule
            
            Spacer()
            
            // Delete Button (if editing)
            if isEditing {
                GlassCircleButton(
                    icon: "trash.fill",
                    size: 44,
                    iconSize: 14,
                    tintColor: SpendyColors.expenseRed,
                    foregroundColor: SpendyColors.expenseRed,
                    haptic: .warning,
                    accessibilityLabel: "Delete Folder"
                ) {
                    showDeleteConfirm = true
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Type Toggle Capsule
    private var typeToggleCapsule: some View {
        HStack(spacing: 6) {
            typeTabButton(typeOption: .expense, title: "Expense", icon: "arrow.up.right")
            typeTabButton(typeOption: .income, title: "Income", icon: "arrow.down.left")
        }
        .padding(4)
        .frame(height: 44)
        .background {
            Capsule()
                .fill(Color(hex: "#18181A"))
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
    }
    
    @ViewBuilder
    private func typeTabButton(typeOption: TransactionType, title: String, icon: String) -> some View {
        let isSelected = type == typeOption
        
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                type = typeOption
            }
            HapticsManager.shared.trigger(.selection)
        }) {
            if isSelected {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                    
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background {
                    Capsule()
                        .fill(Color(hex: "#242426"))
                        .overlay {
                            Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        }
                }
                .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
            } else {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(Color(hex: "#101012"))
                        .overlay {
                            Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                        }
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Folder Name Card
    private var folderNameCard: some View {
        HStack(spacing: 12) {
            TextField("Folder Name", text: $name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                }
        }
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        Button(action: {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            
            HapticsManager.shared.trigger(.success)
            
            if let existing = folderToEdit {
                let updated = Folder(id: existing.id, name: trimmed, type: type)
                store.updateFolder(updated, oldName: existing.name)
            } else {
                let newFolder = Folder(name: trimmed, type: type)
                store.addFolder(newFolder)
            }
            dismiss()
        }) {
            Text(isEditing ? "Save Changes" : "Create")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(uiColor: .dynamic(light: .white, dark: .black)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(SpendyColors.primaryBlue, in: Capsule())
                .shadow(color: Color.black.opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1.0)
    }
}
