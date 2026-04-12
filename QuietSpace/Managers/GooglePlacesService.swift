// Nguyen Minh Triet Luu — Student ID: 101542519

import Foundation
import CoreLocation

/// Complete Google Places service mirroring the React Native GooglePlacesService.
/// Uses the same API key and endpoints so both apps return identical data.
final class GooglePlacesService {
    static let shared = GooglePlacesService()

    private let session = URLSession(configuration: .default)
    private let baseURL = URL(string: "https://maps.googleapis.com/maps/api/place")!
    private let apiKey = AppConfig.googlePlacesAPIKey

    private let quietPlaceTypes: [String: [String]] = [
        "library": ["library"],
        "park": ["park"],
        "cafe": ["cafe"],
        "museum": ["museum", "art_gallery"],
        "bookstore": ["book_store"],
        "garden": ["park", "tourist_attraction"],
        "coworking": ["establishment"]
    ]

    private let transitTypes = ["subway_station", "transit_station", "bus_station", "light_rail_station"]

    private init() {}

    // MARK: - Nearby Search

    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int = 5_000,
        type: String? = nil
    ) async throws -> [Place] {
        let types: [String]
        if let t = type, let mapped = quietPlaceTypes[t] {
            types = mapped
        } else if let t = type {
            types = [t]
        } else {
            types = ["library", "park", "cafe", "museum"]
        }

        var allResults: [GooglePlaceDTO] = []
        try await withThrowingTaskGroup(of: [GooglePlaceDTO].self) { group in
            for placeType in types {
                group.addTask {
                    try await self.fetchNearby(lat: latitude, lng: longitude, radius: radius, type: placeType)
                }
            }
            for try await batch in group { allResults.append(contentsOf: batch) }
        }

        let unique = Dictionary(grouping: allResults, by: { $0.place_id })
            .compactMapValues { $0.first }
            .values

        var places = unique.prefix(80).map { $0.toPlace(userLat: latitude, userLng: longitude) }
        places.sort { (PlaceHelpers.parseDistance($0.distance) ?? 999) < (PlaceHelpers.parseDistance($1.distance) ?? 999) }
        return Array(places)
    }

    // MARK: - Text Search

    func searchByText(query: String, latitude: Double, longitude: Double) async throws -> [Place] {
        var comp = URLComponents(url: baseURL.appendingPathComponent("textsearch/json"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "10000"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let url = comp.url else { return [] }
        let (data, _) = try await session.data(from: url)
        let resp = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
        guard resp.status == "OK" else { return [] }
        return resp.results.map { $0.toPlace(userLat: latitude, userLng: longitude) }
    }

    // MARK: - Autocomplete

    struct AutocompletePrediction {
        let placeId: String
        let description: String
        let mainText: String
        let secondaryText: String
    }

    func autocomplete(query: String, latitude: Double, longitude: Double) async throws -> [AutocompletePrediction] {
        guard query.count >= 2 else { return [] }
        var comp = URLComponents(url: baseURL.appendingPathComponent("autocomplete/json"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [
            URLQueryItem(name: "input", value: query),
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "10000"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let url = comp.url else { return [] }
        let (data, _) = try await session.data(from: url)
        let resp = try JSONDecoder().decode(AutocompleteResponse.self, from: data)
        guard resp.status == "OK" else { return [] }
        return resp.predictions.map { p in
            AutocompletePrediction(
                placeId: p.place_id,
                description: p.description,
                mainText: p.structured_formatting?.main_text ?? p.description,
                secondaryText: p.structured_formatting?.secondary_text ?? ""
            )
        }
    }

    // MARK: - Place Details

    func getPlaceDetails(placeId: String) async throws -> Place? {
        var comp = URLComponents(url: baseURL.appendingPathComponent("details/json"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "name,formatted_address,formatted_phone_number,website,opening_hours,rating,user_ratings_total,price_level,geometry,types,photos,reviews"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let url = comp.url else { return nil }
        let (data, _) = try await session.data(from: url)
        let resp = try JSONDecoder().decode(DetailsResponse.self, from: data)
        guard resp.status == "OK", let r = resp.result else { return nil }
        return r.toDetailedPlace()
    }

    // MARK: - Photo URL

    func photoURL(reference: String, maxWidth: Int = 400) -> URL? {
        var comp = URLComponents(url: baseURL.appendingPathComponent("photo"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [
            URLQueryItem(name: "maxwidth", value: "\(maxWidth)"),
            URLQueryItem(name: "photo_reference", value: reference),
            URLQueryItem(name: "key", value: apiKey)
        ]
        return comp.url
    }

    // MARK: - Transit Stops

    func searchTransitStops(latitude: Double, longitude: Double, radius: Int = 2_000) async throws -> [TransitStop] {
        var allResults: [GooglePlaceDTO] = []
        try await withThrowingTaskGroup(of: [GooglePlaceDTO].self) { group in
            for tt in transitTypes {
                group.addTask {
                    try await self.fetchNearby(lat: latitude, lng: longitude, radius: radius, type: tt)
                }
            }
            for try await batch in group { allResults.append(contentsOf: batch) }
        }

        let unique = Dictionary(grouping: allResults, by: { $0.place_id })
            .compactMapValues { $0.first }.values

        var stops = unique.map { $0.toTransitStop(userLat: latitude, userLng: longitude) }
        stops.sort { (PlaceHelpers.parseDistance($0.distance) ?? 999) < (PlaceHelpers.parseDistance($1.distance) ?? 999) }
        return stops
    }

    // MARK: - Internal fetch

    private func fetchNearby(lat: Double, lng: Double, radius: Int, type: String) async throws -> [GooglePlaceDTO] {
        var comp = URLComponents(url: baseURL.appendingPathComponent("nearbysearch/json"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [
            URLQueryItem(name: "location", value: "\(lat),\(lng)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "key", value: apiKey)
        ]
        guard let url = comp.url else { return [] }
        let (data, _) = try await session.data(from: url)
        let resp = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
        guard resp.status == "OK" else { return [] }
        return resp.results
    }
}

// MARK: - Response DTOs

private struct GoogleSearchResponse: Decodable {
    let status: String
    let results: [GooglePlaceDTO]
}

private struct DetailsResponse: Decodable {
    let status: String
    let result: GoogleDetailDTO?
}

private struct AutocompleteResponse: Decodable {
    let status: String
    let predictions: [PredictionDTO]
}

private struct PredictionDTO: Decodable {
    let place_id: String
    let description: String
    let structured_formatting: StructuredFormatting?
    let types: [String]?

    struct StructuredFormatting: Decodable {
        let main_text: String?
        let secondary_text: String?
    }
}

private struct GooglePlaceDTO: Decodable {
    let place_id: String
    let name: String
    let geometry: Geometry
    let rating: Double?
    let user_ratings_total: Int?
    let vicinity: String?
    let formatted_address: String?
    let opening_hours: OpenHours?
    let price_level: Int?
    let photos: [PhotoDTO]?
    let types: [String]?

    struct Geometry: Decodable {
        struct Loc: Decodable { let lat: Double; let lng: Double }
        let location: Loc
    }
    struct OpenHours: Decodable { let open_now: Bool? }
    struct PhotoDTO: Decodable { let photo_reference: String }

    func toPlace(userLat: Double, userLng: Double) -> Place {
        let km = PlaceHelpers.haversineDistance(lat1: userLat, lon1: userLng,
                                                lat2: geometry.location.lat, lon2: geometry.location.lng)
        let pType = PlaceHelpers.primaryType(from: types ?? [])
        return Place(
            id: place_id,
            googlePlaceId: place_id,
            name: name,
            type: pType,
            distance: PlaceHelpers.formatDistance(km),
            rating: rating ?? 0,
            reviewCount: user_ratings_total ?? 0,
            latitude: geometry.location.lat,
            longitude: geometry.location.lng,
            address: vicinity ?? formatted_address,
            isOpen: opening_hours?.open_now ?? true,
            quietScore: PlaceHelpers.estimatedQuietScore(for: pType, rating: rating),
            photoReference: photos?.first?.photo_reference,
            emoji: PlaceHelpers.emojiForType(pType),
            favorite: false,
            priceLevel: price_level
        )
    }

    func toTransitStop(userLat: Double, userLng: Double) -> TransitStop {
        let km = PlaceHelpers.haversineDistance(lat1: userLat, lon1: userLng,
                                                lat2: geometry.location.lat, lon2: geometry.location.lng)
        let ts = types ?? []
        let nm = name.lowercased()
        var transitType = "transit"
        if ts.contains("subway_station") { transitType = "subway" }
        else if ts.contains("light_rail_station") { transitType = "streetcar" }
        else if ts.contains("bus_station") { transitType = "bus" }
        else if ts.contains("transit_station") {
            if nm.contains("subway") || nm.contains("station") { transitType = "subway" }
            else if nm.contains("streetcar") || nm.contains("tram") { transitType = "streetcar" }
            else { transitType = "bus" }
        }
        return TransitStop(
            id: "transit_\(place_id)",
            googlePlaceId: place_id,
            name: name,
            transitType: transitType,
            distance: PlaceHelpers.formatDistance(km),
            latitude: geometry.location.lat,
            longitude: geometry.location.lng,
            address: vicinity ?? formatted_address
        )
    }
}

private struct GoogleDetailDTO: Decodable {
    let place_id: String?
    let name: String?
    let formatted_address: String?
    let formatted_phone_number: String?
    let website: String?
    let opening_hours: DetailOpenHours?
    let rating: Double?
    let user_ratings_total: Int?
    let price_level: Int?
    let geometry: GooglePlaceDTO.Geometry?
    let types: [String]?
    let photos: [GooglePlaceDTO.PhotoDTO]?
    let reviews: [ReviewDTO]?

    struct DetailOpenHours: Decodable {
        let open_now: Bool?
        let weekday_text: [String]?
    }
    struct ReviewDTO: Decodable {
        let author_name: String?
        let rating: Int?
        let text: String?
        let time: Int?
        let profile_photo_url: String?
    }

    func toDetailedPlace() -> Place {
        let pType = PlaceHelpers.primaryType(from: types ?? [])
        return Place(
            id: place_id ?? UUID().uuidString,
            googlePlaceId: place_id,
            name: name ?? "Unknown",
            type: pType,
            distance: nil,
            rating: rating ?? 0,
            reviewCount: user_ratings_total ?? 0,
            latitude: geometry?.location.lat ?? 0,
            longitude: geometry?.location.lng ?? 0,
            address: formatted_address,
            isOpen: opening_hours?.open_now ?? true,
            quietScore: PlaceHelpers.estimatedQuietScore(for: pType, rating: rating),
            photoReference: photos?.first?.photo_reference,
            emoji: PlaceHelpers.emojiForType(pType),
            favorite: false,
            phoneNumber: formatted_phone_number,
            website: website,
            openingHours: opening_hours?.weekday_text,
            reviews: reviews?.map { Review(authorName: $0.author_name ?? "", rating: $0.rating ?? 0, text: $0.text ?? "") },
            priceLevel: price_level
        )
    }
}

// MARK: - PlaceHelpers extension for distance parsing

extension PlaceHelpers {
    static func parseDistance(_ s: String?) -> Double? {
        guard let s = s else { return nil }
        if s.hasSuffix("km"), let v = Double(s.dropLast(2)) { return v }
        if s.hasSuffix("m"), let v = Double(s.dropLast(1)) { return v / 1000 }
        return nil
    }
}
