import SwiftUI

struct DataSyncSettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @EnvironmentObject var settings: AppSettings
    @State private var showProUpgradeSheet = false
    @State private var showResetAlert = false
    @State private var showFullResetAlert = false

    var body: some View {
        Form {
            Section(header: Text("Sync")) {
                Toggle("Use iCloud", isOn: Binding(get: { settings.useICloud }, set: { newValue in
                        settings.useICloud = newValue
                    }))
                    .onChange(of: settings.useICloud) { _ in
                        store.syncStorageIfNeeded()
                    }
            }

            Section(header: Text("Backup & Restore")) {
                if store.isProUser {
                    NavigationLink(destination: ExportView()) {
                        Text("Export Data")
                    }
                    NavigationLink(destination: ImportView()) {
                        Text("Import Data")
                    }
                } else {
                    Button(action: { showProUpgradeSheet = true }) {
                        HStack {
                            Text("Export & Import Data")
                            Spacer()
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }

            Section(header: Text("Reset")) {
                Button("Restore All Settings", role: .destructive) {
                    showResetAlert = true
                }
                Button("Erase All Data", role: .destructive) {
                    showFullResetAlert = true
                }
            }
        }
        .navigationTitle("Data & Sync")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProUpgradeSheet) {
            ProUpgradeModalView(isPresented: $showProUpgradeSheet)
        }
        .alert("Restore All Settings", isPresented: $showResetAlert) {
            Button("Restore", role: .destructive) {
                restoreDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to restore all settings to their default values?")
        }
        .alert("Erase All Data", isPresented: $showFullResetAlert) {
            Button("Erase", role: .destructive) {
                eraseAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all of your expenses, categories, and recurring rules. This action cannot be undone.")
        }
    }

    private func restoreDefaults() {
        settings.resetSettings()
    }

    private func eraseAllData() {
        restoreDefaults()
        store.eraseAllData()
    }
}
