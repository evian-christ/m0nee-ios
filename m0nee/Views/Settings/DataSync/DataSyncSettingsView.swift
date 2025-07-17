import SwiftUI

struct DataSyncSettingsView: View {
    @ObservedObject var store: ExpenseStore
    @State private var showProUpgradeSheet = false
    @State private var showResetAlert = false
    @State private var showFullResetAlert = false

    @AppStorage("useiCloud") private var useiCloud: Bool = true

    var body: some View {
        Form {
            Section(header: Text("Sync")) {
                Toggle("Use iCloud", isOn: $useiCloud)
                    .onChange(of: useiCloud) { _ in
                        store.syncStorageIfNeeded()
                    }
            }

            Section(header: Text("Backup & Restore")) {
                if store.isProUser {
                    NavigationLink(destination: ExportView().environmentObject(store)) {
                        Text("Export Data")
                    }
                    NavigationLink(destination: ImportView().environmentObject(store)) {
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
            ProUpgradeModalView(isPresented: $showProUpgradeSheet).environmentObject(store)
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
        // Note: This only resets settings stored in AppStorage.
        // We might need a more robust system for this.
        let defaults = UserDefaults.standard
        let groupDefaults = UserDefaults(suiteName: "group.com.chankim.Monir")

        defaults.removeObject(forKey: "groupByDay")
        defaults.removeObject(forKey: "useFixedInsightCards")
        defaults.removeObject(forKey: "displayMode")
        defaults.removeObject(forKey: "appearanceMode")
        defaults.removeObject(forKey: "useiCloud")
        defaults.removeObject(forKey: "budgetPeriod")
        defaults.removeObject(forKey: "monthlyStartDay")
        defaults.removeObject(forKey: "weeklyStartDay")
        defaults.removeObject(forKey: "monthlyBudget")
        defaults.removeObject(forKey: "budgetEnabled")
        defaults.removeObject(forKey: "budgetByCategory")
        defaults.removeObject(forKey: "categoryBudgets")
        defaults.removeObject(forKey: "decimalDisplayMode")

        groupDefaults?.removeObject(forKey: "showRating")
        groupDefaults?.removeObject(forKey: "currencyCode")
    }

    private func eraseAllData() {
        restoreDefaults()
        store.eraseAllData()
    }
}
