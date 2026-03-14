import SwiftUI
import MapKit

// MARK: - Colors matching React Native MapMarkers.js PLACE_ICONS

private enum PlaceMarkerColors {
    static func gradient(for type: String) -> (Color, Color) {
        switch type.lowercased() {
        case "library":   return (Color(hex: "8B5CF6"), Color(hex: "6D28D9"))
        case "cafe", "café": return (Color(hex: "D97706"), Color(hex: "B45309"))
        case "park":     return (Color(hex: "22C55E"), Color(hex: "16A34A"))
        case "museum":   return (Color(hex: "F59E0B"), Color(hex: "D97706"))
        case "gallery":  return (Color(hex: "EC4899"), Color(hex: "DB2777"))
        case "coworking": return (Color(hex: "3B82F6"), Color(hex: "2563EB"))
        case "bookstore": return (Color(hex: "F97316"), Color(hex: "EA580C"))
        case "garden":   return (Color(hex: "14B8A6"), Color(hex: "0D9488"))
        case "place", "other": return (Color(hex: "6366F1"), Color(hex: "4F46E5"))
        default:         return (Color(hex: "6366F1"), Color(hex: "4F46E5"))
        }
    }
}

// MARK: - Triangle shape for pin pointer (like RN markerPin)

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Place marker view (gradient bubble + pin + emoji, same as React Native PlaceMarker)

struct PlaceMarkerView: View {
    let place: Place
    var size: CGFloat = 36

    private var colors: (Color, Color) {
        PlaceMarkerColors.gradient(for: place.type)
    }

    var body: some View {
        VStack(spacing: -2) {
            // Bubble with gradient + emoji (matches RN LinearGradient + Ionicons; we use emoji from Place)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [colors.0, colors.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)

                Text(place.emoji)
                    .font(.system(size: size * 0.5))
            }

            // Pin pointer (triangle, darker color like RN markerPin borderTopColor)
            Triangle()
                .fill(colors.1)
                .frame(width: 16, height: 10)
                .offset(y: -2)
        }
        .animation(nil, value: place.id)
    }
}

// MARK: - Color hex helper

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    PlaceMarkerView(place: Place(
        id: "p",
        googlePlaceId: nil,
        name: "Library",
        type: "library",
        distance: nil,
        rating: 4.5,
        reviewCount: 100,
        latitude: 0,
        longitude: 0,
        address: nil,
        isOpen: true,
        quietScore: 4,
        photoReference: nil,
        emoji: "📚",
        favorite: false,
        phoneNumber: nil,
        website: nil,
        openingHours: nil,
        reviews: nil
    ))
}
