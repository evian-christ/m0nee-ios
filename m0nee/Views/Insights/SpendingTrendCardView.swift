import SwiftUI
import Charts

struct SpendingTrendCardView: View {
	let expenses: [Expense]
	let startDate: Date
	let endDate: Date
	let monthlyBudget: Double
	
	var body: some View {
		let calendar = Calendar.current
		let cappedEndDate = min(endDate, Date())
		let spendingData = expenses
			.filter { $0.date >= startDate && $0.date <= cappedEndDate }
			.sorted(by: { $0.date < $1.date })
		
		let grouped = Dictionary(grouping: spendingData) {
			calendar.startOfDay(for: $0.date)
		}
		
		let dateRange = calendar.dateComponents([.day], from: startDate, to: cappedEndDate).day ?? 0
		let sortedDates = (0...dateRange).compactMap {
			calendar.date(byAdding: .day, value: $0, to: startDate)
		}
		
		let dailyTotals: [(date: Date, total: Double)] = {
			var runningTotal: Double = 0
			return sortedDates.map { date in
				let dayTotal = grouped[date]?.reduce(0) { $0 + $1.amount } ?? 0
				runningTotal += dayTotal
				return (date, runningTotal)
			}
		}()
		
		return VStack(alignment: .leading, spacing: 8) {
			Chart {
				ForEach(Array(dailyTotals.enumerated()), id: \.1.date) { index, item in
					if item.date <= cappedEndDate {
						LineMark(
							x: .value("Date", item.date),
							y: .value("Total", item.total)
						)
					}
				}
			}
			.chartYScale(domain: 0...max(monthlyBudget, dailyTotals.last?.total ?? 0))
			.chartXAxis {
				let today = Calendar.current.startOfDay(for: Date())
				let axisDates: [Date] = {
					if startDate <= today && today <= endDate {
						return [startDate, today, endDate]
					} else {
						let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
						return stride(from: 0, through: days, by: 10).compactMap {
							Calendar.current.date(byAdding: .day, value: $0, to: startDate)
						}
					}
				}()
				
				AxisMarks(values: axisDates) { date in
					AxisGridLine()
					AxisTick()
					AxisValueLabel {
						if let dateValue = date.as(Date.self) {
							Text(dateValue.formatted(.dateTime.day().month()))
						}
					}
				}
			}
			.frame(height: 180)
		}
	}
}
