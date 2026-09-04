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
    @FocusState private var isSearchFocused: Bool
    
    // Sheets presentation states
    @State private var showAddCategory: Bool = false
    @State private var showAddFolder: Bool = false
    @State private var selectedFolderForAdd: String? = nil
    @State private var categoryToEdit: Category? = nil
    @State private var folderToEdit: Folder? = nil
    @State private var categoryToDelete: Category? = nil
    @Namespace private var categoriesNamespace
    
    // Default folder ordering for clean layout
    private let expenseFolderOrder = ["Everyday Spending", "Transport", "Living", "Personal & Wellness", "Uncategorized"]
    private let incomeFolderOrder = ["Salary & Career", "Investments & Other", "Uncategorized"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.settingsBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Expense / Income Segmented Glass Toggle
                    typeSegmentedControl
                        .padding(.top, 12)
                    
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
                .padding(.top, 6)
                .padding(.bottom, 120) // Clearance for bottom floating bar
            }
            
            // Bottom Floating Bar: Search Capsule + Plus Button
            bottomFloatingBar
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticsManager.shared.trigger(.light)
                    withAnimation(.spring(response: 0.25)) {
                        isEditMode.toggle()
                    }
                } label: {
                    Image(systemName: isEditMode ? "checkmark" : "pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isEditMode ? SpendyColors.primaryBlue : SpendyColors.textPrimary)
                }
            }
        }
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
        .alert(
            "Delete Category?",
            isPresented: Binding(
                get: { categoryToDelete != nil },
                set: { if !$0 { categoryToDelete = nil } }
            )
        ) {
            Button("Delete \(categoryToDelete?.label ?? "Category")", role: .destructive) {
                if let cat = categoryToDelete {
                    store.deleteCategory(id: cat.id)
                }
                categoryToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            Text("Past transactions assigned to this category will remain.")
        }
    }
    
    // MARK: - Type Segmented Control (Expense / Income - Liquid Glass)
    private var typeSegmentedControl: some View {
        GlassSegmentedPicker(
            selection: $selectedType,
            items: [.expense, .income],
            titleFor: { $0.title },
            iconFor: { $0.sfSymbol }
        )
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
                
                if title != "Uncategorized" {
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        if let folderObj = store.customFolders.first(where: { $0.name == title && $0.type == selectedType }) {
                            folderToEdit = folderObj
                        } else {
                            folderToEdit = Folder(name: title, type: selectedType)
                        }
                    }) {
                        Text("Edit")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(SpendyColors.primaryBlue)
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
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
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
                                // SpendyIconBadge (Dynamic Color)
                                SpendyIconBadge(
                                    sfSymbol: cat.sfSymbol,
                                    color: cat.color,
                                    size: .medium,
                                    style: .rounded()
                                )
                                
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
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
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
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(cat.label), \(cat.type.rawValue) category")
                        .draggable(cat.id) {
                            HStack(spacing: 10) {
                                SpendyIconBadge(
                                    sfSymbol: cat.sfSymbol,
                                    color: cat.color,
                                    size: .small,
                                    style: .rounded()
                                )
                                Text(cat.label)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(SpendyColors.sheetCardBackground, in: Capsule())
                        }
                        
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
                    .fill(SpendyColors.sheetCardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
            .dropDestination(for: String.self) { items, _ in
                guard let catId = items.first else { return false }
                if let idx = store.categories.firstIndex(where: { $0.id == catId }) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        store.categories[idx].folder = title
                    }
                    HapticsManager.shared.trigger(.success)
                    return true
                }
                return false
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
        let isSearchActive = isSearchFocused || !searchQuery.isEmpty
        return SpendyGlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                // Search Bar Capsule (Smoothly expands to full width when focused or containing text)
                HStack(spacing: 8) {
                    Image(systemName: SFIcons.search)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(SpendyColors.textTertiary)
                    
                    TextField("Search categories", text: $searchQuery)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                    
                    if isSearchActive {
                        Button {
                            HapticsManager.shared.trigger(.tick)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                searchQuery = ""
                                isSearchFocused = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(SpendyColors.textTertiary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, isSearchActive ? 4 : 16)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .nativeLiquidGlassCapsule(isInteractive: true)
                .glassMorphID("searchCapsule", in: categoriesNamespace)
                
                if !isSearchActive {
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
                            foregroundColor: SpendyColors.textPrimary,
                            haptic: .medium,
                            accessibilityLabel: "Add Options Menu",
                            morphID: "addPlusButton",
                            namespace: categoriesNamespace
                        ) {
                            // Tap action intercepted by Menu wrapper
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isSearchActive)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    private var filteredCategories: [Category] {
        var list = store.categories.filter { $0.type == selectedType }
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter { $0.label.localizedCaseInsensitiveContains(searchQuery) }
        }
        return list
    }
}
