import Foundation

enum DecimalDisplayMode: String, CaseIterable, Identifiable, Codable {
	case automatic = "Automatic"
	case twoPlaces = "Two Places"
	case none = "None"
	
	var id: String { self.rawValue }
}
