import SwiftUI

struct PostCard: View {
    let feedPost: CommunityFeedPost
    let currentUserId: String?
    let isAdmin: Bool

    let onLike: () -> Void
    let onFlag: () -> Void
    let onAdminDelete: () -> Void
    let onCommentLike: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var colors: AppColors { AppColors(colorScheme) }

    private var post: CommunityPost { feedPost.post }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow

            placeRow

            if let cap = post.caption, !cap.isEmpty {
                Text(cap)
                    .font(.body)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(6)
                    .padding(.top, 8)
            }

            if let urlStr = post.imageUrl, let u = URL(string: urlStr) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        Color.gray.opacity(0.2)
                    default:
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 10)
            }

            Divider().padding(.vertical, 12)

            actionRow

            if !feedPost.topComments.isEmpty {
                Divider().padding(.top, 8)
                commentsPreview
            }
        }
        .padding(16)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colors.border, lineWidth: 1)
        )
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            avatarView

            VStack(alignment: .leading, spacing: 4) {
                Text(post.userName ?? "Anonymous")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(colors.textPrimary)

                HStack(spacing: 6) {
                    Text(CommunityHelpers.timeAgo(from: post.createdAt))
                        .font(.caption)
                        .foregroundColor(colors.textMuted)
                    Circle().fill(colors.textMuted).frame(width: 3, height: 3)
                    Text(CommunityHelpers.categoryEmoji(for: post.category))
                    Text(post.category ?? "")
                        .font(.caption)
                        .foregroundColor(colors.textMuted)
                }
            }

            Spacer()

            if isAdmin {
                Button(role: .destructive, action: onAdminDelete) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var avatarView: some View {
        Group {
            if let s = post.userAvatarUrl, let u = URL(string: s) {
                AsyncImage(url: u) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    placeholderAvatar
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                placeholderAvatar
            }
        }
    }

    private var placeholderAvatar: some View {
        Text(String((post.userName ?? "?").prefix(1)).uppercased())
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .frame(width: 44, height: 44)
            .background(avatarColor(for: post.userName ?? ""))
            .clipShape(Circle())
    }

    private func avatarColor(for name: String) -> Color {
        let palette: [Color] = [.indigo, .purple, .pink, .orange, .green, .blue, .red]
        let h = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[abs(h) % palette.count]
    }

    private var placeRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(colors.primary)
            Text(post.placeName ?? "Place")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(colors.primary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(colors.primary.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(colors.primaryLight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.top, 8)
    }

    private var actionRow: some View {
        HStack(spacing: 20) {
            Button(action: onLike) {
                HStack(spacing: 6) {
                    Image(systemName: feedPost.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(feedPost.isLiked ? colors.error : colors.textSecondary)
                    Text("\(post.displayLikes)")
                        .font(.subheadline)
                        .foregroundColor(feedPost.isLiked ? colors.error : colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(currentUserId == nil)

            if let pid = post.id {
                NavigationLink {
                    PostCommentsView(postId: pid, placeName: post.placeName ?? "")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .foregroundColor(colors.textSecondary)
                        Text("\(post.displayComments)")
                            .font(.subheadline)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }

            if let urlStr = post.imageUrl, let u = URL(string: urlStr) {
                ShareLink(item: u) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(colors.textSecondary)
                }
            } else {
                ShareLink(item: "\(post.placeName ?? "") — \(post.caption ?? "")") {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(colors.textSecondary)
                }
            }

            Spacer()

            Button(action: onFlag) {
                Image(systemName: post.status == "flagged" ? "flag.fill" : "flag")
                    .foregroundColor(post.status == "flagged" ? colors.warning : colors.textSecondary)
            }
            .buttonStyle(.plain)
            .disabled(currentUserId == nil)
        }
        .font(.subheadline)
    }

    private var commentsPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(feedPost.topComments) { tc in
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tc.userName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(colors.textPrimary)
                        Text(tc.text)
                            .font(.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    Spacer(minLength: 8)
                    Button {
                        onCommentLike(tc.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: tc.isLikedByCurrentUser ? "heart.fill" : "heart")
                                .font(.caption2)
                                .foregroundColor(tc.isLikedByCurrentUser ? colors.error : colors.textMuted)
                            if tc.likesCount > 0 {
                                Text("\(tc.likesCount)")
                                    .font(.caption2)
                                    .foregroundColor(tc.isLikedByCurrentUser ? colors.error : colors.textMuted)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(currentUserId == nil)
                }
            }

            if let pid = post.id, post.displayComments > feedPost.topComments.count {
                NavigationLink {
                    PostCommentsView(postId: pid, placeName: post.placeName ?? "")
                } label: {
                    Text("View all \(post.displayComments) comments")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(colors.primary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 8)
    }
}
