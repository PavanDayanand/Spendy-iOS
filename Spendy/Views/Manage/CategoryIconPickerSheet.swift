//
//  CategoryIconPickerSheet.swift
//  Spendy
//
//  Centralized, Reusable Universal Icon Picker Sheet Drawer
//  Features:
//  - Apple default grey theme (.systemGroupedBackground)
//  - 2-toggle Liquid Glass Segmented Switcher (Defaults & Brands)
//  - Direct PhotosPicker gallery launcher on the first slot
//  - "Aa" dynamic monogram launcher on the second slot
//  - Curated, extensive collection of SF Symbols and Brand representations
//  - Liquid Glass Floating Bottom Search Bar with real-time filtering
//  - Apple HIG compliant 52x52pt tap targets with bounce micro-interactions & haptic feedback
//

import SwiftUI
import PhotosUI

struct CategoryIconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ExpenseStore.self) private var store
    
    @Binding var selectedSymbol: String
    var showPhotoOption: Bool = true
    var isPhotoSet: Bool = false
    var onPhotoLibrarySelected: (() -> Void)? = nil
    var onCameraSelected: (() -> Void)? = nil
    var onRemovePhotoSelected: (() -> Void)? = nil
    var onIconSelected: ((String) -> Void)? = nil
    
    @State private var selectedTab: IconTab = .defaults
    @State private var searchText: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @Namespace private var iconSheetNamespace
    
    // MARK: - 2-Toggle Mode Switcher
    enum IconTab: String, CaseIterable, Identifiable {
        case defaults = "Defaults"
        case brands = "Brands"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .defaults: return "circle.grid.2x2.fill"
            case .brands: return "applelogo"
            }
        }
    }
    
    // MARK: - Apple Default Grey Colors
    private var sheetBackgroundColor: Color {
        Color(uiColor: .systemGroupedBackground)
    }
    
    private var iconItemBackgroundColor: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
    
    // User name initial monogram or "Aa"
    private var monogramText: String {
        let trimmed = store.userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first {
            return String(first).uppercased()
        }
        return "Aa"
    }
    
    // MARK: - Curated System SF Symbols matching reference order
    private let defaultSymbols: [String] = [
        // Row 1 (cont)
        "sparkles", "sparkle", "alarm.fill",
        
        // Row 2
        "face.smiling.fill", "leaf.fill", "cross.case.fill", "anchor", "applelogo",
        
        // Row 3
        "backpack.fill", "banknote.fill", "dollarsign.circle.fill", "briefcase.fill", "case.fill",
        
        // Row 4
        "birthday.cake.fill", "basketball.fill", "balloon.fill", "moon.fill", "bandage.fill",
        
        // Row 5
        "building.columns.fill", "frying.pan.fill", "baseball.fill", "gamecontroller.fill", "battery.100",
        
        // Row 6
        "umbrella.fill", "pawprint.fill", "mug.fill", "bicycle", "creditcard.fill",
        
        // Row 7
        "creditcard.and.123", "chart.pie.fill", "boxingglove.fill", "bone.fill", "soup.fill",
        
        // Row 8
        "fork.knife", "bus.fill", "car.fill", "cablecar.fill", "cart.fill",
        
        // Row 9
        "calculator.fill", "flame.fill", "tent.fill", "gift.fill", "theatermasks.fill",
        
        // Finance & Currency
        "indianrupeesign.circle.fill", "eurosign.circle.fill", "sterlingsign.circle.fill", "yensign.circle.fill",
        "chineseyuansign.circle.fill", "rublesign.circle.fill", "turkishlirasign.circle.fill", "wallet.pass.fill",
        "wallet.bifold.fill", "chart.bar.fill", "chart.line.uptrend.xyaxis", "percent", "bitcoinsign.circle.fill",
        "arrow.triangle.2.circlepath", "shield.lefthalf.filled.badge.checkmark",
        
        // Food & Groceries
        "takeoutbag.and.cup.and.straw.fill", "cup.and.saucer.fill", "wineglass.fill", "waterbottle.fill",
        "popcorn.fill", "carrot.fill", "fish.fill",
        
        // Shopping & Fashion
        "bag.fill", "bag.badge.plus", "tag.fill", "gift.circle.fill", "shippingbox.fill",
        "tshirt.fill", "shoe.fill", "scissors", "comb.fill", "key.fill", "lock.fill",
        "ticket.fill", "crown.fill", "trophy.fill", "medal.fill",
        
        // Transport & Auto
        "car.side.fill", "fuelpump.fill", "ev.charger.fill", "tram.fill", "train.side.front.car",
        "ferry.fill", "airplane", "airplane.departure", "airplane.arrival", "scooter",
        "sailboat.fill", "parkingsign.circle.fill",
        
        // Home & Utilities
        "house.fill", "building.2.fill", "bolt.fill", "drop.fill", "wifi",
        "lightbulb.fill", "lamp.desk.fill", "bed.double.fill", "sofa.fill", "bathtub.fill",
        "washer.fill", "refrigerator.fill", "fan.fill", "trash.fill",
        
        // Fitness & Sports
        "heart.fill", "heart.circle.fill", "pills.fill", "cross.circle.fill", "dumbbell.fill",
        "figure.run", "figure.walk", "figure.strengthtraining.traditional", "figure.yoga",
        "figure.outdoor.cycle", "tennis.racket", "soccerball",
        
        // Entertainment & Media
        "tv.fill", "music.note", "music.mic", "headphones", "play.rectangle.fill",
        "film.fill", "camera.fill", "photo.fill", "video.fill", "book.fill",
        "text.book.closed.fill", "sparkles.tv.fill",
        
        // Devices & Tech
        "iphone", "ipad", "laptopcomputer", "desktopcomputer", "applewatch",
        "airpodsmax", "airpodspro", "homepod.fill", "printer.fill", "display",
        "externaldrive.fill", "cpu.fill", "server.rack",
        
        // Work & Education
        "graduationcap.fill", "briefcase.circle.fill", "folder.fill", "doc.text.fill",
        "newspaper.fill", "pencil", "paintbrush.fill", "hammer.fill", "wrench.and.screwdriver.fill",
        "gearshape.2.fill", "ruler.fill",
        
        // People & Nature
        "person.fill", "person.2.fill", "person.3.fill", "figure.2.and.child.holdinghands",
        "tree.fill", "sun.max.fill", "cloud.rain.fill", "snowflake", "globe.americas.fill",
        "bell.fill", "bubble.left.and.bubble.right.fill", "paperplane.fill", "star.fill",
        "bookmark.fill", "flag.fill", "calendar.badge.clock"
    ]
    
    // MARK: - Curated Brand & Service Symbols
    private let brandSymbols: [String] = [
        // Tech Platforms & Ecosystems
        "applelogo", "playstation.logo", "xbox.logo", "appletv.fill", "visionpro.fill",
        
        // Streaming & Video (Netflix, YouTube, Prime Video, Disney+)
        "play.tv.fill", "play.rectangle.fill", "film.fill", "tv.and.mediabox.fill",
        "play.circle.fill", "video.fill", "popcorn.fill", "sparkles.tv.fill",
        
        // Music & Audio (Spotify, Apple Music, Tidal, Podcasts)
        "music.note", "music.note.list", "headphones.circle.fill", "waveform",
        "waveform.badge.mic", "hifispeaker.fill", "radio.fill", "mic.circle.fill",
        
        // Cloud & Productivity (iCloud, Google Drive, Dropbox, Notion)
        "icloud.fill", "cloud.fill", "arrow.up.doc.fill", "externaldrive.connected.to.line.below.fill",
        "folder.circle.fill", "doc.text.fill", "checklist", "note.text",
        
        // AI & Innovation (OpenAI, ChatGPT, Claude, Gemini, Copilot)
        "sparkle", "wand.and.stars", "cpu.fill", "brain.head.profile.fill", "brain.fill", "atom",
        
        // Shopping & Delivery (Amazon, Swiggy, Zomato, DoorDash, UberEats)
        "shippingbox.fill", "cart.badge.plus", "bag.badge.plus", "box.truck.fill",
        "takeoutbag.and.cup.and.straw.fill", "fork.knife.circle.fill", "cup.and.heat.waves.fill",
        
        // Rides & Transit (Uber, Lyft, Ola, Maps, Airlines)
        "car.side.fill", "location.circle.fill", "location.fill", "map.circle.fill",
        "airplane.circle.fill", "tram.fill",
        
        // Banking & Fintech (Visa, Mastercard, Amex, PayPal, Revolut)
        "building.columns.circle.fill", "creditcard.circle.fill", "wallet.bifold.fill",
        "banknote.fill", "bitcoinsign.circle.fill", "shield.checkered", "lock.shield.fill",
        
        // Telecom & VPN (Airtel, Jio, Verizon, NordVPN)
        "antenna.radiowaves.left.and.right", "cellularbars", "network.badge.shield.half.filled",
        "phone.connection.fill", "simcard.fill", "lock.fill", "key.fill",
        
        // Design & Dev (Adobe, Figma, GitHub, VS Code, Slack, Teams)
        "paintpalette.fill", "wand.and.rays", "paintbrush.pointed.fill", "pencil.and.ruler.fill",
        "terminal.fill", "curlybraces", "chevron.left.forwardslash.chevron.right",
        "rectangle.3.group.fill", "bubble.left.and.text.bubble.right.fill",
        
        // Social & News (Substack, Medium, Tinder, Bumble)
        "newspaper.fill", "text.quote", "book.circle.fill", "text.bubble.fill",
        "heart.rectangle.fill", "sparkles.rectangle.stack.fill", "megaphone.fill",
        
        // Alphabetical Brand Monograms (A–Z)
        "a.circle.fill", "b.circle.fill", "c.circle.fill", "d.circle.fill",
        "e.circle.fill", "f.circle.fill", "g.circle.fill", "h.circle.fill",
        "i.circle.fill", "j.circle.fill", "k.circle.fill", "l.circle.fill",
        "m.circle.fill", "n.circle.fill", "o.circle.fill", "p.circle.fill",
        "q.circle.fill", "r.circle.fill", "s.circle.fill", "t.circle.fill",
        "u.circle.fill", "v.circle.fill", "w.circle.fill", "x.circle.fill",
        "y.circle.fill", "z.circle.fill"
    ]
    
    // MARK: - Active Filtered Symbols
    private var activeSymbols: [String] {
        let baseList = (selectedTab == .defaults) ? defaultSymbols : brandSymbols
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return baseList
        }
        return baseList.filter { $0.lowercased().contains(query) }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            sheetBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Header Bar: Close Button & Centered Title "Choose Icon"
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                // 2. 2-Toggle Segmented Control (Defaults / Brands)
                segmentedTabControl
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                
                // 3. Scrollable Unified Icon Grid
                ScrollView(showsIndicators: false) {
                    if activeSymbols.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
                            // Top Row Slot 1: Photo Library Picker (when on Defaults & not searching)
                            if selectedTab == .defaults && searchText.isEmpty && showPhotoOption {
                                photoPickerSlot
                            }
                            
                            // Top Row Slot 2: "Aa" Monogram Launcher (when on Defaults & not searching)
                            if selectedTab == .defaults && searchText.isEmpty {
                                monogramSlot
                            }
                            
                            // Remaining Grid Slots
                            ForEach(activeSymbols, id: \.self) { sym in
                                iconButton(symbol: sym)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        
                        // Bottom spacing to prevent floating search bar overlap
                        Color.clear
                            .frame(height: 72)
                    }
                }
            }
            
            // 4. Floating Liquid Glass Bottom Search Bar
            floatingSearchCapsule
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .presentationBackground(sheetBackgroundColor)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        store.profileImageData = data
                        onPhotoLibrarySelected?()
                        HapticsManager.shared.trigger(.success)
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        SpendyGlassEffectContainer(spacing: 0) {
            ZStack {
                Text("Choose Icon")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 60)
                
                HStack {
                    GlassCircleButton(
                        icon: "xmark",
                        size: 44,
                        iconSize: 14,
                        foregroundColor: SpendyColors.textPrimary,
                        haptic: .selection,
                        accessibilityLabel: "Close",
                        morphID: "closeIconPickerButton",
                        namespace: iconSheetNamespace
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - 2-Toggle Segmented Control (Defaults / Brands)
    private var segmentedTabControl: some View {
        GlassSegmentedPicker(
            selection: $selectedTab,
            items: IconTab.allCases,
            titleFor: { $0.rawValue },
            iconFor: { $0.icon }
        )
    }
    
    // MARK: - Photo Picker Slot (Opens Gallery Directly)
    @ViewBuilder
    private var photoPickerSlot: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack {
                Circle()
                    .fill(isPhotoSet ? SpendyColors.primaryBlue : iconItemBackgroundColor)
                    .frame(width: 52, height: 52)
                    .overlay {
                        if isPhotoSet {
                            Circle()
                                .stroke(SpendyColors.textPrimary, lineWidth: 2)
                        } else {
                            Circle()
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                    }
                    .shadow(color: isPhotoSet ? Color.black.opacity(0.20) : Color.clear, radius: 6, y: 2)
                
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        isPhotoSet
                            ? SpendyColors.inverseText
                            : SpendyColors.textPrimary
                    )
            }
            .contentShape(Circle())
        }
    }
    
    // MARK: - "Aa" Monogram Slot
    @ViewBuilder
    private var monogramSlot: some View {
        let isSelected = selectedSymbol == "Aa" || selectedSymbol == monogramText
        
        Button {
            selectedSymbol = "Aa"
            onIconSelected?("Aa")
            HapticsManager.shared.trigger(.selection)
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? SpendyColors.primaryBlue : iconItemBackgroundColor)
                    .frame(width: 52, height: 52)
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(SpendyColors.textPrimary, lineWidth: 2)
                        } else {
                            Circle()
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                    }
                    .shadow(color: isSelected ? Color.black.opacity(0.20) : Color.clear, radius: 6, y: 2)
                
                Text("Aa")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        isSelected
                            ? SpendyColors.inverseText
                            : SpendyColors.textPrimary
                    )
                    .symbolEffect(.bounce.byLayer, value: isSelected)
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Icon Grid Item Button
    @ViewBuilder
    private func iconButton(symbol: String) -> some View {
        let isSelected = selectedSymbol == symbol && !isPhotoSet
        
        Button {
            selectedSymbol = symbol
            onIconSelected?(symbol)
            HapticsManager.shared.trigger(.selection)
            dismiss()
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? SpendyColors.primaryBlue : iconItemBackgroundColor)
                    .frame(width: 52, height: 52)
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(SpendyColors.textPrimary, lineWidth: 2)
                        } else {
                            Circle()
                                .stroke(SpendyColors.separator, lineWidth: 0.8)
                        }
                    }
                    .shadow(color: isSelected ? Color.black.opacity(0.20) : Color.clear, radius: 6, y: 2)
                
                Image(systemName: cleanSymbolName(symbol))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        isSelected
                            ? SpendyColors.inverseText
                            : SpendyColors.textPrimary
                    )
                    .symbolEffect(.bounce.byLayer, value: isSelected)
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Floating Liquid Glass Bottom Search Bar
    private var floatingSearchCapsule: some View {
        HStack(spacing: 10) {
            Image(systemName: SFIcons.search)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            TextField(selectedTab == .defaults ? "Search icons" : "Search brands", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !searchText.isEmpty {
                Button {
                    HapticsManager.shared.trigger(.tick)
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(SpendyColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .nativeLiquidGlassCapsule(isInteractive: true)
        .shadow(color: Color.black.opacity(0.16), radius: 12, y: 4)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(SpendyColors.textTertiary)
                .padding(.top, 40)
            
            Text("No icons matching \"\(searchText)\"")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SpendyColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Helper Symbol Translation
    private func cleanSymbolName(_ name: String) -> String {
        switch name {
        case "abc":
            return "character.textbox"
        case "delivery.truck.fill":
            return "truck.box.fill"
        default:
            return name
        }
    }
}
