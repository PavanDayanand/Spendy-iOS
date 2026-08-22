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
    
    @State private var selectedTab: IconTab = .defaults
    @State private var searchText: String = ""
    
    enum IconTab: String, CaseIterable, Identifiable {
        case defaults = "Defaults"
        case brands = "Brands"
        
        var id: String { rawValue }
    }
    
    // SF Symbols library matching your screenshot and designs (with photo.fill and abc removed)
    private let defaultSymbols = [
        "sparkles", "sparkles.rectangle.stack", "alarm.fill",
        "face.smiling.fill", "leaf.fill", "truck.box.fill", "anchor", "apple.logo",
        "backpack.fill", "bag.fill", "dollarsign.circle.fill", "briefcase.fill", "cross.case.fill",
        "fork.knife", "basketball.fill", "balloon.fill", "moon.fill", "bandage.fill",
        "building.columns.fill", "frying.pan.fill", "baseball.fill", "soccerball", "battery.100",
        "sun.max.fill", "pawprint.fill", "mug.fill", "bicycle", "camera.fill",
        "creditcard.fill", "banknote.fill", "hand.thumbsup.fill", "bone.fill", "soup.fill",
        "cart.fill", "gift.fill", "tag.fill", "car.fill", "fuelpump.fill",
        "house.fill", "bolt.fill", "drop.fill", "wifi", "tv.fill",
        "gamecontroller.fill", "heart.fill", "pills.fill", "percent", "book.fill",
        "briefcase.circle.fill", "phone.fill", "envelope.fill", "airplane", "paperplane.fill",
        "star.fill", "bell.fill", "bookmark.fill", "scissors", "comb.fill",
        "paintbrush.fill", "music.note", "pencil", "hammer.fill", "wrench.and.screwdriver.fill"
    ]
    
    private let brandSymbols = [
        "applelogo", "playstation.logo", "xbox.logo", "play.rectangle.fill", "music.note",
        "message.fill", "bubble.left.and.bubble.right.fill", "safari.fill", "cloud.fill", "drop.circle.fill",
        "arrow.triangle.2.circlepath", "paperplane.fill", "bolt.horizontal.fill", "cart.badge.plus", "briefcase.circle.fill",
        "exclamationmark.shield.fill", "g.circle.fill", "f.circle.fill", "m.circle.fill", "n.circle.fill",
        "s.circle.fill", "y.circle.fill", "a.circle.fill", "t.circle.fill", "o.circle.fill", "w.circle.fill",
        "bird.fill", "infinity", "graduationcap.fill", "globe", "cpu.fill",
        "phone.circle.fill", "envelope.circle.fill", "bolt.circle.fill", "person.circle.fill", "heart.circle.fill"
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
            SpendyColors.appBackground
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
                        ForEach(activeSymbols, id: \.self) { sym in
                            Button(action: {
                                selectedSymbol = sym
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
                    colors: [Color.clear, SpendyColors.appBackground.opacity(0.95), SpendyColors.appBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        ZStack {
            HStack {
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
            }
            
            Text("Choose Icon")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(SpendyColors.textPrimary)
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
            Capsule()
                .fill(Color(hex: "#18181A"))
                .overlay {
                    Capsule().stroke(Color.white.opacity(0.08), lineWidth: 0.8)
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
                    Capsule()
                        .fill(Color(hex: "#242426"))
                        .overlay {
                            Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        }
                        .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
                }
            }
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
