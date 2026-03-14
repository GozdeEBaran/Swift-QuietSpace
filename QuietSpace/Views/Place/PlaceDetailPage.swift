import SwiftUI
import MapKit

struct PlaceDetailPage: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    private var colors: AppColors { AppColors(colorScheme) }
    
    // The place to display. This is injected from navigation (search, favorites, etc.).
    @State private var place: Place
    
    @State private var mapRegion: MKCoordinateRegion
    
    init(place: Place) {
        _place = State(initialValue: place)
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Image Header
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(colors.primaryLight)
                        .frame(height: 250)
                        .overlay(
                            Text(place.emoji)
                                .font(.system(size: 80))
                        )
                    
                    // Header Buttons
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(colors.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button {
                            // Toggle favorite logic would go here
                        } label: {
                            Image(systemName: place.favorite ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundColor(place.favorite ? colors.error : colors.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(.thinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, 60) // Adjust for safe area
                }
                
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Title & Type
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(place.type.capitalized)
                            .font(.body)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    // Stats Row
                    HStack(spacing: Spacing.md) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                            Text("\(String(format: "%.1f", place.rating)) (\(place.reviewCount))")
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        HStack(spacing: 4) {
                            Text("🤫 Quiet Score:")
                                .foregroundColor(colors.textSecondary)
                            Text("\(Int(place.quietScore))")
                                .fontWeight(.semibold)
                                .foregroundColor(colors.primary)
                        }
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(place.isOpen ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(place.isOpen ? "Open" : "Closed")
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.bottom, Spacing.md)
                    .overlay(Divider(), alignment: .bottom)
                    
                    // Address
                    if let address = place.address {
                        detailSection(icon: "location.fill", title: "Address") {
                            Text(address)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                    
                    // Contact
                    if place.phoneNumber != nil || place.website != nil {
                        detailSection(icon: "phone.fill", title: "Contact") {
                            HStack(spacing: Spacing.md) {
                                if let phone = place.phoneNumber {
                                    Button {
                                        // Call action
                                    } label: {
                                        HStack {
                                            Image(systemName: "phone")
                                            Text(phone)
                                        }
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(colors.primaryLight)
                                        .foregroundColor(colors.primary)
                                        .cornerRadius(CornerRadius.md)
                                    }
                                }
                                
                                if place.website != nil {
                                    Button {
                                        // Open website action
                                    } label: {
                                        HStack {
                                            Image(systemName: "globe")
                                            Text("Website")
                                        }
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(colors.primaryLight)
                                        .foregroundColor(colors.primary)
                                        .cornerRadius(CornerRadius.md)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Opening Hours
                    if let hours = place.openingHours {
                        detailSection(icon: "clock.fill", title: "Opening Hours") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(hours, id: \.self) { hour in
                                    Text(hour)
                                        .foregroundColor(colors.textSecondary)
                                }
                            }
                        }
                    }
                    
                    // Map
                    detailSection(icon: "map.fill", title: "Location") {
                        Map(coordinateRegion: $mapRegion, annotationItems: [place]) { place in
                            MapMarker(coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), tint: .blue)
                        }
                        .frame(height: 200)
                        .cornerRadius(CornerRadius.md)
                        .disabled(true) // Disable interaction for dummy view
                    }
                    
                    // Action Buttons
                    VStack(spacing: Spacing.sm) {
                        NavigationLink(destination: CheckInPage(placeName: place.name)) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Check In")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colors.accent)
                            .foregroundColor(.white)
                            .cornerRadius(CornerRadius.md)
                        }
                        
                        Button {
                            // Get Directions action
                        } label: {
                            Text("Get Directions")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(CornerRadius.md)
                        }
                    }
                    .padding(.top, Spacing.md)
                    
                    // Reviews
                    if let reviews = place.reviews {
                        detailSection(icon: "bubble.left.and.bubble.right.fill", title: "Reviews") {
                            VStack(spacing: Spacing.md) {
                                ForEach(reviews) { review in
                                    VStack(alignment: .leading, spacing: Spacing.xs) {
                                        HStack {
                                            Text(review.authorName)
                                                .fontWeight(.semibold)
                                                .foregroundColor(colors.textPrimary)
                                            Spacer()
                                            HStack(spacing: 2) {
                                                ForEach(0..<5) { index in
                                                    Image(systemName: index < review.rating ? "star.fill" : "star")
                                                        .font(.caption)
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                        }
                                        Text(review.text)
                                            .font(.subheadline)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    .padding()
                                    .background(colors.surface)
                                    .cornerRadius(CornerRadius.md)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .stroke(colors.border, lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(Spacing.lg)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(colors.background)
        .navigationBarHidden(true)
    }
    
    // Helper View Builder for Sections
    private func detailSection<Content: View>(icon: String, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(colors.primary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(colors.textPrimary)
            }
            content()
        }
    }
}


#Preview {
    let sample = Place(
        id: "preview",
        googlePlaceId: nil,
        name: "Preview Library",
        type: "library",
        distance: "0.3km",
        rating: 4.5,
        reviewCount: 120,
        latitude: 43.6532,
        longitude: -79.3832,
        address: "123 Main St",
        isOpen: true,
        quietScore: 4.5,
        photoReference: nil,
        emoji: "📚",
        favorite: false,
        phoneNumber: nil,
        website: nil,
        openingHours: nil,
        reviews: nil
    )
    
    return NavigationStack {
        PlaceDetailPage(place: sample)
    }
}
