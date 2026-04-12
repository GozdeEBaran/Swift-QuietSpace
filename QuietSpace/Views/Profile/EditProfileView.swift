// Nguyen Minh Triet Luu — Student ID: 101542519

import PhotosUI
import SwiftUI
import UIKit

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthStore

    @State private var fullName: String = ""
    @State private var selectedAvatar: PhotosPickerItem?
    @State private var selectedCover: PhotosPickerItem?
    @State private var avatarData: Data?
    @State private var coverData: Data?
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var existingAvatarUrl: String?
    @State private var existingCoverUrl: String?

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Full name", text: $fullName)
            }

            Section("Avatar") {
                PhotosPicker(selection: $selectedAvatar, matching: .images) {
                    Label("Choose avatar", systemImage: "person.crop.circle")
                }
                if avatarData != nil || existingAvatarUrl != nil {
                    avatarPreview
                }
            }

            Section("Cover photo") {
                PhotosPicker(selection: $selectedCover, matching: .images) {
                    Label("Choose cover", systemImage: "photo")
                }
                if coverData != nil || existingCoverUrl != nil {
                    coverPreview
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving || auth.userId == nil)
            }
        }
        .task { await load() }
        .onChange(of: selectedAvatar) { _, new in
            Task { avatarData = try? await new?.loadTransferable(type: Data.self) }
        }
        .onChange(of: selectedCover) { _, new in
            Task { coverData = try? await new?.loadTransferable(type: Data.self) }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var avatarPreview: some View {
        HStack(spacing: 12) {
            Group {
                if let data = avatarData, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else if let s = existingAvatarUrl, let u = URL(string: s) {
                    AsyncImage(url: u) { img in img.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            Text("Preview")
                .foregroundColor(.secondary)
        }
    }

    private var coverPreview: some View {
        Group {
            if let data = coverData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else if let s = existingCoverUrl, let u = URL(string: s) {
                AsyncImage(url: u) { img in img.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func load() async {
        guard let uid = auth.userId else { return }
        do {
            let profile = try await SupabaseService.shared.getUserProfile(userId: uid)
            fullName = profile?.fullName ?? (auth.fullName ?? "")
            existingAvatarUrl = profile?.avatarUrl
            existingCoverUrl = profile?.coverImageUrl
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() async {
        guard let uid = auth.userId else { return }
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter your name."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            var avatarUrl = existingAvatarUrl
            var coverUrl = existingCoverUrl

            if let data = avatarData, let ui = UIImage(data: data) {
                let jpeg = ui.jpegData(compressionQuality: 0.85) ?? data
                avatarUrl = try await SupabaseService.shared.uploadAvatarImage(userId: uid, data: jpeg)
            }
            if let data = coverData, let ui = UIImage(data: data) {
                let jpeg = ui.jpegData(compressionQuality: 0.85) ?? data
                coverUrl = try await SupabaseService.shared.uploadProfileCoverImage(userId: uid, data: jpeg)
            }

            try await SupabaseService.shared.updateUserProfile(
                userId: uid,
                fullName: trimmed,
                avatarUrl: avatarUrl,
                coverImageUrl: coverUrl
            )

            auth.updateCachedProfile(fullName: trimmed)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(AuthStore())
    }
}

