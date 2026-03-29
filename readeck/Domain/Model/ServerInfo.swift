import Foundation

struct ServerInfo {
    let version: String
    let isReachable: Bool
    // swiftlint:disable:next discouraged_optional_collection
    let features: [String]?

    var supportsOAuth: Bool {
        features?.contains("oauth") ?? false
    }

    var supportsEmail: Bool {
        features?.contains("email") ?? false
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
