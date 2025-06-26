import WidgetKit
import SwiftUI
import Intents

struct TotalSpendingEntry: TimelineEntry {
		let date: Date
		let total: Double
		let budget: Double
		let currencySymbol: String
}

struct TotalSpendingProvider: TimelineProvider {
		func placeholder(in context: Context) -> TotalSpendingEntry {
				TotalSpendingEntry(date: Date(), total: 123.45, budget: 500.0, currencySymbol: "$")
		}

		func getSnapshot(in context: Context, completion: @escaping (TotalSpendingEntry) -> ()) {
				let (amountSpent, monthlyBudget, currencySymbol) = fetchWidgetData()
				let entry = TotalSpendingEntry(date: Date(), total: amountSpent, budget: monthlyBudget, currencySymbol: currencySymbol)
				completion(entry)
		}

		func getTimeline(in context: Context, completion: @escaping (Timeline<TotalSpendingEntry>) -> ()) {
				let (amountSpent, monthlyBudget, currencySymbol) = fetchWidgetData()
				let entry = TotalSpendingEntry(date: Date(), total: amountSpent, budget: monthlyBudget, currencySymbol: currencySymbol)
				let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
				let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
				completion(timeline)
		}

		func fetchWidgetData() -> (Double, Double, String) {
				let defaults = UserDefaults(suiteName: "group.com.chankim.Monir")
				guard let data = defaults?.data(forKey: "totalSpendingWidgetData") else { return (0.0, 0.0, "$") }

				struct WidgetSpendingData: Codable {
						let amountSpent: Double
						let monthlyBudget: Double
						let currencySymbol: String
				}

				if let decoded = try? JSONDecoder().decode(WidgetSpendingData.self, from: data) {
						return (decoded.amountSpent, decoded.monthlyBudget, decoded.currencySymbol)
				}
				return (0.0, 0.0, "$")
		}
}

struct TotalSpendingWidgetEntryView: View {
		var entry: TotalSpendingProvider.Entry

		var body: some View {
				VStack(alignment: .leading, spacing: 8) {
						Text("Total Spending")
								.font(.system(size: 14, weight: .semibold))
								.foregroundColor(.primary)

						Text("\(entry.currencySymbol)\(String(format: "%.2f", entry.total)) / \(entry.currencySymbol)\(String(format: "%.2f", entry.budget))")
								.font(.system(size: 18, weight: .semibold))
								.foregroundColor(.primary)

						ProgressView(value: min(entry.total / max(entry.budget, 1), 1))
								.progressViewStyle(LinearProgressViewStyle(tint: .blue))

						Text("\(Int(entry.budget > 0 ? (entry.total / entry.budget * 100) : 0))% used")
								.font(.system(size: 12, weight: .medium))
								.foregroundColor(.secondary)
				}
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(Color.clear)
				.containerBackground(.clear, for: .widget)
		}
}

struct TotalSpendingWidget: Widget {
		let kind: String = "TotalSpendingWidget"

		var body: some WidgetConfiguration {
				StaticConfiguration(kind: kind, provider: TotalSpendingProvider()) { entry in
						TotalSpendingWidgetEntryView(entry: entry)
				}
				.configurationDisplayName("Total Spending")
				.description("Shows your total expenses.")
				.supportedFamilies([.systemSmall, .systemMedium])
		}
}
