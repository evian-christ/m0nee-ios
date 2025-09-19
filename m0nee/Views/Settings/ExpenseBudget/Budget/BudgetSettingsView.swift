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
				Toggle("Enable Budget Tracking", isOn: Binding(get: { settings.budgetTrackingEnabled }, set: { settings.budgetTrackingEnabled = $0 }))
			}
			
			if settings.budgetTrackingEnabled {
				Section {
					NavigationLink(destination: BudgetFrequencyView()) {
						HStack {
							Text("Budget Period")
							Spacer()
							Text(LocalizedStringKey(settings.budgetPeriod))
								.foregroundColor(.gray)
						}
					}
					
					NavigationLink(destination: MonthlyBudgetView()) {
						HStack {
							if settings.budgetPeriod == "Monthly" {
								Text(LocalizedStringKey("Monthly Budget"))
							} else {
								Text(LocalizedStringKey("Weekly Budget"))
							}
							Spacer()
							Text("\(currencySymbol)\(settings.monthlyBudget, specifier: "%.0f")")
								.foregroundColor(.gray)
						}
					}
					
					if settings.budgetPeriod == "Monthly" {
						Picker("Start day of month", selection: Binding(get: { settings.monthlyStartDay }, set: { settings.monthlyStartDay = $0 })) {
							ForEach(1...31, id: \.self) {
								Text("\($0)")
							}
						}
					}
					
					if settings.budgetPeriod == "Weekly" {
						Picker("Start day of week", selection: Binding(get: { settings.weeklyStartDay }, set: { settings.weeklyStartDay = $0 })) {
							ForEach(0..<Calendar.current.weekdaySymbols.count, id: \.self) { index in
								Text(Calendar.current.weekdaySymbols[index]).tag(index + 1)
							}
						}
					}
				}
			}
		}
		.onChange(of: settings.budgetTrackingEnabled) { _ in
			NotificationCenter.default.post(name: Notification.Name("budgetTrackingChanged"), object: nil)
		}
		.navigationTitle("Budget & Planning")
		.navigationBarTitleDisplayMode(.inline)
	}
}
