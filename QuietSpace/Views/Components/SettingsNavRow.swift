//
//  SettingsNavRow.swift
//  QuietSpace
//
//  Created by Nadiia on 2026-02-08.
//

import SwiftUI

struct SettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)

                Text(title)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.6))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    SettingsNavRow(icon: "lock", iconColor: .black, title: "Privacy"){
        // TODO
    }
}
