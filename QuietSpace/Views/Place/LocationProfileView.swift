import SwiftUI

struct LocationProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let place: Place

    private var colors: AppColors { AppColors(colorScheme) }

    // Build a Google Places photo URL when a photoReference is available.
    // Falls back to the emoji + gradient header if nil or if loading fails.
    private var photoURL: URL? {
        guard let ref = place.photoReference, !ref.isEmpty else { return nil }
        let urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=600&photo_reference=\(ref)&key=\(AppConfig.googlePlacesAPIKey)"
        return URL(string: urlString)
    }

    // Type-matched gradient colors, consistent with PlaceMarkerView
    private var headerGradient: LinearGradient {
        switch place.type {
        case "library":   return LinearGradient(colors: [.purple.opacity(0.75), .blue.opacity(0.55)],   startPoint: .topLeading, endPoint: .bottomTrailing)
        case "cafe":      return LinearGradient(colors: [.orange.opacity(0.75), .yellow.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "park":      return LinearGradient(colors: [.green.opacity(0.75), .mint.opacity(0.55)],    startPoint: .topLeading, endPoint: .bottomTrailing)
        case "museum":    return LinearGradient(colors: [.yellow.opacity(0.75), .orange.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "gallery":   return LinearGradient(colors: [.pink.opacity(0.75), .purple.opacity(0.55)],   startPoint: .topLeading, endPoint: .bottomTrailing)
        case "bookstore": return LinearGradient(colors: [.orange.opacity(0.75), .red.opacity(0.55)],    startPoint: .topLeading, endPoint: .bottomTrailing)
        case "garden":    return LinearGradient(colors: [.teal.opacity(0.75), .green.opacity(0.55)],    startPoint: .topLeading, endPoint: .bottomTrailing)
        default:          return LinearGradient(colors: [.blue.opacity(0.75), .cyan.opacity(0.55)],     startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    nameSection

                    Divider()

                    statsSection

                    Divider()

                    // Info rows — each is shown only if the field is present in the model
                    if let address = place.address {
                        infoRow(icon: "mappin.circle.fill", label: "Address", value: address)
                    }

                    infoRow(
                        icon: "location.circle.fill",
                        label: "Coordinates",
                        value: String(format: "%.4f°N, %.4f°W", place.latitude, abs(place.longitude))
                    )

                    if let phone = place.phoneNumber {
                        infoRow(icon: "phone.circle.fill", label: "Phone", value: phone)
                    }

                    if let website = place.website {
                        infoRow(icon: "globe", label: "Website", value: website)
                    }

                    if let distance = place.distance {
                        infoRow(icon: "figure.walk.circle.fill", label: "Distance", value: distance)
                    }

                    Divider()

                    // Navigates to the existing full-detail screen
                    NavigationLink(destination: PlaceDetailPage(place: place)) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("View Full Details")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(CornerRadius.md)
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

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .top) {
            if let url = photoURL {
                // Show real place photo when a Google photoReference exists
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    default:
                        // Network error or still loading — fall through to gradient
                        gradientPlaceholder
                    }
                }
            } else {
                // No photoReference available — use emoji + gradient
                gradientPlaceholder
            }

            // Back button overlaid on the header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, 60)
        }
        .frame(height: 250)
    }

    // Gradient rectangle with the place's emoji — used as a photo placeholder
    private var gradientPlaceholder: some View {
        Rectangle()
            .fill(headerGradient)
            .frame(height: 250)
            .overlay(
                Text(place.emoji)
                    .font(.system(size: 72))
            )
    }

    // MARK: - Name / Type / Status

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(place.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colors.textPrimary)

            HStack(spacing: Spacing.sm) {
                Text(place.type.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colors.primaryLight)
                    .foregroundColor(colors.primary)
                    .cornerRadius(CornerRadius.sm)

                HStack(spacing: 4) {
                    Circle()
                        .fill(place.isOpen ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(place.isOpen ? "Open" : "Closed")
                        .font(.caption)
                        .foregroundColor(place.isOpen ? .green : .red)
                }
            }
        }
    }

    // MARK: - Stats Bubbles

    private var statsSection: some View {
        // Only show the price bubble when priceLevel is present in the model
        HStack(spacing: Spacing.sm) {
            statBubble(icon: "🤫", value: String(format: "%.1f", place.quietScore), label: "Quiet Score")
            statBubble(icon: "⭐", value: String(format: "%.1f", place.rating),     label: "\(place.reviewCount) reviews")

            if let price = place.priceLevel {
                statBubble(icon: "💰", value: String(repeating: "$", count: max(1, price)), label: "Price")
            }
        }
    }

    private func statBubble(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.title2)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(colors.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.sm)
        .background(colors.surface)
        .cornerRadius(CornerRadius.md)
        .overlay(RoundedRectangle(cornerRadius: CornerRadius.md).stroke(colors.border, lineWidth: 1))
    }

    // MARK: - Info Row

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(colors.primary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(colors.textPrimary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    let sample = Place(
        id: "preview-profile",
        googlePlaceId: nil,
        name: "The Quiet Corner Cafe",
        type: "cafe",
        distance: "0.4km",
        rating: 4.7,
        reviewCount: 89,
        latitude: 43.6532,
        longitude: -79.3832,
        address: "456 Elgin St, Toronto, ON M5G 1Z1",
        isOpen: true,
        quietScore: 4.2,
        photoReference: nil,
        emoji: "☕",
        favorite: true,
        phoneNumber: "+1 (416) 555-0199",
        website: "quietcorner.ca",
        priceLevel: 2
    )

    return NavigationStack {
        LocationProfileView(place: sample)
    }
}
