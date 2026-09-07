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
    
    var categoryToEdit: Category? = nil
    var defaultType: TransactionType = .expense
    var defaultFolder: String? = nil
    
    @State private var label: String = ""
    @State private var type: TransactionType = .expense
    @State private var selectedFolder: String = "Everyday Spending"
    @State private var selectedSymbol: String = "tag.fill"
    @State private var selectedColorHex: String = "#FFFFFF"
    
    // Icon picker sheet and Color picker state
    @State private var showIconPickerSheet: Bool = false
    @State private var showColorPalette: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var showDiscardConfirm: Bool = false
    
    // Sliders state for Custom Color Picker (Image 2 style)
    @State private var sliderHue: Double = 0.65
    @State private var sliderBrightness: Double = 0.45
    
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
            return label != cat.label || type != cat.type || selectedFolder != (cat.folder.isEmpty ? "Uncategorized" : cat.folder) || selectedSymbol != cat.sfSymbol || selectedColorHex != cat.colorHex
        } else {
            return !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedSymbol != "tag.fill" || selectedColorHex != "#007AFF"
        }
    }
    
    init(categoryToEdit: Category? = nil, defaultType: TransactionType = .expense, defaultFolder: String? = nil) {
        self.categoryToEdit = categoryToEdit
        self.defaultType = defaultType
        self.defaultFolder = defaultFolder
        
        if let cat = categoryToEdit {
            _label = State(initialValue: cat.label)
            _type = State(initialValue: cat.type)
            _selectedFolder = State(initialValue: cat.folder.isEmpty ? "Uncategorized" : cat.folder)
            _selectedSymbol = State(initialValue: cat.sfSymbol)
            _selectedColorHex = State(initialValue: cat.colorHex)
            _showColorPalette = State(initialValue: false)
        } else {
            _type = State(initialValue: defaultType)
            _selectedFolder = State(initialValue: defaultFolder ?? (defaultType == .expense ? "Everyday Spending" : "Salary & Career"))
            _selectedColorHex = State(initialValue: "#007AFF")
            _showColorPalette = State(initialValue: false)
        }
    }
    
    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            SpendyAmbientHeaderBackground(color: Color(hex: selectedColorHex), height: 280, opacity: 0.28)
            
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
                        
                        SpendyCreateFormCard {
                            SpendyCreateFormRow {
                                TextField("Category name", text: $label)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.words)
                            } trailing: {
                                if !store.isMonoIconMode {
                                    SpendyColorSwatchButton(hex: selectedColorHex) {
                                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                            showColorPalette.toggle()
                                        }
                                    }
                                }
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
                        
                        if showColorPalette && !store.isMonoIconMode {
                            SpendyCreateColorPalette(
                                selectedHex: $selectedColorHex,
                                hue: $sliderHue,
                                brightness: $sliderBrightness
                            )
                            .onChange(of: selectedColorHex) { _, newHex in
                                syncSlidersFromHex(newHex)
                            }
                            .onChange(of: sliderHue) { _, _ in
                                updateHexFromHSB()
                            }
                            .onChange(of: sliderBrightness) { _, _ in
                                updateHexFromHSB()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .onAppear {
                syncSlidersFromHex(selectedColorHex)
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
        .presentationBackground(SpendyColors.appBackground)
        .presentationDetents([.large])
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
            style: .rounded(),
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
    
    private func syncSlidersFromHex(_ hex: String) {
        let color = Color(hex: hex)
        let uiColor = UIColor(color)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            sliderHue = Double(h)
            sliderBrightness = Double(b)
        }
    }
    
    private func updateHexFromHSB() {
        let color = Color(hue: sliderHue, saturation: 0.85, brightness: min(sliderBrightness, 0.95))
        selectedColorHex = color.toHex()
    }
}

//
