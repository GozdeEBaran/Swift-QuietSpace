import Foundation
import Combine

class FavoritesViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var favorites: [Place] = []
    @Published var errorMessage: String? = nil

    // Store the userId so removeFavorite can reference it
    private var currentUserId: String?

    init() {
        // FavoritesPage calls fetchFavorites(userId:) on appear, so nothing needed here
    }

    func fetchFavorites(userId: String?) {
        guard let userId = userId else {
            favorites = []
            return
        }

        currentUserId = userId
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Fetch real favorites from the Supabase `user_favorites` table
                let rows = try await SupabaseService.shared.getFavorites(userId: userId)
                let places = rows.map { $0.toPlace() }

                await MainActor.run {
                    self.favorites = places
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Could not load favorites. Please try again."
                    self.isLoading = false
                }
            }
        }
    }

    func removeFavorite(_ place: Place) {
        // Remove from the list immediately so the UI feels instant
        favorites.removeAll { $0.id == place.id }

        // Then delete from Supabase in the background
        guard let userId = currentUserId,
              let googlePlaceId = place.googlePlaceId ?? Optional(place.id) else { return }

        Task {
            try? await SupabaseService.shared.removeFavorite(userId: userId, googlePlaceId: googlePlaceId)
        }
    }
}
