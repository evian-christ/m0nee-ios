import SwiftUI

struct ExpenseInputSettingsView: View {
		@AppStorage("groupByDay") private var groupByDay: Bool = false
		@AppStorage("showRating") private var showRating: Bool = true

		var body: some View {
				Form {
						Section(header: Text("Expense Logging")) {
								Toggle("Group expenses by day", isOn: $groupByDay)
								Toggle("Enable Ratings", isOn: $showRating)
						}
				}
				.navigationTitle("Expense Input")
				.navigationBarTitleDisplayMode(.inline)
		}
}
