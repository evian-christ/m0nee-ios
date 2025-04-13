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
		Form {
			Section(header: Text("Main Screen Settings")) {
				NavigationLink(destination: {
					Form {
						Picker("Display Mode", selection: $displayMode) {
							Text("Compact").tag("Compact")
							Text("Standard").tag("Standard")
							Text("Detailed").tag("Detailed")
						}
						.pickerStyle(.inline)
					}
					.navigationTitle("Display Mode")
				}) {
					HStack {
						Text("Display Mode")
						Spacer()
						Text(displayMode)
							.foregroundColor(.gray)
					}
				}
				
				Toggle("Group expenses by day", isOn: $groupByDay)
				Toggle("Pin Insight Cards", isOn: $useFixedInsightCards)
			}
			Section(header: Text("Budget")) {
				Toggle("Enable Budget Tracking", isOn: $budgetEnabled)
				if budgetEnabled {
					NavigationLink(destination: BudgetFrequencyView()) {
						Text("Budget Period")
					}
					NavigationLink(destination: MonthlyBudgetView()) {
						HStack {
							Text("\(budgetPeriod) Budget")
							Spacer()
							Text("\(currencySymbol)\(monthlyBudget, specifier: "%.0f")")
								.foregroundColor(.gray)
						}
					}
					if budgetPeriod == "Monthly" {
						Picker("Start day of month", selection: $monthlyStartDay) {
							ForEach(1...31, id: \.self) {
								Text("\($0)")
							}
						}
					}
					if budgetPeriod == "Weekly" {
						Picker("Start day of week", selection: $weeklyStartDay) {
							ForEach(0..<Calendar.current.weekdaySymbols.count, id: \.self) { index in
								Text(Calendar.current.weekdaySymbols[index]).tag(index + 1)
							}
						}
					}
				}
				// Removed category budgeting from main Budget section.
			}
			Section(header: Text("Categories")) {
				NavigationLink(destination: ManageCategoriesView(store: store)) {
					Text("Manage Categories")
				}
			}
			Section(header: Text("Appearance")) {
				Picker("Currency", selection: $currencySymbol) {
					ForEach(currencyOptions, id: \.symbol) { option in
						Text("\(option.symbol) - \(option.country)").tag(option.symbol)
					}
				}
				NavigationLink(destination: {
					Form {
						Picker("Theme", selection: $appearanceMode) {
							Text("Automatic").tag("Automatic")
							Text("Light").tag("Light")
							Text("Dark").tag("Dark")
						}
						.pickerStyle(.inline)
					}
					.navigationTitle("Theme")
				}) {
					HStack {
						Text("Theme")
						Spacer()
						Text(appearanceMode)
							.foregroundColor(.gray)
					}
				}
			}
			Section(header: Text("Storage")) {
				Toggle("Use iCloud for Data", isOn: $useiCloud)
				
				NavigationLink(destination: ExportView().environmentObject(store)) {
						Text("Export Data")
				}
			}
			Section(header: Text("Other")) {
				Button("Restore Settings") {
					showResetAlert = true
				}
				.foregroundColor(.red)
			}
		}
		.onChange(of: useiCloud) { _ in
			store.syncStorageIfNeeded()
		}
		.navigationTitle("Settings")
		.navigationBarTitleDisplayMode(.inline)
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
