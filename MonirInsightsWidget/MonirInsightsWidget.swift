//
//  MonirInsightsWidget.swift
//  MonirInsightsWidget
//
//  Created by Chan on 01/06/2025.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
		func placeholder(in context: Context) -> ExpenseEntry {
				ExpenseEntry(date: Date(), expenses: [])
		}

		func getSnapshot(in context: Context, completion: @escaping (ExpenseEntry) -> Void) {
				completion(ExpenseEntry(date: Date(), expenses: loadExpenses()))
		}

		func getTimeline(in context: Context, completion: @escaping (Timeline<ExpenseEntry>) -> Void) {
				let entry = ExpenseEntry(date: Date(), expenses: loadExpenses())
				let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30)))
				completion(timeline)
		}

		private func loadExpenses() -> [Expense] {
				guard let data = UserDefaults(suiteName: "group.com.yourname.Monir")?.data(forKey: "shared_expenses"),
							let expenses = try? JSONDecoder().decode([Expense].self, from: data) else {
						return []
				}
				return expenses
		}
}

struct ExpenseEntry: TimelineEntry {
		let date: Date
		let expenses: [Expense]
}

struct MonirInsightsWidgetEntryView: View {
		var entry: ExpenseEntry

		var body: some View {
				VStack {
						Text("이번 달 지출")
								.font(.caption)
						Text("\(entry.expenses.count)건")
								.font(.title2)
								.bold()
				}
				.padding()
		}
}

struct MonirInsightsWidget: Widget {
		let kind: String = "MonirInsightsWidget"

		var body: some WidgetConfiguration {
				StaticConfiguration(kind: kind, provider: Provider()) { entry in
						if #available(iOS 17.0, *) {
								MonirInsightsWidgetEntryView(entry: entry)
										.containerBackground(.fill.tertiary, for: .widget)
						} else {
								MonirInsightsWidgetEntryView(entry: entry)
										.padding()
										.background()
						}
				}
				.configurationDisplayName("My Widget")
				.description("This is an example widget.")
		}
}

#Preview(as: .systemSmall) {
		MonirInsightsWidget()
} timeline: {
		ExpenseEntry(date: .now, expenses: [])
}
