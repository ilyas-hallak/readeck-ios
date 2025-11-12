import Foundation

struct ServerInfo {
    let version: String
    let buildDate: String?
    let userAgent: String?
    let isReachable: Bool
}

extension ServerInfo {
    init(from dto: ServerInfoDto) {
        self.version = dto.version
        self.buildDate = dto.buildDate
        self.userAgent = dto.userAgent
        self.isReachable = true
    }

    static var unreachable: ServerInfo {
        ServerInfo(version: "", buildDate: nil, userAgent: nil, isReachable: false)
    }
}
