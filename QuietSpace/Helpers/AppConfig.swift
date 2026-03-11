import Foundation

struct AppConfig {
    static let supabaseURL: URL = URL(string: Secrets.supabaseURL)!

    static let supabaseAnonKey: String = Secrets.supabaseAnonKey

    static let googlePlacesAPIKey: String = Secrets.googlePlacesAPIKey

    static let defaultLatitude: Double = 43.6532
    static let defaultLongitude: Double = -79.3832

    static let defaultSearchRadiusMeters: Int = 5_000
    static let maxSearchResults: Int = 20

    static let quietSpaceCategories = [
        "Libraries", "Parks", "Cafes", "Museums",
        "Galleries", "Wellness", "Spiritual", "Study Spaces"
    ]

    static let categoryIcons: [String: String] = [
        "Libraries": "📚",
        "Parks": "🌳",
        "Cafes": "☕",
        "Museums": "🏛️",
        "Galleries": "🎨",
        "Wellness": "🧘",
        "Spiritual": "🕯️",
        "Study Spaces": "📖"
    ]
}
