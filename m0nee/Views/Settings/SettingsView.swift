import SwiftUI

struct SettingsView: View {
	@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
	@AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
	@AppStorage("monthlyStartDay") private var monthlyStartDay: Int = 1
	@AppStorage("categories") private var categories: String = "Food,Transport,Other"
	@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
	@AppStorage("currencySymbol") private var currencySymbol: String = "£"
	@AppStorage("useiCloud") private var useiCloud: Bool = true
	@StateObject var store = ExpenseStore()
	@AppStorage("budgetEnabled") private var budgetEnabled: Bool = true
	@AppStorage("weeklyStartDay") private var weeklyStartDay: Int = 1
	@AppStorage("budgetByCategory") private var budgetByCategory: Bool = false
	@AppStorage("categoryBudgets") private var categoryBudgets: String = ""
	@AppStorage("groupByDay") private var groupByDay: Bool = false
	@AppStorage("showRating") private var showRating: Bool = true
	@AppStorage("simpleMode") private var simpleMode: Bool = false
	@AppStorage("displayMode") private var displayMode: String = "Standard"
	@AppStorage("useFixedInsightCards") private var useFixedInsightCards: Bool = true
	@State private var showResetAlert = false
	
	let currencyOptions: [(symbol: String, country: String)] = [
		("£", "United Kingdom"),
		("$", "United States"),
		("€", "Eurozone"),
		("₩", "South Korea"),
		("¥", "Japan"),
		("₹", "India"),
		("₽", "Russia"),
		("฿", "Thailand"),
		("₫", "Vietnam"),
		("₴", "Ukraine"),
		("₪", "Israel"),
		("₦", "Nigeria"),
		("₲", "Paraguay"),
		("₵", "Ghana")
	]
	
	var categoryList: [String] {
		categories.split(separator: ",").map { String($0) }
	}
	
	func saveCategories(_ updated: [String]) {
		categories = updated.joined(separator: ",")
	}
	
	var body: some View {
		List {
			Section {
				NavigationLink(destination: AppearanceSettingsView()) {
					Label("Appearance", systemImage: "paintbrush")
						.frame(minHeight: 44)
				}

				NavigationLink(destination: ExpenseInputSettingsView()) {
					Label("Expense", systemImage: "square.and.pencil")
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

				NavigationLink(destination: AdvancedSettingsView()) {
					Label("Advanced", systemImage: "gearshape")
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
		.onChange(of: useiCloud) { _ in
			store.syncStorageIfNeeded()
		}
		.alert("Restore Settings", isPresented: $showResetAlert) {
			Button("Restore", role: .destructive) {
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
			Button("Cancel", role: .cancel) {}
		} message: {
			Text("Are you sure you want to restore all settings to default?")
		}
	}
}
