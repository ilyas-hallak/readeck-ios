//
//  WebViewCoordinatorTests.swift
//  readeckTests
//

import Testing
import Foundation
@testable import readeck

@MainActor
@Suite("Legacy reader web view coordinator")
struct WebViewCoordinatorTests {

    // WebKit only calls the link policy when the method really satisfies the delegate
    // requirement. A signature that merely looks alike is skipped without any error.
    @Test("The coordinator answers the navigation policy callback")
    func answersNavigationPolicyCallback() {
        let selector = NSSelectorFromString("webView:decidePolicyForNavigationAction:decisionHandler:")
        #expect(WebViewCoordinator().responds(to: selector))
    }
}
