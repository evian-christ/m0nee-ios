import Foundation
import Combine

@MainActor
final class ContentViewModel: ObservableObject {
    struct BudgetSummary: Identifiable {
        let id: UUID
        let budget: Budget
        let totalSpent: Double
        let expenseCount: Int
    }

    struct DaySection: Identifiable {
        let id: Date
        let date: Date
        let expenses: [Expense]
    }

    @Published private(set) var totalSpent: Double = 0
    @Published private(set) var summaries: [BudgetSummary] = []

    private let store: ExpenseStore
    private let calendar: Calendar
    private var cancellables: Set<AnyCancellable> = []

    init(store: ExpenseStore, calendar: Calendar = .current) {
        self.store = store
        self.calendar = calendar

        Publishers.CombineLatest(store.$budgets, store.$expenses)
            .receive(on: RunLoop.main)
            .sink { [weak self] budgets, expenses in
                self?.rebuildSummaries(budgets: budgets, expenses: expenses)
            }
            .store(in: &cancellables)

        rebuildSummaries(budgets: store.budgets, expenses: store.expenses)
    }

    func createBudget(name: String, goalAmount: Double?) {
        store.createBudget(name: name, goalAmount: goalAmount)
    }

    func expenses(for budget: Budget) -> [Expense] {
        store.expenses(for: budget.id)
    }

    func daySections(for budget: Budget) -> [DaySection] {
        let expenses = store.expenses(for: budget.id)
        let grouped = Dictionary(grouping: expenses) { expense in
            calendar.startOfDay(for: expense.date)
        }

        return grouped
            .map { key, values in
                DaySection(
                    id: key,
                    date: key,
                    expenses: values.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.date > $1.date }
    }

    private func rebuildSummaries(budgets: [Budget], expenses: [Expense]) {
        totalSpent = expenses.reduce(0) { $0 + $1.amount }

        summaries = budgets.map { budget in
            let budgetExpenses = expenses.filter { $0.budgetID == budget.id }
            let spent = budgetExpenses.reduce(0) { $0 + $1.amount }
            return BudgetSummary(
                id: budget.id,
                budget: budget,
                totalSpent: spent,
                expenseCount: budgetExpenses.count
            )
        }
        .sorted { $0.budget.name.localizedCaseInsensitiveCompare($1.budget.name) == .orderedAscending }
    }
}
