#if canImport(UIKit)
import UIKit
import Vision

enum LabOCRService {
    struct Result {
        let fullText: String
        let highlights: [String]
    }

    static func analyze(imageData: Data) async -> Result? {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }

                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                let fullText = lines.joined(separator: "\n")
                let highlights = extractHighlights(from: lines)
                continuation.resume(returning: Result(fullText: fullText, highlights: highlights))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ru-RU", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    private static func extractHighlights(from lines: [String]) -> [String] {
        let keywords = [
            "гемоглобин", "hemoglobin", "hb", "hgb",
            "лейкоц", "wbc", "leuk",
            "тромбоц", "plt", "platelet",
            "глюкоз", "glucose",
            "соэ", "esr",
            "crp", "срб", "c-reactive",
            "alt", "ast", "билирубин", "bilirubin",
            "креатинин", "creatinine",
            "железо", "iron", "ferritin", "ферритин"
        ]

        var highlights: [String] = []
        for line in lines {
            let lower = line.lowercased()
            guard keywords.contains(where: { lower.contains($0) }) || containsLabValue(line) else { continue }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !highlights.contains(trimmed) {
                highlights.append(trimmed)
            }
        }
        return Array(highlights.prefix(12))
    }

    private static func containsLabValue(_ line: String) -> Bool {
        let pattern = #"\d+([.,]\d+)?\s*(g/l|g/l|mg/l|mmol/l|×10|10\^|/l|%)?"#
        return line.range(of: pattern, options: .regularExpression) != nil
    }
}
#endif
