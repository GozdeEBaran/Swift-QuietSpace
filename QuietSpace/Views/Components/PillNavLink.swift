import SwiftUI

struct PillNavLink<Destination: View>: View {
    let title: String
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .overlay(Capsule().stroke(.primary, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        PillNavLink(title: "User Manager", destination: AdminDashboard())
    }
}
