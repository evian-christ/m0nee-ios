import SwiftUI

struct RepeatExpenseView: View {
    @Binding var draft: RecurrenceDraft
    
    var body: some View {
        Form {
            Section(header: Text("Period")) {
                Picker(selection: $draft.selectedPeriod, label: EmptyView()) {
                    ForEach(Period.allCases) { period in
                        Text(period.localizedStringKey).tag(period)
                    }
                }
                .pickerStyle(.inline)
                .onChange(of: draft.selectedPeriod) { newPeriod in
                    if newPeriod == .never {
                        draft = RecurrenceDraft() // Reset draft
                    } else {
                        // Reset to a sensible default when period changes
                        draft.frequencyType = .everyN
                        draft.dayInterval = 1
                        if draft.selectedWeekdays.isEmpty {
                            draft.selectedWeekdays = [1]
                        }
                        if draft.selectedMonthDays.isEmpty {
                            draft.selectedMonthDays = [1]
                        }
                    }
                }
            }
            
            if draft.selectedPeriod == .daily {
                Section {
                    HStack {
                        Text("Every")
                        TextField("", value: $draft.dayInterval, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .textFieldStyle(.roundedBorder)
                        Text(draft.dayInterval == 1 ? "day" : "days")
                    }
                }
            }
            
            if draft.selectedPeriod == .weekly {
                Section(header: Text("Frequency")) {
                    Picker(selection: $draft.frequencyType, label: EmptyView()) {
                        Text("Every N weeks").tag(RecurrenceRule.FrequencyType.everyN)
                        Text("On specific days").tag(RecurrenceRule.FrequencyType.weeklySelectedDays)
                    }
                    .pickerStyle(.inline)
                }
                
                if draft.frequencyType == .everyN {
                    Section {
                        HStack {
                            Text("Every")
                            TextField("", value: $draft.dayInterval, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 50)
                                .textFieldStyle(.roundedBorder)
                            Text(draft.dayInterval == 1 ? "week" : "weeks")
                        }
                    }
                } else if draft.frequencyType == .weeklySelectedDays {
                    Section {
                        HStack(spacing: 10) {
                            let days = Array(1...7)
                            let symbols = Array(Calendar.current.shortWeekdaySymbols)
                            let weekdayPairs: [(Int, String)] = Array(zip(days, symbols))
                            
                            ForEach(weekdayPairs, id: \.0) { pair in
                                let weekdayNumber = pair.0
                                let label = pair.1
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
            }
            
            if draft.selectedPeriod == .monthly {
                Section(header: Text("Frequency")) {
                    Picker(selection: $draft.frequencyType, label: EmptyView()) {
                        Text("Every N months").tag(RecurrenceRule.FrequencyType.everyN)
                        Text("On specific days").tag(RecurrenceRule.FrequencyType.monthlySelectedDays)
                    }
                    .pickerStyle(.inline)
                }
                
                if draft.frequencyType == .everyN {
                    Section {
                        HStack {
                            Text("Every")
                            TextField("", value: $draft.dayInterval, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 50)
                                .textFieldStyle(.roundedBorder)
                            Text(draft.dayInterval == 1 ? "month" : "months")
                        }
                    }
                } else if draft.frequencyType == .monthlySelectedDays {
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
            }
        }
        .navigationTitle("Repeat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Backward compatibility for rules created with the old UI
            if draft.selectedPeriod == .daily {
                if draft.frequencyType == .weeklySelectedDays {
                    draft.selectedPeriod = .weekly
                } else if draft.frequencyType == .monthlySelectedDays {
                    draft.selectedPeriod = .monthly
                }
            }
        }
    }
}
