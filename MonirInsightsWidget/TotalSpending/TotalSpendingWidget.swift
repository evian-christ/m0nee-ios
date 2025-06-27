import WidgetKit
import SwiftUI
import Intents

struct TotalSpendingEntry: TimelineEntry {
		let date: Date
		let total: Double
		let budget: Double
		let currencySymbol: String
		let isBudgetTrackingEnabled: Bool
}

struct TotalSpendingProvider: TimelineProvider {
		func placeholder(in context: Context) -> TotalSpendingEntry {
				TotalSpendingEntry(date: Date(), total: 123.45, budget: 500.0, currencySymbol: "$", isBudgetTrackingEnabled: true)
		}

		func getSnapshot(in context: Context, completion: @escaping (TotalSpendingEntry) -> ()) {
				let (amountSpent, monthlyBudget, currencySymbol, budgetTrackingEnabled) = fetchWidgetData()
				let entry = TotalSpendingEntry(date: Date(), total: amountSpent, budget: monthlyBudget, currencySymbol: currencySymbol, isBudgetTrackingEnabled: budgetTrackingEnabled)
				completion(entry)
		}

		func getTimeline(in context: Context, completion: @escaping (Timeline<TotalSpendingEntry>) -> ()) {
				let (amountSpent, monthlyBudget, currencySymbol, budgetTrackingEnabled) = fetchWidgetData()
				let entry = TotalSpendingEntry(date: Date(), total: amountSpent, budget: monthlyBudget, currencySymbol: currencySymbol, isBudgetTrackingEnabled: budgetTrackingEnabled)
				let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
				let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
				completion(timeline)
		}

		func fetchWidgetData() -> (Double, Double, String, Bool) {
				let defaults = UserDefaults(suiteName: "group.com.chankim.Monir")
				// Read the shared AppStorage key "enableBudgetTracking", defaulting to true if missing
				let budgetTrackingEnabled = (defaults?.object(forKey: "budgetTrackingEnabled") as? Bool) ?? true
				guard let data = defaults?.data(forKey: "totalSpendingWidgetData") else { return (0.0, 0.0, "$", budgetTrackingEnabled) }

				struct WidgetSpendingData: Codable {
						let amountSpent: Double
						let monthlyBudget: Double
						let currencySymbol: String
				}

				if let decoded = try? JSONDecoder().decode(WidgetSpendingData.self, from: data) {
						return (decoded.amountSpent, decoded.monthlyBudget, decoded.currencySymbol, budgetTrackingEnabled)
				}
				return (0.0, 0.0, "$", budgetTrackingEnabled)
		}
}

struct TotalSpendingWidgetEntryView: View {
		var entry: TotalSpendingProvider.Entry

		@Environment(\.widgetFamily) var family

		var body: some View {
				switch family {
				case .systemSmall:
						smallView
				case .systemMedium:
						mediumView
				default:
						smallView
				}
		}

		var smallView: some View {
				VStack(alignment: .leading, spacing: 8) {
						Text("Spent so far")
								.font(.system(size: 12, weight: .medium))
								.foregroundColor(.primary)

						Text("\(entry.currencySymbol)\(String(format: "%.2f", entry.total))")
								.font(.system(size: 18, weight: .semibold))
								.foregroundColor(.primary)

						if entry.isBudgetTrackingEnabled {
								ProgressView(value: min(entry.total / max(entry.budget, 1), 1))
										.progressViewStyle(LinearProgressViewStyle(tint: .blue))
						}
				}
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(Color.clear)
				.containerBackground(.clear, for: .widget)
		}

		var mediumView: some View {
				VStack(alignment: .leading, spacing: 8) {
						Text("Spent so far")
								.font(.system(size: 14, weight: .semibold))
								.foregroundColor(.primary)

						if entry.isBudgetTrackingEnabled {
								Text("\(entry.currencySymbol)\(String(format: "%.2f", entry.total)) / \(entry.currencySymbol)\(String(format: "%.2f", entry.budget))")
										.font(.system(size: 18, weight: .semibold))
										.foregroundColor(.primary)

								ProgressView(value: min(entry.total / max(entry.budget, 1), 1))
										.progressViewStyle(LinearProgressViewStyle(tint: .blue))

								Text("\(Int(entry.budget > 0 ? (entry.total / entry.budget * 100) : 0))% used")
										.font(.system(size: 12, weight: .medium))
										.foregroundColor(.secondary)
						} else {
								Text("\(entry.currencySymbol)\(String(format: "%.2f", entry.total))")
										.font(.system(size: 18, weight: .semibold))
										.foregroundColor(.primary)
						}
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
