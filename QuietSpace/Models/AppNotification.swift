import Foundation

struct AppNotification: Decodable {
    let id: String?
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try? c.decodeIfPresent(String.self, forKey: .id)
        userId = try? c.decodeIfPresent(String.self, forKey: .userId)
        type = try? c.decodeIfPresent(String.self, forKey: .type)
        title = try? c.decodeIfPresent(String.self, forKey: .title)
        message = try? c.decodeIfPresent(String.self, forKey: .message)
        isRead = try? c.decodeIfPresent(Bool.self, forKey: .isRead)
        if let s = try? c.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = s
        } else if let n = try? c.decodeIfPresent(Int64.self, forKey: .createdAt) {
            createdAt = String(n)
        } else {
            createdAt = nil
        }
        if let m = try? c.decodeIfPresent([String: String].self, forKey: .metadata) {
            metadata = m
        } else {
            metadata = nil
        }
    }

    init(id: String?, userId: String?, type: String?, title: String?, message: String?,
         metadata: [String: String]?, isRead: Bool?, createdAt: String?) {
        self.id = id; self.userId = userId; self.type = type; self.title = title
        self.message = message; self.metadata = metadata; self.isRead = isRead; self.createdAt = createdAt
    }

    var rowKey: String {
        if let id { return "n-\(id)" }
        return "n-\(createdAt ?? "")-\(title ?? "")"
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
