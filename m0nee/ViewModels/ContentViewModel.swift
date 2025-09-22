import Foundation
import Combine
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var selectedMonth: String
    @Published var selectedWeekStart: Date
    @Published private(set) var favouriteCards: [InsightCardType] = []
    @Published private(set) var cardRefreshTokens: [InsightCardType: UUID] = [:]

    private let store: ExpenseStore
    private let settings: AppSettings
    private let calendar: Calendar
    private var cancellables: Set<AnyCancellable> = []

    init(store: ExpenseStore, settings: AppSettings, calendar: Calendar = .current) {
        self.store = store
        self.settings = settings
        self.calendar = calendar

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        self.selectedMonth = formatter.string(from: Date())

        let today = calendar.startOfDay(for: Date())
        let delta = (calendar.component(.weekday, from: today) - settings.weeklyStartDay + 7) % 7
        if let adjusted = calendar.date(byAdding: .day, value: -delta, to: today) {
            self.selectedWeekStart = calendar.startOfDay(for: adjusted)
        } else {
            self.selectedWeekStart = today
        }

        observeChanges()
        reloadFavourites(resetTokens: true)
    }

    func onAppear() {
        store.updateTotalSpendingWidgetData()
        reloadFavourites(resetTokens: true)
        alignSelectedWeekWithSettings()
    }

    // MARK: - Exposed settings-backed values

    var hasSeenTutorial: Bool { settings.hasSeenTutorial }
    var currencyCode: String { settings.currencyCode }
    var currencySymbol: String { CurrencyManager.symbol(for: settings.currencyCode) }
    var displayMode: String { settings.displayMode }
    var budgetPeriod: String { settings.budgetPeriod }
    var appearanceMode: String { settings.appearanceMode }
    var useFixedInsightCards: Bool { settings.useFixedInsightCards }
    var shouldGroupByDay: Bool { settings.groupByDay }
    var showRating: Bool { settings.showRating }
    var decimalDisplayMode: DecimalDisplayMode { settings.decimalDisplayMode }
    var budgetByCategory: Bool { settings.budgetByCategory }
    var monthlyBudget: Double { settings.monthlyBudget }
    var weeklyStartDay: Int { settings.weeklyStartDay }
    var monthlyStartDay: Int { settings.monthlyStartDay }

    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "Dark":
            return .dark
        case "Light":
            return .light
        default:
            return nil
        }
    }

    // MARK: - Filtering helpers

    var displayedDateRange: String {
        if budgetPeriod == "Weekly" {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Week of \(formatter.string(from: selectedWeekStart))"
        } else {
            return "\(displayMonth(selectedMonth)) (\(formattedRange(budgetDates)))"
        }
    }

    var budgetDates: (start: Date, end: Date) {
        if budgetPeriod == "Weekly" {
            let start = calendar.startOfDay(for: selectedWeekStart)
            let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            return (start, calendar.startOfDay(for: end))
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            guard let baseDate = formatter.date(from: selectedMonth) else {
                let today = Date()
                return (today, today)
            }

            let monthStart = calendar.date(byAdding: .day, value: monthlyStartDay - 1, to: baseDate) ?? baseDate
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
            let endDate = calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? nextMonth
            return (calendar.startOfDay(for: monthStart), calendar.startOfDay(for: endDate))
        }
    }

    var monthsWithExpenses: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        let adjustedMonths: [String] = store.expenses.map { expense in
            let date = expense.date
            let monthStart: Date = {
                if calendar.component(.day, from: date) >= monthlyStartDay {
                    let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
                    return calendar.date(byAdding: .day, value: monthlyStartDay - 1, to: thisMonth) ?? thisMonth
                } else {
                    let previousMonth = calendar.date(byAdding: .month, value: -1, to: date) ?? date
                    let prevStart = calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth)) ?? previousMonth
                    return calendar.date(byAdding: .day, value: monthlyStartDay - 1, to: prevStart) ?? prevStart
                }
            }()
            return formatter.string(from: monthStart)
        }

        return Array(Set(adjustedMonths)).sorted(by: >)
    }

    var recentWeeks: [Date] {
        let allWeekStarts = store.expenses.map { expense -> Date in
            let weekday = calendar.component(.weekday, from: expense.date)
            let delta = (weekday - weeklyStartDay + 7) % 7
            let candidate = calendar.date(byAdding: .day, value: -delta, to: expense.date) ?? expense.date
            return calendar.startOfDay(for: candidate)
        }
        return Array(Set(allWeekStarts)).sorted(by: >)
    }

    var filteredExpenseIDs: [UUID] {
        filteredExpenses().map { $0.id }
    }

    var groupedExpenseIDs: [(date: Date, ids: [UUID])] {
        let grouped = Dictionary(grouping: filteredExpenses()) { expense -> Date in
            calendar.startOfDay(for: expense.date)
        }
        return grouped
            .map { (date: $0.key, ids: $0.value.map { $0.id }) }
            .sorted { $0.date > $1.date }
    }

    func displayMonth(_ month: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM"
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMMM yyyy"
        if let date = inputFormatter.date(from: month) {
            return outputFormatter.string(from: date)
        }
        return month
    }

    func currencyFormatter() -> NumberFormatter {
        NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode)
    }

    // MARK: - Favourite Handling

    func refreshFavouriteTokens() {
        reloadFavourites(resetTokens: true)
    }

    // MARK: - Private helpers

    private func filteredExpenses() -> [Expense] {
        if budgetPeriod == "Weekly" {
            let start = calendar.startOfDay(for: selectedWeekStart)
            guard let end = calendar.date(byAdding: .day, value: 6, to: start) else { return [] }
            return store.expenses
                .filter { calendar.startOfDay(for: $0.date) >= start && calendar.startOfDay(for: $0.date) <= calendar.startOfDay(for: end) }
                .sorted { $0.date > $1.date }
        } else {
            let range = budgetDates
            let start = calendar.startOfDay(for: range.start)
            let end = calendar.startOfDay(for: range.end)
            return store.expenses
                .filter {
                    let date = calendar.startOfDay(for: $0.date)
                    return date >= start && date <= end
                }
                .sorted { $0.date > $1.date }
        }
    }

    private func formattedRange(_ range: (start: Date, end: Date)) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: range.start)) - \(formatter.string(from: range.end))"
    }

    private func reloadFavourites(resetTokens: Bool) {
        let decoded = (try? JSONDecoder().decode([InsightCardType].self, from: settings.favouriteInsightCardsData)) ?? []
        favouriteCards = decoded
        if resetTokens {
            cardRefreshTokens = Dictionary(uniqueKeysWithValues: decoded.map { ($0, UUID()) })
        }
    }

    private func alignSelectedWeekWithSettings() {
        let today = calendar.startOfDay(for: Date())
        let delta = (calendar.component(.weekday, from: today) - settings.weeklyStartDay + 7) % 7
        if let adjusted = calendar.date(byAdding: .day, value: -delta, to: today) {
            selectedWeekStart = calendar.startOfDay(for: adjusted)
        }
    }

    private func observeChanges() {
        settings.$favouriteInsightCardsData
            .sink { [weak self] _ in
                self?.reloadFavourites(resetTokens: true)
            }
            .store(in: &cancellables)

        store.$expenses
            .sink { [weak self] _ in
                self?.reloadFavourites(resetTokens: true)
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        store.$categories
            .sink { [weak self] _ in
                self?.reloadFavourites(resetTokens: true)
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$weeklyStartDay
            .sink { [weak self] _ in
                self?.alignSelectedWeekWithSettings()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$monthlyStartDay
            .sink { [weak self] _ in
                guard let self else { return }
                self.selectedMonth = self.currentMonthIdentifier()
                self.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$budgetPeriod
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$displayMode
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        settings.$groupByDay
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        settings.$useFixedInsightCards
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        settings.$appearanceMode
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func currentMonthIdentifier() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}
