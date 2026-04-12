// Nguyen Minh Triet Luu — Student ID: 101542519

import Foundation

struct PostLike: Identifiable, Codable {
    let id: String?
    let postId: String?
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
    let id: String?
    let commentId: String?
    let userId: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case commentId = "comment_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
