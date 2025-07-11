import SwiftUI
import WidgetKit

struct TotalSpendingCardView: View {
	let expenses: [Expense]
	let monthlyBudget: Double
	let currencySymbol: String
	let budgetTrackingEnabled: Bool

	var body: some View {
		let amountSpent = expenses.reduce(0) { $0 + $1.amount }

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


