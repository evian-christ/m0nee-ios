import Foundation
import Combine
import SwiftUI

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published private(set) var favourites: [InsightCardType] = []

    private let store: ExpenseStore
    private let settings: AppSettings
    private let calendar: Calendar
    private var cancellables: Set<AnyCancellable> = []

    init(store: ExpenseStore, settings: AppSettings, calendar: Calendar = .current) {
        self.store = store
        self.settings = settings
        self.calendar = calendar

        observeChanges()
        syncFavourites()
    }

    func onAppear() {
        syncFavourites()
    }

    // MARK: - Data exposed to the view

    var allCardTypes: [InsightCardType] { InsightCardType.allCases }
    var categories: [CategoryItem] { store.categories }
    var isProUser: Bool { store.isProUser }
    var showRating: Bool { settings.showRating }

    var currentBudgetDates: (start: Date, end: Date) {
        let today = Date()
        if settings.budgetPeriod == "Weekly" {
            let startDay = settings.weeklyStartDay
            let weekdayToday = calendar.component(.weekday, from: today)
            let delta = (weekdayToday - startDay + 7) % 7
            let weekStart = calendar.date(byAdding: .day, value: -delta, to: today) ?? today
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
            return (calendar.startOfDay(for: weekStart), calendar.startOfDay(for: weekEnd))
        } else {
            let startDay = settings.monthlyStartDay
            let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            let monthStart = calendar.date(byAdding: .day, value: startDay - 1, to: currentMonth) ?? currentMonth
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
            let endDate = calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? nextMonth
            return (calendar.startOfDay(for: monthStart), calendar.startOfDay(for: endDate))
        }
    }

    var currentExpenses: [Expense] {
        let range = currentBudgetDates
        return store.expenses.filter { expense in
            let date = calendar.startOfDay(for: expense.date)
            return date >= range.start && date <= range.end
        }
    }

    func isFavourited(_ type: InsightCardType) -> Bool {
        favourites.contains(type)
    }

    func toggleFavourite(_ type: InsightCardType) {
        if let index = favourites.firstIndex(of: type) {
            favourites.remove(at: index)
        } else {
            favourites.append(type)
        }
        saveFavourites()
        syncFavourites()
    }

    // MARK: - Private helpers

    private func syncFavourites() {
        favourites = (try? JSONDecoder().decode([InsightCardType].self, from: settings.favouriteInsightCardsData)) ?? []
    }

    private func saveFavourites() {
        if let encoded = try? JSONEncoder().encode(favourites) {
            settings.favouriteInsightCardsData = encoded
        }
    }

    private func observeChanges() {
        settings.$favouriteInsightCardsData
            .sink { [weak self] _ in self?.syncFavourites() }
            .store(in: &cancellables)

        settings.$budgetPeriod
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        settings.$weeklyStartDay
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        settings.$monthlyStartDay
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        settings.$showRating
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        store.$expenses
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        store.$categories
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        store.$productID
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        store.$isPromoProUser
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}
