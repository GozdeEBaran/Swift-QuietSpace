// Daniil Orlov - 101500729
// logic for user registration, login, and session restore
// Nguyen Minh Triet Luu — Student ID: 101542519

import Foundation

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
        do {
            return try decoder.decode(type, from: data)
        } catch {
            let raw = String(data: data.prefix(500), encoding: .utf8) ?? "(non-utf8)"
            print("[SupabaseService] decode \(type) FAILED: \(error)\nraw: \(raw)")
            throw error
        }
    }

    private func fetchRaw(req: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "SupabaseService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return (data, http)
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }

    // MARK: - Auth
    
    private let defaults = UserDefaults.standard

    private enum SessionKeys {
        static let accessToken = "qs.accessToken"
        static let refreshToken = "qs.refreshToken"
        static let userId = "qs.userId"
        static let email = "qs.email"
    }

    struct AuthResponse: Decodable {
        struct User: Decodable {
            let id: String
            let email: String?
        }

        let access_token: String?
        let refresh_token: String?
        let user: User?
    }

    @discardableResult
    func signUp(email: String, password: String, fullName: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["full_name": fullName]
        ]
        var req = try request(
            base: authBase,
            path: "signup",
            method: "POST",
            body: try JSONSerialization.data(withJSONObject: body)
        )
        req.setValue(nil, forHTTPHeaderField: "Authorization")
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let result = try await fetch(AuthResponse.self, req: req)
        saveSession(result)
        return result
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        var req = try request(
            base: authBase,
            path: "token",
            method: "POST",
            query: [URLQueryItem(name: "grant_type", value: "password")],
            body: try JSONSerialization.data(withJSONObject: body)
        )
        req.setValue(nil, forHTTPHeaderField: "Authorization")
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        let result = try await fetch(AuthResponse.self, req: req)
        saveSession(result)
        return result
    }

    func signOut() {
        clearSavedSession()
    }

    /// Updates the signed-in user via `PUT /auth/v1/user` (email, password, and/or auth metadata).
    func updateAuthUser(email: String? = nil, password: String? = nil, metadataFullName: String? = nil) async throws {
        var payload: [String: Any] = [:]
        if let e = email?.trimmingCharacters(in: .whitespacesAndNewlines), !e.isEmpty {
            payload["email"] = e
        }
        if let p = password, !p.isEmpty {
            payload["password"] = p
        }
        if let name = metadataFullName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            payload["data"] = ["full_name": name]
        }
        guard !payload.isEmpty else {
            throw NSError(domain: "SupabaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Nothing to update"])
        }

        let body = try JSONSerialization.data(withJSONObject: payload)
        var req = try request(base: authBase, path: "user", method: "PUT", body: body)
        var (data, resp) = try await session.data(for: req)
        guard var http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 405 {
            req = try request(base: authBase, path: "user", method: "PATCH", body: body)
            (data, resp) = try await session.data(for: req)
            guard let httpRetry = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
            http = httpRetry
        }
        guard (200..<300).contains(http.statusCode) else {
            let msg = Self.authAPIErrorMessage(from: data) ?? (String(data: data, encoding: .utf8) ?? "Unknown error")
            throw NSError(domain: "SupabaseService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        applyAuthUserAPIResponse(data)
    }

    /// Email stored with the current session (updated after auth responses when the server includes it).
    func sessionStoredEmail() -> String? {
        defaults.string(forKey: SessionKeys.email)
    }

    private static func authAPIErrorMessage(from data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let d = obj["error_description"] as? String { return d }
        if let d = obj["msg"] as? String { return d }
        if let e = obj["message"] as? String { return e }
        if let e = obj["error"] as? String { return e }
        return nil
    }

    /// Merges tokens and user fields from a GoTrue `/user` response into local session storage.
    private func applyAuthUserAPIResponse(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        if let session = json["session"] as? [String: Any] {
            if let at = session["access_token"] as? String {
                authToken = at
                defaults.set(at, forKey: SessionKeys.accessToken)
            }
            if let rt = session["refresh_token"] as? String {
                defaults.set(rt, forKey: SessionKeys.refreshToken)
            }
            if let user = session["user"] as? [String: Any] {
                if let id = user["id"] as? String { defaults.set(id, forKey: SessionKeys.userId) }
                if let em = user["email"] as? String { defaults.set(em, forKey: SessionKeys.email) }
            }
            return
        }

        if let at = json["access_token"] as? String {
            authToken = at
            defaults.set(at, forKey: SessionKeys.accessToken)
        }
        if let rt = json["refresh_token"] as? String {
            defaults.set(rt, forKey: SessionKeys.refreshToken)
        }
        if let user = json["user"] as? [String: Any] {
            if let id = user["id"] as? String { defaults.set(id, forKey: SessionKeys.userId) }
            if let em = user["email"] as? String { defaults.set(em, forKey: SessionKeys.email) }
        } else if let em = json["email"] as? String {
            defaults.set(em, forKey: SessionKeys.email)
        }
    }

    private func saveSession(_ response: AuthResponse) {
        if let access = response.access_token {
            authToken = access
            defaults.set(access, forKey: SessionKeys.accessToken)
        }

        if let refresh = response.refresh_token {
            defaults.set(refresh, forKey: SessionKeys.refreshToken)
        }

        if let user = response.user {
            defaults.set(user.id, forKey: SessionKeys.userId)
            defaults.set(user.email, forKey: SessionKeys.email)
        }
    }

    private func clearSavedSession() {
        authToken = key
        defaults.removeObject(forKey: SessionKeys.accessToken)
        defaults.removeObject(forKey: SessionKeys.refreshToken)
        defaults.removeObject(forKey: SessionKeys.userId)
        defaults.removeObject(forKey: SessionKeys.email)
    }

    struct RestoredSession {
        let userId: String
        let email: String?
        let fullName: String?
    }
    
    func restoreSession() async throws -> RestoredSession? {
        guard let refreshToken = defaults.string(forKey: SessionKeys.refreshToken) else {
            return nil
        }

        let body: [String: Any] = [
            "refresh_token": refreshToken
        ]

        var req = try request(
            base: authBase,
            path: "token",
            method: "POST",
            query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: try JSONSerialization.data(withJSONObject: body)
        )
        req.setValue(nil, forHTTPHeaderField: "Authorization")
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        do {
            let result = try await fetch(AuthResponse.self, req: req)
            saveSession(result)

            guard let uid = result.user?.id ?? defaults.string(forKey: SessionKeys.userId) else {
                return nil
            }

            let email = result.user?.email ?? defaults.string(forKey: SessionKeys.email)
            let profile = try? await getUserProfile(userId: uid)

            return RestoredSession(
                userId: uid,
                email: email,
                fullName: profile?.fullName
            )
        } catch {
            clearSavedSession()
            return nil
        }
    }

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

    func updateUserProfile(userId: String, fullName: String?, avatarUrl: String?, coverImageUrl: String? = nil) async throws {
        var updates: [String: Any] = [:]
        if let fn = fullName { updates["full_name"] = fn }
        if let av = avatarUrl { updates["avatar_url"] = av }
        if let cv = coverImageUrl { updates["cover_image_url"] = cv }
        let body = try JSONSerialization.data(withJSONObject: updates)
        let q = [URLQueryItem(name: "id", value: "eq.\(userId)")]
        let req = try request(path: "profiles", method: "PATCH", query: q, body: body)
        _ = try await fetchRaw(req: req)
    }

    func uploadAvatarImage(userId: String, data: Data, contentType: String = "image/jpeg") async throws -> String {
        let file = "avatar_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        var uploadURL = storageBase
        uploadURL.appendPathComponent("object")
        uploadURL.appendPathComponent("avatars")
        uploadURL.appendPathComponent(userId)
        uploadURL.appendPathComponent(file)
        var req = URLRequest(url: uploadURL)
        req.httpMethod = "POST"
        req.addValue(key, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(authToken ?? key)", forHTTPHeaderField: "Authorization")
        req.addValue(contentType, forHTTPHeaderField: "Content-Type")
        req.addValue("true", forHTTPHeaderField: "x-upsert")
        req.httpBody = data
        let (_, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "SupabaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Avatar upload failed"])
        }
        _ = http
        var publicURL = storageBase
        publicURL.appendPathComponent("object")
        publicURL.appendPathComponent("public")
        publicURL.appendPathComponent("avatars")
        publicURL.appendPathComponent(userId)
        publicURL.appendPathComponent(file)
        return publicURL.absoluteString
    }

    func uploadProfileCoverImage(userId: String, data: Data, contentType: String = "image/jpeg") async throws -> String {
        let file = "cover_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        var uploadURL = storageBase
        uploadURL.appendPathComponent("object")
        uploadURL.appendPathComponent("profile-covers")
        uploadURL.appendPathComponent(userId)
        uploadURL.appendPathComponent(file)
        var req = URLRequest(url: uploadURL)
        req.httpMethod = "POST"
        req.addValue(key, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(authToken ?? key)", forHTTPHeaderField: "Authorization")
        req.addValue(contentType, forHTTPHeaderField: "Content-Type")
        req.addValue("true", forHTTPHeaderField: "x-upsert")
        req.httpBody = data
        let (_, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "SupabaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Cover upload failed"])
        }
        _ = http
        var publicURL = storageBase
        publicURL.appendPathComponent("object")
        publicURL.appendPathComponent("public")
        publicURL.appendPathComponent("profile-covers")
        publicURL.appendPathComponent(userId)
        publicURL.appendPathComponent(file)
        return publicURL.absoluteString
    }

    func isAdmin(userId: String) async throws -> Bool {
        let q = [
            URLQueryItem(name: "select", value: "id,role,is_admin"),
            URLQueryItem(name: "id", value: "eq.\(userId)")
        ]
        let req = try request(path: "profiles", query: q)
        let rows = try await fetch([AdminCheckRow].self, req: req)
        guard let row = rows.first else { return false }
        if row.is_admin == true { return true }
        return row.role == "admin"
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

    // MARK: - Community posts (admin)

    func getPendingPosts() async throws -> [CommunityPost] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "status", value: "in.(pending,flagged)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let req = try request(path: "community_posts", query: q)
        return try await fetch([CommunityPost].self, req: req)
    }

    func updatePostStatus(postId: String, status: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["status": status])
        let q = [URLQueryItem(name: "id", value: "eq.\(postId)")]
        let req = try request(path: "community_posts", method: "PATCH", query: q, body: body)
        _ = try await fetchRaw(req: req)
    }

    func deletePost(postId: String) async throws {
        let q = [URLQueryItem(name: "id", value: "eq.\(postId)")]
        let req = try request(path: "community_posts", method: "DELETE", query: q)
        _ = try await fetchRaw(req: req)
    }

    // MARK: - Notifications

    func createNotification(
        userId: String,
        type: String,
        title: String,
        message: String,
        metadata: [String: Any] = [:]
    ) async throws {
        let rpcPayload: [String: Any] = [
            "p_user_id": userId,
            "p_type": type,
            "p_title": title,
            "p_message": message,
            "p_metadata": metadata
        ]
        let body = try JSONSerialization.data(withJSONObject: rpcPayload)
        let rpcReq = try request(path: "rpc/create_notification", method: "POST", body: body,
                                  extraHeaders: ["Prefer": "return=minimal"])

        let (_, rpcResp) = try await session.data(for: rpcReq)
        if let http = rpcResp as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
            return
        }

        var direct: [String: Any] = [
            "user_id": userId,
            "type": type,
            "title": title,
            "message": message,
            "metadata": metadata,
            "is_read": false
        ]
        direct["created_at"] = ISO8601DateFormatter().string(from: Date())
        let insertBody = try JSONSerialization.data(withJSONObject: direct)
        let insertReq = try request(path: "notifications", method: "POST", body: insertBody,
                                     extraHeaders: ["Prefer": "return=minimal"])
        _ = try await fetchRaw(req: insertReq)
    }

    func getUnreadNotificationCount(userId: String) async -> Int {
        do {
            let q = [
                URLQueryItem(name: "user_id", value: "eq.\(userId)"),
                URLQueryItem(name: "is_read", value: "eq.false"),
                URLQueryItem(name: "select", value: "id")
            ]
            var req = try request(path: "notifications", query: q)
            req.setValue("exact", forHTTPHeaderField: "Prefer")
            req.setValue("0-0", forHTTPHeaderField: "Range")
            let (_, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let range = http.value(forHTTPHeaderField: "Content-Range") else {
                return 0
            }
            let parts = range.split(separator: "/")
            guard parts.count == 2, let n = Int(parts[1]) else { return 0 }
            return n
        } catch {
            return 0
        }
    }

    func getNotifications(userId: String, limit: Int = 50) async throws -> [AppNotification] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = try request(path: "notifications", query: q)
        return try await fetch([AppNotification].self, req: req)
    }

    func markNotificationAsRead(notificationId: String) async throws {
        let patchBody = try JSONSerialization.data(withJSONObject: ["is_read": true])
        let q = [URLQueryItem(name: "id", value: "eq.\(notificationId)")]
        let patchReq = try request(path: "notifications", method: "PATCH", query: q, body: patchBody)
        _ = try await fetchRaw(req: patchReq)
    }

    func markAllNotificationsAsRead(userId: String) async throws {
        let patchBody = try JSONSerialization.data(withJSONObject: ["is_read": true])
        let q = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "is_read", value: "eq.false")
        ]
        let patchReq = try request(path: "notifications", method: "PATCH", query: q, body: patchBody)
        _ = try await fetchRaw(req: patchReq)
    }

    // MARK: - Community feed

    func getApprovedCommunityPosts(limit: Int = 20) async throws -> [CommunityPost] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "status", value: "eq.approved"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = try request(path: "community_posts", query: q)
        return try await fetch([CommunityPost].self, req: req)
    }

    func getUserLikedPostIds(userId: String) async throws -> [String] {
        let q = [
            URLQueryItem(name: "select", value: "post_id"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let req = try request(path: "post_likes", query: q)
        let rows = try await fetch([PostLikeRow].self, req: req)
        return rows.compactMap(\.post_id)
    }

    func getUserLikedCommentIds(userId: String) async throws -> [String] {
        let q = [
            URLQueryItem(name: "select", value: "comment_id"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let req = try request(path: "comment_likes", query: q)
        let rows = try await fetch([CommentLikeRow].self, req: req)
        return rows.compactMap(\.comment_id)
    }

    func getTopCommentsForPost(postId: String, limit: Int = 3) async throws -> [PostComment] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)"),
            URLQueryItem(name: "parent_comment_id", value: "is.null"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = try request(path: "post_comments", query: q)
        return try await fetch([PostComment].self, req: req)
    }

    func getComments(postId: String) async throws -> [PostComment] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let req = try request(path: "post_comments", query: q)
        return try await fetch([PostComment].self, req: req)
    }

    struct ToggleResult: Sendable {
        let isLiked: Bool
        let likesCount: Int
    }

    func toggleLike(postId: String, userId: String) async throws -> ToggleResult {
        let checkQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let checkReq = try request(path: "post_likes", query: checkQ)
        let existing = try await fetch([IdRow].self, req: checkReq)

        if existing.isEmpty {
            let insert: [String: Any] = [
                "post_id": postId,
                "user_id": userId,
                "created_at": Int64(Date().timeIntervalSince1970 * 1000)
            ]
            let body = try JSONSerialization.data(withJSONObject: insert)
            let insReq = try request(path: "post_likes", method: "POST", body: body,
                                       extraHeaders: ["Prefer": "return=minimal"])
            _ = try await fetchRaw(req: insReq)
        } else {
            let delQ = [
                URLQueryItem(name: "post_id", value: "eq.\(postId)"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)")
            ]
            let delReq = try request(path: "post_likes", method: "DELETE", query: delQ)
            _ = try await fetchRaw(req: delReq)
        }

        let countQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)")
        ]
        let countReq = try request(path: "post_likes", query: countQ)
        let likes = try await fetch([IdRow].self, req: countReq)
        let likesCount = likes.count

        let patchBody = try JSONSerialization.data(withJSONObject: ["likes_count": likesCount])
        let patchQ = [URLQueryItem(name: "id", value: "eq.\(postId)")]
        let patchReq = try request(path: "community_posts", method: "PATCH", query: patchQ, body: patchBody)
        _ = try await fetchRaw(req: patchReq)

        let likedQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let likedReq = try request(path: "post_likes", query: likedQ)
        let still = try await fetch([IdRow].self, req: likedReq)
        return ToggleResult(isLiked: !still.isEmpty, likesCount: likesCount)
    }

    func toggleCommentLike(commentId: String, userId: String) async throws -> ToggleResult {
        let checkQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "comment_id", value: "eq.\(commentId)"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let checkReq = try request(path: "comment_likes", query: checkQ)
        let existing = try await fetch([IdRow].self, req: checkReq)

        if existing.isEmpty {
            let insert: [String: Any] = [
                "comment_id": commentId,
                "user_id": userId
            ]
            let body = try JSONSerialization.data(withJSONObject: insert)
            let insReq = try request(path: "comment_likes", method: "POST", body: body,
                                       extraHeaders: ["Prefer": "return=minimal"])
            _ = try await fetchRaw(req: insReq)
        } else {
            let delQ = [
                URLQueryItem(name: "comment_id", value: "eq.\(commentId)"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)")
            ]
            let delReq = try request(path: "comment_likes", method: "DELETE", query: delQ)
            _ = try await fetchRaw(req: delReq)
        }

        let countQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "comment_id", value: "eq.\(commentId)")
        ]
        let countReq = try request(path: "comment_likes", query: countQ)
        let likes = try await fetch([IdRow].self, req: countReq)
        let likesCount = likes.count

        let patchBody = try JSONSerialization.data(withJSONObject: ["likes_count": likesCount])
        let patchQ = [URLQueryItem(name: "id", value: "eq.\(commentId)")]
        let patchReq = try request(path: "post_comments", method: "PATCH", query: patchQ, body: patchBody)
        _ = try await fetchRaw(req: patchReq)

        let likedQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "comment_id", value: "eq.\(commentId)"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let likedReq = try request(path: "comment_likes", query: likedQ)
        let still = try await fetch([IdRow].self, req: likedReq)
        return ToggleResult(isLiked: !still.isEmpty, likesCount: likesCount)
    }

    func flagPost(postId: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["p_post_id": postId])
        let req = try request(path: "rpc/flag_community_post", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=minimal"])
        _ = try await fetchRaw(req: req)
    }

    func createPost(
        userId: String,
        userName: String,
        userAvatarUrl: String?,
        placeName: String,
        caption: String,
        category: String,
        imageUrl: String?
    ) async throws {
        let createdAt = Int64(Date().timeIntervalSince1970 * 1000)
        var dict: [String: Any] = [
            "user_id": userId,
            "user_name": userName,
            "place_name": placeName,
            "caption": caption,
            "category": category,
            "likes_count": 0,
            "comments_count": 0,
            "created_at": createdAt
        ]
        if let av = userAvatarUrl { dict["user_avatar_url"] = av }
        if let img = imageUrl { dict["image_url"] = img }
        let body = try JSONSerialization.data(withJSONObject: dict)
        let req = try request(path: "community_posts", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=minimal"])
        _ = try await fetchRaw(req: req)
    }

    func addComment(_ insert: PostCommentInsert) async throws {
        let body = try encode(insert)
        let req = try request(path: "post_comments", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=representation"])
        let rows = try await fetch([PostComment].self, req: req)
        if let postId = rows.first?.postId {
            try await updateCommentsCount(postId: postId)
        }
    }

    func addReply(parentCommentId: String, reply: ReplyInsert) async throws {
        let body = try encode(reply)
        let req = try request(path: "post_comments", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=representation"])
        _ = try await fetchRaw(req: req)
        try await updateCommentsCount(postId: reply.postId)
    }

    private func updateCommentsCount(postId: String) async throws {
        let countQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)")
        ]
        let countReq = try request(path: "post_comments", query: countQ)
        let rows = try await fetch([IdRow].self, req: countReq)
        let c = rows.count
        let patchBody = try JSONSerialization.data(withJSONObject: ["comments_count": c])
        let patchQ = [URLQueryItem(name: "id", value: "eq.\(postId)")]
        let patchReq = try request(path: "community_posts", method: "PATCH", query: patchQ, body: patchBody)
        _ = try await fetchRaw(req: patchReq)
    }

    func uploadCommunityPostImage(userId: String, data: Data, contentType: String = "image/jpeg") async throws -> String {
        let file = "\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        var uploadURL = storageBase
        uploadURL.appendPathComponent("object")
        uploadURL.appendPathComponent("community-posts")
        uploadURL.appendPathComponent(userId)
        uploadURL.appendPathComponent(file)
        var req = URLRequest(url: uploadURL)
        req.httpMethod = "POST"
        req.addValue(key, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(authToken ?? key)", forHTTPHeaderField: "Authorization")
        req.addValue(contentType, forHTTPHeaderField: "Content-Type")
        req.addValue("false", forHTTPHeaderField: "x-upsert")
        req.httpBody = data
        let (_, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "SupabaseService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image upload failed"])
        }
        _ = http
        var publicURL = storageBase
        publicURL.appendPathComponent("object")
        publicURL.appendPathComponent("public")
        publicURL.appendPathComponent("community-posts")
        publicURL.appendPathComponent(userId)
        publicURL.appendPathComponent(file)
        return publicURL.absoluteString
    }

    // MARK: - Favorites

    func getFavorites(userId: String) async throws -> [FavoritePlace] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let req = try request(path: "user_favorites", query: q)
        return try await fetch([FavoritePlace].self, req: req)
    }

    // MARK: - Check-ins

    func getUserCheckIns(userId: String, limit: Int = 20) async throws -> [CheckIn] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = try request(path: "check_ins", query: q)
        return try await fetch([CheckIn].self, req: req)
    }

    func getUserCommunityPosts(userId: String, limit: Int = 20) async throws -> [CommunityPost] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "status", value: "in.(approved,flagged)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = try request(path: "community_posts", query: q)
        return try await fetch([CommunityPost].self, req: req)
    }

    func addFavorite(userId: String, place: Place) async throws {
        let insert = FavoritePlaceInsert(
            userId: userId,
            googlePlaceId: place.googlePlaceId ?? place.id,
            name: place.name,
            address: place.address,
            rating: place.rating,
            userRatingsTotal: place.reviewCount,
            latitude: place.latitude,
            longitude: place.longitude,
            placeType: place.type,
            quietScore: place.quietScore,
            photoReference: place.photoReference
        )
        let body = try encode(insert)
        let req = try request(path: "user_favorites", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=representation"])
        _ = try await fetchRaw(req: req)
    }

    func removeFavorite(userId: String, googlePlaceId: String) async throws {
        let q = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "google_place_id", value: "eq.\(googlePlaceId)")
        ]
        let req = try request(path: "user_favorites", method: "DELETE", query: q)
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

    func getPendingLocationSubmissionsForAdmin() async throws -> [LocationSubmissionAdmin] {
        let q = [
            URLQueryItem(
                name: "select",
                value: "id,user_id,name,address,type,description,latitude,longitude,quiet_score,image_url,status,admin_notes,created_at,profiles(full_name,avatar_url)"
            ),
            URLQueryItem(name: "status", value: "eq.pending"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let req = try request(path: "location_submissions", query: q)
        do {
            let rows = try await fetch([LocationSubmissionJoinedRow].self, req: req)
            return rows.map(\.toAdmin)
        } catch {
            let subs = try await getLocationSubmissions(status: "pending")
            return subs.map { LocationSubmissionAdmin(submission: $0, submitterName: nil) }
        }
    }

    func updateLocationSubmissionStatus(id: String, status: String, adminNotes: String? = nil) async throws {
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

    /// Returns all submissions (any status) for a specific user.
    func getMyLocationSubmissions(userId: String) async throws -> [LocationSubmission] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let req = try request(path: "location_submissions", query: q)
        return try await fetch([LocationSubmission].self, req: req)
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

// MARK: - Community feed DTOs

private struct PostLikeRow: Decodable { let post_id: String? }
private struct CommentLikeRow: Decodable { let comment_id: String? }
private struct IdRow: Decodable { let id: String? }
private struct AdminCheckRow: Decodable {
    let id: String
    let role: String?
    let is_admin: Bool?
}

// MARK: - Location submission + profile join (admin)

private struct LocationSubmissionJoinedRow: Decodable {
    struct ProfileJoin: Decodable {
        let full_name: String?
        let avatar_url: String?
    }

    let id: String?
    let user_id: String?
    let name: String?
    let address: String?
    let type: String?
    let description: String?
    let latitude: Double?
    let longitude: Double?
    let quiet_score: Double?
    let image_url: String?
    let status: String?
    let admin_notes: String?
    let created_at: String?
    let profiles: ProfileJoin?

    var toAdmin: LocationSubmissionAdmin {
        let submission = LocationSubmission(
            id: id,
            userId: user_id,
            name: name,
            address: address,
            type: type,
            description: description,
            latitude: latitude,
            longitude: longitude,
            quietScore: quiet_score,
            imageUrl: image_url,
            status: status,
            adminNotes: admin_notes,
            createdAt: created_at
        )
        return LocationSubmissionAdmin(submission: submission, submitterName: profiles?.full_name)
    }
}
