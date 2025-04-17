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
		
		var csvText = "Date,Name,Amount,Category,Details,Rating,Note,IsRecurring\n"
		
		for expense in store.expenses {
			let date = DateFormatter.m0neeCSV.string(from: expense.date)
			let name = escape(expense.name)
			let amount = String(format: "%.2f", expense.amount)
			let category = escape(expense.category)
			let details = escape(expense.details ?? "")
			let rating = expense.rating.map { "\($0)" } ?? ""
			let note = escape(expense.memo ?? "")
			let isRecurring = expense.isRecurring ? "Yes" : "No"
			csvText += "\(date),\(name),\(amount),\(category),\(details),\(rating),\(note),\(isRecurring)\n"
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
