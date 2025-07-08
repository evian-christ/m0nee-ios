
//
//  m0neeTests.swift
//  m0neeTests
//
//  Created by Chan on 03/07/2025.
//

import Foundation
import Testing
@testable import m0nee // Import your app module to access its code

struct ExpenseStoreTests {

    // This initializer runs once before all tests in this struct.
    // It ensures a clean slate by deleting the persistence files.
    init() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let expensesURL = documentsDirectory.appendingPathComponent("expenses.json")
        let backupURL = documentsDirectory.appendingPathComponent("expenses_backup_for_recovery.json")

        // Attempt to delete the local files
        try? fileManager.removeItem(at: expensesURL)
        try? fileManager.removeItem(at: backupURL)

        // Also try to delete iCloud version if it exists (for complete cleanup)
        if let iCloudContainerURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            let iCloudExpensesURL = iCloudContainerURL.appendingPathComponent("expenses.json")
            try? fileManager.removeItem(at: iCloudExpensesURL)
        }

        // Clear UserDefaults for category budgets to ensure a clean state for tests
        UserDefaults.standard.removeObject(forKey: "categoryBudgets")

        // Clear shared UserDefaults for app group settings
        let sharedDefaults = UserDefaults(suiteName: "group.com.chankim.Monir")
        sharedDefaults?.removeObject(forKey: "categoryBudgets")
        sharedDefaults?.removeObject(forKey: "monthlyBudget")
        sharedDefaults?.removeObject(forKey: "enableBudgetTracking")
        sharedDefaults?.removeObject(forKey: "budgetPeriod")
        sharedDefaults?.removeObject(forKey: "weeklyStartDay")
        sharedDefaults?.removeObject(forKey: "monthlyStartDay")
        sharedDefaults?.removeObject(forKey: "currencyCode")
        sharedDefaults?.removeObject(forKey: "totalSpendingWidgetData")
        sharedDefaults?.synchronize() // Force synchronization for test reliability
    }

    // A helper function to make creating dates easier in our tests.
    // This keeps the test code clean and readable.
    private func dateFrom(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // It's generally safe to force-unwrap here in a test context,
        // because we, the developer, control the input strings.
        // If a test fails because of a bad date string, we'll know immediately.
        return formatter.date(from: string)!
    }

    // Helper to get a date for a specific day of the week (1=Sunday, 2=Monday, ..., 7=Saturday)
    private func dateForWeekday(_ weekday: Int, year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else { fatalError("Invalid date components") }
        // Find the first occurrence of the weekday on or after the given date
        var current = date
        while calendar.component(.weekday, from: current) != weekday {
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return calendar.startOfDay(for: current)
    }

    @Test func testAddExpense() {
        // ARRANGE: Create a new, empty ExpenseStore instance for this test.
        let store = ExpenseStore()
        let initialCount = store.expenses.count
        let newExpense = Expense(id: UUID(), date: Date(), name: "Test Coffee", amount: 2.50, category: "Food", details: nil, rating: nil, memo: nil)

        // ACT: Call the function we want to test.
        store.add(newExpense)

        // ASSERT: Check if the outcome is what we expected.
        // We expect the number of expenses to have increased by exactly 1.
        #expect(store.expenses.count == initialCount + 1)
        // We also expect the newly added expense to be the last one in the array.
        #expect(store.expenses.last?.name == "Test Coffee")
    }

    @Test func testDeleteExpense() {
        // ARRANGE: Set up the store with an expense that we will try to delete.
        let store = ExpenseStore()
        let expenseToDelete = Expense(id: UUID(), date: Date(), name: "Book", amount: 20.00, category: "Shopping", details: nil, rating: nil, memo: nil)
        store.expenses = [expenseToDelete]
        let initialCount = store.expenses.count

        // ACT: Call the delete function.
        store.delete(expenseToDelete)

        // ASSERT: Verify that the expense count has decreased by 1.
        #expect(store.expenses.count == initialCount - 1)
        // And verify that the specific expense we tried to delete is no longer in the array.
        #expect(store.expenses.contains(where: { $0.id == expenseToDelete.id }) == false)
    }

    @Test func testTotalSpentForMonth_CalculatesCorrectly() {
        // ARRANGE: Create a store and add some specific test data.
        let store = ExpenseStore()
        store.expenses = [
            // Expense in the target month (July 2025)
            Expense(id: UUID(), date: dateFrom("2025-07-15"), name: "Coffee", amount: 5.00, category: "Food", details: nil, rating: nil, memo: nil),
            // Another expense in the target month
            Expense(id: UUID(), date: dateFrom("2025-07-20"), name: "Movie", amount: 15.00, category: "Entertainment", details: nil, rating: nil, memo: nil),
            // An expense in a DIFFERENT month (August 2025)
            Expense(id: UUID(), date: dateFrom("2025-08-01"), name: "Groceries", amount: 50.00, category: "Food", details: nil, rating: nil, memo: nil)
        ]

        // ACT: Call the function we are testing.
        let total = store.totalSpent(forMonth: "2025-07")

        // ASSERT: Check if the result is exactly what we expect (5.00 + 15.00).

        #expect(total == 20.00)
    }

    @Test func testTotalSpentForMonth_WithNoExpenses() {
        // ARRANGE: Create a store with no expenses in the target month.
        let store = ExpenseStore()
        store.expenses = [
            Expense(id: UUID(), date: dateFrom("2025-08-01"), name: "Groceries", amount: 50.00, category: "Food", details: nil, rating: nil, memo: nil)
        ]

        // ACT: Call the function for a month with no expenses.
        let total = store.totalSpent(forMonth: "2025-09")

        // ASSERT: The total should be 0.0.
        #expect(total == 0.0)
    }

    // MARK: - Recurring Expense Tests

    @Test func testGenerateDailyRecurringExpense() {
        // ARRANGE
        // 1. Create a store, which will be used to manage expenses.
        let store = ExpenseStore(forTesting: true)
        
        // 2. Define the start and end dates for the test period.
        let startDate = dateFrom("2025-07-01")
        let endDate = dateFrom("2025-07-03") // We will generate expenses for 3 days.

        // 3. Create a recurrence rule for a daily expense.
        let rule = RecurrenceRule(
            period: .daily,
            frequencyType: .everyN,
            interval: 1, // Every 1 day
            selectedWeekdays: nil,
            selectedMonthDays: nil,
            startDate: startDate,
            endDate: nil
        )
        
        // 4. Create the recurring expense object and add it to the store.
        let recurringExpense = RecurringExpense(
            id: UUID(),
            name: "Daily Newspaper",
            amount: 1.5,
            category: "News",
            details: nil, 
            rating: nil, 
            memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        store.recurringExpenses = [recurringExpense]

        // ACT
        // 5. Call the function that generates expenses from the recurring rules.
        store.generateExpensesFromRecurringIfNeeded(currentDate: endDate)

        // ASSERT
        // 6. Check if the correct number of expenses were created.
        #expect(store.expenses.count == 3) // Expect 3 expenses for July 1, 2, and 3.
        
        // 7. Verify the dates of the generated expenses.
        let generatedDates = store.expenses.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        #expect(generatedDates.contains(dateFrom("2025-07-01")))
        #expect(generatedDates.contains(dateFrom("2025-07-02")))
        #expect(generatedDates.contains(dateFrom("2025-07-03")))
    }

    @Test func testGenerateWeeklyRecurringExpense() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-06-01") // This is a Tuesday

        let rule = RecurrenceRule(
            period: .weekly,
            frequencyType: .everyN,
            interval: 1, // Every 1 week
            startDate: startDate
        )
        
        let recurringExpense = RecurringExpense(
            id: UUID(),
            name: "Weekly Team Lunch",
            amount: 25.0,
            category: "Food",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        store.recurringExpenses = [recurringExpense]

        // ACT
        store.generateExpensesFromRecurringIfNeeded(currentDate: dateFrom("2025-07-04"))

        // ASSERT
        #expect(store.expenses.count == 5) // Expect 5 expenses: June 1, 8, 15, 22, 29
        
        let generatedDates = store.expenses.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        #expect(generatedDates.contains(dateFrom("2025-06-01")))
        #expect(generatedDates.contains(dateFrom("2025-06-08")))
        #expect(generatedDates.contains(dateFrom("2025-06-15")))
				#expect(generatedDates.contains(dateFrom("2025-06-22")))
				#expect(generatedDates.contains(dateFrom("2025-06-29")))
    }

    @Test func testGenerateMonthlyRecurringExpense() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-10")
        let endDate = dateFrom("2025-10-10") // Generate for 4 months

        let rule = RecurrenceRule(
            period: .monthly,
            frequencyType: .everyN,
            interval: 1, // Every 1 month
            startDate: startDate
        )
        
        let recurringExpense = RecurringExpense(
            id: UUID(),
            name: "Monthly Rent",
            amount: 1200.0,
            category: "Rent",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        store.recurringExpenses = [recurringExpense]

        // ACT
        store.generateExpensesFromRecurringIfNeeded(currentDate: endDate)

        // ASSERT
        #expect(store.expenses.count == 4) // Expect 4 expenses: July, Aug, Sep, Oct
        
        let generatedDates = store.expenses.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        #expect(generatedDates.contains(dateFrom("2025-07-10")))
        #expect(generatedDates.contains(dateFrom("2025-08-10")))
        #expect(generatedDates.contains(dateFrom("2025-09-10")))
        #expect(generatedDates.contains(dateFrom("2025-10-10")))
    }

    @Test func testGenerateWeeklySelectedDays() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-01") // Tuesday
        let endDate = dateFrom("2025-07-09") // A little over a week

        // Rule: Repeat on Monday (2) and Wednesday (4)
        let rule = RecurrenceRule(
            period: .weekly, // This period is less relevant for selected days
            frequencyType: .weeklySelectedDays,
            interval: 0, // Interval is not used for this frequency type
            selectedWeekdays: [2, 4], // Monday, Wednesday
            startDate: startDate
        )
        
        let recurringExpense = RecurringExpense(
            id: UUID(),
            name: "Gym Session",
            amount: 15.0,
            category: "Health",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        store.recurringExpenses = [recurringExpense]

        // ACT
        store.generateExpensesFromRecurringIfNeeded(currentDate: endDate)

        // ASSERT
        #expect(store.expenses.count == 3) // Expect 3 expenses: Wed (Jul 2), Mon (Jul 7), Wed (Jul 9)
        
        let generatedDates = store.expenses.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        #expect(generatedDates.contains(dateFrom("2025-07-02"))) // First Wednesday
        #expect(generatedDates.contains(dateFrom("2025-07-07"))) // First Monday
        #expect(generatedDates.contains(dateFrom("2025-07-09"))) // Second Wednesday
    }

    @Test func testGenerateMonthlySelectedDays() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-01")
        let endDate = dateFrom("2025-08-20") // Cover two months

        // Rule: Repeat on the 5th and 20th of each month
        let rule = RecurrenceRule(
            period: .monthly, // This period is less relevant for selected days
            frequencyType: .monthlySelectedDays,
            interval: 0, // Interval is not used
            selectedMonthDays: [5, 20],
            startDate: startDate
        )
        
        let recurringExpense = RecurringExpense(
            id: UUID(),
            name: "Paycheck Deposit",
            amount: 2000.0,
            category: "Income",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        store.recurringExpenses = [recurringExpense]

        // ACT
        store.generateExpensesFromRecurringIfNeeded(currentDate: endDate)

        // ASSERT
        #expect(store.expenses.count == 4) // Expect 4 expenses: July 5, July 20, Aug 5, Aug 20
        
        let generatedDates = store.expenses.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        #expect(generatedDates.contains(dateFrom("2025-07-05")))
        #expect(generatedDates.contains(dateFrom("2025-07-20")))
        #expect(generatedDates.contains(dateFrom("2025-08-05")))
        #expect(generatedDates.contains(dateFrom("2025-08-20")))
    }

    @Test func testGenerateRecurringExpenses_NoDuplicatesOnRerun() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-01")
        let midDate = dateFrom("2025-07-03")
        let endDate = dateFrom("2025-07-05")

        let rule = RecurrenceRule(period: .daily, frequencyType: .everyN, interval: 1, startDate: startDate)
        let recurringExpense = RecurringExpense(
            id: UUID(),
            name: "Daily Standup Coffee",
            amount: 4.0,
            category: "Food",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        store.recurringExpenses = [recurringExpense]

        // ACT 1: Run generation for the first few days.
        store.generateExpensesFromRecurringIfNeeded(currentDate: midDate)

        // ASSERT 1: Check that the first batch of expenses was created.
        #expect(store.expenses.count == 3) // Should have expenses for July 1, 2, 3.

        // ACT 2: Run generation again for a longer period.
        store.generateExpensesFromRecurringIfNeeded(currentDate: endDate)

        // ASSERT 2: Check that only new expenses were added, without creating duplicates.
        #expect(store.expenses.count == 5) // Should have a TOTAL of 5 expenses (July 1, 2, 3, 4, 5).
        
        // Optional: A more detailed check to be certain.
        let finalDates = store.expenses.map { $0.date }.map { Calendar.current.startOfDay(for: $0) }
        let uniqueDates = Set(finalDates)
        #expect(uniqueDates.count == 5)
    }

    @Test func testAddRecurringExpense_GeneratesInitialExpenses() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-01")
        let currentDate = dateFrom("2025-07-04") // Simulate today's date

        let rule = RecurrenceRule(
            period: .daily,
            frequencyType: .everyN,
            interval: 1,
            startDate: startDate
        )
        
        let newRecurring = RecurringExpense(
            id: UUID(),
            name: "New Daily Subscription",
            amount: 10.0,
            category: "Subscriptions",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )

        // ACT
        // We need to call generateExpensesFromRecurringIfNeeded with the simulated current date
        // before adding the recurring expense, to ensure the store's internal state is ready.
        // Then, add the recurring expense.
        store.generateExpensesFromRecurringIfNeeded(currentDate: currentDate)
        store.addRecurringExpense(newRecurring, currentDate: currentDate)

        // ASSERT
        // Expect expenses for July 1, 2, 3, 4
        #expect(store.expenses.count == 4)
        
        let generatedDates = store.expenses.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        #expect(generatedDates.contains(dateFrom("2025-07-01")))
        #expect(generatedDates.contains(dateFrom("2025-07-02")))
        #expect(generatedDates.contains(dateFrom("2025-07-03")))
        #expect(generatedDates.contains(dateFrom("2025-07-04")))
        
        // Also check that the recurring expense itself was added and its lastGeneratedDate is updated
        #expect(store.recurringExpenses.count == 1)
        #expect(store.recurringExpenses.first?.lastGeneratedDate == currentDate)
    }

    @Test func testDeleteRecurringExpense_RemovesRuleButNotChildren() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-01")
        let generationDate = dateFrom("2025-07-03")

        let rule = RecurrenceRule(
            period: .daily,
            frequencyType: .everyN,
            interval: 1,
            startDate: startDate
        )
        
        let recurringToDelete = RecurringExpense(
            id: UUID(),
            name: "Daily Coffee Subscription",
            amount: 3.50,
            category: "Food",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        
        // Add the recurring expense and generate some instances
        store.recurringExpenses = [recurringToDelete]
        store.generateExpensesFromRecurringIfNeeded(currentDate: generationDate)
        
        let initialExpenseCount = store.expenses.count
        let initialRecurringCount = store.recurringExpenses.count

        // ACT
        store.removeRecurringExpense(id: recurringToDelete.id)

        // ASSERT
        // 1. The recurring expense rule should be removed.
        #expect(store.recurringExpenses.count == initialRecurringCount - 1)
        #expect(store.recurringExpenses.contains(where: { $0.id == recurringToDelete.id }) == false)
        
        // 2. The previously generated expenses should still exist.
        #expect(store.expenses.count == initialExpenseCount)
        #expect(store.expenses.contains(where: { $0.parentRecurringID == recurringToDelete.id }))
    }

    @Test func testGenerateExpenseWithIntervalGreaterThanOne() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-01")
        let endDate = dateFrom("2025-07-07") // Generate for a week

        // Rule: Every 2 days
        let rule = RecurrenceRule(
            period: .daily,
            frequencyType: .everyN,
            interval: 2, // Every 2 days
            startDate: startDate
        )
        
        let recurringExpense = RecurringExpense(
            id: UUID(),
            name: "Bi-Daily Delivery",
            amount: 7.0,
            category: "Food",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        store.recurringExpenses = [recurringExpense]

        // ACT
        store.generateExpensesFromRecurringIfNeeded(currentDate: endDate)

        // ASSERT
        #expect(store.expenses.count == 4) // Expect expenses for July 1, 3, 5, 7
        
        let generatedDates = store.expenses.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        #expect(generatedDates.contains(dateFrom("2025-07-01")))
        #expect(generatedDates.contains(dateFrom("2025-07-03")))
        #expect(generatedDates.contains(dateFrom("2025-07-05")))
        #expect(generatedDates.contains(dateFrom("2025-07-07")))
    }

    @Test func testRecurringExpense_StartsInFuture() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-10") // Recurring expense starts in the future
        let currentDate = dateFrom("2025-07-05") // Simulate today's date, before start date

        let rule = RecurrenceRule(
            period: .daily,
            frequencyType: .everyN,
            interval: 1,
            startDate: startDate
        )
        
        let recurringExpense = RecurringExpense(
            id: UUID(),
            name: "Future Subscription",
            amount: 20.0,
            category: "Subscriptions",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        store.recurringExpenses = [recurringExpense]

        // ACT
        store.generateExpensesFromRecurringIfNeeded(currentDate: currentDate)

        // ASSERT
        // No expenses should be generated because the start date is in the future.
        #expect(store.expenses.count == 0)
        
        // The lastGeneratedDate should still be nil or the startDate if it was already set
        // (though in this test, it should remain nil as no generation occurred).
        #expect(store.recurringExpenses.first?.lastGeneratedDate == nil)
    }

    @Test func testUpdateExpense() {
        // ARRANGE: Set up the store with an expense to be updated.
        let store = ExpenseStore(forTesting: true) // Use forTesting: true to bypass persistence during setup
        let originalExpense = Expense(id: UUID(), date: dateFrom("2025-07-01"), name: "Old Name", amount: 10.0, category: "Misc", details: nil, rating: nil, memo: nil)
        store.expenses.append(originalExpense) // Directly add to the in-memory array
        let initialCount = store.expenses.count

        // Create an updated version of the expense
        var updatedExpense = originalExpense
        updatedExpense.name = "New Name"
        updatedExpense.amount = 25.0

        // ACT: Call the update function.
        store.update(updatedExpense)

        // ASSERT: Verify that the expense was updated and no new expenses were added/removed.
        #expect(store.expenses.count == initialCount)
        
        // 1. Find the expense in the store (it's still an optional here).
        let foundExpenseOptional = store.expenses.first(where: { $0.id == updatedExpense.id })

        // 2. Assert that the expense was found (i.e., it's not nil).
        #expect(foundExpenseOptional != nil, "Updated expense not found in store.")

        // 3. Safely unwrap the optional. We can force unwrap here because the previous #expect
        // would have failed the test if foundExpenseOptional was nil.
        let expenseInStore = foundExpenseOptional!

        // 4. Perform assertions on the unwrapped expense's properties.
        #expect(expenseInStore.name == "New Name")
        #expect(expenseInStore.amount == 25.0)
    }

    @Test func testAddCategory() {
        // ARRANGE: Create a new, empty ExpenseStore instance.
        let store = ExpenseStore(forTesting: true)
        let initialCategoryCount = store.categories.count
        
        // Create a new category item.
        let newCategory = CategoryItem(name: "Utilities", symbol: "lightbulb.fill", color: CodableColor(.green))

        // ACT: Call the function to add the category.
        store.addCategory(newCategory)

        // ASSERT: Check if the category was added and the count increased.
        #expect(store.categories.count == initialCategoryCount + 1)
        #expect(store.categories.contains(where: { $0.name == "Utilities" }))
    }

    @Test func testRemoveCategory() {
        // ARRANGE: Set up the store with a category to be removed.
        let store = ExpenseStore(forTesting: true)
        let categoryToRemove = CategoryItem(name: "Books", symbol: "book.closed.fill", color: CodableColor(.brown))
        store.addCategory(categoryToRemove)
        let initialCategoryCount = store.categories.count

        // ACT: Call the function to remove the category.
        store.removeCategory(categoryToRemove)

        // ASSERT: Check if the category was removed and the count decreased.
        #expect(store.categories.count == initialCategoryCount - 1)
        #expect(store.categories.contains(where: { $0.id == categoryToRemove.id }) == false)
    }

    @Test func testCategoryBudgetPersistence() {
        // ARRANGE
        let testCategoryName = "Test Category"
        let testBudgetAmount = "100.00"
        let expectedBudgets: [String: String] = [testCategoryName: testBudgetAmount]

        // Manually save the budget to shared UserDefaults, simulating ExpenseStore's save
        let sharedDefaults = UserDefaults(suiteName: "group.com.chankim.Monir")
        guard let encoded = try? JSONEncoder().encode(expectedBudgets) else {
            #expect(Bool(false), "Failed to encode initial budgets.")
            return
        }
        sharedDefaults?.set(encoded, forKey: "categoryBudgets")
        sharedDefaults?.synchronize() // Force synchronization for test reliability

        // ACT
        // Retrieve the budget directly from shared UserDefaults to verify persistence
        var loadedBudgets: [String: String]?
        if let data = sharedDefaults?.data(forKey: "categoryBudgets"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            loadedBudgets = decoded
        }

        // ASSERT
        #expect(loadedBudgets != nil, "Failed to load budgets from shared UserDefaults.")
        #expect(loadedBudgets == expectedBudgets, "Loaded budgets do not match expected budgets.")
    }

    @Test func testTotalSpentByMonth() {
        // ARRANGE: Create a store and add expenses for different months.
        let store = ExpenseStore(forTesting: true)
        store.expenses = [
            Expense(id: UUID(), date: dateFrom("2025-01-05"), name: "Coffee Jan", amount: 5.0, category: "Food", details: nil, rating: nil, memo: nil),
            Expense(id: UUID(), date: dateFrom("2025-01-10"), name: "Lunch Jan", amount: 15.0, category: "Food", details: nil, rating: nil, memo: nil),
            Expense(id: UUID(), date: dateFrom("2025-02-01"), name: "Rent Feb", amount: 1000.0, category: "Rent", details: nil, rating: nil, memo: nil),
            Expense(id: UUID(), date: dateFrom("2025-02-15"), name: "Dinner Feb", amount: 20.0, category: "Food", details: nil, rating: nil, memo: nil),
            Expense(id: UUID(), date: dateFrom("2025-03-20"), name: "Shopping Mar", amount: 50.0, category: "Shopping", details: nil, rating: nil, memo: nil)
        ]

        // ACT: Call the function to get totals by month.
        let monthlyTotals = store.totalSpentByMonth()

        // ASSERT: Verify the totals for each month.
        #expect(monthlyTotals.count == 3) // Expect totals for Jan, Feb, Mar
        #expect(monthlyTotals["2025-01"] == 20.0) // 5.0 + 15.0
        #expect(monthlyTotals["2025-02"] == 1020.0) // 1000.0 + 20.0
        #expect(monthlyTotals["2025-03"] == 50.0)
        #expect(monthlyTotals["2025-04"] == nil) // Ensure months with no expenses are not present
    }

    @Test func testEraseAllData() {
        // ARRANGE: Populate the store with data
        let store = ExpenseStore(forTesting: true)

        // Add some expenses
        store.add(Expense(id: UUID(), date: dateFrom("2025-01-01"), name: "Old Expense 1", amount: 10.0, category: "Food", details: nil, rating: nil, memo: nil))
        store.add(Expense(id: UUID(), date: dateFrom("2025-01-02"), name: "Old Expense 2", amount: 20.0, category: "Transport", details: nil, rating: nil, memo: nil))

        // Add some recurring expenses
        let rule = RecurrenceRule(period: .daily, frequencyType: .everyN, interval: 1, startDate: dateFrom("2025-01-01"))
        store.recurringExpenses.append(RecurringExpense(id: UUID(), name: "Old Recurring", amount: 5.0, category: "Misc", details: nil, rating: nil, memo: nil, startDate: dateFrom("2025-01-01"), recurrenceRule: rule))

        // Add some custom categories
        let customCategory1 = CategoryItem(name: "Custom 1", symbol: "star.fill", color: CodableColor(.yellow))
        let customCategory2 = CategoryItem(name: "Custom 2", symbol: "heart.fill", color: CodableColor(.cyan))
        store.addCategory(customCategory1)
        store.addCategory(customCategory2)

        // Set some budget data in UserDefaults
        let initialBudgets: [String: String] = ["Food": "500", "Transport": "200", "Custom 1": "100"]
        let sharedDefaults = UserDefaults(suiteName: "group.com.chankim.Monir")
        if let encoded = try? JSONEncoder().encode(initialBudgets) {
            sharedDefaults?.set(encoded, forKey: "categoryBudgets")
        }

        // ACT: Erase all data
        store.eraseAllData()

        // ASSERT: Verify that everything is reset
        #expect(store.expenses.isEmpty)
        #expect(store.recurringExpenses.isEmpty)

        // Verify categories are reset to default
        let defaultCategories = [
            CategoryItem(name: "No Category", symbol: "tray", color: CodableColor(.gray)),
            CategoryItem(name: "Food", symbol: "fork.knife", color: CodableColor(.red)),
            CategoryItem(name: "Transport", symbol: "car.fill", color: CodableColor(.blue)),
            CategoryItem(name: "Entertainment", symbol: "gamecontroller.fill", color: CodableColor(.purple)),
            CategoryItem(name: "Rent", symbol: "house.fill", color: CodableColor(.orange)),
            CategoryItem(name: "Shopping", symbol: "bag.fill", color: CodableColor(.pink))
        ]
        #expect(store.categories.count == defaultCategories.count)
        // Check if all default categories are present in the store's categories
        for defaultCat in defaultCategories {
            #expect(store.categories.contains(where: { $0.name == defaultCat.name && $0.symbol == defaultCat.symbol }))
        }

        // Verify budgets are reset to "0" for default categories
        if let data = sharedDefaults?.data(forKey: "categoryBudgets"),
           let decodedBudgets = try? JSONDecoder().decode([String: String].self, from: data) {
            #expect(decodedBudgets.count == defaultCategories.count)
            for defaultCat in defaultCategories {
                #expect(decodedBudgets[defaultCat.name] == "0")
            }
        } else {
            #expect(false, "Failed to load or decode budgets after eraseAllData.")
        }
    }

    @Test func testNextOccurrenceForDailyRecurringExpense() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-01")
        let lastGeneratedDate = dateFrom("2025-07-05")

        let rule = RecurrenceRule(
            period: .daily,
            frequencyType: .everyN,
            interval: 1,
            startDate: startDate
        )
        
        var recurring = RecurringExpense(
            id: UUID(),
            name: "Daily Check",
            amount: 1.0,
            category: "Misc",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        recurring.lastGeneratedDate = lastGeneratedDate

        // ACT
        let nextDate = store.nextOccurrence(for: recurring)

        // ASSERT
        #expect(nextDate != nil)
        #expect(Calendar.current.isDate(nextDate!, inSameDayAs: dateFrom("2025-07-06")))
    }

    @Test func testNextOccurrenceForWeeklyRecurringExpense() {
        // ARRANGE
        let store = ExpenseStore(forTesting: true)
        let startDate = dateFrom("2025-07-02") // Wednesday
        let lastGeneratedDate = dateFrom("2025-07-02") // Same as start date

        let rule = RecurrenceRule(
            period: .daily,
            frequencyType: .weeklySelectedDays,
            interval: 0, // Interval is not used for selected days
            selectedWeekdays: [4], // Wednesday
            startDate: startDate
        )
        
        var recurring = RecurringExpense(
            id: UUID(),
            name: "Weekly Meeting",
            amount: 0.0,
            category: "Work",
            details: nil, rating: nil, memo: nil,
            startDate: startDate,
            recurrenceRule: rule
        )
        recurring.lastGeneratedDate = lastGeneratedDate

        // ACT
        let nextDate = store.nextOccurrence(for: recurring)

        // ASSERT
        #expect(nextDate != nil)
        #expect(Calendar.current.isDate(nextDate!, inSameDayAs: dateFrom("2025-07-09"))) // Expect next Wednesday
    }
}
