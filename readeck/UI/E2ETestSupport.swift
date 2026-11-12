#if DEBUG
import Foundation

/// Launch arguments understood by `E2ETestSupport`, parsed ahead of time so the
/// parsing itself can be unit tested without touching the keychain.
struct E2ELaunchArguments: Equatable {
    let endpoint: String
    let accessToken: String
    let clientId: String
    let refreshToken: String?
    let expiresIn: Int?

    private static let recognizedKeys: Set<String> = [
        "-e2eEndpoint",
        "-e2eOAuthAccessToken",
        "-e2eOAuthClientId",
        "-e2eOAuthRefreshToken",
        "-e2eOAuthExpiresIn"
    ]

    static func parse(_ arguments: [String]) -> Self? {
        var values: [String: String] = [:]
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            if recognizedKeys.contains(argument), index + 1 < arguments.count {
                values[argument] = arguments[index + 1]
                index += 2
            } else {
                index += 1
            }
        }

        guard let endpoint = values["-e2eEndpoint"],
              let accessToken = values["-e2eOAuthAccessToken"],
              let clientId = values["-e2eOAuthClientId"] else {
            return nil
        }

        return Self(
            endpoint: endpoint,
            accessToken: accessToken,
            clientId: clientId,
            refreshToken: values["-e2eOAuthRefreshToken"],
            expiresIn: values["-e2eOAuthExpiresIn"].flatMap(Int.init)
        )
    }
}

/// Injects a pre-fetched OAuth session before the app's first render, so Maestro
/// flows can skip the OAuth web sheet entirely (out of scope for automation, #160).
/// Only reachable in Debug builds: the whole file is compiled out of Release by
/// the `#if DEBUG` above, not by a runtime check.
enum E2ETestSupport {
    static func applyLaunchArgumentsIfNeeded(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard let parsed = E2ELaunchArguments.parse(arguments) else { return }

        let token = OAuthToken(
            accessToken: parsed.accessToken,
            tokenType: "Bearer",
            scope: OAuthManager.scopes,
            expiresIn: parsed.expiresIn,
            refreshToken: parsed.refreshToken,
            createdAt: Date()
        )

        KeychainHelper.shared.saveEndpoint(parsed.endpoint)
        KeychainHelper.shared.saveOAuthToken(token)
        KeychainHelper.shared.saveAuthMethod(.oauth)
        KeychainHelper.shared.saveOAuthClientId(parsed.clientId)

        // Bypasses the DI factory on purpose: this only needs the synchronous
        // UserDefaults-backed setter, and must run before AppViewModel's init
        // reads it, which rules out the protocol's async saveHasFinishedSetup.
        SettingsRepository().hasFinishedSetup = true
    }
}
#endif
