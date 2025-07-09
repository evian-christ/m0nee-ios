import Foundation

struct RecurringExpense: Identifiable, Codable, Hashable {
	let id: UUID
	var name: String
	var amount: Double
	var category: String
	var details: String?
	var rating: Int?
	var memo: String?
	let startDate: Date
	var recurrenceRule: RecurrenceRule
	var lastGeneratedDate: Date?
}

struct RecurrenceRule: Codable, Hashable {
	enum Period: String, Codable {
		case daily, weekly, monthly
	}
	
	enum FrequencyType: String, Codable {
		case everyN
		case weeklySelectedDays
		case monthlySelectedDays
	}
	
	var period: Period
	var frequencyType: FrequencyType
	var interval: Int       // e.g., N in "every N days"
	var selectedWeekdays: [Int]?   // 1 = Sunday, ..., 7 = Saturday
	var selectedMonthDays: [Int]?  // 1...31
	var startDate: Date
	var endDate: Date?
}
