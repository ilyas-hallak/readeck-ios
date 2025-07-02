import Foundation

struct UserDto: Codable {
    let id: String
    let token: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case token
    }
}