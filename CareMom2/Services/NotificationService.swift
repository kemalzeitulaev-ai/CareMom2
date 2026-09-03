import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleMedicationReminder(for course: MedicationCourse) {
        let center = UNUserNotificationCenter.current()
        cancelReminder(for: course.id)
        guard course.reminderEnabled else { return }

        let times = course.reminderTimes.isEmpty
            ? [(course.reminderHour, course.reminderMinute)]
            : course.reminderTimes

        for (index, time) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = L10n.t("notification.medication.title")
            content.body = "\(course.name) — \(course.dosage)"
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            center.add(UNNotificationRequest(
                identifier: "\(course.id.uuidString)-\(index)",
                content: content, trigger: trigger
            ))
        }
    }

    func scheduleVaccinationReminder(for vaccine: VaccinationRecord, childName: String) {
        guard !vaccine.isCompleted else { return }
        let center = UNUserNotificationCenter.current()
        let id = "vaccine-\(vaccine.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: vaccine.scheduledDate),
              reminderDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = L10n.t("notification.vaccination.title")
        content.body = L10n.format("notification.vaccination.body", childName, vaccine.name)
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancelReminder(for courseID: UUID) {
        let center = UNUserNotificationCenter.current()
        let ids = (0..<6).map { "\(courseID.uuidString)-\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }
}
