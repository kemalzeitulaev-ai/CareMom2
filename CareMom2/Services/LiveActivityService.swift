#if canImport(ActivityKit)
import ActivityKit
import Foundation

@MainActor
enum LiveActivityService {
    static func updateMedicationActivity(
        childName: String,
        medicationName: String?,
        dosage: String?,
        scheduledDate: Date?
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        endAll()

        guard let medicationName, let scheduledDate, scheduledDate > .now else { return }

        let attributes = MedicationActivityAttributes(childName: childName)
        let state = MedicationActivityAttributes.ContentState(
            medicationName: medicationName,
            dosage: dosage ?? "",
            childName: childName,
            scheduledDate: scheduledDate
        )

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: scheduledDate.addingTimeInterval(3600)),
                pushType: nil
            )
        } catch {
            print("Live Activity error: \(error)")
        }
    }

    static func endAll() {
        for activity in Activity<MedicationActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
#endif
