import Foundation

struct FavoritePlace: Identifiable, Codable {
    let id: Int?
    let userId: String?
    let googlePlaceId: String?
    let name: String?
    let address: String?
    let rating: Double?
    let userRatingsTotal: Int?
    let latitude: Double?
    let longitude: Double?
    let placeType: String?
    let quietScore: Double?
    let photoReference: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case googlePlaceId = "google_place_id"
        case name
        case address
        case rating
        case userRatingsTotal = "user_ratings_total"
        case latitude
        case longitude
        case placeType = "place_type"
        case quietScore = "quiet_score"
        case photoReference = "photo_reference"
        case createdAt = "created_at"
    }

    func toPlace() -> Place {
        Place(
            id: googlePlaceId ?? "\(id ?? 0)",
            googlePlaceId: googlePlaceId,
            name: name ?? "Unknown",
            type: placeType ?? "place",
            distance: nil,
            rating: rating ?? 0,
            reviewCount: userRatingsTotal ?? 0,
            latitude: latitude ?? 0,
            longitude: longitude ?? 0,
            address: address,
            isOpen: true,
            quietScore: quietScore ?? 3.0,
            photoReference: photoReference,
            emoji: PlaceHelpers.emojiForType(placeType ?? "place"),
            favorite: true,
            phoneNumber: nil,
            website: nil,
            openingHours: nil,
            reviews: nil
        )
    }
}

struct FavoritePlaceInsert: Encodable {
    let userId: String
    let googlePlaceId: String
    let name: String?
    let address: String?
    let rating: Double?
    let userRatingsTotal: Int?
    let latitude: Double?
    let longitude: Double?
    let placeType: String?
    let quietScore: Double?
    let photoReference: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case googlePlaceId = "google_place_id"
        case name, address, rating
        case userRatingsTotal = "user_ratings_total"
        case latitude, longitude
        case placeType = "place_type"
        case quietScore = "quiet_score"
        case photoReference = "photo_reference"
    }
}
