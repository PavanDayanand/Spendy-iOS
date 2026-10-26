//
//  MainTabView.swift
//  Spendy
//
//  Root Navigation Shell hosting Home, Subscriptions, and Floating Bottom Dock
//

import SwiftUI

struct MainTabView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedTab: AppTab = .home
    @State private var showAddTransaction: Bool = false
    @State private var isHomeDrawerExpanded: Bool = false
    @State private var isHomeSubpageActive: Bool = false
    @State private var isAnalyticsSubpageActive: Bool = false
    @State private var analyticsNavigationHeader = AnalyticsNavigationHeaderState()
    @State private var quickActionManager = QuickActionManager.shared

    @AppStorage("hasSeenReceiptScanIntroduction") private var hasSeenReceiptIntroduction = false
    @State private var receiptSheet: HomeReceiptSheet?
    @State private var pendingReceiptSheet: HomeReceiptSheet?
    @State private var openReceiptMenuOnDismiss = false
    @State private var receiptMenuRequest = 0
    @State private var showReceiptPhotos = false
    @State private var receiptPhotosArePresented = false
    @State private var openReceiptPhotosOnDismiss = false
    @State private var pendingReceiptPhoto: UIImage?
    @State private var receiptImportError: String?
    @State private var receiptToEdit: ReceiptScanResult?
    @State private var pendingReceiptEdit: ReceiptScanResult?

    private var isDockVisible: Bool {
        switch selectedTab {
        case .home:
            return !isHomeSubpageActive
        case .analytics:
            return !isAnalyticsSubpageActive
        case .subscriptions, .quickAdd:
            return true
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Screen Content
            ZStack {
                DashboardView(
                    showAddTransaction: $showAddTransaction,
                    selectedTab: $selectedTab,
                    isSheetExpandedBinding: $isHomeDrawerExpanded,
                    isSubpageActiveBinding: $isHomeSubpageActive
                )
                .environment(\.spendyTipsAllowed, selectedTab == .home && !showAddTransaction && receiptSheet == nil && !showReceiptPhotos)
                .opacity(selectedTab == .home ? 1 : 0)
                .allowsHitTesting(selectedTab == .home)
                .accessibilityHidden(selectedTab != .home)

                NavigationStack {
                    SubscriptionsView()
                }
                .environment(\.spendyTipsAllowed, selectedTab == .subscriptions && !showAddTransaction)
                .opacity(selectedTab == .subscriptions ? 1 : 0)
                .allowsHitTesting(selectedTab == .subscriptions)
                .accessibilityHidden(selectedTab != .subscriptions)

                NavigationStack {
                    AnalyticsView(
                        selectedTab: $selectedTab,
                        sharedNavigationHeader: analyticsNavigationHeader,
                        isSubpageActiveBinding: $isAnalyticsSubpageActive
                    )
                }
                .overlay(alignment: .top) {
                    if analyticsNavigationHeader.isVisible {
                        AnalyticsNavigationHeader(state: analyticsNavigationHeader)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .transition(.identity)
                    }
                }
                .environment(\.spendyTipsAllowed, selectedTab == .analytics && !showAddTransaction)
                .opacity(selectedTab == .analytics ? 1 : 0)
                .allowsHitTesting(selectedTab == .analytics)
                .accessibilityHidden(selectedTab != .analytics)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Adaptive Bottom Dock (Home + Subscriptions + Hero Blue Spend Pill)
            GlassTabBar(
                selectedTab: $selectedTab,
                isExpanded: selectedTab == .home ? isHomeDrawerExpanded : true,
                onQuickAdd: {
                    receiptToEdit = nil
                    showAddTransaction = true
                },
                receiptNeedsIntroduction: !hasSeenReceiptIntroduction,
                receiptMenuRequest: receiptMenuRequest,
                onReceiptIntroduction: { receiptSheet = .introduction },
                onReceiptSource: selectReceiptSource
            )
            .padding(.bottom, 6)
            .offset(y: isDockVisible || reduceMotion ? 0 : 120)
            .opacity(isDockVisible ? 1 : 0)
            .allowsHitTesting(isDockVisible)
            .accessibilityHidden(!isDockVisible)
            .animation(reduceMotion ? nil : AppMotion.fluidSpring, value: isDockVisible)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        #if DEBUG
        .overlay(alignment: .topLeading) {
            if ProcessInfo.processInfo.environment["SPENDY_UI_TEST_ACTION_PAYLOAD"] != nil {
                ReceiptActionTestHost().padding(20)
            }
        }
        #endif
        .fullScreenCover(isPresented: $showAddTransaction, onDismiss: {
            receiptToEdit = nil
            openReceivedReceipt()
            openRequestedReceiptCamera()
        }) {
            AddTransactionView(scannedReceipt: receiptToEdit)
        }
        .sheet(item: $receiptSheet, onDismiss: receiptSheetDismissed) { sheet in
            switch sheet {
            case .introduction:
                ReceiptScanIntroductionSheet {
                    hasSeenReceiptIntroduction = true
                    openReceiptMenuOnDismiss = true
                    receiptSheet = nil
                }
            case .camera:
                ReceiptCameraCaptureView { image in
                    pendingReceiptSheet = .review([image])
                    receiptSheet = nil
                } onCancel: {
                    receiptSheet = nil
                } onChoosePhoto: {
                    openReceiptPhotosOnDismiss = true
                    receiptSheet = nil
                }
                .presentationDetents([.fraction(0.72)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.clear)
                .preferredColorScheme(.dark)
            case .review(let images):
                ReceiptScannerSheet(images: images,
                    initialAccountId: store.accounts.first?.id,
                    initialCategoryId: store.categories.first(where: { $0.type == .expense })?.id,
                    onEditResult: { result in
                        pendingReceiptEdit = result
                        receiptSheet = nil
                    },
                    onAddResult: addReceiptTransaction)
            }
        }
        .sheet(isPresented: $showReceiptPhotos, onDismiss: {
            receiptPhotosArePresented = false
            if quickActionManager.receivedReceiptImages != nil {
                pendingReceiptPhoto = nil
                openReceivedReceipt()
            } else if let image = pendingReceiptPhoto {
                pendingReceiptPhoto = nil
                receiptSheet = .review([image])
            }
        }) {
            ReceiptPhotoPickerSheet { image in pendingReceiptPhoto = image }
                .onAppear { receiptPhotosArePresented = true }
        }
        .alert("Receipt image", isPresented: Binding(
            get: { receiptImportError != nil },
            set: { if !$0 { receiptImportError = nil } }
        )) {
            Button("OK", role: .cancel) { receiptImportError = nil }
        } message: { Text(receiptImportError ?? "") }
        .onChange(of: quickActionManager.shouldPresentQuickAdd) { _, shouldPresent in
            if shouldPresent {
                showAddTransaction = true
                quickActionManager.shouldPresentQuickAdd = false
            }
        }
        .onChange(of: quickActionManager.shouldPresentReceiptScan) { _, shouldPresent in
            if shouldPresent { openRequestedReceiptCamera() }
        }
        .onChange(of: quickActionManager.receivedReceiptImages) { _, _ in openReceivedReceipt() }
        .onChange(of: quickActionManager.receiptFileImportError) { _, error in
            guard let error else { return }
            receiptImportError = error
            quickActionManager.receiptFileImportError = nil
        }
        .onAppear {
            openReceivedReceipt()
            openRequestedReceiptCamera()
        }
        .onChange(of: quickActionManager.targetTab) { _, target in
            if let target {
                withAnimation(AppMotion.snappySpring) {
                    selectedTab = target
                }
                quickActionManager.targetTab = nil
            }
        }
    }

    private func openRequestedReceiptCamera() {
        guard quickActionManager.shouldPresentReceiptScan else { return }
        if showAddTransaction {
            showAddTransaction = false
            return // Present from the cover's onDismiss, after the form is gone.
        }
        quickActionManager.shouldPresentReceiptScan = false
        selectedTab = .home
        if receiptSheet != nil {
            pendingReceiptSheet = .camera
            receiptSheet = nil
        } else {
            receiptSheet = .camera
        }
    }

    private func openReceivedReceipt() {
        if let error = quickActionManager.receiptFileImportError {
            receiptImportError = error
            quickActionManager.receiptFileImportError = nil
        }
        guard let images = quickActionManager.receivedReceiptImages else { return }
        pendingReceiptPhoto = nil
        pendingReceiptEdit = nil
        openReceiptMenuOnDismiss = false
        openReceiptPhotosOnDismiss = false
        if showReceiptPhotos || receiptPhotosArePresented {
            showReceiptPhotos = false
            return // Finish dismissing the picker before presenting the received image.
        }
        if showAddTransaction {
            showAddTransaction = false
            return
        }
        quickActionManager.receivedReceiptImages = nil
        selectedTab = .home
        if receiptSheet != nil {
            pendingReceiptSheet = .review(images)
            receiptSheet = nil
        } else {
            receiptSheet = .review(images)
        }
    }

    private func selectReceiptSource(_ source: ReceiptSourceMenuButton.Source) {
        switch source {
        case .paste:
            guard let image = ReceiptImageClipboard.image else {
                receiptImportError = "Copy a receipt image first, then choose Paste image again."
                return
            }
            receiptSheet = .review([image])
        case .photos: showReceiptPhotos = true
        case .camera: receiptSheet = .camera
        }
    }

    private func receiptSheetDismissed() {
        if let result = pendingReceiptEdit {
            pendingReceiptEdit = nil
            receiptToEdit = result
            showAddTransaction = true
        } else if let sheet = pendingReceiptSheet {
            pendingReceiptSheet = nil
            receiptSheet = sheet
        } else if openReceiptPhotosOnDismiss {
            openReceiptPhotosOnDismiss = false
            showReceiptPhotos = true
        } else if openReceiptMenuOnDismiss {
            openReceiptMenuOnDismiss = false
            receiptMenuRequest += 1
        }
    }

    private func addReceiptTransaction(_ result: ReceiptScanResult) {
        let title = result.merchantName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard result.totalAmount > 0, !title.isEmpty, result.hasDetectedDate,
              result.paymentStatus != .pending, result.paymentStatus != .failed,
              result.currencySymbol == store.currencySymbol,
              let categoryID = result.suggestedCategoryId,
              let accountID = result.suggestedAccountId,
              store.categories.contains(where: { $0.id == categoryID && $0.type == result.transactionType }),
              store.accounts.contains(where: { $0.id == accountID }) else { return }
        HapticsManager.shared.trigger(.success)
        store.addTransaction(Transaction(title: title, amount: result.totalAmount,
            type: result.transactionType, categoryId: categoryID, accountId: accountID, date: result.date))
        receiptSheet = nil
    }

}
