import SwiftUI

struct RecurringSettingsView: View {
	@EnvironmentObject var store: ExpenseStore
	@AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}
	
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
						HStack(spacing: 12) {
							// Category icon on the left
							if let item = store.categories.first(where: { $0.name == expense.category }) {
								ZStack {
									Circle()
										.fill(item.color.color)
										.frame(width: 32, height: 32)
									Image(systemName: item.symbol)
										.font(.system(size: 16))
										.foregroundColor(.white)
								}
							}
							
							// Title and rule
							VStack(alignment: .leading, spacing: 2) {
								Text(expense.name)
									.font(.headline)
									.foregroundColor(.primary)
								Text(RecurringSettingsView.ruleDescription(expense.recurrenceRule))
									.font(.caption2)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							// Amount and chevron
							Text("\(currencySymbol)\(expense.amount, specifier: "%.2f")")
								.font(.system(size: 17, weight: .bold))
								.foregroundColor(.primary)
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
		@AppStorage("currencyCode") private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
		@Environment(\.colorScheme) private var colorScheme
	@Environment(\.dismiss) private var dismiss
	@State private var showingDeleteDialog = false
		
		private var categoryItem: CategoryItem? {
			store.categories.first { $0.name == recurring.category }
		}
		private var categoryColor: Color {
			categoryItem?.color.color ?? .gray
		}
		private var currencySymbol: String {
			CurrencyManager.symbol(for: currencyCode)
		}
		
		var body: some View {
			ScrollView {
				VStack(spacing: 20) {
					// Header card
					HStack(spacing: 16) {
						// Category icon on the left
						ZStack {
							Circle()
								.fill(categoryColor)
								.frame(width: 60, height: 60)
							Image(systemName: categoryItem?.symbol ?? "questionmark")
								.font(.system(size: 24, weight: .medium))
								.foregroundColor(.white)
						}
						// Name and category
						VStack(alignment: .leading, spacing: 4) {
							Text(recurring.name)
								.font(.title2.bold())
							Text(recurring.category)
								.font(.subheadline)
								.foregroundColor(.secondary)
						}
						Spacer()
						// Amount on the right
						Text("\(currencySymbol)\(recurring.amount, specifier: "%.2f")")
							.font(.title3.bold())
					}
					.padding()
					.background(Color(.systemGray6))
					.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
					.padding(.horizontal)
					
					// Details section
					VStack(alignment: .leading, spacing: 12) {
						Text("Recurrence Details")
							.font(.headline)
						
						HStack {
							Label("Starts on", systemImage: "calendar")
							Spacer()
							Text(recurring.startDate.formatted(date: .long, time: .omitted))
						}
						
						HStack {
							Label("Frequency", systemImage: "repeat")
							Spacer()
							Text(RecurringSettingsView.ruleDescription(recurring.recurrenceRule))
						}
						
						if let nextDate = store.nextOccurrence(for: recurring) {
							HStack {
								Label("Next", systemImage: "arrow.forward")
								Spacer()
								Text(nextDate.formatted(date: .long, time: .omitted))
									.foregroundColor(.accentColor)
							}
						}
					}
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.fill(Color(.systemBackground))
							.shadow(
								color: colorScheme == .dark
								? Color.white.opacity(0.3)
								: Color.primary.opacity(0.05),
								radius: 4, x: 0, y: 2
							)
					)
					.padding(.horizontal)
					
					Button(role: .destructive) {
						showingDeleteDialog = true
					} label: {
						Text("Delete")
							.frame(maxWidth: .infinity)
					}
					.confirmationDialog("Delete this recurring rule?", isPresented: $showingDeleteDialog, titleVisibility: .visible) {
						Button("Delete recurring rule only", role: .destructive) {
							store.removeRecurringExpense(id: recurring.id)
							dismiss()
						}
						Button("Delete rule and all related expenses", role: .destructive) {
							store.removeAllExpenses(withParentID: recurring.id)
							store.removeRecurringExpense(id: recurring.id)
							dismiss()
						}
						Button("Cancel", role: .cancel) { }
					}
					.padding()
					
					Spacer()
				}
				.padding(.top)
			}
			.navigationTitle("Details")
			.navigationBarTitleDisplayMode(.inline)
		}
	}
}
