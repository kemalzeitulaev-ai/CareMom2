import PhotosUI
import SwiftUI
import SwiftData

struct AddEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let child: Child
    var existingEntry: DiaryEntry?

    @State private var selectedType: EntryType = .illness
    @State private var date = Date()
    @State private var title = ""
    @State private var notes = ""
    @State private var temperatureText = ""
    @State private var selectedSymptoms: Set<Symptom> = []
    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var voiceFilename: String?
    @State private var speechTranscript = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    private var isEditing: Bool { existingEntry != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !isEditing { templatesSection }
                    typePicker
                    DatePicker(L10n.t("entry.date_time"), selection: $date)
                        .datePickerStyle(.compact)

                    typeSpecificFields
                    photoSection

                    notesSection
                    VoiceNoteControlsView(voiceFilename: $voiceFilename, speechTranscript: $speechTranscript)
                }
                .padding()
            }
            .background(CareMomTheme.creamBackground)
            .navigationTitle(isEditing ? L10n.t("entry.edit") : L10n.t("entry.new"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.save")) { saveEntry() }
                        .fontWeight(.semibold)
                        .foregroundStyle(CareMomTheme.warmCoral)
                }
            }
            .onAppear { loadExistingEntry() }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .careMomSheetBackground(CareMomTheme.creamBackground)
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("entry.templates"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CareMomTheme.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EntryTemplate.all) { template in
                        Button {
                            applyTemplate(template)
                        } label: {
                            Label(template.title, systemImage: template.icon)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(CareMomTheme.cardBackground)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(CareMomTheme.textPrimary)
                    }
                }
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("entry.photo"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CareMomTheme.textSecondary)
            PhotosPicker(selection: $photoItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text(photoData == nil ? L10n.t("entry.add_photo") : L10n.t("entry.photo_added"))
                    Spacer()
                    if photoData != nil {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
                .padding()
                .careMomCard()
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    photoData = try? await item?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    private func applyTemplate(_ template: EntryTemplate) {
        selectedType = template.type
        title = template.entryTitle
        notes = template.notes
        medicationName = template.medicationName
        dosage = template.dosage
        selectedSymptoms = Set(template.symptoms)
        if let temp = template.temperature {
            temperatureText = String(format: "%.1f", temp)
        }
        HapticService.light()
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("entry.type_section"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CareMomTheme.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(EntryType.allCases) { type in
                    Button {
                        selectedType = type
                    } label: {
                        EntryTypeChip(type: type, isSelected: selectedType == type)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        }
    }

    @ViewBuilder
    private var typeSpecificFields: some View {
        switch selectedType {
        case .illness:
            illnessFields
        case .medication:
            medicationFields
        default:
            TextField(L10n.t("entry.title_field"), text: $title)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var illnessFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🌡")
                TextField(L10n.t("entry.temperature"), text: $temperatureText)
                    .keyboardType(.decimalPad)
                Text("°C")
                    .foregroundStyle(CareMomTheme.textSecondary)
            }
            .padding()
            .background(CareMomTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(L10n.t("entry.symptoms"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CareMomTheme.textSecondary)

            FlowLayout(spacing: 8) {
                ForEach(Symptom.allCases) { symptom in
                    Button {
                        if selectedSymptoms.contains(symptom) {
                            selectedSymptoms.remove(symptom)
                        } else {
                            selectedSymptoms.insert(symptom)
                        }
                    } label: {
                        Text(symptom.title)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(selectedSymptoms.contains(symptom)
                                          ? CareMomTheme.warmCoral
                                          : CareMomTheme.softPeach.opacity(0.5))
                            )
                            .foregroundStyle(selectedSymptoms.contains(symptom) ? .white : CareMomTheme.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var medicationFields: some View {
        VStack(spacing: 12) {
            TextField(L10n.t("entry.medication_name"), text: $medicationName)
                .textFieldStyle(.roundedBorder)
            TextField(L10n.t("meds.dosage"), text: $dosage)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("entry.notes"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CareMomTheme.textSecondary)
            TextField(L10n.t("entry.notes_placeholder"), text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding()
                .background(CareMomTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func loadExistingEntry() {
        guard let entry = existingEntry else { return }
        selectedType = entry.type
        date = entry.date
        title = entry.title
        notes = entry.notes
        if let temp = entry.temperature {
            temperatureText = String(format: "%.1f", temp)
        }
        selectedSymptoms = Set(entry.symptoms)
        medicationName = entry.medicationName
        dosage = entry.dosage
        voiceFilename = entry.voiceNoteFilename
        speechTranscript = entry.speechTranscript
        photoData = entry.photoData
    }

    private func saveEntry() {
        let temp = Double(temperatureText.replacingOccurrences(of: ",", with: "."))

        if let entry = existingEntry {
            entry.date = date
            entry.typeRaw = selectedType.rawValue
            entry.title = title
            entry.notes = notes
            entry.temperature = temp
            entry.symptomsRaw = selectedSymptoms.map(\.rawValue).joined(separator: "|")
            entry.medicationName = medicationName
            entry.dosage = dosage
            entry.voiceNoteFilename = voiceFilename
            entry.speechTranscript = speechTranscript
            entry.photoData = photoData
        } else {
            let entry = DiaryEntry(
                date: date,
                type: selectedType,
                title: title,
                notes: notes,
                temperature: temp,
                symptoms: Array(selectedSymptoms),
                medicationName: medicationName,
                dosage: dosage,
                child: child
            )
            entry.voiceNoteFilename = voiceFilename
            entry.speechTranscript = speechTranscript
            entry.photoData = photoData
            modelContext.insert(entry)
        }
        HapticService.success()
        dismiss()
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
