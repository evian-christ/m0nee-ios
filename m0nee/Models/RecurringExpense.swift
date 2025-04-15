import Foundation

struct RecurringExpense: Identifiable, Codable {
	let id: UUID
	let name: String
	let amount: Double
	let category: String
	let details: String?
	let rating: Int?
	let memo: String?
	let startDate: Date
	let recurrenceRule: RecurrenceRule
	var lastGeneratedDate: Date?
}

struct RecurrenceRule: Codable {
	enum Frequency: String, Codable {
		case daily
		case weekly
		case monthly
		case quarterly
		case yearly
		case custom
	}

	var frequency: Frequency
	var interval: Int?           // e.g. every 2 weeks
	var weekdays: [Int]?         // [1 = Sunday, ..., 7 = Saturday]
	var endDate: Date?
}
