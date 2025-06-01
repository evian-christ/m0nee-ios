import Foundation

struct Expense: Identifiable, Codable {
		let id: UUID
		let date: Date
		let name: String
		let amount: Double
		let category: String
}
