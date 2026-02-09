import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section(header: Text("Visuals")) {
                NavigationLink(destination: ThemeSelectionView(appearanceMode: settings.binding(\.appearanceMode))) {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text(NSLocalizedString(settings.appearanceMode.capitalized, comment: "Appearance mode name"))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Main Screen Layout")) {
                NavigationLink(destination: StatsCardSettingsView()) {
                    Text("Stats Cards")
                }
                Toggle("Group Expenses by Day", isOn: settings.binding(\.groupByDay))
            }

            Section(header: Text("Language")) {
                Button("Change Language in System Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Private Subviews for Appearance Settings
private struct ThemeSelectionView: View {
    @Binding var appearanceMode: String

    var body: some View {
        Form {
            Section {
                Picker(selection: $appearanceMode, label: EmptyView()) {
                    Text("Automatic").tag("Automatic")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("Theme")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DisplayModeSelectionView: View {
    @Binding var displayMode: String

    var body: some View {
        Form {
            Section {
                Picker(selection: $displayMode, label: EmptyView()) {
                    Text("Compact").tag("Compact")
                    Text("Standard").tag("Standard")
                    Text("Detailed").tag("Detailed")
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("Display Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}
