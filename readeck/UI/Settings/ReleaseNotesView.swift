import SwiftUI

struct ReleaseNotesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let markdownContent = loadReleaseNotes() {
                        MarkdownContentView(content: markdownContent)
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

    private func loadReleaseNotes() -> String? {
        guard let url = Bundle.main.url(forResource: "RELEASE_NOTES", withExtension: "md"),
              let markdownContent = try? String(contentsOf: url) else {
            return nil
        }
        return markdownContent
    }
}

#Preview {
    ReleaseNotesView()
}
