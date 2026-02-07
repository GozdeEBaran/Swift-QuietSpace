// QuietSpaceApp.swift
// Main entry point setting up NavigationStack with LaunchScreen as the initial view.
import SwiftUI

@main
struct QuietSpaceApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                LaunchScreen()
            }
        }
    }
}
