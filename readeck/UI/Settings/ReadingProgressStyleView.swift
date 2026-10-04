import SwiftUI

/// Lets the user pick how the reader shows the progress, or turn it off, with a small
/// animated preview per option.
@available(iOS 26.0, *)
struct ReadingProgressStyleView: View {
    @Bindable var viewModel: FontSettingsViewModel
    @Environment(AppSettings.self) private var appSettings

    private var styles: [ReadingProgressStyle] {
        let hasIsland = IslandProgressRing.isAvailableOnDevice
        return ReadingProgressStyle.allCases.filter { hasIsland || !$0.requiresDynamicIsland }
    }

    var body: some View {
        List {
            option(
                style: nil,
                title: "Off".localized,
                description: "No progress is shown while you read.".localized
            )
            ForEach(styles) { style in
                option(style: style, title: style.localizedTitle, description: style.localizedDescription)
            }
        }
        .listStyle(.insetGrouped)
        .oledScrollBackground(appSettings.theme.isOLED)
        .navigationTitle("Progress Style")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isSelected(_ style: ReadingProgressStyle?) -> Bool {
        guard let style else { return viewModel.hideProgressBar }
        return !viewModel.hideProgressBar && viewModel.readingProgressStyle == style
    }

    private func option(style: ReadingProgressStyle?, title: String, description: String) -> some View {
        Button {
            guard !isSelected(style) else { return }
            Task { await viewModel.saveProgressDisplay(style) }
        } label: {
            row(style: style, title: title, description: description)
        }
        .buttonStyle(.plain)
    }

    private func row(style: ReadingProgressStyle?, title: String, description: String) -> some View {
        let isSelected = isSelected(style)
        return VStack(alignment: .leading, spacing: 12) {
            ReadingProgressStylePreview(style: style)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 12))

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
            }
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
    }
}
