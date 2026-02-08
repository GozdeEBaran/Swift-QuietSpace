import SwiftUI

struct AdminDashboardCard: View {
    //let imageName: String
    let title: String
    let submittedBy: String
    let statusText: String

    var onReview: () -> Void
    var onReject: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Left accent
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.yellow.opacity(0.8))
                .frame(width: 4)

            // Thumbnail
            Image(systemName: "photo")
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)

                        HStack(spacing: 4) {
                            Text("Submitted by:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(submittedBy)
                                .font(.subheadline)
                                .foregroundColor(.teal)
                        }
                    }

                    Spacer()

                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.yellow.opacity(0.25))
                        .clipShape(Capsule())
                        .foregroundColor(.orange)
                }

                HStack(spacing: 10) {
                    Button(action: onReview) {
                        Text("Review")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.teal.opacity(0.75))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onReject) {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .foregroundColor(.gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    AdminDashboardCard(
        //imageName: "cafe1",
        title: "The Study Hub",
        submittedBy: "Sarah J.",
        statusText: "PENDING",
        onReview: { },
        onReject: { }
    )
}
