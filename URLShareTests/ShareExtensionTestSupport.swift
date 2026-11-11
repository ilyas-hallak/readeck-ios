//
//  ShareExtensionTestSupport.swift
//  URLShareTests
//
//  Created by Ilyas Hallak
//

import Foundation
import CoreData
import Synchronization

/// HTTPSession mock for the share extension tests.
/// A separate copy, because `readeckTests` is a different module.
final class MockHTTPSession: HTTPSession {
    enum Stub {
        case http(status: Int, data: Data, headers: [String: String] = [:])
        case failure(Error)
    }

    private struct State {
        let stubs: [Stub]
        var requests: [URLRequest] = []
        var index = 0
    }

    private let state: Mutex<State>

    init(_ stubs: [Stub]) {
        self.state = Mutex(State(stubs: stubs))
    }

    convenience init(_ stub: Stub) {
        self.init([stub])
    }

    var requests: [URLRequest] { state.withLock { $0.requests } }
    var lastRequest: URLRequest? { requests.last }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let stub = state.withLock { state -> Stub? in
            state.requests.append(request)
            let stub = state.index < state.stubs.count ? state.stubs[state.index] : state.stubs.last
            state.index += 1
            return stub
        }
        guard let stub else {
            throw URLError(.unsupportedURL)
        }

        switch stub {
        case let .http(status, data, headers):
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://mock.example.com")!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: headers
            )!
            return (data, response)
        case let .failure(error):
            throw error
        }
    }
}

extension MockHTTPSession.Stub {
    static func json(_ json: String, status: Int = 200, headers: [String: String] = [:]) -> MockHTTPSession.Stub {
        .http(status: status, data: Data(json.utf8), headers: headers)
    }
}

// MARK: - In-Memory CoreData

enum TestCoreData {
    /// One model shared by every store: several `mergedModel` instances would each
    /// claim the same NSManagedObject subclass, and CoreData could no longer resolve
    /// `+entity`.
    ///
    /// The model is loaded from the test bundle rather than `Bundle.main`:
    /// URLShareTests runs without a host app, where `Bundle.main` is the xctest tool.
    // Built once and only read afterwards.
    nonisolated(unsafe) static let model: NSManagedObjectModel = {
        let bundle = Bundle(for: MockHTTPSession.self)
        guard let model = NSManagedObjectModel.mergedModel(from: [bundle]) else {
            preconditionFailure("CoreData model not found in the URLShareTests bundle")
        }
        return model
    }()

    static func makeManager() -> CoreDataManager {
        let container = NSPersistentContainer(name: "readeck", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            precondition(error == nil, "In-memory store failed to load: \(String(describing: error))")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        return CoreDataManager(container: container)
    }
}

// MARK: - SimpleAPI Environment

extension SimpleAPIEnvironment {
    static func test(
        session: HTTPSession,
        token: String? = "test-token",
        endpoint: String? = "https://mock.example.com"
    ) -> SimpleAPIEnvironment {
        SimpleAPIEnvironment(
            session: session,
            loadToken: { token },
            loadEndpoint: { endpoint }
        )
    }
}
