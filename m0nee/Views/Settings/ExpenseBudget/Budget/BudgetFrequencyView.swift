import SwiftUI

struct BudgetFrequencyView: View {
	@EnvironmentObject var settings: AppSettings
	let frequencies = ["Weekly", "Monthly"]

	var body: some View {
		Form {
			Picker("Select Period", selection: settings.binding(\.budgetPeriod)) {
				ForEach(frequencies, id: \.self) { frequency in
					Text(LocalizedStringKey(frequency)).tag(frequency)
				}
			}
			.pickerStyle(.inline)
		}
		.navigationTitle("Budget Period")
	}
}
