import LocalAuthentication
import SwiftUI

@MainActor
@Observable
final class AppLockManager {
    var isUnlocked: Bool

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "appLockEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "appLockEnabled") }
    }

    init() {
        // Если блокировка выключена — сразу разблокировано
        isUnlocked = !UserDefaults.standard.bool(forKey: "appLockEnabled")
    }

    func authenticate() async {
        guard isEnabled else {
            isUnlocked = true
            return
        }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
                || context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // Нет Face ID / код-пароля — не блокируем приложение
            isUnlocked = true
            return
        }
        let reason = L10n.t("lock.reason")
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            isUnlocked = success
        } catch {
            isUnlocked = false
        }
    }

    func lock() {
        guard isEnabled else { return }
        isUnlocked = false
    }

    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "appLockEnabled")
        if enabled {
            isUnlocked = false
            Task { await authenticate() }
        } else {
            isUnlocked = true
        }
    }
}

struct AppLockView: View {
    @Bindable var lockManager: AppLockManager

    var body: some View {
        ZStack {
            CareMomTheme.creamBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(CareMomTheme.warmCoral)
                Text("CareMom")
                    .font(.title2.weight(.bold))
                Text(L10n.t("lock.verify_identity"))
                    .foregroundStyle(CareMomTheme.textSecondary)
                Button(L10n.t("lock.unlock")) {
                    Task { await lockManager.authenticate() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
            }
        }
    }
}
