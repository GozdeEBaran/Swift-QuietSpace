//
//  NavBar.swift
//  QuietSpace
//
//  Created by Nadiia on 2026-02-08.
//

import SwiftUI

struct NavBar: View {
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                    Text("Home")
                        .font(.caption2)
                        .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                }
            }
            
            Spacer()
            
            NavigationLink(destination: SearchPage()) {
                VStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("Search")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Community/Post Button
            NavigationLink(destination: CommunityPage()) {
                VStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                }
            }
            .offset(y: -10)
            
            Spacer()
            
            NavigationLink(destination: FavoritesPage()) {
                VStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("Saved")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            NavigationLink(destination: UserProfile()) {
                VStack(spacing: 4) {
                    Image(systemName: "person")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("Profile")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

#Preview {
    NavBar()
}
