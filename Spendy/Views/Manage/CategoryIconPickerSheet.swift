//
//  CategoryIconPickerSheet.swift
//  Spendy
//
//  Universal Choose Icon Sheet Drawer with Defaults & Brands tabs and dynamic Search Filtering
//

import SwiftUI

struct CategoryIconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSymbol: String
    var showPhotoOption: Bool = false
    var isPhotoSet: Bool = false
    var onPhotoLibrarySelected: (() -> Void)? = nil
    var onCameraSelected: (() -> Void)? = nil
    var onRemovePhotoSelected: (() -> Void)? = nil
    var onIconSelected: ((String) -> Void)? = nil
    
    @State private var selectedTab: IconTab = .defaults
    @State private var searchText: String = ""
    @Namespace private var iconSheetNamespace
    
    enum IconTab: String, CaseIterable, Identifiable {
        case defaults = "Defaults"
        case brands = "Brands"
        
        var id: String { rawValue }
    }
    
    // MARK: - Default SF Symbols (~130 icons organized by category)
    private let defaultSymbols = [
        // Food & Drink
        "cart.fill", "fork.knife", "takeoutbag.and.cup.and.straw.fill", "cup.and.saucer.fill",
        "mug.fill", "wineglass.fill", "waterbottle.fill", "birthday.cake.fill",
        "frying.pan.fill", "soup.fill",
        
        // Finance & Money
        "dollarsign.circle.fill", "indianrupeesign.circle.fill", "sterlingsign.circle.fill",
        "eurosign.circle.fill", "yensign.circle.fill", "creditcard.fill", "banknote.fill",
        "wallet.pass.fill", "chart.bar.fill", "chart.pie.fill", "chart.line.uptrend.xyaxis",
        "percent", "building.columns.fill",
        
        // Transport
        "car.fill", "car.side.fill", "bus.fill", "tram.fill", "ferry.fill",
        "bicycle", "scooter", "fuelpump.fill", "airplane", "airplane.departure",
        "airplane.arrival",
        
        // Home & Living
        "house.fill", "bolt.fill", "drop.fill", "wifi", "lightbulb.fill",
        "lamp.desk.fill", "bed.double.fill", "sofa.fill", "bathtub.fill",
        "washer.fill", "refrigerator.fill", "fan.fill",
        
        // Shopping & Objects
        "bag.fill", "tag.fill", "gift.fill", "gift.circle.fill", "shippingbox.fill",
        "tshirt.fill", "scissors", "comb.fill", "key.fill", "lock.fill",
        "ticket.fill", "crown.fill", "trophy.fill", "medal.fill",
        
        // Health & Fitness
        "heart.fill", "heart.circle.fill", "pills.fill", "cross.case.fill",
        "bandage.fill", "dumbbell.fill", "figure.run", "figure.walk",
        "figure.strengthtraining.traditional", "figure.yoga",
        
        // Entertainment & Media
        "tv.fill", "gamecontroller.fill", "music.note", "headphones",
        "play.rectangle.fill", "film.fill", "theatermasks.fill", "camera.fill",
        "photo.fill", "book.fill", "text.book.closed.fill",
        
        // Tech & Devices
        "desktopcomputer", "laptopcomputer", "iphone", "ipad",
        "printer.fill", "display", "externaldrive.fill", "cpu.fill",
        
        // People & Social
        "person.fill", "person.2.fill", "person.3.fill",
        "figure.2.and.child.holdinghands",
        
        // Nature & Weather
        "leaf.fill", "tree.fill", "cloud.rain.fill", "sun.max.fill",
        "moon.fill", "snowflake", "flame.fill", "pawprint.fill",
        
        // Communication
        "phone.fill", "envelope.fill", "message.fill", "paperplane.fill",
        "bell.fill", "megaphone.fill",
        
        // Education & Work
        "graduationcap.fill", "briefcase.fill", "briefcase.circle.fill",
        "hammer.fill", "wrench.and.screwdriver.fill", "gearshape.2.fill",
        "pencil", "paintbrush.fill",
        
        // Misc
        "sparkles", "star.fill", "bookmark.fill", "flag.fill",
        "map.fill", "globe", "anchor", "shield.checkered",
        "face.smiling.fill", "balloon.fill", "hand.thumbsup.fill",
        "alarm.fill", "calendar.badge.clock", "arrow.uturn.left.circle.fill",
        "backpack.fill", "bone.fill", "truck.box.fill",
        "basketball.fill", "soccerball", "baseball.fill", "tennis.racket",
        "battery.100", "binoculars.fill"
    ]
    
    // MARK: - Brand & Subscription SF Symbols (~85 icons)
    private let brandSymbols = [
        // Platform Logos
        "applelogo", "playstation.logo", "xbox.logo",
        
        // Streaming & Video (Netflix, YouTube, Disney+, Hulu, Prime Video)
        "play.tv.fill", "play.rectangle.fill", "film.fill", "tv.and.mediabox.fill",
        "play.circle.fill", "video.fill",
        
        // Music (Spotify, Apple Music, Tidal, SoundCloud)
        "music.note", "music.note.list", "headphones.circle.fill", "waveform",
        "hifispeaker.fill", "radio.fill",
        
        // Cloud & Storage (iCloud, Google Drive, Dropbox, OneDrive)
        "icloud.fill", "cloud.fill", "arrow.up.doc.fill", "externaldrive.connected.to.line.below.fill",
        "folder.circle.fill",
        
        // AI & Tech Tools (ChatGPT, Claude, Gemini, Copilot)
        "cpu.fill", "brain.head.profile.fill", "sparkle", "wand.and.stars",
        "brain.fill",
        
        // Shopping & E-Commerce (Amazon, Flipkart, eBay)
        "shippingbox.fill", "cart.badge.plus", "bag.badge.plus", "box.truck.fill",
        
        // Ride-hailing & Maps (Uber, Ola, Lyft)
        "car.side.fill", "location.circle.fill", "location.fill", "map.circle.fill",
        
        // Food Delivery (Swiggy, Zomato, DoorDash, UberEats)
        "takeoutbag.and.cup.and.straw.fill", "fork.knife.circle.fill", "cup.and.heat.waves.fill",
        
        // Fitness & Health (Gym, Peloton, Strava, Fitbit)
        "dumbbell.fill", "figure.strengthtraining.traditional", "figure.run.circle.fill",
        "heart.text.clipboard.fill", "figure.cooldown",
        
        // Insurance & Banking (Insurance, Banks, Fintech)
        "shield.checkered", "building.columns.circle.fill", "banknote.fill",
        "creditcard.circle.fill", "wallet.bifold.fill",
        
        // Phone & Telecom (Airtel, Jio, T-Mobile, Verizon)
        "antenna.radiowaves.left.and.right", "cellularbars", "phone.connection.fill",
        "simcard.fill",
        
        // Design & Creative (Adobe, Figma, Canva, Sketch)
        "paintpalette.fill", "wand.and.rays", "photo.artframe",
        "paintbrush.pointed.fill", "pencil.and.ruler.fill",
        
        // Developer & Productivity (GitHub, VS Code, Notion, Slack, Teams)
        "terminal.fill", "curlybraces", "chevron.left.forwardslash.chevron.right",
        "doc.text.fill", "bubble.left.and.text.bubble.right.fill",
        "person.3.fill", "rectangle.3.group.fill",
        
        // VPN & Security (NordVPN, ExpressVPN, 1Password)
        "lock.shield.fill", "network.badge.shield.half.filled", "key.fill",
        
        // News & Reading (Medium, Substack, Apple News, Kindle)
        "newspaper.fill", "text.quote", "book.circle.fill", "text.bubble.fill",
        
        // Social & Dating (Tinder, Bumble, Hinge)
        "heart.rectangle.fill", "sparkles.rectangle.stack.fill",
        
        // Letter-circle brand placeholders (A–Z)
        "a.circle.fill", "b.circle.fill", "c.circle.fill", "d.circle.fill",
        "e.circle.fill", "f.circle.fill", "g.circle.fill", "h.circle.fill",
        "i.circle.fill", "j.circle.fill", "k.circle.fill", "l.circle.fill",
        "m.circle.fill", "n.circle.fill", "o.circle.fill", "p.circle.fill",
        "q.circle.fill", "r.circle.fill", "s.circle.fill", "t.circle.fill",
        "u.circle.fill", "v.circle.fill", "w.circle.fill", "x.circle.fill",
        "y.circle.fill", "z.circle.fill"
    ]
    
    enum IconDomain: String, CaseIterable, Identifiable {
        case all = "All"
        case food = "Food & Drink"
        case finance = "Finance"
        case transport = "Transport"
        case home = "Home"
        case shopping = "Shopping"
        case health = "Health"
        case media = "Media"
        case tech = "Tech"
        case nature = "Nature"
        case work = "Work"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .all: return "sparkles"
            case .food: return "fork.knife"
            case .finance: return "creditcard.fill"
            case .transport: return "car.fill"
            case .home: return "house.fill"
            case .shopping: return "bag.fill"
            case .health: return "heart.fill"
            case .media: return "tv.fill"
            case .tech: return "laptopcomputer"
            case .nature: return "leaf.fill"
            case .work: return "briefcase.fill"
            }
        }
    }
    
    @State private var selectedDomain: IconDomain = .all
    
    private var domainFilteredDefaultSymbols: [String] {
        switch selectedDomain {
        case .all:
            return defaultSymbols
        case .food:
            return ["cart.fill", "fork.knife", "takeoutbag.and.cup.and.straw.fill", "cup.and.saucer.fill", "mug.fill", "wineglass.fill", "waterbottle.fill", "birthday.cake.fill", "frying.pan.fill", "soup.fill"]
        case .finance:
            return ["dollarsign.circle.fill", "indianrupeesign.circle.fill", "sterlingsign.circle.fill", "eurosign.circle.fill", "yensign.circle.fill", "creditcard.fill", "banknote.fill", "wallet.pass.fill", "chart.bar.fill", "chart.pie.fill", "chart.line.uptrend.xyaxis", "percent", "building.columns.fill"]
        case .transport:
            return ["car.fill", "car.side.fill", "bus.fill", "tram.fill", "ferry.fill", "bicycle", "scooter", "fuelpump.fill", "airplane", "airplane.departure", "airplane.arrival"]
        case .home:
            return ["house.fill", "bolt.fill", "drop.fill", "wifi", "lightbulb.fill", "lamp.desk.fill", "bed.double.fill", "sofa.fill", "bathtub.fill", "washer.fill", "refrigerator.fill", "fan.fill"]
        case .shopping:
            return ["bag.fill", "tag.fill", "gift.fill", "gift.circle.fill", "shippingbox.fill", "tshirt.fill", "scissors", "comb.fill", "key.fill", "lock.fill", "ticket.fill", "crown.fill", "trophy.fill", "medal.fill"]
        case .health:
            return ["heart.fill", "heart.circle.fill", "pills.fill", "cross.case.fill", "bandage.fill", "dumbbell.fill", "figure.run", "figure.walk", "figure.strengthtraining.traditional", "figure.yoga"]
        case .media:
            return ["tv.fill", "gamecontroller.fill", "music.note", "headphones", "play.rectangle.fill", "film.fill", "theatermasks.fill", "camera.fill", "photo.fill", "book.fill", "text.book.closed.fill"]
        case .tech:
            return ["desktopcomputer", "laptopcomputer", "iphone", "ipad", "printer.fill", "display", "externaldrive.fill", "cpu.fill"]
        case .nature:
            return ["leaf.fill", "tree.fill", "cloud.rain.fill", "sun.max.fill", "moon.fill", "snowflake", "flame.fill", "pawprint.fill"]
        case .work:
            return ["graduationcap.fill", "briefcase.fill", "briefcase.circle.fill", "hammer.fill", "wrench.and.screwdriver.fill", "gearshape.2.fill", "pencil", "paintbrush.fill"]
        }
    }
    
    private var activeSymbols: [String] {
        let list: [String]
        if selectedTab == .defaults {
            list = searchText.isEmpty ? domainFilteredDefaultSymbols : defaultSymbols
        } else {
            list = brandSymbols
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return list
        }
        return list.filter { $0.lowercased().contains(query) }
    }
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Header: Close & Centered Title
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                
                // 2. Top Search Bar (Liquid Glass)
                searchCapsule
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // 3. Segmented Tab Switcher (Defaults / Brands)
                segmentedTabControl
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // 4. Horizontal Domain Category Filter Chips (when on Defaults & not searching)
                if selectedTab == .defaults && searchText.isEmpty {
                    domainFilterChips
                        .padding(.bottom, 12)
                }
                
                // 5. Grid Content Scroll
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
                        if showPhotoOption && searchText.isEmpty {
                            photoOptionMenu
                        }
                        
                        ForEach(activeSymbols, id: \.self) { sym in
                            let isSelected = selectedSymbol == sym
                            
                            Button {
                                selectedSymbol = sym
                                onIconSelected?(sym)
                                HapticsManager.shared.trigger(.selection)
                                dismiss()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(isSelected ? SpendyColors.primaryBlue : SpendyColors.cardBackgroundSecondary)
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
                                    
                                    Image(systemName: cleanSymbolName(sym))
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(
                                            isSelected
                                                ? Color.white
                                                : SpendyColors.textPrimary
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 36)
                }
            }
        }
        .presentationBackground(SpendyColors.appBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
    }
    
    // MARK: - Header
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
                        morphID: "closeButton",
                        namespace: iconSheetNamespace
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Top Search Bar
    private var searchCapsule: some View {
        HStack(spacing: 10) {
            Image(systemName: SFIcons.search)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            TextField("Search icons", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !searchText.isEmpty {
                Button {
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
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
    }
    
    // MARK: - Tab Switcher (Defaults / Brands)
    private var segmentedTabControl: some View {
        GlassSegmentedPicker(
            selection: $selectedTab,
            items: IconTab.allCases,
            titleFor: { $0.rawValue },
            iconFor: { tab in
                tab == .defaults ? "circle.grid.2x2.fill" : "applelogo"
            }
        )
    }
    
    // MARK: - Domain Filter Chips
    private var domainFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(IconDomain.allCases) { domain in
                    let isSelected = selectedDomain == domain
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedDomain = domain
                        }
                        HapticsManager.shared.trigger(.selection)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: domain.icon)
                                .font(.system(size: 11, weight: .bold))
                            
                            Text(domain.rawValue)
                                .font(.system(size: 12, weight: isSelected ? .bold : .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .foregroundStyle(isSelected ? Color.white : SpendyColors.textSecondary)
                        .background {
                            Capsule()
                                .fill(isSelected ? SpendyColors.primaryBlue : SpendyColors.cardBackgroundSecondary)
                                .overlay {
                                    if !isSelected {
                                        Capsule().stroke(SpendyColors.separator, lineWidth: 0.8)
                                    }
                                }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Photo Option Menu
    private var photoOptionMenu: some View {
        Menu {
            Button(action: {
                HapticsManager.shared.trigger(.selection)
                onPhotoLibrarySelected?()
            }) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(action: {
                    HapticsManager.shared.trigger(.selection)
                    onCameraSelected?()
                }) {
                    Label("Take Photo", systemImage: "camera")
                }
            }
            
            if isPhotoSet {
                Button(role: .destructive, action: {
                    HapticsManager.shared.trigger(.warning)
                    onRemovePhotoSelected?()
                }) {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(SpendyColors.cardBackgroundSecondary)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle().stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
    
    // Helper to translate mock names to correct iOS System icons if needed
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
