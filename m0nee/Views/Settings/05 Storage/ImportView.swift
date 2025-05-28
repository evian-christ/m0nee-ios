import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
		@Environment(\.dismiss) private var dismiss
		@EnvironmentObject var store: ExpenseStore
		@State private var showImporter = false
		@State private var importError: String?

		var body: some View {
				VStack(spacing: 24) {
						Text("Import CSV")
								.font(.title)
								.padding(.top)

						Button("Select CSV File") {
								showImporter = true
						}
						.padding()
						.buttonStyle(.borderedProminent)

						if let error = importError {
								Text("Import failed: \(error)")
										.foregroundColor(.red)
										.padding()
						}

						Spacer()
				}
				.padding()
				.fileImporter(
						isPresented: $showImporter,
						allowedContentTypes: [.commaSeparatedText, .plainText],
						allowsMultipleSelection: false
				) { result in
						do {
								guard let selectedFile = try result.get().first else { return }

								let didStartAccessing = selectedFile.startAccessingSecurityScopedResource()
								defer {
										if didStartAccessing {
												selectedFile.stopAccessingSecurityScopedResource()
										}
								}

								let data = try Data(contentsOf: selectedFile)
								if let content = String(data: data, encoding: .utf8) {
										try importCSV(content)
										dismiss()
								} else {
										importError = "Invalid encoding"
								}
						} catch {
								importError = error.localizedDescription
						}
				}
		}

		func importCSV(_ content: String) throws {
				let allRows = content.components(separatedBy: "\n").filter { !$0.isEmpty }
				let rows = allRows.dropFirst()

				for row in rows {
						let columns = row.components(separatedBy: ",")

						// Detect recurring expense format
						/*
						if columns.count >= 7 {
								// Assume recurring expense format
								let name = columns[0]
								let amount = Double(columns[1]) ?? 0
								let category = columns[2]
								let startDate = ISO8601DateFormatter().date(from: columns[3]) ?? Date()
								let frequencyType = columns[4]
								let period = columns[5]
								let weekdays = columns[6].split(separator: "|").compactMap { Int($0) }
								let monthdays = columns.count > 7 ? columns[7].split(separator: "|").compactMap { Int($0) } : []
								let lastGenerated = columns.count > 8 ? ISO8601DateFormatter().date(from: columns[8]) : nil

								let recurring = RecurringExpense(
										id: UUID(),
										name: name,
										amount: amount,
										category: category,
										startDate: startDate,
										frequencyType: frequencyType,
										selectedPeriod: period,
										selectedWeekdays: weekdays,
										selectedMonthDays: monthdays,
										lastGeneratedDate: lastGenerated
								)
								store.recurringExpenses.append(recurring)
						} else 
						*/
						if columns.count >= 4 {
								// Regular expense fallback
								let date = ISO8601DateFormatter().date(from: columns[0]) ?? Date()
								let name = columns[1]
								let amount = Double(columns[2]) ?? 0
								let category = columns[3]

								let expense = Expense(
										id: UUID(),
										date: date,
										name: name,
										amount: amount,
										category: category,
										details: "",
										rating: nil,
										memo: ""
								)
								store.expenses.append(expense)
						}
				}
		}
}
