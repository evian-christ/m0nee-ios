import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
	@EnvironmentObject var store: ExpenseStore
	@EnvironmentObject var settings: AppSettings
	
	var body: some View {
		List {
			Section {
				Button {
					if let url = generateCSV() {
						shareCSV(url: url)
					}
				} label: {
					Text("Export as CSV")
				}
			}
		}
		.navigationTitle("Export Data")
		.navigationBarTitleDisplayMode(.inline)
	}
	
	private func generateCSV() -> URL? {
		let fileName = "Monir_Export.csv"
		let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
		
		var csvText = "# Budgets\n"
		csvText += "ID,Name,GoalAmount,StartDate,EndDate,Notes\n"
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
		for budget in store.budgets {
			let goal = budget.goalAmount.map { String($0) } ?? ""
			let start = budget.startDate.map { dateFormatter.string(from: $0) } ?? ""
			let end = budget.endDate.map { dateFormatter.string(from: $0) } ?? ""
			let notes = escape(budget.notes ?? "")
			csvText += "\(budget.id.uuidString),\(escape(budget.name)),\(goal),\(start),\(end),\(notes)\n"
		}

		csvText += "\n# Expenses\n"
		csvText += "Date,Time,Name,Amount,Category,Details,Rating,Note,IsRecurring,ParentRecurringID,BudgetID\n"
		
		for expense in store.expenses {
			let date = DateFormatter.m0neeCSV.string(from: expense.date)
			let time = DateFormatter.m0neeTimeOnly.string(from: expense.date)
			let name = escape(expense.name)
			let amount = NumberFormatter.currency(for: settings.decimalDisplayMode, currencyCode: settings.currencyCode).string(from: NSNumber(value: expense.amount)) ?? ""
			let category = escape(expense.category)
			let details = escape(expense.details ?? "")
			let rating = expense.rating.map { "\($0)" } ?? ""
			let note = escape(expense.memo ?? "")
			let isRecurring = expense.isRecurring ? "Yes" : "No"
			let parentRecurringID = expense.parentRecurringID?.uuidString ?? ""
			let budgetID = expense.budgetID.uuidString
			csvText += "\(date),\(time),\(name),\(amount),\(category),\(details),\(rating),\(note),\(isRecurring),\(parentRecurringID),\(budgetID)\n"
		}

				csvText += "\n# RecurringExpenses\n"
				csvText += "StartDate,LastGeneratedDate,Name,Amount,Category,Details,Rating,Note,FrequencyType,Interval,Period,SelectedWeekdays,SelectedMonthDays,BudgetID,RecurringExpenseID\n"

				for recurring in store.recurringExpenses {
						// Format start date with both date and time (dd-MM-yyyy HH:mm)
						let start = "\(DateFormatter.m0neeCSV.string(from: recurring.startDate)) \(DateFormatter.m0neeTimeOnly.string(from: recurring.startDate))"
						let name = escape(recurring.name)
						let amount = NumberFormatter.currency(for: settings.decimalDisplayMode, currencyCode: settings.currencyCode).string(from: NSNumber(value: recurring.amount)) ?? ""
						let category = escape(recurring.category)
						let interval = "\(recurring.recurrenceRule.interval)"
						let period = recurring.recurrenceRule.period.rawValue
						let selectedWeekdays = recurring.recurrenceRule.selectedWeekdays?.map { String($0) }.joined(separator: "|") ?? ""
						let selectedMonthDays = recurring.recurrenceRule.selectedMonthDays?.map { String($0) }.joined(separator: "|") ?? ""
						let note = escape(recurring.memo ?? "")
						let frequencyType = recurring.recurrenceRule.frequencyType.rawValue
						let lastGenerated = recurring.lastGeneratedDate != nil
								? "\(DateFormatter.m0neeCSV.string(from: recurring.lastGeneratedDate!)) \(DateFormatter.m0neeTimeOnly.string(from: recurring.lastGeneratedDate!))"
								: ""
						let details = escape(recurring.details ?? "")
					let rating = recurring.rating.map { "\($0)" } ?? ""
					let budgetID = recurring.budgetID.uuidString
					csvText += """
\(start),\(lastGenerated),\(name),\(amount),\(category),\
\(details),\(rating),\(note),\(frequencyType),\(interval),\
\(period),\(selectedWeekdays),\(selectedMonthDays),\(budgetID),\(recurring.id.uuidString)\n
"""
				}
		
		do {
			try csvText.write(to: path, atomically: true, encoding: .utf8)
			return path
		} catch {
			// CSV 파일 쓰기 실패
			return nil
		}
	}
	
	private func shareCSV(url: URL) {
		let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
		if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			 let rootVC = scene.windows.first?.rootViewController {
			rootVC.present(activityVC, animated: true)
		}
	}
	
	private func escape(_ field: String) -> String {
		if field.contains(",") || field.contains("\"") || field.contains("\n") {
			return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
		} else {
			return field
		}
	}
}
