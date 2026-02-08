import SwiftUI

// MARK: - Review Location Screen

struct ReviewLocation: View {

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    HeaderBar(title: "Review Location")

                    StatusBanner(
                        title: "Pending Approval",
                        subtitle: "Submitted on Oct 24, 2025. Needs review."
                    )

                    CardContainer {
                        LocationInfoCard(
                            name: "The Study Hub",
                            address: "401 Richmond St W",
                            type: "Co-working Space"
                        )
                    }

                    CardContainer {
                        PhotosCard(
                            title: "USER PHOTOS",
                            images: ["photo1", "photo2", "photo3"] // Replace with your asset names
                        )
                    }

                    CardContainer {
                        DescriptionCard(
                            title: "DESCRIPTION",
                            text: "A quiet spot on the second floor. Great natural light and plenty of outlets."
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                // Leave room for bottom bar
                .padding(.bottom, 110)
            }

            BottomActionBar(
                onReject: { /* TODO */ },
                onApprove: { /* TODO */ }
            )
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Header (Back + Title + Bell)

private struct HeaderBar: View {
    let title: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.title3.weight(.semibold))

            Spacer()

            ZStack(alignment: .topTrailing) {
                Button {
                    // TODO
                } label: {
                    Image(systemName: "bell")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.red)
                    .offset(x: -6, y: 6)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Status Banner

private struct StatusBanner: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.title3.weight(.semibold))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.orange)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.orange.opacity(0.85))
            }

            Spacer()
        }
        .padding(14)
        .background(Color.yellow.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.yellow.opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Card Container

private struct CardContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 5)
    }
}

// MARK: - Location Info Card

private struct LocationInfoCard: View {
    let name: String
    let address: String
    let type: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            SectionLabel("LOCATION NAME")
            Text(name)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)

            SectionLabel("ADDRESS")
            HStack(spacing: 10) {
                Image(systemName: "mappin.circle")
                    .font(.title3)
                    .foregroundColor(.teal)

                Text(address)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()
            }

            SectionLabel("TYPE")
            TypeChip(text: type)
        }
    }
}

// MARK: - Photos Card

private struct PhotosCard: View {
    let title: String
    let images: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(title)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(images, id: \.self) { name in
                        PhotoThumb(imageName: name)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct PhotoThumb: View {
    let imageName: String

    var body: some View {
        Group {
            // If your assets exist, this will show them.
            // Otherwise you’ll see an empty box; swap to a system placeholder if needed.
            Image(imageName)
                .resizable()
                .scaledToFill()
        }
        .frame(width: 110, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .clipped()
    }
}

// MARK: - Description Card

private struct DescriptionCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title)

            Text(text)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Bottom Action Bar

private struct BottomActionBar: View {
    let onReject: () -> Void
    let onApprove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onReject) {
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle")
                        .font(.headline.weight(.semibold))
                    Text("Reject")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.red.opacity(0.65), lineWidth: 1.2)
                )
            }
            .buttonStyle(.plain)

            Button(action: onApprove) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.headline.weight(.semibold))
                    Text("Approve")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.teal.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.10), radius: 16, x: 0, y: -4)
        )
    }
}

// MARK: - Small UI bits

private struct SectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(.gray.opacity(0.7))
    }
}

private struct TypeChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.primary.opacity(0.8))
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReviewLocation()
    }
}
