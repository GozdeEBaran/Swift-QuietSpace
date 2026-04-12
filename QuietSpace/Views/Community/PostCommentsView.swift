// Nguyen Minh Triet Luu — Student ID: 101542519

import SwiftUI

struct PostCommentsView: View {
    let postId: String
    let placeName: String

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore

    @State private var comments: [PostComment] = []
    @State private var isLoading = true
    @State private var newComment = ""
    @State private var errorMessage: String?
    @State private var replyingTo: PostComment?
    @State private var replyText = ""
    @State private var likedCommentIds = Set<String>()

    private var colors: AppColors { AppColors(colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            header

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(sortedComments, id: \.stableId) { c in
                            commentRow(c)
                        }
                    }
                    .padding()
                }

                inputBar
            }
        }
        .background(colors.background)
        .navigationBarHidden(true)
        .task { await load() }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .fontWeight(.semibold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Comments")
                    .font(.headline)
                Text(placeName)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(colors.surface)
    }

    private var sortedComments: [PostComment] {
        comments.sorted { a, b in
            let ta = parseDate(a.createdAt)
            let tb = parseDate(b.createdAt)
            return ta < tb
        }
    }

    private func parseDate(_ raw: String?) -> TimeInterval {
        guard let raw, !raw.isEmpty else { return 0 }
        if let ms = Int64(raw) { return TimeInterval(ms) / 1000 }
        if let d = ISO8601DateFormatter().date(from: raw) { return d.timeIntervalSince1970 }
        return 0
    }

    private func commentRow(_ c: PostComment) -> some View {
        let isReply = c.parentCommentId != nil
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.userName ?? "User")
                        .font(.subheadline.weight(.semibold))
                    Text(c.comment ?? "")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                }
                Spacer()
                if let uid = auth.userId, let cid = c.id {
                    Button {
                        Task { await toggleCommentLike(cid: cid, userId: uid) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: likedCommentIds.contains(cid) ? "heart.fill" : "heart")
                                .foregroundColor(likedCommentIds.contains(cid) ? colors.error : colors.textMuted)
                            Text("\(c.displayLikes)")
                                .font(.caption)
                                .foregroundColor(colors.textMuted)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, isReply ? 16 : 0)

            if let uid = auth.userId, c.parentCommentId == nil {
                Button("Reply") {
                    replyingTo = c
                    replyText = ""
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(colors.primary)
            }

            if replyingTo?.id == c.id {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Write a reply…", text: $replyText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                    HStack {
                        Button("Cancel") { replyingTo = nil; replyText = "" }
                        Spacer()
                        Button("Send") { Task { await submitReply(to: c) } }
                            .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(10)
                .background(colors.surfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.vertical, 6)
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                TextField("Add a comment…", text: $newComment, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                Button("Post") { Task { await submitComment() } }
                    .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || auth.userId == nil)
            }
            .padding()
        }
        .background(colors.surface)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            comments = try await SupabaseService.shared.getComments(postId: postId)
            if let uid = auth.userId {
                let liked = try await SupabaseService.shared.getUserLikedCommentIds(userId: uid)
                likedCommentIds = Set(liked)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitComment() async {
        guard let uid = auth.userId,
              let profile = try? await SupabaseService.shared.getUserProfile(userId: uid) else { return }
        let text = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let insert = PostCommentInsert(
            postId: postId,
            userId: uid,
            userName: CommunityHelpers.displayName(from: profile, email: auth.email),
            userAvatarUrl: profile.avatarUrl,
            comment: text,
            rating: 0,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        do {
            try await SupabaseService.shared.addComment(insert)
            newComment = ""
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitReply(to parent: PostComment) async {
        guard let uid = auth.userId,
              let parentId = parent.id,
              let profile = try? await SupabaseService.shared.getUserProfile(userId: uid) else { return }
        let text = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let reply = ReplyInsert(
            postId: postId,
            parentCommentId: parentId,
            userId: uid,
            userName: CommunityHelpers.displayName(from: profile, email: auth.email),
            userAvatarUrl: profile.avatarUrl,
            comment: text,
            rating: 0,
            createdAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        do {
            try await SupabaseService.shared.addReply(parentCommentId: parentId, reply: reply)
            replyingTo = nil
            replyText = ""
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleCommentLike(cid: String, userId: String) async {
        do {
            let r = try await SupabaseService.shared.toggleCommentLike(commentId: cid, userId: userId)
            if r.isLiked {
                likedCommentIds.insert(cid)
            } else {
                likedCommentIds.remove(cid)
            }
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension PostComment {
    var stableId: String {
        "\(id ?? "nil")-\(createdAt ?? "")"
    }
}
