import Foundation

struct ServerInfoDto: Codable {
    let version: VersionInfo
    let features: [String]?

    struct VersionInfo: Codable {
        let canonical: String
        let release: String
        let build: String
    }
}
