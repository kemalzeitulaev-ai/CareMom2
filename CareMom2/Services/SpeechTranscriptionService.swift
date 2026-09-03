import Foundation
import Speech

@MainActor
enum SpeechTranscriptionService {
    static func transcribe(url: URL, locale: Locale = L10n.exportLocale) async -> String? {
        let speechLocale = resolvedSpeechLocale(from: locale)
        guard SFSpeechRecognizer(locale: speechLocale) != nil else { return nil }

        let authorized = await requestAuthorization()
        guard authorized else { return nil }

        return await withCheckedContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            let recognizer = SFSpeechRecognizer(locale: speechLocale)
            var resumed = false

            recognizer?.recognitionTask(with: request) { result, error in
                if let result, result.isFinal, !resumed {
                    resumed = true
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if error != nil, !resumed {
                    resumed = true
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private static func resolvedSpeechLocale(from locale: Locale) -> Locale {
        let language = locale.language.languageCode?.identifier ?? "en"
        switch language {
        case "ru":
            return Locale(identifier: "ru_RU")
        case "en":
            return Locale(identifier: "en_US")
        default:
            if let preferred = Locale.preferredLanguages.first {
                return Locale(identifier: preferred)
            }
            return Locale(identifier: "en_US")
        }
    }

    private static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}
