import Foundation

enum VoiceNoteStorage {
    private static var directory: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VoiceNotes", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    static func exists(_ filename: String) -> Bool {
        FileManager.default.fileExists(atPath: url(for: filename).path)
    }

    @discardableResult
    static func save(from sourceURL: URL) throws -> String {
        let filename = "voice-\(UUID().uuidString).m4a"
        let destination = url(for: filename)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return filename
    }

    static func delete(_ filename: String?) {
        guard let filename else { return }
        try? FileManager.default.removeItem(at: url(for: filename))
    }
}

extension DiaryEntry {
    var voiceNoteURL: URL? {
        guard let filename = voiceNoteFilename, VoiceNoteStorage.exists(filename) else { return nil }
        return VoiceNoteStorage.url(for: filename)
    }

    var hasVoiceNote: Bool {
        voiceNoteURL != nil
    }
}
