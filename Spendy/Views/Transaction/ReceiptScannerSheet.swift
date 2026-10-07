//
//  ReceiptScannerSheet.swift
//  Spendy
//
//  Smart On-Device AI Receipt & Payment Screenshot Scanner Sheet
//  Features:
//  - 3 Input Methods: Document Camera (Auto edge detection), Photo Library, and Clipboard Detector
//  - Real-time OCR & semantic extraction (Merchant, Amount, Date, Category, Line Items)
//  - Liquid Glass scanner shimmer animation
//  - Interactive breakdown review card with inline category/account toggling
//

import SwiftUI
import PhotosUI
import VisionKit

struct ReceiptScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    
    var onApplyResult: ((ReceiptScanResult) -> Void)?
    var onSaveDirectly: ((ReceiptScanResult) -> Void)?
    
    // Scanner State
    @State private var isScanning: Bool = false
    @State private var scanResult: ReceiptScanResult? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showCameraScanner: Bool = false
    @State private var clipboardImage: UIImage? = nil
    
    // Editable review fields
    @State private var editedMerchantName: String = ""
    @State private var editedAmountString: String = "0.00"
    @State private var editedDate: Date = Date()
    @State private var selectedCategoryId: String = ""
    @State private var selectedAccountId: String = ""
    @State private var lineItems: [ReceiptLineItem] = []
    
    // Laser Animation Phase
    @State private var laserOffset: CGFloat = -120
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                SpendyColors.appBackground.ignoresSafeArea()
                
                if isScanning {
                    scanningLoadingView
                        .transition(.opacity)
                } else if let result = scanResult {
                    reviewResultView(result)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))
                } else {
                    scannerEntryPointView
                        .transition(.opacity)
                }
            }
            .navigationTitle("Receipt Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                }
                
                if scanResult != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                scanResult = nil
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(SpendyColors.textPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCameraScanner) {
                ReceiptCameraScannerView { images in
                    showCameraScanner = false
                    if let first = images.first {
                        processImage(first)
                    }
                } onCancel: {
                    showCameraScanner = false
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            processImage(uiImage)
                        }
                    }
                }
            }
            .onAppear {
                checkClipboardForImage()
            }
        }
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - 1. Entry Point: Choose Method (Camera / Photos / Clipboard)
    private var scannerEntryPointView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Hero Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(SpendyColors.primaryBlue.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "doc.text.viewfinder")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(SpendyColors.primaryBlue)
                    }
                    .padding(.top, 24)
                    
                    Text("Instant Smart Scanner")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Text("Scan paper receipts, digital bills, or payment confirmation screenshots. On-device AI extracts amount, merchant, and items instantly.")
                        .font(.system(size: 14.5, weight: .regular))
                        .foregroundStyle(SpendyColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Clipboard Detected Banner
                if let clip = clipboardImage {
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        processImage(clip)
                    }) {
                        HStack(spacing: 14) {
                            Image(uiImage: clip)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                                }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Text("Image on Clipboard")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                    
                                    Text("New")
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundStyle(Color.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(SpendyColors.primaryBlue, in: Capsule())
                                }
                                
                                Text("Tap to analyze screenshot or receipt")
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(SpendyColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(SpendyColors.primaryBlue)
                        }
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(SpendyColors.primaryBlue.opacity(0.1))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(SpendyColors.primaryBlue.opacity(0.3), lineWidth: 1.0)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
                
                // Primary Action Grid
                VStack(spacing: 12) {
                    // Option 1: Live Document Camera
                    Button(action: {
                        HapticsManager.shared.trigger(.selection)
                        showCameraScanner = true
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(SpendyColors.primaryBlue)
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Scan Physical Receipt")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Text("Auto-detects paper borders & removes shadows")
                                    .font(.system(size: 12.5, weight: .regular))
                                    .foregroundStyle(SpendyColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Option 2: Photos Library Picker
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.purple)
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "photo.stack.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Import from Photos")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(SpendyColors.textPrimary)
                                
                                Text("Apple Pay, Venmo, or banking screenshots")
                                    .font(.system(size: 12.5, weight: .regular))
                                    .foregroundStyle(SpendyColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SpendyColors.textTertiary)
                        }
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                
                // Privacy Guarantee Badge
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(SpendyColors.incomeGreen)
                    
                    Text("100% On-Device OCR · No receipt data leaves your phone")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .padding(.top, 12)
            }
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - 2. Scanning / Analyzing Loading View
    private var scanningLoadingView: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(SpendyColors.cardBackground)
                    .frame(width: 220, height: 280)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(SpendyColors.primaryBlue.opacity(0.4), lineWidth: 1.5)
                    }
                
                // Animated laser line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, SpendyColors.primaryBlue, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 3)
                    .shadow(color: SpendyColors.primaryBlue, radius: 8, y: 0)
                    .offset(y: laserOffset)
                
                VStack(spacing: 12) {
                    Image(systemName: "waveform.and.magnifyingglass")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(SpendyColors.primaryBlue)
                        .symbolEffect(.pulse, options: .repeating)
                    
                    Text("Analyzing...")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    laserOffset = 120
                }
            }
            
            Text("Extracting merchant, totals & line items...")
                .font(.system(size: 14.5, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
        }
    }
    
    // MARK: - 3. Review Parsed Results View
    private func reviewResultView(_ result: ReceiptScanResult) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                // Top Hero Card (Merchant + Total Amount)
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Text(result.receiptType.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.primaryBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SpendyColors.primaryBlue.opacity(0.12), in: Capsule())
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                            Text("\(Int(result.confidence * 100))% confidence")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(SpendyColors.incomeGreen)
                    }
                    
                    // Editable Merchant Name Field
                    TextField("Merchant Name", text: $editedMerchantName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                    
                    // Editable Amount Field
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(store.currencySymbol)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(SpendyColors.textTertiary)
                        
                        TextField("0.00", text: $editedAmountString)
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .keyboardType(.decimalPad)
                            .frame(minWidth: 120)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        }
                }
                .padding(.horizontal, 20)
                
                // Details Grid: Category & Account & Date
                VStack(spacing: 12) {
                    // Category Selection Row
                    HStack {
                        Text("Category")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(store.categories.filter { $0.type == .expense }) { cat in
                                Button(action: {
                                    selectedCategoryId = cat.id
                                    HapticsManager.shared.trigger(.selection)
                                }) {
                                    Label(cat.label, systemImage: cat.sfSymbol)
                                }
                            }
                        } label: {
                            if let cat = store.categories.first(where: { $0.id == selectedCategoryId }) {
                                HStack(spacing: 6) {
                                    SpendyIconBadge(
                                        sfSymbol: cat.sfSymbol,
                                        color: cat.color,
                                        size: .small,
                                        style: .circle,
                                        monogramName: cat.label
                                    )
                                    Text(cat.label)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(SpendyColors.textTertiary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
                            }
                        }
                    }
                    
                    Divider().overlay(SpendyColors.separator.opacity(0.5))
                    
                    // Account Selection Row
                    HStack {
                        Text("Account")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(store.accounts) { acc in
                                Button(action: {
                                    selectedAccountId = acc.id
                                    HapticsManager.shared.trigger(.selection)
                                }) {
                                    Label(acc.label, systemImage: acc.sfSymbol)
                                }
                            }
                        } label: {
                            if let acc = store.accounts.first(where: { $0.id == selectedAccountId }) {
                                HStack(spacing: 6) {
                                    Text(acc.label)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(SpendyColors.textPrimary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(SpendyColors.textTertiary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(SpendyColors.cardBackgroundSecondary, in: Capsule())
                            }
                        }
                    }
                    
                    Divider().overlay(SpendyColors.separator.opacity(0.5))
                    
                    // Date Picker Row
                    HStack {
                        Text("Date")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Spacer()
                        
                        DatePicker("", selection: $editedDate, displayedComponents: [.date])
                            .labelsHidden()
                    }
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(SpendyColors.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                        }
                }
                .padding(.horizontal, 20)
                
                // Line Items Breakdown (If Detected)
                if !lineItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detected Line Items (\(lineItems.count))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(lineItems.enumerated()), id: \.element.id) { index, item in
                                HStack {
                                    Button(action: {
                                        lineItems[index].isSelected.toggle()
                                        recalculateTotalFromSelectedItems()
                                    }) {
                                        Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 18))
                                            .foregroundStyle(item.isSelected ? SpendyColors.primaryBlue : SpendyColors.textTertiary)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text(item.name)
                                        .font(.system(size: 14.5, weight: .medium))
                                        .foregroundStyle(item.isSelected ? SpendyColors.textPrimary : SpendyColors.textTertiary)
                                    
                                    Spacer()
                                    
                                    Text("\(item.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 2))")
                                        .font(.system(size: 14.5, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(item.isSelected ? SpendyColors.textPrimary : SpendyColors.textTertiary)
                                }
                                .padding(.vertical, 10)
                                
                                if index < lineItems.count - 1 {
                                    Divider().overlay(SpendyColors.separator.opacity(0.4))
                                }
                            }
                        }
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(SpendyColors.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Apply to Add Transaction
                    Button(action: {
                        HapticsManager.shared.trigger(.success)
                        applyResultAndDismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.and.list.clipboard")
                                .font(.system(size: 16, weight: .bold))
                            Text("Fill in Transaction Editor")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    
                    // Direct Save Button
                    Button(action: {
                        HapticsManager.shared.trigger(.success)
                        saveDirectlyAndDismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Save Directly to Spendy")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(SpendyColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(SpendyColors.cardBackgroundSecondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - Actions & Processing
    private func processImage(_ image: UIImage) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isScanning = true
        }
        
        Task {
            let result = await ReceiptScannerEngine.shared.scanImage(
                image,
                categories: store.categories,
                accounts: store.accounts,
                defaultCurrencySymbol: store.currencySymbol
            )
            
            await MainActor.run {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.scanResult = result
                    self.editedMerchantName = result.merchantName
                    self.editedAmountString = result.totalAmount > 0 ? String(format: "%.2f", result.totalAmount) : "0.00"
                    self.editedDate = result.date
                    self.selectedCategoryId = result.suggestedCategoryId ?? store.categories.first?.id ?? ""
                    self.selectedAccountId = result.suggestedAccountId ?? store.accounts.first?.id ?? ""
                    self.lineItems = result.lineItems
                    self.isScanning = false
                }
            }
        }
    }
    
    private func checkClipboardForImage() {
        if UIPasteboard.general.hasImages, let img = UIPasteboard.general.image {
            self.clipboardImage = img
        }
    }
    
    private func recalculateTotalFromSelectedItems() {
        let selected = lineItems.filter { $0.isSelected }
        if !selected.isEmpty {
            let sum = selected.reduce(0) { $0 + $1.amount }
            editedAmountString = String(format: "%.2f", sum)
        }
    }
    
    private func applyResultAndDismiss() {
        var result = scanResult ?? ReceiptScanResult(
            merchantName: editedMerchantName,
            totalAmount: Double(editedAmountString) ?? 0,
            currencySymbol: store.currencySymbol,
            date: editedDate,
            suggestedCategoryId: selectedCategoryId,
            suggestedAccountId: selectedAccountId,
            confidence: 1.0,
            lineItems: lineItems,
            rawRecognizedText: "",
            receiptType: .physicalReceipt,
            originalImage: nil
        )
        result.merchantName = editedMerchantName
        result.totalAmount = Double(editedAmountString) ?? 0
        result.date = editedDate
        result.suggestedCategoryId = selectedCategoryId
        result.suggestedAccountId = selectedAccountId
        
        onApplyResult?(result)
        dismiss()
    }
    
    private func saveDirectlyAndDismiss() {
        let amount = Double(editedAmountString) ?? 0
        guard amount > 0 else { return }
        
        var notes = editedMerchantName
        if !lineItems.isEmpty {
            let itemLines = lineItems.filter { $0.isSelected }.map { "\($0.name) (\($0.amount.formattedCurrency(symbol: store.currencySymbol, decimals: 2)))" }.joined(separator: ", ")
            if !itemLines.isEmpty {
                notes += " · " + itemLines
            }
        }
        
        let tx = Transaction(
            title: editedMerchantName,
            amount: amount,
            type: .expense,
            categoryId: selectedCategoryId.isEmpty ? (store.categories.first?.id ?? "groceries") : selectedCategoryId,
            accountId: selectedAccountId.isEmpty ? (store.accounts.first?.id ?? "bank") : selectedAccountId,
            date: editedDate,
            notes: notes
        )
        store.addTransaction(tx)
        dismiss()
    }
}
