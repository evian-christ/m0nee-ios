import Foundation
import WidgetKit

@MainActor
protocol WidgetSyncing: AnyObject {
    func syncExpenses(_ expenses: [Expense])
    func updateTotalSpending(using expenses: [Expense])
}

struct TotalSpendingWidgetData: Codable {
    let amountSpent: Double
    let monthlyBudget: Double
    let currencySymbol: String
    let budgetTrackingEnabled: Bool
}

@MainActor
final class WidgetSyncService: WidgetSyncing {
    private let sharedDefaults: UserDefaults?
    private let allowsWidgetReload: Bool

    init(sharedSuiteName: String = "group.com.chankim.Monir", allowsWidgetReload: Bool = true) {
        self.sharedDefaults = UserDefaults(suiteName: sharedSuiteName)
        self.allowsWidgetReload = allowsWidgetReload
    }

    func syncExpenses(_ expenses: [Expense]) {
        guard let encoded = try? JSONEncoder().encode(expenses) else { return }
        sharedDefaults?.set(encoded, forKey: "shared_expenses")
    }

    func updateTotalSpending(using expenses: [Expense]) {
        guard let sharedDefaults else { return }

        let budgetTrackingEnabled = (sharedDefaults.object(forKey: "enableBudgetTracking") as? Bool) ?? true
        let budgetPeriod = sharedDefaults.string(forKey: "budgetPeriod") ?? "Monthly"
        let monthlyBudget = sharedDefaults.double(forKey: "monthlyBudget")
        let budgetByCategory = sharedDefaults.bool(forKey: "budgetByCategory")
        let categoryBudgetsData = sharedDefaults.data(forKey: "categoryBudgets")
        let currencyCode = sharedDefaults.string(forKey: "currencyCode") ?? Locale.current.currency?.identifier ?? "USD"
        let currencySymbol = CurrencyManager.symbol(for: currencyCode)

        let calendar = Calendar.current
        let today = Date()

        var startDate: Date
        var endDate: Date

        if budgetPeriod == "Weekly" {
            let weeklyStartDay = {
                let value = sharedDefaults.object(forKey: "weeklyStartDay") as? Int
                return value ?? 1
            }()
            let weekdayToday = calendar.component(.weekday, from: today)
            let delta = (weekdayToday - weeklyStartDay + 7) % 7
            startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -delta, to: today) ?? today)
            endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        } else {
            let monthlyStartDay = {
                let value = sharedDefaults.object(forKey: "monthlyStartDay") as? Int
                return value ?? 1
            }()
            let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            startDate = calendar.date(byAdding: .day, value: monthlyStartDay - 1, to: currentMonth) ?? currentMonth
            if calendar.component(.day, from: today) < monthlyStartDay {
                startDate = calendar.date(byAdding: .month, value: -1, to: startDate) ?? startDate
            }
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
            endDate = calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? nextMonth
        }

        let filteredExpenses = expenses.filter { expense in
            let expenseDate = calendar.startOfDay(for: expense.date)
            return expenseDate >= startDate && expenseDate <= endDate
        }

        let totalAmountSpent = filteredExpenses.reduce(0) { $0 + $1.amount }

        var currentBudget = monthlyBudget
        if budgetByCategory,
           let categoryBudgetsData,
           let decoded = try? JSONDecoder().decode([String: String].self, from: categoryBudgetsData) {
            currentBudget = decoded.values.compactMap { Double($0) }.reduce(0, +)
        }

        let widgetData = TotalSpendingWidgetData(
            amountSpent: totalAmountSpent,
            monthlyBudget: currentBudget,
            currencySymbol: currencySymbol,
            budgetTrackingEnabled: budgetTrackingEnabled
        )

        if let encoded = try? JSONEncoder().encode(widgetData) {
            sharedDefaults.set(encoded, forKey: "totalSpendingWidgetData")
            if allowsWidgetReload {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
