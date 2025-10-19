import Foundation

struct ServerInfoDto: Codable {
    let version: String
    let buildDate: String?
    let userAgent: String?

    enum CodingKeys: String, CodingKey {
        case version
        case buildDate = "build_date"
        case userAgent = "user_agent"
    }
}
