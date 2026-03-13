import Foundation

/// Complete Supabase service mirroring the React Native SupabaseService.
/// Uses the same Supabase project, tables, and storage buckets so data is shared across platforms.
final class SupabaseService {
    static let shared = SupabaseService()

    private let session = URLSession(configuration: .default)
    private let base: URL = AppConfig.supabaseURL
    private let key: String = AppConfig.supabaseAnonKey

    private var authToken: String?

    private init() {
        authToken = key
    }

    // MARK: - Generic REST helpers

    private var restBase: URL { base.appendingPathComponent("rest/v1") }
    private var authBase: URL { base.appendingPathComponent("auth/v1") }
    private var storageBase: URL { base.appendingPathComponent("storage/v1") }

    private func request(
        base: URL? = nil,
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil,
        extraHeaders: [String: String] = [:]
    ) throws -> URLRequest {
        let root = base ?? restBase
        guard var comp = URLComponents(url: root.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        if !query.isEmpty { comp.queryItems = query }
        guard let url = comp.url else { throw URLError(.badURL) }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.addValue(key, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(authToken ?? key)", forHTTPHeaderField: "Authorization")
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        for (k, v) in extraHeaders { req.addValue(v, forHTTPHeaderField: k) }
        req.httpBody = body
        return req
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private func fetch<T: Decodable>(_ type: T.Type, req: URLRequest) async throws -> T {
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "SupabaseService", code: (resp as? HTTPURLResponse)?.statusCode ?? 0, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return try decoder.decode(type, from: data)
    }

    private func fetchRaw(req: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }

    // MARK: - Auth

    struct AuthResponse: Decodable {
        struct User: Decodable { let id: String; let email: String? }
        let access_token: String?
        let user: User?
    }

    @discardableResult
    func signUp(email: String, password: String, fullName: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["full_name": fullName]
        ]
        var req = try request(base: authBase, path: "signup", method: "POST",
                               body: try JSONSerialization.data(withJSONObject: body))
        req.setValue(nil, forHTTPHeaderField: "Authorization")
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let result = try await fetch(AuthResponse.self, req: req)
        if let token = result.access_token { authToken = token }
        return result
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = ["email": email, "password": password]
        var req = try request(base: authBase, path: "token", method: "POST",
                               query: [URLQueryItem(name: "grant_type", value: "password")],
                               body: try JSONSerialization.data(withJSONObject: body))
        req.setValue(nil, forHTTPHeaderField: "Authorization")
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let result = try await fetch(AuthResponse.self, req: req)
        if let token = result.access_token { authToken = token }
        return result
    }

    func signOut() { authToken = key }

    // MARK: - Profiles

    func getUserProfile(userId: String) async throws -> UserProfile? {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "id", value: "eq.\(userId)")
        ]
        let req = try request(path: "profiles", query: q)
        let rows = try await fetch([UserProfile].self, req: req)
        return rows.first
    }

    func updateUserProfile(userId: String, fullName: String?, avatarUrl: String?) async throws {
        var updates: [String: Any] = [:]
        if let fn = fullName { updates["full_name"] = fn }
        if let av = avatarUrl { updates["avatar_url"] = av }
        let body = try JSONSerialization.data(withJSONObject: updates)
        let q = [URLQueryItem(name: "id", value: "eq.\(userId)")]
        let req = try request(path: "profiles", method: "PATCH", query: q, body: body)
        _ = try await fetchRaw(req: req)
    }

    func isAdmin(userId: String) async throws -> Bool {
        let q = [
            URLQueryItem(name: "select", value: "role,is_admin"),
            URLQueryItem(name: "id", value: "eq.\(userId)")
        ]
        let req = try request(path: "profiles", query: q)
        let rows = try await fetch([UserProfile].self, req: req)
        guard let profile = rows.first else { return false }
        return profile.displayRole == "admin"
    }

    func getAllUsers() async throws -> [UserProfile] {
        let q = [
            URLQueryItem(name: "select", value: "id,full_name,email,avatar_url,role,is_admin,created_at"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let req = try request(path: "profiles", query: q)
        return try await fetch([UserProfile].self, req: req)
    }

    func banUser(userId: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["role": "banned"])
        let q = [URLQueryItem(name: "id", value: "eq.\(userId)")]
        let req = try request(path: "profiles", method: "PATCH", query: q, body: body)
        _ = try await fetchRaw(req: req)
    }

    func unbanUser(userId: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["role": "user"])
        let q = [URLQueryItem(name: "id", value: "eq.\(userId)")]
        let req = try request(path: "profiles", method: "PATCH", query: q, body: body)
        _ = try await fetchRaw(req: req)
    }

    // MARK: - Location Submissions

    func createLocationSubmission(_ submission: LocationSubmissionInsert) async throws -> LocationSubmission? {
        let body = try encode(submission)
        let req = try request(path: "location_submissions", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=representation"])
        let rows = try await fetch([LocationSubmission].self, req: req)
        return rows.first
    }

    func getLocationSubmissions(status: String = "pending") async throws -> [LocationSubmission] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "status", value: "eq.\(status)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let req = try request(path: "location_submissions", query: q)
        return try await fetch([LocationSubmission].self, req: req)
    }

    func updateLocationSubmissionStatus(id: Int, status: String, adminNotes: String? = nil) async throws {
        var dict: [String: Any] = ["status": status]
        if let notes = adminNotes { dict["admin_notes"] = notes }
        let body = try JSONSerialization.data(withJSONObject: dict)
        let q = [URLQueryItem(name: "id", value: "eq.\(id)")]
        let req = try request(path: "location_submissions", method: "PATCH", query: q, body: body)
        _ = try await fetchRaw(req: req)
    }

    func getApprovedSubmissions() async throws -> [LocationSubmission] {
        return try await getLocationSubmissions(status: "approved")
    }

    // MARK: - Delete user account (admin)

    func deleteUserAccount(userId: String) async throws {
        let tables: [(String, String)] = [
            ("community_posts", "user_id"),
            ("post_comments", "user_id"),
            ("post_likes", "user_id"),
            ("profiles", "id")
        ]
        for (table, col) in tables {
            let q = [URLQueryItem(name: col, value: "eq.\(userId)")]
            let req = try request(path: table, method: "DELETE", query: q)
            _ = try await fetchRaw(req: req)
        }
    }
}
