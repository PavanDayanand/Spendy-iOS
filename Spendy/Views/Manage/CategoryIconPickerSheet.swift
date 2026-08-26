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
    
    private var activeSymbols: [String] {
        let list = selectedTab == .defaults ? defaultSymbols : brandSymbols
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            return list
        }
        return list.filter { $0.lowercased().contains(query) }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header: Close, Title
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Defaults / Brands pill-style segmented switcher
                segmentedTabControl
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                
                // Grid Content Scroll
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 5), spacing: 14) {
                        if showPhotoOption && searchText.isEmpty {
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
                                        .fill(Color(hex: "#1C1C1E"))
                                        .frame(width: 52, height: 52)
                                        .overlay {
                                            Circle().stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        }
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        ForEach(activeSymbols, id: \.self) { sym in
                            Button(action: {
                                selectedSymbol = sym
                                onIconSelected?(sym)
                                HapticsManager.shared.trigger(.selection)
                                dismiss()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(selectedSymbol == sym ? SpendyColors.primaryBlue : Color(hex: "#1C1C1E"))
                                        .frame(width: 52, height: 52)
                                        .overlay {
                                            if selectedSymbol == sym {
                                                Circle()
                                                    .stroke(SpendyColors.textPrimary, lineWidth: 2)
                                            }
                                        }
                                    
                                    Image(systemName: cleanSymbolName(sym))
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(
                                            selectedSymbol == sym
                                                ? Color(uiColor: .dynamic(light: .white, dark: .black))
                                                : .white
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120) // Clearance for search capsule
                }
            }
            
            // Search Input capsule container (Full Width)
            VStack(spacing: 0) {
                searchCapsule
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
        .presentationDragIndicator(.hidden)
    }
    
    // MARK: - Header
    private var headerBar: some View {
        SpendyGlassEffectContainer(spacing: 0) {
            ZStack {
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
                
                Text("Choose Icon")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SpendyColors.textPrimary)
            }
        }
    }
    
    // MARK: - Tab Switcher Pill (Liquid Glass)
    private var segmentedTabControl: some View {
        HStack(spacing: 6) {
            tabButton(tabOption: .defaults, title: "Defaults", icon: "circle.grid.2x2.fill")
            tabButton(tabOption: .brands, title: "Brands", icon: "applelogo")
        }
        .padding(4)
        .frame(height: 44)
        .background {
            if #available(iOS 26, *) {
                Capsule()
                    .fill(Color(hex: "#18181A").opacity(0.7))
                    .glassEffect(.clear.interactive(), in: .capsule)
            } else {
                Capsule()
                    .fill(Color(hex: "#18181A"))
                    .overlay {
                        Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                    }
            }
        }
    }
    
    @ViewBuilder
    private func tabButton(tabOption: IconTab, title: String, icon: String) -> some View {
        let isSelected = selectedTab == tabOption
        
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tabOption
            }
            HapticsManager.shared.trigger(.selection)
        }) {
            HStack(spacing: 8) {
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background {
                if isSelected {
                    if #available(iOS 26, *) {
                        Capsule()
                            .fill(Color(hex: "#242426"))
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .glassEffectID("activeTabPill", in: iconSheetNamespace)
                    } else {
                        Capsule()
                            .fill(Color(hex: "#242426"))
                            .overlay {
                                Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                            }
                            .matchedGeometryEffect(id: "activeTabPill", in: iconSheetNamespace)
                    }
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Floating Search Bar (Liquid Glass)
    private var searchCapsule: some View {
        HStack(spacing: 8) {
            Image(systemName: SFIcons.search)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
            
            TextField("Search icons", text: $searchText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            
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
        .frame(height: 52)
        .nativeLiquidGlassCapsule(isInteractive: true)
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
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
