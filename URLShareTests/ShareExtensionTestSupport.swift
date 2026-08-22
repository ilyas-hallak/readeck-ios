//
//  ShareExtensionTestSupport.swift
//  URLShareTests
//
//  Created by Ilyas Hallak
//

import Foundation
import CoreData

/// HTTPSession-Mock für die Share-Extension-Tests.
/// Eigene Kopie, weil `readeckTests` ein anderes Modul ist.
final class MockHTTPSession: HTTPSession, @unchecked Sendable {
    enum Stub {
        case http(status: Int, data: Data, headers: [String: String] = [:])
        case failure(Error)
    }

    var stubs: [Stub]
    private(set) var requests: [URLRequest] = []
    private var index = 0

    init(_ stubs: [Stub]) {
        self.stubs = stubs
    }

    convenience init(_ stub: Stub) {
        self.init([stub])
    }

    var lastRequest: URLRequest? { requests.last }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)

        guard let stub = index < stubs.count ? stubs[index] : stubs.last else {
            throw URLError(.unsupportedURL)
        }
        index += 1

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
    /// Ein gemeinsames Modell für alle Stores: mehrere `mergedModel`-Instanzen
    /// beanspruchen sonst dieselbe NSManagedObject-Subklasse und CoreData
    /// kann `+entity` nicht mehr auflösen.
    ///
    /// Das Modell wird aus dem Test-Bundle geladen, nicht aus `Bundle.main`:
    /// URLShareTests läuft ohne Host-App, `Bundle.main` ist dort das xctest-Tool.
    static let model: NSManagedObjectModel = {
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
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

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
