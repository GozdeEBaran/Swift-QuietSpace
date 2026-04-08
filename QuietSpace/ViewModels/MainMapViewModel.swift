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

    @Published var transitStops: [TransitStop] = []

    enum Category: String, CaseIterable, Identifiable {
        case all, library, park, cafe, museum
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "All"
            case .library: return "Libraries"
            case .park: return "Parks"
            case .cafe: return "Cafés"
            case .museum: return "Museums"
            }
        }
    }

    func loadQuietSpaces(
        around coordinate: CLLocationCoordinate2D,
        radiusMeters: Int,
        category: Category,
        showCommunityPlaces: Bool
    ) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let resolvedType: String? = (category == .all) ? nil : category.rawValue

                var combined = try await GooglePlacesService.shared.searchNearby(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radius: radiusMeters,
                    type: resolvedType
                )

                if showCommunityPlaces {
                    let approvedSubmissions = try await SupabaseService.shared.getApprovedSubmissions()
                    let communityPlaces = approvedSubmissions
                        .filter { sub in
                            guard let lat = sub.latitude, let lng = sub.longitude else { return false }
                            let distance = haversineMeters(
                                a: coordinate,
                                b: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                            )
                            return distance <= Double(radiusMeters)
                        }
                        .map { $0.toPlace() }
                    combined.append(contentsOf: communityPlaces)
                }

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

    func loadTransitStops(around coordinate: CLLocationCoordinate2D, radiusMeters: Int) {
        Task {
            do {
                let stops = try await GooglePlacesService.shared.searchTransitStops(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    radius: radiusMeters
                )
                await MainActor.run { self.transitStops = stops }
            } catch {
                await MainActor.run { self.transitStops = [] }
            }
        }
    }

    private func haversineMeters(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Double {
        let earthRadiusM = 6_371_000.0
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let x = sin(dLat / 2) * sin(dLat / 2)
            + sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2)
        let c = 2 * atan2(sqrt(x), sqrt(1 - x))
        return earthRadiusM * c
    }
}

