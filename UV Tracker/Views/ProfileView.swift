//
//  ProfileView.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    
    var body: some View {
        ZStack {
            Color(hex: "F0F2F4").ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "tab_profile"))
                    .font(.system(size: 32, weight: .bold))
                    .kerning(-1)
                    .foregroundColor(.black)
                    .padding(.horizontal)
                    .padding(.top)
                
                List {
                    Section(header: Text("My Profile").foregroundColor(.black.opacity(0.6))) {
                        HStack {
                            Text("Skin Type").foregroundColor(.black)
                            Spacer()
                            Text(profileManager.profile.skinType?.name ?? "Unknown")
                                .foregroundColor(.black.opacity(0.6))
                        }
                        
                        HStack {
                            Text("Premium").foregroundColor(.black)
                            Spacer()
                            Text(profileManager.profile.isPremium ? "Yes" : "No")
                                .foregroundColor(profileManager.profile.isPremium ? .green : .black.opacity(0.6))
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            // Reset onboarding for testing
                            profileManager.profile.isOnboardingCompleted = false
                        } label: {
                            Text("Reset Onboarding")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}

