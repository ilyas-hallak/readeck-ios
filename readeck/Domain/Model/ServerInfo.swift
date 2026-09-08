import Foundation

struct ServerInfo {
    let version: String
    let isReachable: Bool
    // swiftlint:disable:next discouraged_optional_collection
    let features: [String]?

    /// Central capability mapping for this server. Every version gate belongs
    /// here instead of into ad hoc string comparisons at the call site.
    ///
    /// `hasOAuthMetadata` stays false: OAuth availability is determined from
    /// `/.well-known/oauth-authorization-server`, which the login flow does not
    /// probe yet. Until it does, use `capabilities.canUseOAuth` only where the
    /// metadata was actually fetched.
    var capabilities: ServerCapabilities {
        ServerCapabilities(versionString: version, features: features)
    }

    /// Transition property based on the `features` array.
    ///
    /// The "oauth" entry is hardcoded in the server and always present from
    /// 0.21.0 on, so it really only means "server >= 0.21". The login flow will
    /// move to `ServerCapabilities.canUseOAuth`, which is backed by the
    /// authorization server metadata, in the follow-up work package. Kept
    /// unchanged here so runtime behaviour stays identical.
    @available(*, deprecated, message: "Use ServerCapabilities.canUseOAuth once the login flow probes /.well-known/oauth-authorization-server")
    var supportsOAuth: Bool {
        features?.contains("oauth") ?? false
    }

    var supportsEmail: Bool {
        capabilities.supportsEmailSharing
    }
}

extension ServerInfo {
    init(from dto: ServerInfoDto) {
        self.version = dto.version.canonical
        self.features = dto.features
        self.isReachable = true
    }

    static var unreachable: ServerInfo {
        ServerInfo(version: "", isReachable: false, features: nil)
    }
}
