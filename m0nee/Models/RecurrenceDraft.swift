import SwiftUI

enum Period: String, CaseIterable, Identifiable, Codable, LocalizedCaseIterable {
    case never = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var id: String { self.rawValue }

    var localizedStringKey: LocalizedStringKey {
        switch self {
        case .never: return "Never"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct RecurrenceDraft {
    var selectedPeriod: Period = .never
    var frequencyType: RecurrenceRule.FrequencyType = .everyN
    var selectedWeekdays: [Int] = []
    var selectedMonthDays: [Int] = []
    var dayInterval: Int = 1 {
        didSet {
            if dayInterval < 1 {
                dayInterval = 1
            }
        }
    }
}
