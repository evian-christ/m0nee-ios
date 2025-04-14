import SwiftUI

struct StorageSettingsView: View {
		@AppStorage("useiCloud") private var useiCloud: Bool = true
		@ObservedObject var store: ExpenseStore

		var body: some View {
				Form {
						Section(header: Text("iCloud")) {
								Toggle("Use iCloud for Data", isOn: $useiCloud)
										.onChange(of: useiCloud) { _ in
												store.syncStorageIfNeeded()
										}
						}

						Section(header: Text("Export")) {
								NavigationLink(destination: ExportView().environmentObject(store)) {
										Text("Export Data")
								}
						}
				}
				.navigationTitle("Storage & Export")
				.navigationBarTitleDisplayMode(.inline)
		}
}
