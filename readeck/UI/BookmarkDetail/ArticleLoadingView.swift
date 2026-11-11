//
//  ArticleLoadingView.swift
//  readeck
//

import SwiftUI

/// Article spinner that offers to go offline once loading takes too long.
struct ArticleLoadingView: View {
    let onGoOffline: () -> Void
    @Environment(AppSettings.self) private var appSettings
    @State private var slowLoading = SlowLoadingMonitor()

    var body: some View {
        VStack(spacing: 20) {
            ProgressView("Loading article...")
            if slowLoading.isSlow && appSettings.isNetworkConnected {
                SlowConnectionHint(action: onGoOffline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .onAppear { slowLoading.update(isLoading: true) }
        .onDisappear { slowLoading.update(isLoading: false) }
    }
}

/// Hint shown below a spinner that has been running for a while.
private struct SlowConnectionHint: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Your connection seems very slow or offline.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Go Offline", action: action)
                .font(.footnote.weight(.semibold))
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
        }
        .padding(.horizontal, 40)
    }
}

/// Shown above the "open original" button when an uncached article can't load offline.
struct OfflineArticleNote: View {
    var body: some View {
        Text("This article isn't available offline.")
            .font(.footnote)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }
}
