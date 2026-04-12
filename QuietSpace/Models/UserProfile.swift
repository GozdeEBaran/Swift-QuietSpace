// Nguyen Minh Triet Luu — Student ID: 101542519

import Foundation

struct UserProfile: Identifiable, Decodable {
    let id: String
    let email: String?
    let fullName: String?
    let avatarUrl: String?
    let coverImageUrl: String?
    let role: String?
    let isAdmin: Bool?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case coverImageUrl = "cover_image_url"
        case role
        case isAdmin = "is_admin"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        email = try? c.decodeIfPresent(String.self, forKey: .email)
        fullName = try? c.decodeIfPresent(String.self, forKey: .fullName)
        avatarUrl = try? c.decodeIfPresent(String.self, forKey: .avatarUrl)
        coverImageUrl = try? c.decodeIfPresent(String.self, forKey: .coverImageUrl)
        role = try? c.decodeIfPresent(String.self, forKey: .role)
        createdAt = try? c.decodeIfPresent(String.self, forKey: .createdAt)

        if let b = try? c.decodeIfPresent(Bool.self, forKey: .isAdmin) {
            isAdmin = b
        } else if let i = try? c.decodeIfPresent(Int.self, forKey: .isAdmin) {
            isAdmin = i != 0
        } else if let s = try? c.decodeIfPresent(String.self, forKey: .isAdmin) {
            isAdmin = s == "true" || s == "1"
        } else {
            isAdmin = nil
        }
    }

    var displayRole: String {
        if isAdmin == true { return "admin" }
        return role ?? "user"
    }

    var displayName: String {
        fullName ?? "Unknown User"
    }
}
