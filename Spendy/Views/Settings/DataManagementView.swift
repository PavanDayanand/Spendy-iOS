//
//  DataManagementView.swift
//  Spendy
//
//  Data Backup, Export with Native ShareLink/Transferable, and JSON Import Management
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Spendy Backup Transferable Document (Blueprint §53 & §54)
struct SpendyBackupDocument: Transferable {
    let data: Data
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { doc in
            doc.data
        }
        .suggestedFileName { doc in
            doc.filename
        }
    }
}

struct DataManagementView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var showClearConfirm: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var importAlertMessage: String? = nil
    
    private var backupDocument: SpendyBackupDocument? {
        guard let data = store.exportJSONData() else { return nil }
        let dateStr = Date().formatted(.dateTime.year().month().day())
        return SpendyBackupDocument(data: data, filename: "Spendy_Backup_\(dateStr).json")
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#1C1C1E")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Sticky at top!)
                HStack {
                    GlassCircleButton(
                        icon: "chevron.left",
                        size: 44,
                        iconSize: 15,
                        foregroundColor: SpendyColors.textPrimary,
                        haptic: .selection,
                        accessibilityLabel: "Back"
                    ) {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Data Management")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(SpendyColors.textPrimary)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(Color(hex: "#1C1C1E"))
                .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Backup & Export Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("BACKUP & EXPORT")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundStyle(SpendyColors.textTertiary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                // Native SwiftUI ShareLink (Blueprint §53 & §54)
                                if let doc = backupDocument {
                                    ShareLink(
                                        item: doc,
                                        preview: SharePreview("Spendy Backup JSON", image: Image(systemName: "arrow.down.doc.fill"))
                                    ) {
                                        rowItem(
                                            icon: "square.and.arrow.up.fill",
                                            iconColor: SpendyColors.primaryBlue,
                                            title: "Export JSON Backup",
                                            subtitle: "\(store.transactions.count) transactions, \(store.accounts.count) accounts"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        HapticsManager.shared.trigger(.selection)
                                    })
                                } else {
                                    Button(action: {}) {
                                        rowItem(
                                            icon: "square.and.arrow.up.fill",
                                            iconColor: SpendyColors.textTertiary,
                                            title: "Export JSON Backup",
                                            subtitle: "No data available to export"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(true)
                                }
                                
                                Divider().overlay(SpendyColors.separator)
                                
                                Button(action: {
                                    HapticsManager.shared.trigger(.selection)
                                    showFileImporter = true
                                }) {
                                    rowItem(
                                        icon: "square.and.arrow.down.fill",
                                        iconColor: SpendyColors.incomeGreen,
                                        title: "Import JSON Backup",
                                        subtitle: "Restore from a previous backup file"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .background {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(SpendyColors.cardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                                    }
                            }
                        }
                        
                        // Danger Zone
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DANGER ZONE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.0)
                                .foregroundStyle(SpendyColors.expenseRed.opacity(0.8))
                                .padding(.horizontal, 4)
                            
                            Button(action: {
                                HapticsManager.shared.trigger(.warning)
                                showClearConfirm = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(SpendyColors.expenseRed)
                                        .frame(width: 32, height: 32)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Erase All Data")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(SpendyColors.expenseRed)
                                        Text("Permanently delete all local data")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(SpendyColors.textTertiary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(SpendyColors.cardBackground)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .stroke(SpendyColors.expenseRed.opacity(0.25), lineWidth: 0.8)
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarHidden(true)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let fileURL = urls.first else { return }
                if fileURL.startAccessingSecurityScopedResource() {
                    defer { fileURL.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: fileURL) {
                        let success = store.importJSONData(data: data)
                        importAlertMessage = success ? "Data imported successfully!" : "Failed to parse JSON backup."
                        HapticsManager.shared.trigger(success ? .success : .error)
                    }
                }
            case .failure(let error):
                importAlertMessage = "Import failed: \(error.localizedDescription)"
                HapticsManager.shared.trigger(.error)
            }
        }
        .alert("Backup Status", isPresented: Binding(
            get: { importAlertMessage != nil },
            set: { if !$0 { importAlertMessage = nil } }
        )) {
            Button("OK") {
                HapticsManager.shared.trigger(.selection)
                importAlertMessage = nil
            }
        } message: {
            Text(importAlertMessage ?? "")
        }
        .confirmationDialog(
            "Erase All Local Data?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Erase All Data", role: .destructive) {
                store.eraseAllData()
                HapticsManager.shared.trigger(.warning)
            }
        } message: {
            Text("This will permanently delete all your data, including accounts and subscriptions. This action cannot be undone.")
        }
    }
    
    private func rowItem(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(SpendyColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SpendyColors.textTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(16)
    }
}
