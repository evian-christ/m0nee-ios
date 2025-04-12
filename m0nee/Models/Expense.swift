import Foundation

struct Expense: Identifiable, Codable {
		let id: UUID
		var date: Date
		var name: String
		var amount: Double
		var category: String
		var details: String?
		var rating: Int?
		var memo: String?
}
