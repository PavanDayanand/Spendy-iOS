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
            _selectedColorHex = State(initialValue: "#FFFFFF")
            _showColorPalette = State(initialValue: false)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            // Dynamic Category Full-Width Ambient Header Glow based on selected category color
            let themeColor = Color(hex: selectedColorHex)
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
                        // Hero Circle Avatar
                        avatarHeroSection
                            .padding(.top, 32)
                        
                        // Category Name Field & Color Circle button
                        nameAndColorCard
                        
                        // Color Palette / Sliders Card (Settings style)
                        if showColorPalette {
                            colorPickerCard
                        }
                        
                        // Folder Selector Card
                        folderSelectionCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom button
                }
            }
            .onAppear {
                syncSlidersFromHex(selectedColorHex)
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
        .sheet(isPresented: $showIconPickerSheet) {
            CategoryIconPickerSheet(selectedSymbol: $selectedSymbol)
        }
        .confirmationDialog(
            "Delete Category?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
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
    
    // MARK: - Top Header Bar
    @Namespace private var headerNamespace
    
    private var topHeaderBar: some View {
        HStack {
            // Close Button
            GlassCircleButton(
                icon: "xmark",
                size: 44,
                iconSize: 14,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close",
                morphID: "closeButton",
                namespace: headerNamespace
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
                    accessibilityLabel: "Delete Category",
                    morphID: "deleteButton",
                    namespace: headerNamespace
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
        GlassSegmentedPicker(
            selection: $type,
            items: [.expense, .income],
            titleFor: { $0.title },
            iconFor: { $0.sfSymbol }
        )
        .glassMorphID("categoryTypePill", in: headerNamespace)
        .onChange(of: type) { _, typeOption in
            let folders = typeOption == .expense
                ? ["Everyday Spending", "Transport", "Living", "Personal & Wellness"] + store.customFolders.filter { $0.type == .expense }.map { $0.name } + ["Uncategorized"]
                : ["Salary & Career", "Investments & Other"] + store.customFolders.filter { $0.type == .income }.map { $0.name } + ["Uncategorized"]
            if !folders.contains(selectedFolder) {
                selectedFolder = typeOption == .expense ? "Everyday Spending" : "Salary & Career"
            }
        }
    }
    
    // MARK: - Avatar Hero Section
    private var avatarHeroSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Large Circular Avatar using unified SpendyIconBadge
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showIconPickerSheet = true
                }) {
                    SpendyIconBadge(
                        sfSymbol: selectedSymbol,
                        color: Color(hex: selectedColorHex),
                        size: .hero,
                        style: .circle
                    )
                }
                .buttonStyle(.plain)
                
                // Small Pencil Edit Badge
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showIconPickerSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#1C1C1E"))
                            .frame(width: 26, height: 26)
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                            }
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: 2, y: -2)
            }
            
            Text(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Category Name" : label)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
        }
    }
    
    // MARK: - Name & Color Card
    private var nameAndColorCard: some View {
        HStack {
            TextField("Category Name", text: $label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .autocorrectionDisabled()
            
            Spacer()
            
            // Circular Color Picker button
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showColorPalette.toggle()
                }
                HapticsManager.shared.trigger(.light)
            }) {
                Circle()
                    .fill(Color(hex: selectedColorHex))
                    .frame(width: 24, height: 24)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.06), in: Capsule())
    }
    
    // MARK: - Custom Color Picker (Image 2 style)
    private var colorPickerCard: some View {
        VStack(spacing: 16) {
            SpendyColorPresetSwatches(selectedHex: $selectedColorHex, hue: $sliderHue, brightness: $sliderBrightness)
                .onChange(of: selectedColorHex) { _, newHex in
                    syncSlidersFromHex(newHex)
                }
                .onChange(of: sliderHue) { _, newValue in
                    updateHexFromHSB()
                }
                .onChange(of: sliderBrightness) { _, newValue in
                    updateHexFromHSB()
                }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "#141416"))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                }
        }
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
    
    // MARK: - Folder Selection Card
    private var folderSelectionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                ForEach(availableFolders, id: \.self) { folder in
                    Button(action: {
                        selectedFolder = folder
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        if selectedFolder == folder {
                            Label(folder, systemImage: "checkmark")
                        } else {
                            Text(folder)
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Folder")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text(selectedFolder)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        }
                }
            }
            .buttonStyle(.plain)
            
            Text("Assign this category to a folder for better organization")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.horizontal, 6)
        }
    }
    
    // MARK: - Bottom Action Button
    private var bottomActionButton: some View {
        Button(action: {
            HapticsManager.shared.trigger(.success)
            let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
            
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
        }) {
            Text(isEditing ? "Save Changes" : "Create")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(SpendyColors.primaryBlue, in: Capsule())
                .shadow(color: Color.black.opacity(0.15), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1.0)
    }
    
    private var avatarLetter: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "C" : String(trimmed.prefix(1)).uppercased()
    }
}

//
