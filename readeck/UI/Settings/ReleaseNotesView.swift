import SwiftUI

struct ReleaseNotesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let attributedString = loadReleaseNotes() {
                        Text(attributedString)
                            .textSelection(.enabled)
                            .padding()
                    } else {
                        Text("Unable to load release notes")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func loadReleaseNotes() -> AttributedString? {
        guard let url = Bundle.main.url(forResource: "RELEASE_NOTES", withExtension: "md"),
              let markdownContent = try? String(contentsOf: url),
              let attributedString = try? AttributedString(
                markdown: markdownContent,
                options: .init(interpretedSyntax: .full)
              ) else {
            return nil
        }
        return attributedString
    }
}

#Preview {
    ReleaseNotesView()
}
