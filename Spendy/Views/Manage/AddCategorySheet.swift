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
    @State private var showSliders: Bool = false
    
    private let presetColors = [
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Gold / Yellow
        "#34C759", // Green
        "#00C7BE", // Teal / Cyan
        "#007AFF", // Blue
        "#5856D6", // Purple
        "#AF52DE"  // Pink Violet
    ]
    
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
            
            // Dynamic Category Ambient Gradient Glow based on selected category color
            let themeColor = Color(hex: selectedColorHex)
            VStack {
                RadialGradient(
                    colors: [
                        themeColor.opacity(0.35),
                        themeColor.opacity(0.12),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 360
                )
                .frame(height: 380)
                .blur(radius: 15)
                .ignoresSafeArea()
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                // Top Header: Close, Type Toggle Switcher, Delete
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Circle Avatar
                        avatarHeroSection
                            .padding(.top, 52)
                        
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
                    accessibilityLabel: "Delete Category"
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
                let folders = typeOption == .expense
                    ? ["Everyday Spending", "Transport", "Living", "Personal & Wellness"] + store.customFolders.filter { $0.type == .expense }.map { $0.name } + ["Uncategorized"]
                    : ["Salary & Career", "Investments & Other"] + store.customFolders.filter { $0.type == .income }.map { $0.name } + ["Uncategorized"]
                if !folders.contains(selectedFolder) {
                    selectedFolder = typeOption == .expense ? "Everyday Spending" : "Salary & Career"
                }
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
    
    // MARK: - Avatar Hero Section
    private var avatarHeroSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Large Circular Avatar
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showIconPickerSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: selectedColorHex))
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: selectedColorHex).opacity(0.40), radius: 12, y: 4)
                        
                        if selectedSymbol != "tag.fill" {
                            Image(systemName: selectedSymbol)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(selectedColorHex == "#FFFFFF" ? .black : .white)
                        } else {
                            Text(avatarLetter)
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundStyle(selectedColorHex == "#FFFFFF" ? .black : .white)
                        }
                    }
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
            // presets row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Spectrum Wheel Circle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showSliders.toggle()
                        }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red]),
                                    center: .center
                                )
                            )
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: showSliders ? 2.5 : 0)
                            )
                            .shadow(color: Color.white.opacity(0.35), radius: showSliders ? 4 : 0)
                    }
                    .buttonStyle(.plain)
                    
                    // preset circles
                    ForEach(presetColors, id: \.self) { hex in
                        Button(action: {
                            selectedColorHex = hex
                            syncSlidersFromHex(hex)
                            HapticsManager.shared.trigger(.light)
                        }) {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if selectedColorHex == hex {
                                        Circle()
                                            .stroke(SpendyColors.textPrimary, lineWidth: 2)
                                            .shadow(color: Color.black.opacity(0.3), radius: 3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
            
            // hue & brightness sliders
            if showSliders {
                VStack(spacing: 14) {
                    // Hue slider
                    HueSpectrumSlider(hue: $sliderHue)
                        .onChange(of: sliderHue) { _, newValue in
                            updateHexFromHSB()
                        }
                    
                    // Brightness slider
                    DarkBrightnessSlider(hue: sliderHue, brightness: $sliderBrightness)
                        .onChange(of: sliderBrightness) { _, newValue in
                            updateHexFromHSB()
                        }
                }
                .padding(.vertical, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(SpendyColors.separator, lineWidth: 0.8)
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

// MARK: - Hue Spectrum Slider Component
private struct HueSpectrumSlider: View {
    @Binding var hue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let thumbX = CGFloat(hue) * width
            
            ZStack(alignment: .leading) {
                // Hue Spectrum Gradient Bar
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hue: 0.0, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.17, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.33, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.50, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.67, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.83, saturation: 1.0, brightness: 0.95),
                                Color(hue: 1.0, saturation: 1.0, brightness: 0.95)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 38)
                
                // Draggable Thumb
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .background(Circle().fill(Color(hue: hue, saturation: 1.0, brightness: 0.95)))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: max(16, min(width - 16, thumbX)), y: 19)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let locationX = max(0, min(geometry.size.width, value.location.x))
                        let newHue = Double(locationX / geometry.size.width)
                        self.hue = newHue
                    }
            )
        }
        .frame(height: 38)
    }
}

// MARK: - Dark-to-Medium Brightness Slider Component
private struct DarkBrightnessSlider: View {
    let hue: Double
    @Binding var brightness: Double
    
    private let minB: Double = 0.12
    private let maxB: Double = 0.95
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let normB = (brightness - minB) / (maxB - minB)
            let thumbX = CGFloat(max(0, min(1, normB))) * width
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black,
                                Color(hue: hue, saturation: 0.85, brightness: 0.50),
                                Color(hue: hue, saturation: 0.85, brightness: maxB)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 38)
                
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .background(Circle().fill(Color(hue: hue, saturation: 0.85, brightness: min(brightness, maxB))))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: max(16, min(width - 16, thumbX)), y: 19)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let locationX = max(0, min(geometry.size.width, value.location.x))
                        let fraction = Double(locationX / geometry.size.width)
                        let newB = minB + fraction * (maxB - minB)
                        self.brightness = min(max(minB, newB), maxB)
                    }
            )
        }
        .frame(height: 38)
    }
}
