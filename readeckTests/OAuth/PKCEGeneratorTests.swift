//
//  PKCEGeneratorTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 15.12.25.
//

import XCTest
@testable import readeck

final class PKCEGeneratorTests: XCTestCase {

    // MARK: - Code Verifier Tests

    func testGenerateCodeVerifier_ReturnsCorrectLength() {
        let verifier = PKCEGenerator.generateCodeVerifier()

        XCTAssertEqual(verifier.count, 64, "Code verifier should be 64 characters long")
    }

    func testGenerateCodeVerifier_ContainsOnlyAllowedCharacters() {
        let verifier = PKCEGenerator.generateCodeVerifier()
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

        for character in verifier {
            XCTAssertTrue(
                allowedCharacterSet.contains(character.unicodeScalars.first!),
                "Verifier should only contain alphanumeric characters"
            )
        }
    }

    func testGenerateCodeVerifier_GeneratesUniqueValues() {
        let verifier1 = PKCEGenerator.generateCodeVerifier()
        let verifier2 = PKCEGenerator.generateCodeVerifier()

        XCTAssertNotEqual(verifier1, verifier2, "Each verifier should be unique")
    }

    // MARK: - Code Challenge Tests

    func testGenerateCodeChallenge_ReturnsNonEmptyString() {
        let verifier = "test_verifier_1234567890abcdefghijklmnopqrstuvwxyz1234567890123"
        let challenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        XCTAssertFalse(challenge.isEmpty, "Code challenge should not be empty")
    }

    func testGenerateCodeChallenge_IsBase64UrlEncoded() {
        let verifier = PKCEGenerator.generateCodeVerifier()
        let challenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        // Base64url should not contain +, /, or =
        XCTAssertFalse(challenge.contains("+"), "Challenge should not contain '+'")
        XCTAssertFalse(challenge.contains("/"), "Challenge should not contain '/'")
        XCTAssertFalse(challenge.contains("="), "Challenge should not contain '=' padding")
    }

    func testGenerateCodeChallenge_ContainsOnlyBase64UrlCharacters() {
        let verifier = PKCEGenerator.generateCodeVerifier()
        let challenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

        for character in challenge {
            XCTAssertTrue(
                allowedCharacterSet.contains(character.unicodeScalars.first!),
                "Challenge should only contain base64url characters (A-Z, a-z, 0-9, -, _)"
            )
        }
    }

    func testGenerateCodeChallenge_IsDeterministic() {
        let verifier = "consistent_verifier_for_testing_purposes_1234567890abcdefghij"
        let challenge1 = PKCEGenerator.generateCodeChallenge(from: verifier)
        let challenge2 = PKCEGenerator.generateCodeChallenge(from: verifier)

        XCTAssertEqual(challenge1, challenge2, "Same verifier should always produce same challenge")
    }

    func testGenerateCodeChallenge_DifferentVerifiersProduceDifferentChallenges() {
        let verifier1 = PKCEGenerator.generateCodeVerifier()
        let verifier2 = PKCEGenerator.generateCodeVerifier()

        let challenge1 = PKCEGenerator.generateCodeChallenge(from: verifier1)
        let challenge2 = PKCEGenerator.generateCodeChallenge(from: verifier2)

        XCTAssertNotEqual(challenge1, challenge2, "Different verifiers should produce different challenges")
    }

    // MARK: - Combined Generation Tests

    func testGenerate_ReturnsVerifierAndChallenge() {
        let (verifier, challenge) = PKCEGenerator.generate()

        XCTAssertEqual(verifier.count, 64, "Verifier should be 64 characters")
        XCTAssertFalse(challenge.isEmpty, "Challenge should not be empty")
    }

    func testGenerate_ChallengeMatchesVerifier() {
        let (verifier, challenge) = PKCEGenerator.generate()
        let expectedChallenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        XCTAssertEqual(challenge, expectedChallenge, "Challenge should match the one generated from verifier")
    }

    func testGenerate_ProducesUniqueValues() {
        let (verifier1, challenge1) = PKCEGenerator.generate()
        let (verifier2, challenge2) = PKCEGenerator.generate()

        XCTAssertNotEqual(verifier1, verifier2, "Each verifier should be unique")
        XCTAssertNotEqual(challenge1, challenge2, "Each challenge should be unique")
    }

    // MARK: - RFC 7636 Compliance Tests

    func testPKCE_RFC7636_Example() {
        // Test with a known example to verify SHA-256 + base64url encoding
        // This ensures our implementation matches the RFC spec

        // Using a simple known verifier for testing
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let challenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        // Expected challenge (calculated externally using RFC 7636 algorithm)
        let expectedChallenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

        XCTAssertEqual(challenge, expectedChallenge, "Challenge should match RFC 7636 example")
    }
}
