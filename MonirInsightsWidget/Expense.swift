import Foundation

struct Expense: Identifiable, Codable {
		let id: UUID
		let date: Date
		let name: String
		let amount: Double
		let category: String
		let details: String?
		let rating: Int?
		let memo: String?
		let isRecurring: Bool
		let parentRecurringID: UUID?
}
