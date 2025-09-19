import SwiftUI

struct RecurringSettingsView: View {
	@EnvironmentObject var store: ExpenseStore
	@EnvironmentObject var settings: AppSettings
	private var currencySymbol: String {
		CurrencyManager.symbol(for: settings.currencyCode)
	}
	
	var body: some View {
		List {
			if store.recurringExpenses.isEmpty {
				Text("No recurring expenses")
					.foregroundColor(.secondary)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(.vertical, 16)
			} else {
				ForEach(store.recurringExpenses) { expense in
					NavigationLink {
						RecurringDetailView(recurring: expense)
					} label: {
						HStack(spacing: 12) {
							// Category icon on the left
							if let item = store.categories.first(where: { $0.name == expense.category }) {
								ZStack {
									Circle()
										.fill(item.color.color)
										.frame(width: 32, height: 32)
									Image(systemName: item.symbol)
										.font(.system(size: 16))
										.foregroundColor(.white)
								}
							}
							
							// Title and rule
															VStack(alignment: .leading, spacing: 2) {
								Text(expense.name)
									.font(.headline)
									.foregroundColor(.primary)
								Text(RecurringSettingsView.ruleDescription(recurrenceRule: expense.recurrenceRule))
									.font(.caption2)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							// Amount and chevron
						Text(NumberFormatter.currency(for: settings.decimalDisplayMode, currencyCode: settings.currencyCode).string(from: NSNumber(value: expense.amount)) ?? "")
								.font(.system(size: 17, weight: .bold))
								.foregroundColor(.primary)
						}
						.padding(.vertical, 8)
					}
				}
			}
		}
		.navigationTitle("Recurring Expenses")
	}
	
	
}

extension RecurringSettingsView {
	public static func ruleDescription(recurrenceRule: RecurrenceRule) -> String {
		switch recurrenceRule.period {
				case .daily:
			let interval = recurrenceRule.interval > 0 ? recurrenceRule.interval : 1
			let dayString = interval == 1 ? "day" : "days"
			return "Every \(interval) \(dayString)"
		case .weekly:
			if recurrenceRule.frequencyType == .everyN {
				return "Every \(recurrenceRule.interval) week(s)"
			} else if recurrenceRule.frequencyType == .weeklySelectedDays, let weekdays = recurrenceRule.selectedWeekdays, !weekdays.isEmpty {
				let sortedWeekdays = weekdays.sorted()
				let dayNames = sortedWeekdays.map { dayIndex -> String in
					switch dayIndex {
					case 1: return "Sun"
					case 2: return "Mon"
					case 3: return "Tue"
					case 4: return "Wed"
					case 5: return "Thu"
					case 6: return "Fri"
					case 7: return "Sat"
					default: return ""
					}
				}.joined(separator: ", ")
				return "Weekly on \(dayNames)"
			} else {
				return "Weekly"
			}
		case .monthly:
			if recurrenceRule.frequencyType == .everyN {
				return "Every \(recurrenceRule.interval) month(s)"
			} else if recurrenceRule.frequencyType == .monthlySelectedDays, let monthDays = recurrenceRule.selectedMonthDays, !monthDays.isEmpty {
				let dayStrings = monthDays.sorted().map { String($0) }.joined(separator: ", ")
				return "Monthly on day(s) \(dayStrings)"
			} else {
				return "Monthly"
			}
		}
	}

	struct RecurringDetailView: View {
		let recurring: RecurringExpense
		@EnvironmentObject var store: ExpenseStore
		@AppStorage("currencyCode", store: UserDefaults(suiteName: "group.com.chankim.Monir")) private var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
		@AppStorage("decimalDisplayMode") private var decimalDisplayMode: DecimalDisplayMode = .automatic
		@Environment(\.colorScheme) private var colorScheme
	@Environment(\.dismiss) private var dismiss
	@State private var showingDeleteDialog = false
	@State private var showingEditSheet = false
		
		private var categoryItem: CategoryItem? {
			store.categories.first { $0.name == recurring.category }
		}
		private var categoryColor: Color {
			categoryItem?.color.color ?? .gray
		}
		private var currencySymbol: String {
			CurrencyManager.symbol(for: currencyCode)
		}
		
		var body: some View {
			ScrollView {
				VStack(spacing: 20) {
					// Header card
					HStack(spacing: 16) {
						// Category icon on the left
						ZStack {
							Circle()
								.fill(categoryColor)
								.frame(width: 60, height: 60)
							Image(systemName: categoryItem?.symbol ?? "questionmark")
								.font(.system(size: 24, weight: .medium))
								.foregroundColor(.white)
						}
						// Name and category
						VStack(alignment: .leading, spacing: 4) {
							Text(recurring.name)
								.font(.title2.bold())
							Text(recurring.category)
								.font(.subheadline)
								.foregroundColor(.secondary)
						}
						Spacer()
						// Amount on the right
												Text(NumberFormatter.currency(for: decimalDisplayMode, currencyCode: currencyCode).string(from: NSNumber(value: recurring.amount)) ?? "")
							.font(.title3.bold())
					}
					.padding()
					.background(Color(.systemGray6))
					.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
					.padding(.horizontal)
					
					// Details section
					VStack(alignment: .leading, spacing: 12) {
						Text("Recurrence Details")
							.font(.headline)
						
						HStack {
							Label("Starts on", systemImage: "calendar")
							Spacer()
							Text(recurring.startDate.formatted(date: .long, time: .omitted))
						}
						
						HStack {
							Label("Frequency", systemImage: "repeat")
							Spacer()
							Text(RecurringSettingsView.ruleDescription(recurrenceRule: recurring.recurrenceRule))
						}
						
						if let nextDate = store.nextOccurrence(for: recurring) {
							HStack {
								Label("Next", systemImage: "arrow.forward")
								Spacer()
								Text(nextDate.formatted(date: .long, time: .omitted))
									.foregroundColor(.accentColor)
							}
						}
					}
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.fill(Color(.systemBackground))
							.shadow(
								color: colorScheme == .dark
								? Color.white.opacity(0.3)
								: Color.primary.opacity(0.05),
								radius: 4, x: 0, y: 2
							)
					)
					.padding(.horizontal)
					
					Button(role: .destructive) {
						showingDeleteDialog = true
					} label: {
						Text("Delete")
							.frame(maxWidth: .infinity)
					}
					.confirmationDialog("Delete this recurring rule?", isPresented: $showingDeleteDialog, titleVisibility: .visible) {
						Button("Delete recurring rule only", role: .destructive) {
							store.removeRecurringExpense(id: recurring.id)
							dismiss()
						}
						Button("Delete rule and all related expenses", role: .destructive) {
							store.removeAllExpenses(withParentID: recurring.id)
							store.removeRecurringExpense(id: recurring.id)
							dismiss()
						}
						Button("Cancel", role: .cancel) { }
					}
					.padding()
					
					Spacer()
				}
				.padding(.top)
			}
			.navigationTitle("Details")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Edit") {
						showingEditSheet = true
					}
				}
			}
			.sheet(isPresented: $showingEditSheet) {
				EditRecurringExpenseView(recurringExpense: recurring, decimalDisplayMode: decimalDisplayMode, currencyCode: currencyCode)
					.environmentObject(store)
			}
		}
	}
}
