import Foundation

@MainActor
protocol BudgetComputing: AnyObject {
    func loadBudgets() -> [String: String]
    func saveBudgets(_ budgets: [String: String])
    func ensureCategoryBudgetEntry(for name: String)
    func removeCategoryBudgetEntry(for name: String)
    func cleanupBudgets(using categories: [CategoryItem])
    func seedBudgetsIfNeeded(with categories: [CategoryItem])
}

@MainActor
final class AppBudgetService: BudgetComputing {
    private unowned let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    func loadBudgets() -> [String: String] {
        settings.loadCategoryBudgets()
    }

    func saveBudgets(_ budgets: [String: String]) {
        settings.saveCategoryBudgets(budgets)
    }

    func ensureCategoryBudgetEntry(for name: String) {
        var budgets = loadBudgets()
        if budgets[name] == nil {
            budgets[name] = "0"
            saveBudgets(budgets)
        }
    }

    func removeCategoryBudgetEntry(for name: String) {
        var budgets = loadBudgets()
        budgets.removeValue(forKey: name)
        saveBudgets(budgets)
    }

    func cleanupBudgets(using categories: [CategoryItem]) {
        let validNames = Set(categories.map { $0.name })
        var budgets = loadBudgets()
        let originalCount = budgets.count

        budgets = budgets.filter { validNames.contains($0.key) }

        if originalCount != budgets.count {
            saveBudgets(budgets)
        }
    }

    func seedBudgetsIfNeeded(with categories: [CategoryItem]) {
        var budgets = loadBudgets()
        guard budgets.isEmpty else { return }

        for category in categories {
            budgets[category.name] = "0"
        }
        saveBudgets(budgets)
    }
}
