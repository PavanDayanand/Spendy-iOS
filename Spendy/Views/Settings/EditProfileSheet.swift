//
//  EditProfileSheet.swift
//  Spendy
//
//  Drawer Sheet for Editing User Profile & Space Settings matching AddCategorySheet Liquid Glass Design
//

import SwiftUI
import PhotosUI

struct EditProfileSheet: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempName: String = ""
    @State private var selectedImageData: Data? = nil
    @State private var selectedIconSymbol: String = "person.fill"
    @State private var selectedColorHex: String = "#007AFF"
    
    // Icon picker sheet & Photo dialog state
    @State private var showIconPickerSheet: Bool = false
    @State private var showPhotoDialog: Bool = false
    @State private var showCameraPicker: Bool = false
    
    // Color Palette & Sliders state matching AddCategorySheet
    @State private var showColorPalette: Bool = false

    @State private var sliderHue: Double = 0.65
    @State private var sliderBrightness: Double = 0.45
    
    @State private var showCurrencyPicker: Bool = false
    @State private var showDiscardConfirm: Bool = false
    @Namespace private var profileNamespace
    
    private var hasUnsavedChanges: Bool {
        let originalName = store.userName.isEmpty ? "Personal" : store.userName
        let originalIcon = store.profileIconSymbol ?? "person.fill"
        let originalColor = store.profileColorHex ?? store.topGradientColorHex
        return tempName != originalName ||
               selectedImageData != store.profileImageData ||
               selectedIconSymbol != originalIcon ||
               selectedColorHex != originalColor
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
                        
                        // Name Input Field & Color Circle button (Matching AddCategorySheet)
                        nameAndColorCard
                        
                        // Color Palette / Sliders Card (Matching AddCategorySheet)
                        if showColorPalette {
                            colorPickerCard
                        }
                        
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
                syncSlidersFromHex(selectedColorHex)
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
                onCameraSelected: {
                    showCameraPicker = true
                },
                onRemovePhotoSelected: {
                    selectedImageData = nil
                },
                onIconSelected: { _ in
                    selectedImageData = nil
                }
            )
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerView { capturedImage in
                if let data = capturedImage.jpegData(compressionQuality: 0.8) {
                    selectedImageData = data
                    showIconPickerSheet = false
                    HapticsManager.shared.trigger(.success)
                }
            }
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
            ZStack(alignment: .topTrailing) {
                // Large Circular Avatar
                Button(action: {
                    HapticsManager.shared.trigger(.light)
                    showIconPickerSheet = true
                }) {
                    ZStack {
                        if let imgData = selectedImageData, let uiImage = UIImage(data: imgData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 2))
                                .shadow(color: Color(hex: selectedColorHex).opacity(0.4), radius: 10, y: 4)
                        } else {
                            SpendyIconBadge(
                                sfSymbol: selectedIconSymbol.isEmpty ? "person.fill" : selectedIconSymbol,
                                color: Color(hex: selectedColorHex),
                                size: .hero,
                                style: .circle
                            )
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
                            .fill(SpendyColors.cardBackground)
                            .frame(width: 26, height: 26)
                            .overlay {
                                Circle().stroke(SpendyColors.separator, lineWidth: 1)
                            }
                            .shadow(color: Color.black.opacity(0.12), radius: 3, y: 1)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(SpendyColors.textPrimary)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .offset(x: 2, y: -2)
            }
            
            Text(tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Personal" : tempName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
        }
    }
    
    // MARK: - Name & Color Card (Matching AddCategorySheet)
    private var nameAndColorCard: some View {
        HStack {
            TextField("Personal", text: $tempName)
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
        .background(SpendyColors.sheetCardBackground, in: Capsule())
    }
    
    // MARK: - Custom Color Picker (Matching AddCategorySheet & Settings)
    private var colorPickerCard: some View {
        VStack(spacing: 16) {
            SpendyColorPresetSwatches(selectedHex: $selectedColorHex, hue: $sliderHue, brightness: $sliderBrightness)
                .onChange(of: selectedColorHex) { _, newHex in
                    syncSlidersFromHex(newHex)
                    store.setTopGradientColor(Color(hex: newHex))
                }
                .onChange(of: sliderHue) { _, newValue in
                    updateHexFromHSB()
                }
                .onChange(of: sliderBrightness) { _, newValue in
                    updateHexFromHSB()
                }
            
            Divider()
                .overlay(SpendyColors.separator)
            
            // Gradient Background Toggle
            HStack {
                Text("Gradient background")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(SpendyColors.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { store.isGradientBackgroundEnabled },
                    set: {
                        store.isGradientBackgroundEnabled = $0
                        HapticsManager.shared.trigger(.selection)
                    }
                ))
                .labelsHidden()
                .tint(SpendyColors.incomeGreen)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(SpendyColors.sheetCardBackground)
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
        store.setTopGradientColor(color)
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
            store.profileColorHex = selectedColorHex
            store.setTopGradientColor(Color(hex: selectedColorHex))
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

// MARK: - Native Camera Picker UIViewControllerRepresentable Wrapper
struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


