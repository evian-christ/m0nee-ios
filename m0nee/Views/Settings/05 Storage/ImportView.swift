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

				let allRows = content.components(separatedBy: "\n").filter { !$0.isEmpty }
				var inRecurringSection = false

				for row in allRows {
						let trimmed = row.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
						// Detect start of recurring section by keyword
						if trimmed.contains("recurringexpenses") {
								inRecurringSection = true
								continue
						}
						// Skip header rows
						if trimmed.contains("date") && trimmed.contains("name") {
								continue
						}

						let columns = splitCSVRow(row)
						// Skip rows with an empty date column
						let dateStringRaw = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
						guard !dateStringRaw.isEmpty else { continue }
						// Regular expenses (before recurring section)
						if !inRecurringSection {
								guard columns.count >= 10 else { continue }
								let dateString = columns[0]
								let timeString = columns[1]
								let date = DateFormatter.dateFromCSV(dateString: dateString, timeString: timeString) ?? Date()
								let name = columns[2]
								let amount = Double(columns[3]) ?? 0
								let category = columns[4]
								let isRecurring = (columns.count > 8)
									? ["true", "yes"].contains(columns[8].trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
									: false
								let parentRecurringID = (columns.count > 9) ? UUID(uuidString: columns[9]) : nil
								let expense = Expense(
										id: UUID(),
										date: date,
										name: name,
										amount: amount,
										category: category,
										details: "",
										rating: nil,
										memo: "",
										isRecurring: isRecurring,
										parentRecurringID: parentRecurringID
								)
								store.expenses.append(expense)
						} else {
								// Recurring expenses
								// Expecting 12 columns as per export:
								// StartDate,Name,Amount,Category,FrequencyType,Interval,Period,SelectedWeekdays,SelectedMonthDays,EndDate,LastGeneratedDate,Note
								guard columns.count >= 12 else { continue }
								let startDate = dateTimeFormatter.date(from: columns[0]) ?? Date()
								let name = columns[1]
								let amount = Double(columns[2]) ?? 0
								let category = columns[3]
								let frequencyType = columns[4] // rawValue for RecurrenceRule.FrequencyType
								let interval = Int(columns[5]) ?? 1
								let period = columns[6] // rawValue for RecurrenceRule.Period
								let weekdays = columns[7].split(separator: "|").compactMap { Int($0) }
								let monthDays = columns[8].split(separator: "|").compactMap { Int($0) }
								let endDate = dateFormatter.date(from: columns[9])
								let lastGen = dateFormatter.date(from: columns[10])
								let memo = columns[11]

								let rule = RecurrenceRule(
										period: RecurrenceRule.Period(rawValue: period) ?? .monthly,
										frequencyType: RecurrenceRule.FrequencyType(rawValue: frequencyType) ?? .everyN,
										interval: interval,
										selectedWeekdays: weekdays,
										selectedMonthDays: monthDays,
										startDate: startDate,
										endDate: endDate
								)
								let recurringID = (columns.count > 12) ? UUID(uuidString: columns[12]) ?? UUID() : UUID()
								let recurring = RecurringExpense(
										id: recurringID,
										name: name,
										amount: amount,
										category: category,
										details: "",
										rating: nil,
										memo: memo,
										startDate: startDate,
										recurrenceRule: rule,
										lastGeneratedDate: lastGen
								)
								store.recurringExpenses.append(recurring)
						}
				}
				// Persist all changes
				store.save()
		}
}
