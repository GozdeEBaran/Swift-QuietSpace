import Foundation

struct PostLike: Identifiable, Codable {
    let id: Int?
    let postId: Int?
    let userId: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct CommentLike: Identifiable, Codable {
    let id: Int?
    let commentId: Int?
    let userId: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case commentId = "comment_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
