import Foundation

struct LocationSubmission: Identifiable, Codable {
    let id: Int?
    let userId: String?
    let name: String?
    let address: String?
    let type: String?
    let description: String?
    let latitude: Double?
    let longitude: Double?
    let quietScore: Double?
    let imageUrl: String?
    let status: String?
    let adminNotes: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, address, type, description
        case latitude, longitude
        case quietScore = "quiet_score"
        case imageUrl = "image_url"
        case status
        case adminNotes = "admin_notes"
        case createdAt = "created_at"
    }

    func toPlace() -> Place {
        Place(
            id: "sub-\(id ?? 0)",
            googlePlaceId: nil,
            name: name ?? "Unknown",
            type: type ?? "place",
            distance: nil,
            rating: 0,
            reviewCount: 0,
            latitude: latitude ?? 0,
            longitude: longitude ?? 0,
            address: address,
            isOpen: true,
            quietScore: quietScore ?? 3.0,
            photoReference: nil,
            emoji: PlaceHelpers.emojiForType(type ?? "place"),
            favorite: false,
            phoneNumber: nil,
            website: nil,
            openingHours: nil,
            reviews: nil
        )
    }
}

struct LocationSubmissionInsert: Encodable {
    let userId: String
    let name: String
    let address: String
    let type: String
    let description: String
    let latitude: Double
    let longitude: Double
    let quietScore: Double?
    let imageUrl: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name, address, type, description
        case latitude, longitude
        case quietScore = "quiet_score"
        case imageUrl = "image_url"
        case status
    }
}
