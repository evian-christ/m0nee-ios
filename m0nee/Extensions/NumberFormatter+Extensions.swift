import Foundation

extension NumberFormatter {
	static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? Locale.current.currency?.identifier ?? "USD"
        formatter.currencySymbol = CurrencyManager.symbol(for: currencyCode)
        return formatter
    }
}
