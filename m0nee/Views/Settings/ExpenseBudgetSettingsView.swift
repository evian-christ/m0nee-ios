import SwiftUI

struct ExpenseBudgetSettingsView: View {
    @ObservedObject var store: ExpenseStore
    @State private var showProUpgradeSheet = false

    @AppStorage("currencyCode", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    @AppStorage("decimalDisplayMode") private var decimalDisplayMode: DecimalDisplayMode = .automatic
    @AppStorage("showRating", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var showRating: Bool = true

    var body: some View {
        Form {
            Section(header: Text("Management")) {
                NavigationLink(destination: BudgetSettingsView(store: store)) {
                    Text("Budget")
                }
                NavigationLink(destination: CategorySettingsView(store: store)) {
                    Text("Categories")
                }
                if store.isProUser {
                    NavigationLink(destination: RecurringSettingsView().environmentObject(store)) {
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
                Picker("Currency", selection: $currencyCode) {
                    ForEach(CurrencyManager.currencyOptions, id: \.code) { option in
                        Text("\(option.code) (\(option.symbol))").tag(option.code)
                    }
                }
                Picker("Decimal Places", selection: $decimalDisplayMode) {
                    ForEach(DecimalDisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }

            Section(header: Text("Options")) {
                Toggle("Enable Expense Ratings", isOn: $showRating)
            }
        }
        .navigationTitle("Expense & Budget")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProUpgradeSheet) {
            ProUpgradeModalView(isPresented: $showProUpgradeSheet).environmentObject(store)
        }
    }
}
