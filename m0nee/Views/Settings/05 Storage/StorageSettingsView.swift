import SwiftUI
import StoreKit

struct StorageSettingsView: View {
		@AppStorage("useiCloud") private var useiCloud: Bool = true
		@AppStorage("isProUser") private var isProUser: Bool = false
		@ObservedObject var store: ExpenseStore
		@State private var showUpgradeModal = false

		var body: some View {
				Form {
						Section(header: Text("iCloud")) {
								Toggle("Use iCloud for Data", isOn: $useiCloud)
										.onChange(of: useiCloud) { _ in
												store.syncStorageIfNeeded()
										}
						}

						Section(header: Text("Export & Import")) {
								if isProUser {
										NavigationLink(destination: ExportView().environmentObject(store)) {
												Text("Export Data")
										}
										NavigationLink(destination: ImportView().environmentObject(store)) {
												Text("Import Data")
										}
								} else {
										Button("Export Data") {
												showUpgradeModal = true
										}
										Button("Import Data") {
												showUpgradeModal = true
										}
								}
						}
				}
				.sheet(isPresented: $showUpgradeModal) {
						ProUpgradeModalView(isPresented: $showUpgradeModal)
				}
				.navigationTitle("Storage & Export")
				.navigationBarTitleDisplayMode(.inline)
		}
}
