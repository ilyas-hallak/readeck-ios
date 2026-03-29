//
//  FontSettingsView.swift
//  readeck
//
//  Created by Ilyas Hallak on 29.06.25.
//

import SwiftUI

struct FontSettingsView: View {
    @State private var viewModel: FontSettingsViewModel
    @State private var showCSSHelp = false

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

                Text("font.web.match.hint".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading) {
                    HStack {
                        Text("Font size")
                        Spacer()
                        Text("\(Int(viewModel.fontSizeNumeric))px")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $viewModel.fontSizeNumeric, in: 10...30, step: 1)
                        .onChange(of: viewModel.fontSizeNumeric) {
                            Task {
                                await viewModel.saveFontSettings()
                            }
                        }
                }
            } header: {
                Text("Font Settings")
            }

            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Horizontal margin")
                        Spacer()
                        Text("\(Int(viewModel.horizontalMargin))px")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $viewModel.horizontalMargin, in: 0...40, step: 1)
                        .onChange(of: viewModel.horizontalMargin) {
                            Task {
                                await viewModel.saveReaderLayout()
                            }
                        }
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text("Line height")
                        Spacer()
                        Text(String(format: "%.1f", viewModel.lineHeight))
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $viewModel.lineHeight, in: 1.0...2.5, step: 0.1)
                        .onChange(of: viewModel.lineHeight) {
                            Task {
                                await viewModel.saveReaderLayout()
                            }
                        }
                }
            } header: {
                Text("Reader Layout")
            }

            Section {
                Toggle("Hide progress bar", isOn: $viewModel.hideProgressBar)
                    .onChange(of: viewModel.hideProgressBar) {
                        Task { await viewModel.saveVisibilitySettings() }
                    }
                Toggle("Hide word count & reading time", isOn: $viewModel.hideWordCount)
                    .onChange(of: viewModel.hideWordCount) {
                        Task { await viewModel.saveVisibilitySettings() }
                    }
                Toggle("Hide hero image", isOn: $viewModel.hideHeroImage)
                    .onChange(of: viewModel.hideHeroImage) {
                        Task { await viewModel.saveVisibilitySettings() }
                    }
            } header: {
                Text("Visibility")
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

            Section {
                TextEditor(text: $viewModel.customCSS)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 100)
                    .onChange(of: viewModel.customCSS) {
                        Task { await viewModel.saveCustomCSS() }
                    }
                Text("css.help.hint".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                HStack {
                    Text("Custom CSS")
                    Spacer()
                    Button {
                        showCSSHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showCSSHelp) {
                CustomCSSHelpView(customCSS: $viewModel.customCSS)
            }
        }
        .task {
            await viewModel.loadFontSettings()
        }
    }
}

#Preview {
    List {
        FontSettingsView(
            viewModel: .init(factory: MockUseCaseFactory())
        )
    }
    .listStyle(.insetGrouped)
}
