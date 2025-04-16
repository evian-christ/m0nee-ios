import SwiftUI

struct RecurringSettingsView: View {
		@EnvironmentObject var store: ExpenseStore

		var body: some View {
				List {
						if store.recurringExpenses.isEmpty {
								Text("No recurring expenses")
										.foregroundColor(.secondary)
										.frame(maxWidth: .infinity, alignment: .center)
										.padding(.vertical, 16)
						} else {
								ForEach(store.recurringExpenses) { expense in
										NavigationLink {
												RecurringDetailView(recurring: expense)
														.environmentObject(store)
										} label: {
												VStack(alignment: .leading, spacing: 4) {
														Text(expense.name)
																.font(.headline)
														Text("\(expense.amount, specifier: "%.2f") • \(expense.category)")
																.font(.subheadline)
																.foregroundColor(.secondary)
														Text("Starts on \(expense.startDate.formatted(date: .abbreviated, time: .omitted))")
																.font(.caption)
																.foregroundColor(.gray)
														Text(RecurringSettingsView.ruleDescription(expense.recurrenceRule))
																.font(.caption2)
																.foregroundColor(.blue)
												}
												.padding(.vertical, 8)
										}
								}
						}
				}
				.navigationTitle("Recurring Expenses")
		}

		private static func ruleDescription(_ rule: RecurrenceRule) -> String {
				var components: [String] = []

				switch rule.frequencyType {
				case .everyN:
						switch rule.period {
						case .daily:
								components.append("Every \(rule.interval) day\(rule.interval > 1 ? "s" : "")")
						case .weekly:
								components.append("Every \(rule.interval) week\(rule.interval > 1 ? "s" : "")")
						case .monthly:
								components.append("Every \(rule.interval) month\(rule.interval > 1 ? "s" : "")")
						}
				case .weeklySelectedDays:
						if let weekdays = rule.selectedWeekdays {
								let symbols = Calendar.current.shortWeekdaySymbols
								let ranges = formatWeekdayRanges(weekdays, symbols: symbols)
								components.append(contentsOf: ranges)
						}
				case .monthlySelectedDays:
						if let monthDays = rule.selectedMonthDays {
								let days = monthDays.sorted().map(String.init).joined(separator: ", ")
								components.append("days \(days)")
						}
				}
				return components.joined(separator: ", ")
		}

		private static func formatWeekdayRanges(_ days: [Int], symbols: [String]) -> [String] {
				let sortedDays = days.sorted()
				var grouped: [[Int]] = []
				var current: [Int] = []
				for day in sortedDays {
						if current.isEmpty || day == current.last! + 1 {
								current.append(day)
						} else {
								grouped.append(current)
								current = [day]
						}
				}
				if !current.isEmpty { grouped.append(current) }

				return grouped.compactMap { group in
						guard let first = group.first, let last = group.last,
									first >= 1, last <= symbols.count else { return nil }
						let firstName = symbols[first - 1]
						let lastName = symbols[last - 1]
						return group.count == 1 ? firstName : "\(firstName) - \(lastName)"
				}
		}
}

extension RecurringSettingsView {
		struct RecurringDetailView: View {
				let recurring: RecurringExpense
				@EnvironmentObject var store: ExpenseStore

				var body: some View {
						ScrollView {
								VStack(alignment: .leading, spacing: 16) {
										Text(recurring.name)
												.font(.title2.bold())

										HStack(spacing: 8) {
												if let item = store.categories.first(where: { $0.name == recurring.category }) {
														ZStack {
																Circle()
																		.fill(item.color.color)
																		.frame(width: 36, height: 36)
																Image(systemName: item.symbol)
																		.font(.system(size: 16))
																		.foregroundColor(.white)
														}
												}
												Text("\(recurring.amount, specifier: "%.2f")")
														.font(.title3.bold())
										}

										Text("Start Date")
												.font(.headline)
										Text(recurring.startDate.formatted(date: .long, time: .omitted))
												.foregroundColor(.secondary)

										Text("Recurrence Rule")
												.font(.headline)
										Text(RecurringSettingsView.ruleDescription(recurring.recurrenceRule))
												.foregroundColor(.secondary)

										Spacer()
								}
								.padding()
						}
						.navigationTitle("Details")
						.navigationBarTitleDisplayMode(.inline)
				}
		}
}
