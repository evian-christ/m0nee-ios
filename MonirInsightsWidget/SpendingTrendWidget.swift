import WidgetKit
import SwiftUI
import Charts

struct SpendingTrendEntry: TimelineEntry {
    let date: Date
    let dailyTotals: [(date: Date, total: Double)]
    let monthlyBudget: Double
    let isBudgetTrackingEnabled: Bool
    let endDate: Date
}

struct SpendingTrendProvider: TimelineProvider {
    func placeholder(in context: Context) -> SpendingTrendEntry {
        SpendingTrendEntry(date: Date(), dailyTotals: [], monthlyBudget: 0.0, isBudgetTrackingEnabled: false, endDate: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SpendingTrendEntry) -> ()) {
        let entry = SpendingTrendEntry(date: Date(), dailyTotals: [], monthlyBudget: 0.0, isBudgetTrackingEnabled: false, endDate: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SpendingTrendEntry>) -> ()) {
        var entries: [SpendingTrendEntry] = []

        // Calculate the start and end dates for the current month
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!

        // Fetch expenses from UserDefaults
        let defaults = UserDefaults(suiteName: "group.com.chankim.Monir")
        let monthlyBudget = defaults?.double(forKey: "monthlyBudget") ?? 0.0
        let isBudgetTrackingEnabled = defaults?.bool(forKey: "enableBudgetTracking") ?? false

        var expenses: [Expense] = []
        if let savedExpensesData = defaults?.data(forKey: "shared_expenses"),
           let decodedExpenses = try? JSONDecoder().decode([Expense].self, from: savedExpensesData) {
            expenses = decodedExpenses
        }

        let spendingData = expenses
            .filter { $0.date >= startDate && $0.date <= endDate }
            .sorted(by: { $0.date < $1.date })

        let grouped = Dictionary(grouping: spendingData) {
            calendar.startOfDay(for: $0.date)
        }

        let dateRange = max(0, calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0)
        let sortedDates = (0...dateRange).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startDate)
        }

        var runningTotal: Double = 0
        let dailyTotals: [(date: Date, total: Double)] = sortedDates.map { date in
            let dayTotal = grouped[date]?.reduce(0) { $0 + $1.amount } ?? 0
            runningTotal += dayTotal
            return (date, runningTotal)
        }

        let entry = SpendingTrendEntry(date: now, dailyTotals: dailyTotals, monthlyBudget: monthlyBudget, isBudgetTrackingEnabled: isBudgetTrackingEnabled, endDate: endDate)
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SpendingTrendWidgetEntryView : View {
    var entry: SpendingTrendProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.subheadline.bold())
            Chart {
                ForEach(Array(entry.dailyTotals.enumerated()), id: \.1.date) { index, item in
                    if item.date <= Date() {
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Total", item.total)
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
            }
            .chartYScale(domain: 0...(entry.isBudgetTrackingEnabled ? entry.monthlyBudget : (entry.dailyTotals.last?.total ?? 0) * 1.2))
            .chartXAxis {
                AxisMarks(values: xAxisDates) { date in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let dateValue = date.as(Date.self) {
                            Text(dateValue, format: .dateTime.day().month())
                        }
                    }
                }
            }
            .frame(height: family == .systemMedium ? 100 : nil)
            
        }
        .padding(.horizontal, 8)
        .padding(.vertical, family == .systemLarge ? 4 : nil)
    }

    private var xAxisDates: [Date] {
        let calendar = Calendar.current
        let startDate = entry.dailyTotals.first?.date ?? Date()
        let today = calendar.startOfDay(for: Date())
        let endDate = entry.endDate
        
        var dates: [Date] = [startDate]
        if calendar.isDate(today, equalTo: startDate, toGranularity: .day) == false && today <= endDate {
            dates.append(today)
        }
        if calendar.isDate(endDate, equalTo: startDate, toGranularity: .day) == false && calendar.isDate(endDate, equalTo: today, toGranularity: .day) == false {
            dates.append(endDate)
        }
        return dates.sorted()
    }
}

struct SpendingTrendWidget: Widget {
    let kind: String = "SpendingTrendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendingTrendProvider()) { entry in
            SpendingTrendWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Spending Trend")
        .description("Shows your spending trend over time.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
