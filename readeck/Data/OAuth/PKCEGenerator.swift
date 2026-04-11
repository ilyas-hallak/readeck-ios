//
//  PKCEGenerator.swift
//  readeck
//
//  Created by Ilyas Hallak on 15.12.25.
//

import Foundation
import CryptoKit

/// Generates PKCE (Proof Key for Code Exchange) verifier and challenge for OAuth 2.0
/// According to RFC 7636: https://datatracker.ietf.org/doc/html/rfc7636
struct PKCEGenerator {
    /// Generates a cryptographically random code verifier
    /// - Returns: A 64-character random alphanumeric string
    static func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)

        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        return buffer.map { String(alphabet[Int($0) % alphabet.count]) }.joined()
    }

    /// Generates a code challenge from a verifier using SHA-256 and base64url encoding
    /// - Parameter verifier: The code verifier string
    /// - Returns: Base64url-encoded SHA-256 hash (without padding)
    static func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        let base64 = Data(hash).base64EncodedString()

        // Convert to base64url (RFC 7636 Section 4.2)
        // Replace '+' with '-', '/' with '_', and remove '=' padding
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Generates both verifier and challenge in one call
    /// - Returns: Tuple containing (verifier, challenge)
    static func generate() -> (verifier: String, challenge: String) {
        let verifier = generateCodeVerifier()
        let challenge = generateCodeChallenge(from: verifier)
        return (verifier, challenge)
    }
}
