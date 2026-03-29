//
//  PKCEGeneratorTests.swift
//  readeckTests
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Testing
import Foundation
@testable import readeck

@Suite("PKCE Generator Tests")
struct PKCEGeneratorTests {

    // MARK: - Code Verifier Tests

    @Test("Generate code verifier returns correct length")
    func generateCodeVerifier_ReturnsCorrectLength() {
        let verifier = PKCEGenerator.generateCodeVerifier()

        #expect(verifier.count == 64, "Code verifier should be 64 characters long")
    }

    @Test("Generate code verifier contains only allowed characters")
    func generateCodeVerifier_ContainsOnlyAllowedCharacters() {
        let verifier = PKCEGenerator.generateCodeVerifier()
        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

        for character in verifier {
            #expect(
                allowedCharacterSet.contains(character.unicodeScalars.first!),
                "Verifier should only contain alphanumeric characters"
            )
        }
    }

    @Test("Generate code verifier generates unique values")
    func generateCodeVerifier_GeneratesUniqueValues() {
        let verifier1 = PKCEGenerator.generateCodeVerifier()
        let verifier2 = PKCEGenerator.generateCodeVerifier()

        #expect(verifier1 != verifier2, "Each verifier should be unique")
    }

    // MARK: - Code Challenge Tests

    @Test("Generate code challenge returns non-empty string")
    func generateCodeChallenge_ReturnsNonEmptyString() {
        let verifier = "test_verifier_1234567890abcdefghijklmnopqrstuvwxyz1234567890123"
        let challenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        #expect(!challenge.isEmpty, "Code challenge should not be empty")
    }

    @Test("Generate code challenge is Base64 URL encoded")
    func generateCodeChallenge_IsBase64UrlEncoded() {
        let verifier = PKCEGenerator.generateCodeVerifier()
        let challenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        // Base64url should not contain +, /, or =
        #expect(!challenge.contains("+"), "Challenge should not contain '+'")
        #expect(!challenge.contains("/"), "Challenge should not contain '/'")
        #expect(!challenge.contains("="), "Challenge should not contain '=' padding")
    }

    @Test("Generate code challenge contains only Base64 URL characters")
    func generateCodeChallenge_ContainsOnlyBase64UrlCharacters() {
        let verifier = PKCEGenerator.generateCodeVerifier()
        let challenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

        for character in challenge {
            #expect(
                allowedCharacterSet.contains(character.unicodeScalars.first!),
                "Challenge should only contain base64url characters (A-Z, a-z, 0-9, -, _)"
            )
        }
    }

    @Test("Generate code challenge is deterministic")
    func generateCodeChallenge_IsDeterministic() {
        let verifier = "consistent_verifier_for_testing_purposes_1234567890abcdefghij"
        let challenge1 = PKCEGenerator.generateCodeChallenge(from: verifier)
        let challenge2 = PKCEGenerator.generateCodeChallenge(from: verifier)

        #expect(challenge1 == challenge2, "Same verifier should always produce same challenge")
    }

    @Test("Different verifiers produce different challenges")
    func generateCodeChallenge_DifferentVerifiersProduceDifferentChallenges() {
        let verifier1 = PKCEGenerator.generateCodeVerifier()
        let verifier2 = PKCEGenerator.generateCodeVerifier()

        let challenge1 = PKCEGenerator.generateCodeChallenge(from: verifier1)
        let challenge2 = PKCEGenerator.generateCodeChallenge(from: verifier2)

        #expect(challenge1 != challenge2, "Different verifiers should produce different challenges")
    }

    // MARK: - Combined Generation Tests

    @Test("Generate returns verifier and challenge")
    func generate_ReturnsVerifierAndChallenge() {
        let (verifier, challenge) = PKCEGenerator.generate()

        #expect(verifier.count == 64, "Verifier should be 64 characters")
        #expect(!challenge.isEmpty, "Challenge should not be empty")
    }

    @Test("Generate challenge matches verifier")
    func generate_ChallengeMatchesVerifier() {
        let (verifier, challenge) = PKCEGenerator.generate()
        let expectedChallenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        #expect(challenge == expectedChallenge, "Challenge should match the one generated from verifier")
    }

    @Test("Generate produces unique values")
    func generate_ProducesUniqueValues() {
        let (verifier1, challenge1) = PKCEGenerator.generate()
        let (verifier2, challenge2) = PKCEGenerator.generate()

        #expect(verifier1 != verifier2, "Each verifier should be unique")
        #expect(challenge1 != challenge2, "Each challenge should be unique")
    }

    // MARK: - RFC 7636 Compliance Tests

    @Test("PKCE RFC 7636 example")
    func pKCE_RFC7636_Example() {
        // Test with a known example to verify SHA-256 + base64url encoding
        // This ensures our implementation matches the RFC spec

        // Using a simple known verifier for testing
        let verifier = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
        let challenge = PKCEGenerator.generateCodeChallenge(from: verifier)

        // Expected challenge (calculated externally using RFC 7636 algorithm)
        let expectedChallenge = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"

        #expect(challenge == expectedChallenge, "Challenge should match RFC 7636 example")
    }
}
