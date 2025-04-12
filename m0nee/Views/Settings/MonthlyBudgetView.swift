import SwiftUI

struct MonthlyBudgetView: View {
	@AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
	@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
	@AppStorage("budgetByCategory") private var budgetByCategory: Bool = false
	@AppStorage("currencySymbol") private var currencySymbol: String = "£"
	@AppStorage("categoryBudgets") private var categoryBudgets: String = ""
	
	var totalCategoryBudget: Double {
		categoryBudgets
			.split(separator: ",")
			.compactMap { pair in
				let parts = pair.split(separator: ":")
				return parts.count == 2 ? Double(parts[1]) : nil
			}
			.reduce(0, +)
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
					}
					.font(.title2)
					.bold()
					.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
			Section {
				Toggle("Budget by Category", isOn: $budgetByCategory)
				if budgetByCategory {
					NavigationLink(destination: CategoryBudgetView()) {
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
		.onChange(of: categoryBudgets) { _ in
			if budgetByCategory {
				monthlyBudget = totalCategoryBudget
			}
		}
	}
}
