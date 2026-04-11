//
//  EndpointValidator.swift
//  readeck
//
//  Created by Ilyas Hallak on 05.12.25.
//

import Foundation

/// Validates and normalizes server endpoint URLs for consistent API usage
struct EndpointValidator {
    /// Normalizes an endpoint URL by:
    /// - Trimming whitespace
    /// - Ensuring proper scheme (http/https, defaults to https if missing)
    /// - Preserving custom ports
    /// - Removing trailing slashes from path
    /// - Removing query parameters and fragments
    ///
    /// - Parameter endpoint: Raw endpoint string from user input
    /// - Returns: Normalized endpoint URL string
    ///
    /// Examples:
    /// - "example.com" → "https://example.com"
    /// - "http://100.80.0.1:8080" → "http://100.80.0.1:8080"
    /// - "https://server:3000/path/" → "https://server:3000/path"
    /// - "192.168.1.100:9090?query=test" → "https://192.168.1.100:9090"
    static func normalize(_ endpoint: String) -> String {
        var normalized = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle empty input
        guard !normalized.isEmpty else {
            return normalized
        }

        // Remove query parameters first
        if let queryIndex = normalized.firstIndex(of: "?") {
            normalized = String(normalized[..<queryIndex])
        }

        // Try to parse as URLComponents
        var urlComponents: URLComponents?

        // First attempt: parse as-is
        urlComponents = URLComponents(string: normalized)

        // If parsing failed, no scheme, or no host (means URLComponents misinterpreted it),
        // try adding https:// prefix
        if urlComponents == nil ||
           urlComponents?.scheme == nil ||
           urlComponents?.host == nil {
            urlComponents = URLComponents(string: "https://" + normalized)
        }

        // If still no valid components, return original
        guard let components = urlComponents else {
            return normalized
        }

        return buildNormalizedURL(from: components)
    }

    /// Validates if an endpoint string can be normalized to a valid URL
    /// - Parameter endpoint: Endpoint string to validate
    /// - Returns: true if the endpoint can be normalized to a valid URL, false otherwise
    static func isValid(_ endpoint: String) -> Bool {
        let normalized = normalize(endpoint)
        guard let url = URL(string: normalized) else {
            return false
        }
        // Check that we have at minimum a scheme and host
        return url.scheme != nil && url.host != nil
    }

    // MARK: - Private Helpers

    private static func buildNormalizedURL(from components: URLComponents) -> String {
        var urlComponents = components

        // Ensure scheme is http or https, default to https
        if urlComponents.scheme == nil {
            urlComponents.scheme = "https"
        } else if urlComponents.scheme != "http" && urlComponents.scheme != "https" {
            urlComponents.scheme = "https"
        }

        // Remove trailing slash from path if present
        if urlComponents.path.hasSuffix("/") {
            urlComponents.path = String(urlComponents.path.dropLast())
        }

        // Remove query parameters and fragments
        urlComponents.query = nil
        urlComponents.fragment = nil

        return urlComponents.string ?? components.string ?? ""
    }
}
