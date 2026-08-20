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
    @State private var selectedColorHex: String = "#FF9500"
    @State private var showIconPicker: Bool = false
    @State private var showColorPalette: Bool = true
    @State private var showDeleteConfirm: Bool = false
    
    private let availableColors = [
        "#30D158", "#FF9500", "#FF453A", "#007AFF",
        "#FFD60A", "#AF52DE", "#FF2D55", "#5856D6",
        "#32ADE6", "#FF375F", "#30B0C7", "#8E8E93"
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
            _selectedColorHex = State(initialValue: defaultType == .expense ? "#FF9500" : "#30D158")
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
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .nativeLiquidGlassCircle(isInteractive: true)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Expense / Income Segmented Glass Toggle Pill
            typeToggleCapsule
            
            Spacer()
            
            // Right Delete Button (if editing) or spacing balancer
            if isEditing {
                Button(action: {
                    HapticsManager.shared.trigger(.warning)
                    showDeleteConfirm = true
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SpendyColors.expenseRed)
                        .frame(width: 44, height: 44)
                        .nativeLiquidGlassCircle(isInteractive: true, tint: SpendyColors.expenseRed)
                }
                .buttonStyle(.plain)
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
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(type == .expense ? .white : .white.opacity(0.40))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if type == .expense {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
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
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(type == .income ? .white : .white.opacity(0.40))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if type == .income {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(3)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay {
            Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.8)
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
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
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
                            .fill(Color(hex: "#24262B"))
                            .frame(width: 26, height: 26)
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
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
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Name & Color Card
    private var nameAndColorCard: some View {
        HStack(spacing: 12) {
            TextField("Category Name", text: $label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
            
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
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
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
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
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
                                        .stroke(Color.white, lineWidth: 2.5)
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
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text(selectedFolder)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.70))
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        }
                }
            }
            .buttonStyle(.plain)
            
            Text("Assign this category to a folder for better organization")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.40))
                .padding(.horizontal, 6)
        }
    }
    
    // MARK: - Icon Picker Grid
    private var iconPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Select Icon")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.50))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.25)) {
                        showIconPicker.toggle()
                    }
                }) {
                    Text(showIconPicker ? "Hide" : "Show All")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
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
                                .fill(selectedSymbol == sym ? Color(hex: selectedColorHex) : Color.white.opacity(0.08))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: sym)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(selectedSymbol == sym ? .white : .white.opacity(0.70))
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
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
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
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white, in: Capsule())
                .shadow(color: Color.white.opacity(0.20), radius: 12, y: 4)
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
