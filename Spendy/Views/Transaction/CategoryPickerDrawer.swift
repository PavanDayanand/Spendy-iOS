import SwiftUI

// MARK: - Category Selection Drawer (Clean Custom Drawer & Full Liquid Glass Styling)
struct CategoryPickerDrawer: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategoryId: String
    var currentType: TransactionType
    var categories: [Category]
    var typeSelection: Binding<TransactionType>? = nil
    var onCreateCategory: (() -> Void)? = nil

    @State private var searchText: String = ""

    private var filteredCategories: [Category] {
        categories.filter { $0.type == currentType }
    }

    private var groupedFolders: [CategoryDirectorySection] {
        CategoryDirectory.folderSections(filteredCategories, query: searchText)
    }

    private var suggestedCategories: [Category] {
        if !searchText.isEmpty { return [] }
        return Array(filteredCategories.prefix(2))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyPinnedHeaderLayout(usesSoftScrollEdge: true) {
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        GlassCircleButton(
                            icon: "xmark",
                            size: 44,
                            iconSize: 14,
                            foregroundColor: SpendyColors.textPrimary,
                            haptic: .selection
                        ) {
                            dismiss()
                        }
                        .accessibilityLabel("Close category picker")

                        Spacer()

                        Text("Select category")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)

                        Spacer()

                        if let onCreateCategory {
                            GlassCircleButton(icon: "plus", size: 44, iconSize: 17,
                                foregroundColor: SpendyColors.textPrimary, haptic: .selection,
                                action: onCreateCategory)
                                .accessibilityLabel("Create category")
                        } else {
                            Color.clear.frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                    if let typeSelection {
                        Picker("Transaction type", selection: typeSelection) {
                            Text("Expense").tag(TransactionType.expense)
                            Text("Income").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("receipt-category-type")
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                }
            } content: {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 22) {
                        // 1. Suggested Section
                        if !suggestedCategories.isEmpty {
                            categoryFolderBlock(
                                title: "Suggested",
                                items: suggestedCategories
                            )
                        }
                        
                        // 2. Folder Grouped Sections
                        ForEach(groupedFolders) { group in
                            categoryFolderBlock(
                                title: group.title,
                                items: group.categories
                            )
                        }
                        
                        Spacer(minLength: 88)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            
            // Floating Bottom Liquid Glass Search Bar
            floatingSearchBar
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .presentationDetents([.fraction(0.88), .large])
        .presentationDragIndicator(.visible)
    }
    
    private func categoryFolderBlock(title: String, items: [Category]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 0) {
                ForEach(items) { cat in
                    let isSelected = selectedCategoryId == cat.id
                    
                    Button(action: {
                        selectedCategoryId = cat.id
                        HapticsManager.shared.trigger(.selection)
                        dismiss()
                    }) {
                        HStack(spacing: 14) {
                            SpendyIconBadge(
                                sfSymbol: cat.sfSymbol,
                                color: cat.color,
                                size: .small,
                                style: .circle,
                                monogramName: cat.label
                            )
                            
                            Text(cat.label)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(SpendyColors.textPrimary)
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if cat.id != items.last?.id {
                        Divider()
                            .background(SpendyColors.separator)
                            .padding(.leading, 68)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    private var floatingSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            TextField("Search category", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#8E8E93"))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .nativeLiquidGlassCapsule(isInteractive: true)
        .shadow(color: Color.black.opacity(0.35), radius: 12, y: 4)
    }
}

