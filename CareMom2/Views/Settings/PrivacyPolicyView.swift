import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(L10n.t("privacy.title"))
                    .font(.title2.weight(.bold))

                Group {
                    section(L10n.t("privacy.data_title"), L10n.t("privacy.data_body"))
                    section(L10n.t("privacy.storage_title"), L10n.t("privacy.storage_body"))
                    section(L10n.t("privacy.permissions_title"), L10n.t("privacy.permissions_body"))
                    section(L10n.t("privacy.backup_title"), L10n.t("privacy.backup_body"))
                    section(L10n.t("privacy.tracking_title"), L10n.t("privacy.tracking_body"))
                }

                Text(L10n.t("privacy.contact"))
                    .font(.subheadline)
                    .foregroundStyle(CareMomTheme.textSecondary)
            }
            .padding()
        }
        .background(CareMomTheme.creamBackground)
        .navigationTitle(L10n.t("settings.privacy_policy"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.body)
                .foregroundStyle(CareMomTheme.textSecondary)
        }
    }
}
