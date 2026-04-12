// Nguyen Minh Triet Luu — Student ID: 101542519

import SwiftUI

// MARK: - Display name

struct ChangeDisplayNameSettingsView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var fullName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didSave = false

    var body: some View {
        Form {
            Section {
                TextField("Full name", text: $fullName)
                    .textContentType(.name)
            } footer: {
                Text("This is the name shown on your profile and in the community.")
            }
        }
        .navigationTitle("Display name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving || auth.userId == nil)
            }
        }
        .task { await load() }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Saved", isPresented: $didSave) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your display name was updated.")
        }
    }

    private func load() async {
        guard let uid = auth.userId else { return }
        do {
            let profile = try await SupabaseService.shared.getUserProfile(userId: uid)
            fullName = profile?.fullName ?? (auth.fullName ?? "")
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
            try await SupabaseService.shared.updateUserProfile(
                userId: uid,
                fullName: trimmed,
                avatarUrl: nil,
                coverImageUrl: nil
            )
            try await SupabaseService.shared.updateAuthUser(metadataFullName: trimmed)
            auth.updateCachedProfile(fullName: trimmed)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Email

struct ChangeEmailSettingsView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var newEmail = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didSave = false

    var body: some View {
        Form {
            if let current = auth.email, !current.isEmpty {
                Section {
                    Text(current)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Current")
                }
            }

            Section {
                TextField("Email address", text: $newEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("New email")
            } footer: {
                Text("If email confirmation is enabled in Supabase, you will get a message to verify the new address.")
            }
        }
        .navigationTitle("Email")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving || auth.userId == nil)
            }
        }
        .onAppear {
            if newEmail.isEmpty, let e = auth.email { newEmail = e }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Request sent", isPresented: $didSave) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your inbox to confirm the new email if your project requires verification.")
        }
    }

    private func save() async {
        let trimmed = newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.count > 3 else {
            errorMessage = "Enter a valid email address."
            return
        }
        if let current = auth.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           !current.isEmpty,
           current == trimmed.lowercased() {
            errorMessage = "That is already your email."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await SupabaseService.shared.updateAuthUser(email: trimmed)
            if let em = SupabaseService.shared.sessionStoredEmail() {
                auth.updateCachedEmail(em)
            }
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Password

struct ChangePasswordSettingsView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var didSave = false

    var body: some View {
        Form {
            Section {
                SecureField("New password", text: $newPassword)
                    .textContentType(.newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
                    .textContentType(.newPassword)
            } footer: {
                Text("Use at least 6 characters. You stay signed in on this device after changing your password.")
            }
        }
        .navigationTitle("Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving…" : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving || auth.userId == nil)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert("Saved", isPresented: $didSave) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your password was updated.")
        }
    }

    private func save() async {
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords don't match."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await SupabaseService.shared.updateAuthUser(password: newPassword)
            newPassword = ""
            confirmPassword = ""
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Display name") {
    NavigationStack {
        ChangeDisplayNameSettingsView()
            .environmentObject(AuthStore())
    }
}

#Preview("Email") {
    NavigationStack {
        ChangeEmailSettingsView()
            .environmentObject(AuthStore())
    }
}

#Preview("Password") {
    NavigationStack {
        ChangePasswordSettingsView()
            .environmentObject(AuthStore())
    }
}
