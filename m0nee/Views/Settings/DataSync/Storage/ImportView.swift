import SwiftUI
import UniformTypeIdentifiers

/// Splits a CSV row into columns, respecting quoted fields
private func splitCSVRow(_ row: String) -> [String] {
		var columns: [String] = []
		var current = ""
		var inQuotes = false
		for char in row {
				if char == "\"" {
						inQuotes.toggle()
				} else if char == "," && !inQuotes {
						columns.append(current)
						current = ""
				} else {
						current.append(char)
				}
		}
		columns.append(current)
		return columns
}

struct ImportView: View {
		@Environment(\.dismiss) private var dismiss
		@EnvironmentObject var store: ExpenseStore
		@State private var showImporter = false
		@State private var importError: String?
		@State private var pendingContent: String? = nil
		@State private var showImportOptions = false

		var body: some View {
				Form {
						Button("Select CSV File") {
								showImporter = true
						}

						if let error = importError {
								Text("Import failed: \(error)")
										.foregroundColor(.red)
						}
				}
				.navigationTitle("Import Data")
				.navigationBarTitleDisplayMode(.inline)
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
										pendingContent = content
										showImportOptions = true
								} else {
										importError = "Invalid encoding"
								}
						} catch {
								importError = error.localizedDescription
						}
				}
				.alert("Import Data", isPresented: $showImportOptions) {
					Button("Reset and Import") {
							if let content = pendingContent {
									// Clear existing data
									store.budgets.removeAll()
									store.expenses.removeAll()
									store.recurringExpenses.removeAll()
										// Import new data
										do {
												try importCSV(content)
												dismiss()
										} catch {
												importError = error.localizedDescription
										}
								}
						}
					Button("Append and Import") {
								if let content = pendingContent {
										do {
												try importCSV(content)
												dismiss()
										} catch {
												importError = error.localizedDescription
										}
								}
						}
						Button("Cancel", role: .cancel) {
								pendingContent = nil
						}
				} message: {
						Text("Would you like to reset existing data before importing, or append to existing data?")
				}
		}

		func importCSV(_ content: String) throws {
				let dateFormatter = DateFormatter()
				dateFormatter.dateFormat = "yyyy-MM-dd"
				let dateTimeFormatter = DateFormatter()
				dateTimeFormatter.dateFormat = "dd-MM-yyyy HH:mm"

				let rows = content.components(separatedBy: "\n").filter { !$0.isEmpty }

				enum Section {
						case none
						case budgets
						case expenses
						case recurring
				}

				var section: Section = .none

				for row in rows {
						let trimmed = row.trimmingCharacters(in: .whitespacesAndNewlines)
						let lower = trimmed.lowercased()

						if lower == "# budgets" {
								section = .budgets
								continue
						}
						if lower == "# expenses" {
								section = .expenses
								continue
						}
						if lower == "# recurringexpenses" {
								section = .recurring
								continue
						}

						if trimmed.isEmpty { continue }
						let columns = splitCSVRow(row)

						switch section {
						case .budgets:
								if columns.first?.lowercased() == "id" { continue }
								guard columns.count >= 6 else { continue }
								let id = UUID(uuidString: columns[0]) ?? UUID()
								let name = columns[1]
								let goalAmount = Double(columns[2])
								let startDate = columns[3].isEmpty ? nil : dateFormatter.date(from: columns[3])
								let endDate = columns[4].isEmpty ? nil : dateFormatter.date(from: columns[4])
								let notes = columns[5].isEmpty ? nil : columns[5]
								let budget = Budget(id: id, name: name, goalAmount: goalAmount, startDate: startDate, endDate: endDate, notes: notes)
								if let index = store.budgets.firstIndex(where: { $0.id == id }) {
										store.budgets[index] = budget
								} else {
										store.budgets.append(budget)
								}

						case .expenses:
								if columns.first?.lowercased() == "date" { continue }
								guard columns.count >= 11 else { continue }
								let date = DateFormatter.dateFromCSV(dateString: columns[0], timeString: columns[1]) ?? Date()
								let name = columns[2]
								let amount = Double(columns[3]) ?? 0
								let category = columns[4]
								let details = columns[5]
								let rating = Int(columns[6])
								let memo = columns[7]
								let isRecurring = ["true", "yes"].contains(columns[8].trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
								let parentRecurringID = UUID(uuidString: columns[9])
								let budgetID = UUID(uuidString: columns[10]) ?? store.budgets.first?.id ?? UUID()

								let expense = Expense(
										id: UUID(),
										date: date,
										name: name,
										amount: amount,
										category: category,
										details: details,
										rating: rating,
										memo: memo,
										isRecurring: isRecurring,
										parentRecurringID: parentRecurringID,
										budgetID: budgetID
								)
								store.expenses.append(expense)

						case .recurring:
								if columns.first?.lowercased() == "startdate" { continue }
								guard columns.count >= 15 else { continue }
								let startDate = dateTimeFormatter.date(from: columns[0]) ?? Date()
								let lastGen = dateTimeFormatter.date(from: columns[1])
								let name = columns[2]
								let amount = Double(columns[3]) ?? 0
								let category = columns[4]
								let details = columns[5]
								let rating = Int(columns[6])
								let memo = columns[7]
								let frequencyRaw = columns[8]
								let interval = Int(columns[9]) ?? 1
								let periodRaw = columns[10]
								let weekdays = columns[11].split(separator: "|").compactMap { Int($0) }
								let monthDays = columns[12].split(separator: "|").compactMap { Int($0) }
								let budgetID = UUID(uuidString: columns[13]) ?? store.budgets.first?.id ?? UUID()
								let recurringID = UUID(uuidString: columns[14]) ?? UUID()

								let rule = RecurrenceRule(
										period: RecurrenceRule.Period(rawValue: periodRaw) ?? .monthly,
										frequencyType: RecurrenceRule.FrequencyType(rawValue: frequencyRaw) ?? .everyN,
										interval: interval,
										selectedWeekdays: weekdays,
										selectedMonthDays: monthDays,
										startDate: startDate,
										endDate: nil
								)

								let recurring = RecurringExpense(
										id: recurringID,
										name: name,
										amount: amount,
										category: category,
										details: details,
										rating: rating,
										memo: memo,
										startDate: startDate,
										recurrenceRule: rule,
										lastGeneratedDate: lastGen,
										budgetID: budgetID
								)
								store.recurringExpenses.append(recurring)

						case .none:
								continue
						}
				}

				if store.budgets.isEmpty {
						store.budgets = [Budget(name: "Imported Budget")]
				}

				store.generateExpensesFromRecurringIfNeeded()
		}

}