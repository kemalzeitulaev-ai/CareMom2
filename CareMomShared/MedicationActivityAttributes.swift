#if canImport(ActivityKit)
import ActivityKit
import Foundation

struct MedicationActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var medicationName: String
        var dosage: String
        var childName: String
        var scheduledDate: Date
    }

    var childName: String
}
#endif
