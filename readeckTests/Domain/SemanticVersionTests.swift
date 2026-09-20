//
//  SemanticVersionTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 04.09.26.
//

import Foundation
import Testing
@testable import readeck

@Suite("Semantic Version Tests")
struct SemanticVersionTests {

    // MARK: - Parsing

    @Test("Parses a full major.minor.patch version")
    func parse_FullVersion() throws {
        let version = try #require(SemanticVersion("0.23.2"))

        #expect(version.major == 0)
        #expect(version.minor == 23)
        #expect(version.patch == 2)
    }

    @Test("Parses a two component version with patch defaulting to zero")
    func parse_MinorOnly() throws {
        let version = try #require(SemanticVersion("0.23"))

        #expect(version == SemanticVersion(major: 0, minor: 23, patch: 0))
    }

    @Test("Parses a single component version")
    func parse_MajorOnly() throws {
        let version = try #require(SemanticVersion("1"))

        #expect(version == SemanticVersion(major: 1, minor: 0, patch: 0))
    }

    @Test("Ignores pre-release suffixes")
    func parse_PreRelease() throws {
        // The old string splitting silently dropped "2-rc1" here, which turned
        // a release candidate into a server that supported nothing.
        let version = try #require(SemanticVersion("0.23.2-rc1"))

        #expect(version == SemanticVersion(major: 0, minor: 23, patch: 2))
    }

    @Test("Ignores build metadata")
    func parse_BuildMetadata() throws {
        let version = try #require(SemanticVersion("0.23.2+build.5"))

        #expect(version == SemanticVersion(major: 0, minor: 23, patch: 2))
    }

    @Test("Ignores pre-release and build metadata combined")
    func parse_PreReleaseAndBuildMetadata() throws {
        let version = try #require(SemanticVersion("0.23.2-rc1+build.5"))

        #expect(version == SemanticVersion(major: 0, minor: 23, patch: 2))
    }

    @Test("Strips a leading v")
    func parse_LeadingV() throws {
        #expect(SemanticVersion("v0.23.2") == SemanticVersion(major: 0, minor: 23, patch: 2))
        #expect(SemanticVersion("V0.23.2") == SemanticVersion(major: 0, minor: 23, patch: 2))
    }

    @Test("Trims surrounding whitespace")
    func parse_Whitespace() {
        #expect(SemanticVersion("  0.23.2\n") == SemanticVersion(major: 0, minor: 23, patch: 2))
    }

    @Test("Tolerates a fourth component")
    func parse_FourComponents() {
        #expect(SemanticVersion("0.23.2.7") == SemanticVersion(major: 0, minor: 23, patch: 2))
    }

    @Test("Unparsable input returns nil instead of a silent default", arguments: [
        "",
        "   ",
        "abc",
        "v",
        "0.23.",
        ".23.2",
        "0..2",
        "latest",
        "0.x.2",
        "-1.2.3"
    ])
    func parse_Garbage_ReturnsNil(input: String) {
        #expect(SemanticVersion(input) == nil, "\"\(input)\" must not parse into a default version")
    }

    // MARK: - Comparison

    @Test("Patch versions compare numerically")
    func compare_Patch() {
        #expect(SemanticVersion(major: 0, minor: 20, patch: 2) > SemanticVersion(major: 0, minor: 20, patch: 0))
        #expect(SemanticVersion(major: 0, minor: 20, patch: 0) < SemanticVersion(major: 0, minor: 20, patch: 1))
    }

    @Test("Double digit minor versions are not compared as strings")
    func compare_DoubleDigitMinor() {
        // A lexicographic comparison would claim "0.9.0" > "0.10.0".
        #expect(SemanticVersion(major: 0, minor: 9) < SemanticVersion(major: 0, minor: 10))
        #expect(SemanticVersion(major: 0, minor: 9) < SemanticVersion(major: 0, minor: 23, patch: 2))
    }

    @Test("Major version dominates the comparison")
    func compare_Major() {
        #expect(SemanticVersion(major: 1) > SemanticVersion(major: 0, minor: 99, patch: 99))
    }

    @Test("Equal components compare equal")
    func compare_Equality() {
        #expect(SemanticVersion("0.22.0") == SemanticVersion(major: 0, minor: 22))
        #expect(!(SemanticVersion(major: 0, minor: 22) < SemanticVersion(major: 0, minor: 22)))
    }

    @Test("A pre-release compares equal to its release")
    func compare_PreReleaseEqualsRelease() {
        // Deliberate: a 0.23.2 release candidate already carries 0.23.2 features.
        #expect(SemanticVersion("0.23.2-rc1") == SemanticVersion("0.23.2"))
    }

    @Test("Description prints the normalized version")
    func description_IsNormalized() {
        #expect(SemanticVersion("v0.23-rc1")?.description == "0.23.0")
    }
}
