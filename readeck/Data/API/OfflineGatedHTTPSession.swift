//
//  OfflineGatedHTTPSession.swift
//  readeck
//

import Foundation
import Combine

/// Fails requests at once while the user works offline, and cancels the requests
/// that are still waiting when offline mode starts. Callers then see the same
/// `URLError` as on a real offline device, so the existing offline paths apply.
final class OfflineGatedHTTPSession: HTTPSession {
    private let base: HTTPSession
    private let lock = NSLock()
    private var isForcedOffline = false
    private var inFlight: [UUID: Task<(Data, URLResponse), Error>] = [:]
    private var cancellable: AnyCancellable?

    init(base: HTTPSession, isForcedOffline: AnyPublisher<Bool, Never>) {
        self.base = base
        cancellable = isForcedOffline.sink { [weak self] isForced in
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
            if lock.withLock({ isForcedOffline }) { throw URLError(.notConnectedToInternet) }
            throw error
        }
    }

    private func startTask(for request: URLRequest, id: UUID) -> Task<(Data, URLResponse), Error>? {
        lock.withLock {
            guard !isForcedOffline else { return nil }
            let task = Task { [base] in try await base.data(for: request) }
            inFlight[id] = task
            return task
        }
    }

    private func unregister(id: UUID) {
        lock.withLock { _ = inFlight.removeValue(forKey: id) }
    }

    private func update(isForcedOffline isForced: Bool) {
        let waiting = lock.withLock {
            isForcedOffline = isForced
            return isForced ? Array(inFlight.values) : []
        }
        waiting.forEach { $0.cancel() }
    }
}
