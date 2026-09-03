import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class VoiceNoteRecorder {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    private(set) var isRecording = false
    private(set) var recordingDuration: TimeInterval = 0
    private(set) var lastRecordingURL: URL?
    private(set) var permissionDenied = false

    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            await startRecording()
        }
    }

    func reset() {
        stopRecording()
        lastRecordingURL = nil
        recordingDuration = 0
    }

    private func startRecording() async {
        #if os(iOS)
        let granted = await requestPermission()
        guard granted else {
            permissionDenied = true
            return
        }
        permissionDenied = false

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("voice-recording-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            isRecording = true
            lastRecordingURL = url
            recordingDuration = 0

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration = self?.recorder?.currentTime ?? 0
                }
            }
        } catch {
            isRecording = false
        }
        #endif
    }

    private func stopRecording() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recordingDuration = recorder?.currentTime ?? recordingDuration
        recorder = nil
        isRecording = false
    }

    private func requestPermission() async -> Bool {
        #if os(iOS)
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
        #else
        return false
        #endif
    }
}
