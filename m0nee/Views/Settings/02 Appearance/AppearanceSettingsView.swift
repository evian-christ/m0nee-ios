import SwiftUI

struct AppearanceSettingsView: View {
	@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
	@AppStorage("currencyCode") private var currencyCode: String = "GBP"
	
	let currencyOptions: [(symbol: String, code: String)] = [
		("$", "USD"),
		("€", "EUR"),
		("£", "GBP"),
		("¥", "JPY"),
		("₩", "KRW"),
		("¥", "CNY"),
		("A$", "AUD"),
		("C$", "CAD"),
		("R$", "BRL"),
		("CHF", "CHF"),
		("₵", "GHS"),
		("₪", "ILS"),
		("₹", "INR"),
		("₦", "NGN"),
		("NOK", "NOK"),
		("₱", "PHP"),
		("₽", "RUB"),
		("S$", "SGD"),
		("SEK", "SEK"),
		("฿", "THB"),
		("₺", "TRY"),
		("₴", "UAH"),
		("₫", "VND"),
		("R", "ZAR"),
		("د.إ", "AED"),
		("DKK", "DKK"),
		("NZ$", "NZD"),
		("₲", "PYG")
	]
	
	var selectedCurrencySymbol: String {
		currencyOptions.first(where: { $0.code == currencyCode })?.symbol ?? "£"
	}
	
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
					ForEach(currencyOptions, id: \.code) { option in
						Text("\(option.code) (\(option.symbol))").tag(option.code)
					}
				}
			}
		}
		.navigationTitle("Appearance")
		.navigationBarTitleDisplayMode(.inline)
	}
}
