#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

struct ChildAvatarView: View {
    let child: Child
    var size: CGFloat = 44

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let data = child.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderAvatar
            }
            #else
            placeholderAvatar
            #endif
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholderAvatar: some View {
        ZStack {
            Circle()
                .fill(child.gender.avatarBackground)
            Text(String(child.firstName.prefix(1)).uppercased())
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundStyle(child.gender.avatarForeground)
        }
    }
}

struct ChildSelectorBar: View {
    let children: [Child]
    @Binding var selectedChildID: UUID?

    var body: some View {
        Group {
            if children.count <= 4 {
                HStack(spacing: 24) {
                    ForEach(children, id: \.id) { child in
                        childButton(for: child)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(children, id: \.id) { child in
                            childButton(for: child)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private func childButton(for child: Child) -> some View {
        let isSelected = selectedChildID == child.id
            || (selectedChildID == nil && child.id == children.first?.id)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedChildID = child.id
            }
        } label: {
            VStack(spacing: 6) {
                ChildAvatarView(child: child, size: 52)
                    .overlay {
                        Circle()
                            .stroke(
                                isSelected ? child.gender.accentColor : Color.clear,
                                lineWidth: 3
                            )
                    }
                Text(child.firstName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? CareMomTheme.textPrimary : CareMomTheme.textSecondary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct EntryTypeChip: View {
    let type: EntryType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundStyle(isSelected ? .white : CareMomTheme.entryColor(for: type))
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(isSelected ? CareMomTheme.entryColor(for: type) : CareMomTheme.entryColor(for: type).opacity(0.15))
                )
            Text(type.title.components(separatedBy: " / ").first ?? type.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(CareMomTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 72)
        }
    }
}

struct QuickAddFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: CareMomTheme.fabSize, height: CareMomTheme.fabSize)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [CareMomTheme.warmCoral, CareMomTheme.primaryPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: CareMomTheme.warmCoral.opacity(0.4), radius: 12, y: 6)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(L10n.t("accessibility.add_entry"))
    }
}
