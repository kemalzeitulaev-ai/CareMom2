#if canImport(UIKit)
import UIKit
#endif
import Foundation
import SwiftUI

enum PDFExportService {
    static func generateReport(for child: Child, entries: [DiaryEntry], since: Date? = nil) -> URL? {
        #if canImport(UIKit)
        let locale = L10n.exportLocale
        let filtered = entries
            .filter { entry in since.map { entry.date >= $0 } ?? true }
            .sorted { $0.date > $1.date }

        var pdfMeta: [String: Any] = [
            kCGPDFContextCreator as String: "CareMom",
            kCGPDFContextAuthor as String: child.fullName
        ]
        if let since {
            let sinceText = since.formatted(date: .long, time: .omitted)
            pdfMeta[kCGPDFContextSubject as String] = L10n.format("pdf.subject_since", locale: locale, sinceText)
        }

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMeta

        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            let title = L10n.format("pdf.health_diary", locale: locale, child.fullName)
            title.draw(at: CGPoint(x: 40, y: 40), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.darkGray
            ])

            let dob = child.dateOfBirth.formatted(date: .long, time: .omitted)
            let age = child.ageDescription(locale: locale)
            var info = L10n.format("pdf.dob_age", locale: locale, dob, age)
            if let since {
                let sinceFormatted = since.formatted(date: .abbreviated, time: .omitted)
                info += " · " + L10n.format("pdf.entries_since", locale: locale, sinceFormatted)
            }
            info.draw(at: CGPoint(x: 40, y: 70), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ])

            var y: CGFloat = 110

            for entry in filtered.prefix(60) {
                if y > pageHeight - 60 {
                    context.beginPage()
                    y = 40
                }

                let line = "\(entry.date.formatted(date: .abbreviated, time: .shortened)) — \(entry.displayTitle)"
                line.draw(at: CGPoint(x: 40, y: y), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                    .foregroundColor: UIColor.black
                ])
                y += 18

                if let temp = entry.temperature {
                    let tempLine = L10n.format("pdf.temperature", locale: locale, temp)
                    tempLine.draw(at: CGPoint(x: 56, y: y), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor.darkGray
                    ])
                    y += 16
                }

                if !entry.notes.isEmpty {
                    entry.notes.draw(at: CGPoint(x: 56, y: y), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor.darkGray
                    ])
                    y += 16
                }
                y += 8
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CareMom-\(child.firstName).pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
        #else
        return nil
        #endif
    }

    static func generateDoctorVisitReport(for child: Child, entries: [DiaryEntry]) -> URL? {
        let since = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        let recent = entries.filter { $0.date >= since }.sorted { $0.date > $1.date }
        #if canImport(UIKit)
        let locale = L10n.exportLocale
        let none = L10n.t("child.none", locale: locale).lowercased()
        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: 595, height: 842),
            format: format
        )
        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 40

            func draw(_ text: String, font: UIFont, color: UIColor = .black) {
                if y > 780 { context.beginPage(); y = 40 }
                text.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: font, .foregroundColor: color])
                y += font.lineHeight + 6
            }

            let dob = child.dateOfBirth.formatted(date: .long, time: .omitted)
            let age = child.ageDescription(locale: locale)
            draw(L10n.format("pdf.doctor_report", locale: locale, child.fullName), font: .boldSystemFont(ofSize: 20))
            draw(L10n.format("pdf.dob_age", locale: locale, dob, age), font: .systemFont(ofSize: 12), color: .gray)
            let allergies = child.allergies.isEmpty ? none : child.allergies
            draw(L10n.format("pdf.blood_allergies", locale: locale, child.bloodType.title, allergies), font: .systemFont(ofSize: 12), color: .gray)
            let chronic = child.chronicConditions.isEmpty ? none : child.chronicConditions
            draw(L10n.format("pdf.chronic", locale: locale, chronic), font: .systemFont(ofSize: 12), color: .gray)
            y += 10

            let temps = recent.compactMap { e -> String? in
                guard let t = e.temperature else { return nil }
                return "\(e.date.formatted(date: .abbreviated, time: .omitted)): \(String(format: "%.1f", t))°C"
            }
            if !temps.isEmpty {
                draw(L10n.t("pdf.temperature_14d", locale: locale), font: .boldSystemFont(ofSize: 14))
                temps.prefix(10).forEach { draw("  • \($0)", font: .systemFont(ofSize: 12)) }
            }

            let illnesses = recent.filter { $0.type == .illness }
            if !illnesses.isEmpty {
                draw(L10n.t("pdf.symptoms_illnesses", locale: locale), font: .boldSystemFont(ofSize: 14))
                for e in illnesses.prefix(8) {
                    let sym = e.symptoms.map(\.title).joined(separator: ", ")
                    draw("  • \(e.date.formatted(date: .abbreviated, time: .omitted)): \(sym.isEmpty ? e.displayTitle : sym)", font: .systemFont(ofSize: 12))
                }
            }

            let meds = recent.filter { $0.type == .medication }
            if !meds.isEmpty {
                draw(L10n.t("pdf.medications", locale: locale), font: .boldSystemFont(ofSize: 14))
                for e in meds.prefix(8) {
                    draw("  • \(e.medicationName) \(e.dosage)", font: .systemFont(ofSize: 12))
                }
            }

            let generated = Date.now.formatted(date: .long, time: .shortened)
            draw(L10n.format("pdf.generated", locale: locale, generated), font: .systemFont(ofSize: 10), color: .gray)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CareMom-doctor-\(child.firstName).pdf")
        try? data.write(to: url)
        return url
        #else
        return nil
        #endif
    }
}
