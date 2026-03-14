import Foundation

struct CheckIn: Identifiable, Codable {
    let id: Int?
    let userId: String?
    let userName: String?
    let placeId: String?
    let placeName: String?
    let placeType: String?
    let latitude: Double?
    let longitude: Double?
    let noiseLevel: String?
    let busyness: String?
    let wifiQuality: String?
    let outlets: String?
    let note: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case placeId = "place_id"
        case placeName = "place_name"
        case placeType = "place_type"
        case latitude, longitude
        case noiseLevel = "noise_level"
        case busyness
        case wifiQuality = "wifi_quality"
        case outlets, note
        case createdAt = "created_at"
    }
}

struct CheckInInsert: Encodable {
    let userId: String
    let userName: String
    let placeId: String
    let placeName: String
    let placeType: String?
    let latitude: Double
    let longitude: Double
    let noiseLevel: String
    let busyness: String
    let wifiQuality: String
    let outlets: String
    let note: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case placeId = "place_id"
        case placeName = "place_name"
        case placeType = "place_type"
        case latitude, longitude
        case noiseLevel = "noise_level"
        case busyness
        case wifiQuality = "wifi_quality"
        case outlets, note
        case createdAt = "created_at"
    }
}
