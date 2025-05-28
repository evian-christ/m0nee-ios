import Foundation

extension DateFormatter {
		/// 13-04-2025
		static let m0neeCSV: DateFormatter = {
				let formatter = DateFormatter()
				formatter.dateFormat = "dd-MM-yyyy"
				return formatter
		}()

		/// 13 Apr
		static let m0neeListSection: DateFormatter = {
				let formatter = DateFormatter()
				formatter.dateFormat = "dd MMM"
				return formatter
		}()

		/// 14:35
		static let m0neeTimeOnly: DateFormatter = {
				let formatter = DateFormatter()
				formatter.dateFormat = "HH:mm"
				return formatter
		}()

		/// Converts separate date and time strings into a single Date object.
		/// - Parameters:
		///   - dateString: A string representing the date in "dd-MM-yyyy" format.
		///   - timeString: A string representing the time in "HH:mm" format.
		/// - Returns: A Date object if parsing is successful, otherwise nil.
		static func dateFromCSV(dateString: String, timeString: String) -> Date? {
				let formatter = DateFormatter()
				formatter.dateFormat = "dd-MM-yyyy HH:mm"
				formatter.locale = Locale(identifier: "en_US_POSIX")
				return formatter.date(from: "\(dateString) \(timeString)")
		}
}
