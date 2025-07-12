import SwiftUI

struct SettingsView: View {
	@StateObject var store = ExpenseStore()
	@State private var showProUpgradeSheet = false
	
	var body: some View {
		List {
			Section(header: Text("General")) {
				NavigationLink(destination: GeneralSettingsView(store: store)) {
					Label("General", systemImage: "gearshape")
				}
				
				NavigationLink(destination: AppearanceSettingsView()) {
					Label("Appearance", systemImage: "paintbrush")
				}
				
				NavigationLink(destination: StorageSettingsView(store: store)) {
					Label("Storage", systemImage: "externaldrive")
				}
			}
			
			Section(header: Text("Usability")) {
				NavigationLink(destination: BudgetSettingsView(store: store)) {
					Label("Budget", systemImage: "chart.pie.fill")
				}
				
				NavigationLink(destination: CategorySettingsView(store: store)) {
					Label("Categories", systemImage: "folder")
				}
				
				if store.isProUser {
					NavigationLink(destination: RecurringSettingsView()) {
						Label("Recurring Expenses", systemImage: "arrow.triangle.2.circlepath")
					}
				} else {
					NavigationLink(destination: ProUpgradeModalView(isPresented: $showProUpgradeSheet)) {
						Label("Recurring Expenses", systemImage: "arrow.triangle.2.circlepath")
					}
				}
			}
			
			Section(header: Text("Misc")) {
				NavigationLink(destination: SubscriptionSettingsView()) {
					Label("Monir Pro", systemImage: "star.fill")
				}
				NavigationLink(destination: SupportSettingsView()) {
					Label("Help & Support", systemImage: "questionmark.circle")
				}
			}
			
			Section {
				VStack(alignment: .center) {
					Text("Monir v1.3.3")
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
		.navigationTitle("settings_title")
		.navigationBarTitleDisplayMode(.inline)
		.sheet(isPresented: $showProUpgradeSheet) {
			ProUpgradeModalView(isPresented: $showProUpgradeSheet)
		}
	}
}
