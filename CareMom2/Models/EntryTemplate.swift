import Foundation

struct EntryTemplate: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let type: EntryType
    let entryTitle: String
    let notes: String
    let temperature: Double?
    let symptoms: [Symptom]
    let medicationName: String
    let dosage: String

    static var all: [EntryTemplate] {
        [
            EntryTemplate(title: L10n.t("template.temperature"), icon: "thermometer.medium", type: .illness,
                          entryTitle: "", notes: "", temperature: 37.5, symptoms: [.fever], medicationName: "", dosage: ""),
            EntryTemplate(title: L10n.t("template.nurofen"), icon: "pills.fill", type: .medication,
                          entryTitle: "", notes: L10n.t("template.nurofen_note"), temperature: nil, symptoms: [], medicationName: L10n.t("template.nurofen"), dosage: "5 ml"),
            EntryTemplate(title: L10n.t("template.cough"), icon: "waveform.path", type: .illness,
                          entryTitle: "", notes: "", temperature: nil, symptoms: [.cough], medicationName: "", dosage: ""),
            EntryTemplate(title: L10n.t("template.pediatrician"), icon: "stethoscope", type: .doctorVisit,
                          entryTitle: L10n.t("template.pediatrician_visit"), notes: "", temperature: nil, symptoms: [], medicationName: "", dosage: ""),
            EntryTemplate(title: L10n.t("template.doctor_questions"), icon: "list.bullet.clipboard", type: .doctorVisit,
                          entryTitle: L10n.t("template.pediatrician_visit"), notes: L10n.t("template.doctor_checklist"), temperature: nil, symptoms: [], medicationName: "", dosage: ""),
            EntryTemplate(title: L10n.t("template.poor_sleep"), icon: "moon.fill", type: .sleep,
                          entryTitle: L10n.t("template.restless_sleep"), notes: "", temperature: nil, symptoms: [], medicationName: "", dosage: ""),
            EntryTemplate(title: L10n.t("template.rash"), icon: "hand.raised.fill", type: .illness,
                          entryTitle: "", notes: "", temperature: nil, symptoms: [.rash], medicationName: "", dosage: "")
        ]
    }
}
