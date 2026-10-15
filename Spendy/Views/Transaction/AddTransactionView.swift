//
//  AddTransactionView.swift
//  Spendy
//
//  Pixel-Perfect iOS Liquid Glass Transaction Screen with Consistently-Padded Toggles,
//  Uniform 44pt Control Heights, Inline Note Editor with Confirm Checkmark, Dual Transfer Cards,
//  Clean 3-Column Numeric Keypad (No Math Operators), and Non-Duplicated Liquid Glass Sheets.
//

import PhotosUI
import SwiftUI

// MARK: - Active Sheet Enum for Single-Sheet Presentation
enum TransactionActiveSheet: Identifiable {
    case category
    case createCategory
    case account(isDestination: Bool)
    case calendar
    case receiptIntroduction
    case scanner([UIImage])
    
    var id: String {
        switch self {
        case .category: return "category"
        case .createCategory: return "createCategory"
        case .account(let isDest): return "account_\(isDest)"
        case .calendar: return "calendar"
        case .receiptIntroduction: return "receiptIntroduction"
        case .scanner: return "scanner"
        }
    }
}

private enum ReceiptImageError: Error {
    case invalidImage
}

struct AddTransactionView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(QuickActionManager.self) private var quickActionManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isMonoIconMode) private var isMonoMode
    
    var transactionToEdit: Transaction? = nil
    
    // Core Transaction State
    @State private var type: TransactionType = .expense
    @State private var amountString: String = "0"
    
    @State private var selectedCategoryId: String = "groceries"
    @State private var fromAccountId: String = "bank"
    @State private var toAccountId: String = "cash"
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var initialDate: Date
    
    // UI Mode State (Inline Note Editor)
    @State private var isEditingNote: Bool = false
    @FocusState private var isNoteFocused: Bool
    @Namespace private var transactionNamespace
    @AppStorage("addTransactionInputMode") private var inputMode: AmountInputMode = .keypad
    @AppStorage("addTransactionRulerStep") private var rulerStep: AmountRulerStep = .one
    
    // Single Active Sheet State
    @State private var activeSheet: TransactionActiveSheet? = nil
    @State private var pendingCategoryCreation = false
    @State private var showDiscardConfirmation: Bool = false
    @AppStorage("hasSeenReceiptScanIntroduction") private var hasSeenReceiptScanIntroduction = false
    @State private var openReceiptSourcesAfterIntroduction = false
    @State private var receiptMenuPresentationRequest = 0
    @State private var showReceiptCamera = false
    @State private var showReceiptPhotos = false
    @State private var openPhotosAfterCamera = false
    @State private var selectedReceiptPhoto: PhotosPickerItem?
    @State private var pendingReceiptPhoto: UIImage?
    @State private var receiptImages: [UIImage] = []
    @State private var receiptImportError: String?
    @State private var dismissAfterReceiptAdd = false
    
    private var isEditing: Bool {
        transactionToEdit != nil
    }
    
    private var currentAmountValue: Double {
        Double(amountString) ?? 0.0
    }
    
    private var hasUnsavedChanges: Bool {
        if let existing = transactionToEdit {
            return currentAmountValue != existing.amount ||
                   note != (existing.notes ?? "") ||
                   selectedCategoryId != existing.categoryId ||
                   fromAccountId != existing.accountId ||
                   (type == .transfer && toAccountId != existing.toAccountId) ||
                   date != existing.date ||
                   type != existing.type
        } else {
            return currentAmountValue > 0 || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || date != initialDate
        }
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
    private var sheetAccent: Color {
        if type == .income { return SpendyColors.incomeGreen }
        return selectedCategory?.color ?? SpendyColors.primaryBlue
    }
    
    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var amountCaption: String? {
        guard currentAmountValue > 0 else { return nil }
        let categoryName = (selectedCategory?.label ?? "").lowercased()
        if type == .income {
            return categoryName.isEmpty ? "received" : "to \(categoryName)"
        }
        return categoryName.isEmpty ? "spent" : "on \(categoryName)"
    }
    
    @ScaledMetric(relativeTo: .largeTitle) private var amountHeroSize: CGFloat = 72
    @ScaledMetric(relativeTo: .largeTitle) private var amountSymbolSize: CGFloat = 38
    @ScaledMetric(relativeTo: .largeTitle) private var transferAmountSize: CGFloat = 60
    
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
    
    init(
        transactionToEdit: Transaction? = nil,
        defaultType: TransactionType = .expense,
        defaultCategoryId: String? = nil,
        defaultAccountId: String? = nil,
        scannedReceipt: ReceiptScanResult? = nil
    ) {
        self.transactionToEdit = transactionToEdit
        let initialDate = transactionToEdit?.date ?? scannedReceipt?.date ?? Date()
        _initialDate = State(initialValue: initialDate)
        _date = State(initialValue: initialDate)
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
            if let catId = defaultCategoryId {
                _selectedCategoryId = State(initialValue: catId)
            }
            if let accId = defaultAccountId {
                _fromAccountId = State(initialValue: accId)
            }
            if let receipt = scannedReceipt {
                _type = State(initialValue: receipt.transactionType)
                if receipt.totalAmount > 0 {
                    _amountString = State(initialValue: String(format: "%.2f", receipt.totalAmount))
                }
                _note = State(initialValue: receipt.merchantName)
                if let categoryID = receipt.suggestedCategoryId {
                    _selectedCategoryId = State(initialValue: categoryID)
                }
                if let accountID = receipt.suggestedAccountId {
                    _fromAccountId = State(initialValue: accountID)
                }
            }
        }
    }
    
    var body: some View {
        return ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - 1. Top Header Bar (Close ✕ | Compact Type Switcher | More ...)
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, type == .transfer ? 10 : 16)

                
                // MARK: - 2. Subheader Row (Account Pill on Left) - Hidden in Transfer Mode
                if type != .transfer {
                    subHeaderRow
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96)),
                            removal: .opacity.combined(with: .scale(scale: 0.96))
                        ))
                }
                
                if isEditingNote {
                    inlineNoteEditorView
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    Spacer()
                } else {
                    // MARK: - 3. Amount Display
                    if type == .transfer {
                        transferCardsSection
                            .padding(.bottom, 4)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                removal: .opacity.combined(with: .scale(scale: 0.98))
                            ))
                    } else {
                        standardAmountSection
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                removal: .opacity.combined(with: .scale(scale: 0.98))
                            ))
                    }
                    
                    // MARK: - 5. Bottom Keypad & Actions (dock card)
                    keypadAndActionsSection
                        .padding(.horizontal, 12)
                        .padding(.bottom, type == .transfer ? 8 : 14)
                        .ignoresSafeArea(.container, edges: .bottom)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: type)
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
        .alert("Discard Changes?", isPresented: $showDiscardConfirmation) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .sheet(item: $activeSheet, onDismiss: {
            if openReceiptSourcesAfterIntroduction {
                openReceiptSourcesAfterIntroduction = false
                receiptMenuPresentationRequest += 1
            }
            if pendingCategoryCreation {
                pendingCategoryCreation = false
                activeSheet = .createCategory
            }
            if dismissAfterReceiptAdd {
                dismissAfterReceiptAdd = false
                dismiss()
            }
        }) { sheet in
            switch sheet {
            case .category:
                CategoryPickerDrawer(
                    selectedCategoryId: $selectedCategoryId,
                    currentType: type,
                    categories: availableCategories,
                    onCreateCategory: {
                        pendingCategoryCreation = true
                        activeSheet = nil
                    }
                )
            case .createCategory:
                AddCategorySheet(defaultType: type, onCreated: { category in
                    type = category.type
                    selectedCategoryId = category.id
                })
            case .account(let isDestination):
                AccountPickerDrawer(
                    selectedAccountId: accountSelectionBinding(isDestination: isDestination),
                    title: isDestination ? "Select destination account" : "Select account",
                    accounts: store.accounts
                )
            case .calendar:
                CustomCalendarDrawer(selectedDate: $date)
            case .receiptIntroduction:
                ReceiptScanIntroductionSheet {
                    hasSeenReceiptScanIntroduction = true
                    openReceiptSourcesAfterIntroduction = true
                    activeSheet = nil
                }
            case .scanner(let images):
                ReceiptScannerSheet(
                    images: images,
                    initialAccountId: fromAccountId,
                    initialCategoryId: selectedCategoryId,
                    onEditResult: { result in applyScanResult(result) },
                    onAddResult: { result in addScannedTransaction(result) }
                )
            }
        }
        .sheet(isPresented: $showReceiptCamera, onDismiss: {
            if openPhotosAfterCamera {
                openPhotosAfterCamera = false
                showReceiptPhotos = true
            } else {
                presentCapturedReceipt()
            }
        }) {
            ReceiptCameraCaptureView { image in
                receiptImages = [image]
                showReceiptCamera = false
            } onCancel: {
                showReceiptCamera = false
            } onChoosePhoto: {
                openPhotosAfterCamera = true
                showReceiptCamera = false
            }
            .presentationDetents([.fraction(0.72)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
            .preferredColorScheme(.dark)
        }
        .photosPicker(
            isPresented: $showReceiptPhotos,
            selection: $selectedReceiptPhoto,
            matching: .images,
            preferredItemEncoding: .compatible
        )
        .onChange(of: showReceiptPhotos) { _, isPresented in
            if !isPresented, let image = pendingReceiptPhoto {
                pendingReceiptPhoto = nil
                activeSheet = .scanner([image])
            }
        }
        .onChange(of: selectedReceiptPhoto) { _, item in
            guard let item else { return }
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        throw ReceiptImageError.invalidImage
                    }
                    selectedReceiptPhoto = nil
                    receiptImages = [image]
                    if showReceiptPhotos {
                        pendingReceiptPhoto = image
                    } else {
                        activeSheet = .scanner([image])
                    }
                } catch {
                    selectedReceiptPhoto = nil
                    receiptImportError = "That photo could not be opened. Choose another receipt or screenshot."
                }
            }
        }
        .alert("Receipt image", isPresented: Binding(
            get: { receiptImportError != nil },
            set: { if !$0 { receiptImportError = nil } }
        )) {
            Button("OK", role: .cancel) { receiptImportError = nil }
        } message: {
            Text(receiptImportError ?? "")
        }
        .onAppear {
            if !store.accounts.contains(where: { $0.id == fromAccountId }) {
                fromAccountId = store.accounts.first?.id ?? fromAccountId
            }
            if !store.accounts.contains(where: { $0.id == toAccountId }) {
                toAccountId = store.accounts.first(where: { $0.id != fromAccountId })?.id ?? toAccountId
            }
            if !store.categories.contains(where: { $0.id == selectedCategoryId }) {
                selectedCategoryId = availableCategories.first?.id ?? selectedCategoryId
            }
            if store.accounts.count < 2 && type == .transfer {
                type = .expense
            }
            if store.accounts.count >= 2 && fromAccountId == toAccountId {
                if let other = store.accounts.first(where: { $0.id != fromAccountId }) {
                    toAccountId = other.id
                }
            }
            openRequestedReceiptCamera()
        }
        .onChange(of: quickActionManager.shouldPresentReceiptScan) { _, requested in
            if requested { openRequestedReceiptCamera() }
        }
    }

    private func openRequestedReceiptCamera() {
        guard quickActionManager.shouldPresentReceiptScan else { return }
        quickActionManager.shouldPresentReceiptScan = false
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            showReceiptCamera = true
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
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close",
                morphID: "closeButton",
                namespace: transactionNamespace
            ) {
                if hasUnsavedChanges {
                    showDiscardConfirmation = true
                } else {
                    dismiss()
                }
            }
            
            Spacer()
            
            SpendyTransactionTypeToggle(
                selection: $type,
                availableTypes: availableTypes
            ) { newType in
                if let first = store.categories.filter({ $0.type == newType }).first {
                    selectedCategoryId = first.id
                }
            }
            
            Spacer()
            
            // Standard 44x44 More Options Menu ...
            Menu {
                Button {
                    HapticsManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        inputMode = inputMode == .keypad ? .slider : .keypad
                    }
                } label: {
                    Label(
                        inputMode == .keypad ? "Use Slider" : "Use Keypad",
                        systemImage: inputMode == .keypad ? SFIcons.amountRuler : SFIcons.amountKeypad
                    )
                }
                
                Divider()
                
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
            } label: {
                GlassCircleIcon(
                    size: 44,
                    morphID: "moreButton",
                    namespace: transactionNamespace
                ) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
        }
    }
    
    private var availableTypes: [TransactionType] {
        store.accounts.count >= 2 ? [.expense, .income, .transfer] : [.expense, .income]
    }

    private func accountSelectionBinding(isDestination: Bool) -> Binding<String> {
        Binding(
            get: { isDestination ? toAccountId : fromAccountId },
            set: { selectedId in
                guard type == .transfer else {
                    fromAccountId = selectedId
                    return
                }
                if isDestination {
                    if selectedId == fromAccountId { fromAccountId = toAccountId }
                    toAccountId = selectedId
                } else {
                    if selectedId == toAccountId { toAccountId = fromAccountId }
                    fromAccountId = selectedId
                }
            }
        )
    }
    
    // MARK: - 2. Subheader Row (Account Pill on Left)
    private var subHeaderRow: some View {
        HStack {
            if type != .transfer {
                accountPillButton(account: fromAccount, isDestination: false)
            }
            Spacer()
        }
    }
    
    // Account Pill Button (Strict 44pt Height & iOS Liquid Glass Styling)
    @ViewBuilder
    private func accountPillButton(account: Account?, isDestination: Bool) -> some View {
        let accBalance = store.balance(for: account?.id ?? "")
        let initialLetter = String((account?.label.prefix(1) ?? "A")).uppercased()
        let paint = SpendyIconPaint.resolve(
            account?.color ?? SpendyColors.cardBackgroundSecondary,
            scheme: colorScheme,
            mono: isMonoMode,
            prominent: false
        )
        
        let button = Button(action: {
            activeSheet = .account(isDestination: isDestination)
            HapticsManager.shared.trigger(.selection)
        }) {
            HStack(spacing: 8) {
                // Account letter badge — same solid paint as every other entity icon
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(account == nil ? SpendyColors.cardBackgroundSecondary : paint.fill)
                        .frame(width: 32, height: 32)
                        .shadow(
                            color: account == nil ? .clear : paint.fill.opacity(0.35),
                            radius: 3,
                            y: 0
                        )
                    
                    Text(initialLetter)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(account != nil ? paint.glyph : SpendyColors.textPrimary)
                }
                .padding(.leading, 6)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(account?.label ?? "SBI")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text(accBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 11, weight: .medium, tracking: -0.3)
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .padding(.trailing, 16)
            }
            .frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SpendyColors.transactionControlSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
        
        if isDestination {
            button
        } else {
            button.glassMorphID("sourceAccountPill", in: transactionNamespace)
        }
    }
    
    // MARK: - 3. Standard Amount Section (Expense & Income Mode with Numeric Text Transitions)
    private var standardAmountSection: some View {
        VStack(spacing: 10) {
            Spacer()

            Text("AMOUNT")
                .font(AppTypography.eyebrow)
                .tracking(1.4)
                .foregroundStyle(SpendyColors.textTertiary)
                .accessibilityHidden(true)
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(store.currencySymbol)
                    .font(.system(size: amountSymbolSize, weight: .bold, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .fixedSize()
                
                Text(amountString)
                    .spendyNumberFont(size: amountHeroSize, weight: .heavy, tracking: -1.2)
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .layoutPriority(1)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.28, dampingFraction: 0.72), value: amountString)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Amount, \(store.currencySymbol)\(amountString)")
            
            if let amountCaption {
                Text(amountCaption)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .textCase(.lowercase)
            }
            
            if !trimmedNote.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isEditingNote = true
                    }
                    HapticsManager.shared.trigger(.light)
                } label: {
                    Text(trimmedNote)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Note, \(trimmedNote)")
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - 4. Transfer Amount and Account Selection
    private var transferCardsSection: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 4)

            VStack(spacing: 2) {
                Text("Transfer amount")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(store.currencySymbol)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(SpendyColors.textSecondary)

                    Text(amountString)
                        .font(.system(size: transferAmountSize, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: amountString)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Transfer amount, \(store.currencySymbol)\(amountString)")

            Spacer(minLength: 4)

            ZStack(alignment: .trailing) {
                VStack(spacing: 8) {
                    transferAccountCard(account: fromAccount, isDestination: false)
                    transferAccountCard(account: toAccount, isDestination: true)
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        swap(&fromAccountId, &toAccountId)
                    }
                    HapticsManager.shared.trigger(.selection)
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(SpendyColors.transactionControlSurface)
                                .overlay {
                                    Circle().stroke(SpendyColors.separator, lineWidth: 1)
                                }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Swap accounts")
                .padding(.trailing, 20)
                .zIndex(1)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func transferAccountCard(
        account: Account?,
        isDestination: Bool
    ) -> some View {
        let paint = SpendyIconPaint.resolve(
            account?.color ?? SpendyColors.cardBackgroundSecondary,
            scheme: colorScheme,
            mono: isMonoMode,
            prominent: false
        )

        return Button {
            activeSheet = .account(isDestination: isDestination)
            HapticsManager.shared.trigger(.selection)
        } label: {
            HStack(spacing: 12) {
                Text(String((account?.label.prefix(1) ?? "A")).uppercased())
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(paint.glyph)
                    .frame(width: 44, height: 44)
                    .background(paint.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(isDestination ? "To" : "From")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textSecondary)

                    Text(account?.label ?? "Choose account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .lineLimit(1)

                    Text(store.balance(for: account?.id ?? "").formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                        .spendyNumberFont(size: 12, weight: .medium)
                        .foregroundStyle(SpendyColors.textTertiary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpendyColors.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(SpendyColors.transactionControlSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose \(isDestination ? "destination" : "source") account, \(account?.label ?? "none selected")")
        .accessibilityHint("Opens account picker")
    }
    
    // MARK: - 5. Full-Width Keypad & Actions Section
    private var keypadAndActionsSection: some View {
        VStack(spacing: 10) {
            // Keep frequent details visible; the alternate input mode lives in More.
            HStack(spacing: 10) {
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
                    .foregroundStyle(SpendyColors.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(SpendyColors.transactionKeySurface)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(SpendyColors.separator, lineWidth: 0.8)
                            }
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                ReceiptSourceMenuButton(
                    needsIntroduction: !hasSeenReceiptScanIntroduction,
                    presentationRequest: receiptMenuPresentationRequest,
                    onIntroduction: { activeSheet = .receiptIntroduction },
                    onSelect: selectReceiptSource
                )
                .frame(width: 44, height: 44)

                // Note Button
                Button {
                    HapticsManager.shared.trigger(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        isEditingNote = true
                    }
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(SpendyColors.transactionKeySurface)
                                .overlay {
                                    Circle()
                                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                                }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(note.isEmpty ? "Add Note" : "Edit Note")
            }
            
            SpendyGlassEffectContainer(spacing: 12) {
                if inputMode == .keypad {
                    SpendyKeypad(
                        amountString: $amountString,
                        maxDigits: 8,
                        useLiquidGlass: false
                    )
                    .glassMorphID("amountEntrySurface", in: transactionNamespace)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .bottom))
                    ))
                } else {
                    SpendyAmountRuler(
                        amountString: $amountString,
                        step: $rulerStep,
                        maxDigits: 8
                    )
                    .glassMorphID("amountEntrySurface", in: transactionNamespace)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .bottom))
                    ))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: inputMode)
            
            // Bottom Action Row: [ (🛒) Category ] + [ Save ]
            if type != .transfer {
                HStack(spacing: 12) {
                    Button(action: {
                        activeSheet = .category
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        HStack(spacing: 8) {
                            SpendyIconBadge(
                                sfSymbol: selectedCategory?.sfSymbol ?? "cart.fill",
                                color: selectedCategory?.color ?? Color(hex: "#34C759"),
                                size: .small,
                                style: .circle,
                                monogramName: selectedCategory?.label ?? ""
                            )
                            .padding(.leading, 6)
                            
                            Text(selectedCategory?.label ?? "Groceries")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                                .lineLimit(1)
                                .padding(.trailing, 16)
                        }
                        .frame(height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SpendyColors.transactionKeySurface)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(SpendyColors.separator, lineWidth: 0.8)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        saveTransaction()
                    }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(currentAmountValue > 0 ? SpendyColors.elevatedControlForeground : SpendyColors.textTertiary)
                            .padding(.horizontal, 32)
                            .frame(height: 44)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(currentAmountValue > 0 ? SpendyColors.elevatedControlFill : SpendyColors.transactionKeySurface)
                            }
                    }
                    .buttonStyle(KeypadPressStyle())
                    .disabled(currentAmountValue <= 0)
                    .accessibilityLabel("Save")
                }
                .padding(.top, 8)
            } else {
                // Transfer Mode: iOS "Slide to Transfer" Liquid Glass Slider
                SpendySlideToTransfer(
                    title: "slide to transfer",
                    sourceAccountName: fromAccount?.label ?? "Source",
                    destinationAccountName: toAccount?.label ?? "Destination",
                    isEnabled: currentAmountValue > 0 && fromAccountId != toAccountId,
                    disabledMessage: currentAmountValue <= 0
                        ? "enter amount to transfer"
                        : "choose a different account"
                ) {
                    saveTransaction()
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, type == .transfer ? 14 : 22)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(SpendyColors.transactionTraySurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            SpendyColors.separator,
                            lineWidth: 0.8
                        )
                }
        }
    }
    
    // MARK: - 6. Inline Note Editor (Matching Image 2 with iOS Liquid Glass styling)
    private var inlineNoteEditorView: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Add notes or tags starting with #", text: $note, axis: .vertical)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(SpendyColors.textPrimary)
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
                            .fill(SpendyColors.incomeGreen)
                            .frame(width: 40, height: 40)
                            .shadow(color: SpendyColors.incomeGreen.opacity(0.35), radius: 6, y: 2)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(SpendyColors.elevatedControlForeground)
                    }
                }
                .padding(14)
            }
            .onAppear {
                isNoteFocused = true
            }
        }
    }
    
    private func selectReceiptSource(_ source: ReceiptSourceMenuButton.Source) {
        switch source {
        case .paste:
            guard let image = copiedReceiptImage else {
                receiptImportError = "Copy a receipt image first, then choose Paste image again."
                return
            }
            receiptImages = [image]
            activeSheet = .scanner([image])
        case .photos:
            showReceiptPhotos = true
        case .camera:
            receiptImages = []
            showReceiptCamera = true
        }
    }

    private var copiedReceiptImage: UIImage? { ReceiptImageClipboard.image }

    // MARK: - Apply Scanned Receipt Result
    private func presentCapturedReceipt() {
        guard !receiptImages.isEmpty else { return }
        activeSheet = .scanner(receiptImages)
    }

    private func applyScanResult(_ result: ReceiptScanResult) {
        if result.totalAmount > 0 {
            amountString = String(format: result.totalAmount.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", result.totalAmount)
        }
        if !result.merchantName.isEmpty {
            note = result.merchantName
        }
        date = result.date
        type = result.transactionType
        if let catId = result.suggestedCategoryId, store.categories.contains(where: { $0.id == catId && $0.type == type }) {
            selectedCategoryId = catId
        } else if !store.categories.contains(where: { $0.id == selectedCategoryId && $0.type == type }) {
            selectedCategoryId = availableCategories.first?.id ?? selectedCategoryId
        }
        if let accId = result.suggestedAccountId, store.accounts.contains(where: { $0.id == accId }) {
            fromAccountId = accId
        }
    }

    private func addScannedTransaction(_ result: ReceiptScanResult) {
        let merchant = result.merchantName.trimmingCharacters(in: .whitespacesAndNewlines)
        let categoryId = result.suggestedCategoryId ?? selectedCategoryId
        let accountId = result.suggestedAccountId ?? fromAccountId
        guard result.totalAmount > 0, !merchant.isEmpty, result.hasDetectedDate,
              result.paymentStatus != .pending, result.paymentStatus != .failed,
              result.currencySymbol == store.currencySymbol,
              store.categories.contains(where: { $0.id == categoryId && $0.type == result.transactionType }),
              store.accounts.contains(where: { $0.id == accountId }) else { return }

        HapticsManager.shared.trigger(.success)
        store.addTransaction(Transaction(
            title: merchant,
            amount: result.totalAmount,
            type: result.transactionType,
            categoryId: categoryId,
            accountId: accountId,
            date: result.date
        ))
        dismissAfterReceiptAdd = true
    }
    
    // MARK: - Save Transaction Action
    private func saveTransaction() {
        guard currentAmountValue > 0 else { return }
        if type == .transfer, fromAccountId == toAccountId { return }
        HapticsManager.shared.trigger(.success)
        
        let txTitle = note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (selectedCategory?.label ?? type.title)
            : note.trimmingCharacters(in: .whitespacesAndNewlines)
            
        let toAmt = type == .transfer ? currentAmountValue : nil
        
        if let existing = transactionToEdit {
            var updated = existing
            updated.amount = currentAmountValue
            updated.toAmount = toAmt
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
                toAmount: toAmt,
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
    
    private func clearAll() {
        amountString = "0"
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
    var onCreateCategory: (() -> Void)? = nil
    
    @State private var searchText: String = ""
    
    private var groupedFolders: [CategoryDirectorySection] {
        CategoryDirectory.folderSections(categories, query: searchText)
    }

    private var suggestedCategories: [Category] {
        if !searchText.isEmpty { return [] }
        return Array(categories.prefix(2))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyPinnedHeaderLayout {

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

// MARK: - Account Selection Drawer (Pure Native Liquid Glass Styling)
struct AccountPickerDrawer: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAccountId: String
    var title: String
    var accounts: [Account]
    
    var body: some View {
        ZStack {
            SpendyPinnedHeaderLayout {

                // Clean Custom Header
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
                    
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)
            } content: {
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
                                            size: .medium,
                                            monogramName: acc.label
                                        )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(acc.label)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(SpendyColors.textPrimary)
                                            
                                            Text(liveBalance.formattedCurrency(symbol: store.currencySymbol, decimals: 0))
                                                .font(.system(size: 13, weight: .medium))
                                                .monospacedDigit()
                                                .foregroundStyle(SpendyColors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(SpendyColors.textPrimary)
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
                                        .background(SpendyColors.separator)
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(SpendyColors.cardBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .presentationDetents([.fraction(0.55), .medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Custom Month Calendar Drawer (Pure Native Liquid Glass Styling)
struct CustomCalendarDrawer: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    @State private var displayedMonth: Date = Date()
    @State private var isPickingMonthYear: Bool = false
    
    private let calendar = Calendar.current
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    private let monthSymbols = Calendar.current.shortMonthSymbols
    
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
            VStack(spacing: 20) {
                // Clean Custom Header
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
                    
                    Spacer()
                    
                    Text(calendar.isDateInToday(selectedDate) ? "Today" : formattedDateTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        selectedDate = Date()
                        displayedMonth = Date()
                        HapticsManager.shared.trigger(.selection)
                        dismiss()
                    }) {
                        Text("Today")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .nativeLiquidGlassCapsule(isInteractive: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isPickingMonthYear.toggle()
                        }
                        HapticsManager.shared.trigger(.selection)
                    } label: {
                        HStack(spacing: 6) {
                            Text(isPickingMonthYear ? displayedYearTitle : monthYearString)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                            
                            Image(systemName: isPickingMonthYear ? "chevron.down" : "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPickingMonthYear ? "Choose year and month" : "Choose month")
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button {
                            shiftDisplayed(by: isPickingMonthYear ? -1 : -1, unit: isPickingMonthYear ? .year : .month)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            shiftDisplayed(by: 1, unit: isPickingMonthYear ? .year : .month)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(SpendyColors.textPrimary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)
                
                if isPickingMonthYear {
                    monthYearPicker
                } else {
                    weekdayHeader
                    daysGrid
                }
                
                Spacer()
            }
        }
        .presentationDetents([.fraction(0.68)])
        .presentationDragIndicator(.visible)
        .onAppear {
            displayedMonth = selectedDate
        }
    }
    
    private var formattedDateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: selectedDate)
    }
    
    private var displayedYearTitle: String {
        String(calendar.component(.year, from: displayedMonth))
    }
    
    private var displayedYear: Int {
        calendar.component(.year, from: displayedMonth)
    }
    
    private var displayedMonthIndex: Int {
        calendar.component(.month, from: displayedMonth)
    }
    
    private func shiftDisplayed(by value: Int, unit: Calendar.Component) {
        if let next = calendar.date(byAdding: unit, value: value, to: displayedMonth) {
            displayedMonth = next
        }
        HapticsManager.shared.trigger(.light)
    }
    
    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(SpendyColors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 14)
    }
    
    private var daysGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, dayDate in
                if let day = dayDate {
                    let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                    let dayNumber = calendar.component(.day, from: day)
                    
                    Button {
                        selectedDate = day
                        HapticsManager.shared.trigger(.selection)
                        dismiss()
                    } label: {
                        VStack(spacing: 2) {
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(SpendyColors.elevatedControlFill)
                                        .frame(width: 38, height: 38)
                                }
                                
                                Text("\(dayNumber)")
                                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textPrimary)
                            }
                            .frame(width: 44, height: 44)
                            
                            if isSelected {
                                Circle()
                                    .fill(SpendyColors.elevatedControlFill)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 14)
    }
    
    private var monthYearPicker: some View {
        VStack(spacing: 18) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(1...12, id: \.self) { month in
                    let isSelected = month == displayedMonthIndex
                    Button {
                        selectMonth(month)
                    } label: {
                        Text(monthSymbols[month - 1])
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background {
                                if isSelected {
                                    Capsule(style: .continuous)
                                        .fill(SpendyColors.elevatedControlFill)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(monthSymbols[month - 1])
                }
            }
            .padding(.horizontal, 18)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(yearRange, id: \.self) { year in
                            let isSelected = year == displayedYear
                            Button {
                                selectYear(year)
                            } label: {
                                Text(String(year))
                                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? SpendyColors.elevatedControlForeground : SpendyColors.textPrimary)
                                    .padding(.horizontal, 16)
                                    .frame(height: 40)
                                    .background {
                                        Capsule(style: .continuous)
                                            .fill(isSelected ? SpendyColors.elevatedControlFill : SpendyColors.cardBackgroundSecondary)
                                    }
                            }
                            .buttonStyle(.plain)
                            .id(year)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .onAppear {
                    proxy.scrollTo(displayedYear, anchor: .center)
                }
                .onChange(of: displayedYear) { _, year in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(year, anchor: .center)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var yearRange: [Int] {
        let current = calendar.component(.year, from: Date())
        return Array((current - 15)...(current + 2))
    }
    
    private func selectMonth(_ month: Int) {
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.month = month
        if let next = calendar.date(from: components) {
            displayedMonth = next
        }
        HapticsManager.shared.trigger(.selection)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isPickingMonthYear = false
        }
    }
    
    private func selectYear(_ year: Int) {
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.year = year
        if let next = calendar.date(from: components) {
            displayedMonth = next
        }
        HapticsManager.shared.trigger(.selection)
    }
}

// MARK: - iOS-Native "Slide to Transfer" Slider Control (Pure Apple Liquid Glass)
struct SpendySlideToTransfer: View {
    var title: String = "slide to transfer"
    var sourceAccountName: String? = nil
    var destinationAccountName: String? = nil
    var isEnabled: Bool = true
    var disabledMessage: String = "enter amount to transfer"
    var onConfirm: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isCompleted: Bool = false
    @State private var shimmerPhase: CGFloat = -0.5
    
    private let trackHeight: CGFloat = 68
    private let knobSize: CGFloat = 56
    private let knobPadding: CGFloat = 6
    
    private var displayText: String {
        if !isEnabled {
            return disabledMessage
        }
        if let dst = destinationAccountName {
            return "slide to transfer to \(dst)"
        }
        return title
    }
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let maxDrag = max(0, totalWidth - knobSize - (knobPadding * 2))
            let progress = maxDrag > 0 ? (dragOffset / maxDrag) : 0
            
            ZStack(alignment: .leading) {
                // 1. Authentic Frosted Liquid Glass Track
                Capsule()
                    .fill(SpendyColors.transactionTraySurface)
                    .overlay {
                        Capsule()
                            .stroke(SpendyColors.separator, lineWidth: 1.0)
                    }
                    .nativeLiquidGlassCapsule(isInteractive: false)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, y: 3)
                
                // 2. Shimmering "slide to transfer to [Destination]" Text
                HStack {
                    Spacer()
                    
                    Text(displayText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                stops: [
                                    .init(color: SpendyColors.textSecondary, location: max(0, shimmerPhase - 0.3)),
                                    .init(color: SpendyColors.textPrimary, location: shimmerPhase),
                                    .init(color: SpendyColors.textSecondary, location: min(1, shimmerPhase + 0.3))
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(isEnabled ? max(0, 1.0 - (progress * 1.8)) : 0.4)
                        .offset(x: 14) // Balanced text position
                    
                    Spacer()
                }
                
                // 3. Circular Liquid Glass Knob
                ZStack {
                    Circle()
                        .fill(SpendyColors.elevatedControlFill)
                        .overlay {
                            Circle()
                                .stroke(SpendyColors.separator, lineWidth: 1.2)
                        }
                        .nativeLiquidGlassCircle(isInteractive: true, tint: isEnabled ? Color.white.opacity(0.16) : nil)
                        .shadow(color: Color.black.opacity(0.4), radius: 6, y: 2)
                    
                    // Knob Icon
                    Image(systemName: isCompleted ? "checkmark" : "arrow.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isEnabled ? SpendyColors.elevatedControlForeground : SpendyColors.textTertiary)
                        .rotationEffect(.degrees(isCompleted ? 0 : (progress * 45)))
                }
                .frame(width: knobSize, height: knobSize)
                .padding(.leading, knobPadding)
                .offset(x: dragOffset)
                .gesture(
                    isEnabled ?
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.width
                            dragOffset = min(max(0, translation), maxDrag)
                        }
                        .onEnded { value in
                            if progress >= 0.82 {
                                // Successful Slide Confirmation!
                                HapticsManager.shared.trigger(.success)
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    dragOffset = maxDrag
                                    isCompleted = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                    onConfirm()
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        dragOffset = 0
                                        isCompleted = false
                                    }
                                }
                            } else {
                                // Snap back with spring physics
                                HapticsManager.shared.trigger(.selection)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                                    dragOffset = 0
                                }
                            }
                        }
                    : nil
                )
            }
            .frame(height: trackHeight)
            .onAppear {
                withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1.5
                }
            }
        }
        .frame(height: trackHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isEnabled ? "Transfer to \(destinationAccountName ?? "destination account")" : disabledMessage)
        .accessibilityHint(isEnabled ? "Double tap to confirm the transfer" : disabledMessage)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            guard isEnabled, !isCompleted else { return }
            HapticsManager.shared.trigger(.success)
            onConfirm()
        }
    }
}
