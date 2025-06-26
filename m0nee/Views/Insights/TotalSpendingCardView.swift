import SwiftUI
import WidgetKit

struct TotalSpendingCardView: View {
	let expenses: [Expense]
	let monthlyBudget: Double
	let currencySymbol: String
	let budgetTrackingEnabled: Bool

	var body: some View {
		let amountSpent = expenses.reduce(0) { $0 + $1.amount }

		let widgetData = TotalSpendingWidgetData(
			amountSpent: amountSpent,
			monthlyBudget: monthlyBudget,
			currencySymbol: currencySymbol,
			budgetTrackingEnabled: budgetTrackingEnabled
		)

		if let sharedDefaults = UserDefaults(suiteName: "group.com.chankim.Monir"),
			 let encoded = try? JSONEncoder().encode(widgetData) {
			sharedDefaults.set(encoded, forKey: "totalSpendingWidgetData")
			WidgetCenter.shared.reloadAllTimelines()
		}

		return VStack {
			Spacer()
			VStack(alignment: .leading) {
				Label("Total Spending", systemImage: "creditcard")
					.font(.headline)
					.padding(.bottom, 4)
				
				if !budgetTrackingEnabled {
					Text("\(currencySymbol)\(String(format: "%.2f", amountSpent))")
						.font(.largeTitle)
						.bold()
						.padding(.top, -8)
				} else {
					Text(String(format: "\(currencySymbol)%.2f / \(currencySymbol)%.2f", amountSpent, monthlyBudget))
						.font(.title2)
						.bold()
					if monthlyBudget == 0 && amountSpent == 0 {
						ProgressView(value: 0, total: 1)
							.accentColor(.gray)
					} else {
						ProgressView(value: amountSpent, total: monthlyBudget)
							.accentColor(amountSpent > monthlyBudget ? .red : .blue)
					}
				}
			}
			Spacer()
		}
	}
}

struct TotalSpendingWidgetData: Codable {
	let amountSpent: Double
	let monthlyBudget: Double
	let currencySymbol: String
	let budgetTrackingEnabled: Bool
}
