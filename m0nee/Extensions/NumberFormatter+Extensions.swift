import Foundation

extension NumberFormatter {
	static var currency: NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "£"
		return formatter
	}
}
