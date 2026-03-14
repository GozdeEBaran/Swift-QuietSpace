import Foundation

struct PostComment: Identifiable, Codable {
    let id: Int?
    let postId: Int?
    let userId: String?
    let userName: String?
    let userAvatarUrl: String?
    let comment: String?
    let rating: Int?
    let likesCount: Int?
    let parentCommentId: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case comment
        case rating
        case likesCount = "likes_count"
        case parentCommentId = "parent_comment_id"
        case createdAt = "created_at"
    }

    var displayLikes: Int { likesCount ?? 0 }
}

struct PostCommentInsert: Encodable {
    let postId: Int
    let userId: String
    let userName: String
    let userAvatarUrl: String?
    let comment: String
    let rating: Int
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case comment, rating
        case createdAt = "created_at"
    }
}

struct ReplyInsert: Encodable {
    let postId: Int
    let parentCommentId: Int
    let userId: String
    let userName: String
    let userAvatarUrl: String?
    let comment: String
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case parentCommentId = "parent_comment_id"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case comment
        case createdAt = "created_at"
    }
}
