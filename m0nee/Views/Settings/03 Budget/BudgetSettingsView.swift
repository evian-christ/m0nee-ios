import SwiftUI

struct BudgetSettingsView: View {
		@AppStorage("budgetEnabled") private var budgetEnabled: Bool = true
		@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
		@AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
		@AppStorage("currencyCode") private var currencyCode: String = "GBP"

		private var currencySymbol: String {
				CurrencyManager.symbol(for: currencyCode)
		}
		
		@AppStorage("monthlyStartDay") private var monthlyStartDay: Int = 1
		@AppStorage("weeklyStartDay") private var weeklyStartDay: Int = 1

		var body: some View {
				Form {
						Section {
								Toggle("Enable Budget Tracking", isOn: $budgetEnabled)
						}

						if budgetEnabled {
								Section {
										NavigationLink(destination: BudgetFrequencyView()) {
												HStack {
														Text("Budget Period")
														Spacer()
														Text(budgetPeriod)
																.foregroundColor(.gray)
												}
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
						}
				}
				.navigationTitle("Budget & Planning")
				.navigationBarTitleDisplayMode(.inline)
		}
}
