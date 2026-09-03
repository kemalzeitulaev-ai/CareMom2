import Foundation
import SwiftData

enum BackupService {
    struct ExportPayload: Codable {
        let exportedAt: Date
        let version: Int?
        let children: [ChildExport]
    }

    struct ChildExport: Codable {
        let id: UUID
        let firstName: String
        let lastName: String
        let dateOfBirth: Date
        let genderRaw: String
        let bloodTypeRaw: String
        let allergies: String
        let chronicConditions: String
        let entries: [EntryExport]
        let growth: [GrowthExport]
        let vaccinations: [VaccineExport]
        let medicationCourses: [MedicationExport]?
    }

    struct EntryExport: Codable {
        let date: Date
        let typeRaw: String
        let title: String
        let notes: String
        let temperature: Double?
        let symptomsRaw: String?
        let medicationName: String
        let dosage: String
        let speechTranscript: String
    }

    struct GrowthExport: Codable {
        let date: Date
        let weightKg: Double?
        let heightCm: Double?
        let notes: String
    }

    struct VaccineExport: Codable {
        let name: String
        let scheduledDate: Date
        let isCompleted: Bool
        let notes: String
    }

    struct MedicationExport: Codable {
        let name: String
        let dosage: String
        let startDate: Date
        let durationDays: Int
        let timesPerDay: Int
        let reminderEnabled: Bool
        let isActive: Bool
    }

    private static let exportVersion = 2

    static func exportData(children: [Child]) throws -> URL {
        let payload = ExportPayload(
            exportedAt: .now,
            version: exportVersion,
            children: children.map(exportChild)
        )
        let data = try JSONEncoder().encode(payload)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CareMom-backup-\(Int(Date.now.timeIntervalSince1970)).json")
        try data.write(to: url)
        return url
    }

    @MainActor
    static func importData(from url: URL, context: ModelContext) throws -> Int {
        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder().decode(ExportPayload.self, from: data)
        let existingChildren = try context.fetch(FetchDescriptor<Child>())
        let existingIDs = Set(existingChildren.map(\.id))
        var count = 0

        for exported in payload.children {
            guard !existingIDs.contains(exported.id) else { continue }

            let child = Child(
                firstName: exported.firstName,
                lastName: exported.lastName,
                dateOfBirth: exported.dateOfBirth,
                gender: ChildGender(rawValue: exported.genderRaw) ?? .girl,
                bloodType: BloodType.fromStored(exported.bloodTypeRaw),
                allergies: exported.allergies,
                chronicConditions: exported.chronicConditions
            )
            child.id = exported.id
            context.insert(child)
            count += 1

            for entry in exported.entries {
                let record = DiaryEntry(
                    date: entry.date,
                    type: EntryType(rawValue: entry.typeRaw) ?? .note,
                    title: entry.title,
                    notes: entry.notes,
                    temperature: entry.temperature,
                    medicationName: entry.medicationName,
                    dosage: entry.dosage,
                    child: child
                )
                record.symptomsRaw = entry.symptomsRaw ?? ""
                record.speechTranscript = entry.speechTranscript
                context.insert(record)
            }

            for g in exported.growth {
                context.insert(GrowthRecord(
                    date: g.date, weightKg: g.weightKg, heightCm: g.heightCm,
                    notes: g.notes, child: child
                ))
            }

            for v in exported.vaccinations {
                let record = VaccinationRecord(
                    name: v.name, scheduledDate: v.scheduledDate,
                    notes: v.notes, child: child
                )
                if v.isCompleted { record.markCompleted(on: v.scheduledDate) }
                context.insert(record)
            }

            for med in exported.medicationCourses ?? [] {
                let course = MedicationCourse(
                    name: med.name,
                    dosage: med.dosage,
                    startDate: med.startDate,
                    durationDays: med.durationDays,
                    timesPerDay: med.timesPerDay,
                    reminderEnabled: med.reminderEnabled,
                    child: child
                )
                course.isActive = med.isActive
                course.generateIntakeSchedule()
                context.insert(course)
            }
        }

        try context.save()
        return count
    }

    private static func exportChild(_ child: Child) -> ChildExport {
        ChildExport(
            id: child.id,
            firstName: child.firstName,
            lastName: child.lastName,
            dateOfBirth: child.dateOfBirth,
            genderRaw: child.genderRaw,
            bloodTypeRaw: child.bloodTypeRaw,
            allergies: child.allergies,
            chronicConditions: child.chronicConditions,
            entries: child.entries.map {
                EntryExport(
                    date: $0.date, typeRaw: $0.typeRaw, title: $0.title, notes: $0.notes,
                    temperature: $0.temperature, symptomsRaw: $0.symptomsRaw,
                    medicationName: $0.medicationName, dosage: $0.dosage,
                    speechTranscript: $0.speechTranscript
                )
            },
            growth: child.growthRecords.map {
                GrowthExport(date: $0.date, weightKg: $0.weightKg, heightCm: $0.heightCm, notes: $0.notes)
            },
            vaccinations: child.vaccinations.map {
                VaccineExport(name: $0.name, scheduledDate: $0.scheduledDate,
                              isCompleted: $0.isCompleted, notes: $0.notes)
            },
            medicationCourses: child.medicationCourses.map {
                MedicationExport(
                    name: $0.name, dosage: $0.dosage, startDate: $0.startDate,
                    durationDays: $0.durationDays, timesPerDay: $0.timesPerDay,
                    reminderEnabled: $0.reminderEnabled, isActive: $0.isActive
                )
            }
        )
    }
}
