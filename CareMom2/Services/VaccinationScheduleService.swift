import Foundation
import SwiftData

struct ScheduledVaccine: Identifiable {
    let id = UUID()
    let name: String
    let recommendedDate: Date
    let ageLabel: String
}

enum VaccinationScheduleService {
    static func recommendedSchedule(for dateOfBirth: Date, existing: [VaccinationRecord]) -> [ScheduledVaccine] {
        let locale = L10n.exportLocale
        let existingNames = Set(existing.map { $0.name.lowercased() })
        let calendar = Calendar.current

        let milestones: [(months: Int, vaccines: [(nameKey: String, ageKey: String)])] = [
            (0, [("schedule.hep_b_1", "schedule.age.0m"), ("schedule.bcg", "schedule.age.0_1m")]),
            (1, [("schedule.dtp_1", "schedule.age.1m"), ("schedule.polio_1", "schedule.age.1m"), ("schedule.hep_b_2", "schedule.age.1m")]),
            (2, [("schedule.dtp_2", "schedule.age.2m"), ("schedule.polio_2", "schedule.age.2m")]),
            (3, [("schedule.dtp_3", "schedule.age.3m"), ("schedule.polio_3", "schedule.age.3m")]),
            (4, [("schedule.hep_b_3_4m", "schedule.age.4m")]),
            (6, [("schedule.hep_b_3_6m", "schedule.age.6m"), ("schedule.mmr_1", "schedule.age.6m")]),
            (12, [("schedule.mmr_2", "schedule.age.12m")]),
            (18, [("schedule.dtp_revacc_18m", "schedule.age.18m"), ("schedule.polio_revacc_18m", "schedule.age.18m")]),
            (72, [("schedule.dtp_revacc_6y", "schedule.age.6y")])
        ]

        var result: [ScheduledVaccine] = []
        for milestone in milestones {
            guard let date = calendar.date(byAdding: .month, value: milestone.months, to: dateOfBirth) else { continue }
            for vaccine in milestone.vaccines {
                let name = L10n.t(String.LocalizationValue(stringLiteral: vaccine.nameKey), locale: locale)
                guard !existingNames.contains(name.lowercased()) else { continue }
                let ageLabel = L10n.t(String.LocalizationValue(stringLiteral: vaccine.ageKey), locale: locale)
                result.append(ScheduledVaccine(name: name, recommendedDate: date, ageLabel: ageLabel))
            }
        }
        return result.sorted { $0.recommendedDate < $1.recommendedDate }
    }
}
