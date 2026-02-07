// RegisterPage.swift
import SwiftUI

struct RegisterPage: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var agreed: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 40)
                
                // Logo
                Image(systemName: "location.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.6))
                
                // Title and subtitle
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
                
                // Full Name field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person")
                            .foregroundColor(.gray)
                        TextField("Full Name", text: $fullName)
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.gray)
                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 40)
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        SecureField("Password", text: $password)
                        Button(action: {}) {
                            Image(systemName: "eye.slash")
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
                
                // Confirm Password field
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        SecureField("Confirm Password", text: $confirmPassword)
                        Button(action: {}) {
                            Image(systemName: "eye.slash")
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
                
                // Terms agreement toggle
                HStack(spacing: 10) {
                    Button(action: {
                        agreed.toggle()
                    }) {
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
                
                // Register button (enabled only if agreed)
                NavigationLink(destination: MainPage()) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(agreed ? Color(red: 0.6, green: 0.8, blue: 0.7) : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!agreed)
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                // Login link
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
    }
}
