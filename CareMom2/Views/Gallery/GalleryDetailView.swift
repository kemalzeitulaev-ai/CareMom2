#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
import SwiftData

struct GalleryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: GalleryItem

    @State private var isScanning = false
    @State private var scanMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: item.imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    #endif

                    if isScanning {
                        ProgressView(String(localized: "ocr.scanning"))
                    } else if !item.ocrText.isEmpty {
                        ocrSection
                    } else {
                        Text(String(localized: "ocr.empty"))
                            .font(.caption)
                            .foregroundStyle(CareMomTheme.textSecondary)
                    }

                    if let scanMessage {
                        Text(scanMessage)
                            .font(.caption)
                            .foregroundStyle(CareMomTheme.warmCoral)
                    }

                    Button(String(localized: "ocr.rescan")) {
                        Task { await rescan() }
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    if !item.ocrText.isEmpty, let child = item.child {
                        Button(String(localized: "ocr.create_entry")) {
                            createDiaryEntry(for: child)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
            }
            .background(CareMomTheme.creamBackground)
            .navigationTitle(item.title.isEmpty ? String(localized: "gallery.detail.title") : item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.close")) { dismiss() }
                }
            }
        }
    }

    private var ocrSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "ocr.results"))
                .font(.headline)
            Text(item.ocrText)
                .font(.caption)
                .foregroundStyle(CareMomTheme.textPrimary)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CareMomTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func rescan() async {
        isScanning = true
        scanMessage = nil
        defer { isScanning = false }

        #if canImport(UIKit)
        if let result = await LabOCRService.analyze(imageData: item.imageData) {
            item.ocrText = result.highlights.isEmpty ? result.fullText : result.highlights.joined(separator: "\n")
            if item.title.isEmpty {
                item.title = String(localized: "gallery.lab_result")
            }
            try? modelContext.save()
            HapticService.success()
        } else {
            scanMessage = String(localized: "ocr.failed")
        }
        #endif
    }

    private func createDiaryEntry(for child: Child) {
        let entry = DiaryEntry(
            date: item.date,
            type: .test,
            title: String(localized: "gallery.lab_result"),
            notes: item.ocrText,
            child: child
        )
        entry.photoData = item.imageData
        modelContext.insert(entry)
        try? modelContext.save()
        HapticService.success()
        dismiss()
    }
}

struct GalleryItemRoute: Identifiable {
    let id: UUID
    let item: GalleryItem

    init(item: GalleryItem) {
        self.id = item.id
        self.item = item
    }
}
