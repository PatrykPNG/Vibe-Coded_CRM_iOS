import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(for contact: Contact) {
        guard let date = contact.reminderDate, date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Follow up with \(contact.fullName)"
        content.body = contact.reminderNote.isEmpty
            ? "Time to reach out!"
            : contact.reminderNote
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: contact.notificationID.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancel(for contact: Contact) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [contact.notificationID.uuidString])
    }
}
