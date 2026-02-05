import SwiftUI

struct BudgetSettingsView: View {
	@EnvironmentObject var store: ExpenseStore
	@EnvironmentObject var settings: AppSettings

	private var currencySymbol: String {
		CurrencyManager.symbol(for: settings.currencyCode)
	}
	
	var body: some View {
		Form {
			Section {
				NavigationLink(destination: MonthlyBudgetView()) {
					HStack {
						Text(LocalizedStringKey("Monthly Budget"))
						Spacer()
						Text("\(currencySymbol)\(settings.monthlyBudget, specifier: "%.0f")")
							.foregroundColor(.gray)
					}
				}

				Picker("Start day of month", selection: Binding(get: { settings.monthlyStartDay }, set: { settings.monthlyStartDay = $0 })) {
					ForEach(1...31, id: \.self) {
						Text("\($0)")
					}
				}
			}
		}
		.navigationTitle("Budget & Planning")
		.navigationBarTitleDisplayMode(.inline)
	}
}
