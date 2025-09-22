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
    var budgetID: UUID

    enum CodingKeys: String, CodingKey {
        case id, name, amount, category, details, rating, memo, startDate, recurrenceRule, lastGeneratedDate, budgetID
    }

    init(
        id: UUID,
        name: String,
        amount: Double,
        category: String,
        details: String?,
        rating: Int?,
        memo: String?,
        startDate: Date,
        recurrenceRule: RecurrenceRule,
        lastGeneratedDate: Date?,
        budgetID: UUID = UUID()
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.details = details
        self.rating = rating
        self.memo = memo
        self.startDate = startDate
        self.recurrenceRule = recurrenceRule
        self.lastGeneratedDate = lastGeneratedDate
        self.budgetID = budgetID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        amount = try container.decode(Double.self, forKey: .amount)
        category = try container.decode(String.self, forKey: .category)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        memo = try container.decodeIfPresent(String.self, forKey: .memo)
        startDate = try container.decode(Date.self, forKey: .startDate)
        recurrenceRule = try container.decode(RecurrenceRule.self, forKey: .recurrenceRule)
        lastGeneratedDate = try container.decodeIfPresent(Date.self, forKey: .lastGeneratedDate)
        budgetID = try container.decodeIfPresent(UUID.self, forKey: .budgetID) ?? UUID()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(amount, forKey: .amount)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(details, forKey: .details)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(memo, forKey: .memo)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(recurrenceRule, forKey: .recurrenceRule)
        try container.encodeIfPresent(lastGeneratedDate, forKey: .lastGeneratedDate)
        try container.encode(budgetID, forKey: .budgetID)
    }
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
