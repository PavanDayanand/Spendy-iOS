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
    @State private var showAddCategory: Bool = false
    @State private var selectedFolderForAdd: String? = nil
    @State private var categoryToEdit: Category? = nil
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
        }
        .sheet(item: $categoryToEdit) { cat in
            AddCategorySheet(categoryToEdit: cat)
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
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .nativeLiquidGlassCircle(isInteractive: true)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text("Categories")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Spacer()
            
            // Right "Edit" Capsule Button
            Button(action: {
                withAnimation(.spring(response: 0.25)) {
                    isEditMode.toggle()
                }
                HapticsManager.shared.trigger(.light)
            }) {
                Text(isEditMode ? "Done" : "Edit")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(isEditMode ? SpendyColors.primaryBlue : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .nativeLiquidGlassCapsule(isInteractive: true)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Type Segmented Control (Expense / Income)
    private var typeSegmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Expense", type: .expense)
            segmentButton(title: "Income", type: .income)
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(SpendyColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                }
        }
    }
    
    private func segmentButton(title: String, type: TransactionType) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedType = type
            }
            HapticsManager.shared.trigger(.selection)
        }) {
            Text(title)
                .font(.system(size: 14, weight: selectedType == type ? .bold : .medium, design: .rounded))
                .foregroundStyle(selectedType == type ? .white : .white.opacity(0.40))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    if selectedType == type {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Folder Sections View
    private var folderSectionsView: some View {
        let currentTypeCategories = store.categories.filter { $0.type == selectedType }
        let folderOrder = selectedType == .expense ? expenseFolderOrder : incomeFolderOrder
        
        // Group existing categories by folder
        var grouped: [String: [Category]] = [:]
        for cat in currentTypeCategories {
            let f = cat.folder.isEmpty ? "Uncategorized" : cat.folder
            grouped[f, default: []].append(cat)
        }
        
        // Create ordered list of folders that have categories + any active folder order
        var sortedFolders: [String] = []
        for f in folderOrder {
            if let items = grouped[f], !items.isEmpty {
                sortedFolders.append(f)
            }
        }
        for (f, items) in grouped {
            if !sortedFolders.contains(f) && !items.isEmpty {
                sortedFolders.append(f)
            }
        }
        
        return VStack(spacing: 24) {
            ForEach(sortedFolders, id: \.self) { folderName in
                if let items = grouped[folderName], !items.isEmpty {
                    folderSectionCard(title: folderName, categories: items)
                }
            }
        }
    }
    
    // MARK: - Folder Section Card
    private func folderSectionCard(title: String, categories: [Category]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Folder Header with "Edit" Button on right
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.25)) {
                        isEditMode.toggle()
                    }
                    HapticsManager.shared.trigger(.light)
                }) {
                    Text("Edit")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            // List of Categories in this Folder
            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, cat in
                    Button(action: {
                        HapticsManager.shared.trigger(.light)
                        categoryToEdit = cat
                    }) {
                        HStack(spacing: 14) {
                            // Circular Icon Badge (Monochrome)
                            ZStack {
                                Circle()
                                    .fill(cat.colorHex == "#18181B" ? Color.black : Color(uiColor: .dynamic(light: UIColor(white: 0.85, alpha: 1), dark: UIColor(white: 0.2, alpha: 1))))
                                    .frame(width: 38, height: 38)
                                
                                Image(systemName: cat.sfSymbol)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(cat.colorHex == "#18181B" ? Color.white : SpendyColors.textPrimary)
                            }
                            
                            Text(cat.label)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
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
            folderSectionCard(title: "Matching Categories", categories: filteredCategories)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: SFIcons.categoriesFolder)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
            
            Text("No categories found")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.65))
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
                    .foregroundStyle(.white.opacity(0.45))
                
                TextField("Search categories", text: $searchQuery)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .nativeLiquidGlassCapsule(isInteractive: true)
            
            // Floating Plus (+) Button
            Button(action: {
                HapticsManager.shared.trigger(.medium)
                selectedFolderForAdd = nil
                showAddCategory = true
            }) {
                Image(systemName: SFIcons.plus)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .nativeLiquidGlassCircle(isInteractive: true)
                    .shadow(color: Color.black.opacity(0.25), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
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
