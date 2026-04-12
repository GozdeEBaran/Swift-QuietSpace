// Daniil Orlov - 101500729
// implemented the registration logic
// and input validation

import SwiftUI

struct RegisterPage: View {
    @EnvironmentObject private var auth: AuthStore

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var agreed: Bool = false

    @State private var showPassword = false
    @State private var showConfirmPassword = false

    @State private var goToLogin = false
    @State private var showSuccessAlert = false

    private var canSubmit: Bool {
        agreed &&
        !auth.isLoading &&
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 40)

                Image(systemName: "location.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.6))

                Text("QuietSpace")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Find Your Serenity")
                    .font(.title3)
                    .foregroundColor(.gray)

                Text("Register")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.gray)

                        TextField("Full Name", text: $fullName)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)

                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)

                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye" : "eye.slash")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)

                        if showConfirmPassword {
                            TextField("Confirm Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm Password", text: $confirmPassword)
                        }

                        Button {
                            showConfirmPassword.toggle()
                        } label: {
                            Image(systemName: showConfirmPassword ? "eye" : "eye.slash")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)

                HStack(spacing: 10) {
                    Button {
                        agreed.toggle()
                    } label: {
                        Image(systemName: agreed ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreed ? Color(red: 0.4, green: 0.7, blue: 0.6) : .gray)
                    }

                    Text("I agree to Terms & Privacy Policy")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)

                Button {
                    Task {
                        do {
                            try await auth.signUp(
                                email: email,
                                password: password,
                                confirmPassword: confirmPassword,
                                fullName: fullName
                            )
                            showSuccessAlert = true
                        } catch {
                            // auth.errorMessage is already set in AuthStore
                        }
                    }
                } label: {
                    HStack {
                        if auth.isLoading {
                            ProgressView()
                        }
                        Text(auth.isLoading ? "Processing registration..." : "Register")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color(red: 0.6, green: 0.8, blue: 0.7) : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(!canSubmit)
                .padding(.horizontal, 40)
                .padding(.top, 20)

                if let err = auth.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                HStack {
                    Text("Already have an account?")
                        .font(.subheadline)

                    NavigationLink(destination: LoginPage()) {
                        Text("Login")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.6))
                    }
                }
                .padding(.top, 10)

                Spacer(minLength: 40)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .alert("Registration successful", isPresented: $showSuccessAlert) {
            Button("OK") {
                goToLogin = true
            }
        } message: {
            Text("Please check your email for the confirmation.")
        }
        .navigationDestination(isPresented: $goToLogin) {
            LoginPage()
        }
    }
}
