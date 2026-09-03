#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var entry: DiaryEntry

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    dateSection

                    if entry.type == .illness {
                        illnessSection
                    }

                    if entry.type == .medication {
                        medicationSection
                    }

                    if !entry.title.isEmpty && entry.type != .illness && entry.type != .medication {
                        detailRow(L10n.t("entry.title_field"), entry.title)
                    }

                    if !entry.notes.isEmpty {
                        detailRow(L10n.t("entry.notes"), entry.notes)
                    }

                    if let data = entry.photoData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VoiceNoteControlsView(voiceFilename: voiceNoteBinding, speechTranscript: speechTranscriptBinding)
                }
                .padding()
            }
            .background(CareMomTheme.creamBackground)
            .navigationTitle(entry.type.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.close")) { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(L10n.t("common.edit")) { showEdit = true }
                        Button(L10n.t("common.delete"), role: .destructive) {
                            showDeleteConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(CareMomTheme.warmCoral)
                    }
                }
            }
            .sheet(isPresented: $showEdit) {
                if let child = entry.child {
                    AddEntryView(child: child, existingEntry: entry)
                }
            }
            .confirmationDialog(L10n.t("entry.delete_confirm"), isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button(L10n.t("common.delete"), role: .destructive) {
                    VoiceNoteStorage.delete(entry.voiceNoteFilename)
                    modelContext.delete(entry)
                    dismiss()
                }
            } message: {
                Text(L10n.t("entry.delete_message"))
            }
        }
    }

    private var speechTranscriptBinding: Binding<String> {
        Binding(get: { entry.speechTranscript }, set: { entry.speechTranscript = $0 })
    }

    private var voiceNoteBinding: Binding<String?> {
        Binding(
            get: { entry.voiceNoteFilename },
            set: { entry.voiceNoteFilename = $0 }
        )
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: entry.type.icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(CareMomTheme.entryColor(for: entry.type))
                .frame(width: 56, height: 56)
                .background(CareMomTheme.entryColor(for: entry.type).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(CareMomTheme.textPrimary)
                Text(entry.type.title)
                    .font(.subheadline)
                    .foregroundStyle(CareMomTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateSection: some View {
        detailRow(
            L10n.t("entry.date_time"),
            entry.date.formatted(date: .long, time: .shortened)
        )
    }

    private var illnessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let temp = entry.temperature {
                detailRow(L10n.t("entry.temperature"), "\(String(format: "%.1f", temp))°C")
            }

            if !entry.symptoms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t("entry.symptoms"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CareMomTheme.textSecondary)
                    FlowLayout(spacing: 8) {
                        ForEach(entry.symptoms) { symptom in
                            Text(symptom.title)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(CareMomTheme.softPeach.opacity(0.5))
                                .clipShape(Capsule())
                                .foregroundStyle(CareMomTheme.textPrimary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .careMomCard()
            }
        }
    }

    private var medicationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !entry.medicationName.isEmpty {
                detailRow(L10n.t("entry.detail.medication"), entry.medicationName)
            }
            if !entry.dosage.isEmpty {
                detailRow(L10n.t("meds.dosage"), entry.dosage)
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CareMomTheme.textSecondary)
            Text(value)
                .font(.body)
                .foregroundStyle(CareMomTheme.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .careMomCard()
    }
}
