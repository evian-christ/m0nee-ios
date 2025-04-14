import SwiftUI

struct AppearanceSettingsView: View {
		@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
		@AppStorage("currencySymbol") private var currencySymbol: String = "£"

		let currencyOptions: [(symbol: String, country: String)] = [
				("£", "United Kingdom"),
				("$", "United States"),
				("€", "Eurozone"),
				("₩", "South Korea"),
				("¥", "Japan"),
				("₹", "India"),
				("₽", "Russia"),
				("฿", "Thailand"),
				("₫", "Vietnam"),
				("₴", "Ukraine"),
				("₪", "Israel"),
				("₦", "Nigeria"),
				("₲", "Paraguay"),
				("₵", "Ghana")
		]

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
								Picker("Currency", selection: $currencySymbol) {
										ForEach(currencyOptions, id: \.symbol) { option in
												Text("\(option.symbol) - \(option.country)").tag(option.symbol)
										}
								}
						}
				}
				.navigationTitle("Appearance")
				.navigationBarTitleDisplayMode(.inline)
		}
}
