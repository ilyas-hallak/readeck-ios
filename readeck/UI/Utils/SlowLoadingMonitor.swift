//
//  SlowLoadingMonitor.swift
//  readeck
//

import Foundation

/// Flags a loading state that runs longer than the threshold, so the UI can offer
/// a way out when the network is connected but nothing comes back.
@MainActor
@Observable
final class SlowLoadingMonitor {
    private(set) var isSlow = false
    private let threshold: Duration
    private var timer: Task<Void, Never>?

    init(threshold: Duration = .seconds(10)) {
        self.threshold = threshold
    }

    func update(isLoading: Bool) {
        timer?.cancel()
        timer = nil
        isSlow = false
        guard isLoading else { return }

        timer = Task { [weak self, threshold] in
            try? await Task.sleep(for: threshold)
            guard !Task.isCancelled else { return }
            self?.isSlow = true
        }
    }
}
