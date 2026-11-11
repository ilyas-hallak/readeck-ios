import SwiftUI

/// Compact bottom sheet that lists the ways to share an article.
struct ArticleShareSheet: View {
    let options: [ArticleShareOption]
    let isEnabled: (ArticleShareOption) -> Bool
    let onSelect: (ArticleShareOption) -> Void

    @State private var contentHeight: Double = 320

    var body: some View {
        VStack(spacing: 16) {
            Text("Share".localized)
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(options) { option in
                    Button {
                        onSelect(option)
                    } label: {
                        ShareOptionRow(option: option)
                    }
                    .buttonStyle(ShareOptionButtonStyle())
                    .disabled(!isEnabled(option))

                    if option != options.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: Double.self) { proxy in
            // The sheet adds the bottom safe area to a height detent.
            proxy.size.height - proxy.safeAreaInsets.bottom
        } action: { height in
            contentHeight = height
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(contentHeight)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemGroupedBackground))
    }
}

private struct ShareOptionRow: View {
    let option: ArticleShareOption

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: option.systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(.tint)
                .frame(width: 24)

            Text(option.title)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct ShareOptionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? 1 : 0.4)
            .background(configuration.isPressed ? Color(.systemGray4) : .clear)
    }
}
