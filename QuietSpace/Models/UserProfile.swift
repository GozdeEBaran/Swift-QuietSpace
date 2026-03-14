import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let email: String?
    let fullName: String?
    let avatarUrl: String?
    let role: String?
    let isAdmin: Bool?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case role
        case isAdmin = "is_admin"
        case createdAt = "created_at"
    }

    var displayRole: String {
        if isAdmin == true { return "admin" }
        return role ?? "user"
    }

    var displayName: String {
        fullName ?? "Unknown User"
    }
}
