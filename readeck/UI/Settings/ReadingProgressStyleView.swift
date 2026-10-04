import SwiftUI

/// Lets the user pick how the reader shows the progress, with a small animated preview per style.
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
            ForEach(styles) { style in
                Button {
                    select(style)
                } label: {
                    row(for: style)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.insetGrouped)
        .oledScrollBackground(appSettings.theme.isOLED)
        .navigationTitle("Progress Style")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(for style: ReadingProgressStyle) -> some View {
        let isSelected = viewModel.readingProgressStyle == style
        return VStack(alignment: .leading, spacing: 12) {
            ReadingProgressStylePreview(style: style)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 12))

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.localizedTitle)
                        .font(.headline)
                    Text(style.localizedDescription)
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

    private func select(_ style: ReadingProgressStyle) {
        guard viewModel.readingProgressStyle != style else { return }
        viewModel.readingProgressStyle = style
        Task { await viewModel.saveReadingProgressStyle() }
    }
}
