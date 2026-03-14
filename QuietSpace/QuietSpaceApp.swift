// QuietSpaceApp.swift
// Main entry point setting up NavigationStack with LaunchScreen as the initial view.
import SwiftUI

@main
struct QuietSpaceApp: App {
    @StateObject private var auth = AuthStore()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if auth.isLoggedIn {
                    MainPage()
                } else {
                    LoginPage()
                }
            }
            .environmentObject(auth)
            
            
        }
    }
}
