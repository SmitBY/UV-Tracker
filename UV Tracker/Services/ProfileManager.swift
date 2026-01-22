//
//  ProfileManager.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    private let userDefaultsKey = "user_profile"
    
    @Published var profile: UserProfile {
        didSet {
            saveProfile(profile)
        }
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserProfile()
        }
    }
    
    func updateSkinType(_ type: SkinType) {
        profile.skinType = type
    }
    
    func completeOnboarding() {
        profile.isOnboardingCompleted = true
    }
    
    func setPremium(_ isPremium: Bool) {
        profile.isPremium = isPremium
    }
    
    private func saveProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
}

