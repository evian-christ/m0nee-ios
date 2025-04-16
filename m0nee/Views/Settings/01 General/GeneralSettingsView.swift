import SwiftUI

struct GeneralSettingsView: View {
	@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
	@AppStorage("currencySymbol") private var currencySymbol: String = "£"
	@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
	@AppStorage("monthlyStartDay") private var monthlyStartDay: Int = 1
	@AppStorage("weeklyStartDay") private var weeklyStartDay: Int = 1
	@AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
	@AppStorage("budgetEnabled") private var budgetEnabled: Bool = true
	@AppStorage("budgetByCategory") private var budgetByCategory: Bool = false
	@AppStorage("categoryBudgets") private var categoryBudgets: String = ""
	@AppStorage("groupByDay") private var groupByDay: Bool = false
	@AppStorage("showRating") private var showRating: Bool = true
	@AppStorage("useFixedInsightCards") private var useFixedInsightCards: Bool = true
	
	@State private var showResetAlert = false
	@State private var showFullResetAlert = false
	
	@ObservedObject var store: ExpenseStore
	
	var body: some View {
		Form {
			Section(header: Text("Main screen")) {
				Toggle("Group expenses by day", isOn: $groupByDay)
				Toggle("Pin Insight Cards", isOn: $useFixedInsightCards)
			}
			
			Section(header: Text("Expense")) {
				Toggle("Enable Ratings", isOn: $showRating)
				NavigationLink("Recurring Expenses") {
					RecurringSettingsView()
				}
			}
			
			Section(header: Text("Reset")) {
				Button("Restore All Settings") {
					showResetAlert = true
				}
				.foregroundColor(.red)
				
				Button("Erase All Settings & Data") {
					showFullResetAlert = true
				}
				.foregroundColor(.red)
			}
		}
		.navigationTitle("General")
		.navigationBarTitleDisplayMode(.inline)
		.alert("Restore Settings", isPresented: $showResetAlert) {
			Button("Restore", role: .destructive) {
				restoreDefaults()
			}
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("Are you sure you want to restore all settings to default?")
		}
		.alert("Erase Everything", isPresented: $showFullResetAlert) {
			Button("Erase", role: .destructive) {
				eraseAllData()
			}
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("This will delete all expenses and reset all settings and categories to default. This action cannot be undone.")
		}
	}
	
	private func restoreDefaults() {
		appearanceMode = "Automatic"
		currencySymbol = "$"
		budgetPeriod = "Monthly"
		monthlyStartDay = 1
		weeklyStartDay = 1
		monthlyBudget = 0
		budgetEnabled = true
		budgetByCategory = false
		categoryBudgets = ""
	}
	
	private func eraseAllData() {
		restoreDefaults()
		store.eraseAllData()
	}
}
