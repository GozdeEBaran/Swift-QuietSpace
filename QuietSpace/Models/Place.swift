import Foundation

struct Review: Identifiable, Hashable {
    let id = UUID()
    let authorName: String
    let rating: Int
    let text: String
}

struct Place: Identifiable {
    let id: String
    let googlePlaceId: String?
    let name: String
    let type: String
    let distance: String?
    let rating: Double
    let reviewCount: Int
    let latitude: Double
    let longitude: Double
    let address: String?
    let isOpen: Bool
    let quietScore: Double
    let photoReference: String?
    let emoji: String
    let favorite: Bool
    let phoneNumber: String?
    let website: String?
    let openingHours: [String]?
    let reviews: [Review]?
    let priceLevel: Int?

    init(
        id: String,
        googlePlaceId: String?,
        name: String,
        type: String,
        distance: String?,
        rating: Double,
        reviewCount: Int,
        latitude: Double,
        longitude: Double,
        address: String?,
        isOpen: Bool,
        quietScore: Double,
        photoReference: String?,
        emoji: String,
        favorite: Bool,
        phoneNumber: String? = nil,
        website: String? = nil,
        openingHours: [String]? = nil,
        reviews: [Review]? = nil,
        priceLevel: Int? = nil
    ) {
        self.id = id
        self.googlePlaceId = googlePlaceId
        self.name = name
        self.type = type
        self.distance = distance
        self.rating = rating
        self.reviewCount = reviewCount
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.isOpen = isOpen
        self.quietScore = quietScore
        self.photoReference = photoReference
        self.emoji = emoji
        self.favorite = favorite
        self.phoneNumber = phoneNumber
        self.website = website
        self.openingHours = openingHours
        self.reviews = reviews
        self.priceLevel = priceLevel
    }
}

struct TransitStop: Identifiable {
    let id: String
    let googlePlaceId: String
    let name: String
    let transitType: String
    let distance: String
    let latitude: Double
    let longitude: Double
    let address: String?
}

enum PlaceHelpers {
    static func emojiForType(_ type: String) -> String {
        switch type {
        case "library":   return "📚"
        case "park":      return "🌳"
        case "cafe":      return "☕"
        case "museum":    return "🏛️"
        case "gallery":   return "🎨"
        case "bookstore": return "📖"
        case "garden":    return "🌿"
        default:          return "📍"
        }
    }

    static func primaryType(from types: [String]) -> String {
        let priority = ["library", "park", "cafe", "museum", "art_gallery", "book_store"]
        for p in priority {
            if types.contains(p) {
                if p == "art_gallery" { return "gallery" }
                if p == "book_store" { return "bookstore" }
                return p
            }
        }
        return "place"
    }

    static func estimatedQuietScore(for type: String, rating: Double?) -> Double {
        let baseScores: [String: Double] = [
            "library": 4.5, "park": 3.5, "cafe": 2.5,
            "museum": 4.0, "gallery": 4.0, "bookstore": 4.0, "garden": 4.0
        ]
        let base = baseScores[type] ?? 3.0
        let bonus = (rating ?? 3.0 - 3.0) * 0.2
        return min(5, max(1, base + bonus))
    }

    static func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6_371.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    static func formatDistance(_ km: Double) -> String {
        if km < 1 { return "\(Int(km * 1000))m" }
        return String(format: "%.1fkm", km)
    }
}
