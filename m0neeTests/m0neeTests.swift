
//
//  m0neeTests.swift
//  m0neeTests
//
//  Created by Chan on 03/07/2025.
//

import Foundation // <-- THE FIX IS HERE!
import Testing
@testable import m0nee // Import your app module to access its code

struct m0neeTests {

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
}
