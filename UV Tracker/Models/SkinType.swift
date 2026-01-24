//
//  SkinType.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import Foundation
import SwiftUI

enum SkinType: Int, Codable, CaseIterable {
    case type1 = 1 // Type I: Always burns, never tans (pale white skin)
    case type2 = 2 // Type II: Always burns, tans minimally (fair skin)
    case type3 = 3 // Type III: Burns moderately, tans uniformly (light brown skin)
    case type4 = 4 // Type IV: Burns minimally, tans well (moderate brown skin)
    case type5 = 5 // Type V: Rarely burns, tans profusely (dark brown skin)
    case type6 = 6 // Type VI: Never burns, deeply pigmented (deeply pigmented dark brown to black skin)
    
    var description: String {
        switch self {
        case .type1: return String(localized: "skin_type_1_desc")
        case .type2: return String(localized: "skin_type_2_desc")
        case .type3: return String(localized: "skin_type_3_desc")
        case .type4: return String(localized: "skin_type_4_desc")
        case .type5: return String(localized: "skin_type_5_desc")
        case .type6: return String(localized: "skin_type_6_desc")
        }
    }
    
    var name: String {
        switch self {
        case .type1: return String(localized: "skin_type_1_name")
        case .type2: return String(localized: "skin_type_2_name")
        case .type3: return String(localized: "skin_type_3_name")
        case .type4: return String(localized: "skin_type_4_name")
        case .type5: return String(localized: "skin_type_5_name")
        case .type6: return String(localized: "skin_type_6_name")
        }
    }
    
    var nameKey: String {
        switch self {
        case .type1: return "skin_type_1_name"
        case .type2: return "skin_type_2_name"
        case .type3: return "skin_type_3_name"
        case .type4: return "skin_type_4_name"
        case .type5: return "skin_type_5_name"
        case .type6: return "skin_type_6_name"
        }
    }
}

enum TimerNotificationSound: String, Codable, CaseIterable, Identifiable {
    case `default` = "default"
    case ringtone = "ringtone"
    case mute = "mute"
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .default: return "notification_sound_default"
        case .ringtone: return "notification_sound_ringtone"
        case .mute: return "notification_sound_mute"
        }
    }
}

struct UserProfile: Codable {
    var skinType: SkinType?
    var isOnboardingCompleted: Bool = false
    var isPremium: Bool = false
    var timerNotificationSound: TimerNotificationSound = .default
    
    enum CodingKeys: String, CodingKey {
        case skinType
        case isOnboardingCompleted
        case isPremium
        case timerNotificationSound
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        skinType = try container.decodeIfPresent(SkinType.self, forKey: .skinType)
        isOnboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .isOnboardingCompleted) ?? false
        isPremium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) ?? false
        timerNotificationSound = try container.decodeIfPresent(TimerNotificationSound.self, forKey: .timerNotificationSound) ?? .default
    }
}

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var name: LocalizedStringKey {
        switch self {
        case .system: return "theme_system"
        case .light: return "theme_light"
        case .dark: return "theme_dark"
        }
    }
}

