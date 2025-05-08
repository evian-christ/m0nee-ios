import Foundation
import SwiftUI

private struct StoreData: Codable {
		var expenses: [Expense]
		var categories: [CategoryItem]
		var recurringExpenses: [RecurringExpense]
}

class ExpenseStore: ObservableObject {
		@Published var expenses: [Expense] = []
		@Published var categories: [CategoryItem] = []
		@Published var recurringExpenses: [RecurringExpense] = []
		@Published var restoredFromBackup: Bool = false
		@Published var failedToRestore: Bool = false
		
		private var saveURL: URL
		
		init() {
				let fileManager = FileManager.default
				let localURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("expenses.json")
				let iCloudURL: URL
				let useiCloud = UserDefaults.standard.bool(forKey: "useiCloud")

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

						syncStorageIfNeeded()
				} else {
						self.saveURL = localURL
				}

				repairICloudIfNeeded()
				print("💾 Using saveURL: \(saveURL.path)")
				load()
				if categories.isEmpty {
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
				
				generateExpensesFromRecurringIfNeeded()
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

		private func repairICloudIfNeeded() {
				guard saveURL.path.contains("Mobile Documents") else { return }

				let fileManager = FileManager.default
				let iCloudPath = saveURL.path
				let backupURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
						.appendingPathComponent("expenses_backup_for_recovery.json")

				guard fileManager.fileExists(atPath: backupURL.path) else { return }

				let iCloudDate = (try? fileManager.attributesOfItem(atPath: iCloudPath)[.modificationDate] as? Date) ?? Date.distantPast
				let backupDate = (try? fileManager.attributesOfItem(atPath: backupURL.path)[.modificationDate] as? Date) ?? Date.distantPast

				if backupDate > iCloudDate {
						do {
								let backupData = try Data(contentsOf: backupURL)
								try backupData.write(to: saveURL)
								print("🛟 iCloud was outdated, overwritten with backup")
								DispatchQueue.main.async {
										self.restoredFromBackup = true
								}
						} catch {
								print("❌ Failed to repair iCloud with backup: \(error)")
								DispatchQueue.main.async {
										self.failedToRestore = true
								}
						}
				}
		}
	
	func generateExpensesFromRecurringIfNeeded(currentDate: Date = Date()) {
			for index in recurringExpenses.indices {
				var recurring = recurringExpenses[index]
				let rule = recurring.recurrenceRule
				let calendar = Calendar.current

				var lastDate = calendar.date(byAdding: .day, value: 0, to: recurring.lastGeneratedDate ?? rule.startDate) ?? rule.startDate
				let endDate = currentDate

				while lastDate <= endDate {
					if shouldGenerateToday(for: rule, on: lastDate) {
						let alreadyGenerated = calendar.isDate(lastDate, inSameDayAs: recurring.lastGeneratedDate ?? .distantPast)

						if !alreadyGenerated {
							let newExpense = Expense(
								id: UUID(),
								date: lastDate,
								name: recurring.name,
								amount: recurring.amount,
								category: recurring.category,
								details: recurring.details,
								rating: recurring.rating,
								memo: recurring.memo,
								isRecurring: true,
								parentRecurringID: recurring.id
							)
							add(newExpense)
							recurring.lastGeneratedDate = lastDate
						}
					}

					switch rule.frequencyType {
					case .everyN:
						switch rule.period {
						case .daily:
							lastDate = calendar.date(byAdding: .day, value: rule.interval, to: lastDate) ?? lastDate
						case .weekly:
							lastDate = calendar.date(byAdding: .weekOfYear, value: rule.interval, to: lastDate) ?? lastDate
						case .monthly:
							lastDate = calendar.date(byAdding: .month, value: rule.interval, to: lastDate) ?? lastDate
						
						}
					case .weeklySelectedDays, .monthlySelectedDays:
						lastDate = calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate
					}
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

		func removeAllExpenses(withParentID parentID: UUID) {
			expenses.removeAll { $0.parentRecurringID == parentID }
			save()
		}

		/// Returns the next occurrence date after today (or the next after lastGeneratedDate) for the given recurring expense.
		func nextOccurrence(for recurring: RecurringExpense) -> Date? {
			let rule = recurring.recurrenceRule
			let calendar = Calendar.current
			let start = recurring.lastGeneratedDate ?? rule.startDate
			let today = Date()
			
			// Start from either today or the start date, whichever is later
			var candidate = max(start, today)
			
			// If start > today, first occurrence is start
			if calendar.isDate(candidate, inSameDayAs: rule.startDate) && candidate > today {
				return rule.startDate
			}
			
			// Increment until we find the next valid date > today
			repeat {
				switch rule.frequencyType {
				case .everyN:
					switch rule.period {
					case .daily:
						candidate = calendar.date(byAdding: .day, value: rule.interval, to: candidate) ?? candidate
					case .weekly:
						candidate = calendar.date(byAdding: .weekOfYear, value: rule.interval, to: candidate) ?? candidate
					case .monthly:
						candidate = calendar.date(byAdding: .month, value: rule.interval, to: candidate) ?? candidate
					}
				case .weeklySelectedDays:
					// Move forward one day until a selected weekday
					candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
				case .monthlySelectedDays:
					// Move forward one day until a selected month-day
					candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
				}
			} while candidate <= today

			return candidate
		}
}

extension ExpenseStore {
		func save() {
				do {
						let storeData = StoreData(expenses: expenses, categories: categories, recurringExpenses: recurringExpenses)
						let data = try JSONEncoder().encode(storeData)
						try data.write(to: saveURL)
						// Also write local backup if using iCloud
						if saveURL.path.contains("Mobile Documents") {
								let backupURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
										.appendingPathComponent("expenses_backup_for_recovery.json")
								do {
										try data.write(to: backupURL)
										print("🛟 Local backup saved at \(backupURL.path)")
								} catch {
										print("❌ Failed to save local backup: \(error)")
								}
						}
						let isICloud = saveURL.path.contains("Mobile Documents")
						print("\(isICloud ? "☁️" : "💾") Saved \(expenses.count) expenses")
				} catch {
						print("Failed to save: \(error)")
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
				} catch {
						print("Failed to load: \(error)")
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

		func addRecurringExpense(_ recurring: RecurringExpense) {
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
					rating: recurring.rating,
					memo: recurring.memo,
					isRecurring: true,
					parentRecurringID: recurring.id
				)
				add(expense)
				mutableRecurring.lastGeneratedDate = recurring.startDate
			}

			recurringExpenses.append(mutableRecurring)
			generateExpensesFromSingleRecurringIfNeeded(&recurringExpenses[recurringExpenses.count - 1], upTo: Date())
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
				UserDefaults.standard.set(encoded, forKey: "categoryBudgets")
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
					let weeksBetween = calendar.dateComponents([.weekOfYear], from: rule.startDate, to: date).weekOfYear ?? 0
					return weeksBetween >= 0 && weeksBetween % rule.interval == 0

				case .monthly:
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

			var lastDate = calendar.date(byAdding: .day, value: 0, to: recurring.lastGeneratedDate ?? rule.startDate) ?? rule.startDate
			let endDate = currentDate

			while lastDate <= endDate {
				if shouldGenerateToday(for: rule, on: lastDate) {
					let alreadyGenerated = calendar.isDate(lastDate, inSameDayAs: recurring.lastGeneratedDate ?? .distantPast)
					if !alreadyGenerated {
						let newExpense = Expense(
							id: UUID(),
							date: lastDate,
							name: recurring.name,
							amount: recurring.amount,
							category: recurring.category,
							details: recurring.details,
							rating: recurring.rating,
							memo: recurring.memo,
							isRecurring: true,
							parentRecurringID: recurring.id
						)
						add(newExpense)
						recurring.lastGeneratedDate = lastDate
					}
				}

				switch rule.frequencyType {
				case .everyN:
					switch rule.period {
					case .daily:
						lastDate = calendar.date(byAdding: .day, value: rule.interval, to: lastDate) ?? lastDate
					case .weekly:
						lastDate = calendar.date(byAdding: .weekOfYear, value: rule.interval, to: lastDate) ?? lastDate
					case .monthly:
						lastDate = calendar.date(byAdding: .month, value: rule.interval, to: lastDate) ?? lastDate
						
					}
				case .weeklySelectedDays, .monthlySelectedDays:
					lastDate = calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate
				}
			}
		}
}
