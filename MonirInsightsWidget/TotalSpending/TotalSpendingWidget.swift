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
            let budgetTrackingEnabled = (defaults?.object(forKey: "enableBudgetTracking") as? Bool) ?? true
            let monthlyBudget = defaults?.double(forKey: "monthlyBudget") ?? 0.0
            let currencyCode = defaults?.string(forKey: "currencyCode") ?? Locale.current.currency?.identifier ?? "USD"
            let currencySymbol = CurrencyManager.symbol(for: currencyCode)

            var expenses: [Expense] = []
            if let savedExpensesData = defaults?.data(forKey: "shared_expenses"),
               let decodedExpenses = try? JSONDecoder().decode([Expense].self, from: savedExpensesData) {
                expenses = decodedExpenses
            }

            let totalAmount = expenses.reduce(0) { $0 + $1.amount }

            return (totalAmount, monthlyBudget, currencySymbol, budgetTrackingEnabled)
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

						Text("\(entry.currencySymbol)\(String(format: "%.2f", entry.total))")
								.font(.system(size: 18, weight: .semibold))
								.foregroundColor(.primary)

						if entry.isBudgetTrackingEnabled {
								ProgressView(value: min(entry.total / max(entry.budget, 1), 1))
										.progressViewStyle(LinearProgressViewStyle(tint: .blue))
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
