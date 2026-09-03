import Foundation
import SwiftData

@Model
final class DiaryEntry {
    var id: UUID
    var date: Date
    var typeRaw: String
    var title: String
    var notes: String
    var temperature: Double?
    var symptomsRaw: String
    var medicationName: String
    var dosage: String
    var voiceNoteFilename: String?
    var speechTranscript: String
    var photoData: Data?

    var child: Child?

    init(
        date: Date = .now,
        type: EntryType,
        title: String = "",
        notes: String = "",
        temperature: Double? = nil,
        symptoms: [Symptom] = [],
        medicationName: String = "",
        dosage: String = "",
        child: Child? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.typeRaw = type.rawValue
        self.title = title
        self.notes = notes
        self.temperature = temperature
        self.symptomsRaw = symptoms.map(\.rawValue).joined(separator: "|")
        self.medicationName = medicationName
        self.dosage = dosage
        self.speechTranscript = ""
        self.child = child
    }

    var type: EntryType {
        EntryType(rawValue: typeRaw) ?? .note
    }

    var symptoms: [Symptom] {
        symptomsRaw
            .split(separator: "|")
            .compactMap { Symptom(legacyRawValue: String($0)) }
    }

    var displayTitle: String {
        if !title.isEmpty { return title }
        switch type {
        case .illness:
            if let temperature {
                let format = String(localized: "entry.display.temperature_format")
                return String(format: format, temperature)
            }
            return symptoms.isEmpty ? type.title : symptoms.map(\.title).joined(separator: ", ")
        case .medication:
            return medicationName.isEmpty ? type.title : medicationName
        case .sleep, .feeding:
            return title.isEmpty ? type.title : title
        default:
            return type.title
        }
    }
}
