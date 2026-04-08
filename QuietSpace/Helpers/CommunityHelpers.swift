import Foundation

enum CommunityHelpers {
    static func categoryEmoji(for category: String?) -> String {
        let c = (category ?? "").lowercased()
        switch c {
        case "food": return "🍽️"
        case "drink": return "☕"
        case "atmosphere": return "✨"
        case "environment": return "🌿"
        case "libraries": return "📚"
        case "parks": return "🌳"
        case "cafes": return "☕"
        case "museums": return "🏛️"
        default: return "📍"
        }
    }

    static func timeAgo(from raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "recently" }
        let date: Date?
        if let ms = Int64(raw) {
            date = Date(timeIntervalSince1970: TimeInterval(ms) / 1000)
        } else if let n = Double(raw), n > 1_000_000_000_000 {
            date = Date(timeIntervalSince1970: n / 1000)
        } else {
            let iso = ISO8601DateFormatter()
            date = iso.date(from: raw)
        }
        guard let date else { return "recently" }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    static func displayName(from profile: UserProfile?, email: String?) -> String {
        if let n = profile?.fullName, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return n
        }
        if let e = email, let at = e.firstIndex(of: "@") {
            return String(e[..<at])
        }
        return "User"
    }
}
