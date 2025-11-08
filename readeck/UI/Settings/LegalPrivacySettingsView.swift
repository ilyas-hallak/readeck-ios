import SwiftUI

struct LegalPrivacySettingsView: View {
    @State private var showingPrivacyPolicy = false
    @State private var showingLegalNotice = false
    @State private var showReleaseNotes = false

    var body: some View {
        Group {
            Section {
                Button(action: {
                    showReleaseNotes = true
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
                    showingPrivacyPolicy = true
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
                    showingLegalNotice = true
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
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingLegalNotice) {
            LegalNoticeView()
        }
        .sheet(isPresented: $showReleaseNotes) {
            ReleaseNotesView()
        }
    }
}

#Preview {
    List {
        LegalPrivacySettingsView()
    }
    .listStyle(.insetGrouped)
}
