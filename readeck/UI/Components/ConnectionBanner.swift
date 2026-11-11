//
//  ConnectionBanner.swift
//  readeck
//

import SwiftUI

/// Slim bar at the top of the list, styled consistently whether or not it offers an action.
struct ConnectionBanner: View {
    let systemImage: String
    let message: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundColor(.secondary)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 44)
        .background(Color(.systemGray6))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
}

#Preview {
    VStack(spacing: 0) {
        ConnectionBanner(
            systemImage: "wifi.exclamationmark",
            message: "Your connection seems very slow or offline.",
            actionTitle: "Go Offline"
        ) {}
        ConnectionBanner(systemImage: "wifi", message: "You're back online.", actionTitle: "Go Online") {}
        ConnectionBanner(systemImage: "wifi.slash", message: "Offline mode, showing cached articles.")
        Spacer()
    }
}
