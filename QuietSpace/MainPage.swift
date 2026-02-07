// MainPage.swift
import SwiftUI
import MapKit

struct MainPage: View {
    @State private var searchText: String = ""
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        ZStack {
            // Map View - Modern iOS 17+ API
            Map(position: $position)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top search bar
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Find a space...", text: $searchText)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        // Nearby button
                        Button(action: {}) {
                            Text("Nearby")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.6, green: 0.8, blue: 0.7))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 50)
                    .padding(.bottom, 12)
                    
                    // Category chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryChip(name: "All", isSelected: true)
                            CategoryChip(name: "Libraries", isSelected: false)
                            CategoryChip(name: "Cafes", isSelected: false)
                            CategoryChip(name: "Parks", isSelected: false)
                            CategoryChip(name: "Co-working", isSelected: false)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 12)
                }
                .background(Color.white.opacity(0.95))
                
                Spacer()
                
                // Featured location card at bottom
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Location image
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Featured QuietSpaces")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text("The Quiet Corner")
                                .font(.headline)
                                .fontWeight(.semibold)
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("4.5")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("• 2.3 km away")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    
                    // Bottom navigation bar
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
                        
                        Button(action: {}) {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                                Text("Search")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                            }
                        }
                        .offset(y: -10)
                        
                        Spacer()
                        
                        Button(action: {}) {
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
                        
                        Button(action: {}) {
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
        }
        .navigationBarHidden(true)
    }
}

// Helper view for category chips
struct CategoryChip: View {
    var name: String
    var isSelected: Bool = false
    
    var body: some View {
        Text(name)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color(red: 0.6, green: 0.8, blue: 0.7) : Color.white)
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
    }
}
