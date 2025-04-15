import SwiftUI

struct CategoryBudgetProgressCardView: View {
	let expenses: [Expense]
	let startDate: Date
	let endDate: Date
	let categoryBudgets: [String: Double]
	
	var body: some View {
		let calendar = Calendar.current
		let today = Date()
		let cappedToday = min(max(today, startDate), endDate)
		
		let daysElapsed = calendar.dateComponents([.day], from: startDate, to: cappedToday).day ?? 0
		let totalDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1
		let timeProgress = Double(daysElapsed + 1) / Double(totalDays + 1)
		
		let grouped = Dictionary(grouping: expenses) { $0.category }
		let spendingPerCategory = grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
		
		print("categoryBudgets:", categoryBudgets)
		
		return ScrollView {
			VStack(alignment: .leading, spacing: 8) {
				ForEach(Array(categoryBudgets.keys).sorted(), id: \.self) { category in
					let budget = categoryBudgets[category] ?? 0
					let spent = spendingPerCategory[category] ?? 0
					let progress = budget > 0 ? spent / budget : (spent > 0 ? 1 : 0)
					
					VStack(alignment: .leading, spacing: 4) {
						Text(category)
							.font(.caption)
							.foregroundColor(.secondary)
						
						ProgressView(value: progress)
							.accentColor(progress > timeProgress ? .red : .blue)
					}
				}
			}
		}
		.padding(.horizontal, 8)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
	}
}
