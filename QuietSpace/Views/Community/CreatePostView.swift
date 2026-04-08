import PhotosUI
import SwiftUI
import UIKit

struct CreatePostView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore

    var onPosted: (() -> Void)? = nil

    @State private var placeName = ""
    @State private var caption = ""
    @State private var selectedCategoryId = "food"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var colors: AppColors { AppColors(colorScheme) }

    private static let categories: [(id: String, label: String, emoji: String)] = [
        ("food", "Food", "🍽️"),
        ("drink", "Drink", "☕"),
        ("atmosphere", "Atmosphere", "✨"),
        ("environment", "Environment", "🌿")
    ]

    var body: some View {
        NavigationStack {
            scrollContent
                .background(colors.background)
                .navigationTitle("Create Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { createToolbar }
                .alert("Error", isPresented: errorBinding) {
                    Button("OK") { errorMessage = nil }
                } message: {
                    Text(errorMessage ?? "")
                }
        }
        .onChange(of: selectedPhoto) { _, new in
            Task {
                guard let new else {
                    imageData = nil
                    return
                }
                imageData = try? await new.loadTransferable(type: Data.self)
            }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                userHeader
                labeledField("Place Name", placeholder: "Where is this quiet spot?", text: $placeName)
                captionField
                categorySection
                photoSection
            }
            .padding(Spacing.md)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(colors.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                ForEach(Self.categories, id: \.id) { c in
                    categoryChip(c)
                }
            }
        }
    }

    private var createToolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSubmitting ? "Posting…" : "Post") {
                    Task { await submit() }
                }
                .disabled(!canSubmit || isSubmitting)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private var canSubmit: Bool {
        !placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && auth.userId != nil
    }

    private var userHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(colors.primaryLight)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(initials)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(colors.primary)
                )
            Text(displayUserName)
                .font(.headline)
                .foregroundColor(colors.textPrimary)
            Spacer()
        }
    }

    private var initials: String {
        let name = auth.fullName ?? auth.email ?? "?"
        let parts = name.split(separator: " ").map(String.init)
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var displayUserName: String {
        if let n = auth.fullName, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return n }
        if let e = auth.email, let at = e.firstIndex(of: "@") { return String(e[..<at]) }
        return "User"
    }

    private func labeledField(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(colors.textSecondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var captionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Caption")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(colors.textSecondary)
            TextField("Share your experience…", text: $caption, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(4...10)
        }
    }

    private func categoryChip(_ c: (id: String, label: String, emoji: String)) -> some View {
        let selected = selectedCategoryId == c.id
        return Button {
            selectedCategoryId = c.id
        } label: {
            HStack(spacing: 8) {
                Text(c.emoji)
                Text(c.label)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(selected ? colors.primaryLight : colors.surfaceVariant)
            .foregroundColor(selected ? colors.primary : colors.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? colors.primary : colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo (optional)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(colors.textSecondary)

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose photo", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(colors.surfaceVariant)
                        .foregroundColor(colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                if imageData != nil {
                    Button("Remove") {
                        selectedPhoto = nil
                        imageData = nil
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }

            if let data = imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func submit() async {
        guard let uid = auth.userId else {
            errorMessage = "Please sign in to create a post."
            return
        }
        let place = placeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cap = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !place.isEmpty, !cap.isEmpty else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            guard let profile = try await SupabaseService.shared.getUserProfile(userId: uid) else {
                errorMessage = "Could not load your profile."
                return
            }
            let userName = CommunityHelpers.displayName(from: profile, email: auth.email)

            var uploadedUrl: String?
            if let raw = imageData, let ui = UIImage(data: raw) {
                let jpeg = ui.jpegData(compressionQuality: 0.8) ?? raw
                uploadedUrl = try await SupabaseService.shared.uploadCommunityPostImage(
                    userId: uid,
                    data: jpeg,
                    contentType: "image/jpeg"
                )
            }

            try await SupabaseService.shared.createPost(
                userId: uid,
                userName: userName,
                userAvatarUrl: profile.avatarUrl,
                placeName: place,
                caption: cap,
                category: selectedCategoryId,
                imageUrl: uploadedUrl
            )
            onPosted?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CreatePostView()
        .environmentObject(AuthStore())
}
