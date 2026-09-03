import Foundation
import SwiftData

@Model
final class MedicationCourse {
    var id: UUID
    var name: String
    var dosage: String
    var startDate: Date
    var durationDays: Int
    var timesPerDay: Int
    var reminderHour: Int
    var reminderMinute: Int
    var reminderTimesRaw: String = "8:0|14:0|20:0"
    var reminderEnabled: Bool
    var isActive: Bool
    var createdAt: Date

    var child: Child?

    @Relationship(deleteRule: .cascade, inverse: \MedicationIntake.course)
    var intakeLogs: [MedicationIntake]

    init(
        name: String,
        dosage: String,
        startDate: Date = .now,
        durationDays: Int = 5,
        timesPerDay: Int = 3,
        reminderHour: Int = 8,
        reminderMinute: Int = 0,
        reminderEnabled: Bool = true,
        child: Child? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.startDate = startDate
        self.durationDays = durationDays
        self.timesPerDay = timesPerDay
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.reminderTimesRaw = Self.defaultReminderTimes(for: timesPerDay)
        self.reminderEnabled = reminderEnabled
        self.isActive = true
        self.createdAt = .now
        self.child = child
        self.intakeLogs = []
    }

    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: durationDays - 1, to: startDate) ?? startDate
    }

    var progress: Double {
        let total = durationDays * timesPerDay
        guard total > 0 else { return 0 }
        let taken = intakeLogs.filter(\.wasTaken).count
        return min(Double(taken) / Double(total), 1.0)
    }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: endDate).day ?? 0)
    }

    var reminderTimes: [(hour: Int, minute: Int)] {
        reminderTimesRaw.split(separator: "|").compactMap { part in
            let bits = part.split(separator: ":")
            guard bits.count == 2, let h = Int(bits[0]), let m = Int(bits[1]) else { return nil }
            return (h, m)
        }
    }

    static func defaultReminderTimes(for count: Int) -> String {
        reminderTimes(firstHour: 8, firstMinute: 0, count: count)
    }

    /// Builds reminder slots starting from the user's first pick, spaced 6 hours apart.
    static func reminderTimes(firstHour: Int, firstMinute: Int, count: Int) -> String {
        let slots = max(count, 1)
        return (0..<slots).map { index in
            let totalMinutes = firstHour * 60 + firstMinute + index * 6 * 60
            let wrapped = ((totalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60)
            return "\(wrapped / 60):\(wrapped % 60)"
        }.joined(separator: "|")
    }

    func setRemindersEnabled(_ enabled: Bool) {
        reminderEnabled = enabled
        if enabled {
            Task { @MainActor in
                _ = await NotificationService.shared.requestAuthorization()
                NotificationService.shared.scheduleMedicationReminder(for: self)
            }
        } else {
            Task { @MainActor in
                NotificationService.shared.cancelReminder(for: id)
            }
        }
    }

    func cancelReminders() {
        reminderEnabled = false
        Task { @MainActor in
            NotificationService.shared.cancelReminder(for: id)
        }
    }

    func generateIntakeSchedule() {
        intakeLogs.removeAll()
        let calendar = Calendar.current
        let times = reminderTimes.isEmpty ? [(reminderHour, reminderMinute)] : reminderTimes
        for dayOffset in 0..<durationDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: startDate)) else { continue }
            for time in times.prefix(timesPerDay) {
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = time.hour
                components.minute = time.minute
                if let scheduled = calendar.date(from: components) {
                    intakeLogs.append(MedicationIntake(scheduledDate: scheduled, course: self))
                }
            }
        }
    }

    /// Marks course inactive and cancels reminders when all doses are handled or the end date has passed.
    func refreshCompletionStatus() {
        guard isActive else { return }

        let allHandled = !intakeLogs.isEmpty && intakeLogs.allSatisfy { $0.wasTaken || $0.wasSkipped }
        let courseEnded = Calendar.current.startOfDay(for: .now) > Calendar.current.startOfDay(for: endDate)

        guard allHandled || courseEnded else { return }

        isActive = false
        Task { @MainActor in
            NotificationService.shared.cancelReminder(for: id)
        }
    }
}

@Model
final class MedicationIntake {
    var id: UUID
    var scheduledDate: Date
    var takenAt: Date?
    var wasTaken: Bool
    var wasSkipped: Bool

    var course: MedicationCourse?

    init(scheduledDate: Date, course: MedicationCourse? = nil) {
        self.id = UUID()
        self.scheduledDate = scheduledDate
        self.course = course
        self.wasTaken = false
        self.wasSkipped = false
    }

    func markTaken() {
        wasTaken = true
        wasSkipped = false
        takenAt = .now
        course?.refreshCompletionStatus()
    }

    func markSkipped() {
        wasSkipped = true
        wasTaken = false
        takenAt = nil
        course?.refreshCompletionStatus()
    }
}
