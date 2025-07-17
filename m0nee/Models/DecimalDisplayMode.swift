import Foundation

enum DecimalDisplayMode: String, CaseIterable, Identifiable, Codable {
	case automatic = "Automatic"
	case twoPlaces = "Two Places"
	case none = "None"
	
	var id: String { self.rawValue }
	
	var localizedTitle: String {
		switch self {
		case .automatic:
			return NSLocalizedString("Automatic", comment: "Automatic decimal display mode")
		case .twoPlaces:
			return NSLocalizedString("Two Places", comment: "Two decimal places")
		case .none:
			return NSLocalizedString("None", comment: "No decimals")
		}
	}
}
