import SwiftUI

struct BudgetProgressCardView: View {
	@AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
	@AppStorage("enableBudgetTracking") private var budgetTrackingEnabled: Bool = true

	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}

	let expenses: [Expense]
	let startDate: Date
	let endDate: Date
	let monthlyBudget: Double
	
	var body: some View {
		let totalSpent = expenses.reduce(0) { $0 + $1.amount }
		let today = Calendar.current.startOfDay(for: Date())
		let cappedToday = min(max(today, startDate), endDate)
		
		let daysElapsed = Calendar.current.dateComponents([.day], from: startDate, to: cappedToday).day ?? 0
		let totalDays = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
		let timeProgress = Double(daysElapsed + 1) / Double(totalDays + 1)
		let spendingProgress: Double = {
			if monthlyBudget > 0 {
				return totalSpent / monthlyBudget
			} else if totalSpent > 0 {
				return 1.0
			} else {
				return 0.0
			}
		}()
		
		ZStack {
			// Foreground content
			VStack(alignment: .leading, spacing: 8) {
				Label("Spending vs. Time", systemImage: "gauge.with.needle")
					.font(.headline)
					.padding(.bottom, 4)

				Text(String(format: "\(currencySymbol)%.2f / \(currencySymbol)%.2f", totalSpent, monthlyBudget))
					.font(.title3)
					.bold()
					.foregroundColor(spendingProgress > timeProgress ? .red : .primary)

				ProgressView(value: spendingProgress)
					.accentColor(spendingProgress > timeProgress ? .red : .blue)

				Text(String(format: "Time: %.0f%%", timeProgress * 100))
					.font(.subheadline)
					.foregroundColor(.secondary)

				ProgressView(value: timeProgress)
					.accentColor(.gray)
			}
			.padding(.horizontal, 0)
			.frame(maxWidth: .infinity)
			.frame(height: 240)
		}
		
		.cornerRadius(16)
		.frame(height: 240)
	}
}
