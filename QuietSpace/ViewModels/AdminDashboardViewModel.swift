import Foundation
import Combine

@MainActor
final class AdminDashboardViewModel: ObservableObject {
    @Published var pendingPosts: [CommunityPost] = []
    @Published var locationRows: [LocationSubmissionAdmin] = []
    @Published var users: [UserProfile] = []
    @Published var selectedTab = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let postsTask = SupabaseService.shared.getPendingPosts()
            async let locTask = SupabaseService.shared.getPendingLocationSubmissionsForAdmin()
            async let usersTask = SupabaseService.shared.getAllUsers()

            pendingPosts = try await postsTask
            locationRows = try await locTask
            users = try await usersTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func approvePost(_ post: CommunityPost) async {
        guard let pid = post.id, let uid = post.userId else { return }
        do {
            try await SupabaseService.shared.updatePostStatus(postId: pid, status: "approved")
            try await SupabaseService.shared.createNotification(
                userId: uid,
                type: "post_approved",
                title: "Post Approved! 🎉",
                message: "Your post about \"\(post.placeName ?? "a place")\" has been approved and is now visible to the community."
            )
            pendingPosts.removeAll { $0.id == post.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rejectPost(_ post: CommunityPost, reason: String) async {
        guard let pid = post.id, let uid = post.userId else { return }
        do {
            try await SupabaseService.shared.deletePost(postId: pid)
            try await SupabaseService.shared.createNotification(
                userId: uid,
                type: "post_rejected",
                title: "Post Rejected",
                message: reason.isEmpty ? "Your post did not meet our community guidelines." : reason
            )
            pendingPosts.removeAll { $0.id == post.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func approveLocation(_ row: LocationSubmissionAdmin) async {
        guard let sid = row.submission.id else { return }
        do {
            try await SupabaseService.shared.updateLocationSubmissionStatus(id: sid, status: "approved")
            if let uid = row.submission.userId {
                try await SupabaseService.shared.createNotification(
                    userId: uid,
                    type: "location_approved",
                    title: "Location Approved! 📍",
                    message: "Your submitted location \"\(row.submission.name ?? "Location")\" has been approved and added to QuietSpace."
                )
            }
            locationRows.removeAll { $0.submission.id == row.submission.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rejectLocation(_ row: LocationSubmissionAdmin, reason: String) async {
        guard let sid = row.submission.id else { return }
        do {
            try await SupabaseService.shared.updateLocationSubmissionStatus(
                id: sid,
                status: "rejected",
                adminNotes: reason.isEmpty ? nil : reason
            )
            if let uid = row.submission.userId {
                try await SupabaseService.shared.createNotification(
                    userId: uid,
                    type: "location_rejected",
                    title: "Location Submission Rejected",
                    message: reason.isEmpty
                        ? "Your location \"\(row.submission.name ?? "")\" did not meet our criteria."
                        : reason
                )
            }
            locationRows.removeAll { $0.submission.id == row.submission.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func banUser(_ user: UserProfile, reason: String) async {
        do {
            try await SupabaseService.shared.banUser(userId: user.id)
            try await SupabaseService.shared.createNotification(
                userId: user.id,
                type: "user_banned",
                title: "Account Suspended",
                message: reason.isEmpty ? "Your account has been suspended for violating community guidelines." : reason
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unbanUser(_ user: UserProfile) async {
        do {
            try await SupabaseService.shared.unbanUser(userId: user.id)
            try await SupabaseService.shared.createNotification(
                userId: user.id,
                type: "user_unbanned",
                title: "Account Restored! 🎉",
                message: "Your account has been restored. Welcome back to the community!"
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteUser(_ user: UserProfile) async {
        do {
            try await SupabaseService.shared.deleteUserAccount(userId: user.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var pendingLocationCount: Int {
        locationRows.filter { ($0.submission.status ?? "") == "pending" }.count
    }
}
