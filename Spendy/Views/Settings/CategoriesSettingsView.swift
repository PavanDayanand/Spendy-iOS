//
//  CategoriesSettingsView.swift
//  Spendy
//
//  Grouped Category Management matching the Spendy React App with Folder Organization & Liquid Glass Controls
//

import SwiftUI

struct CategoriesSettingsView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: TransactionType = .expense
    @State private var searchQuery: String = ""
    @State private var isEditMode: Bool = false
    
    // Sheets presentation states
    @State private var showAddCategory: Bool = false
    @State private var showAddFolder: Bool = false
    @State private var selectedFolderForAdd: String? = nil
    @State private var categoryToEdit: Category? = nil
    @State private var folderToEdit: Folder? = nil
    @State private var categoryToDelete: Category? = nil
    
    // Default folder ordering for clean layout
    private let expenseFolderOrder = ["Everyday Spending", "Transport", "Living", "Personal & Wellness", "Uncategorized"]
    private let incomeFolderOrder = ["Salary & Career", "Investments & Other", "Uncategorized"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Top Custom Header Bar
                    headerBar
                    
                    // Expense / Income Segmented Glass Toggle
                    typeSegmentedControl
                        .padding(.top, 4)
                    
                    // Grouped Categories Content
                    if filteredCategories.isEmpty {
                        emptyStateView
                    } else if searchQuery.isEmpty {
                        folderSectionsView
                    } else {
                        searchResultsView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 120) // Clearance for bottom floating bar
            }
            
            // Bottom Floating Bar: Search Capsule + Plus Button
            bottomFloatingBar
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet(categoryToEdit: nil, defaultType: selectedType, defaultFolder: selectedFolderForAdd)
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $categoryToEdit) { cat in
            AddCategorySheet(categoryToEdit: cat)
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(isPresented: $showAddFolder) {
            AddFolderSheet(folderToEdit: nil, defaultType: selectedType)
                .presentationBackground(SpendyColors.appBackground)
        }
        .sheet(item: $folderToEdit) { folder in
            AddFolderSheet(folderToEdit: folder)
                .presentationBackground(SpendyColors.appBackground)
        }
        .confirmationDialog(
            "Delete Category?",
            isPresented: Binding(
                get: { categoryToDelete != nil },
                set: { if !$0 { categoryToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete \(categoryToDelete?.label ?? "Category")", role: .destructive) {
                if let cat = categoryToDelete {
                    store.deleteCategory(id: cat.id)
                }
                categoryToDelete = nil
            }
        } message: {
            Text("Past transactions assigned to this category will remain.")
        }
    }
    
    // MARK: - Top Header Bar
    private var headerBar: some View {
        HStack {
            // Circular Glass Back Button
            GlassCircleButton(
                icon: "chevron.left",
                size: 44,
                iconSize: 15,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Back"
            ) {
                dismiss()
            }
            
            Spacer()
            
            Text("Categories")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            // Right "Edit" Circle Toggle Button
            GlassCircleButton(
                icon: isEditMode ? "checkmark" : "pencil",
                size: 44,
                iconSize: 15,
                foregroundColor: isEditMode ? SpendyColors.primaryBlue : SpendyColors.textPrimary,
                haptic: .light,
                accessibilityLabel: "Toggle Edit Mode"
            ) {
                withAnimation(.spring(response: 0.25)) {
                    isEditMode.toggle()
                }
            }
        }
    }
    
    // MARK: - Type Segmented Control (Expense / Income - Liquid Glass)
    private var typeSegmentedControl: some View {
        HStack(spacing: 6) {
            segmentButton(title: "Expense", type: .expense, icon: "arrow.up.right")
            segmentButton(title: "Income", type: .income, icon: "arrow.down.left")
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
    private func segmentButton(title: String, type: TransactionType, icon: String) -> some View {
        let isSelected = selectedType == type
        
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedType = type
            }
            HapticsManager.shared.trigger(.selection)
        }) {
            HStack(spacing: 8) {
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color(hex: "#242426"))
                        .overlay {
                            Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        }
                        .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Folder Sections View
    private var folderSectionsView: some View {
        let currentTypeCategories = store.categories.filter { $0.type == selectedType }
        let customFoldersForType = store.customFolders.filter { $0.type == selectedType }
        let defaultFolders = selectedType == .expense ? expenseFolderOrder : incomeFolderOrder
        
        // Merge folders: default system folders first (excluding Uncategorized), then custom folders, then Uncategorized at the end.
        var allFolders = defaultFolders.filter { $0 != "Uncategorized" }
        for f in customFoldersForType {
            if !allFolders.contains(f.name) {
                allFolders.append(f.name)
            }
        }
        allFolders.append("Uncategorized")
        
        // Group existing categories by folder
        var grouped: [String: [Category]] = [:]
        for cat in currentTypeCategories {
            let f = cat.folder.isEmpty ? "Uncategorized" : cat.folder
            grouped[f, default: []].append(cat)
        }
        
        return VStack(spacing: 24) {
            ForEach(allFolders, id: \.self) { folderName in
                let items = grouped[folderName] ?? []
                let isCustomFolder = customFoldersForType.contains(where: { $0.name == folderName })
                folderSectionCard(title: folderName, categories: items, isCustom: isCustomFolder)
            }
        }
    }
    
    // MARK: - Folder Section Card
    private func folderSectionCard(title: String, categories: [Category], isCustom: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Folder Header with "Edit" Button on right
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
                
                Spacer()
                
                if isCustom {
                    Button(action: {
                        if let folderObj = store.customFolders.first(where: { $0.name == title && $0.type == selectedType }) {
                            HapticsManager.shared.trigger(.light)
                            folderToEdit = folderObj
                        }
                    }) {
                        Text("Edit")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.primaryBlue)
                    }
                    .buttonStyle(.plain)
                } else if !categories.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.25)) {
                            isEditMode.toggle()
                        }
                        HapticsManager.shared.trigger(.light)
                    }) {
                        Text(isEditMode ? "Done" : "Edit")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            
            // List of Categories in this Folder
            VStack(spacing: 0) {
                if categories.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Text("No categories in this folder")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(SpendyColors.textTertiary)
                            
                            Button(action: {
                                selectedFolderForAdd = title
                                showAddCategory = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Add Category")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(SpendyColors.primaryBlue)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                } else {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, cat in
                        Button(action: {
                            HapticsManager.shared.trigger(.light)
                            categoryToEdit = cat
                        }) {
                            HStack(spacing: 14) {
                                // Circular Icon Badge (Dynamic Color)
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: cat.colorHex))
                                        .frame(width: 38, height: 38)
                                    
                                    let isLightColor = cat.colorHex.uppercased() == "#FFFFFF" || cat.colorHex.uppercased() == "FFFFFF" || cat.colorHex.uppercased() == "#E4E4E7" || cat.colorHex.uppercased() == "#D4D4D8"
                                    Image(systemName: cat.sfSymbol)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(isLightColor ? Color.black : Color.white)
                                }
                                
                                Text(cat.label)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Spacer()
                                
                                if isEditMode {
                                    Button(role: .destructive) {
                                        categoryToDelete = cat
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(SpendyColors.expenseRed)
                                    }
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(SpendyColors.textTertiary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                        }
                        .buttonStyle(.plain)
                        
                        if index < categories.count - 1 {
                            Divider()
                                .overlay(SpendyColors.separator)
                                .padding(.leading, 68)
                        }
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    // MARK: - Search Results View
    private var searchResultsView: some View {
        VStack(spacing: 12) {
            folderSectionCard(title: "Matching Categories", categories: filteredCategories, isCustom: false)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: SFIcons.categoriesFolder)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(SpendyColors.textTertiary)
            
            Text("No categories found")
                .font(.system(.body, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Bottom Floating Bar (Search Capsule + Plus Button)
    private var bottomFloatingBar: some View {
        HStack(spacing: 12) {
            // Search Bar Capsule
            HStack(spacing: 8) {
                Image(systemName: SFIcons.search)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(SpendyColors.textTertiary)
                
                TextField("Search categories", text: $searchQuery)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .nativeLiquidGlassCapsule(isInteractive: true)
            
            // Floating Plus (+) Button with context menu dropdown options
            Menu {
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    showAddFolder = true
                }) {
                    Label("Create a Folder", systemImage: "folder.badge.plus")
                }
                
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    selectedFolderForAdd = nil
                    showAddCategory = true
                }) {
                    Label("Create a Category", systemImage: "plus.circle")
                }
            } label: {
                GlassCircleButton(
                    icon: SFIcons.plus,
                    size: 52,
                    iconSize: 20,
                    tintColor: SpendyColors.primaryBlue,
                    foregroundColor: Color(uiColor: .dynamic(light: .white, dark: .black)),
                    haptic: .medium,
                    accessibilityLabel: "Add Options Menu"
                ) {
                    // Tap action intercepted by Menu wrapper
                }
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var filteredCategories: [Category] {
        var list = store.categories.filter { $0.type == selectedType }
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter { $0.label.localizedCaseInsensitiveContains(searchQuery) }
        }
        return list
    }
}
