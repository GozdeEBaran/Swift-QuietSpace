import Foundation

struct AppNotification: Identifiable, Codable {
    let id: Int?
    let userId: String?
    let type: String?
    let title: String?
    let message: String?
    let metadata: [String: String]?
    let isRead: Bool?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type, title, message, metadata
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

struct NotificationInsert: Encodable {
    let userId: String
    let type: String
    let title: String
    let message: String
    let metadata: [String: String]?
    let isRead: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case type, title, message, metadata
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}
