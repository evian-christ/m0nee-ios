import SwiftUI

struct AdvancedSettingsView: View {
		@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
		@AppStorage("currencySymbol") private var currencySymbol: String = "£"
		@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
		@AppStorage("monthlyStartDay") private var monthlyStartDay: Int = 1
		@AppStorage("weeklyStartDay") private var weeklyStartDay: Int = 1
		@AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
		@AppStorage("budgetEnabled") private var budgetEnabled: Bool = true
		@AppStorage("budgetByCategory") private var budgetByCategory: Bool = false
		@AppStorage("categoryBudgets") private var categoryBudgets: String = ""

		@State private var showResetAlert = false

		var body: some View {
				Form {
						Section(header: Text("Reset")) {
								Button("Restore All Settings") {
										showResetAlert = true
								}
								.foregroundColor(.red)
						}
				}
				.navigationTitle("Advanced")
				.navigationBarTitleDisplayMode(.inline)
				.alert("Restore Settings", isPresented: $showResetAlert) {
						Button("Restore", role: .destructive) {
								restoreDefaults()
						}
						Button("Cancel", role: .cancel) {}
				} message: {
						Text("Are you sure you want to restore all settings to default?")
				}
		}

		private func restoreDefaults() {
				appearanceMode = "Automatic"
				currencySymbol = "£"
				budgetPeriod = "Monthly"
				monthlyStartDay = 1
				weeklyStartDay = 1
				monthlyBudget = 0
				budgetEnabled = true
				budgetByCategory = false
				categoryBudgets = ""
		}
}
