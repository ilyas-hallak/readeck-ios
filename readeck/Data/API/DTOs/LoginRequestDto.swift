import Foundation

struct LoginRequestDto: Codable {
    let application: String
    let username: String
    let password: String
}
