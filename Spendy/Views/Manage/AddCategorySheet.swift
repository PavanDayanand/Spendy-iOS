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
    @State private var showIconPicker: Bool = false
    @State private var showColorPalette: Bool = true
    @State private var showDeleteConfirm: Bool = false
    
    private let availableColors = [
        "#FFFFFF", "#E4E4E7", "#D4D4D8", "#A1A1AA",
        "#71717A", "#52525B", "#3F3F46", "#27272A",
        "#18181B", "#09090B"
    ]
    
    private let availableSymbols = [
        // Shopping & Food
        "cart.fill", "fork.knife", "takeoutbag.and.cup.and.straw.fill", "cup.and.saucer.fill",
        "bag.fill", "gift.fill", "tag.fill", "creditcard.fill",
        
        // Transport & Auto
        "bus.fill", "car.fill", "fuelpump.fill", "tram.fill",
        "airplane", "bicycle", "gearshape.2.fill",
        
        // Living & Utilities
        "house.fill", "bolt.fill", "drop.fill", "wifi",
        "calendar.badge.clock", "tv.fill", "gamecontroller.fill",
        
        // Health & Wellness
        "heart.fill", "cross.case.fill", "figure.run", "pills.fill",
        
        // Income & Work
        "dollarsign.circle.fill", "briefcase.fill", "chart.line.uptrend.xyaxis",
        "percent", "arrow.uturn.left.circle.fill", "banknote.fill"
    ]
    
    private var availableFolders: [String] {
        if type == .expense {
            return ["Everyday Spending", "Transport", "Living", "Personal & Wellness", "Uncategorized"]
        } else {
            return ["Salary & Career", "Investments & Other", "Uncategorized"]
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
        } else {
            _type = State(initialValue: defaultType)
            _selectedFolder = State(initialValue: defaultFolder ?? (defaultType == .expense ? "Everyday Spending" : "Salary & Career"))
            _selectedColorHex = State(initialValue: "#FFFFFF")
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header: Close ✕, Expense/Income Toggle, and Delete (if editing)
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Circle Avatar with Pencil Badge & Category Title
                        avatarHeroSection
                            .padding(.top, 16)
                        
                        // Category Name Input & Color Swatch Trigger
                        nameAndColorCard
                        
                        // Color Palette Swatches (Always accessible)
                        if showColorPalette {
                            colorPaletteSection
                        }
                        
                        // Folder Selector Card
                        folderSelectionCard
                        
                        // Icon Picker Grid
                        iconPickerSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom Save/Create button
                }
            }
            
            // Bottom Fixed Action Button (Create / Save Changes)
            bottomActionButton
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
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
    private var topHeaderBar: some View {
        HStack {
            // Circular Glass Close Button ✕
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
            
            // Expense / Income Segmented Glass Toggle Pill
            typeToggleCapsule
            
            Spacer()
            
            // Right Delete Button (if editing) or spacing balancer
            if isEditing {
                GlassCircleButton(
                    icon: "trash.fill",
                    size: 44,
                    iconSize: 14,
                    tintColor: SpendyColors.expenseRed,
                    foregroundColor: SpendyColors.expenseRed,
                    haptic: .warning,
                    accessibilityLabel: "Delete Category"
                ) {
                    showDeleteConfirm = true
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Type Toggle Capsule (Expense / Income)
    private var typeToggleCapsule: some View {
        HStack(spacing: 4) {
            Button(action: {
                withAnimation(.spring(response: 0.25)) {
                    type = .expense
                    if selectedFolder == "Salary & Career" || selectedFolder == "Investments & Other" {
                        selectedFolder = "Everyday Spending"
                    }
                }
                HapticsManager.shared.trigger(.selection)
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.down.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("Expense")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(
                    type == .expense
                        ? Color(uiColor: .dynamic(light: .white, dark: .black))
                        : SpendyColors.textSecondary
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if type == .expense {
                        Capsule()
                            .fill(SpendyColors.primaryBlue)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Button(action: {
                withAnimation(.spring(response: 0.25)) {
                    type = .income
                    if selectedFolder == "Everyday Spending" || selectedFolder == "Transport" || selectedFolder == "Living" {
                        selectedFolder = "Salary & Career"
                    }
                }
                HapticsManager.shared.trigger(.selection)
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                    Text("Income")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(
                    type == .income
                        ? Color(uiColor: .dynamic(light: .white, dark: .black))
                        : SpendyColors.textSecondary
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if type == .income {
                        Capsule()
                            .fill(SpendyColors.primaryBlue)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(3)
        .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
        .overlay {
            Capsule().stroke(SpendyColors.separator, lineWidth: 0.8)
        }
    }
    
    // MARK: - Avatar Hero Section
    private var avatarHeroSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Large Circular Avatar
                Button(action: {
                    withAnimation(.spring(response: 0.25)) {
                        showIconPicker.toggle()
                    }
                    HapticsManager.shared.trigger(.light)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: selectedColorHex))
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: selectedColorHex).opacity(0.40), radius: 12, y: 4)
                        
                        if selectedSymbol != "tag.fill" {
                            Image(systemName: selectedSymbol)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Text(avatarLetter)
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // Small Pencil Edit Badge ✎
                Button(action: {
                    withAnimation(.spring(response: 0.25)) {
                        showIconPicker.toggle()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(SpendyColors.cardBackgroundSecondary)
                            .frame(width: 26, height: 26)
                            .overlay {
                                Circle().stroke(SpendyColors.separator, lineWidth: 1)
                            }
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
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
        HStack(spacing: 12) {
            TextField("Category Name", text: $label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            
            // Circular Color Picker Swatch Button
            Button(action: {
                withAnimation(.spring(response: 0.25)) {
                    showColorPalette.toggle()
                }
                HapticsManager.shared.trigger(.light)
            }) {
                Circle()
                    .fill(Color(hex: selectedColorHex))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Circle().stroke(SpendyColors.separator, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
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
    
    // MARK: - Color Palette Section
    private var colorPaletteSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableColors, id: \.self) { hex in
                    Button(action: {
                        selectedColorHex = hex
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 34, height: 34)
                            .overlay {
                                if selectedColorHex == hex {
                                    Circle()
                                        .stroke(SpendyColors.textPrimary, lineWidth: 2.5)
                                        .shadow(color: Color.black.opacity(0.4), radius: 3)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
    }
    
    // MARK: - Folder Selection Card
    private var folderSelectionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                ForEach(availableFolders, id: \.self) { folder in
                    Button(folder) {
                        selectedFolder = folder
                        HapticsManager.shared.trigger(.selection)
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
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
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
    
    // MARK: - Icon Picker Grid
    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Select Icon")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpendyColors.textTertiary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.25)) {
                        showIconPicker.toggle()
                    }
                }) {
                    Text(showIconPicker ? "Hide" : "Show All")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(showIconPicker ? availableSymbols : Array(availableSymbols.prefix(12)), id: \.self) { sym in
                    Button(action: {
                        selectedSymbol = sym
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        ZStack {
                            Circle()
                                .fill(selectedSymbol == sym ? Color(hex: selectedColorHex) : SpendyColors.cardBackgroundSecondary)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: sym)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(selectedSymbol == sym ? .white : SpendyColors.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - Bottom Action Button (Create / Save Changes)
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
                .foregroundStyle(Color(uiColor: .dynamic(light: .white, dark: .black)))
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
