import SwiftUI

struct BudgetFrequencyView: View {
	@EnvironmentObject var settings: AppSettings

	var body: some View {
		Form {
			Text("Budget period is now fixed to Monthly.")
				.foregroundColor(.secondary)
		}
		.navigationTitle("Budget Period")
	}
}
