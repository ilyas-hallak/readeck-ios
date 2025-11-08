//
//  FontSelectionView.swift
//  readeck
//
//  Created by Ilyas Hallak on 08.11.25.
//

import SwiftUI

struct FontSelectionView: View {
    @State private var viewModel: FontSettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: FontSettingsViewModel = FontSettingsViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            // Preview Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("readeck Bookmark Title")
                        .font(viewModel.previewTitleFont)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text("This is how your bookmark descriptions and article text will appear in the app. The quick brown fox jumps over the lazy dog. Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                        .font(viewModel.previewBodyFont)
                        .lineLimit(4)

                    Text("12 min • Today • example.com")
                        .font(viewModel.previewCaptionFont)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
            } header: {
                Text("Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .textCase(nil)
            }

            // Font Settings Section
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Font size")
                        .font(.subheadline)
                        .foregroundColor(.primary)

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
                }
                .padding(.vertical, 4)
            } header: {
                Text("Font Settings")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Font")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFontSettings()
        }
    }
}

#Preview {
    NavigationStack {
        FontSelectionView(viewModel: .init(
            factory: MockUseCaseFactory()
        ))
    }
}
