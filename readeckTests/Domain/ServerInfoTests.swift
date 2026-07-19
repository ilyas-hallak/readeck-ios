//
//  ServerInfoTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation
import Testing
@testable import readeck

@Suite("Server Info Tests")
struct ServerInfoTests {

    // MARK: - OAuth Feature Detection

    @Test("Supports OAuth with OAuth feature returns true")
    func supportsOAuth_WithOAuthFeature_ReturnsTrue() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: ["oauth", "email"]
        )

        #expect(serverInfo.supportsOAuth)
    }

    @Test("Supports OAuth without OAuth feature returns false")
    func supportsOAuth_WithoutOAuthFeature_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: ["email"]
        )

        #expect(!serverInfo.supportsOAuth)
    }

    @Test("Supports OAuth with nil features returns false")
    func supportsOAuth_WithNilFeatures_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: nil
        )

        #expect(!serverInfo.supportsOAuth, "Should return false for old servers without features array")
    }

    @Test("Supports OAuth with empty features returns false")
    func supportsOAuth_WithEmptyFeatures_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: []
        )

        #expect(!serverInfo.supportsOAuth)
    }

    // MARK: - Email Feature Detection

    @Test("Supports email with email feature returns true")
    func supportsEmail_WithEmailFeature_ReturnsTrue() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: ["oauth", "email"]
        )

        #expect(serverInfo.supportsEmail)
    }

    @Test("Supports email without email feature returns false")
    func supportsEmail_WithoutEmailFeature_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: ["oauth"]
        )

        #expect(!serverInfo.supportsEmail)
    }

    @Test("Supports email with nil features returns false")
    func supportsEmail_WithNilFeatures_ReturnsFalse() {
        let serverInfo = ServerInfo(
            version: "1.0.0",
            isReachable: true,
            features: nil
        )

        #expect(!serverInfo.supportsEmail)
    }

    // MARK: - DTO Conversion

    @Test("Init from DTO with features")
    func init_FromDto_WithFeatures() {
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "1.2.3", release: "1.2.3", build: "abc123"),
            features: ["oauth", "email"]
        )

        let serverInfo = ServerInfo(from: dto)

        #expect(serverInfo.version == "1.2.3")
        #expect(serverInfo.isReachable)
        #expect(serverInfo.features == ["oauth", "email"])
        #expect(serverInfo.supportsOAuth)
        #expect(serverInfo.supportsEmail)
    }

    @Test("Init from DTO without features")
    func init_FromDto_WithoutFeatures() {
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "0.9.0", release: "0.9.0", build: ""),
            features: nil
        )

        let serverInfo = ServerInfo(from: dto)

        #expect(serverInfo.version == "0.9.0")
        #expect(serverInfo.isReachable)
        #expect(serverInfo.features == nil)
        #expect(!serverInfo.supportsOAuth, "Old server without features should not support OAuth")
        #expect(!serverInfo.supportsEmail)
    }

    @Test("Unreachable has no features")
    func unreachable_HasNoFeatures() {
        let serverInfo = ServerInfo.unreachable

        #expect(serverInfo.version == "")
        #expect(!serverInfo.isReachable)
        #expect(serverInfo.features == nil)
        #expect(!serverInfo.supportsOAuth)
        #expect(!serverInfo.supportsEmail)
    }

    // MARK: - Backward Compatibility

    @Test("Backward compatibility: old server without features array")
    func backwardCompatibility_OldServerWithoutFeaturesArray() {
        // Simulates an old Readeck server that doesn't include features in /api/info response
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "0.5.0", release: "0.5.0", build: ""),
            features: nil  // Old server doesn't send features
        )

        let serverInfo = ServerInfo(from: dto)

        // Should work without crashing
        #expect(serverInfo != nil)
        #expect(serverInfo.version == "0.5.0")

        // OAuth detection should gracefully return false
        #expect(!serverInfo.supportsOAuth, "Old servers should gracefully report no OAuth support")
        #expect(!serverInfo.supportsEmail)
    }

    @Test("Backward compatibility: new server with features array")
    func backwardCompatibility_NewServerWithFeaturesArray() {
        // Simulates a new Readeck server with OAuth support
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "1.0.0", release: "1.0.0", build: "xyz"),
            features: ["oauth", "email"]
        )

        let serverInfo = ServerInfo(from: dto)

        #expect(serverInfo != nil)
        #expect(serverInfo.supportsOAuth, "New servers with oauth feature should report OAuth support")
        #expect(serverInfo.supportsEmail)
    }

    @Test("Backward compatibility: new server without OAuth feature")
    func backwardCompatibility_NewServerWithoutOAuthFeature() {
        // Simulates a new server that has features array but OAuth is disabled
        let dto = ServerInfoDto(
            version: ServerInfoDto.VersionInfo(canonical: "1.0.0", release: "1.0.0", build: "xyz"),
            features: ["email"]  // Has features array but no oauth
        )

        let serverInfo = ServerInfo(from: dto)

        #expect(serverInfo != nil)
        #expect(!serverInfo.supportsOAuth, "Server with features but no oauth should report no OAuth support")
        #expect(serverInfo.supportsEmail)
    }

    // MARK: - JSON Decoding

    @Test("Decodes real server /api/info response with nested version object")
    func decode_RealServerResponse_WithNestedVersion() throws {
        let json = """
        {
          "version": {
            "canonical": "0.22.2",
            "release": "0.22.2",
            "build": ""
          },
          "features": ["oauth"]
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(ServerInfoDto.self, from: json)

        #expect(dto.version.canonical == "0.22.2")
        #expect(dto.version.release == "0.22.2")
        #expect(dto.version.build == "")
        #expect(dto.features == ["oauth"])
    }

    @Test("Decodes real 0.20.1 response without features array")
    func decode_RealServerResponse_0201_WithoutFeatures() throws {
        // Actual /api/info from a Readeck 0.20.1 instance — no "features" key at all.
        let json = #"{"version":{"canonical":"0.20.1","release":"0.20.1","build":""}}"#.data(using: .utf8)!

        let dto = try JSONDecoder().decode(ServerInfoDto.self, from: json)

        #expect(dto.version.canonical == "0.20.1")
        #expect(dto.features == nil)
    }

    @Test("Decodes legacy plain-string version")
    func decode_LegacyPlainStringVersion() throws {
        // Older Readeck servers return `version` as a plain string, not an object.
        let json = #"{"version":"0.15.0"}"#.data(using: .utf8)!

        let dto = try JSONDecoder().decode(ServerInfoDto.self, from: json)

        #expect(dto.version.canonical == "0.15.0")
        #expect(dto.version.release == "0.15.0")
        #expect(dto.version.build == nil)
        #expect(dto.features == nil)
    }

    @Test("Decodes version object with missing build/release")
    func decode_VersionObject_MissingBuildAndRelease() throws {
        // Some server versions omit build (and/or release) from the version object.
        let json = #"{"version":{"canonical":"0.19.0"},"features":["oauth"]}"#.data(using: .utf8)!

        let dto = try JSONDecoder().decode(ServerInfoDto.self, from: json)

        #expect(dto.version.canonical == "0.19.0")
        #expect(dto.version.release == nil)
        #expect(dto.version.build == nil)
        #expect(dto.features == ["oauth"])
    }

    @Test("Decodes version object with explicit null build")
    func decode_VersionObject_NullBuild() throws {
        let json = #"{"version":{"canonical":"0.19.0","release":"0.19.0","build":null}}"#.data(using: .utf8)!

        let dto = try JSONDecoder().decode(ServerInfoDto.self, from: json)

        #expect(dto.version.canonical == "0.19.0")
        #expect(dto.version.build == nil)
    }
}
