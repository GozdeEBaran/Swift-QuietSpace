// QuietSpaceApp.swift
// Main entry point setting up NavigationStack with LaunchScreen as the initial view.
import SwiftUI

@main
struct QuietSpaceApp: App {
    @StateObject private var auth = AuthStore()
    @StateObject private var favoritesVM = FavoritesViewModel()  // Shared across all views
    @StateObject private var placesStore = UserAddedPlacesStore() // Shared user-added locations

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if auth.isLoggedIn {
                    MainPage()
                } else {
                    LoginPage()
                }
            }
            .id(auth.isLoggedIn) // forces full stack reset on sign-in / sign-out
            .environmentObject(auth)
            .environmentObject(favoritesVM)
            .environmentObject(placesStore)
            
            
        }
    }
}
