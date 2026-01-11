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
    
    @State private var newHeaderKey: String = ""
    @State private var newHeaderValue: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingHeadersSection.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showingHeadersSection ? 90 : 0))
                    Text("Custom HTTP Headers")
                        .font(.body)
                    Spacer()
                    if !customHeaders.isEmpty {
                        Text("\(customHeaders.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            
            if showingHeadersSection {
                // Helper text
                Text("Configure custom HTTP headers for proxy authentication.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    // Existing headers list
                    if !customHeaders.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(customHeaders.keys.sorted()), id: \.self) { key in
                                if editingHeaderKey == key {
                                    // Edit mode - use unified component
                                    InlineHeaderFormView(
                                        headerKey: $editingHeaderKeyValue,
                                        headerValue: $editingHeaderValue,
                                        onCancel: {
                                            onCancelEditingHeader()
                                        },
                                        onAdd: {
                                            // Handle save: check if key changed
                                            let originalKey = key
                                            let newKey = editingHeaderKeyValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                            
                                            onFinishEditingHeader(originalKey, newKey, editingHeaderValue)
                                        },
                                        mode: .edit(originalKey: key)
                                    )
                                } else {
                                    // Display mode
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(key)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text(customHeaders[key] ?? "")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        Button(action: {
                                            onStartEditingHeader(key)
                                        }) {
                                            Image(systemName: "pencil")
                                                .font(.caption)
                                                .foregroundColor(.accentColor)
                                        }
                                        .buttonStyle(.plain)
                                        Button(action: {
                                            onRemoveHeader(key)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
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
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
    }
}
