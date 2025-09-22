import Foundation

struct Budget: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var goalAmount: Double?
    var startDate: Date?
    var endDate: Date?
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        goalAmount: Double? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.goalAmount = goalAmount
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
    }
}
