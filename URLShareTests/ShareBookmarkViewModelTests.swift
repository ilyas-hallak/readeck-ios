//
//  ShareBookmarkViewModelTests.swift
//  URLShareTests
//
//  Created by Ilyas Hallak
//

import Testing
import Foundation

@MainActor
private final class MockRequestCompleter: ExtensionRequestCompleting {
    // swiftlint:disable:next discouraged_optional_collection
    private(set) var completedItems: [Any]?
    private(set) var cancelledError: Error?

    // swiftlint:disable:next discouraged_optional_collection
    func completeRequest(returningItems items: [Any]?, completionHandler: (@Sendable (Bool) -> Void)?) {
        completedItems = items
        completionHandler?(true)
    }

    func cancelRequest(withError error: Error) {
        cancelledError = error
    }
}

@Suite("ShareBookmarkViewModel Tests")
@MainActor
struct ShareBookmarkViewModelTests {
    @Test("cancel() tells the extension context the user cancelled, with a userCancelled error")
    func cancelReportsUserCancelled() {
        let completer = MockRequestCompleter()
        let viewModel = ShareBookmarkViewModel(extensionContext: nil, requestCompleter: completer)

        viewModel.cancel()

        let cocoaError = try? #require(completer.cancelledError as? CocoaError)
        #expect(cocoaError?.code == .userCancelled)
        #expect(completer.completedItems == nil)
    }

    @Test("cancel() without an extension context does not crash")
    func cancelWithoutRequestCompleter() {
        let viewModel = ShareBookmarkViewModel(extensionContext: nil)

        viewModel.cancel()
    }
}
