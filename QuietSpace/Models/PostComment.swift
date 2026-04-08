import Foundation

struct PostComment: Identifiable, Decodable {
    let id: String?
    let postId: String?
    let userId: String?
    let userName: String?
    let userAvatarUrl: String?
    let comment: String?
    let rating: Int?
    let likesCount: Int?
    let parentCommentId: String?
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
        postId = try? c.decodeIfPresent(String.self, forKey: .postId)
        userId = try? c.decodeIfPresent(String.self, forKey: .userId)
        userName = try? c.decodeIfPresent(String.self, forKey: .userName)
        userAvatarUrl = try? c.decodeIfPresent(String.self, forKey: .userAvatarUrl)
        comment = try? c.decodeIfPresent(String.self, forKey: .comment)
        rating = decodeLossyInt(.rating)
        likesCount = decodeLossyInt(.likesCount)
        parentCommentId = try? c.decodeIfPresent(String.self, forKey: .parentCommentId)
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
}

struct PostCommentInsert: Encodable {
    let postId: String
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
    let postId: String
    let parentCommentId: String
    let userId: String
    let userName: String
    let userAvatarUrl: String?
    let comment: String
    let rating: Int
    let createdAt: Int64

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case parentCommentId = "parent_comment_id"
        case userId = "user_id"
        case userName = "user_name"
        case userAvatarUrl = "user_avatar_url"
        case comment
        case rating
        case createdAt = "created_at"
    }
}
