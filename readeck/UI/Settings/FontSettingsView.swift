//
//  FontSettingsView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct FontSettingsView: View {
    @State private var viewModel: FontSettingsViewModel

    init(viewModel: FontSettingsViewModel = FontSettingsViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            Section {
                Picker("Font family", selection: $viewModel.selectedFontFamily) {
                    ForEach(FontFamily.allCases, id: \.self) { family in
                        Text(family.displayName).tag(family)
                    }
                }
                .onChange(of: viewModel.selectedFontFamily) {
                    Task {
                        await viewModel.saveFontSettings()
                    }
                }

                Picker("Font size", selection: $viewModel.selectedFontSize) {
                    ForEach(FontSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.selectedFontSize) {
                    Task {
                        await viewModel.saveFontSettings()
                    }
                }
            } header: {
                Text("Font Settings")
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("readeck Bookmark Title")
                        .font(viewModel.previewTitleFont)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("This is how your bookmark descriptions and article text will appear in the app. The quick brown fox jumps over the lazy dog.")
                        .font(viewModel.previewBodyFont)
                        .lineLimit(3)

                    Text("12 min • Today • example.com")
                        .font(viewModel.previewCaptionFont)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Preview")
            }
        }
        .task {
            await viewModel.loadFontSettings()
        }
    }
}

#Preview {
    List {
        FontSettingsView(viewModel: .init(
            factory: MockUseCaseFactory())
        )
    }
    .listStyle(.insetGrouped)
}
