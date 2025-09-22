import Foundation

struct Expense: Identifiable, Codable {
		var id: UUID
		var date: Date
		var name: String
		var amount: Double
		var category: String
		var details: String?
		var rating: Int?
		var memo: String?
		var isRecurring: Bool = false
		var parentRecurringID: UUID?
		var budgetID: UUID

		enum CodingKeys: String, CodingKey {
				case id, date, name, amount, category, details, rating, memo, isRecurring, parentRecurringID, budgetID
		}

		init(id: UUID, date: Date, name: String, amount: Double, category: String, details: String?, rating: Int?, memo: String?, isRecurring: Bool = false, parentRecurringID: UUID? = nil, budgetID: UUID = UUID()) {
				self.id = id
				self.date = date
				self.name = name
				self.amount = amount
				self.category = category
				self.details = details
				self.rating = rating
				self.memo = memo
				self.isRecurring = isRecurring
				self.parentRecurringID = parentRecurringID
				self.budgetID = budgetID
		}

		init(from decoder: Decoder) throws {
				let container = try decoder.container(keyedBy: CodingKeys.self)

				id = try container.decode(UUID.self, forKey: .id)
				date = try container.decode(Date.self, forKey: .date)
				name = try container.decode(String.self, forKey: .name)
				amount = try container.decode(Double.self, forKey: .amount)
				category = try container.decode(String.self, forKey: .category)
				details = try container.decodeIfPresent(String.self, forKey: .details)
				rating = try container.decodeIfPresent(Int.self, forKey: .rating)
				memo = try container.decodeIfPresent(String.self, forKey: .memo)
				isRecurring = try container.decodeIfPresent(Bool.self, forKey: .isRecurring) ?? false
				parentRecurringID = try container.decodeIfPresent(UUID.self, forKey: .parentRecurringID)
				budgetID = try container.decodeIfPresent(UUID.self, forKey: .budgetID) ?? UUID()
		}

		func encode(to encoder: Encoder) throws {
				var container = encoder.container(keyedBy: CodingKeys.self)

				try container.encode(id, forKey: .id)
				try container.encode(date, forKey: .date)
				try container.encode(name, forKey: .name)
				try container.encode(amount, forKey: .amount)
				try container.encode(category, forKey: .category)
				try container.encodeIfPresent(details, forKey: .details)
				try container.encodeIfPresent(rating, forKey: .rating)
				try container.encodeIfPresent(memo, forKey: .memo)
				try container.encode(isRecurring, forKey: .isRecurring)
				try container.encodeIfPresent(parentRecurringID, forKey: .parentRecurringID)
				try container.encode(budgetID, forKey: .budgetID)
		}
}
