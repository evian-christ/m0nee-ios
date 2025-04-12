import Foundation
import SwiftUI

class ExpenseStore: ObservableObject {
		@Published var expenses: [Expense] = []
		
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
						// iCloud가 활성화된 경우 스토리지 동기화 실행
						syncStorageIfNeeded()
				} else {
						self.saveURL = localURL
				}
				
				print("💾 Using saveURL: \(saveURL.path)")
				load()
		}
}

extension ExpenseStore {
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
		
		private func save() {
				do {
						let data = try JSONEncoder().encode(expenses)
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
						expenses = try JSONDecoder().decode([Expense].self, from: data)
				} catch {
						print("Failed to load: \(error)")
				}
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
				
				print("localExists:", localExists, ", iCloudExists:", iCloudExists)
				if localExists {
						let localDate = (try? fileManager.attributesOfItem(atPath: localURL.path)[.modificationDate] as? Date) ?? Date.distantPast
						let iCloudDate = (try? fileManager.attributesOfItem(atPath: iCloudDocsURL.path)[.modificationDate] as? Date) ?? Date.distantPast
						
						print("localDate:", localDate, ", iCloudDate:", iCloudDate)
						
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
				load() // 동기화 후 메모리 내 데이터를 새로 불러옴
		}
}
