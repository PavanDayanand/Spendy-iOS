//
//  AddFolderSheet.swift
//  Spendy
//
//  Drawer Sheet for Adding & Editing Folders matching AddCategorySheet Format
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
            
            // Dynamic Ambient Header Glow based on selected folder type
            let themeColor = type == .expense ? SpendyColors.primaryBlue : SpendyColors.incomeGreen
            SpendyAmbientHeaderBackground(color: themeColor, height: 340, opacity: 0.32)
            
            VStack(spacing: 0) {
                // Top Header: Close, Type Toggle Switcher, Delete (Sticky at top!)
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Circle Avatar (Matching AddCategorySheet)
                        avatarHeroSection
                            .padding(.top, 32)
                        
                        // Folder Name Field (Matching AddCategorySheet)
                        folderNameCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom button
                }
            }
            
            // Bottom Fixed Action Button Container (Full Width)
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
        .presentationBackground(SpendyColors.appBackground)
        .presentationDragIndicator(.hidden)
        .confirmationDialog(
            "Delete Folder?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Folder", role: .destructive) {
                if let folder = folderToEdit {
                    store.deleteFolder(id: folder.id, name: folder.name, type: folder.type)
                    HapticsManager.shared.trigger(.warning)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Categories inside \(name.isEmpty ? "this folder" : name) will be reassigned to Uncategorized.")
        }
    }
    
    // MARK: - Top Header Bar (Matching AddCategorySheet)
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
            
            // Type toggleSwitcher (Expense / Income)
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
    
    // MARK: - Type Toggle Capsule (Exact Match with AddCategorySheet)
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
    
    // MARK: - Avatar Hero Section (Matching AddCategorySheet)
    private var avatarHeroSection: some View {
        VStack(spacing: 12) {
            SpendyIconBadge(
                sfSymbol: "folder.fill",
                color: type == .expense ? SpendyColors.primaryBlue : SpendyColors.incomeGreen,
                size: .hero,
                style: .circle
            )
            
            Text(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Folder Name" : name)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
        }
    }
    
    // MARK: - Folder Name Card (Matching AddCategorySheet Capsule)
    private var folderNameCard: some View {
        HStack {
            TextField("Folder Name", text: $name)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06), in: Capsule())
    }
    
    // MARK: - Bottom Action Button (Matching AddCategorySheet)
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
            Text(isEditing ? "Save Changes" : "Create Folder")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white, in: Capsule())
                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1.0)
    }
}
