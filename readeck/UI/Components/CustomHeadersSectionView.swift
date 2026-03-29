//
//  CustomHeadersSectionView.swift
//  readeck
//
//  Created for custom HTTP headers section component
//

import SwiftUI

struct CustomHeadersSectionView: View {
    @Binding var customHeaders: [String: String]
    @Binding var showingHeadersSection: Bool
    @Binding var editingHeaderKey: String?
    @Binding var editingHeaderKeyValue: String
    @Binding var editingHeaderValue: String
    let onAddHeader: (String, String) -> Void
    let onUpdateHeader: (String, String) -> Void
    let onRemoveHeader: (String) -> Void
    let onStartEditingHeader: (String) -> Void
    let onCancelEditingHeader: () -> Void
    let onFinishEditingHeader: (String, String, String) -> Void

    @State private var newHeaderKey = ""
    @State private var newHeaderValue = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Schlichterer Disclosure-Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showingHeadersSection.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: showingHeadersSection ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Custom HTTP Headers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if !customHeaders.isEmpty {
                        Text("(\(customHeaders.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if showingHeadersSection {
                VStack(alignment: .leading, spacing: 10) {
                    // Schlichterer Helper-Text
                    Text("For proxy authentication or special server configurations.")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                        .padding(.bottom, 4)

                    // Existing headers list - schlichter dargestellt
                    if !customHeaders.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(customHeaders.keys.sorted()), id: \.self) { key in
                                if editingHeaderKey == key {
                                    // Edit mode
                                    InlineHeaderFormView(
                                        headerKey: $editingHeaderKeyValue,
                                        headerValue: $editingHeaderValue,
                                        onCancel: {
                                            onCancelEditingHeader()
                                        },
                                        onAdd: {
                                            let originalKey = key
                                            let newKey = editingHeaderKeyValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                            onFinishEditingHeader(originalKey, newKey, editingHeaderValue)
                                        },
                                        mode: .edit(originalKey: key)
                                    )
                                } else {
                                    // Display mode - schlichter
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(key)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                            Text(customHeaders[key] ?? "")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        // Schlichtere Buttons
                                        Button(action: {
                                            onStartEditingHeader(key)
                                        }) {
                                            Image(systemName: "pencil")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                        Button(action: {
                                            onRemoveHeader(key)
                                        }) {
                                            Image(systemName: "minus.circle")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(Color(.systemGray6).opacity(0.5))
                                    .cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Add new header - nur wenn nicht im Edit-Modus
                    if editingHeaderKey == nil {
                        InlineHeaderFormView(
                            headerKey: $newHeaderKey,
                            headerValue: $newHeaderValue,
                            onCancel: {
                                newHeaderKey = ""
                                newHeaderValue = ""
                            },
                            onAdd: {
                                onAddHeader(newHeaderKey, newHeaderValue)
                                newHeaderKey = ""
                                newHeaderValue = ""
                            },
                            mode: .add
                        )
                    }
                }
                .padding(.leading, 4)
            }
        }
        .padding(.top, 4)
    }
}
