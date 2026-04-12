// Nguyen Minh Triet Luu — Student ID: 101542519

import Foundation

struct CheckIn: Identifiable, Decodable {
    let id: String?
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try? c.decodeIfPresent(String.self, forKey: .id)
        userId = try? c.decodeIfPresent(String.self, forKey: .userId)
        userName = try? c.decodeIfPresent(String.self, forKey: .userName)
        placeId = try? c.decodeIfPresent(String.self, forKey: .placeId)
        placeName = try? c.decodeIfPresent(String.self, forKey: .placeName)
        placeType = try? c.decodeIfPresent(String.self, forKey: .placeType)
        latitude = try? c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try? c.decodeIfPresent(Double.self, forKey: .longitude)
        noiseLevel = try? c.decodeIfPresent(String.self, forKey: .noiseLevel)
        busyness = try? c.decodeIfPresent(String.self, forKey: .busyness)
        wifiQuality = try? c.decodeIfPresent(String.self, forKey: .wifiQuality)
        outlets = try? c.decodeIfPresent(String.self, forKey: .outlets)
        note = try? c.decodeIfPresent(String.self, forKey: .note)
        if let s = try? c.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = s
        } else if let n = try? c.decodeIfPresent(Int64.self, forKey: .createdAt) {
            createdAt = String(n)
        } else {
            createdAt = nil
        }
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
