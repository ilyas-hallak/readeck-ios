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
        VStack(spacing: 0) {
            // Pinned preview at top
            readerPreview
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))

            Divider()

            // Scrollable settings below
            List {
                fontSection
                readerLayoutSection
                visibilitySection
                customCSSSection
            }
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Reader Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadFontSettings()
        }
    }

    // MARK: - Preview

    private var readerPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Simulated article preview with actual settings applied
            VStack(alignment: .leading, spacing: 0) {
                Text("The Future of Reading Apps")
                    .font(viewModel.previewTitleFont)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .padding(.bottom, 4)

                HStack(spacing: 4) {
                    Image(systemName: "person")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Jane Doe · Mar 21, 2026")
                        .font(viewModel.previewCaptionFont)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)

                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.")
                    .font(viewModel.previewBodyFont)
                    .lineSpacing(viewModel.previewLineSpacing)
                    .lineLimit(5)
            }
            .padding(.horizontal, viewModel.horizontalMargin)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    // MARK: - Font Section

    private var fontSection: some View {
        Section {
            Picker("Font family", selection: $viewModel.selectedFontFamily) {
                ForEach(FontFamily.allCases, id: \.self) { family in
                    Text(family.displayName).tag(family)
                }
            }
            .onChange(of: viewModel.selectedFontFamily) {
                Task { await viewModel.saveFontSettings() }
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
                        Task { await viewModel.saveFontSettings() }
                    }
            }
        } header: {
            Text("Font")
        }
    }

    // MARK: - Reader Layout Section

    private var readerLayoutSection: some View {
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
                        Task { await viewModel.saveReaderLayout() }
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
                        Task { await viewModel.saveReaderLayout() }
                    }
            }
        } header: {
            Text("Reader Layout")
        }
    }

    // MARK: - Visibility Section

    private var visibilitySection: some View {
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
    }

    // MARK: - Custom CSS Section

    private var customCSSSection: some View {
        Section {
            TextEditor(text: $viewModel.customCSS)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 100)
                .onChange(of: viewModel.customCSS) {
                    Task { await viewModel.saveCustomCSS() }
                }
            Text("Custom CSS rules appended after all default styles. Use at your own risk.")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("Custom CSS")
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
