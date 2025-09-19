import SwiftUI
import Foundation

struct MonthlyBudgetView: View {
	@EnvironmentObject var store: ExpenseStore
	@EnvironmentObject var settings: AppSettings

	private var currencySymbol: String {
		CurrencyManager.symbol(for: settings.currencyCode)
	}

	private var totalCategoryBudget: Double {
		settings.categoryBudgets.values.compactMap { Double($0) }.reduce(0, +)
	}

	var body: some View {
		Form {
			Section {
				if settings.budgetByCategory {
					Text("\(currencySymbol)  \(totalCategoryBudget, specifier: "%.0f")")
						.font(.title2)
						.bold()
						.foregroundColor(.gray)
						.opacity(0.6)
						.frame(maxWidth: .infinity, alignment: .leading)
				} else {
					HStack {
						Text(currencySymbol)
						TextField(
							"Budget",
							value: Binding(get: { settings.monthlyBudget }, set: { newValue in
								let positiveValue = abs(newValue)
								let rounded = round(positiveValue)
								if settings.monthlyBudget != rounded {
									settings.monthlyBudget = rounded
								}
							}) ,
							format: .number
						)
						.keyboardType(.decimalPad)
					}
					.font(.title2)
					.bold()
					.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
			Section {
				Toggle(
					"Budget by Category",
					isOn: Binding(get: { settings.budgetByCategory }, set: { newValue in
						settings.budgetByCategory = newValue
						if newValue {
							settings.monthlyBudget = totalCategoryBudget
						}
					})
				)
				if settings.budgetByCategory {
					NavigationLink(destination: CategoryBudgetView()) {
						Text("Category Budgets")
					}
				}
			}
		}
		.navigationTitle("\(settings.budgetPeriod) Budget")
		.navigationBarTitleDisplayMode(.inline)
		.onChange(of: settings.categoryBudgets) { _ in
			if settings.budgetByCategory {
				settings.monthlyBudget = totalCategoryBudget
			}
		}
	}
}
