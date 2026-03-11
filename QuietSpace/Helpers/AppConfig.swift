import Foundation

struct AppConfig {
    static let supabaseURL: URL = URL(string: "REMOVED_SUPABASE_URL")!

    static let supabaseAnonKey: String = "REMOVED_SUPABASE_KEY"

    static let googlePlacesAPIKey: String = "REMOVED_GOOGLE_KEY"

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
