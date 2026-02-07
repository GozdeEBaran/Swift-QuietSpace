import SwiftUI
import Combine

struct PlaceCard: View {
    let place: Place
    let onPress: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    private var colors: AppColors { AppColors(colorScheme) }

    var body: some View {
        Button(action: onPress) {
            HStack(alignment: .top, spacing: 14) {
                // MARK: - Emoji Circle
                ZStack {
                    Circle()
                        .fill(colors.primaryLight)
                        .frame(width: 48, height: 48)

                    Text(place.emoji)
                        .font(.system(size: 22))
                }

                // MARK: - Place Info
                VStack(alignment: .leading, spacing: 4) {
                    // Name and distance row
                    HStack(alignment: .top) {
                        Text(place.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(colors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        // Distance badge
                        if let distance = place.distance {
                            Text(distance)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(colors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(colors.primaryLight.opacity(0.6))
                                .clipShape(Capsule())
                        }
                    }

                    // Type
                    Text(place.type.capitalized)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(colors.textSecondary)

                    // Address
                    if let address = place.address, !address.isEmpty {
                        Text(address)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(colors.textMuted)
                            .lineLimit(1)
                    }

                    // Rating and Quiet Score row
                    HStack(spacing: 12) {
                        // Star rating
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(colors.accent)

                            Text(String(format: "%.1f", place.rating))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(colors.textPrimary)

                            Text("(\(place.reviewCount))")
                                .font(.system(size: 12))
                                .foregroundStyle(colors.textMuted)
                        }

                        // Quiet score badge
                        HStack(spacing: 3) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(colors.primary)

                            Text(String(format: "%.0f", place.quietScore))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(colors.primary)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(colors.primaryLight.opacity(0.5))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
            }
            .padding(14)
            .background(colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colors.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(PlaceCardButtonStyle())
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}

// MARK: - Button Style with Scale Animation

private struct PlaceCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        PlaceCard(
            place: Place(
                id: "1",
                googlePlaceId: nil,
                name: "Central Library",
                type: "library",
                distance: "0.3 mi",
                rating: 4.5,
                reviewCount: 128,
                latitude: 0,
                longitude: 0,
                address: "123 Main St",
                isOpen: true,
                quietScore: 92,
                photoReference: nil,
                emoji: "📚",
                favorite: false,
                phoneNumber: nil,
                website: nil,
                openingHours: nil,
                reviews: nil
            ),
            onPress: {}
        )

        PlaceCard(
            place: Place(
                id: "2",
                googlePlaceId: nil,
                name: "Sunrise Park",
                type: "park",
                distance: nil,
                rating: 4.2,
                reviewCount: 56,
                latitude: 0,
                longitude: 0,
                address: nil,
                isOpen: true,
                quietScore: 85,
                photoReference: nil,
                emoji: "🌳",
                favorite: true,
                phoneNumber: nil,
                website: nil,
                openingHours: nil,
                reviews: nil
            ),
            onPress: {}
        )
    }
}
