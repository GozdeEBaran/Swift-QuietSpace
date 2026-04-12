// Name: Gozde Baran
// Student ID: 101515982
// Contribution:
// - Created this file entirely
// - Implemented the in-memory ObservableObject store for user-added places
// - Used as a shared EnvironmentObject between MainPage and UserProfileView

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
