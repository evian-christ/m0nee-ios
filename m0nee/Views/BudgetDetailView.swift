import SwiftUI

struct BudgetDetailView: View {
    let budget: Budget
    @ObservedObject var viewModel: ContentViewModel
    let currencyFormatter: NumberFormatter

    @EnvironmentObject private var store: ExpenseStore
    @EnvironmentObject private var settings: AppSettings
    @State private var showingAddExpense = false

    private var totalSpent: Double {
        viewModel.summaries.first(where: { $0.id == budget.id })?.totalSpent ?? 0
    }

    private var goalAmount: Double? { budget.goalAmount }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(currencyFormatter.string(from: NSNumber(value: totalSpent)) ?? "—")
                        .font(.title2.weight(.semibold))
                    if let goal = goalAmount {
                        let remaining = max(goal - totalSpent, 0)
                        Text("Goal: \(currencyFormatter.string(from: NSNumber(value: goal)) ?? "—")")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("Remaining: \(currencyFormatter.string(from: NSNumber(value: remaining)) ?? "—")")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No goal set")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            let sections = viewModel.daySections(for: budget)
            if sections.isEmpty {
                Section {
                    Text("No expenses yet")
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(sections) { section in
                    Section(header: Text(section.date, formatter: DateFormatter.m0neeListSection)) {
                        ForEach(section.expenses, id: \.id) { expense in
                            NavigationLink {
                                ExpenseDetailView(expenseID: expense.id, store: store)
                                    .environmentObject(settings)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(expense.name)
                                        Text(expense.date.formatted(date: .omitted, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(currencyFormatter.string(from: NSNumber(value: expense.amount)) ?? "")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(budget.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExpense = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            NavigationStack {
                AddExpenseView(defaultBudgetID: budget.id) { newExpense in
                    store.add(newExpense)
                }
                .environmentObject(store)
                .environmentObject(settings)
            }
        }
    }
}
