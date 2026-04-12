// Nguyen Minh Triet Luu — Student ID: 101542519

import Foundation

struct CommunityPost: Identifiable, Decodable {
    let id: String?
    let userId: String?
    let userName: String?
    let userAvatarUrl: String?
    let placeName: String?
    let imageUrl: String?
    let caption: String?
    let category: String?
    let likesCount: Int?
    let commentsCount: Int?
    let status: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case placeName = "place_name"
        case imageUrl = "image_url"
        case caption
        case category
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case status
        case createdAt = "created_at"
    }

    var displayLikes: Int { likesCount ?? 0 }
    var displayComments: Int { commentsCount ?? 0 }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func decodeLossyInt(_ key: CodingKeys) -> Int? {
            if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
            if let v = try? c.decodeIfPresent(Int64.self, forKey: key) { return Int(v) }
            if let v = try? c.decodeIfPresent(Double.self, forKey: key) { return Int(v) }
            if let s = try? c.decodeIfPresent(String.self, forKey: key), let v = Int(s) { return v }
            return nil
        }
        id = try? c.decodeIfPresent(String.self, forKey: .id)
        userId = try? c.decodeIfPresent(String.self, forKey: .userId)
        userName = try? c.decodeIfPresent(String.self, forKey: .userName)
        userAvatarUrl = try? c.decodeIfPresent(String.self, forKey: .userAvatarUrl)
        placeName = try? c.decodeIfPresent(String.self, forKey: .placeName)
        imageUrl = try? c.decodeIfPresent(String.self, forKey: .imageUrl)
        caption = try? c.decodeIfPresent(String.self, forKey: .caption)
        category = try? c.decodeIfPresent(String.self, forKey: .category)
        likesCount = decodeLossyInt(.likesCount)
        commentsCount = decodeLossyInt(.commentsCount)
        status = try? c.decodeIfPresent(String.self, forKey: .status)
        if let s = try? c.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = s
        } else if let n = try? c.decodeIfPresent(Int64.self, forKey: .createdAt) {
            createdAt = String(n)
        } else if let n = try? c.decodeIfPresent(Double.self, forKey: .createdAt) {
            createdAt = String(Int64(n))
        } else {
            createdAt = nil
        }
    }

    init(
        id: String?,
        userId: String?,
        userName: String?,
        userAvatarUrl: String?,
        placeName: String?,
        imageUrl: String?,
        caption: String?,
        category: String?,
        likesCount: Int?,
        commentsCount: Int?,
        status: String?,
        createdAt: String?
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatarUrl = userAvatarUrl
        self.placeName = placeName
        self.imageUrl = imageUrl
        self.caption = caption
        self.category = category
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.status = status
        self.createdAt = createdAt
    }
}

struct CommunityPostInsert: Encodable {
    let userId: String
    let userName: String
    let userAvatarUrl: String?
    let placeName: String
    let imageUrl: String?
    let caption: String
    let category: String?
    let likesCount: Int
    let commentsCount: Int
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case placeName = "place_name"
        case imageUrl = "image_url"
        case caption, category
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case createdAt = "created_at"
    }
}
