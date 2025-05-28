import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
	@EnvironmentObject var store: ExpenseStore
	
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
		
		var csvText = "Date,Time,Name,Amount,Category,Details,Rating,Note,IsRecurring,ParentRecurringID\n"
		
		for expense in store.expenses {
			let date = DateFormatter.m0neeCSV.string(from: expense.date)
			let time = DateFormatter.m0neeTimeOnly.string(from: expense.date)
			let name = escape(expense.name)
			let amount = String(format: "%.2f", expense.amount)
			let category = escape(expense.category)
			let details = escape(expense.details ?? "")
			let rating = expense.rating.map { "\($0)" } ?? ""
			let note = escape(expense.memo ?? "")
			let isRecurring = expense.isRecurring ? "Yes" : "No"
			let parentRecurringID = expense.parentRecurringID?.uuidString ?? ""
			csvText += "\(date),\(time),\(name),\(amount),\(category),\(details),\(rating),\(note),\(isRecurring),\(parentRecurringID)\n"
		}

				csvText += "\n# RecurringExpenses\n"
				csvText += "StartDate,Name,Amount,Category,FrequencyType,Interval,Period,SelectedWeekdays,SelectedMonthDays,EndDate,LastGeneratedDate,Note\n"

				for recurring in store.recurringExpenses {
						// Format start date with both date and time (dd-MM-yyyy HH:mm)
						let start = "\(DateFormatter.m0neeCSV.string(from: recurring.startDate)) \(DateFormatter.m0neeTimeOnly.string(from: recurring.startDate))"
						let name = escape(recurring.name)
						let amount = String(format: "%.2f", recurring.amount)
						let category = escape(recurring.category)
						let cycle = escape(recurring.recurrenceRule.frequencyType.rawValue)
						let interval = "\(recurring.recurrenceRule.interval)"
						let period = recurring.recurrenceRule.period.rawValue
						let selectedWeekdays = recurring.recurrenceRule.selectedWeekdays?.map { String($0) }.joined(separator: "|") ?? ""
						let selectedMonthDays = recurring.recurrenceRule.selectedMonthDays?.map { String($0) }.joined(separator: "|") ?? ""
						let endDate = recurring.recurrenceRule.endDate != nil ? DateFormatter.m0neeCSV.string(from: recurring.recurrenceRule.endDate!) : ""
						let note = escape(recurring.memo ?? "")
						let lastGenerated = recurring.lastGeneratedDate != nil ? DateFormatter.m0neeCSV.string(from: recurring.lastGeneratedDate!) : ""

						csvText += "\(start),\(name),\(amount),\(category),\(cycle),\(interval),\(period),\(selectedWeekdays),\(selectedMonthDays),\(endDate),\(lastGenerated),\(note)\n"
				}
		
		do {
			try csvText.write(to: path, atomically: true, encoding: .utf8)
			return path
		} catch {
			print("❌ CSV 파일 쓰기 실패: \(error.localizedDescription)")
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
