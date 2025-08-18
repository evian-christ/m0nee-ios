import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("notificationHour") private var notificationHour: Int = 20
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0

    @State private var selectedTime: Date = Date()

    var body: some View {
        Form {
            Section {
                Toggle("Enable Daily Reminders", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { newValue in
                        if newValue {
                            requestNotificationAuthorization()
                            scheduleDailyNotification()
                        } else {
                            cancelAllNotifications()
                        }
                    }
            }

            if notificationsEnabled {
                Section {
                    DatePicker("Reminder Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .onChange(of: selectedTime) { newTime in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                            notificationHour = components.hour ?? 20
                            notificationMinute = components.minute ?? 0
                            scheduleDailyNotification()
                        }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setupInitialNotificationState)
    }

    private func setupInitialNotificationState() {
        // Initialize selectedTime from stored hour and minute
        selectedTime = Calendar.current.date(bySettingHour: notificationHour, minute: notificationMinute, second: 0, of: Date()) ?? Date()

        if notificationsEnabled {
            scheduleDailyNotification()
        }
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                // Notification authorization granted
            } else if let error = error {
                // Notification authorization error occurred
                // Optionally, you might want to turn off the toggle if authorization is denied
                // notificationsEnabled = false
            }
        }
    }

    private func scheduleDailyNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Daily check-in time", comment: "Notification Title")
        content.body = NSLocalizedString("Log today’s spending before you forget.", comment: "Notification Body")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "dailyExpenseReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                // Error scheduling notification
            } else {
                // Daily expense reminder scheduled
            }
        }
    }

    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // All pending notifications cancelled
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationSettingsView()
        }
    }
}
