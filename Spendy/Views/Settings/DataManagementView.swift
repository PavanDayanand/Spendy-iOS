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

// MARK: - Spendy CSV Transferable Document
struct SpendyCSVDocument: Transferable {
    let data: Data
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { doc in
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
    
    private var csvDocument: SpendyCSVDocument? {
        guard let data = store.exportCSVData() else { return nil }
        let dateStr = Date().formatted(.dateTime.year().month().day())
        return SpendyCSVDocument(data: data, filename: "Spendy_Transactions_\(dateStr).csv")
    }
    
    private var exportSummary: String {
        "\(store.transactions.count) tx · \(store.accounts.count) accounts"
    }
    
    private var csvSummary: String {
        "\(store.transactions.count) rows · Spreadsheet"
    }
    
    var body: some View {
        ZStack {
            SpendyColors.settingsBackground
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    settingsGroup(title: "Backup & Export") {
                        if let csvDoc = csvDocument {
                            ShareLink(
                                item: csvDoc,
                                preview: SharePreview("Spendy CSV Export", image: Image(systemName: "tablecells"))
                            ) {
                                linkRow(icon: "tablecells", title: "Export CSV", value: csvSummary)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                HapticsManager.shared.trigger(.selection)
                            })
                        } else {
                            linkRow(icon: "tablecells", title: "Export CSV", value: "No data")
                                .opacity(0.45)
                        }
                        
                        groupDivider
                        
                        if let doc = backupDocument {
                            ShareLink(
                                item: doc,
                                preview: SharePreview("Spendy backup", image: Image(systemName: "square.and.arrow.up"))
                            ) {
                                linkRow(icon: "square.and.arrow.up", title: "Export JSON", value: exportSummary)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                HapticsManager.shared.trigger(.selection)
                            })
                        } else {
                            linkRow(icon: "square.and.arrow.up", title: "Export JSON", value: "No data")
                                .opacity(0.45)
                        }
                        
                        groupDivider
                        
                        Button {
                            HapticsManager.shared.trigger(.selection)
                            showFileImporter = true
                        } label: {
                            linkRow(icon: "square.and.arrow.down", title: "Import JSON", value: nil)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    settingsGroup(title: "Danger") {
                        Button {
                            HapticsManager.shared.trigger(.warning)
                            showClearConfirm = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "trash")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(SpendyColors.expenseRed)
                                    .frame(width: 28, height: 28)
                                
                                Text("Erase all data")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(SpendyColors.expenseRed)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let fileURL = urls.first else { return }
                let scoped = fileURL.startAccessingSecurityScopedResource()
                defer { if scoped { fileURL.stopAccessingSecurityScopedResource() } }
                do {
                    let data = try Data(contentsOf: fileURL)
                    let success = store.importJSONData(data: data)
                    if success { store.flushPendingSave() }
                    importAlertMessage = success
                        ? (store.persistenceError == nil ? "Data imported successfully!" : "Imported data could not be saved. Export a backup and retry saving.")
                        : "The backup is invalid. Your current data has not been changed."
                    HapticsManager.shared.trigger(success ? .success : .error)
                } catch {
                    importAlertMessage = "Import failed: \(error.localizedDescription)"
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
        .alert("Erase All Local Data?", isPresented: $showClearConfirm) {
            Button("Erase All Data", role: .destructive) {
                store.eraseAllData()
                HapticsManager.shared.trigger(.warning)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your data, including accounts and subscriptions. This action cannot be undone.")
        }
    }
    
    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textSecondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content()
            }
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(SpendyColors.sheetCardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(SpendyColors.separator, lineWidth: 0.8)
                    }
            }
        }
    }
    
    private var groupDivider: some View {
        Divider()
            .overlay(SpendyColors.separator)
            .padding(.leading, 54)
    }
    
    private func linkRow(icon: String, title: String, value: String?) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
                .frame(width: 28, height: 28)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(SpendyColors.textPrimary)
            
            Spacer()
            
            if let value {
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SpendyColors.textSecondary)
                    .lineLimit(1)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SpendyColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}
