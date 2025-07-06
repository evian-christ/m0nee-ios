import SwiftUI

struct AppearanceSettingsView: View {
	@AppStorage("appearanceMode") private var appearanceMode: String = "Automatic"
	@AppStorage("currencyCode", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"

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
			
			Section(header: Text("Language")) {
				Button("Change Language in Settings") {
					if let url = URL(string: UIApplication.openSettingsURLString) {
						UIApplication.shared.open(url)
					}
				}
				.foregroundColor(.blue)
			}
		}
		.navigationTitle("Appearance")
		.navigationBarTitleDisplayMode(.inline)
	}
}
