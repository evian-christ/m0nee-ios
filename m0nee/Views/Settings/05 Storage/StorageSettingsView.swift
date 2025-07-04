import SwiftUI
import StoreKit

struct StorageSettingsView: View {
		@AppStorage("useiCloud") private var useiCloud: Bool = true
		
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
				if store.isProUser {
					NavigationLink(destination: ExportView().environmentObject(store)) {
						Text("Export Data")
					}
					NavigationLink(destination: ImportView().environmentObject(store)) {
						Text("Import Data")
					}
				} else {
					NavigationLink(destination: ProUpgradeModalView(isPresented: $showUpgradeModal)) {
						HStack {
							Text("Export Data")
							Spacer()
						}
					}
					NavigationLink(destination: ProUpgradeModalView(isPresented: $showUpgradeModal)) {
						HStack {
							Text("Import Data")
							Spacer()
						}
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