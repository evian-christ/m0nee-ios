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
						
						if localExists {
								let localDate = (try? fileManager.attributesOfItem(atPath: localURL.path)[.modificationDate] as? Date) ?? Date.distantPast
								let iCloudDate = (try? fileManager.attributesOfItem(atPath: iCloudURL.path)[.modificationDate] as? Date) ?? Date.distantPast
								
								if !iCloudExists || localDate > iCloudDate {
										do {
												try fileManager.copyItem(at: localURL, to: iCloudURL)
												print("☁️ Copied local data to iCloud")
										} catch {
												print("❌ Failed to copy local data to iCloud: \(error)")
										}
								}
						}
						self.saveURL = iCloudURL
						syncStorageIfNeeded()
				} else {
						self.saveURL = localURL
				}
				
				print("💾 Using saveURL: \(saveURL.path)")
				load()
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
}

extension ExpenseStore {
		func save() {
				do {
						let storeData = StoreData(expenses: expenses, categories: categories, recurringExpenses: recurringExpenses)
						let data = try JSONEncoder().encode(storeData)
						try data.write(to: saveURL)
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
				recurringExpenses.append(recurring)
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
}
