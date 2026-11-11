import Foundation

/// The `{ status, message }` body the server sends for plain confirmations.
struct ServerMessageDto: Codable {
    let status: Int
    let message: String
}
