//
//  OAuthSession.swift
//  readeck
//
//  Created by Ilyas Hallak on 16.12.25.
//

import AuthenticationServices
import Foundation

/// Wrapper for ASWebAuthenticationSession to handle OAuth browser flow
@MainActor
final class OAuthSession: NSObject {
    private var authSession: ASWebAuthenticationSession?
    private let logger = Logger.network

    /// Starts the OAuth authentication flow in a browser
    /// - Parameters:
    ///   - url: Authorization URL to open
    ///   - callbackURLScheme: Custom URL scheme for callback (e.g., "readeck")
    ///   - completion: Called with callback URL or error
    func start(
        url: URL,
        callbackURLScheme: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        logger.info("Starting OAuth authentication session with URL: \(url.absoluteString)")

        // Create authentication session
        authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackURLScheme
        ) { [weak self] callbackURL, error in
            guard let self else { return }

            if let error {
                self.logger.error("OAuth authentication failed: \(error.localizedDescription)")

                // Check if user cancelled
                if let authError = error as? ASWebAuthenticationSessionError,
                   authError.code == .canceledLogin {
                    self.logger.info("User cancelled OAuth login")
                    completion(.failure(OAuthError.userCancelled))
                } else {
                    completion(.failure(error))
                }
                return
            }

            guard let callbackURL else {
                self.logger.error("OAuth callback URL is nil")
                completion(.failure(OAuthError.invalidCallback))
                return
            }

            self.logger.info("OAuth callback received: \(callbackURL.absoluteString)")
            completion(.success(callbackURL))
        }

        // Configure session
        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false // Allow cookies/saved passwords

        // Start the session
        guard let session = authSession, session.start() else {
            logger.error("Failed to start OAuth authentication session")
            completion(.failure(OAuthError.invalidCallback))
            return
        }

        logger.info("OAuth authentication session started successfully")
    }

    /// Cancels the ongoing authentication session
    func cancel() {
        logger.info("Cancelling OAuth authentication session")
        authSession?.cancel()
        authSession = nil
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OAuthSession: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window for presenting the authentication session
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for OAuth presentation")
        }
        return window
    }
}
