//
//  ServerInfoTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 15.12.25.
//

import XCTest
@testable import readeck

final class ServerInfoTests: XCTestCase {

    // MARK: - OAuth Feature Detection

    func testSupportsOAuth_WithOAuthFeature_ReturnsTrue() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: ["oauth", "email"]
        )

        XCTAssertTrue(serverInfo.supportsOAuth)
    }

    func testSupportsOAuth_WithoutOAuthFeature_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: ["email"]
        )

        XCTAssertFalse(serverInfo.supportsOAuth)
    }

    func testSupportsOAuth_WithNilFeatures_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: nil
        )

        XCTAssertFalse(serverInfo.supportsOAuth, "Should return false for old servers without features array")
    }

    func testSupportsOAuth_WithEmptyFeatures_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: []
        )

        XCTAssertFalse(serverInfo.supportsOAuth)
    }

    // MARK: - Email Feature Detection

    func testSupportsEmail_WithEmailFeature_ReturnsTrue() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: ["oauth", "email"]
        )

        XCTAssertTrue(serverInfo.supportsEmail)
    }

    func testSupportsEmail_WithoutEmailFeature_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: ["oauth"]
        )

        XCTAssertFalse(serverInfo.supportsEmail)
    }

    func testSupportsEmail_WithNilFeatures_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: nil
        )

        XCTAssertFalse(serverInfo.supportsEmail)
    }

    // MARK: - DTO Conversion

    func testInit_FromDto_WithFeatures() {
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "1.2.3", release: "1.2.3", build: "abc123"),
            features: ["oauth", "email"]
        )

        let serverInfo = ServerInfo(from: dto)

        XCTAssertEqual(serverInfo.version, "1.2.3")
        XCTAssertTrue(serverInfo.isReachable)
        XCTAssertEqual(serverInfo.features, ["oauth", "email"])
        XCTAssertTrue(serverInfo.supportsOAuth)
        XCTAssertTrue(serverInfo.supportsEmail)
    }

    func testInit_FromDto_WithoutFeatures() {
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "0.9.0", release: "0.9.0", build: ""),
            features: nil
        )

        let serverInfo = ServerInfo(from: dto)

        XCTAssertEqual(serverInfo.version, "0.9.0")
        XCTAssertTrue(serverInfo.isReachable)
        XCTAssertNil(serverInfo.features)
        XCTAssertFalse(serverInfo.supportsOAuth, "Old server without features should not support OAuth")
        XCTAssertFalse(serverInfo.supportsEmail)
    }

    func testUnreachable_HasNoFeatures() {
        let serverInfo = ServerInfo.unreachable

        XCTAssertEqual(serverInfo.version, "")
        XCTAssertFalse(serverInfo.isReachable)
        XCTAssertNil(serverInfo.features)
        XCTAssertFalse(serverInfo.supportsOAuth)
        XCTAssertFalse(serverInfo.supportsEmail)
    }

    // MARK: - Backward Compatibility

    func testBackwardCompatibility_OldServerWithoutFeaturesArray() {
        // Simulates an old Readeck server that doesn't include features in /api/info response
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "0.5.0", release: "0.5.0", build: ""),
            features: nil  // Old server doesn't send features
        )

        let serverInfo = ServerInfo(from: dto)

        // Should work without crashing
        XCTAssertNotNil(serverInfo)
        XCTAssertEqual(serverInfo.version, "0.5.0")

        // OAuth detection should gracefully return false
        XCTAssertFalse(serverInfo.supportsOAuth, "Old servers should gracefully report no OAuth support")
        XCTAssertFalse(serverInfo.supportsEmail)
    }

    func testBackwardCompatibility_NewServerWithFeaturesArray() {
        // Simulates a new Readeck server with OAuth support
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "1.0.0", release: "1.0.0", build: "xyz"),
            features: ["oauth", "email"]
        )

        let serverInfo = ServerInfo(from: dto)

        XCTAssertNotNil(serverInfo)
        XCTAssertTrue(serverInfo.supportsOAuth, "New servers with oauth feature should report OAuth support")
        XCTAssertTrue(serverInfo.supportsEmail)
    }

    func testBackwardCompatibility_NewServerWithoutOAuthFeature() {
        // Simulates a new server that has features array but OAuth is disabled
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "1.0.0", release: "1.0.0", build: "xyz"),
            features: ["email"]  // Has features array but no oauth
        )

        let serverInfo = ServerInfo(from: dto)

        XCTAssertNotNil(serverInfo)
        XCTAssertFalse(serverInfo.supportsOAuth, "Server with features but no oauth should report no OAuth support")
        XCTAssertTrue(serverInfo.supportsEmail)
    }
}
