import Foundation
import Combine

/// Shared in-memory store for locations the user adds from the map or profile.
/// Injected as an EnvironmentObject so both MainPage and UserProfileView can read/write it.
final class UserAddedPlacesStore: ObservableObject {
    @Published var places: [Place] = []

    func add(_ place: Place) {
        places.append(place)
    }
}
