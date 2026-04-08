import SwiftUI

struct AdminProfile: View {
    @EnvironmentObject var auth: AuthStore

    @State private var notificationsOn = true
    @State private var locationServicesOn = false

    var body: some View {
        
        
        ScrollView{
            VStack(spacing: 20){
                
                VStack(spacing: 12) {
                    Image(systemName: "person")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.6))
                    
                    Text("Admin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(auth.email ?? "admin@email.com")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                
                
                VStack(alignment: .leading, spacing: 12) {
                    NavigationLink(destination: AdminDashboard()) {
                        HStack {
                            Image(systemName: "rectangle.grid.2x2.fill")
                            Text("Open Admin Dashboard")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    SettingsToggleRow(icon: "bell.fill", iconColor: .yellow, title: "Notifications", isOn: $notificationsOn)
                    
                    SettingsToggleRow(icon: "location.magnifyingglass", iconColor: .red, title: "Location Services", isOn: $locationServicesOn)
                    
                    SettingsNavRow(icon: "paintpalette.fill", iconColor: .orange, title: "Appearance"){
                        // TODO: later
                    }
                    
                    SettingsNavRow(icon: "lock", iconColor: .black, title: "Privacy"){
                        // TODO: later
                    }
                    
                    SettingsNavRow(icon: "questionmark.circle", iconColor: .red, title: "Help & Support"){
                        // TODO: later
                    }
                    
                    SettingsNavRow(icon: "info", iconColor: .blue, title: "About"){
                        // TODO: later
                    }
                    
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
                
            }
        }
        
        NavBar()
    }
}





#Preview {
    NavigationStack {
        AdminProfile()
            .environmentObject(AuthStore())
    }
}
