import SwiftUI

struct PostCard: View {
    let post: CommunityViewModel.Post
    let onLike: () -> Void
    let onComment: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    private var colors: AppColors { AppColors(colorScheme) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(colors.primaryLight)
                    .frame(width: 40, height: 40)
                    .overlay(Text(post.userName.prefix(1)).foregroundColor(colors.primary))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("\(post.placeName) • \(post.timeAgo)")
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(colors.textMuted)
                }
            }
            
            // Content
            Text(post.content)
                .font(.body)
                .foregroundColor(colors.textPrimary)
            
            Divider()
            
            // Actions
            HStack(spacing: 20) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                        Text("\(post.likes)")
                    }
                }
                
                Button(action: onComment) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .foregroundColor(colors.textSecondary)
            .font(.subheadline)
        }
        .padding(16)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colors.border, lineWidth: 1)
        )
    }
}
