//
//  AddTransactionView.swift
//  Spendy
//
//  Pixel-Perfect iOS Liquid Glass Transaction Screen with Consistently-Padded Toggles,
//  Uniform 44pt Control Heights, Inline Note Editor with Confirm Checkmark, Dual Transfer Cards,
//  Clean 3-Column Numeric Keypad (No Math Operators), and Non-Duplicated Liquid Glass Sheets.
//

import SwiftUI

// MARK: - Active Sheet Enum for Single-Sheet Presentation
enum TransactionActiveSheet: Identifiable {
    case category
    case account(isDestination: Bool)
    case calendar
    
    var id: String {
        switch self {
        case .category: return "category"
        case .account(let isDest): return "account_\(isDest)"
        case .calendar: return "calendar"
        }
    }
}

struct AddTransactionView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    var transactionToEdit: Transaction? = nil
    
    // Core Transaction State
    @State private var type: TransactionType = .expense
    @State private var amountString: String = "0"
    @State private var selectedCategoryId: String = "groceries"
    @State private var fromAccountId: String = "bank"
    @State private var toAccountId: String = "cash"
    @State private var note: String = ""
    @State private var date: Date = Date()
    
    // UI Mode State (Inline Note Editor)
    @State private var isEditingNote: Bool = false
    @FocusState private var isNoteFocused: Bool
    @Namespace private var transactionNamespace
    
    // Single Active Sheet State
    @State private var activeSheet: TransactionActiveSheet? = nil
    
    private var isEditing: Bool {
        transactionToEdit != nil
    }
    
    private var currentAmountValue: Double {
        Double(amountString) ?? 0.0
    }
    
    private var selectedCategory: Category? {
        store.categories.first(where: { $0.id == selectedCategoryId })
    }
    
    private var fromAccount: Account? {
        store.accounts.first(where: { $0.id == fromAccountId }) ?? store.accounts.first
    }
    
    private var toAccount: Account? {
        store.accounts.first(where: { $0.id == toAccountId }) ?? store.accounts.last
    }
    
    private var availableCategories: [Category] {
        store.categories.filter { $0.type == type }
    }
    
    // Date formatted string
    private var formattedDateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }
    
    init(transactionToEdit: Transaction? = nil, defaultType: TransactionType = .expense) {
        self.transactionToEdit = transactionToEdit
        if let t = transactionToEdit {
            _type = State(initialValue: t.type)
            _amountString = State(initialValue: String(format: t.amount.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", t.amount))
            _selectedCategoryId = State(initialValue: t.categoryId)
            _fromAccountId = State(initialValue: t.accountId)
            _toAccountId = State(initialValue: t.toAccountId ?? "cash")
            _note = State(initialValue: t.notes ?? "")
            _date = State(initialValue: t.date)
        } else {
            _type = State(initialValue: defaultType)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#101012")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 1. Top Header Bar (Close ✕ | 44pt Type Switcher | More ...)
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                // MARK: - 2. Subheader Row (Account Pill + Currency Flag)
                subHeaderRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
                
                if isEditingNote {
                    inlineNoteEditorView
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    Spacer()
                } else {
                    // MARK: - 3. Amount Display
                    if type == .transfer {
                        transferCardsSection
                    } else {
                        standardAmountSection
                    }
                    
                    Spacer(minLength: 8)
                    
                    // MARK: - 5. Bottom Keypad & Actions
                    keypadAndActionsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                }
            }
        }
        .presentationBackground(Color(hex: "#101012"))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .category:
                CategoryPickerDrawer(
                    selectedCategoryId: $selectedCategoryId,
                    currentType: type,
                    categories: availableCategories
                )
            case .account(let isDestination):
                AccountPickerDrawer(
                    selectedAccountId: isDestination ? $toAccountId : $fromAccountId,
                    title: isDestination ? "Select destination account" : "Select account",
                    accounts: store.accounts
                )
            case .calendar:
                CustomCalendarDrawer(selectedDate: $date)
            }
        }
    }
    
    // MARK: - 1. Top Header Bar (Close ✕ | 44pt Type Switcher | More ...)
    private var topHeaderBar: some View {
        HStack(alignment: .center) {
            // Standard 44x44 Circular Glass Close Button ✕
            GlassCircleButton(
                icon: "xmark",
                size: 44,
                iconSize: 15,
                foregroundColor: .white,
                haptic: .selection,
                accessibilityLabel: "Close",
                morphID: "closeButton",
                namespace: transactionNamespace
            ) {
                dismiss()
            }
            
            Spacer()
            
            // Standard 44pt Height Liquid Glass Type Switcher
            liquidGlassTypeSwitcher
            
            Spacer()
            
            // Standard 44x44 More Options Menu ...
            Menu {
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    clearAll()
                }) {
                    Label("Clear Amount", systemImage: "delete.left")
                }
                
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    date = Date()
                }) {
                    Label("Reset Date to Today", systemImage: "calendar")
                }
                
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isEditingNote = true
                    }
                }) {
                    Label("Add Note", systemImage: "square.and.pencil")
                }
            } label: {
                GlassCircleIcon(
                    size: 44,
                    morphID: "moreButton",
                    namespace: transactionNamespace
                ) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    // MARK: - Clean Capsule Type Switcher
    private var liquidGlassTypeSwitcher: some View {
        GlassSegmentedPicker(
            selection: $type,
            items: TransactionType.allCases,
            titleFor: { $0.title },
            iconFor: { $0.sfSymbol }
        )
        .glassMorphID("activeTypePill", in: transactionNamespace)
    }
    
    // MARK: - 2. Subheader Row (Account Pill on Left + Currency Flag Pill on Right)
    private var subHeaderRow: some View {
        HStack {
            if type != .transfer {
                accountPillButton(account: fromAccount, isDestination: false)
            }
            
            Spacer()
            
            // Currency Flag Pill (🇮🇳 ₹)
            currencyFlagPill
        }
    }
    
    private var currencyFlagPill: some View {
        HStack(spacing: 6) {
            Text("🇮🇳")
                .font(.system(size: 14))
            
            Text(store.currencySymbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .nativeLiquidGlassCapsule(isInteractive: false)
    }
    
    // Account Pill Button (Strict 44pt Height & iOS Liquid Glass Styling)
    private func accountPillButton(account: Account?, isDestination: Bool) -> some View {
        let accBalance = store.balance(for: account?.id ?? "")
        let initialLetter = String((account?.label.prefix(1) ?? "A")).uppercased()
        
        return Button(action: {
            activeSheet = .account(isDestination: isDestination)
            HapticsManager.shared.trigger(.selection)
        }) {
            HStack(spacing: 8) {
                // Vibrant Account Avatar Circle (32x32)
                ZStack {
                    Circle()
                        .fill(Color(hex: "#007AFF"))
                        .frame(width: 32, height: 32)
                    
                    Text(initialLetter)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.leading, 6)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(account?.label ?? "SBI")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("\(store.currencySymbol)\(String(format: "%.0f", accBalance))")
                        .font(.system(size: 11, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: "#8E8E93"))
                }
                .padding(.trailing, 16)
            }
            .frame(height: 44)
            .nativeLiquidGlassCapsule(isInteractive: true)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 3. Standard Amount Section (Expense & Income Mode)
    private var standardAmountSection: some View {
        VStack(spacing: 4) {
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(store.currencySymbol)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color(hex: "#505054"))
                
                Text(amountString)
                    .font(.system(size: 72, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(Color(hex: "#D0D0D4"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 4. Dual Transfer Cards Section (Transfer Mode - Compact to prevent screen expansion)
    private var transferCardsSection: some View {
        VStack(spacing: 8) {
            Spacer()
            
            // Top From Account Row
            HStack(spacing: 12) {
                accountPillButton(account: fromAccount, isDestination: false)
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(store.currencySymbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: "#505054"))
                    
                    Text(amountString)
                        .font(.system(size: 28, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "#141416"))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    }
            }
            
            // Down Arrow Divider Indicator
            ZStack {
                Circle()
                    .fill(Color(hex: "#202024"))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.8)
                    }
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "#8E8E93"))
            }
            .padding(.vertical, -4)
            
            // Bottom To Account Row
            HStack(spacing: 12) {
                accountPillButton(account: toAccount, isDestination: true)
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(store.currencySymbol)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: "#505054"))
                    
                    Text(amountString)
                        .font(.system(size: 28, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "#141416"))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 5. Full-Width Keypad & Actions Section
    private var keypadAndActionsSection: some View {
        VStack(spacing: 12) {
            // Action Buttons Row: [ 📅 Today ] on left, ( 🏷 ) on right
            SpendyGlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    // Date Selector Pill (44pt height & iOS Liquid Glass Styling)
                    Button(action: {
                        activeSheet = .calendar
                        HapticsManager.shared.trigger(.light)
                    }) {
                        HStack(spacing: 7) {
                            Image(systemName: "calendar")
                                .font(.system(size: 15, weight: .semibold))
                            
                            Text(formattedDateLabel)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .nativeLiquidGlassCapsule(isInteractive: true)
                        .glassMorphID("datePill", in: transactionNamespace)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Note / Tag Button (44x44 Circular Button)
                    GlassCircleButton(
                        icon: note.isEmpty ? "tag" : "tag.fill",
                        size: 44,
                        iconSize: 15,
                        foregroundColor: note.isEmpty ? .white : SpendyColors.primaryBlue,
                        haptic: .light,
                        accessibilityLabel: "Add Note",
                        morphID: "noteButton",
                        namespace: transactionNamespace
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isEditingNote = true
                        }
                    }
                }
            }
            
            // Full-Width 3-Column Calculator Grid (No math operators)
            tactileCalculatorGrid
            
            // Bottom Action Row: [ (🛒) Category ] + [ Save ]
            if type != .transfer {
                SpendyGlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        // Category Selector Pill (44pt height, iOS Liquid Glass, and perfect padding)
                        Button(action: {
                            activeSheet = .category
                            HapticsManager.shared.trigger(.selection)
                        }) {
                            HStack(spacing: 8) {
                                // Vibrant Category Circle Badge
                                SpendyIconBadge(
                                    sfSymbol: selectedCategory?.sfSymbol ?? "cart.fill",
                                    color: selectedCategory?.color ?? Color(hex: "#34C759"),
                                    size: .small,
                                    style: .circle
                                )
                                .padding(.leading, 6)
                                
                                Text(selectedCategory?.label ?? "Groceries")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .padding(.trailing, 16)
                            }
                            .frame(height: 44)
                            .nativeLiquidGlassCapsule(isInteractive: true)
                            .glassMorphID("categoryPill", in: transactionNamespace)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Save Button (44pt height)
                        Button(action: {
                            saveTransaction()
                        }) {
                            Text(isEditing ? "Save" : "Save")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(currentAmountValue > 0 ? Color.black : Color(hex: "#A0A0A4"))
                                .padding(.horizontal, 32)
                                .frame(height: 44)
                                .background {
                                    Capsule()
                                        .fill(currentAmountValue > 0 ? Color.white : Color(hex: "#444448"))
                                        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 3)
                                }
                                .glassMorphID("saveButton", in: transactionNamespace)
                        }
                        .buttonStyle(KeypadPressStyle())
                        .disabled(currentAmountValue <= 0)
                    }
                }
            } else {
                // Transfer Mode Full-Width Save Button
                Button(action: {
                    saveTransaction()
                }) {
                    Text(isEditing ? "Save Transfer" : "Save")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(currentAmountValue > 0 ? Color.black : Color(hex: "#A0A0A4"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background {
                            Capsule()
                                .fill(currentAmountValue > 0 ? Color.white : Color(hex: "#444448"))
                                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 3)
                        }
                }
                .buttonStyle(KeypadPressStyle())
                .disabled(currentAmountValue <= 0)
            }
        }
    }
    
    // MARK: - Tactile 3-Column Calculator Grid (No Math Operators)
    private var tactileCalculatorGrid: some View {
        let rows = [
            ["7", "8", "9"],
            ["4", "5", "6"],
            ["1", "2", "3"],
            [".", "0", "delete"]
        ]
        
        return VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        keypadCell(key: key)
                    }
                }
            }
        }
    }
    
    private func keypadCell(key: String) -> some View {
        return Button(action: {
            handleKeypress(key)
        }) {
            ZStack {
                if key == "delete" {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text(key)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#18181A"))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(KeypadPressStyle())
    }
    
    // MARK: - Keypad Handling Logic
    private func handleKeypress(_ key: String) {
        if key == "delete" {
            HapticsManager.shared.trigger(.light)
            if amountString.count > 1 {
                amountString.removeLast()
            } else {
                amountString = "0"
            }
            return
        }
        
        if key == "." {
            HapticsManager.shared.trigger(.selection)
            if !amountString.contains(".") {
                amountString += "."
            }
            return
        }
        
        // Digit (0-9)
        HapticsManager.shared.trigger(.light)
        if amountString == "0" {
            amountString = key
        } else {
            if let dotIndex = amountString.firstIndex(of: ".") {
                let decimals = amountString[dotIndex...].count - 1
                if decimals >= 2 { return }
            }
            if amountString.count < 10 {
                amountString += key
            }
        }
    }
    
    private func clearAll() {
        amountString = "0"
    }
    
    // MARK: - 6. Inline Note Editor (Matching Image 2 with iOS Liquid Glass styling)
    private var inlineNoteEditorView: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Add notes or tags starting with #", text: $note, axis: .vertical)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(4...6)
                        .focused($isNoteFocused)
                        .padding(16)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .nativeLiquidGlass(cornerRadius: 22, isInteractive: false)
                
                // Confirm Checkmark Button (White circle with black checkmark)
                Button(action: {
                    isNoteFocused = false
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isEditingNote = false
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.black.opacity(0.3), radius: 6, y: 2)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                }
                .padding(14)
            }
            .onAppear {
                isNoteFocused = true
            }
        }
    }
    
    // MARK: - Save Transaction Action
    private func saveTransaction() {
        guard currentAmountValue > 0 else { return }
        HapticsManager.shared.trigger(.success)
        
        let txTitle = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (selectedCategory?.label ?? type.title)
            : note.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existing = transactionToEdit {
            var updated = existing
            updated.amount = currentAmountValue
            updated.type = type
            updated.categoryId = selectedCategoryId
            updated.accountId = fromAccountId
            updated.toAccountId = type == .transfer ? toAccountId : nil
            updated.title = txTitle
            updated.notes = note.isEmpty ? nil : note
            updated.date = date
            store.updateTransaction(updated)
        } else {
            let newTx = Transaction(
                title: txTitle,
                amount: currentAmountValue,
                type: type,
                categoryId: selectedCategoryId,
                accountId: fromAccountId,
                toAccountId: type == .transfer ? toAccountId : nil,
                date: date,
                notes: note.isEmpty ? nil : note
            )
            store.addTransaction(newTx)
        }
        dismiss()
    }
}

// MARK: - Keypad Button Tactile Press Style
struct KeypadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Flow Layout Helper
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        height = currentY + lineHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Category Selection Drawer (Clean Custom Drawer & Full Liquid Glass Styling)
struct CategoryPickerDrawer: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategoryId: String
    var currentType: TransactionType
    var categories: [Category]
    
    @State private var searchText: String = ""
    
    private var groupedFolders: [(folder: String, categories: [Category])] {
        let filtered = searchText.isEmpty
            ? categories
            : categories.filter { $0.label.localizedCaseInsensitiveContains(searchText) }
        
        var groups: [String: [Category]] = [:]
        for cat in filtered {
            let f = cat.folder.isEmpty ? "Uncategorized" : cat.folder
            groups[f, default: []].append(cat)
        }
        
        let predefinedOrder = [
            "Everyday Spending",
            "Transport",
            "Living",
            "Personal & Wellness",
            "Salary & Career",
            "Investments & Other",
            "Uncategorized"
        ]
        
        return predefinedOrder.compactMap { folder in
            if let list = groups[folder], !list.isEmpty {
                return (folder: folder, categories: list.sorted(by: { $0.order < $1.order }))
            }
            return nil
        }
    }
    
    private var suggestedCategories: [Category] {
        if !searchText.isEmpty { return [] }
        return Array(categories.prefix(2))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#121214")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    GlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        iconSize: 14,
                        foregroundColor: .white,
                        haptic: .selection
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Select category")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // 1. Suggested Section
                        if !suggestedCategories.isEmpty {
                            categoryFolderBlock(
                                title: "Suggested",
                                items: suggestedCategories
                            )
                        }
                        
                        // 2. Folder Grouped Sections
                        ForEach(groupedFolders, id: \.folder) { group in
                            categoryFolderBlock(
                                title: group.folder,
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
        .presentationDragIndicator(.hidden)
        .presentationBackground(.ultraThinMaterial)
    }
    
    private func categoryFolderBlock(title: String, items: [Category]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#8E8E93"))
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
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
                                style: .circle
                            )
                            
                            Text(cat.label)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
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
                            .background(Color.white.opacity(0.08))
                            .padding(.leading, 68)
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(hex: "#18181A"))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    }
            }
        }
    }
    
    private var floatingSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(hex: "#8E8E93"))
            
            TextField("Search category", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
            
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

// MARK: - Account Selection Drawer (Dead Copy of Screenshot 1 with Liquid Glass Styling)
struct AccountPickerDrawer: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAccountId: String
    var title: String
    var accounts: [Account]
    
    var body: some View {
        ZStack {
            Color(hex: "#121214").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Clean Custom Header
                HStack {
                    GlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        iconSize: 14,
                        foregroundColor: .white,
                        haptic: .selection
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(spacing: 0) {
                            ForEach(accounts) { acc in
                                let isSelected = selectedAccountId == acc.id
                                let liveBalance = store.balance(for: acc.id)
                                Button(action: {
                                    selectedAccountId = acc.id
                                    HapticsManager.shared.trigger(.selection)
                                    dismiss()
                                }) {
                                    HStack(spacing: 14) {
                                        // Vibrant Account Badge
                                        SpendyIconBadge(
                                            sfSymbol: acc.sfSymbol.isEmpty ? acc.type.defaultSymbol : acc.sfSymbol,
                                            color: acc.color,
                                            size: .medium
                                        )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(acc.label)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.white)
                                            
                                            Text("\(store.currencySymbol)\(String(format: "%.0f", liveBalance))")
                                                .font(.system(size: 13, weight: .medium))
                                                .monospacedDigit()
                                                .foregroundStyle(Color(hex: "#8E8E93"))
                                        }
                                        
                                        Spacer()
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(.white)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if acc.id != accounts.last?.id {
                                    Divider()
                                        .background(Color.white.opacity(0.08))
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color(hex: "#18181A"))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .presentationDetents([.fraction(0.55), .medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.ultraThinMaterial)
    }
}

// MARK: - Custom Month Calendar Drawer (Dead Copy of Screenshot 4 - Clean Custom Header)
struct CustomCalendarDrawer: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @State private var displayedMonth: Date = Date()
    
    private let calendar = Calendar.current
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let _ = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        let numberOfDays = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#121214").ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Clean Custom Header
                HStack {
                    GlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        iconSize: 14,
                        foregroundColor: .white,
                        haptic: .selection
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text(calendar.isDateInToday(selectedDate) ? "Today" : formattedDateTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedDate = Date()
                        displayedMonth = Date()
                        HapticsManager.shared.trigger(.selection)
                        dismiss()
                    }) {
                        Text("Today")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background {
                                Capsule()
                                    .fill(Color(hex: "#18181A"))
                                    .overlay {
                                        Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                    }
                            }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Month Selector Header (< August 2026 >)
                HStack {
                    Button(action: {
                        // Month selector dropdown
                    }) {
                        HStack(spacing: 6) {
                            Text(monthYearString)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "#8E8E93"))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                                displayedMonth = prev
                            }
                            HapticsManager.shared.trigger(.light)
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                        }
                        
                        Button(action: {
                            if let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                                displayedMonth = next
                            }
                            HapticsManager.shared.trigger(.light)
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)
                
                // Weekday Column Headers
                HStack {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(hex: "#8E8E93"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 14)
                
                // Calendar Days Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 14) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, dayDate in
                        if let day = dayDate {
                            let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                            let dayNumber = calendar.component(.day, from: day)
                            
                            Button(action: {
                                selectedDate = day
                                HapticsManager.shared.trigger(.selection)
                                dismiss()
                            }) {
                                VStack(spacing: 2) {
                                    ZStack {
                                        if isSelected {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 38, height: 38)
                                        }
                                        
                                        Text("\(dayNumber)")
                                            .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                                            .foregroundStyle(isSelected ? Color.black : .white)
                                    }
                                    
                                    if isSelected {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            Color.clear
                                .frame(height: 38)
                        }
                    }
                }
                .padding(.horizontal, 14)
                
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.68)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.ultraThinMaterial)
    }
    
    private var formattedDateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: selectedDate)
    }
}
