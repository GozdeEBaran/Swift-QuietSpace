// BeginPage.swift
import SwiftUI

struct BeginPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            Image(systemName: "location.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.6))
            
            // Title and subtitle
            Text("QuietSpace")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Find Your Focus")
                .font(.title3)
                .foregroundColor(.gray)
            
            Spacer()
            
            // Sign Up button navigates to RegisterPage
            NavigationLink(destination: RegisterPage()) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.6, green: 0.8, blue: 0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            
            // Log In button
            NavigationLink(destination: LoginPage()) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.6, green: 0.8, blue: 0.7), lineWidth: 2)
                    )
                    .cornerRadius(8)
            }
            .padding(.horizontal, 40)
            
            // Already have account text
            HStack {
                Text("Already have an account?")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                NavigationLink(destination: LoginPage()) {
                    Text("Log In")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.6))
                }
            }
            .padding(.top, 10)
            
            Spacer()
            
            // Bottom tagline
            Text("Discover Your Next Productive Space")
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer(minLength: 20)
        }
        .padding()
        .background(Color.white)
        .navigationBarHidden(true)
    }
}


#Preview {
    NavigationStack {
        BeginPage()
    }
}
