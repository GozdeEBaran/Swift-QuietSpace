import Foundation
import CoreLocation
import Combine

/// View model that loads all quiet spaces to show on the main map.
/// It combines:
/// - Nearby quiet Google Places (libraries, parks, cafes, museums, etc.)
/// - Approved user-submitted locations from Supabase (`location_submissions`)
class MainMapViewModel: ObservableObject {
    @Published var places: [Place] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func loadAllQuietSpaces(around coordinate: CLLocationCoordinate2D) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // 1. Google Places (nearby quiet categories)
                let googlePlaces = try await GooglePlacesService.shared.searchNearby(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radius: AppConfig.defaultSearchRadiusMeters,
                    type: nil
                )

                // 2. Approved user submissions from Supabase
                let approvedSubmissions = try await SupabaseService.shared.getApprovedSubmissions()
                let submissionPlaces = approvedSubmissions.map { $0.toPlace() }

                let combined = googlePlaces + submissionPlaces

                await MainActor.run {
                    self.places = combined
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

