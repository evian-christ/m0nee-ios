import Foundation

extension NumberFormatter {
	static func currency(for mode: DecimalDisplayMode, currencyCode: String) -> NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencyCode = currencyCode
		
		switch mode {
		case .automatic:
			let tempFormatter = NumberFormatter()
			tempFormatter.numberStyle = .currency
			tempFormatter.currencyCode = currencyCode // Set the currency code to get its default decimal digits
			formatter.minimumFractionDigits = tempFormatter.maximumFractionDigits
			formatter.maximumFractionDigits = tempFormatter.maximumFractionDigits
		case .twoPlaces:
			formatter.minimumFractionDigits = 2
			formatter.maximumFractionDigits = 2
		case .none:
			formatter.minimumFractionDigits = 0
			formatter.maximumFractionDigits = 0
		}
		
		return formatter
	}
}
