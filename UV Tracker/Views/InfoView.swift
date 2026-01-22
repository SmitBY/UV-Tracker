//
//  InfoView.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("tab_info")
                        .font(.system(size: 32, weight: .bold))
                        .kerning(-1)
                        .foregroundColor(.primary)
                        .padding(.top)
                    
                    InfoSection(
                        titleKey: "info_fitzpatrick_title",
                        contentKey: "info_fitzpatrick_desc"
                    )
                    
                    InfoSection(
                        titleKey: "info_uv_index_title",
                        contentKey: "info_uv_index_desc"
                    )
                    
                    InfoSection(
                        titleKey: "info_spf_title",
                        contentKey: "info_spf_desc"
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

struct InfoSection: View {
    let titleKey: LocalizedStringKey
    let contentKey: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titleKey)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(contentKey)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
