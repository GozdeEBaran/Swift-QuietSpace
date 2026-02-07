import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var hasSearched = false
    @Published var searchResults: [Place] = []
    @Published var featuredPlaces: [Place] = []
    
    static let suggestedSearches = ["Libraries", "Parks", "Study Spots", "Coffee Shops"]
    
    struct Category: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
    }
    
    static let categories = [
        Category(label: "Libraries", icon: "📚"),
        Category(label: "Cafes", icon: "☕️"),
        Category(label: "Parks", icon: "🌳"),
        Category(label: "Museums", icon: "🏛️")
    ]
    
    init() {
        // Load some dummy featured places
        self.featuredPlaces = [
            Place(id: "1", googlePlaceId: nil, name: "Central Library", type: "library", distance: "0.3 mi", rating: 4.5, reviewCount: 128, latitude: 0, longitude: 0, address: "123 Main St", isOpen: true, quietScore: 92, photoReference: nil, emoji: "📚", favorite: false, phoneNumber: nil, website: nil, openingHours: nil, reviews: nil),
            Place(id: "2", googlePlaceId: nil, name: "Sunrise Park", type: "park", distance: "0.5 mi", rating: 4.2, reviewCount: 56, latitude: 0, longitude: 0, address: "Park Ave", isOpen: true, quietScore: 85, photoReference: nil, emoji: "🌳", favorite: true, phoneNumber: nil, website: nil, openingHours: nil, reviews: nil)
        ]
    }
    
    func search(query: String, location: Any?) {
        isLoading = true
        hasSearched = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            // Dummy logic: return random subset of featured places or new ones based on query
            if query.lowercased().contains("library") {
                self.searchResults = [self.featuredPlaces[0]]
            } else if query.lowercased().contains("park") {
                self.searchResults = [self.featuredPlaces[1]]
            } else {
                self.searchResults = self.featuredPlaces
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
        hasSearched = false
        searchResults = []
    }
    
    func loadFeaturedPlaces(location: Any?) {
        // Already loaded in init for now
    }
    
    // Helper to match the view's expectation if needed
    @Published var searchText = ""
}
