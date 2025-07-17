import SwiftUI

struct CategoryBudgetView: View {
	@ObservedObject var store: ExpenseStore
	@State private var budgetInputs: [String: String] = [:]
	@State private var selectedCategory: CategoryItem?
	@State private var showAlert: Bool = false
	@State private var alertInput: String = ""
	@AppStorage("currencyCode", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

	private var currencySymbol: String {
		CurrencyManager.symbol(for: currencyCode)
	}
	
	var body: some View {
		List {
			ForEach(store.categories) { category in
				Button {
					selectedCategory = category
					alertInput = budgetInputs[category.name, default: "0"]
					showAlert = true
				} label: {
					HStack {
						ZStack {
							Circle()
								.fill(category.color.color)
								.frame(width: 30, height: 30)
							Image(systemName: category.symbol)
								.font(.system(size: 14))
								.foregroundColor(.white)
						}
						
						Text(category.name)
							.foregroundColor(.primary)
							.padding(.leading, 6)
						
						Spacer()
						
						HStack(spacing: 4) {
							Text("\(currencySymbol)\(budgetInputs[category.name, default: "0"])")
								.foregroundColor(.secondary)
							Image(systemName: "chevron.right")
								.font(.system(size: 12, weight: .semibold))
								.foregroundColor(.gray)
						}
					}
					.padding(.vertical, 4)
				}
			}
		}
		.onAppear {
			let sharedDefaults = UserDefaults(suiteName: "group.com.chankim.Monir")
			if let data = sharedDefaults?.data(forKey: "categoryBudgets"),
				 let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
				budgetInputs = decoded
			}
		}
		.navigationTitle("Category Budgets")
		.alert("Set Budget", isPresented: $showAlert, actions: {
			TextField("Amount", text: $alertInput)
				.keyboardType(.numberPad)
			Button("OK") {
				if let selected = selectedCategory {
					let rawDouble = Double(alertInput) ?? 0
					let positiveValue = abs(rawDouble)
					let roundedValue = Int(round(positiveValue))
					let cleanValue = String(roundedValue)
					budgetInputs[selected.name] = cleanValue
					if let encoded = try? JSONEncoder().encode(budgetInputs) {
						UserDefaults(suiteName: "group.com.chankim.Monir")?.set(encoded, forKey: "categoryBudgets")
					}
				}
			}
			Button("Cancel", role: .cancel) {}
		}, message: {
			if let selected = selectedCategory {
				Text("Enter budget for \(selected.name)")
			}
		})
	}
}
