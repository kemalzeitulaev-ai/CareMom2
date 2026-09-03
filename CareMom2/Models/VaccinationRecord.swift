import Foundation
import SwiftData

@Model
final class VaccinationRecord {
    var id: UUID
    var name: String
    var scheduledDate: Date
    var completedDate: Date?
    var isCompleted: Bool
    var notes: String

    var child: Child?

    init(name: String, scheduledDate: Date, notes: String = "", child: Child? = nil) {
        self.id = UUID()
        self.name = name
        self.scheduledDate = scheduledDate
        self.isCompleted = false
        self.notes = notes
        self.child = child
    }

    func markCompleted(on date: Date = .now) {
        isCompleted = true
        completedDate = date
    }
}

enum DefaultVaccine: String, CaseIterable, Identifiable {
    case bcg
    case hepatitisB
    case dtp
    case polio
    case mmr
    case flu

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bcg: L10n.t("vaccine.bcg")
        case .hepatitisB: L10n.t("vaccine.hepatitis_b")
        case .dtp: L10n.t("vaccine.dtp")
        case .polio: L10n.t("vaccine.polio")
        case .mmr: L10n.t("vaccine.mmr")
        case .flu: L10n.t("vaccine.flu")
        }
    }
}
