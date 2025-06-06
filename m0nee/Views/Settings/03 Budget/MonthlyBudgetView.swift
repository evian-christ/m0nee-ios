import SwiftUI
import Foundation

struct MonthlyBudgetView: View {
	@AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
	@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
	@AppStorage("budgetByCategory") private var budgetByCategory: Bool = false
	@AppStorage("currencyCode") private var currencyCode: String = "GBP"
	@ObservedObject var store: ExpenseStore

	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}
	
	@AppStorage("categoryBudgets") private var categoryBudgetsData: Data = Data()

	var totalCategoryBudget: Double {
		if let decoded = try? JSONDecoder().decode([String: String].self, from: categoryBudgetsData) {
			return decoded.values.compactMap { Double($0) }.reduce(0, +)
		}
		return 0
	}
	
	var formattedBudget: String {
		String(format: "\(currencySymbol)%.2f", monthlyBudget)
	}
	
	var body: some View {
		Form {
			Section {
				if budgetByCategory {
					Text("\(currencySymbol)  \(totalCategoryBudget, specifier: "%.0f")")
						.font(.title2)
						.bold()
						.foregroundColor(.gray)
						.opacity(0.6)
						.frame(maxWidth: .infinity, alignment: .leading)
				} else {
					HStack {
						Text(currencySymbol)
						TextField("Budget", value: $monthlyBudget, format: .number)
							.keyboardType(.decimalPad)
							.onChange(of: monthlyBudget) { newValue in
								let positiveValue = abs(newValue)
								let rounded = round(positiveValue)
								if monthlyBudget != rounded {
									monthlyBudget = rounded
								}
							}
					}
					.font(.title2)
					.bold()
					.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
			Section {
				Toggle("Budget by Category", isOn: $budgetByCategory)
				if budgetByCategory {
					NavigationLink(destination: CategoryBudgetView(store: store)) {
						Text("Category Budgets")
					}
				}
			}
		}
		.navigationTitle("\(budgetPeriod) Budget")
		.navigationBarTitleDisplayMode(.inline)
		.onChange(of: budgetByCategory) { newValue in
			if newValue {
				monthlyBudget = totalCategoryBudget
			}
		}
		.onChange(of: categoryBudgetsData) { _ in
			if budgetByCategory {
				monthlyBudget = totalCategoryBudget
			}
		}
	}
}
