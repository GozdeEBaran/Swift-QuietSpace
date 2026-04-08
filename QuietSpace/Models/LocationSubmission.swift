import Foundation

struct LocationSubmission: Identifiable, Decodable {
    let id: String?
    let userId: String?
    let name: String?
    let address: String?
    let type: String?
    let description: String?
    let latitude: Double?
    let longitude: Double?
    let quietScore: Double?
    let imageUrl: String?
    let status: String?
    let adminNotes: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, address, type, description
        case latitude, longitude
        case quietScore = "quiet_score"
        case imageUrl = "image_url"
        case status
        case adminNotes = "admin_notes"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let s = try? c.decodeIfPresent(String.self, forKey: .id) { id = s }
        else if let n = try? c.decodeIfPresent(Int.self, forKey: .id) { id = String(n) }
        else { id = nil }
        userId = try? c.decodeIfPresent(String.self, forKey: .userId)
        name = try? c.decodeIfPresent(String.self, forKey: .name)
        address = try? c.decodeIfPresent(String.self, forKey: .address)
        type = try? c.decodeIfPresent(String.self, forKey: .type)
        description = try? c.decodeIfPresent(String.self, forKey: .description)
        latitude = try? c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try? c.decodeIfPresent(Double.self, forKey: .longitude)
        imageUrl = try? c.decodeIfPresent(String.self, forKey: .imageUrl)
        status = try? c.decodeIfPresent(String.self, forKey: .status)
        adminNotes = try? c.decodeIfPresent(String.self, forKey: .adminNotes)
        if let v = try? c.decodeIfPresent(Double.self, forKey: .quietScore) { quietScore = v }
        else if let v = try? c.decodeIfPresent(Int.self, forKey: .quietScore) { quietScore = Double(v) }
        else { quietScore = nil }
        if let s = try? c.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = s
        } else if let n = try? c.decodeIfPresent(Int64.self, forKey: .createdAt) {
            createdAt = String(n)
        } else {
            createdAt = nil
        }
    }

    init(id: String?, userId: String?, name: String?, address: String?, type: String?,
         description: String?, latitude: Double?, longitude: Double?, quietScore: Double?,
         imageUrl: String?, status: String?, adminNotes: String?, createdAt: String?) {
        self.id = id; self.userId = userId; self.name = name; self.address = address
        self.type = type; self.description = description; self.latitude = latitude
        self.longitude = longitude; self.quietScore = quietScore; self.imageUrl = imageUrl
        self.status = status; self.adminNotes = adminNotes; self.createdAt = createdAt
    }

    func toPlace() -> Place {
        Place(
            id: "sub-\(id ?? "0")",
            googlePlaceId: nil,
            name: name ?? "Unknown",
            type: type ?? "place",
            distance: nil,
            rating: 0,
            reviewCount: 0,
            latitude: latitude ?? 0,
            longitude: longitude ?? 0,
            address: address,
            isOpen: true,
            quietScore: quietScore ?? 3.0,
            photoReference: nil,
            emoji: PlaceHelpers.emojiForType(type ?? "place"),
            favorite: false,
            phoneNumber: nil,
            website: nil,
            openingHours: nil,
            reviews: nil
        )
    }
}

struct LocationSubmissionAdmin: Identifiable {
    var id: String {
        let sid = submission.id ?? "noid"
        let created = submission.createdAt ?? ""
        let name = submission.name ?? ""
        return "\(sid)-\(created)-\(name)"
    }

    let submission: LocationSubmission
    let submitterName: String?
}

struct LocationSubmissionInsert: Encodable {
    let userId: String
    let name: String
    let address: String
    let type: String
    let description: String
    let latitude: Double
    let longitude: Double
    let quietScore: Double?
    let imageUrl: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name, address, type, description
        case latitude, longitude
        case quietScore = "quiet_score"
        case imageUrl = "image_url"
        case status
    }
}
