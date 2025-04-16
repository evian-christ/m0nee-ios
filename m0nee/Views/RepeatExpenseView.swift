import SwiftUI

struct RepeatExpenseView: View {
	@Binding var draft: RecurrenceDraft
	
	var body: some View {
		Form {
			Section(header: Text("Period")) {
				Picker(selection: $draft.selectedPeriod, label: EmptyView()) {
					ForEach(Period.allCases) { period in
						Text(period.rawValue).tag(period)
					}
				}
				.pickerStyle(.inline)
				.onChange(of: draft.selectedPeriod) { newValue in
					if newValue == .never {
						draft = RecurrenceDraft() // Reset draft
					} else {
						switch newValue {
						case .daily:
							draft.selectedFrequencyOption = "Weekly on selected days"
						case .monthly:
							draft.selectedFrequencyOption = "Every N months"
						case .weekly:
							draft.selectedFrequencyOption = "Every N weeks"
						default:
							break
						}
						draft.selectedWeekdays = Array(1...7)
						draft.selectedMonthDays = Array(1...31)
						draft.dayInterval = 1
					}
				}
			}
			
			if draft.selectedPeriod == .daily {
				Section(header: Text("Frequency")) {
					Picker(selection: $draft.selectedFrequencyOption, label: EmptyView()) {
						Text("Weekly on selected days").tag("Weekly on selected days")
						Text("Monthly on selected days").tag("Monthly on selected days")
						Text("Every N days").tag("Every N days")
					}
					.pickerStyle(.inline)
				}
			}

			if draft.selectedPeriod == .monthly {
				Section(header: Text("Frequency")) {
					Picker(selection: $draft.selectedFrequencyOption, label: EmptyView()) {
						Text("Every N months").tag("Every N months")
					}
					.pickerStyle(.inline)
				}
			}

			if draft.selectedPeriod == .weekly {
				Section(header: Text("Frequency")) {
					Picker(selection: $draft.selectedFrequencyOption, label: EmptyView()) {
						Text("Every N weeks").tag("Every N weeks")
					}
					.pickerStyle(.inline)
				}
			}
			
			if draft.selectedPeriod != .never {
				if draft.selectedFrequencyOption == "Weekly on selected days" {
					Section {
						HStack(spacing: 10) {
							let days = Array(1...7)
			let reordered = Array(Calendar.current.shortWeekdaySymbols[0...6]) // Adjusted to start from Sunday
			ForEach(Array(zip(days, reordered)), id: \.0) { weekdayNumber, label in
								let isSelected = draft.selectedWeekdays.contains(weekdayNumber)

								Button(action: {
									if isSelected {
										if draft.selectedWeekdays.count > 1 {
											draft.selectedWeekdays.removeAll { $0 == weekdayNumber }
										}
									} else {
										draft.selectedWeekdays.append(weekdayNumber)
									}
								}) {
									Text(String(label.prefix(2)))
										.font(.system(size: 13, weight: .medium))
										.frame(width: 38, height: 38)
										.background(
											Circle()
												.fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
										)
										.foregroundColor(isSelected ? .white : .primary)
								}
								.buttonStyle(.plain)
							}
						}
					}
				}

				if draft.selectedFrequencyOption == "Monthly on selected days" {
					Section {
						let days = Array(1...31)
						let isAllSelected = draft.selectedMonthDays.count == 31

						LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 24)), count: 7), spacing: 12) {
							Button(action: {
								if isAllSelected {
									draft.selectedMonthDays = [1]
								} else {
									draft.selectedMonthDays = days
								}
							}) {
								Text("All")
									.font(.system(size: 13, weight: .medium))
									.frame(width: 38, height: 38)
									.background(
										Circle()
											.fill(isAllSelected ? Color.accentColor : Color.gray.opacity(0.2))
									)
									.foregroundColor(isAllSelected ? .white : .primary)
							}
							.buttonStyle(.plain)

							ForEach(days, id: \.self) { day in
								let isSelected = draft.selectedMonthDays.contains(day)
								Button(action: {
									if isSelected {
										if draft.selectedMonthDays.count > 1 {
											draft.selectedMonthDays.removeAll { $0 == day }
										}
									} else {
										draft.selectedMonthDays.append(day)
									}
								}) {
									Text("\(day)")
										.font(.system(size: 13, weight: .medium))
										.frame(width: 38, height: 38)
										.background(
											Circle()
												.fill(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
										)
										.foregroundColor(isSelected ? .white : .primary)
								}
								.buttonStyle(.plain)
							}
						}
						.padding(.top, 4)
					}
				}
				
				if draft.selectedFrequencyOption == "Every N days" {
					Section {
						HStack {
							Text("Every")
							TextField("", value: $draft.dayInterval, formatter: NumberFormatter())
								.keyboardType(.numberPad)
								.multilineTextAlignment(.center)
								.frame(width: 50)
								.textFieldStyle(.roundedBorder)
							Text("days")
						}
					}
				}

				if draft.selectedFrequencyOption == "Every N weeks" {
					Section {
						HStack {
							Text("Every")
							TextField("", value: $draft.dayInterval, formatter: NumberFormatter())
								.keyboardType(.numberPad)
								.multilineTextAlignment(.center)
								.frame(width: 50)
								.textFieldStyle(.roundedBorder)
							Text("weeks")
						}
					}
				}
				
				if draft.selectedFrequencyOption == "Every N months" {
					Section {
						HStack {
							Text("Every")
							TextField("", value: $draft.dayInterval, formatter: NumberFormatter())
								.keyboardType(.numberPad)
								.multilineTextAlignment(.center)
								.frame(width: 50)
								.textFieldStyle(.roundedBorder)
							Text("months")
						}
					}
				}
			}
		}
		.navigationTitle("Repeat")
		.navigationBarTitleDisplayMode(.inline)
		.onAppear {
			print("RepeatExpenseView appeared with draft:")
			print("selectedPeriod: \(draft.selectedPeriod.rawValue)")
			print("selectedFrequencyOption: \(draft.selectedFrequencyOption)")
			print("selectedWeekdays: \(draft.selectedWeekdays)")
			print("selectedMonthDays: \(draft.selectedMonthDays)")
			print("dayInterval: \(draft.dayInterval)")

			if draft.selectedFrequencyOption == "Weekly on selected days",
				 draft.selectedWeekdays.isEmpty {
				draft.selectedWeekdays = Array(1...7)
			}

			if draft.selectedFrequencyOption == "Monthly on selected days",
				 draft.selectedMonthDays.isEmpty {
				draft.selectedMonthDays = Array(1...31);
			}
		}
	}
}
