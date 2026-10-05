import SwiftUI

/// Lists every font family set in its own typeface, so readers see the font before picking it.
struct FontFamilySelectionView: View {
    @Bindable var viewModel: FontSettingsViewModel
    var onSelect: () -> Void = {}
    @Environment(AppSettings.self) private var appSettings

    private static let groups: [(title: LocalizedStringKey, category: FontCategory)] = [
        ("Serif", .serif),
        ("Sans Serif", .sansSerif),
        ("Monospace", .monospace)
    ]

    var body: some View {
        List {
            ForEach(Self.groups, id: \.category) { group in
                Section {
                    ForEach(families(in: group.category), id: \.self) { family in
                        Button {
                            select(family)
                        } label: {
                            row(for: family)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(group.title)
                } footer: {
                    if group.category == Self.groups.last?.category {
                        Text("font.web.match.hint".localized)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .oledScrollBackground(appSettings.theme.isOLED)
        .navigationTitle("Font family")
        .navigationBarTitleDisplayMode(.inline)
    }

    // The legacy families only stay around for readers who still have one of them selected
    private func families(in category: FontCategory) -> [FontFamily] {
        FontFamily.allCases.filter { family in
            family.category == category && (!family.isLegacy || family == viewModel.selectedFontFamily)
        }
    }

    private func row(for family: FontFamily) -> some View {
        let isSelected = viewModel.selectedFontFamily == family
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(family.displayName)
                    .font(family.font(size: 20, bold: true))
                Text("font.sample".localized)
                    .font(family.font(size: 15))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }

    private func select(_ family: FontFamily) {
        guard viewModel.selectedFontFamily != family else { return }
        viewModel.selectedFontFamily = family
        onSelect()
        Task { await viewModel.saveFontSettings() }
    }
}
