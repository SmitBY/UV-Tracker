//
//  ProfileView.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var storeManager = StoreManager.shared
    @AppStorage("app_language") private var appLanguage: String = "system"
    @AppStorage("app_theme") private var appTheme: AppTheme = .system
    @Environment(\.locale) private var currentLocale
    
    @State private var isPaywallPresented: Bool = false
    
    private var supportedLanguageIdentifiers: [String] {
        let raw = Bundle.main.localizations.filter { $0 != "Base" }
        let preferredOrder = ["en", "ru", "de", "es", "fr"]
        
        var ordered: [String] = []
        for code in preferredOrder where raw.contains(code) {
            ordered.append(code)
        }
        for code in raw.sorted() where !ordered.contains(code) {
            ordered.append(code)
        }
        return ordered
    }
    
    private func languageDisplayName(for identifier: String) -> String {
        let locale = Locale(identifier: currentLocale.identifier)
        let baseCode = identifier.split(separator: "-").first.map(String.init) ?? identifier
        
        let name = locale.localizedString(forIdentifier: identifier)
            ?? locale.localizedString(forLanguageCode: baseCode)
            ?? identifier
        
        return name.capitalized(with: locale)
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("tab_profile")
                    .font(.system(size: 32, weight: .bold))
                    .kerning(-1)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top)
                
                List {
                    Section(header: Text("profile_my_profile").foregroundColor(.secondary)) {
                        HStack {
                            Text("profile_skin_type").foregroundColor(.primary)
                            Spacer()
                            if let skinType = profileManager.profile.skinType {
                                Text(LocalizedStringKey(skinType.nameKey))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("—")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button {
                            isPaywallPresented = true
                        } label: {
                            HStack {
                                Text("profile_premium").foregroundColor(.primary)
                                Spacer()
                                Text(profileManager.profile.isPremium ? LocalizedStringKey("Yes") : LocalizedStringKey("No"))
                                    .foregroundColor(profileManager.profile.isPremium ? .green : .secondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.6))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Section(header: Text("profile_language").foregroundColor(.secondary)) {
                        Picker("", selection: $appLanguage) {
                            Text("profile_system").tag("system")
                            ForEach(supportedLanguageIdentifiers, id: \.self) { identifier in
                                Text(languageDisplayName(for: identifier)).tag(identifier)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section(header: Text("profile_appearance").foregroundColor(.secondary)) {
                        Picker("", selection: $appTheme) {
                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                Text(theme.name).tag(theme)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            // Reset onboarding for testing
                            profileManager.profile.isOnboardingCompleted = false
                        } label: {
                            Text("profile_reset_onboarding")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
        }
        .fullScreenCover(isPresented: $isPaywallPresented) {
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "FBDF95"), location: 0),
                        .init(color: Color(hex: "F5D2C0"), location: 0.2189),
                        .init(color: Color(hex: "F6F7F9"), location: 0.6368),
                        .init(color: Color(hex: "F6F7F9"), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                SubscriptionPaywallView(mode: .profile)
                    .padding(.horizontal, 34)
            }
        }
    }
}

