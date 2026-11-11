//
//  OfflineGatedHTTPSession.swift
//  readeck
//

import Foundation
import Combine
import Synchronization

/// Fails requests at once while the user works offline, and cancels the requests
/// that are still waiting when offline mode starts. Callers then see the same
/// `URLError` as on a real offline device, so the existing offline paths apply.
final class OfflineGatedHTTPSession: HTTPSession {
    private struct State {
        var isForcedOffline = false
        var inFlight: [UUID: Task<(Data, URLResponse), Error>] = [:]
    }

    private let base: HTTPSession
    private let state = Mutex(State())
    // Set once in init and only released with self.
    nonisolated(unsafe) private var subscription: AnyCancellable?

    init(base: HTTPSession, isForcedOffline: AnyPublisher<Bool, Never>) {
        self.base = base
        subscription = isForcedOffline.sink { [weak self] isForced in
            self?.update(isForcedOffline: isForced)
        }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let id = UUID()
        guard let task = startTask(for: request, id: id) else {
            throw URLError(.notConnectedToInternet)
        }
        defer { unregister(id: id) }

        do {
            return try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
        } catch {
            // A request cut off by going offline reads like any other offline failure.
            if state.withLock({ $0.isForcedOffline }) { throw URLError(.notConnectedToInternet) }
            throw error
        }
    }

    private func startTask(for request: URLRequest, id: UUID) -> Task<(Data, URLResponse), Error>? {
        state.withLock { state in
            guard !state.isForcedOffline else { return nil }
            let task = Task { [base] in try await base.data(for: request) }
            state.inFlight[id] = task
            return task
        }
    }

    private func unregister(id: UUID) {
        state.withLock { _ = $0.inFlight.removeValue(forKey: id) }
    }

    private func update(isForcedOffline isForced: Bool) {
        let waiting = state.withLock { state in
            state.isForcedOffline = isForced
            return isForced ? Array(state.inFlight.values) : []
        }
        waiting.forEach { $0.cancel() }
    }
}
