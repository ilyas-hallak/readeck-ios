import SwiftUI

struct LegalPrivacySettingsView: View {
    // Single source of truth for the presented sheet. Using one `.sheet(item:)`
    // instead of several `.sheet(isPresented:)` on the same view avoids a
    // SwiftUI bug where all but the last sheet dismiss immediately on first tap.
    private enum ActiveSheet: Identifiable {
        case releaseNotes, privacy, legalNotice, licenses, contributors

        var id: Int { hashValue }
    }

    @State private var activeSheet: ActiveSheet?

    var body: some View {
        Group {
            Section {
                Button(action: {
                    activeSheet = .releaseNotes
                }) {
                    HStack {
                        Text("What's New")
                        Spacer()
                        Text("Version \(VersionManager.shared.currentVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    activeSheet = .privacy
                }) {
                    HStack {
                        Text(NSLocalizedString("Privacy Policy", comment: ""))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    activeSheet = .legalNotice
                }) {
                    HStack {
                        Text(NSLocalizedString("Legal Notice", comment: ""))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    activeSheet = .licenses
                }) {
                    HStack {
                        Text("Open Source Licenses")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    activeSheet = .contributors
                }) {
                    HStack {
                        Text("Hall of Fame")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    if let url = URL(string: "https://github.com/ilyas-hallak/readeck-ios/issues") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text(NSLocalizedString("Report an Issue", comment: ""))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button(action: {
                    if let url = URL(string: "mailto:hi@ilyashallak.de?subject=readeck%20iOS") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text(NSLocalizedString("Contact Support", comment: ""))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Legal, Privacy & Support")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .releaseNotes:
                ReleaseNotesView()
            case .privacy:
                PrivacyPolicyView()
            case .legalNotice:
                LegalNoticeView()
            case .licenses:
                OpenSourceLicensesView()
            case .contributors:
                ContributorsView()
            }
        }
    }
}

#Preview {
    List {
        LegalPrivacySettingsView()
    }
    .listStyle(.insetGrouped)
}
