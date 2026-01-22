//
//  BurnTimeCalculator.swift
//  UV Tracker
//
//  Created by Dmitriy on 27/12/2025.
//

import Foundation

struct BurnTimeCalculator {
    /// Calculates the time to burn in seconds.
    /// - Parameters:
    ///   - skinType: The user's skin type (1-6).
    ///   - uvIndex: Current UV Index.
    ///   - spf: SPF factor (default is 1 for no protection).
    /// - Returns: Time in seconds before burning.
    static func secondsToBurn(skinType: SkinType, uvIndex: Double, spf: Double = 1.0) -> Int {
        guard uvIndex > 0 else { return 86400 } // No burn if UV is 0 (or return a very high value)
        
        // Base time in minutes for UV Index 1 based on skin type
        // Source: General dermatological guidelines for Fitzpatrick scales
        let baseMinutes: Double
        switch skinType {
        case .type1: baseMinutes = 10.0
        case .type2: baseMinutes = 20.0
        case .type3: baseMinutes = 30.0
        case .type4: baseMinutes = 45.0
        case .type5: baseMinutes = 60.0
        case .type6: baseMinutes = 90.0
        }
        
        // Formula: (Base Time / UV Index) * SPF
        let minutesToBurn = (baseMinutes / uvIndex) * spf
        
        return Int(minutesToBurn * 60)
    }
}


