// Nguyen Minh Triet Luu — Student ID: 101542519

import Foundation

struct FavoritePlace: Identifiable, Decodable {
    let id: String?
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try? c.decodeIfPresent(String.self, forKey: .id)
        userId = try? c.decodeIfPresent(String.self, forKey: .userId)
        googlePlaceId = try? c.decodeIfPresent(String.self, forKey: .googlePlaceId)
        name = try? c.decodeIfPresent(String.self, forKey: .name)
        address = try? c.decodeIfPresent(String.self, forKey: .address)
        placeType = try? c.decodeIfPresent(String.self, forKey: .placeType)
        photoReference = try? c.decodeIfPresent(String.self, forKey: .photoReference)
        if let s = try? c.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = s
        } else if let n = try? c.decodeIfPresent(Int64.self, forKey: .createdAt) {
            createdAt = String(n)
        } else {
            createdAt = nil
        }
        if let v = try? c.decodeIfPresent(Double.self, forKey: .rating) { rating = v }
        else if let v = try? c.decodeIfPresent(Int.self, forKey: .rating) { rating = Double(v) }
        else { rating = nil }
        if let v = try? c.decodeIfPresent(Int.self, forKey: .userRatingsTotal) { userRatingsTotal = v }
        else if let v = try? c.decodeIfPresent(Double.self, forKey: .userRatingsTotal) { userRatingsTotal = Int(v) }
        else { userRatingsTotal = nil }
        if let v = try? c.decodeIfPresent(Double.self, forKey: .latitude) { latitude = v }
        else { latitude = nil }
        if let v = try? c.decodeIfPresent(Double.self, forKey: .longitude) { longitude = v }
        else { longitude = nil }
        if let v = try? c.decodeIfPresent(Double.self, forKey: .quietScore) { quietScore = v }
        else if let v = try? c.decodeIfPresent(Int.self, forKey: .quietScore) { quietScore = Double(v) }
        else { quietScore = nil }
    }

    func toPlace() -> Place {
        Place(
            id: googlePlaceId ?? (id ?? "0"),
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
