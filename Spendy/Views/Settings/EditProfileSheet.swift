//
//  EditProfileSheet.swift
//  Spendy
//
//  Drawer Sheet for Editing User Profile & Space Settings matching AddCategorySheet Liquid Glass Design
//

import SwiftUI

struct EditProfileSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempName: String = ""
    @State private var selectedImageData: Data? = nil
    @State private var selectedIconSymbol: String = "person.fill"
    @State private var selectedColorHex: String = "#007AFF"
    
    // Icon picker sheet
    @State private var showIconPickerSheet: Bool = false
    
    
    @State private var showCurrencyPicker: Bool = false
    @State private var showDiscardConfirm: Bool = false
    @Namespace private var profileNamespace
    
    private var hasUnsavedChanges: Bool {
        let originalName = store.userName.isEmpty ? "Personal" : store.userName
        let originalIcon = store.profileIconSymbol ?? "person.fill"
        return tempName != originalName ||
               selectedImageData != store.profileImageData ||
               selectedIconSymbol != originalIcon
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            // Dynamic Space Ambient Gradient Glow based on selected theme color
            let themeColor = Color(hex: selectedColorHex)
            SpendyAmbientHeaderBackground(color: themeColor, height: 340, opacity: 0.32)
            
            VStack(spacing: 0) {
                // Top Header Bar: Close, Title "Edit Space" (Sticky at top!)
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Circle Avatar (Matching AddCategorySheet)
                        avatarHeroSection
                            .padding(.top, 40)
                        
                        // Name field
                        nameAndColorCard
                        
                        // Default Currency Selector Card (Matching reference design)
                        defaultCurrencyCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Clearance for bottom Save button
                }
            }
            .onAppear {
                tempName = store.userName.isEmpty ? "Personal" : store.userName
                selectedImageData = store.profileImageData
                selectedIconSymbol = store.profileIconSymbol ?? "person.fill"
                selectedColorHex = store.profileColorHex ?? store.topGradientColorHex
            }
            
            // Bottom Fixed Action Button Container (White Capsule Save Button)
            VStack(spacing: 0) {
                bottomSaveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 16)
            }
            .background {
                LinearGradient(
                    stops: [
                        .init(color: SpendyColors.appBackground.opacity(0), location: 0),
                        .init(color: SpendyColors.appBackground.opacity(0.85), location: 0.25),
                        .init(color: SpendyColors.appBackground, location: 0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
        .presentationBackground(SpendyColors.appBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .toolbar(.hidden, for: .navigationBar)
        .interactiveDismissDisabled(hasUnsavedChanges)
        .alert("Discard Changes?", isPresented: $showDiscardConfirm) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
        }
        .sheet(isPresented: $showIconPickerSheet) {
            CategoryIconPickerSheet(
                selectedSymbol: $selectedIconSymbol,
                showPhotoOption: true,
                isPhotoSet: selectedImageData != nil,
                onPhotoSelected: { data in
                    selectedImageData = data
                },
                onRemovePhotoSelected: {
                    selectedImageData = nil
                },
                onIconSelected: { _ in
                    selectedImageData = nil
                }
            )
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet()
        }
    }
    
    // MARK: - Subviews
    
    // Top Header Bar
    private var topHeaderBar: some View {
        SpendyGlassEffectContainer(spacing: 0) {
            HStack {
                // Close Button
                GlassCircleButton(
                    icon: "xmark",
                    size: 44,
                    iconSize: 14,
                    foregroundColor: SpendyColors.textPrimary,
                    haptic: .selection,
                    accessibilityLabel: "Close",
                    morphID: "closeButton",
                    namespace: profileNamespace
                ) {
                    if hasUnsavedChanges {
                        showDiscardConfirm = true
                    } else {
                        dismiss()
                    }
                }
                
                Spacer()
                
                Text("Edit Space")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Spacer()
                
                Color.clear.frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Avatar Hero Section (Matching AddCategorySheet)
    private var avatarHeroSection: some View {
        VStack(spacing: 12) {
            SpendyEditableHeroIcon(accessibilityLabel: "Edit profile photo or icon") {
                showIconPickerSheet = true
            } icon: {
                if let imgData = selectedImageData, let uiImage = UIImage(data: imgData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.16), radius: 10, y: 4)
                } else {
                    SpendyIconBadge(
                        sfSymbol: selectedIconSymbol.isEmpty ? "person.fill" : selectedIconSymbol,
                        color: Color(hex: selectedColorHex),
                        size: .hero,
                        style: .rounded(),
                        monogramName: tempName
                    )
                }
            }
            
            Text(tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Personal" : tempName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
        }
    }
    
    // MARK: - Name Card
    private var nameAndColorCard: some View {
        HStack {
            TextField("Personal", text: $tempName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .autocorrectionDisabled()
            
            Spacer()
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(SpendyColors.sheetCardBackground, in: Capsule())
    }
    
    // MARK: - Default Currency Card
    private var defaultCurrencyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                HapticsManager.shared.trigger(.light)
                showCurrencyPicker = true
            }) {
                HStack {
                    Text("Default currency")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("\(CurrencyInfo.flag(for: store.currencyCode)) \(store.currencyCode)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(SpendyColors.textSecondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SpendyColors.textTertiary)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(SpendyColors.sheetCardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                }
            }
            .buttonStyle(.plain)
            
            Text("The default currency used for transactions and budgets in this space.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.horizontal, 6)
        }
    }
    
    // MARK: - Bottom Save Action Button (White Capsule)
    private var bottomSaveButton: some View {
        Button(action: {
            HapticsManager.shared.trigger(.success)
            store.userName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
            store.profileImageData = selectedImageData
            store.profileIconSymbol = selectedIconSymbol
            dismiss()
        }) {
            Text("Save")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(SpendyColors.elevatedControlForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(SpendyColors.elevatedControlFill, in: Capsule())
                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}
