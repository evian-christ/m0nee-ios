import Foundation

struct CurrencyManager {
		static let currencyOptions: [(symbol: String, code: String)] = [
				("$", "USD"), ("€", "EUR"), ("£", "GBP"), ("¥", "JPY"),
				("₩", "KRW"), ("¥", "CNY"), ("A$", "AUD"), ("C$", "CAD"),
				("R$", "BRL"), ("CHF", "CHF"), ("₵", "GHS"), ("₪", "ILS"),
				("₹", "INR"), ("₦", "NGN"), ("NOK", "NOK"), ("₱", "PHP"),
				("₽", "RUB"), ("S$", "SGD"), ("SEK", "SEK"), ("฿", "THB"),
				("₺", "TRY"), ("₴", "UAH"), ("₫", "VND"), ("R", "ZAR"),
				("د.إ", "AED"), ("DKK", "DKK"), ("NZ$", "NZD"), ("₲", "PYG")
		]

		static func symbol(for code: String) -> String {
				currencyOptions.first(where: { $0.code == code })?.symbol ?? "£"
		}
}
