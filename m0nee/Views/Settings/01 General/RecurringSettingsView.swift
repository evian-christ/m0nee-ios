//
//  RecurringSettingsView.swift
//  m0nee
//
//  Created by Chan on 16/04/2025.
//

import SwiftUI

struct RecurringSettingsView: View {
	@EnvironmentObject var store: ExpenseStore

	var body: some View {
		List {
			ForEach(store.recurringExpenses) { expense in
				VStack(alignment: .leading, spacing: 4) {
					Text(expense.name)
						.font(.headline)
					Text("\(expense.amount, specifier: "%.2f") • \(expense.category)")
						.font(.subheadline)
						.foregroundColor(.secondary)
					Text("Starts on \(expense.startDate.formatted(date: .abbreviated, time: .omitted))")
						.font(.caption)
						.foregroundColor(.gray)
					
					if let rule = Optional(expense.recurrenceRule) {
						let description = ruleDescription(rule)
						Text(description)
							.font(.caption2)
							.foregroundColor(.blue)
					}
				}
				.padding(.vertical, 4)
			}
		}
		.navigationTitle("Recurring Expenses")
	}

	private func ruleDescription(_ rule: RecurrenceRule) -> String {
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
				let days = weekdays.sorted().compactMap { $0 >= 1 && $0 <= 7 ? symbols[$0 - 1] : nil }
				if !days.isEmpty {
					components.append(days.joined(separator: ", "))
				}
			}
		case .monthlySelectedDays:
			if let monthDays = rule.selectedMonthDays {
				let sorted = monthDays.sorted().map { "\($0)" }
				components.append("days \(sorted.joined(separator: ", "))")
			}
		}

		return components.joined(separator: ", ")
	}
}
