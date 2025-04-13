import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
		@EnvironmentObject var store: ExpenseStore
		@State private var exportURL: URL?

		var body: some View {
				VStack(spacing: 16) {
						if let exportURL = exportURL {
								ShareLink(item: exportURL, preview: SharePreview("Monir_Export.csv")) {
										Label("Share CSV", systemImage: "square.and.arrow.up")
												.font(.body)
								}
						} else {
								Button(action: {
										exportURL = generateCSV()
								}) {
										Label("Export as CSV", systemImage: "doc.text")
												.font(.body)
								}
						}

						Spacer()
				}
				.padding()
				.navigationTitle("Export Data")
				.navigationBarTitleDisplayMode(.inline)
		}

		private func generateCSV() -> URL? {
				let fileName = "Monir_Export.csv"
				let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

				var csvText = "Date,Name,Amount,Category,Details,Rating\n"

				for expense in store.expenses {
						let date = DateFormatter.m0neeDefault.string(from: expense.date)
						let name = escape(expense.name)
						let amount = String(format: "%.2f", expense.amount)
						let category = escape(expense.category)
						let details = escape(expense.details ?? "")
						let rating = expense.rating.map { "\($0)" } ?? ""
						csvText += "\(date),\(name),\(amount),\(category),\(details),\(rating)\n"
				}

				do {
						try csvText.write(to: path, atomically: true, encoding: .utf8)
						return path
				} catch {
						print("❌ CSV 파일 쓰기 실패: \(error.localizedDescription)")
						return nil
				}
		}

		/// 필드 내 특수문자 처리
		private func escape(_ field: String) -> String {
				if field.contains(",") || field.contains("\"") || field.contains("\n") {
						return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
				} else {
						return field
				}
		}
}
