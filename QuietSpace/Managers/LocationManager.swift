import Foundation
import CoreLocation
import Combine

class LocationManager: ObservableObject {
    @Published var currentLocation: CLLocation? = nil
    
    // Simulate location for now
    init() {
        self.currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
}
