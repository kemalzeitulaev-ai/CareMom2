import SwiftUI

enum CareMomTheme {
    static let cornerRadius: CGFloat = 20
    static let cardCornerRadius: CGFloat = 16
    static let fabSize: CGFloat = 60
    static let minTapTarget: CGFloat = 48

    static let primaryPink = Color("PrimaryPink")
    static let softPeach = Color("SoftPeach")
    static let warmCoral = Color("WarmCoral")
    static let lavender = Color("Lavender")
    static let creamBackground = Color("CreamBackground")
    static let cardBackground = Color("CardBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    static func entryColor(for type: EntryType) -> Color {
        Color(type.colorName)
    }

    static var warmGradient: LinearGradient {
        LinearGradient(
            colors: [primaryPink.opacity(0.15), softPeach.opacity(0.3), lavender.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CareMomCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(CareMomTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CareMomTheme.cardCornerRadius, style: .continuous))
            .shadow(color: CareMomTheme.primaryPink.opacity(0.08), radius: 12, y: 4)
    }
}

extension View {
    func careMomCard() -> some View {
        modifier(CareMomCard())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: CareMomTheme.minTapTarget)
            .background(
                RoundedRectangle(cornerRadius: CareMomTheme.cardCornerRadius, style: .continuous)
                    .fill(CareMomTheme.warmCoral)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(CareMomTheme.warmCoral)
            .frame(maxWidth: .infinity)
            .frame(minHeight: CareMomTheme.minTapTarget)
            .background(
                RoundedRectangle(cornerRadius: CareMomTheme.cardCornerRadius, style: .continuous)
                    .stroke(CareMomTheme.warmCoral, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
