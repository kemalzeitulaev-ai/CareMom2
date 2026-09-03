import Foundation

enum EntryType: String, Codable, CaseIterable, Identifiable {
    case illness
    case medication
    case feeding
    case sleep
    case stool
    case vaccination
    case test
    case doctorVisit
    case note

    var id: String { rawValue }

    var title: String {
        switch self {
        case .illness: String(localized: "entry.type.illness")
        case .medication: String(localized: "entry.type.medication")
        case .feeding: String(localized: "entry.type.feeding")
        case .sleep: String(localized: "entry.type.sleep")
        case .stool: String(localized: "entry.type.stool")
        case .vaccination: String(localized: "entry.type.vaccination")
        case .test: String(localized: "entry.type.test")
        case .doctorVisit: String(localized: "entry.type.doctor")
        case .note: String(localized: "entry.type.note")
        }
    }

    var icon: String {
        switch self {
        case .illness: "thermometer.medium"
        case .medication: "pills.fill"
        case .feeding: "fork.knife"
        case .sleep: "moon.fill"
        case .stool: "leaf.fill"
        case .vaccination: "syringe.fill"
        case .test: "doc.text.magnifyingglass"
        case .doctorVisit: "stethoscope"
        case .note: "note.text"
        }
    }

    var colorName: String {
        switch self {
        case .illness: "EntryIllness"
        case .medication: "EntryMedication"
        case .feeding: "EntryFeeding"
        case .sleep: "EntrySleep"
        case .stool: "EntryStool"
        case .vaccination: "EntryVaccination"
        case .test: "EntryTest"
        case .doctorVisit: "EntryDoctor"
        case .note: "EntryNote"
        }
    }
}

enum Symptom: String, CaseIterable, Identifiable {
    case fever
    case cough
    case runnyNose
    case rash
    case soreThroat
    case vomiting
    case diarrhea
    case fatigue
    case headache

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fever: String(localized: "symptom.fever")
        case .cough: String(localized: "symptom.cough")
        case .runnyNose: String(localized: "symptom.runny_nose")
        case .rash: String(localized: "symptom.rash")
        case .soreThroat: String(localized: "symptom.sore_throat")
        case .vomiting: String(localized: "symptom.vomiting")
        case .diarrhea: String(localized: "symptom.diarrhea")
        case .fatigue: String(localized: "symptom.fatigue")
        case .headache: String(localized: "symptom.headache")
        }
    }

    init?(legacyRawValue: String) {
        let legacy: [String: Symptom] = [
            "Температура": .fever, "Кашель": .cough, "Насморк": .runnyNose,
            "Сыпь": .rash, "Боль в горле": .soreThroat, "Рвота": .vomiting,
            "Диарея": .diarrhea, "Слабость": .fatigue, "Головная боль": .headache
        ]
        if let match = Symptom(rawValue: legacyRawValue) {
            self = match
        } else if let match = legacy[legacyRawValue] {
            self = match
        } else {
            return nil
        }
    }
}

enum BloodType: String, CaseIterable, Identifiable {
    case aPositive = "A+"
    case aNegative = "A-"
    case bPositive = "B+"
    case bNegative = "B-"
    case abPositive = "AB+"
    case abNegative = "AB-"
    case oPositive = "O+"
    case oNegative = "O-"
    case unknown = "unknown"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unknown: String(localized: "blood.unknown")
        default: rawValue
        }
    }

    static func fromStored(_ value: String) -> BloodType {
        if value == "Не знаю" || value == "unknown" { return .unknown }
        return BloodType(rawValue: value) ?? .unknown
    }
}
