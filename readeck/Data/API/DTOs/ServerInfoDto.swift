import Foundation

struct ServerInfoDto: Codable {
    let version: VersionInfo
    // swiftlint:disable:next discouraged_optional_collection
    let features: [String]?

    struct VersionInfo: Codable {
        let canonical: String
        let release: String?
        let build: String?
    }
}

// Decode `version` defensively: newer Readeck servers return a nested object
// ({canonical, release, build}), while older ones return a plain version string.
// release/build are optional because some server versions omit them. This keeps
// login working across the whole range instead of failing with a decoding error.
extension ServerInfoDto.VersionInfo {
    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let versionString = try? single.decode(String.self) {
            self.canonical = versionString
            self.release = versionString
            self.build = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.canonical = try container.decode(String.self, forKey: .canonical)
        self.release = try container.decodeIfPresent(String.self, forKey: .release)
        self.build = try container.decodeIfPresent(String.self, forKey: .build)
    }
}
