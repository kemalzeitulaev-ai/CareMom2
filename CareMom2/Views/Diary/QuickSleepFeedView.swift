import SwiftUI
import SwiftData

enum QuickActivityKind {
    case sleep
    case feeding

    var title: String {
        switch self {
        case .sleep: String(localized: "quick.sleep.title")
        case .feeding: String(localized: "quick.feeding.title")
        }
    }

    var icon: String {
        switch self {
        case .sleep: "moon.fill"
        case .feeding: "fork.knife"
        }
    }
}

struct QuickSleepFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let child: Child
    let kind: QuickActivityKind

    @State private var notes = ""

    private var presets: [(String, String)] {
        switch kind {
        case .sleep:
            [
                (String(localized: "quick.sleep.fell_asleep"), String(localized: "quick.sleep.fell_asleep.note")),
                (String(localized: "quick.sleep.woke_up"), String(localized: "quick.sleep.woke_up.note"))
            ]
        case .feeding:
            [
                (String(localized: "quick.feeding.breast"), String(localized: "quick.feeding.breast.note")),
                (String(localized: "quick.feeding.bottle"), String(localized: "quick.feeding.bottle.note")),
                (String(localized: "quick.feeding.solid"), String(localized: "quick.feeding.solid.note")),
                (String(localized: "quick.feeding.snack"), String(localized: "quick.feeding.snack.note"))
            ]
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Label(child.firstName, systemImage: kind.icon)
                    .font(.headline)
                    .foregroundStyle(CareMomTheme.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(presets, id: \.0) { title, defaultNote in
                        Button {
                            save(title: title, note: defaultNote)
                        } label: {
                            Text(title)
                                .font(.subheadline.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(CareMomTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .foregroundStyle(CareMomTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                TextField(String(localized: "quick.notes.placeholder"), text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(CareMomTheme.creamBackground)
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .careMomSheetBackground(CareMomTheme.creamBackground)
    }

    private func save(title: String, note: String) {
        let entryType: EntryType = kind == .sleep ? .sleep : .feeding
        let combinedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? note : notes
        let entry = DiaryEntry(
            date: .now,
            type: entryType,
            title: title,
            notes: combinedNotes,
            child: child
        )
        modelContext.insert(entry)
        try? modelContext.save()
        HapticService.success()
        dismiss()
    }
}
