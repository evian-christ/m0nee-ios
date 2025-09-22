import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: ExpenseStore
    @EnvironmentObject private var settings: AppSettings

    private var currencyFormatter: NumberFormatter {
        NumberFormatter.currency(for: settings.decimalDisplayMode, currencyCode: settings.currencyCode)
    }

    private var totalSpent: Double {
        store.expenses.reduce(0) { $0 + $1.amount }
    }

    private var categoryTotals: [(name: String, amount: Double)] {
        let grouped = Dictionary(grouping: store.expenses, by: { $0.category })
        return grouped
            .map { key, value in
                (name: key, amount: value.reduce(0) { $0 + $1.amount })
            }
            .sorted(by: { $0.amount > $1.amount })
    }

    var body: some View {
        List {
            Section("Summary") {
                HStack {
                    Text("Total spent")
                    Spacer()
                    Text(currencyFormatter.string(from: NSNumber(value: totalSpent)) ?? "—")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Transactions")
                    Spacer()
                    Text("\(store.expenses.count)")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text("Recurring rules")
                    Spacer()
                    Text("\(store.recurringExpenses.count)")
                        .fontWeight(.semibold)
                }
            }

            if !categoryTotals.isEmpty {
                Section("Categories") {
                    ForEach(categoryTotals, id: \.name) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text(currencyFormatter.string(from: NSNumber(value: item.amount)) ?? "—")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
}
