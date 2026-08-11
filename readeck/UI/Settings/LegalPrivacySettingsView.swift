import SwiftUI

/// Which modal is presented from the legal/about section.
///
/// Presentation is driven from a single `.sheet(item:)` attached to the
/// top-level `List` in `SettingsContainerView` (a stable ancestor). Attaching
/// the sheet here — inside a `List` section — makes the first presentation get
/// cancelled because the section view is rebuilt as the sheet appears (the
/// sheet opened and closed immediately, only working on the second tap).
enum SettingsSheet: Identifiable {
    case releaseNotes, privacy, legalNotice, licenses, contributors

    var id: Int { hashValue }
}

struct LegalPrivacySettingsView: View {
    @Binding var activeSheet: SettingsSheet?

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
    }
}

#Preview {
    List {
        LegalPrivacySettingsView(activeSheet: .constant(nil))
    }
    .listStyle(.insetGrouped)
}
