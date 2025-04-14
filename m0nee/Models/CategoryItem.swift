import Foundation
import SwiftUI

struct CategoryItem: Identifiable, Codable, Equatable {
	var id: UUID = UUID()
	var name: String
	var symbol: String
	var color: CodableColor
}
