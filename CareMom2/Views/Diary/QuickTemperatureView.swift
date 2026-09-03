import SwiftUI
import SwiftData

struct QuickTemperatureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let child: Child

    @State private var customTemp = ""
    private let presets: [Double] = [36.6, 37.0, 37.5, 38.0, 38.5, 39.0]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(String(localized: "quick.temperature.title"))
                    .font(.headline)
                    .foregroundStyle(CareMomTheme.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(presets, id: \.self) { temp in
                        Button {
                            save(temp: temp)
                        } label: {
                            Text(String(format: "%.1f°", temp))
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(CareMomTheme.softPeach.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(temp >= 38 ? CareMomTheme.warmCoral : CareMomTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack {
                    TextField(String(localized: "quick.temperature.other"), text: $customTemp)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Button(String(localized: "common.save")) {
                        if let temp = Double(customTemp.replacingOccurrences(of: ",", with: ".")) {
                            save(temp: temp)
                        }
                    }
                    .disabled(Double(customTemp.replacingOccurrences(of: ",", with: ".")) == nil)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(CareMomTheme.creamBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .careMomSheetBackground(CareMomTheme.creamBackground)
    }

    private func save(temp: Double) {
        let entry = DiaryEntry(
            date: .now,
            type: .illness,
            notes: "",
            temperature: temp,
            symptoms: [.fever],
            child: child
        )
        modelContext.insert(entry)
        try? modelContext.save()
        HapticService.success()
        dismiss()
    }
}
