
//
//  m0neeTests.swift
//  m0neeTests
//
//  Created by Chan on 03/07/2025.
//

import Foundation
import Testing
@testable import m0nee // Import your app module to access its code

struct m0neeTests {

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
}
