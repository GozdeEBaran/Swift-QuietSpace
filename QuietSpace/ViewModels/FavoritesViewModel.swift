// Name: Gozde Baran
// Student ID: 101515982
// Contribution:
// - Replaced hardcoded dummy favorites with real Supabase fetch (getFavorites)
// - Refactored removeFavorite for optimistic UI (removes locally first, then deletes from Supabase)
// - Added errorMessage published property for UI error handling

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

    // Add a place to the local list instantly (called from PlaceDetailPage after saving)
    func addLocally(_ place: Place) {
        guard !favorites.contains(where: { $0.id == place.id }) else { return }
        favorites.insert(place, at: 0)
    }

    // Remove a place from the local list instantly (called from PlaceDetailPage after deleting)
    func removeLocally(_ place: Place) {
        favorites.removeAll { $0.id == place.id }
    }
}
