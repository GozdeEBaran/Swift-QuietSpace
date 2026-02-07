// LoginPage.swift
import SwiftUI

struct LoginPage: View {
    @State private var email: String = ""
    @State private var password: String = ""
    
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
                
                Text("Login")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                
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
                .padding(.top, 10)
                
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
                
                // Forgot password link
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Text("Don't know the password?")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.6))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 5)
                
                // Login button navigates to MainPage
                NavigationLink(destination: MainPage()) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.6, green: 0.8, blue: 0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                // Register link
                HStack {
                    Text("Don't have an account?")
                        .font(.subheadline)
                    NavigationLink(destination: RegisterPage()) {
                        Text("Register")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.6))
                    }
                }
                .padding(.top, 10)
                
                // Divider with "or"
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                    Text("or")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.gray.opacity(0.3))
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                // Social login buttons (static placeholders)
                VStack(spacing: 12) {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.black)
                            Text("Continue with Google")
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "applelogo")
                                .foregroundColor(.black)
                            Text("Continue with Apple")
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
}
