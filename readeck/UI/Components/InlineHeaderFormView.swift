//
//  InlineHeaderFormView.swift
//  readeck
//
//  Created for inline HTTP header form component
//

import SwiftUI

enum HeaderFormMode {
    case add
    case edit(originalKey: String)
}

// Inline header form component
struct InlineHeaderFormView: View {
    @Binding var headerKey: String
    @Binding var headerValue: String
    let onCancel: () -> Void
    let onAdd: () -> Void
    let mode: HeaderFormMode

    private var trimmedKey: String {
        headerKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmedKey.isEmpty && HTTPHeadersHelper.isHeaderNameAllowed(trimmedKey)
    }

    private var isEditMode: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }

    private var buttonLabel: String {
        isEditMode ? "Save" : "Add"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Header Name", text: $headerKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Header Value", text: $headerValue, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .lineLimit(2...4)

            if !trimmedKey.isEmpty && !HTTPHeadersHelper.isHeaderNameAllowed(trimmedKey) {
                Text("\(trimmedKey) cannot be customized.")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundColor(.secondary)

                Spacer()

                Button(buttonLabel, action: onAdd)
                    .foregroundColor(.accentColor)
                    .disabled(!isValid)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
}
