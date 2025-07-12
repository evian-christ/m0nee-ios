import Foundation
import SwiftUI
import WidgetKit

private struct StoreData: Codable {
		var expenses: [Expense]
		var categories: [CategoryItem]
		var recurringExpenses: [RecurringExpense]
}

import StoreKit

struct TotalSpendingWidgetData: Codable {
    let amountSpent: Double
    let monthlyBudget: Double
    let currencySymbol: String
    let budgetTrackingEnabled: Bool
}

class ExpenseStore: ObservableObject {
		@Published var expenses: [Expense] = []
		@Published var productID: String? // Track the product ID for pro status
		@Published var isPromoProUser: Bool = false {
			didSet {
				UserDefaults.standard.set(isPromoProUser, forKey: "isPromoProUser")
			}
		} // Track promo code activation

		var isProUser: Bool {
			return productID == "com.chan.monir.pro.monthly" || productID == "com.chan.monir.pro.lifetime" || isPromoProUser
		}
		@Published var categories: [CategoryItem] = []
		@Published var recurringExpenses: [RecurringExpense] = []
		@Published var restoredFromBackup: Bool = false
		@Published var failedToRestore: Bool = false
		
		private var saveURL: URL
		
		// 기존 init()을 새로운 init(forTesting:)으로 연결
		convenience init() {
			self.init(forTesting: false)
		}

		// 테스트를 위한 새로운 초기화 메서드
		init(forTesting: Bool = false) {
				let fileManager = FileManager.default
				let localURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("expenses.json")
				let iCloudURL: URL
				let defaults = UserDefaults.standard
				let hasUseiCloudKey = defaults.object(forKey: "useiCloud") != nil

				let useiCloud: Bool
				if hasUseiCloudKey {
						useiCloud = defaults.bool(forKey: "useiCloud")
				} else {
						useiCloud = true
						defaults.set(useiCloud, forKey: "useiCloud")
				}

				// Load isPromoProUser from UserDefaults
				self.isPromoProUser = defaults.bool(forKey: "isPromoProUser")

				if useiCloud, let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
						try? fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)
						iCloudURL = containerURL.appendingPathComponent("expenses.json")

						let localExists = fileManager.fileExists(atPath: localURL.path)
						let iCloudExists = fileManager.fileExists(atPath: iCloudURL.path)

						if iCloudExists {
								// ✅ iCloud 파일이 있으면 그걸 무조건 사용
								self.saveURL = iCloudURL
								print("☁️ Using existing iCloud data")
						} else if localExists {
								// ✅ iCloud엔 없지만 로컬엔 있으면 복사
								do {
										try fileManager.copyItem(at: localURL, to: iCloudURL)
										print("☁️ Copied local data to iCloud")
								} catch {
										print("❌ Failed to copy local data to iCloud: \(error)")
								}
								self.saveURL = iCloudURL
						} else {
								// ✅ 아무 것도 없으면 iCloud 경로를 그냥 사용
								self.saveURL = iCloudURL
								print("☁️ No data found, using fresh iCloud path")
						}

						if !forTesting { syncStorageIfNeeded() }
				} else {
						self.saveURL = localURL
				}

				print("💾 Using saveURL: \(saveURL.path)")
				if !forTesting { load() }
				if categories.isEmpty && !forTesting {
					categories = [
						CategoryItem(name: "No Category", symbol: "tray", color: CodableColor(.gray)),
						CategoryItem(name: "Food", symbol: "fork.knife", color: CodableColor(.red)),
						CategoryItem(name: "Transport", symbol: "car.fill", color: CodableColor(.blue)),
						CategoryItem(name: "Entertainment", symbol: "gamecontroller.fill", color: CodableColor(.purple)),
						CategoryItem(name: "Rent", symbol: "house.fill", color: CodableColor(.orange)),
						CategoryItem(name: "Shopping", symbol: "bag.fill", color: CodableColor(.pink))
					]
					
					// 예산도 같이 초기화
					var budgets: [String: String] = [:]
					for category in categories {
						budgets[category.name] = "0"
					}
					if let encoded = try? JSONEncoder().encode(budgets) {
						UserDefaults.standard.set(encoded, forKey: "categoryBudgets")
					}
					
					save()
				}
			//recurringExpenses.removeAll()
			//save()
				if !forTesting { generateExpensesFromRecurringIfNeeded() }
		}
		
		func addCategory(_ category: CategoryItem) {
				categories.append(category)
				ensureCategoryBudgetEntry(for: category.name)
				save()
		}

		func removeCategory(_ category: CategoryItem) {
				categories.removeAll { $0.id == category.id }
				removeCategoryBudgetEntry(for: category.name)
				save()
		}

		func updateCategory(_ category: CategoryItem) {
			guard let index = categories.firstIndex(where: { $0.id == category.id }) else {
				return
			}
			let oldCategoryName = categories[index].name
			categories[index] = category
			
			for i in expenses.indices {
				if expenses[i].category == oldCategoryName {
					expenses[i].category = category.name
				}
			}
			
			for i in recurringExpenses.indices {
				if recurringExpenses[i].category == oldCategoryName {
					recurringExpenses[i].category = category.name
				}
			}
			
			save()
		}

		private func ensureCategoryBudgetEntry(for name: String) {
				var budgets = loadBudgets()
				if budgets[name] == nil {
						budgets[name] = "0"
						saveBudgets(budgets)
				}
		}

		private func removeCategoryBudgetEntry(for name: String) {
				var budgets = loadBudgets()
				budgets.removeValue(forKey: name)
				saveBudgets(budgets)
		}

		private func loadBudgets() -> [String: String] {
				if let data = UserDefaults.standard.data(forKey: "categoryBudgets"),
						let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
						return decoded
				}
				return [:]
		}

		private func saveBudgets(_ budgets: [String: String]) {
				if let encoded = try? JSONEncoder().encode(budgets) {
						UserDefaults.standard.set(encoded, forKey: "categoryBudgets")
				}
		}

	
	func generateExpensesFromRecurringIfNeeded(currentDate: Date = Date()) {
			for index in recurringExpenses.indices {
				var recurring = recurringExpenses[index]
				let rule = recurring.recurrenceRule
				let calendar = Calendar.current

				// Capture the last generated date *before* this run starts
				let initialLastGeneratedDate = recurring.lastGeneratedDate

				// Determine the actual start date for this generation run
				// Start from the day after the initialLastGeneratedDate, or from rule.startDate if no previous generation
				var currentGenerationDate: Date
				if let lastGen = initialLastGeneratedDate {
					currentGenerationDate = calendar.date(byAdding: .day, value: 1, to: lastGen)!
				} else {
					currentGenerationDate = rule.startDate
				}

				let endDate = currentDate

				while currentGenerationDate <= endDate {
					if shouldGenerateToday(for: rule, on: currentGenerationDate) {
						let newExpense = Expense(
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
						add(newExpense)
						// Update lastGeneratedDate as we generate
						recurring.lastGeneratedDate = currentGenerationDate
					}

					// Advance currentGenerationDate based on recurrence rule
									currentGenerationDate = calendar.date(byAdding: .day, value: 1, to: currentGenerationDate) ?? currentGenerationDate
				}

				recurringExpenses[index] = recurring
			}

			save()
		}

		func removeRecurringExpense(id: UUID) {
			if let index = recurringExpenses.firstIndex(where: { $0.id == id }) {
				recurringExpenses.remove(at: index)
				save()
			}
		}

		func updateRecurringExpenseMetadata(_ updatedExpense: RecurringExpense) {
			// 1. Find the index of the recurring expense to update.
			guard let index = recurringExpenses.firstIndex(where: { $0.id == updatedExpense.id }) else {
				return
			}

			// 2. Update the main recurring expense object.
			recurringExpenses[index].name = updatedExpense.name
			recurringExpenses[index].amount = updatedExpense.amount
			recurringExpenses[index].category = updatedExpense.category
			recurringExpenses[index].memo = updatedExpense.memo
			recurringExpenses[index].details = updatedExpense.details

			// 3. Update all associated individual expenses that were already generated.
			for i in expenses.indices {
				if expenses[i].parentRecurringID == updatedExpense.id {
					expenses[i].name = updatedExpense.name
					expenses[i].amount = updatedExpense.amount
					expenses[i].category = updatedExpense.category
					expenses[i].memo = updatedExpense.memo
					expenses[i].details = updatedExpense.details
				}
			}
			
			save()
		}

		func removeAllExpenses(withParentID parentID: UUID) {
			expenses.removeAll { $0.parentRecurringID == parentID }
			save()
		}

		/// Returns the next occurrence date after today (or the next after lastGeneratedDate) for the given recurring expense.
		func nextOccurrence(for recurring: RecurringExpense) -> Date? {
			let rule = recurring.recurrenceRule
			let calendar = Calendar.current
			
			// Start searching from the day after the last generated date, or the rule's start date if none.
			var candidate: Date
			if let lastGen = recurring.lastGeneratedDate {
				candidate = calendar.date(byAdding: .day, value: 1, to: lastGen)!
			} else {
				candidate = rule.startDate
			}
	
			// Loop up to a reasonable limit to prevent infinite loops
			for _ in 0..<365*5 { // Look ahead up to 5 years
				if shouldGenerateToday(for: rule, on: candidate) {
					return candidate // Found the next valid date
				}
				candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
			}
	
			return nil // Return nil if no occurrence is found within the look-ahead period
		}
}

extension ExpenseStore {
		func save() {
				do {
						let storeData = StoreData(expenses: expenses, categories: categories, recurringExpenses: recurringExpenses)
						let data = try JSONEncoder().encode(storeData)
						try data.write(to: saveURL)
						//print("📁 Saved to: \(saveURL.path.contains("Mobile Documents") ? "iCloud" : "Local")")
						// Also write local backup if using iCloud
						if saveURL.path.contains("Mobile Documents") {
								let backupURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
										.appendingPathComponent("expenses_backup_for_recovery.json")
								do {
										try data.write(to: backupURL)
										//print("🛟 Local backup saved at \(backupURL.path)")
								} catch {
										//print("❌ Failed to save local backup: \(error)")
								}
						}
						let isICloud = saveURL.path.contains("Mobile Documents")
						//print("\(isICloud ? "☁️" : "💾") Saved \(expenses.count) expenses")
				} catch {
						print("Failed to save: \(error)")
				}
				// --- Widget/App Group Sync ---
				if let encodedExpenses = try? JSONEncoder().encode(expenses) {
						let sharedDefaults = UserDefaults(suiteName: "group.com.chankim.Monir")
						sharedDefaults?.set(encodedExpenses, forKey: "shared_expenses")
						//print("[✅ WidgetSync] Saved \(expenses.count) expenses to shared_expenses.")
				} else {
						print("[❌ WidgetSync] Failed to encode expenses for widget.")
				}
            updateTotalSpendingWidgetData()
		}

    func updateTotalSpendingWidgetData() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.chankim.Monir")
        let budgetTrackingEnabled = sharedDefaults?.bool(forKey: "enableBudgetTracking") ?? true
        let budgetPeriod = sharedDefaults?.string(forKey: "budgetPeriod") ?? "Monthly"
        let monthlyBudget = sharedDefaults?.double(forKey: "monthlyBudget") ?? 0.0
        let budgetByCategory = sharedDefaults?.bool(forKey: "budgetByCategory") ?? false
        let categoryBudgetsData = sharedDefaults?.data(forKey: "categoryBudgets")
        let currencyCode = sharedDefaults?.string(forKey: "currencyCode") ?? Locale.current.currency?.identifier ?? "USD"
        let currencySymbol = CurrencyManager.symbol(for: currencyCode)

        let calendar = Calendar.current
        let today = Date()

        var startDate: Date
        var endDate: Date

        if budgetPeriod == "Weekly" {
            let weeklyStartDay = sharedDefaults?.integer(forKey: "weeklyStartDay") ?? 1
            let weekdayToday = calendar.component(.weekday, from: today)
            let delta = (weekdayToday - weeklyStartDay + 7) % 7
            startDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -delta, to: today) ?? today)
            endDate = calendar.date(byAdding: .day, value: 6, to: startDate) ?? startDate
        } else { // Monthly
            let monthlyStartDay = sharedDefaults?.integer(forKey: "monthlyStartDay") ?? 1
            let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            startDate = calendar.date(byAdding: .day, value: monthlyStartDay - 1, to: currentMonth) ?? currentMonth
            if calendar.component(.day, from: today) < monthlyStartDay {
                startDate = calendar.date(byAdding: .month, value: -1, to: startDate) ?? startDate
            }
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
            endDate = calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? nextMonth
        }

        let filteredExpenses = expenses.filter { expense in
            let expenseDate = calendar.startOfDay(for: expense.date)
            return expenseDate >= startDate && expenseDate <= endDate
        }

        let totalAmountSpent = filteredExpenses.reduce(0) { $0 + $1.amount }

        var currentBudget = monthlyBudget
        if budgetByCategory {
            if let decodedCategoryBudgets = try? JSONDecoder().decode([String: String].self, from: categoryBudgetsData ?? Data()) {
                currentBudget = decodedCategoryBudgets.values.compactMap { Double($0) }.reduce(0, +)
            }
        }

        let widgetData = TotalSpendingWidgetData(
            amountSpent: totalAmountSpent,
            monthlyBudget: currentBudget,
            currencySymbol: currencySymbol,
            budgetTrackingEnabled: budgetTrackingEnabled
        )

        if let encoded = try? JSONEncoder().encode(widgetData) {
            sharedDefaults?.set(encoded, forKey: "totalSpendingWidgetData")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
		
		private func load() {
				guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
				do {
						let data = try Data(contentsOf: saveURL)
						let storeData = try JSONDecoder().decode(StoreData.self, from: data)
						self.expenses = storeData.expenses
						self.categories = storeData.categories
						self.recurringExpenses = storeData.recurringExpenses
						
						// Perform migration after loading the data
						migrateRecurringRules()
						migrateRecurringExpenseRatings()
						
				} catch {
						print("Failed to load: \(error)")
				}
		}
		
		func migrateRecurringRules() {
			for i in recurringExpenses.indices {
				let oldRule = recurringExpenses[i].recurrenceRule

				// Migrate old rules that incorrectly used .daily period with selected days
				if let selectedWeekdays = oldRule.selectedWeekdays, !selectedWeekdays.isEmpty {
					var newRule = oldRule
					newRule.period = .weekly
					newRule.frequencyType = .weeklySelectedDays
					newRule.interval = 0
					newRule.selectedMonthDays = nil
					recurringExpenses[i].recurrenceRule = newRule // Assign the modified struct back

				} else if let selectedMonthDays = oldRule.selectedMonthDays, !selectedMonthDays.isEmpty {
					var newRule = oldRule
					newRule.period = .monthly
					newRule.frequencyType = .monthlySelectedDays
					newRule.interval = 0
					newRule.selectedWeekdays = nil
					recurringExpenses[i].recurrenceRule = newRule // Assign the modified struct back
				}
			}
		}
		
		func migrateRecurringExpenseRatings() {
			var changed = false
			for i in expenses.indices {
				if expenses[i].isRecurring && expenses[i].rating != nil {
					expenses[i].rating = nil
					changed = true
				}
			}
			if changed {
				save()
			}
		}
		
		func totalSpent(forMonth month: String) -> Double {
				let formatter = DateFormatter()
				formatter.dateFormat = "yyyy-MM"
				return expenses
						.filter { formatter.string(from: $0.date) == month }
						.reduce(0) { $0 + $1.amount }
		}
		
		func add(_ expense: Expense) {
				expenses.append(expense)
				save()
				NotificationCenter.default.post(name: Notification.Name("expensesUpdated"), object: nil)
		}
		
		func update(_ updated: Expense) {
				if let index = expenses.firstIndex(where: { $0.id == updated.id }) {
						expenses[index] = updated
						save()
						NotificationCenter.default.post(name: Notification.Name("expensesUpdated"), object: nil)
				}
		}
		
		func delete(_ expense: Expense) {
				if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
						expenses.remove(at: index)
						save()
						NotificationCenter.default.post(name: Notification.Name("expensesUpdated"), object: nil)
				}
		}

		func addRecurringExpense(_ recurring: RecurringExpense, currentDate: Date = Date()) {
			var mutableRecurring = recurring

			// ✅ 규칙에 따라 오늘 생성 여부 판단
			if shouldGenerateToday(for: recurring.recurrenceRule, on: recurring.startDate) {
				let expense = Expense(
					id: UUID(),
					date: recurring.startDate,
					name: recurring.name,
					amount: recurring.amount,
					category: recurring.category,
					details: recurring.details,
												rating: nil,
					memo: recurring.memo,
					isRecurring: true,
					parentRecurringID: recurring.id
				)
				add(expense)
				mutableRecurring.lastGeneratedDate = recurring.startDate
			}

			// Clear unused fields depending on frequency type before saving
			switch mutableRecurring.recurrenceRule.frequencyType {
			case .weeklySelectedDays:
				mutableRecurring.recurrenceRule.selectedMonthDays = nil
				mutableRecurring.recurrenceRule.interval = 0
			case .monthlySelectedDays:
				mutableRecurring.recurrenceRule.selectedWeekdays = nil
				mutableRecurring.recurrenceRule.interval = 0
			case .everyN:
				mutableRecurring.recurrenceRule.selectedWeekdays = nil
				mutableRecurring.recurrenceRule.selectedMonthDays = nil
			}

			recurringExpenses.append(mutableRecurring)
			generateExpensesFromSingleRecurringIfNeeded(&recurringExpenses[recurringExpenses.count - 1], upTo: currentDate)
			save()
		}
		
		func totalSpentByMonth() -> [String: Double] {
				let formatter = DateFormatter()
				formatter.dateFormat = "yyyy-MM"
				return Dictionary(grouping: expenses, by: { formatter.string(from: $0.date) })
						.mapValues { $0.reduce(0) { $0 + $1.amount } }
		}
		
		func syncStorageIfNeeded() {
				let fileManager = FileManager.default
				let localURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("expenses.json")
				guard let iCloudDocsURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/expenses.json") else {
						print("❌ iCloud URL not found")
						return
				}
				
				let localExists = fileManager.fileExists(atPath: localURL.path)
				let iCloudExists = fileManager.fileExists(atPath: iCloudDocsURL.path)
				
				if localExists {
						let localDate = (try? fileManager.attributesOfItem(atPath: localURL.path)[.modificationDate] as? Date) ?? Date.distantPast
						let iCloudDate = (try? fileManager.attributesOfItem(atPath: iCloudDocsURL.path)[.modificationDate] as? Date) ?? Date.distantPast
						
						if localDate > iCloudDate {
								do {
										try fileManager.removeItem(at: iCloudDocsURL)
								} catch {
										// 제거 실패시 무시
								}
								do {
										try fileManager.copyItem(at: localURL, to: iCloudDocsURL)
										print("☁️ Copied local to iCloud (sync)")
								} catch {
										print("❌ Failed to copy local data to iCloud: \(error)")
								}
						} else if iCloudDate > localDate {
								do {
										try fileManager.removeItem(at: localURL)
								} catch {
										// 무시
								}
								do {
										try fileManager.copyItem(at: iCloudDocsURL, to: localURL)
										print("💾 Copied iCloud to local (sync)")
								} catch {
										print("❌ Failed to copy iCloud data to local: \(error)")
								}
						} else {
								print("No sync needed — same or no changes.")
						}
				} else if iCloudExists {
						do {
								try fileManager.removeItem(at: localURL)
						} catch {
								// 무시
						}
						do {
								try fileManager.copyItem(at: iCloudDocsURL, to: localURL)
								print("💾 Restored local from iCloud (sync)")
						} catch {
								print("❌ Failed to restore local from iCloud: \(error)")
						}
				} else {
						print("❌ Neither local nor iCloud has a file. No data to sync.")
				}
				load()
		}

		func eraseAllData() {
			expenses.removeAll()
			recurringExpenses.removeAll()
			categories = [
				CategoryItem(name: "No Category", symbol: "tray", color: CodableColor(.gray)),
				CategoryItem(name: "Food", symbol: "fork.knife", color: CodableColor(.red)),
				CategoryItem(name: "Transport", symbol: "car.fill", color: CodableColor(.blue)),
				CategoryItem(name: "Entertainment", symbol: "gamecontroller.fill", color: CodableColor(.purple)),
				CategoryItem(name: "Rent", symbol: "house.fill", color: CodableColor(.orange)),
				CategoryItem(name: "Shopping", symbol: "bag.fill", color: CodableColor(.pink))
			]
			save()

			var budgets: [String: String] = [:]
			for category in categories {
				budgets[category.name] = "0"
			}
			if let encoded = try? JSONEncoder().encode(budgets) {
				UserDefaults(suiteName: "group.com.chankim.Monir")?.set(encoded, forKey: "categoryBudgets")
			}
		}
		
		private func shouldGenerateToday(for rule: RecurrenceRule, on date: Date) -> Bool {
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

		private func generateExpensesFromSingleRecurringIfNeeded(_ recurring: inout RecurringExpense, upTo currentDate: Date) {
			let rule = recurring.recurrenceRule
			let calendar = Calendar.current

			// Determine the actual start date for this generation run
			// Start from the day after the initialLastGeneratedDate, or from rule.startDate if no previous generation
			var currentGenerationDate: Date
			if let lastGen = recurring.lastGeneratedDate {
				currentGenerationDate = calendar.date(byAdding: .day, value: 1, to: lastGen)!
			} else {
				currentGenerationDate = rule.startDate
			}

			let endDate = currentDate

			while currentGenerationDate <= endDate {
				if shouldGenerateToday(for: rule, on: currentGenerationDate) {
					let newExpense = Expense(
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
					add(newExpense)
					// Update lastGeneratedDate as we generate
					recurring.lastGeneratedDate = currentGenerationDate
				}

				// Advance currentGenerationDate based on recurrence rule
				currentGenerationDate = calendar.date(byAdding: .day, value: 1, to: currentGenerationDate) ?? currentGenerationDate
			}
		}
}