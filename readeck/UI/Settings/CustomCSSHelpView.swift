//
//  CustomCSSHelpView.swift
//  readeck
//

import SwiftUI

struct CustomCSSHelpView: View {
    @Binding var customCSS: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(CSSSnippetCategory.allCases, id: \.self) { category in
                    Section {
                        ForEach(CSSSnippet.snippets(for: category)) { snippet in
                            snippetCard(snippet)
                        }
                    } header: {
                        Label(category.titleKey.localized, systemImage: category.iconName)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("css.help.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func snippetCard(_ snippet: CSSSnippet) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(snippet.titleKey.localized)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(snippet.descriptionKey.localized)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(snippet.code)
                .font(.system(.caption, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(6)

            HStack(spacing: 12) {
                Button {
                    if customCSS.isEmpty {
                        customCSS = snippet.code
                    } else {
                        customCSS += "\n" + snippet.code
                    }
                } label: {
                    Label("css.help.button.append".localized, systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)

                Button {
                    customCSS = snippet.code
                } label: {
                    Label("css.help.button.replace".localized, systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}
