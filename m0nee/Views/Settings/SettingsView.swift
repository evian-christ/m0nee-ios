import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        List {
            Section(header: Text("Configuration")) {
                NavigationLink(destination: ExpenseBudgetSettingsView()) {
                    Label("Expense & Budget", systemImage: "chart.bar.xaxis")
                }
                NavigationLink(destination: AppearanceSettingsView()) {
                    Label("Appearance", systemImage: "wand.and.stars")
                }
                NavigationLink(destination: DataSyncSettingsView()) {
                    Label("Data & Sync", systemImage: "arrow.2.squarepath")
                }
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Notifications", systemImage: "bell.badge.fill")
                }
            }

            Section(header: Text("Support & Pro")) {
                NavigationLink(destination: SubscriptionSettingsView()) {
                    Label("Monir Pro", systemImage: "star.fill")
                }
                NavigationLink(destination: SupportSettingsView()) {
                    Label("Help & Support", systemImage: "questionmark.circle.fill")
                }
            }

            Section {
                VStack(alignment: .center) {
                    Text("Monir v1.4.2")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text("Made with ❤️ in SwiftUI")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
