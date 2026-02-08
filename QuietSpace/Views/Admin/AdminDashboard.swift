//
//  AdminDashboard.swift
//  QuietSpace
//
//  Created by Nadiia on 2026-02-08.
//

import SwiftUI

struct AdminDashboard: View {
    var body: some View {
        VStack(spacing: 12){
            HStack(){
                Text("Admin Dashboard")
                    .font(.title)
                
                Spacer()
                
                Image(systemName:"bell.badge.circle")
                    .font(.title)
                    .foregroundColor(.red)
            }
            HStack(){
                Text("Pending (3)")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .underline()
                Text("Approved")
                    .font(.title3)
                    .foregroundColor(.primary)
                Text("Rejected")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        
        ScrollView(){
            VStack(alignment: .leading){
                Text("New Submissions")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            
            AdminDashboardCard(title: "The Study Hub", submittedBy: "Sarah J.", statusText: "Pending", onReview: {}, onReject: {})
            
            AdminDashboardCard(title: "Late Night Brews", submittedBy: "Mike T.", statusText: "Pending", onReview: {}, onReject: {})
            
        }
        
        NavBar()
    }
}

#Preview {
    AdminDashboard()
}
