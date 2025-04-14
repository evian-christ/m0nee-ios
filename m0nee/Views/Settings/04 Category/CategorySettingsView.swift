import SwiftUI

struct CategorySettingsView: View {
		@ObservedObject var store: ExpenseStore

		var body: some View {
				Form {
						Section {
								NavigationLink(destination: ManageCategoriesView(store: store)) {
										Text("Manage Categories")
								}
						}
				}
				.navigationTitle("Categories")
				.navigationBarTitleDisplayMode(.inline)
		}
}
