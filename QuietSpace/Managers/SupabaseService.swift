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

    func isFavorite(userId: String, googlePlaceId: String) async throws -> Bool {
        let q = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "google_place_id", value: "eq.\(googlePlaceId)")
        ]
        let req = try request(path: "user_favorites", query: q)
        let rows = try await fetch([FavoritePlace].self, req: req)
        return !rows.isEmpty
    }

    // MARK: - Community Posts

    func getCommunityPosts(limit: Int = 20) async throws -> [CommunityPost] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "status", value: "eq.approved"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = try request(path: "community_posts", query: q)
        return try await fetch([CommunityPost].self, req: req)
    }

    func createCommunityPost(_ post: CommunityPostInsert) async throws -> CommunityPost? {
        let body = try encode(post)
        let req = try request(path: "community_posts", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=representation"])
        let rows = try await fetch([CommunityPost].self, req: req)
        return rows.first
    }

    func getPendingPosts() async throws -> [CommunityPost] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "status", value: "eq.pending"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let req = try request(path: "community_posts", query: q)
        return try await fetch([CommunityPost].self, req: req)
    }

    func updatePostStatus(postId: Int, status: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["status": status])
        let q = [URLQueryItem(name: "id", value: "eq.\(postId)")]
        let req = try request(path: "community_posts", method: "PATCH", query: q, body: body)
        _ = try await fetchRaw(req: req)
    }

    func deletePost(postId: Int) async throws {
        let q = [URLQueryItem(name: "id", value: "eq.\(postId)")]
        let req = try request(path: "community_posts", method: "DELETE", query: q)
        _ = try await fetchRaw(req: req)
    }

    // MARK: - Post Likes

    func toggleLike(postId: Int, userId: String) async throws -> (isLiked: Bool, likesCount: Int) {
        let checkQ = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let checkReq = try request(path: "post_likes", query: checkQ)
        let existing = try await fetch([PostLike].self, req: checkReq)

        var isLiked: Bool
        if existing.isEmpty {
            let insertBody = try JSONSerialization.data(withJSONObject: [
                "post_id": postId, "user_id": userId, "created_at": Int64(Date().timeIntervalSince1970 * 1000)
            ] as [String: Any])
            let insertReq = try request(path: "post_likes", method: "POST", body: insertBody)
            _ = try await fetchRaw(req: insertReq)
            isLiked = true
        } else {
            let delQ = [
                URLQueryItem(name: "post_id", value: "eq.\(postId)"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)")
            ]
            let delReq = try request(path: "post_likes", method: "DELETE", query: delQ)
            _ = try await fetchRaw(req: delReq)
            isLiked = false
        }

        let countQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)")
        ]
        let countReq = try request(path: "post_likes", query: countQ)
        let all = try await fetch([PostLike].self, req: countReq)
        let likesCount = all.count

        let updateBody = try JSONSerialization.data(withJSONObject: ["likes_count": likesCount])
        let updateQ = [URLQueryItem(name: "id", value: "eq.\(postId)")]
        let updateReq = try request(path: "community_posts", method: "PATCH", query: updateQ, body: updateBody)
        _ = try await fetchRaw(req: updateReq)

        return (isLiked, likesCount)
    }

    func isPostLiked(postId: Int, userId: String) async throws -> Bool {
        let q = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let req = try request(path: "post_likes", query: q)
        let rows = try await fetch([PostLike].self, req: req)
        return !rows.isEmpty
    }

    func getUserLikedPosts(userId: String) async throws -> [Int] {
        let q = [
            URLQueryItem(name: "select", value: "post_id"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let req = try request(path: "post_likes", query: q)
        let rows = try await fetch([PostLike].self, req: req)
        return rows.compactMap { $0.postId }
    }

    // MARK: - Comments

    func getComments(postId: Int) async throws -> [PostComment] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        let req = try request(path: "post_comments", query: q)
        return try await fetch([PostComment].self, req: req)
    }

    func addComment(_ comment: PostCommentInsert) async throws -> PostComment? {
        let body = try encode(comment)
        let req = try request(path: "post_comments", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=representation"])
        let rows = try await fetch([PostComment].self, req: req)
        if let first = rows.first, let postId = first.postId {
            try await updateCommentsCount(postId: postId)
        }
        return rows.first
    }

    func deleteComment(commentId: Int) async throws {
        let fetchQ = [
            URLQueryItem(name: "select", value: "post_id"),
            URLQueryItem(name: "id", value: "eq.\(commentId)")
        ]
        let fetchReq = try request(path: "post_comments", query: fetchQ)
        let rows = try await fetch([PostComment].self, req: fetchReq)
        let postId = rows.first?.postId

        let delQ = [URLQueryItem(name: "id", value: "eq.\(commentId)")]
        let delReq = try request(path: "post_comments", method: "DELETE", query: delQ)
        _ = try await fetchRaw(req: delReq)

        if let pid = postId { try await updateCommentsCount(postId: pid) }
    }

    func addReply(parentCommentId: Int, reply: ReplyInsert) async throws -> PostComment? {
        let body = try encode(reply)
        let req = try request(path: "post_comments", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=representation"])
        let rows = try await fetch([PostComment].self, req: req)
        if let pid = rows.first?.postId { try await updateCommentsCount(postId: pid) }
        return rows.first
    }

    private func updateCommentsCount(postId: Int) async throws {
        let q = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "post_id", value: "eq.\(postId)")
        ]
        let countReq = try request(path: "post_comments", query: q,
                                    extraHeaders: ["Prefer": "count=exact"])
        let (_, http) = try await fetchRaw(req: countReq)
        var count = 0
        if let range = http.value(forHTTPHeaderField: "content-range"),
           let total = range.split(separator: "/").last, let n = Int(total) {
            count = n
        }
        let body = try JSONSerialization.data(withJSONObject: ["comments_count": count])
        let updateQ = [URLQueryItem(name: "id", value: "eq.\(postId)")]
        let updateReq = try request(path: "community_posts", method: "PATCH", query: updateQ, body: body)
        _ = try await fetchRaw(req: updateReq)
    }

    // MARK: - Comment Likes

    func toggleCommentLike(commentId: Int, userId: String) async throws -> (isLiked: Bool, likesCount: Int) {
        let checkQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "comment_id", value: "eq.\(commentId)"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let checkReq = try request(path: "comment_likes", query: checkQ)
        let existing = try await fetch([CommentLike].self, req: checkReq)

        var isLiked: Bool
        if existing.isEmpty {
            let body = try JSONSerialization.data(withJSONObject: [
                "comment_id": commentId, "user_id": userId
            ] as [String: Any])
            let insertReq = try request(path: "comment_likes", method: "POST", body: body)
            _ = try await fetchRaw(req: insertReq)
            isLiked = true
        } else {
            let delQ = [
                URLQueryItem(name: "comment_id", value: "eq.\(commentId)"),
                URLQueryItem(name: "user_id", value: "eq.\(userId)")
            ]
            let delReq = try request(path: "comment_likes", method: "DELETE", query: delQ)
            _ = try await fetchRaw(req: delReq)
            isLiked = false
        }

        let countQ = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "comment_id", value: "eq.\(commentId)")
        ]
        let countReq = try request(path: "comment_likes", query: countQ)
        let all = try await fetch([CommentLike].self, req: countReq)
        let likesCount = all.count

        let updateBody = try JSONSerialization.data(withJSONObject: ["likes_count": likesCount])
        let updateQ = [URLQueryItem(name: "id", value: "eq.\(commentId)")]
        let updateReq = try request(path: "post_comments", method: "PATCH", query: updateQ, body: updateBody)
        _ = try await fetchRaw(req: updateReq)

        return (isLiked, likesCount)
    }

    func getUserLikedComments(userId: String) async throws -> [Int] {
        let q = [
            URLQueryItem(name: "select", value: "comment_id"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)")
        ]
        let req = try request(path: "comment_likes", query: q)
        let rows = try await fetch([CommentLike].self, req: req)
        return rows.compactMap { $0.commentId }
    }

    // MARK: - Check-ins

    func createCheckIn(_ checkIn: CheckInInsert) async throws -> CheckIn? {
        let body = try encode(checkIn)
        let req = try request(path: "check_ins", method: "POST", body: body,
                               extraHeaders: ["Prefer": "return=representation"])
        let rows = try await fetch([CheckIn].self, req: req)
        return rows.first
    }

    func getCheckInsForPlace(placeId: String, limit: Int = 20) async throws -> [CheckIn] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "place_id", value: "eq.\(placeId)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = try request(path: "check_ins", query: q)
        return try await fetch([CheckIn].self, req: req)
    }

    func getUserCheckIns(userId: String, limit: Int = 50) async throws -> [CheckIn] {
        let q = [
            URLQueryItem(name: "select", value: "*"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        let req = try request(path: "check_ins", query: q)
        return try await fetch([CheckIn].self, req: req)
    }

    // MARK: - Notifications

    func createNotification(_ notification: NotificationInsert) async throws {
        let body = try encode(notification)
        let req = try request(path: "notifications", method: "POST", body: body)
        _ = try await fetchRaw(req: req)
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

    func markNotificationAsRead(notificationId: Int) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["is_read": true])
        let q = [URLQueryItem(name: "id", value: "eq.\(notificationId)")]
        let req = try request(path: "notifications", method: "PATCH", query: q, body: body)
        _ = try await fetchRaw(req: req)
    }

    func markAllNotificationsAsRead(userId: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["is_read": true])
        let q = [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "is_read", value: "eq.false")
        ]
        let req = try request(path: "notifications", method: "PATCH", query: q, body: body)
        _ = try await fetchRaw(req: req)
    }

    func getUnreadNotificationCount(userId: String) async throws -> Int {
        let q = [
            URLQueryItem(name: "select", value: "id"),
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "is_read", value: "eq.false")
        ]
        let req = try request(path: "notifications", query: q,
                               extraHeaders: ["Prefer": "count=exact"])
        let (_, http) = try await fetchRaw(req: req)
        if let range = http.value(forHTTPHeaderField: "content-range"),
           let total = range.split(separator: "/").last, let n = Int(total) {
            return n
        }
        return 0
    }

    func deleteNotification(notificationId: Int) async throws {
        let q = [URLQueryItem(name: "id", value: "eq.\(notificationId)")]
        let req = try request(path: "notifications", method: "DELETE", query: q)
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

    // MARK: - Storage uploads

    func uploadFile(bucket: String, path: String, data: Data, contentType: String = "image/jpeg") async throws -> String? {
        let uploadURL = storageBase
            .appendingPathComponent("object")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path)

        var req = URLRequest(url: uploadURL)
        req.httpMethod = "POST"
        req.addValue(key, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(authToken ?? key)", forHTTPHeaderField: "Authorization")
        req.addValue(contentType, forHTTPHeaderField: "Content-Type")
        req.httpBody = data

        let (_, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            return nil
        }

        return storageBase
            .appendingPathComponent("object/public")
            .appendingPathComponent(bucket)
            .appendingPathComponent(path)
            .absoluteString
    }

    func uploadAvatar(imageData: Data, userId: String) async throws -> String? {
        let fileName = "\(userId)/avatar_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        return try await uploadFile(bucket: "avatars", path: fileName, data: imageData)
    }

    func uploadPostImage(imageData: Data, userId: String) async throws -> String? {
        let fileName = "\(userId)/\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        return try await uploadFile(bucket: "community-posts", path: fileName, data: imageData)
    }

    func uploadLocationImage(imageData: Data, userId: String) async throws -> String? {
        let fileName = "\(userId)/\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        return try await uploadFile(bucket: "location-submissions", path: fileName, data: imageData)
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
