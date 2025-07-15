import Foundation

enum DecimalDisplayMode: String, CaseIterable, Identifiable, Codable {
	case automatic = "Automatic"
	case twoPlaces = "Two Places"
	case none = "None"
	
	var id: String { self.rawValue }
	
	var localizedTitle: String {
		switch self {
		case .automatic:
			return NSLocalizedString("DecimalDisplayMode.Automatic", comment: "Automatic decimal display mode")
		case .twoPlaces:
			return NSLocalizedString("DecimalDisplayMode.TwoPlaces", comment: "Two decimal places")
		case .none:
			return NSLocalizedString("DecimalDisplayMode.None", comment: "No decimals")
		}
	}
}
