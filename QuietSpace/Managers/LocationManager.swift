import Foundation
import CoreLocation
import Combine

/// Publishes a usable location for the map: prefers live GPS when allowed, otherwise a safe default.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?

    private let manager = CLLocationManager()

    /// Default used before the first GPS fix and when the user has not granted location access.
    private static var fallbackLocation: CLLocation {
        CLLocation(latitude: AppConfig.defaultLatitude, longitude: AppConfig.defaultLongitude)
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        currentLocation = Self.fallbackLocation
    }

    /// Call once (e.g. from the main map) to request permission and start updates.
    func startIfNeeded() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        currentLocation = loc
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if currentLocation == nil {
            currentLocation = Self.fallbackLocation
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            if currentLocation == nil {
                currentLocation = Self.fallbackLocation
            }
        default:
            break
        }
    }
}
