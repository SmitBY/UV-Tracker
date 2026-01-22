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
            Color(hex: "F0F2F4").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(String(localized: "tab_info"))
                        .font(.system(size: 32, weight: .bold))
                        .kerning(-1)
                        .foregroundColor(.black)
                        .padding(.top)
                    
                    InfoSection(
                        title: String(localized: "info_fitzpatrick_title"),
                        content: String(localized: "info_fitzpatrick_desc")
                    )
                    
                    InfoSection(
                        title: String(localized: "info_uv_index_title"),
                        content: String(localized: "info_uv_index_desc")
                    )
                    
                    InfoSection(
                        title: String(localized: "info_spf_title"),
                        content: String(localized: "info_spf_desc")
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

struct InfoSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Text(content)
                .font(.system(size: 16))
                .foregroundColor(.black.opacity(0.7))
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
