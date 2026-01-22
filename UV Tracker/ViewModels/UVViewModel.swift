//
//  UVViewModel.swift
//  UV Tracker
//
//  Created by Dmitriy on 26/12/2025.
//

import SwiftUI
import Combine
import CoreLocation
import UIKit

@MainActor
class UVViewModel: ObservableObject {
    @Published var currentUV: Double = 0
    @Published var maxUVToday: Double = 0
    @Published var timeToBurnSeconds: Int = 0
    @Published var selectedSPF: Int = 30
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var lastUpdate: Date?
    
    @Published var timerManager = TimerManager.shared
    private let uvService = UVService.shared
    private let locationManager = LocationManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        restoreCachedUVIfAvailable()
        setupSubscriptions()
        refreshUV()
    }
    
    private enum StorageKey {
        static let currentUV = "uv_last_known_current_uv"
        static let maxUVToday = "uv_last_known_max_uv_today"
        static let lastUpdate = "uv_last_known_last_update"
        static let sunrise = "uv_last_known_sunrise"
        static let sunset = "uv_last_known_sunset"
        static let lastFetchLatitude = "uv_last_fetch_latitude"
        static let lastFetchLongitude = "uv_last_fetch_longitude"
    }
    
    private let minimumRefreshInterval: TimeInterval = 15 * 60
    private let refreshCheckInterval: TimeInterval = 60
    private let sunTimesLocationMaxDistance: CLLocationDistance = 100_000
    
    private var lastKnownSunrise: Date?
    private var lastKnownSunset: Date?
    private var lastFetchLatitude: Double?
    private var lastFetchLongitude: Double?
    
    private func restoreCachedUVIfAvailable() {
        let defaults = UserDefaults.standard
        guard let cachedLastUpdate = defaults.object(forKey: StorageKey.lastUpdate) as? Date else {
            return
        }
        
        currentUV = defaults.double(forKey: StorageKey.currentUV)
        maxUVToday = defaults.double(forKey: StorageKey.maxUVToday)
        lastUpdate = cachedLastUpdate
        
        // Reset max UV if it's a new day
        if let lastUpdate = lastUpdate, !Calendar.current.isDateInToday(lastUpdate) {
            maxUVToday = 0
        }
        
        lastKnownSunrise = defaults.object(forKey: StorageKey.sunrise) as? Date
        lastKnownSunset = defaults.object(forKey: StorageKey.sunset) as? Date
        
        if defaults.object(forKey: StorageKey.lastFetchLatitude) != nil,
           defaults.object(forKey: StorageKey.lastFetchLongitude) != nil {
            lastFetchLatitude = defaults.double(forKey: StorageKey.lastFetchLatitude)
            lastFetchLongitude = defaults.double(forKey: StorageKey.lastFetchLongitude)
        }

        // If it's currently night, force UV to 0
        if let isSunUp = isSunUp(at: Date(), currentLocation: locationManager.location), !isSunUp {
            currentUV = 0
        }
        
        updateBurnTime()
    }
    
    private func persistCachedUV() {
        let defaults = UserDefaults.standard
        defaults.set(currentUV, forKey: StorageKey.currentUV)
        defaults.set(maxUVToday, forKey: StorageKey.maxUVToday)
        defaults.set(lastUpdate, forKey: StorageKey.lastUpdate)
        
        if let sunrise = lastKnownSunrise, let sunset = lastKnownSunset {
            defaults.set(sunrise, forKey: StorageKey.sunrise)
            defaults.set(sunset, forKey: StorageKey.sunset)
        } else {
            defaults.removeObject(forKey: StorageKey.sunrise)
            defaults.removeObject(forKey: StorageKey.sunset)
        }
        
        if let lat = lastFetchLatitude, let lon = lastFetchLongitude {
            defaults.set(lat, forKey: StorageKey.lastFetchLatitude)
            defaults.set(lon, forKey: StorageKey.lastFetchLongitude)
        } else {
            defaults.removeObject(forKey: StorageKey.lastFetchLatitude)
            defaults.removeObject(forKey: StorageKey.lastFetchLongitude)
        }
    }
    
    private func cachedFetchLocation() -> CLLocation? {
        guard let lat = lastFetchLatitude, let lon = lastFetchLongitude else { return nil }
        return CLLocation(latitude: lat, longitude: lon)
    }
    
    /// Returns `nil` if we don't have reliable sun times (or they are likely for another location).
    private func isSunUp(at now: Date, currentLocation: CLLocation?) -> Bool? {
        guard let sunrise = lastKnownSunrise, let sunset = lastKnownSunset else { return nil }
        guard sunrise < sunset else { return nil }
        
        if let currentLocation,
           let cachedLocation = cachedFetchLocation(),
           cachedLocation.distance(from: currentLocation) > sunTimesLocationMaxDistance {
            return nil
        }
        
        let oneDay: TimeInterval = 24 * 60 * 60
        var adjustedSunrise = sunrise
        var adjustedSunset = sunset
        
        if now >= adjustedSunset {
            let daysToAdd = Int(floor(now.timeIntervalSince(adjustedSunset) / oneDay)) + 1
            let delta = oneDay * Double(max(0, daysToAdd))
            adjustedSunrise = adjustedSunrise.addingTimeInterval(delta)
            adjustedSunset = adjustedSunset.addingTimeInterval(delta)
        }
        
        return now >= adjustedSunrise && now < adjustedSunset
    }
    
    private func setupSubscriptions() {
        timerManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        $currentUV
            .removeDuplicates()
            .sink { [weak self] newUV in
                guard let self else { return }
                if self.timerManager.isTimerRunning {
                    self.timerManager.updateSessionUVIndex(newUV)
                }
            }
            .store(in: &cancellables)

        locationManager.$location
            .compactMap { $0 }
            .debounce(for: .seconds(60), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refreshUV()
                }
            }
            .store(in: &cancellables)
        
        // Periodic refresh (actual fetch is still limited by `minimumRefreshInterval`)
        Timer.publish(every: refreshCheckInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refreshUV()
                }
            }
            .store(in: &cancellables)
        
        // Refresh after returning from background if data is stale
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refreshUV()
                }
            }
            .store(in: &cancellables)
    }
    
    func refreshUV() {
        if isLoading {
            return
        }
        
        let now = Date()
        if let isSunUp = isSunUp(at: now, currentLocation: locationManager.location), !isSunUp {
            print("Skipping UV refresh because sun is down, setting UV to 0")
            if currentUV != 0 {
                currentUV = 0
                updateBurnTime()
            }
            return
        }
        
        // Don't refresh if we updated less than 15 minutes ago
        if let lastUpdate = lastUpdate, now.timeIntervalSince(lastUpdate) < minimumRefreshInterval {
            print("Skipping UV refresh, last update was less than 15 minutes ago")
            return
        }

        guard let location = locationManager.location else {
            locationManager.requestLocation()
            return
        }

        isLoading = true
        Task {
            do {
                let uvData = try await uvService.fetchUVData(for: location)
                self.currentUV = uvData.currentUV
                self.maxUVToday = uvData.maxUV
                self.lastUpdate = Date()
                
                self.lastFetchLatitude = location.coordinate.latitude
                self.lastFetchLongitude = location.coordinate.longitude
                
                if let sunrise = uvData.sunrise, let sunset = uvData.sunset {
                    self.lastKnownSunrise = sunrise
                    self.lastKnownSunset = sunset
                } else {
                    self.lastKnownSunrise = nil
                    self.lastKnownSunset = nil
                }
                
                self.persistCachedUV()

                updateBurnTime()
                self.isLoading = false
                self.errorMessage = nil
            } catch {
                self.errorMessage = "Failed to fetch UV: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func updateBurnTime() {
        let profile = ProfileManager.shared.profile
        guard let skinType = profile.skinType else { return }
        
        self.timeToBurnSeconds = BurnTimeCalculator.secondsToBurn(
            skinType: skinType,
            uvIndex: currentUV,
            spf: Double(selectedSPF)
        )
    }
    
    var uvLevelText: String {
        switch currentUV {
        case 0..<3: return String(localized: "uv_level_low")
        case 3..<6: return String(localized: "uv_level_moderate")
        case 6..<8: return String(localized: "uv_level_high")
        case 8..<11: return String(localized: "uv_level_very_high")
        default: return String(localized: "uv_level_extreme")
        }
    }
    
    var uvLevelColor: Color {
        switch currentUV {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
    }
    
    func startSession() {
        let profile = ProfileManager.shared.profile
        guard let skinType = profile.skinType else { return }
        
        updateBurnTime()
        
        // Burn threshold is constant in UVIndexSeconds for a given skin type + SPF:
        // timeToBurn = (baseMinutes / UV) * SPF  =>  UV * timeToBurn = baseMinutes * SPF (constant)
        let burnLimitUVIndexSeconds = Double(
            BurnTimeCalculator.secondsToBurn(
                skinType: skinType,
                uvIndex: 1,
                spf: Double(selectedSPF)
            )
        )
        
        timerManager.startTimer(
            seconds: timeToBurnSeconds,
            uvIndex: currentUV,
            burnLimitUVIndexSeconds: burnLimitUVIndexSeconds
        )
    }
}

