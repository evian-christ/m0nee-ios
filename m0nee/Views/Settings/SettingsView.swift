import SwiftUI

struct SettingsView: View {
	@StateObject var store = ExpenseStore()
	
	var body: some View {
		List {
			Section {
				NavigationLink(destination: GeneralSettingsView()) {
					Label("General", systemImage: "gearshape")
						.frame(minHeight: 44)
				}
				
				NavigationLink(destination: AppearanceSettingsView()) {
					Label("Appearance", systemImage: "paintbrush")
						.frame(minHeight: 44)
				}
				
				NavigationLink(destination: BudgetSettingsView()) {
					Label("Budget", systemImage: "chart.pie.fill")
						.frame(minHeight: 44)
				}
				
				NavigationLink(destination: CategorySettingsView(store: store)) {
					Label("Categories", systemImage: "folder")
						.frame(minHeight: 44)
				}
				
				NavigationLink(destination: StorageSettingsView(store: store)) {
					Label("Storage", systemImage: "externaldrive")
						.frame(minHeight: 44)
				}
			}
			
			Section {
				VStack(alignment: .center) {
					Text("Monir v1.0.0")
						.font(.footnote)
						.foregroundColor(.gray)
					Text("Made with ❤️ in SwiftUI")
						.font(.caption2)
						.foregroundColor(.secondary)
				}
				.frame(maxWidth: .infinity)
			}
		}
		.navigationTitle("Settings")
		.navigationBarTitleDisplayMode(.inline)
	}
}
