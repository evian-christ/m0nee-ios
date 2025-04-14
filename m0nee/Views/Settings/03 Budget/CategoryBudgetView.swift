import SwiftUI

struct CategoryBudgetView: View {
	@AppStorage("categories") private var categories: String = "Food,Transport,Other"
	@AppStorage("categoryBudgets") private var categoryBudgets: String = ""
	
	@State private var budgetDict: [String: String] = [:]
	
	var categoryList: [String] {
		categories.split(separator: ",").map { String($0) }
	}
	
	func loadBudgets() {
		let pairs = categoryBudgets.split(separator: ",").map { $0.split(separator: ":") }
		for pair in pairs {
			if pair.count == 2 {
				let category = String(pair[0])
				let amount = String(pair[1])
				budgetDict[category] = amount
			}
		}
		for category in categoryList where budgetDict[category] == nil {
			budgetDict[category] = "0"
		}
	}
	
	func saveBudgets() {
		let validEntries = budgetDict.map { "\($0.key):\($0.value)" }
		categoryBudgets = validEntries.joined(separator: ",")
	}
	
	var body: some View {
		Form {
			ForEach(categoryList, id: \.self) { category in
				HStack {
					Text(category)
					Spacer()
					TextField("0", text: Binding(
						get: { budgetDict[category, default: "0"] },
						set: {
							let cleaned = String(Int($0) ?? 0)
							budgetDict[category] = cleaned
							saveBudgets()
						}
					))
					.keyboardType(.numberPad)
					.multilineTextAlignment(.trailing)
					.padding(8)
					.background(Color(.systemGray6))
					.cornerRadius(6)
					.overlay(
						RoundedRectangle(cornerRadius: 6)
							.stroke(Color.gray.opacity(0.3), lineWidth: 1)
					)
					.frame(width: 100)
					.textInputAutocapitalization(.never)
					.disableAutocorrection(true)
					.textSelection(.disabled)
				}
			}
		}
		.navigationTitle("Category Budgets")
		.onAppear {
			loadBudgets()
		}
	}
}
