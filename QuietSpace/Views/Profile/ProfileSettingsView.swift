// Nguyen Minh Triet Luu — Student ID: 101542519

import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var notificationsEnabled = true
    @State private var locationEnabled = true
    @State private var showSignOutConfirm = false
    @State private var isAdmin = false

    var body: some View {
        List {
            Section {
                Toggle("Notifications", isOn: $notificationsEnabled)
                Toggle("Location Services", isOn: $locationEnabled)
            }

            Section("Account") {
                NavigationLink("Display name") {
                    ChangeDisplayNameSettingsView()
                }
                NavigationLink("Email") {
                    ChangeEmailSettingsView()
                }
                NavigationLink("Password") {
                    ChangePasswordSettingsView()
                }
            }

            if isAdmin {
                Section {
                    NavigationLink("Admin Dashboard") { AdminDashboard() }
                }
            }

            Section {
                Button(role: .destructive) { showSignOutConfirm = true } label: {
                    Text("Sign Out")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .task {
            guard let uid = auth.userId else { isAdmin = false; return }
            isAdmin = (try? await SupabaseService.shared.isAdmin(userId: uid)) ?? false
        }
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { auth.signOut() }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
            .environmentObject(AuthStore())
    }
}

