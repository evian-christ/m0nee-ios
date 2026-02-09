import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        List {
            Section(header: Text("Configuration")) {
                NavigationLink(destination: ExpenseBudgetSettingsView()) {
                    Label {
                        Text("Expense & Budget")
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                                .frame(width: 28, height: 28)
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
                NavigationLink(destination: AppearanceSettingsView()) {
                    Label {
                        Text("Appearance")
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.purple)
                                .frame(width: 28, height: 28)
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
                NavigationLink(destination: DataSyncSettingsView()) {
                    Label {
                        Text("Data & Sync")
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green)
                                .frame(width: 28, height: 28)
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
                NavigationLink(destination: NotificationSettingsView()) {
                    Label {
                        Text("Notifications")
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 28, height: 28)
                            Image(systemName: "bell.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
            }

            Section(header: Text("Support & Pro")) {
                NavigationLink(destination: SubscriptionSettingsView()) {
                    Label {
                        Text("Monir Pro")
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange)
                                .frame(width: 28, height: 28)
                            Image(systemName: "star.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
                NavigationLink(destination: SupportSettingsView()) {
                    Label {
                        Text("Help & Support")
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray)
                                .frame(width: 28, height: 28)
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                }
            }

            Section {
                VStack(alignment: .center) {
                    Text("Monir v2.0.0")
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
