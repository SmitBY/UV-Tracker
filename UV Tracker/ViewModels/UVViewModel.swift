//
//  UVViewModel.swift
//  UV Tracker
//
//  Created by Dmitriy on 26/12/2025.
//

import SwiftUI
import Combine
import CoreLocation

@MainActor
class UVViewModel: ObservableObject {
    @Published var currentUV: Double = 0
    @Published var maxUVToday: Double = 0
    @Published var timeToBurnSeconds: Int = 0
    @Published var uvDose: Double = 0
    @Published var selectedSPF: Int = 30
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var timerManager = TimerManager.shared
    private let uvService = UVService.shared
    private let locationManager = LocationManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
        refreshUV()
    }
    
    private func setupSubscriptions() {
        locationManager.$location
            .compactMap { $0 }
            .debounce(for: .seconds(10), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshUV()
            }
            .store(in: &cancellables)
    }
    
    func refreshUV() {
        guard let location = locationManager.location else {
            locationManager.requestLocation()
            return
        }

        isLoading = true
        Task {
            do {
                let uvData = try await uvService.fetchUVData(for: location)
                self.currentUV = uvData.currentUV
                self.maxUVToday = uvData.maxUV // Use max UV from API

                await updateBurnTime()
                self.isLoading = false
            } catch {
                self.errorMessage = "Failed to fetch UV: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func updateBurnTime() async {
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
        Task {
            await updateBurnTime()
            timerManager.startTimer(seconds: timeToBurnSeconds, uvIndex: currentUV)
        }
    }
}

