import Foundation

struct ServerInfoDto: Codable {
    let version: VersionInfo
    // swiftlint:disable:next discouraged_optional_collection
    let features: [String]?

    struct VersionInfo: Codable {
        let canonical: String
        let release: String
        let build: String
    }
}
