//
//  DataManagementView.swift
//  Spendy
//
//  Data Backup, Export, and JSON Import Management
//

import SwiftUI
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(ExpenseStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    
    @State private var showClearConfirm: Bool = false
    @State private var showExportShareSheet: Bool = false
    @State private var exportFileURL: URL? = nil
    @State private var showFileImporter: Bool = false
    @State private var importAlertMessage: String? = nil
    
    var body: some View {
        ZStack {
            SpendyColors.appBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button(action: {
                            HapticsManager.shared.trigger(.selection)
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .nativeLiquidGlassCircle(isInteractive: true)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("Data Management")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Color.clear.frame(width: 44, height: 44)
                    }
                    
                    // Backup & Export Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("BACKUP & EXPORT")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(.white.opacity(0.45))
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            Button(action: { exportData() }) {
                                rowItem(
                                    icon: "square.and.arrow.up.fill",
                                    iconColor: SpendyColors.primaryBlue,
                                    title: "Export JSON Backup",
                                    subtitle: "\(store.transactions.count) transactions, \(store.accounts.count) accounts"
                                )
                            }
                            .buttonStyle(.plain)
                            
                            Divider().overlay(Color.white.opacity(0.06))
                            
                            Button(action: { showFileImporter = true }) {
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
                                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                }
                        }
                    }
                    
                    // Danger Zone
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DANGER ZONE")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(SpendyColors.expenseRed.opacity(0.8))
                            .padding(.horizontal, 4)
                        
                        Button(action: { showClearConfirm = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(SpendyColors.expenseRed)
                                    .frame(width: 32, height: 32)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Erase All Data")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SpendyColors.expenseRed)
                                    Text("Permanently delete local transactions")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.40))
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
                .padding(.top, 10)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showExportShareSheet) {
            if let url = exportFileURL {
                ShareActivityView(activityItems: [url])
            }
        }
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
                    }
                }
            case .failure(let error):
                importAlertMessage = "Import failed: \(error.localizedDescription)"
            }
        }
        .alert("Backup Status", isPresented: Binding(
            get: { importAlertMessage != nil },
            set: { if !$0 { importAlertMessage = nil } }
        )) {
            Button("OK") { importAlertMessage = nil }
        } message: {
            Text(importAlertMessage ?? "")
        }
        .confirmationDialog(
            "Erase All Local Data?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Erase All Data", role: .destructive) {
                store.clearAllTransactions()
                HapticsManager.shared.trigger(.warning)
            }
        } message: {
            Text("This will permanently delete all your transactions. This action cannot be undone.")
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
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.40))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.30))
        }
        .padding(16)
    }
    
    private func exportData() {
        if let data = store.exportJSONData() {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("Spendy_Backup_\(Date().formatted(.dateTime.year().month().day())).json")
            do {
                try data.write(to: fileURL)
                self.exportFileURL = fileURL
                self.showExportShareSheet = true
                HapticsManager.shared.trigger(.success)
            } catch {
                print("Export error: \(error)")
            }
        }
    }
}

// MARK: - Share Sheet Bridge
struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
