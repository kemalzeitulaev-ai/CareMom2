import Foundation
import SwiftData

@Model
final class Child {
    var id: UUID
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var photoData: Data?
    var bloodTypeRaw: String
    var genderRaw: String = ChildGender.girl.rawValue
    var allergies: String
    var chronicConditions: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DiaryEntry.child)
    var entries: [DiaryEntry]

    @Relationship(deleteRule: .cascade, inverse: \MedicationCourse.child)
    var medicationCourses: [MedicationCourse]

    @Relationship(deleteRule: .cascade, inverse: \GalleryItem.child)
    var galleryItems: [GalleryItem]

    @Relationship(deleteRule: .cascade, inverse: \GrowthRecord.child)
    var growthRecords: [GrowthRecord]

    @Relationship(deleteRule: .cascade, inverse: \VaccinationRecord.child)
    var vaccinations: [VaccinationRecord]

    init(
        firstName: String,
        lastName: String = "",
        dateOfBirth: Date,
        photoData: Data? = nil,
        gender: ChildGender = .girl,
        bloodType: BloodType = .unknown,
        allergies: String = "",
        chronicConditions: String = ""
    ) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.photoData = photoData
        self.bloodTypeRaw = bloodType.rawValue
        self.genderRaw = gender.rawValue
        self.allergies = allergies
        self.chronicConditions = chronicConditions
        self.createdAt = .now
        self.entries = []
        self.medicationCourses = []
        self.galleryItems = []
        self.growthRecords = []
        self.vaccinations = []
    }

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var bloodType: BloodType {
        BloodType.fromStored(bloodTypeRaw)
    }

    var gender: ChildGender {
        ChildGender(rawValue: genderRaw) ?? .girl
    }

    var ageDescription: String {
        ageDescription(locale: .current)
    }

    func ageDescription(locale: Locale) -> String {
        let components = Calendar.current.dateComponents([.year, .month], from: dateOfBirth, to: .now)
        if let years = components.year, years > 0 {
            return Self.ageYears(years, locale: locale)
        }
        if let months = components.month, months > 0 {
            return Self.ageMonths(months, locale: locale)
        }
        return L10n.t("age.newborn", locale: locale)
    }

    var latestGrowthRecord: GrowthRecord? {
        growthRecords.max(by: { $0.date < $1.date })
    }

    private static func ageYears(_ n: Int, locale: Locale) -> String {
        let isRu = locale.language.languageCode?.identifier == "ru"
        if isRu {
            return "\(n) \(yearsWordRu(n))"
        }
        return n == 1 ? "\(n) year" : "\(n) years"
    }

    private static func ageMonths(_ n: Int, locale: Locale) -> String {
        let isRu = locale.language.languageCode?.identifier == "ru"
        if isRu {
            return "\(n) \(monthsWordRu(n))"
        }
        return n == 1 ? "\(n) month" : "\(n) months"
    }

    private static func yearsWordRu(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod100 >= 11 && mod100 <= 14 { return "лет" }
        switch mod10 {
        case 1: return "год"
        case 2, 3, 4: return "года"
        default: return "лет"
        }
    }

    private static func monthsWordRu(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod100 >= 11 && mod100 <= 14 { return "месяцев" }
        switch mod10 {
        case 1: return "месяц"
        case 2, 3, 4: return "месяца"
        default: return "месяцев"
        }
    }
}
