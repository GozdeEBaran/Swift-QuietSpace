import Foundation

struct CommunityPost: Identifiable, Codable {
    let id: Int?
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
