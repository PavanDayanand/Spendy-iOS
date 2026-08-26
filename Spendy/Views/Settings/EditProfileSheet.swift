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
    @State private var showPhotoLibraryPicker: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    // Color Palette & Sliders state matching AddCategorySheet
    @State private var showColorPalette: Bool = false
    @State private var showSliders: Bool = false
    @State private var sliderHue: Double = 0.65
    @State private var sliderBrightness: Double = 0.45
    
    @State private var showCurrencyPicker: Bool = false
    
    private let presetColors = [
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Gold / Yellow
        "#34C759", // Green
        "#00C7BE", // Teal / Cyan
        "#007AFF", // Blue
        "#5856D6", // Purple
        "#AF52DE"  // Pink Violet
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header Bar: Close, Title "Edit Space" (Sticky at top!)
                topHeaderBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .background(Color(hex: "#1C1C1E"))
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
                selectedColorHex = store.topGradientColorHex
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
                    colors: [Color.clear, Color(hex: "#1C1C1E").opacity(0.95), Color(hex: "#1C1C1E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .presentationBackground(Color(hex: "#1C1C1E"))
        .presentationDragIndicator(.visible)
        // MARK: - Modals & Pickers
        .sheet(isPresented: $showIconPickerSheet) {
            CategoryIconPickerSheet(
                selectedSymbol: $selectedIconSymbol,
                showPhotoOption: true,
                isPhotoSet: selectedImageData != nil,
                onPhotoLibrarySelected: {
                    showPhotoLibraryPicker = true
                },
                onCameraSelected: {
                    showCameraPicker = true
                },
                onRemovePhotoSelected: {
                    selectedImageData = nil
                }
            )
        }
        .photosPicker(isPresented: $showPhotoLibraryPicker, selection: $selectedPhotoItem, matching: .images)
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedImageData = data
                        showIconPickerSheet = false
                        HapticsManager.shared.trigger(.success)
                    }
                }
            }
        }
    }
    
    // MARK: - Top Header Bar
    private var topHeaderBar: some View {
        HStack {
            // Close Button
            GlassCircleButton(
                icon: "xmark",
                size: 44,
                iconSize: 14,
                foregroundColor: SpendyColors.textPrimary,
                haptic: .selection,
                accessibilityLabel: "Close"
            ) {
                dismiss()
            }
            
            Spacer()
            
            Text("Edit Space")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
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
                            .fill(Color(hex: "#1C1C1E"))
                            .frame(width: 26, height: 26)
                            .overlay {
                                Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                            }
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
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
            // Presets row + Rainbow Wheel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Spectrum Wheel Circle Button (Toggles Sliders)
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showSliders.toggle()
                        }
                        HapticsManager.shared.trigger(.selection)
                    }) {
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red]),
                                    center: .center
                                )
                            )
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: showSliders ? 2.5 : 0)
                            )
                            .shadow(color: Color.white.opacity(0.35), radius: showSliders ? 4 : 0)
                    }
                    .buttonStyle(.plain)
                    
                    // Preset circles
                    ForEach(presetColors, id: \.self) { hex in
                        Button(action: {
                            selectedColorHex = hex
                            syncSlidersFromHex(hex)
                            store.setTopGradientColor(Color(hex: hex))
                            HapticsManager.shared.trigger(.light)
                        }) {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if selectedColorHex == hex {
                                        Circle()
                                            .stroke(SpendyColors.textPrimary, lineWidth: 2)
                                            .shadow(color: Color.black.opacity(0.3), radius: 3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
            }
            
            // Hue & Brightness Sliders
            if showSliders {
                VStack(spacing: 14) {
                    HueSpectrumSlider(hue: $sliderHue)
                        .onChange(of: sliderHue) { _, newValue in
                            updateHexFromHSB()
                        }
                    
                    DarkBrightnessSlider(hue: sliderHue, brightness: $sliderBrightness)
                        .onChange(of: sliderBrightness) { _, newValue in
                            updateHexFromHSB()
                        }
                }
                .padding(.vertical, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
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
                .tint(Color.green)
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
            store.setTopGradientColor(Color(hex: selectedColorHex))
            dismiss()
        }) {
            Text("Save")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white, in: Capsule())
                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 3)
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

// MARK: - Hue Spectrum Slider Component (Matching AddCategorySheet)
private struct HueSpectrumSlider: View {
    @Binding var hue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let thumbX = CGFloat(hue) * width
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hue: 0.0, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.17, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.33, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.50, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.67, saturation: 1.0, brightness: 0.95),
                                Color(hue: 0.83, saturation: 1.0, brightness: 0.95),
                                Color(hue: 1.0, saturation: 1.0, brightness: 0.95)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 38)
                
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .background(Circle().fill(Color(hue: hue, saturation: 1.0, brightness: 0.95)))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: max(16, min(width - 16, thumbX)), y: 19)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let locationX = max(0, min(geometry.size.width, value.location.x))
                        let newHue = Double(locationX / geometry.size.width)
                        self.hue = newHue
                    }
            )
        }
        .frame(height: 38)
    }
}

// MARK: - Dark Brightness Slider Component (Matching AddCategorySheet)
private struct DarkBrightnessSlider: View {
    let hue: Double
    @Binding var brightness: Double
    
    private let minB: Double = 0.12
    private let maxB: Double = 0.95
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let normB = (brightness - minB) / (maxB - minB)
            let thumbX = CGFloat(max(0, min(1, normB))) * width
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black,
                                Color(hue: hue, saturation: 0.85, brightness: 0.50),
                                Color(hue: hue, saturation: 0.85, brightness: maxB)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 38)
                
                Circle()
                    .stroke(Color.white, lineWidth: 3.5)
                    .background(Circle().fill(Color(hue: hue, saturation: 0.85, brightness: min(brightness, maxB))))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: max(16, min(width - 16, thumbX)), y: 19)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let locationX = max(0, min(geometry.size.width, value.location.x))
                        let fraction = Double(locationX / geometry.size.width)
                        let newB = minB + fraction * (maxB - minB)
                        self.brightness = min(max(minB, newB), maxB)
                    }
            )
        }
        .frame(height: 38)
    }
}
