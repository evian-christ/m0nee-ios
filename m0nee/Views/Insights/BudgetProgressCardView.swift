import SwiftUI

struct BudgetProgressCardView: View {
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
		let spendingProgress = monthlyBudget > 0 ? totalSpent / monthlyBudget : 0
		
		VStack(alignment: .leading, spacing: 8) {
			Label("Month's Progress", systemImage: "gauge.with.needle")
				.font(.headline)
				.padding(.bottom, 4)
			
			Text(String(format: "£%.2f / £%.2f", totalSpent, monthlyBudget))
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
		.background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
	}
}
