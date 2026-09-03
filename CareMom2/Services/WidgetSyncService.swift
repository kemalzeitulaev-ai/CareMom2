import Foundation
import SwiftData
import WidgetKit

enum WidgetSyncService {
    static func sync(
        children: [Child],
        entries: [DiaryEntry],
        courses: [MedicationCourse],
        selectedChildID: UUID?
    ) {
        let monthStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: .now)
        ) ?? .now

        let childData = children.map { child -> ChildWidgetData in
            let childEntries = entries.filter { $0.child?.id == child.id }
            let lastTempEntry = childEntries
                .filter { $0.temperature != nil }
                .max(by: { $0.date < $1.date })

            let childCourses = courses.filter { $0.child?.id == child.id && $0.isActive }
            let nextIntake = childCourses
                .flatMap(\.intakeLogs)
                .filter { !$0.wasTaken && !$0.wasSkipped && $0.scheduledDate >= .now }
                .min(by: { $0.scheduledDate < $1.scheduledDate })

            let illnessCount = childEntries.filter {
                $0.type == .illness && $0.date >= monthStart
            }.count

            return ChildWidgetData(
                id: child.id,
                name: child.firstName,
                lastTemperature: lastTempEntry?.temperature,
                lastTemperatureDate: lastTempEntry?.date,
                nextMedicationName: nextIntake.flatMap { $0.course?.name },
                nextMedicationTime: nextIntake?.scheduledDate,
                illnessThisMonth: illnessCount
            )
        }

        let snapshot = CareMomWidgetSnapshot(
            updatedAt: .now,
            selectedChildID: selectedChildID,
            children: childData
        )
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()

        #if canImport(ActivityKit)
        if let child = snapshot.primaryChild {
            LiveActivityService.updateMedicationActivity(
                childName: child.name,
                medicationName: child.nextMedicationName,
                dosage: nil,
                scheduledDate: child.nextMedicationTime
            )
        }
        #endif
    }
}
