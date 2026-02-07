import Foundation
import Combine

class FavoritesViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var favorites: [Place] = []
    
    init() {
        fetchFavorites(userId: nil)
    }
    
    func fetchFavorites(userId: String?) {
        isLoading = true
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.favorites = [
                Place(id: "2", googlePlaceId: nil, name: "Sunrise Park", type: "park", distance: "0.5 mi", rating: 4.2, reviewCount: 56, latitude: 0, longitude: 0, address: "Park Ave", isOpen: true, quietScore: 85, photoReference: nil, emoji: "🌳", favorite: true, phoneNumber: nil, website: nil, openingHours: nil, reviews: nil),
                Place(id: "3", googlePlaceId: nil, name: "Quiet Cafe", type: "cafe", distance: "1.2 mi", rating: 4.8, reviewCount: 42, latitude: 0, longitude: 0, address: "456 Elm St", isOpen: true, quietScore: 88, photoReference: nil, emoji: "☕️", favorite: true, phoneNumber: nil, website: nil, openingHours: nil, reviews: nil)
            ]
        }
    }
    
    func removeFavorite(_ place: Place) {
        if let index = favorites.firstIndex(where: { $0.id == place.id }) {
            favorites.remove(at: index)
        }
    }
}
