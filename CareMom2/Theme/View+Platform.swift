import SwiftUI

enum AppPlatform {
    /// Minimum supported iOS version for CareMom.
    static let minimumOSVersion = OperatingSystemVersion(majorVersion: 18, minorVersion: 0, patchVersion: 0)

    static var isAtLeastMinimum: Bool {
        ProcessInfo.processInfo.isOperatingSystemAtLeast(minimumOSVersion)
    }
}

extension View {
    /// Pulse animation for recording indicator; no-op on unsupported platforms.
    @ViewBuilder
    func careMomPulseSymbol(isActive: Bool) -> some View {
        modifier(PulseSymbolModifier(isActive: isActive))
    }

    /// Sheet background color compatible with iOS 18+.
    @ViewBuilder
    func careMomSheetBackground(_ color: Color) -> some View {
        presentationBackground(color)
    }
}

private struct PulseSymbolModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content.symbolEffect(.pulse, isActive: isActive)
    }
}
