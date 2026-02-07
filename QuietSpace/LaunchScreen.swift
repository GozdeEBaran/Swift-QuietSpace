// LaunchScreen.swift
import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App logo
            Image(systemName: "location.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.6))
            
            // App title and tagline
            Text("QuietSpace")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Find Your Focus")
                .font(.title3)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Developer/Team credit
            VStack(spacing: 8) {
                Text("Group 33:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Felix")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Gozde")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Daniel")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Decorative line
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray.opacity(0.3))
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
            
            // Continue button navigates to BeginPage
            NavigationLink(destination: BeginPage()) {
                Text("Continue to the app")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.6, green: 0.8, blue: 0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Bottom tagline
            Text("Discover Your Next Productive Space")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer(minLength: 20)
        }
        .padding()
        .background(Color.white)
        .navigationBarHidden(true)
    }
}
