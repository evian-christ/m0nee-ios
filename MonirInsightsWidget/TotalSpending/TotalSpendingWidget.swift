import WidgetKit
import SwiftUI
import Intents

struct TotalSpendingWidgetData: Codable {
	let amountSpent: Double
	let monthlyBudget: Double
	let currencySymbol: String
	let budgetTrackingEnabled: Bool
}

struct TotalSpendingEntry: TimelineEntry {
		let date: Date
		let total: Double
		let budget: Double
		let currencySymbol: String
		let isBudgetTrackingEnabled: Bool
		let decimalDisplayMode: DecimalDisplayMode
}

struct TotalSpendingProvider: TimelineProvider {
		func placeholder(in context: Context) -> TotalSpendingEntry {
				TotalSpendingEntry(date: Date(), total: 123.45, budget: 500.0, currencySymbol: "$", isBudgetTrackingEnabled: true, decimalDisplayMode: .automatic)
		}

		func getSnapshot(in context: Context, completion: @escaping (TotalSpendingEntry) -> ()) {
				let (amountSpent, monthlyBudget, currencySymbol, budgetTrackingEnabled, decimalDisplayMode) = fetchWidgetData()
				let entry = TotalSpendingEntry(date: Date(), total: amountSpent, budget: monthlyBudget, currencySymbol: currencySymbol, isBudgetTrackingEnabled: budgetTrackingEnabled, decimalDisplayMode: decimalDisplayMode)
				completion(entry)
		}

		func getTimeline(in context: Context, completion: @escaping (Timeline<TotalSpendingEntry>) -> ()) {
				let (amountSpent, monthlyBudget, currencySymbol, budgetTrackingEnabled, decimalDisplayMode) = fetchWidgetData()
				let entry = TotalSpendingEntry(date: Date(), total: amountSpent, budget: monthlyBudget, currencySymbol: currencySymbol, isBudgetTrackingEnabled: budgetTrackingEnabled, decimalDisplayMode: decimalDisplayMode)
				let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
				let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
				completion(timeline)
		}

		func fetchWidgetData() -> (Double, Double, String, Bool, DecimalDisplayMode) {
            if let sharedDefaults = UserDefaults(suiteName: "group.com.chankim.Monir"),
               let data = sharedDefaults.data(forKey: "totalSpendingWidgetData"),
               let decodedData = try? JSONDecoder().decode(TotalSpendingWidgetData.self, from: data) {
				let decimalDisplayMode = sharedDefaults.string(forKey: "decimalDisplayMode").flatMap(DecimalDisplayMode.init) ?? .automatic
                return (decodedData.amountSpent, decodedData.monthlyBudget, decodedData.currencySymbol, decodedData.budgetTrackingEnabled, decimalDisplayMode)
            } else {
                // Return a default/empty state if data isn't available
                let currencyCode = UserDefaults(suiteName: "group.com.chankim.Monir")?.string(forKey: "currencyCode") ?? "USD"
                let currencySymbol = CurrencyManager.symbol(for: currencyCode)
				let decimalDisplayMode = UserDefaults(suiteName: "group.com.chankim.Monir")?.string(forKey: "decimalDisplayMode").flatMap(DecimalDisplayMode.init) ?? .automatic
                return (0, 0, currencySymbol, false, decimalDisplayMode)
            }
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
						Text("Total Spending")
								.font(.subheadline.bold())
								.foregroundColor(.primary)

						Text(NumberFormatter.currency(for: entry.decimalDisplayMode, currencyCode: entry.currencySymbol).string(from: NSNumber(value: entry.total)) ?? "")
								.font(.system(size: 18, weight: .semibold))
								.foregroundColor(.primary)

						if entry.isBudgetTrackingEnabled {
								ProgressView(value: min(entry.total / max(entry.budget, 1), 1))
										.progressViewStyle(LinearProgressViewStyle(tint: entry.total > entry.budget ? .red : .blue))
						}
				}
				.padding(.horizontal, 8)
				.padding(.vertical)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(Color.clear)
				.containerBackground(.clear, for: .widget)
		}

		var mediumView: some View {
				VStack(alignment: .leading, spacing: 8) {
						Text("Total Spending")
								.font(.subheadline.bold())
								.foregroundColor(.primary)

						if entry.isBudgetTrackingEnabled {
								Text("\(NumberFormatter.currency(for: entry.decimalDisplayMode, currencyCode: entry.currencySymbol).string(from: NSNumber(value: entry.total)) ?? "") / \(NumberFormatter.currency(for: entry.decimalDisplayMode, currencyCode: entry.currencySymbol).string(from: NSNumber(value: entry.budget)) ?? "")")
										.font(.system(size: 18, weight: .semibold))
										.foregroundColor(.primary)

								ProgressView(value: min(entry.total / max(entry.budget, 1), 1))
										.progressViewStyle(LinearProgressViewStyle(tint: entry.total > entry.budget ? .red : .blue))

								Text("\(Int(entry.budget > 0 ? (entry.total / entry.budget * 100) : 0))% used")
										.font(.system(size: 12, weight: .medium))
										.foregroundColor(.secondary)
						} else {
								Text(NumberFormatter.currency(for: entry.decimalDisplayMode, currencyCode: entry.currencySymbol).string(from: NSNumber(value: entry.total)) ?? "")
										.font(.system(size: 18, weight: .semibold))
										.foregroundColor(.primary)
						}
				}
				.padding(.horizontal, 8)
				.padding(.vertical)
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
