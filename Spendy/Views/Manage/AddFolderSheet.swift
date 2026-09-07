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
    @State private var showDiscardConfirm: Bool = false
    
    private var isEditing: Bool {
        folderToEdit != nil
    }
    
    private var hasUnsavedChanges: Bool {
        if let folder = folderToEdit {
            return name != folder.name || type != folder.type
        } else {
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
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
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var themeColor: Color {
        type == .expense ? SpendyColors.primaryBlue : SpendyColors.incomeGreen
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            SpendyAmbientHeaderBackground(color: themeColor, height: 280, opacity: 0.28)
            
            VStack(spacing: 0) {
                SpendyCreateSheetHeader(
                    showDelete: isEditing,
                    deleteLabel: "Delete Folder",
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
                        SpendyIconBadge(
                            sfSymbol: "folder.fill",
                            color: themeColor,
                            size: .hero,
                            style: .rounded(),
                            monogramName: name
                        )
                        .padding(.top, 20)
                        
                        SpendyCreateFormCard {
                            SpendyCreateFormRow {
                                TextField("Folder name", text: $name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.words)
                            } trailing: {
                                EmptyView()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            
            VStack(spacing: 0) {
                SpendyCreatePrimaryButton(
                    title: isEditing ? "Save" : "Create",
                    isEnabled: canSave
                ) {
                    saveFolder()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .padding(.top, 12)
            }
        }
        .presentationBackground(SpendyColors.appBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .alert("Discard Changes?", isPresented: $showDiscardConfirm) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .alert("Delete Folder?", isPresented: $showDeleteConfirm) {
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
    
    private func saveFolder() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let existing = folderToEdit {
            let updated = Folder(id: existing.id, name: trimmed, type: type)
            store.updateFolder(updated, oldName: existing.name)
        } else {
            let newFolder = Folder(name: trimmed, type: type)
            store.addFolder(newFolder)
        }
        dismiss()
    }
}
