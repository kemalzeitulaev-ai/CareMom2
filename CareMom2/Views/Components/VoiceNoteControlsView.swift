import SwiftUI

struct VoiceNoteControlsView: View {
    @Binding var voiceFilename: String?
    @Binding var speechTranscript: String

    @State private var recorder = VoiceNoteRecorder()
    @State private var player = VoiceNotePlayer()
    @State private var pendingRecordingURL: URL?
    @State private var showPermissionAlert = false

    private var hasRecording: Bool {
        pendingRecordingURL != nil || (voiceFilename != nil && VoiceNoteStorage.exists(voiceFilename!))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .careMomPulseSymbol(isActive: recorder.isRecording)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t("voice.title"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CareMomTheme.textPrimary)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(CareMomTheme.textSecondary)
                }

                Spacer()

                if recorder.isRecording {
                    Button(L10n.t("voice.stop")) {
                        Task { await stopAndSaveRecording() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else if hasRecording {
                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(CareMomTheme.lavender)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                } else {
                    Button(L10n.t("voice.record")) {
                        Task { await startRecording() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CareMomTheme.lavender)
                }
            }

            if !speechTranscript.isEmpty {
                Text(speechTranscript)
                    .font(.caption)
                    .foregroundStyle(CareMomTheme.textSecondary)
                    .padding(.top, 4)
            }

            if hasRecording && !recorder.isRecording {
                ProgressView(value: player.currentTime, total: max(player.duration, 0.01))
                    .tint(CareMomTheme.lavender)

                HStack {
                    Text(formatTime(player.currentTime))
                    Spacer()
                    Text(formatTime(player.duration))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(CareMomTheme.textSecondary)

                Button(L10n.t("voice.delete_recording"), role: .destructive) {
                    deleteRecording()
                }
                .font(.caption)
            }

            if !recorder.isRecording && !hasRecording {
                Button(L10n.t("voice.start")) {
                    Task { await startRecording() }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
        .careMomCard()
        .onAppear { loadExistingRecording() }
        .onDisappear {
            player.stop()
            if recorder.isRecording {
                recorder.reset()
            }
        }
        .alert(L10n.t("voice.no_mic"), isPresented: $showPermissionAlert) {
            Button(L10n.t("common.ok"), role: .cancel) {}
        } message: {
            Text(L10n.t("voice.no_mic_message"))
        }
    }

    private var iconName: String {
        if recorder.isRecording { return "waveform.circle.fill" }
        if hasRecording { return "mic.fill" }
        return "mic.circle.fill"
    }

    private var iconColor: Color {
        recorder.isRecording ? .red : CareMomTheme.lavender
    }

    private var statusText: String {
        if recorder.isRecording {
            return L10n.format("voice.recording", formatTime(recorder.recordingDuration))
        }
        if hasRecording {
            return player.isPlaying ? L10n.t("voice.playing") : L10n.t("voice.tap_play")
        }
        return L10n.t("voice.hint")
    }

    private func loadExistingRecording() {
        guard let filename = voiceFilename, VoiceNoteStorage.exists(filename) else { return }
        player.load(filename: filename)
    }

    private func startRecording() async {
        player.stop()
        await recorder.toggleRecording()
        if recorder.permissionDenied {
            showPermissionAlert = true
        }
    }

    private func stopAndSaveRecording() async {
        await recorder.toggleRecording()
        guard let url = recorder.lastRecordingURL else { return }

        do {
            if let oldFilename = voiceFilename {
                VoiceNoteStorage.delete(oldFilename)
            }
            let filename = try VoiceNoteStorage.save(from: url)
            voiceFilename = filename
            pendingRecordingURL = url
            player.load(filename: filename)
            if speechTranscript.isEmpty, let transcript = await SpeechTranscriptionService.transcribe(url: VoiceNoteStorage.url(for: filename)) {
                speechTranscript = transcript
            }
        } catch {
            voiceFilename = nil
            pendingRecordingURL = nil
        }
    }

    private func deleteRecording() {
        player.clear()
        VoiceNoteStorage.delete(voiceFilename)
        voiceFilename = nil
        speechTranscript = ""
        pendingRecordingURL = nil
        recorder.reset()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
