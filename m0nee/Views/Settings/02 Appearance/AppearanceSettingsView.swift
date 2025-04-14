import SwiftUI

struct AppearanceSettingsView: View {
	@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
	@AppStorage("currencyCode") private var currencyCode: String = "GBP"

	var body: some View {
		Form {
			Section(header: Text("Theme")) {
				Picker("", selection: $appearanceMode) {
					Text("Automatic").tag("Automatic")
					Text("Light").tag("Light")
					Text("Dark").tag("Dark")
				}
				.pickerStyle(.inline)
				.labelsHidden()
			}
			
			Section(header: Text("Currency Symbol")) {
				Picker("Currency", selection: $currencyCode) {
					ForEach(CurrencyManager.currencyOptions, id: \.code) { option in
						Text("\(option.code) (\(option.symbol))").tag(option.code)
					}
				}
			}
		}
		.navigationTitle("Appearance")
		.navigationBarTitleDisplayMode(.inline)
	}
}
