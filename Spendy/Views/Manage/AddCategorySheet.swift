//
//  AddCategorySheet.swift
//  Spendy
//
//  Unified Drawer Sheet for Adding & Editing Categories matching Spendy React App with Liquid Glass Controls
//

import SwiftUI

struct AddCategorySheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var categoryToEdit: Category? = nil
    var defaultType: TransactionType = .expense
    var defaultFolder: String? = nil
    var isSettingsPage: Bool = false
    
    @State private var label: String = ""
    @State private var type: TransactionType = .expense
    @State private var selectedFolder: String = "Everyday Spending"
    @State private var selectedSymbol: String = "tag.fill"
    @State private var selectedColorHex: String = "#FFFFFF"
    
    // Icon picker sheet
    @State private var showIconPickerSheet: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var showDiscardConfirm: Bool = false
    
    
    private var availableFolders: [String] {
        let custom = store.customFolders.filter { $0.type == type }.map { $0.name }
        if type == .expense {
            return ["Everyday Spending", "Transport", "Living", "Personal & Wellness"] + custom + ["Uncategorized"]
        } else {
            return ["Salary & Career", "Investments & Other"] + custom + ["Uncategorized"]
        }
    }
    
    private var isEditing: Bool {
        categoryToEdit != nil
    }
    
    private var hasUnsavedChanges: Bool {
        if let cat = categoryToEdit {
            return label != cat.label || type != cat.type || selectedFolder != (cat.folder.isEmpty ? "Uncategorized" : cat.folder) || selectedSymbol != cat.sfSymbol
        } else {
            return !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSymbol != "tag.fill"
        }
    }
    
    init(categoryToEdit: Category? = nil, defaultType: TransactionType = .expense, defaultFolder: String? = nil, isSettingsPage: Bool = false) {
        self.categoryToEdit = categoryToEdit
        self.defaultType = defaultType
        self.defaultFolder = defaultFolder
        self.isSettingsPage = isSettingsPage
        
        if let cat = categoryToEdit {
            _label = State(initialValue: cat.label)
            _type = State(initialValue: cat.type)
            _selectedFolder = State(initialValue: cat.folder.isEmpty ? "Uncategorized" : cat.folder)
            _selectedSymbol = State(initialValue: cat.sfSymbol)
            _selectedColorHex = State(initialValue: cat.colorHex)
        } else {
            _type = State(initialValue: defaultType)
            _selectedFolder = State(initialValue: defaultFolder ?? (defaultType == .expense ? "Everyday Spending" : "Salary & Career"))
            _selectedColorHex = State(initialValue: "#007AFF")
        }
    }
    
    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                SpendyCreateSheetHeader(
                    showDelete: isEditing,
                    deleteLabel: "Delete Category",
                    onClose: {
                        if hasUnsavedChanges {
                            showDiscardConfirm = true
                        } else {
                            dismiss()
                        }
                    },
                    onDelete: { showDeleteConfirm = true }
                ) {
                    SpendyTransactionTypeToggle(
                        selection: $type,
                        availableTypes: [.expense, .income]
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        avatarHeroSection
                            .padding(.top, 20)
                        
                        SpendyCreateFormCard(fillColor: isSettingsPage ? SpendyColors.settingsCardBackground : SpendyColors.cardBackground) {
                            SpendyCreateFormRow {
                                TextField("Category name", text: $label)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.words)
                            } trailing: {
                                EmptyView()
                            }
                            
                            SpendyCreateFormDivider()
                            
                            Menu {
                                ForEach(availableFolders, id: \.self) { folder in
                                    Button {
                                        selectedFolder = folder
                                        HapticsManager.shared.trigger(.selection)
                                    } label: {
                                        if selectedFolder == folder {
                                            Label(folder, systemImage: "checkmark")
                                        } else {
                                            Text(folder)
                                        }
                                    }
                                }
                            } label: {
                                SpendyCreateFormRow {
                                    Text("Folder")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                } trailing: {
                                    HStack(spacing: 6) {
                                        Text(selectedFolder)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(SpendyColors.textSecondary)
                                            .lineLimit(1)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(SpendyColors.textTertiary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .onChange(of: type) { _, newType in
                let folders = newType == .expense
                    ? ["Everyday Spending", "Transport", "Living", "Personal & Wellness"] + store.customFolders.filter { $0.type == .expense }.map { $0.name } + ["Uncategorized"]
                    : ["Salary & Career", "Investments & Other"] + store.customFolders.filter { $0.type == .income }.map { $0.name } + ["Uncategorized"]
                if !folders.contains(selectedFolder) {
                    selectedFolder = newType == .expense ? "Everyday Spending" : "Salary & Career"
                }
            }
            
            VStack(spacing: 0) {
                SpendyCreatePrimaryButton(
                    title: isEditing ? "Save" : "Create",
                    isEnabled: canSave
                ) {
                    saveCategory()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .padding(.top, 12)
            }
        }
        // Short forms start compact; larger text can use the full sheet.
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(420), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .sheet(isPresented: $showIconPickerSheet) {
            CategoryIconPickerSheet(selectedSymbol: $selectedSymbol)
        }
        .alert("Discard Changes?", isPresented: $showDiscardConfirm) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .alert("Delete Category?", isPresented: $showDeleteConfirm) {
            Button("Delete Category", role: .destructive) {
                if let cat = categoryToEdit {
                    store.deleteCategory(id: cat.id)
                    HapticsManager.shared.trigger(.warning)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Past transactions assigned to \(label.isEmpty ? "this category" : label) will remain.")
        }
    }
    
    private var avatarHeroSection: some View {
        SpendyEditableHeroIcon(
            sfSymbol: selectedSymbol,
            color: Color(hex: selectedColorHex),
            style: .circle,
            monogramName: label,
            accessibilityLabel: "Edit category icon"
        ) {
            showIconPickerSheet = true
        }
    }
    
    private func saveCategory() {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let existing = categoryToEdit {
            var updated = existing
            updated.label = trimmed
            updated.sfSymbol = selectedSymbol
            updated.colorHex = selectedColorHex
            updated.type = type
            updated.folder = selectedFolder
            store.updateCategory(updated)
        } else {
            let newCat = Category(
                id: UUID().uuidString.lowercased(),
                label: trimmed,
                sfSymbol: selectedSymbol,
                colorHex: selectedColorHex,
                type: type,
                folder: selectedFolder,
                order: store.categories.count
            )
            store.addCategory(newCat)
        }
        dismiss()
    }
    
}

//
