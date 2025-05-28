import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
		@Environment(\.dismiss) private var dismiss
		@EnvironmentObject var store: ExpenseStore
		@State private var showImporter = false
		@State private var importError: String?
		@State private var pendingContent: String? = nil
		@State private var showImportOptions = false

		var body: some View {
				NavigationView {
						Form {
								Button("Select CSV File") {
										showImporter = true
								}

								if let error = importError {
										Text("Import failed: \(error)")
												.foregroundColor(.red)
								}
						}
						.navigationTitle("Import CSV")
				}
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

				let allRows = content.components(separatedBy: "\n").filter { !$0.isEmpty }

				for row in allRows {
						let trimmedLowercasedRow = row.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
						if trimmedLowercasedRow.hasPrefix("# recurringexpenses") {
								break
						}

						// Skip header row that might be duplicated mid-file
						if trimmedLowercasedRow.contains("date") && trimmedLowercasedRow.contains("name") {
								continue
						}

						let columns = row.components(separatedBy: ",")
						let dateStringRaw = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
						guard !dateStringRaw.isEmpty else { continue }
						if columns.count >= 6 {
								let timeString = columns[1]
								let date = DateFormatter.dateFromCSV(dateString: dateStringRaw, timeString: timeString) ?? Date()
								let name = columns[2]
								let amount = Double(columns[3]) ?? 0
								let category = columns[4]

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
				// Persist imported expenses
				store.save()
		}
}
