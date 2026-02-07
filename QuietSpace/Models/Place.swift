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
}
