// QuietSpaceApp.swift
// Main entry point setting up NavigationStack with LaunchScreen as the initial view.
import SwiftUI

@main
struct QuietSpaceApp: App {
    @StateObject private var auth = AuthStore()
    @StateObject private var favoritesVM = FavoritesViewModel()
    @StateObject private var placesStore = UserAddedPlacesStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if auth.isLoading {
                    ProgressView("Loading...")
                } else if auth.isLoggedIn {
                    MainPage()
                } else {
                    LoginPage()
                }
            }
            .id(auth.isLoggedIn)
            .environmentObject(auth)
            .environmentObject(favoritesVM)
            .environmentObject(placesStore)
        }
    }
}
