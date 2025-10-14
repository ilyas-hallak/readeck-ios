import SwiftUI

struct ReleaseNotesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let markdownContent = loadReleaseNotes() {
                        Text(.init(markdownContent))
                            .font(.body)
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
              let content = try? String(contentsOf: url) else {
            return nil
        }
        return content
    }
}

#Preview {
    ReleaseNotesView()
}
