//
//  ServerCapabilitiesTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 04.09.26.
//

import Foundation
import Testing
@testable import readeck

@Suite("Server Capabilities Tests")
struct ServerCapabilitiesTests {

    private func capabilities(
        _ versionString: String,
        features: [String]? = nil,
        hasOAuthMetadata: Bool = false
    ) -> ServerCapabilities {
        ServerCapabilities(versionString: versionString, features: features, hasOAuthMetadata: hasOAuthMetadata)
    }

    // MARK: - Password Login (< 0.22.0)

    @Test("Password login is available below 0.22.0", arguments: ["0.20.2", "0.21.9"])
    func passwordLogin_BelowBoundary(version: String) {
        #expect(capabilities(version).canUsePasswordLogin)
    }

    @Test("Password login is gone from 0.22.0 on", arguments: ["0.22.0", "0.22.1", "0.23.2"])
    func passwordLogin_AtAndAboveBoundary(version: String) {
        #expect(!capabilities(version).canUsePasswordLogin, "/api/auth was removed in 0.22.0")
    }

    // MARK: - OAuth

    @Test("OAuth needs reachable authorization server metadata")
    func oauth_RequiresMetadata() {
        #expect(capabilities("0.23.2", hasOAuthMetadata: true).canUseOAuth)
        #expect(!capabilities("0.23.2", hasOAuthMetadata: false).canUseOAuth)
    }

    @Test("OAuth is not derived from the features array")
    func oauth_IgnoresFeaturesArray() {
        // "oauth" is hardcoded in the server from 0.21.0 on and says nothing
        // about actual availability.
        #expect(!capabilities("0.23.2", features: ["oauth"]).canUseOAuth)
    }

    // MARK: - HTML Bookmark Upload (>= 0.22.0)

    @Test("HTML upload boundary", arguments: [
        ("0.21.9", false),
        ("0.22.0", true),
        ("0.22.1", true)
    ])
    func htmlBookmarkUpload_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).supportsHTMLBookmarkUpload == expected)
    }

    // MARK: - Sync API (>= 0.22.0)

    @Test("Sync API boundary", arguments: [
        ("0.21.9", false),
        ("0.22.0", true),
        ("0.22.1", true)
    ])
    func syncAPI_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).supportsSyncAPI == expected)
    }

    // MARK: - Conditional Requests (>= 0.20.0)

    @Test("Conditional requests boundary", arguments: [
        ("0.19.9", false),
        ("0.20.0", true),
        ("0.20.1", true)
    ])
    func conditionalRequests_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).supportsConditionalRequests == expected)
    }

    // MARK: - Labels ?name= Query (>= 0.20.0)

    @Test("Labels name query boundary", arguments: [
        ("0.19.9", false),
        ("0.20.0", true),
        ("0.20.1", true)
    ])
    func labelsNameQuery_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).supportsLabelsNameQuery == expected)
    }

    // MARK: - Annotation PATCH (>= 0.17.0)

    @Test("Annotation patch boundary", arguments: [
        ("0.16.9", false),
        ("0.17.0", true),
        ("0.17.1", true)
    ])
    func annotationPatch_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).supportsAnnotationPatch == expected)
    }

    // MARK: - Annotation Notes (>= 0.22.0)

    @Test("Annotation notes boundary", arguments: [
        ("0.21.9", false),
        ("0.22.0", true),
        ("0.22.1", true)
    ])
    func annotationNotes_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).supportsAnnotationNotes == expected)
    }

    // MARK: - Bookmark Notes (>= 0.23.0)

    @Test("Bookmark notes boundary", arguments: [
        ("0.22.9", false),
        ("0.23.0", true),
        ("0.23.1", true)
    ])
    func bookmarkNotes_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).supportsBookmarkNotes == expected)
    }

    // MARK: - has_notes Filter (>= 0.23.0)

    @Test("Notes filter boundary", arguments: [
        ("0.22.9", false),
        ("0.23.0", true),
        ("0.23.1", true)
    ])
    func notesFilter_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).supportsNotesFilter == expected)
    }

    // MARK: - Validation Errors (>= 0.21.4)

    @Test("Validation error boundary", arguments: [
        ("0.21.3", false),
        ("0.21.4", true),
        ("0.21.5", true)
    ])
    func validationErrors_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).supportsValidationErrors == expected)
    }

    // MARK: - Email Sharing (features)

    @Test("Email sharing comes from the features array")
    func emailSharing_FromFeatures() {
        #expect(capabilities("0.23.2", features: ["oauth", "email"]).supportsEmailSharing)
        #expect(!capabilities("0.23.2", features: ["oauth"]).supportsEmailSharing)
        #expect(!capabilities("0.23.2", features: []).supportsEmailSharing)
        #expect(!capabilities("0.23.2", features: nil).supportsEmailSharing)
    }

    @Test("Email sharing is not implied by the version")
    func emailSharing_NotVersionBased() {
        // An unauthenticated /api/info never reports "email", so a new server
        // without the feature entry must not claim mail support.
        #expect(!capabilities("0.23.2").supportsEmailSharing)
    }

    // MARK: - Known Broken Writes (0.20.0, 0.20.1)

    @Test("CSRF regression detection", arguments: [
        ("0.19.9", false),
        ("0.20.0", true),
        ("0.20.1", true),
        ("0.20.2", false),
        ("0.21.0", false)
    ])
    func knownBrokenForWrites(version: String, expected: Bool) {
        #expect(capabilities(version).isKnownBrokenForWrites == expected)
    }

    // MARK: - Support Floor (>= 0.20.2)

    @Test("Support floor boundary", arguments: [
        ("0.20.1", true),
        ("0.20.2", false),
        ("0.20.3", false),
        ("0.23.2", false)
    ])
    func supportFloor_Boundary(version: String, expected: Bool) {
        #expect(capabilities(version).isBelowSupportFloor == expected)
    }

    // MARK: - Unknown Version

    @Test("Unknown version disables every new capability")
    func unknownVersion_IsConservative() {
        let unknown = ServerCapabilities.unknown

        #expect(unknown.version == nil)
        #expect(!unknown.supportsHTMLBookmarkUpload)
        #expect(!unknown.supportsSyncAPI)
        #expect(!unknown.supportsConditionalRequests)
        #expect(!unknown.supportsLabelsNameQuery)
        #expect(!unknown.supportsAnnotationPatch)
        #expect(!unknown.supportsAnnotationNotes)
        #expect(!unknown.supportsBookmarkNotes)
        #expect(!unknown.supportsNotesFilter)
        #expect(!unknown.supportsValidationErrors)
        #expect(!unknown.supportsEmailSharing)
        #expect(!unknown.canUseOAuth)
    }

    @Test("Unknown version keeps password login and stays below the floor")
    func unknownVersion_PasswordLoginAndFloor() {
        let unknown = ServerCapabilities.unknown

        // Servers without /api/info are pre-0.20 and still have /api/auth.
        #expect(unknown.canUsePasswordLogin)
        #expect(unknown.isBelowSupportFloor)
        #expect(!unknown.isKnownBrokenForWrites, "Unknown is not the same as known broken")
    }

    @Test("Unparsable and missing version strings fall back to unknown", arguments: [nil, "", "latest", "0.x.2"] as [String?])
    func unknownVersion_FromBadStrings(versionString: String?) {
        let caps = ServerCapabilities(versionString: versionString)

        #expect(caps.version == nil)
        #expect(caps.isBelowSupportFloor)
        #expect(caps.canUsePasswordLogin)
        #expect(!caps.supportsHTMLBookmarkUpload)
    }

    // MARK: - Wiring

    @Test("ServerInfo exposes the capabilities of its reported version")
    func serverInfo_ExposesCapabilities() {
        let serverInfo = ServerInfo(version: "0.23.2", isReachable: true, features: ["oauth", "email"])

        #expect(serverInfo.capabilities.version == SemanticVersion(major: 0, minor: 23, patch: 2))
        #expect(serverInfo.capabilities.supportsBookmarkNotes)
        #expect(serverInfo.capabilities.supportsEmailSharing)
        #expect(serverInfo.supportsEmail)
        #expect(!serverInfo.capabilities.isBelowSupportFloor)
    }

    @Test("An unreachable server reports the unknown state")
    func serverInfo_UnreachableIsUnknown() {
        #expect(ServerInfo.unreachable.capabilities.version == nil)
        #expect(ServerInfo.unreachable.capabilities.isBelowSupportFloor)
        #expect(!ServerInfo.unreachable.supportsEmail)
    }

    @Test("A release candidate keeps the features of its release")
    func serverInfo_ReleaseCandidate() {
        // Regression guard: the old split based check dropped "2-rc1" and
        // reported no HTML support for a 0.23.2 candidate.
        let serverInfo = ServerInfo(version: "0.23.2-rc1", isReachable: true, features: nil)

        #expect(serverInfo.capabilities.supportsHTMLBookmarkUpload)
        #expect(serverInfo.capabilities.supportsBookmarkNotes)
    }
}
