import Foundation

protocol RecurringExpenseScheduling {
    func generateExpenses(for recurringExpenses: inout [RecurringExpense], currentDate: Date) -> [Expense]
    func prepareRecurringForAdd(_ recurring: RecurringExpense, currentDate: Date) -> (RecurringExpense, [Expense])
    func nextOccurrence(for recurring: RecurringExpense) -> Date?
    func shouldGenerate(rule: RecurrenceRule, on date: Date) -> Bool
}

struct RecurringExpenseService: RecurringExpenseScheduling {
    func generateExpenses(for recurringExpenses: inout [RecurringExpense], currentDate: Date) -> [Expense] {
        var generated: [Expense] = []
        for index in recurringExpenses.indices {
            var recurring = recurringExpenses[index]
            let rule = recurring.recurrenceRule
            let calendar = Calendar.current

            var currentGenerationDate: Date
            if let lastGeneratedDate = recurring.lastGeneratedDate {
                currentGenerationDate = calendar.date(byAdding: .day, value: 1, to: lastGeneratedDate) ?? lastGeneratedDate
            } else {
                currentGenerationDate = rule.startDate
            }

            while currentGenerationDate <= currentDate {
                if shouldGenerate(rule: rule, on: currentGenerationDate) {
                    let expense = Expense(
                        id: UUID(),
                        date: currentGenerationDate,
                        name: recurring.name,
                        amount: recurring.amount,
                        category: recurring.category,
                        details: recurring.details,
                        rating: nil,
                        memo: recurring.memo,
                        isRecurring: true,
                        parentRecurringID: recurring.id
                    )
                    generated.append(expense)
                    recurring.lastGeneratedDate = currentGenerationDate
                }

                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentGenerationDate) else { break }
                currentGenerationDate = nextDate
            }

            recurringExpenses[index] = recurring
        }
        return generated
    }

    func prepareRecurringForAdd(_ recurring: RecurringExpense, currentDate: Date) -> (RecurringExpense, [Expense]) {
        var sanitized = sanitize(recurring)
        var items = [sanitized]
        let expenses = generateExpenses(for: &items, currentDate: currentDate)
        sanitized = items[0]
        return (sanitized, expenses)
    }

    func nextOccurrence(for recurring: RecurringExpense) -> Date? {
        let rule = recurring.recurrenceRule
        let calendar = Calendar.current

        var candidate: Date
        if let lastGeneratedDate = recurring.lastGeneratedDate {
            candidate = calendar.date(byAdding: .day, value: 1, to: lastGeneratedDate) ?? lastGeneratedDate
        } else {
            candidate = rule.startDate
        }

        for _ in 0..<(365 * 5) {
            if shouldGenerate(rule: rule, on: candidate) {
                return candidate
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: candidate) else { break }
            candidate = nextDate
        }

        return nil
    }

    func shouldGenerate(rule: RecurrenceRule, on date: Date) -> Bool {
        let calendar = Calendar.current

        switch rule.frequencyType {
        case .everyN:
            switch rule.period {
            case .daily:
                let daysBetween = calendar.dateComponents([.day], from: rule.startDate, to: date).day ?? 0
                return daysBetween >= 0 && daysBetween % rule.interval == 0
            case .weekly:
                let startWeekday = calendar.component(.weekday, from: rule.startDate)
                let currentWeekday = calendar.component(.weekday, from: date)
                guard startWeekday == currentWeekday else { return false }
                let weeksBetween = calendar.dateComponents([.weekOfYear], from: rule.startDate, to: date).weekOfYear ?? 0
                return weeksBetween >= 0 && weeksBetween % rule.interval == 0
            case .monthly:
                let startDay = calendar.component(.day, from: rule.startDate)
                let currentDay = calendar.component(.day, from: date)
                guard startDay == currentDay else { return false }
                let monthsBetween = calendar.dateComponents([.month], from: rule.startDate, to: date).month ?? 0
                return monthsBetween >= 0 && monthsBetween % rule.interval == 0
            }

        case .weeklySelectedDays:
            let weekday = calendar.component(.weekday, from: date)
            return rule.selectedWeekdays?.contains(weekday) ?? false

        case .monthlySelectedDays:
            let day = calendar.component(.day, from: date)
            return rule.selectedMonthDays?.contains(day) ?? false
        }
    }

    private func sanitize(_ recurring: RecurringExpense) -> RecurringExpense {
        var mutable = recurring
        switch mutable.recurrenceRule.frequencyType {
        case .weeklySelectedDays:
            mutable.recurrenceRule.selectedMonthDays = nil
            mutable.recurrenceRule.interval = 0
        case .monthlySelectedDays:
            mutable.recurrenceRule.selectedWeekdays = nil
            mutable.recurrenceRule.interval = 0
        case .everyN:
            mutable.recurrenceRule.selectedWeekdays = nil
            mutable.recurrenceRule.selectedMonthDays = nil
        }
        return mutable
    }
}
