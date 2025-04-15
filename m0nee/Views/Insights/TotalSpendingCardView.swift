import SwiftUI

struct TotalSpendingCardView: View {
	let expenses: [Expense]
	let monthlyBudget: Double
	let currencySymbol: String
	let budgetTrackingEnabled: Bool

	var body: some View {
		let amountSpent = expenses.reduce(0) { $0 + $1.amount }
		print("🔍 budgetTrackingEnabled:", budgetTrackingEnabled)
		print("🔍 monthlyBudget:", monthlyBudget)

		return VStack(alignment: .leading) {
			if !budgetTrackingEnabled {
				Text("\(currencySymbol)\(String(format: "%.2f", amountSpent))")
					.font(.largeTitle)
					.bold()
					.padding(.top, -8)
			} else {
				Text(String(format: "\(currencySymbol)%.2f / \(currencySymbol)%.2f", amountSpent, monthlyBudget))
					.font(.title2)
					.bold()
				ProgressView(value: amountSpent, total: monthlyBudget)
					.accentColor(amountSpent > monthlyBudget ? .red : .blue)
			}
		}
	}
}
