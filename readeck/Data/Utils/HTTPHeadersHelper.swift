//
//  HTTPHeadersHelper.swift
//  readeck
//
//  Manages custom HTTP headers for API requests.
//  Provides functionality to apply user-defined headers while protecting critical system headers.
//
//  Custom headers are stored securely in the Keychain and applied to all API requests.
//  Protected headers (Content-Type, Authorization) cannot be overridden by custom headers.
//

import Foundation

class HTTPHeadersHelper {
    static let shared = HTTPHeadersHelper()
    private init() {}

    private static let protectedHeaders = ["Content-Type", "Authorization", "content-type", "authorization"] 
    private static let protectedHeadersLowercase = protectedHeaders.map { $0.lowercased() }

    private let keychainHelper = KeychainHelper.shared

    // Custom headers are loaded from Keychain and applied only if:
    // - The header name is not in the protected headers list (case-insensitive check)
    // - The header doesn't already exist in the request
    func applyCustomHeaders(to request: inout URLRequest) {
        guard let customHeaders = keychainHelper.loadCustomHeaders() else {
            return
        }

        for (key, value) in customHeaders {
            let keyLowercase = key.lowercased()
            guard !Self.protectedHeadersLowercase.contains(keyLowercase) else {
                continue
            }

            if request.value(forHTTPHeaderField: key) == nil {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
    }

    static func isHeaderNameAllowed(_ name: String) -> Bool {
        let nameLowercase = name.lowercased()
        return !protectedHeadersLowercase.contains(nameLowercase)
    }
}
