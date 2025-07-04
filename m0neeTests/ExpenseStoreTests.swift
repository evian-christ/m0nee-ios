
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
        let startDate = dateFrom("2025-07-01") // This is a Tuesday
        let endDate = dateFrom("2025-07-15") // Generate for 3 weeks

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
        store.generateExpensesFromRecurringIfNeeded(currentDate: endDate)

        // ASSERT
        #expect(store.expenses.count == 3) // Expect 3 expenses: July 1, 8, 15
        
        let generatedDates = store.expenses.map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        #expect(generatedDates.contains(dateFrom("2025-07-01")))
        #expect(generatedDates.contains(dateFrom("2025-07-08")))
        #expect(generatedDates.contains(dateFrom("2025-07-15")))
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
        store.addRecurringExpense(newRecurring)

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
}
