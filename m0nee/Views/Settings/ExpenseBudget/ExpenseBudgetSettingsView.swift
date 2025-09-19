import SwiftUI

struct ExpenseBudgetSettingsView: View {
    @EnvironmentObject var store: ExpenseStore
    @EnvironmentObject var settings: AppSettings
    @State private var showProUpgradeSheet = false

    var body: some View {
        Form {
            Section(header: Text("Management")) {
                NavigationLink(destination: BudgetSettingsView()) {
                    Text("Budget")
                }
                NavigationLink(destination: CategorySettingsView()) {
                    Text("Categories")
                }
                if store.isProUser {
                    NavigationLink(destination: RecurringSettingsView()) {
                        Text("Recurring Expenses")
                    }
                } else {
                    Button(action: { showProUpgradeSheet = true }) {
                        HStack {
                            Text("Recurring Expenses")
                            Spacer()
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }

            Section(header: Text("Currency & Formatting")) {
                Picker("Currency", selection: Binding(get: { settings.currencyCode }, set: { settings.currencyCode = $0 })) {
                    ForEach(CurrencyManager.currencyOptions, id: \.code) { option in
                        Text("\(option.code) (\(option.symbol))").tag(option.code)
                    }
                }
                Picker("Decimal Places", selection: Binding(get: { settings.decimalDisplayMode }, set: { settings.decimalDisplayMode = $0 })) {
                    ForEach(DecimalDisplayMode.allCases) { mode in
                        Text(mode.localizedTitle).tag(mode)
                    }
                }
            }

            Section(header: Text("Options")) {
                Toggle("Enable Expense Ratings", isOn: Binding(get: { settings.showRating }, set: { settings.showRating = $0 }))
            }
        }
        .navigationTitle("Expense & Budget")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProUpgradeSheet) {
            ProUpgradeModalView(isPresented: $showProUpgradeSheet)
        }
    }
}
