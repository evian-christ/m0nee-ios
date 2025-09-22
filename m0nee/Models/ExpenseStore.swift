import Foundation
import SwiftUI

@MainActor
class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var productID: String?
    @Published var isPromoProUser: Bool {
        didSet {
            proAccessManager.setPromoStatus(isPromoProUser)
        }
    }
    var isProUser: Bool {
        proAccessManager.isPro(productID: productID)
    }

    @Published var budgets: [Budget] = []
    @Published var categories: [CategoryItem] = []
    @Published var recurringExpenses: [RecurringExpense] = []
    @Published var restoredFromBackup: Bool = false
    @Published var failedToRestore: Bool = false

    private let repository: ExpenseRepository
    private let budgetService: BudgetComputing
    private let recurringService: RecurringExpenseScheduling
    private let widgetService: WidgetSyncing
    private let proAccessManager: ProAccessHandling
    private let settings: AppSettings
    private let forTesting: Bool

    init(
        repository: ExpenseRepository,
        budgetService: BudgetComputing,
        recurringService: RecurringExpenseScheduling,
        widgetService: WidgetSyncing,
        proAccessManager: ProAccessHandling,
        settings: AppSettings,
        forTesting: Bool = false
    ) {
        self.repository = repository
        self.budgetService = budgetService
        self.recurringService = recurringService
        self.widgetService = widgetService
        self.proAccessManager = proAccessManager
        self.settings = settings
        self.forTesting = forTesting
        self.productID = nil
        self.isPromoProUser = proAccessManager.isPromoProUser

        Task {
            await bootstrap()
        }
    }

    convenience init(forTesting: Bool = false) {
        let settings: AppSettings = forTesting ? AppSettings.testingInstance() : AppSettings.shared
        let repository: ExpenseRepository
        let widgetService: WidgetSyncing
        if forTesting {
            repository = InMemoryExpenseRepository()
            widgetService = WidgetSyncService(allowsWidgetReload: false)
        } else {
            repository = FileExpenseRepository(forTesting: false)
            widgetService = WidgetSyncService()
        }

        self.init(
            repository: repository,
            budgetService: AppBudgetService(settings: settings),
            recurringService: RecurringExpenseService(),
            widgetService: widgetService,
            proAccessManager: UserDefaultsProAccessManager(),
            settings: settings,
            forTesting: forTesting
        )
    }

    convenience init() {
        self.init(forTesting: false)
    }

    private func bootstrap() async {
        if !forTesting {
            await repository.syncStorageIfNeeded()
        }

        if let loaded = try? await repository.load() {
            apply(storeData: loaded)
            migrateRecurringRules()
            migrateRecurringExpenseRatings()
            budgetService.cleanupBudgets(using: categories)
        } else {
            budgets = [Budget(name: "My Budget")]
            categories = defaultCategories()
            budgetService.seedBudgetsIfNeeded(with: categories)
            persist()
        }

        if categories.isEmpty {
            categories = defaultCategories()
            budgetService.seedBudgetsIfNeeded(with: categories)
            persist()
        }

        if budgets.isEmpty {
            budgets = [Budget(name: "My Budget")]
            reassignExpensesToDefaultBudget()
            persist()
        }

        ensureExpensesHaveBudget()

        if !forTesting {
            generateExpensesFromRecurringIfNeeded()
        } else {
            widgetService.syncExpenses(expenses)
        }
    }

    private func apply(storeData: StoreData) {
        budgets = storeData.budgets
        expenses = storeData.expenses
        categories = storeData.categories
        recurringExpenses = storeData.recurringExpenses
    }

    private func defaultCategories() -> [CategoryItem] {
        [
            CategoryItem(name: "No Category", symbol: "tray", color: CodableColor(.gray)),
            CategoryItem(name: "Food", symbol: "fork.knife", color: CodableColor(.red)),
            CategoryItem(name: "Transport", symbol: "car.fill", color: CodableColor(.blue)),
            CategoryItem(name: "Entertainment", symbol: "gamecontroller.fill", color: CodableColor(.purple)),
            CategoryItem(name: "Rent", symbol: "house.fill", color: CodableColor(.orange)),
            CategoryItem(name: "Shopping", symbol: "bag.fill", color: CodableColor(.pink))
        ]
    }

    private func persist() {
        let snapshot = StoreData(
            budgets: budgets,
            expenses: expenses,
            categories: categories,
            recurringExpenses: recurringExpenses
        )

        let repository = self.repository
        Task.detached(priority: .utility) {
            do {
                try await repository.save(snapshot)
            } catch {
                // ignore persistence errors for now
            }
        }

        widgetService.syncExpenses(expenses)
        widgetService.updateTotalSpending(using: expenses)
    }

    private func ensureExpensesHaveBudget() {
        guard let defaultBudget = budgets.first else { return }
        var changed = false
        for index in expenses.indices {
            if !budgets.contains(where: { $0.id == expenses[index].budgetID }) {
                expenses[index].budgetID = defaultBudget.id
                changed = true
            }
        }
        for index in recurringExpenses.indices {
            if !budgets.contains(where: { $0.id == recurringExpenses[index].budgetID }) {
                recurringExpenses[index].budgetID = defaultBudget.id
                changed = true
            }
        }
        if changed {
            persist()
        }
    }

    private func reassignExpensesToDefaultBudget() {
        guard let defaultBudget = budgets.first else { return }
        for index in expenses.indices {
            expenses[index].budgetID = defaultBudget.id
        }
        for index in recurringExpenses.indices {
            recurringExpenses[index].budgetID = defaultBudget.id
        }
    }

    // MARK: - Category Management

    func addCategory(_ category: CategoryItem) {
        categories.append(category)
        budgetService.ensureCategoryBudgetEntry(for: category.name)
        budgetService.cleanupBudgets(using: categories)
        persist()
    }

    func removeCategory(_ category: CategoryItem) {
        categories.removeAll { $0.id == category.id }
        budgetService.removeCategoryBudgetEntry(for: category.name)
        budgetService.cleanupBudgets(using: categories)
        persist()
    }

    func updateCategory(_ category: CategoryItem) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }

        let oldName = categories[index].name
        categories[index] = category

        if oldName != category.name {
            var budgets = budgetService.loadBudgets()
            if let value = budgets.removeValue(forKey: oldName) {
                budgets[category.name] = value
                budgetService.saveBudgets(budgets)
            }

            for i in expenses.indices where expenses[i].category == oldName {
                expenses[i].category = category.name
            }
            for i in recurringExpenses.indices where recurringExpenses[i].category == oldName {
                recurringExpenses[i].category = category.name
            }
        }

        budgetService.cleanupBudgets(using: categories)
        persist()
    }

    // MARK: - Budget Helpers

    func updateTotalSpendingWidgetData() {
        widgetService.updateTotalSpending(using: expenses)
    }

    // MARK: - Expense CRUD

    func totalSpent(forMonth month: String) -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return expenses
            .filter { formatter.string(from: $0.date) == month }
            .reduce(0) { $0 + $1.amount }
    }

    func add(_ expense: Expense) {
        expenses.append(expense)
        persist()
    }

    func update(_ updated: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == updated.id }) {
            expenses[index] = updated
            persist()
        }
    }

    func delete(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses.remove(at: index)
            persist()
        }
    }

    func totalSpentByMonth() -> [String: Double] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return Dictionary(grouping: expenses, by: { formatter.string(from: $0.date) })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    func createBudget(name: String, goalAmount: Double?) -> Budget {
        let budget = Budget(name: name, goalAmount: goalAmount)
        budgets.append(budget)
        persist()
        return budget
    }

    func updateBudget(_ budget: Budget) {
        guard let index = budgets.firstIndex(where: { $0.id == budget.id }) else { return }
        budgets[index] = budget
        persist()
    }

    func deleteBudget(_ budget: Budget) {
        guard let index = budgets.firstIndex(where: { $0.id == budget.id }) else { return }
        let remainingBudgets = budgets.filter { $0.id != budget.id }
        guard let fallback = remainingBudgets.first else { return }
        budgets.remove(at: index)
        for idx in expenses.indices {
            if expenses[idx].budgetID == budget.id {
                expenses[idx].budgetID = fallback.id
            }
        }
        persist()
    }

    func expenses(for budgetID: UUID) -> [Expense] {
        expenses.filter { $0.budgetID == budgetID }
    }

    // MARK: - Recurring Expenses

    func generateExpensesFromRecurringIfNeeded(currentDate: Date = Date()) {
        let generated = recurringService.generateExpenses(for: &recurringExpenses, currentDate: currentDate)
        if !generated.isEmpty {
            expenses.append(contentsOf: generated)
        }
        persist()
    }

    func addRecurringExpense(_ recurring: RecurringExpense, currentDate: Date = Date()) {
        var (preparedRecurring, generated) = recurringService.prepareRecurringForAdd(recurring, currentDate: currentDate)

        recurringExpenses.append(preparedRecurring)
        if !generated.isEmpty {
            expenses.append(contentsOf: generated)
        }
        persist()
    }

    func removeRecurringExpense(id: UUID) {
        if let index = recurringExpenses.firstIndex(where: { $0.id == id }) {
            recurringExpenses.remove(at: index)
            persist()
        }
    }

    func binding(for expenseID: UUID) -> Binding<Expense>? {
        guard expenses.contains(where: { $0.id == expenseID }) else { return nil }
        return Binding(
            get: { [weak self] in
                guard let self, let item = self.expenses.first(where: { $0.id == expenseID }) else {
                    let fallbackBudget = self?.budgets.first?.id ?? UUID()
                    return Expense(id: expenseID, date: Date(), name: "", amount: 0, category: "", details: nil, rating: nil, memo: nil, budgetID: fallbackBudget)
                }
                return item
            },
            set: { [weak self] updated in
                guard let self, let index = self.expenses.firstIndex(where: { $0.id == expenseID }) else { return }
                self.expenses[index] = updated
            }
        )
    }

    func updateRecurringExpenseMetadata(_ updatedExpense: RecurringExpense) {
        guard let index = recurringExpenses.firstIndex(where: { $0.id == updatedExpense.id }) else { return }

        recurringExpenses[index].name = updatedExpense.name
        recurringExpenses[index].amount = updatedExpense.amount
        recurringExpenses[index].category = updatedExpense.category
        recurringExpenses[index].memo = updatedExpense.memo
        recurringExpenses[index].details = updatedExpense.details

        for i in expenses.indices where expenses[i].parentRecurringID == updatedExpense.id {
            expenses[i].name = updatedExpense.name
            expenses[i].amount = updatedExpense.amount
            expenses[i].category = updatedExpense.category
            expenses[i].memo = updatedExpense.memo
            expenses[i].details = updatedExpense.details
        }

        persist()
    }

    func removeAllExpenses(withParentID parentID: UUID) {
        expenses.removeAll { $0.parentRecurringID == parentID }
        persist()
    }

    func nextOccurrence(for recurring: RecurringExpense) -> Date? {
        recurringService.nextOccurrence(for: recurring)
    }

    // MARK: - Data Sync

    func syncStorageIfNeeded() {
        Task {
            await repository.syncStorageIfNeeded()
            if let loaded = try? await repository.load() {
                apply(storeData: loaded)
            }
        }
    }

    func eraseAllData() {
        expenses.removeAll()
        recurringExpenses.removeAll()
        categories = defaultCategories()

        var zeroBudgets: [String: String] = [:]
        for category in categories {
            zeroBudgets[category.name] = "0"
        }
        budgetService.saveBudgets(zeroBudgets)
        budgetService.cleanupBudgets(using: categories)
        persist()
    }

    // MARK: - Migration Helpers

    func migrateRecurringRules() {
        var changed = false
        for i in recurringExpenses.indices {
            let oldRule = recurringExpenses[i].recurrenceRule

            if let selectedWeekdays = oldRule.selectedWeekdays, !selectedWeekdays.isEmpty {
                var newRule = oldRule
                newRule.period = .weekly
                newRule.frequencyType = .weeklySelectedDays
                newRule.interval = 0
                newRule.selectedMonthDays = nil
                recurringExpenses[i].recurrenceRule = newRule
                changed = true
            } else if let selectedMonthDays = oldRule.selectedMonthDays, !selectedMonthDays.isEmpty {
                var newRule = oldRule
                newRule.period = .monthly
                newRule.frequencyType = .monthlySelectedDays
                newRule.interval = 0
                newRule.selectedWeekdays = nil
                recurringExpenses[i].recurrenceRule = newRule
                changed = true
            }
        }

        if changed {
            persist()
        }
    }

    func migrateRecurringExpenseRatings() {
        var changed = false
        for index in expenses.indices {
            if expenses[index].isRecurring && expenses[index].rating != nil {
                expenses[index].rating = nil
                changed = true
            }
        }
        if changed {
            persist()
        }
    }
}
