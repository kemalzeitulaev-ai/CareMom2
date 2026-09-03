import Foundation
import SwiftData

@Model
final class GrowthRecord {
    var id: UUID
    var date: Date
    var weightKg: Double?
    var heightCm: Double?
    var notes: String

    var child: Child?

    init(date: Date = .now, weightKg: Double? = nil, heightCm: Double? = nil, notes: String = "", child: Child? = nil) {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.notes = notes
        self.child = child
    }
}
