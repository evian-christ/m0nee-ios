import SwiftUI

struct BudgetFrequencyView: View {
	@AppStorage("budgetPeriod") private var budgetPeriod: String = "Monthly"
	let frequencies = ["Weekly", "Monthly"]
	
	var body: some View {
		Form {
			Picker("Select Period", selection: $budgetPeriod) {
				ForEach(frequencies, id: \.self) { frequency in
					Text(frequency).tag(frequency)
				}
			}
			.pickerStyle(.inline)
		}
		.navigationTitle("Budget Period")
	}
}
