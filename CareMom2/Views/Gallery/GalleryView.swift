import PhotosUI
import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.firstName) private var children: [Child]
    @Query(sort: \GalleryItem.date, order: .reverse) private var allItems: [GalleryItem]

    @Bindable var appState: AppState
    @State private var photoItem: PhotosPickerItem?
    @State private var detailRoute: GalleryItemRoute?
    @State private var isScanning = false

    private var selectedChild: Child? {
        appState.selectedChild(from: children)
    }

    private var items: [GalleryItem] {
        guard let child = selectedChild else { return [] }
        return allItems.filter { $0.child?.id == child.id }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !children.isEmpty && children.count > 1 {
                    ChildSelectorBar(
                        children: children,
                        selectedChildID: $appState.selectedChildID
                    )
                    .padding(.vertical, 12)
                    .background(CareMomTheme.creamBackground)
                }

                Group {
                    if children.isEmpty {
                        ContentUnavailableView(String(localized: "gallery.add_child"), systemImage: "photo.on.rectangle.angled")
                    } else if items.isEmpty {
                        ContentUnavailableView {
                            Label(String(localized: "gallery.empty"), systemImage: "photo.stack")
                        } description: {
                            Text(String(localized: "gallery.empty.hint"))
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(items, id: \.id) { item in
                                    Button {
                                        detailRoute = GalleryItemRoute(item: item)
                                    } label: {
                                        GalleryItemView(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .id(appState.selectedChildID)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isScanning {
                    ProgressView(String(localized: "gallery.scanning"))
                        .padding()
                }
            }
            .background(CareMomTheme.creamBackground)
            .navigationTitle(String(localized: "tab.gallery"))
            .toolbar {
                if !children.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(CareMomTheme.warmCoral)
                        }
                    }
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task { await addPhoto(from: newItem) }
            }
            .onChange(of: children.count) { _, _ in
                appState.ensureSelection(from: children)
            }
            .onAppear {
                appState.ensureSelection(from: children)
            }
            .sheet(item: $detailRoute) { route in
                GalleryDetailView(item: route.item)
            }
        }
    }

    private func addPhoto(from item: PhotosPickerItem?) async {
        guard let child = selectedChild,
              let data = try? await item?.loadTransferable(type: Data.self) else { return }

        isScanning = true
        defer {
            isScanning = false
            photoItem = nil
        }

        let galleryItem = GalleryItem(imageData: data, child: child)

        #if canImport(UIKit)
        if let result = await LabOCRService.analyze(imageData: data) {
            galleryItem.ocrText = result.highlights.isEmpty ? result.fullText : result.highlights.joined(separator: "\n")
            galleryItem.title = String(localized: "gallery.lab_result")
        }
        #endif

        modelContext.insert(galleryItem)
        try? modelContext.save()
        HapticService.success()
    }
}

#if canImport(UIKit)
import UIKit

struct GalleryItemView: View {
    let item: GalleryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = UIImage(data: item.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(CareMomTheme.textSecondary)
            if !item.title.isEmpty {
                Text(item.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CareMomTheme.textPrimary)
            }
            if !item.ocrText.isEmpty {
                Label(String(localized: "ocr.results"), systemImage: "text.viewfinder")
                    .font(.caption2)
                    .foregroundStyle(CareMomTheme.lavender)
            }
        }
        .careMomCard()
        .padding(4)
    }
}
#endif
